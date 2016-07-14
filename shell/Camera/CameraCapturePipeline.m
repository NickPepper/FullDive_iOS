#import <UIKit/UIKit.h>
#import "CameraCapturePipeline.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CameraCapturePipeline () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    // __weak doesn't actually do anything under non-ARC
	__weak id <CameraCapturePipelineDelegate> _delegate;
	dispatch_queue_t _delegateCallbackQueue;
	
	AVCaptureSession *_captureSession;
	AVCaptureDevice *_videoDevice;
	AVCaptureConnection *_videoConnection;
	BOOL _running;
	BOOL _startCaptureSessionOnEnteringForeground;
    BOOL _orientationFlag;
	id _applicationWillEnterForegroundNotificationObserver;
	NSDictionary *_videoCompressionSettings;
	
	dispatch_queue_t _sessionQueue;
	dispatch_queue_t _videoDataOutputQueue;
			
	UIBackgroundTaskIdentifier _pipelineRunningTask;
}

@property(nonatomic, retain) __attribute__((NSObject)) CVPixelBufferRef currentPreviewPixelBuffer;

@end

@implementation CameraCapturePipeline

- (instancetype)init {
	self = [super init];
	if ( self ) {
		_sessionQueue = dispatch_queue_create( "com.fulldive.camera.capturepipeline.session", DISPATCH_QUEUE_SERIAL );
		// In a multi-threaded producer consumer system it's generally a good idea to make sure that producers do not get starved of CPU time by their consumers.
		// In this app we start with VideoDataOutput frames on a high priority queue, and downstream consumers use default priority queues.
		_videoDataOutputQueue = dispatch_queue_create( "com.fulldive.camera.capturepipeline.video", DISPATCH_QUEUE_SERIAL );
		dispatch_set_target_queue( _videoDataOutputQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ) );
		_pipelineRunningTask = UIBackgroundTaskInvalid;
        _orientationFlag = YES;
	}
	return self;
}

- (void)dealloc {
    // unregister _delegate as a weak reference
    _delegate = nil;
    if ( _currentPreviewPixelBuffer ) {
		CFRelease( _currentPreviewPixelBuffer );
	}
	[self teardownCaptureSession];
}

#pragma mark - Delegate
// delegate is weak referenced
- (void)setDelegate:(id<CameraCapturePipelineDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue {
	if (delegate && (delegateCallbackQueue == NULL)) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Caller must provide a delegateCallbackQueue" userInfo:nil];
	}
	
	@synchronized( self ) {
        _delegate = delegate;
		if ( delegateCallbackQueue != _delegateCallbackQueue ) {
			_delegateCallbackQueue = delegateCallbackQueue;
		}
	}
}

- (id<CameraCapturePipelineDelegate>)delegate {
	id <CameraCapturePipelineDelegate> delegate = nil;
	@synchronized( self ) {
		delegate = _delegate;
	}
	return delegate;
}

#pragma mark - Capture Session

- (void)startPreview {
	dispatch_sync( _sessionQueue, ^{
        [self setupCaptureSession];
        [_captureSession startRunning];
		_running = YES;
	} );
}

- (void)stopPreview {
	dispatch_sync( _sessionQueue, ^{
		_running = NO;
		
		[_captureSession stopRunning];
		
		[self captureSessionDidStopRunning];
		
		[self teardownCaptureSession];
	} );
}

- (void)setupCaptureSession {
	if ( _captureSession ) {
		return;
	}
    _captureSession = [[AVCaptureSession alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionNotification:) name:nil object:_captureSession];
	_applicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note) {
		// Retain self while the capture session is alive by referencing it in this observer block which is tied to the session lifetime
		// Client must stop us running before we can be deallocated
		[self applicationWillEnterForeground];
	}];
		
	/* Video */
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	_videoDevice = videoDevice;
	AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
	if ( [_captureSession canAddInput:videoIn] ) {
		[_captureSession addInput:videoIn];
	}
	
	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    videoOut.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
	[videoOut setSampleBufferDelegate:self queue:_videoDataOutputQueue];
	
	// If we prefer not to have any dropped frames in the video recording.
	// By setting alwaysDiscardsLateVideoFrames to NO we ensure that minor fluctuations in system load or in our processing time for a given frame won't cause framedrops.
	// We do however need to ensure that on average we can process frames in realtime.
	// If we were doing preview only we would probably want to set alwaysDiscardsLateVideoFrames to YES.
	videoOut.alwaysDiscardsLateVideoFrames = YES;
	
	if ( [_captureSession canAddOutput:videoOut] ) {
		[_captureSession addOutput:videoOut];
	}
	_videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
		
	int frameRate;
	NSString *sessionPreset = AVCaptureSessionPresetHigh;
	CMTime frameDuration = kCMTimeInvalid;
	// For single core systems like iPhone 4 and iPod Touch 4th Generation we use a lower resolution and framerate to maintain real-time performance.
	if ( [NSProcessInfo processInfo].processorCount == 1 ) {
		if ( [_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480] ) {
			sessionPreset = AVCaptureSessionPreset640x480;
		}
		frameRate = 15;
	} else {
		frameRate = 30;
	}
    
	_captureSession.sessionPreset = sessionPreset;
	
	frameDuration = CMTimeMake( 1, frameRate );

	NSError *error = nil;
	if ( [videoDevice lockForConfiguration:&error] ) {
		videoDevice.activeVideoMaxFrameDuration = frameDuration;
		videoDevice.activeVideoMinFrameDuration = frameDuration;
		[videoDevice unlockForConfiguration];
	} else {
		NSLog( @"videoDevice lockForConfiguration returned error %@", error );
	}

	// Get the recommended compression settings after configuring the session/device.
	_videoCompressionSettings = [[videoOut recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie] copy];
	
	return;
}

- (void)teardownCaptureSession {
	if ( _captureSession ) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_captureSession];
		
		[[NSNotificationCenter defaultCenter] removeObserver:_applicationWillEnterForegroundNotificationObserver];
		_applicationWillEnterForegroundNotificationObserver = nil;
		_captureSession = nil;
		_videoCompressionSettings = nil;
	}
}

- (void)captureSessionNotification:(NSNotification *)notification {
	dispatch_async( _sessionQueue, ^{
		
		if ( [notification.name isEqualToString:AVCaptureSessionWasInterruptedNotification] ) {
			NSLog( @"session interrupted" );
			[self captureSessionDidStopRunning];
		} else if ( [notification.name isEqualToString:AVCaptureSessionInterruptionEndedNotification] ) {
			NSLog( @"session interruption ended" );
		} else if ( [notification.name isEqualToString:AVCaptureSessionRuntimeErrorNotification] ) {
			[self captureSessionDidStopRunning];
			NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
			if ( error.code == AVErrorDeviceIsNotAvailableInBackground ) {
				NSLog( @"device not available in background" );
				// Since we can't resume running while in the background we need to remember this for next time we come to the foreground
				if ( _running ) {
					_startCaptureSessionOnEnteringForeground = YES;
				}
			} else if ( error.code == AVErrorMediaServicesWereReset ) {
				NSLog( @"media services were reset" );
				[self handleRecoverableCaptureSessionRuntimeError:error];
			} else {
				[self handleNonRecoverableCaptureSessionRuntimeError:error];
			}
		} else if ( [notification.name isEqualToString:AVCaptureSessionDidStartRunningNotification] ) {
			NSLog( @"session started running" );
		} else if ( [notification.name isEqualToString:AVCaptureSessionDidStopRunningNotification] ) {
			NSLog( @"session stopped running" );
		}
	} );
}

- (void)captureSessionDidStopRunning {
    [self teardownVideoPipeline];
}

- (void)applicationWillEnterForeground {
    NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
    dispatch_sync( _sessionQueue, ^{
        if ( _startCaptureSessionOnEnteringForeground ) {
            NSLog( @"-[%@ %@] manually restarting session", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
            _startCaptureSessionOnEnteringForeground = NO;
            if ( _running ) {
                [_captureSession startRunning];
            }
        }
    } );
}

#pragma mark - ERROR Handling

- (void)handleRecoverableCaptureSessionRuntimeError:(NSError *)error {
	if ( _running ) {
		[_captureSession startRunning];
	}
}

- (void)handleNonRecoverableCaptureSessionRuntimeError:(NSError *)error {
	NSLog( @"fatal runtime error %@, code %i", error, (int)error.code );
	_running = NO;
	[self teardownCaptureSession];
	@synchronized( self ) {
		if ( self.delegate ) {
			dispatch_async( _delegateCallbackQueue, ^{
				@autoreleasepool {
					[self.delegate capturePipeline:self didStopRunningWithError:error];
				}
			});
		}
	}
}

#pragma mark - Capture Pipeline

// synchronous, blocks until the pipeline is drained, don't call from within the pipeline
- (void)teardownVideoPipeline {
	// The session is stopped so we are guaranteed that no new buffers are coming through the video data output.
	// There may be inflight buffers on _videoDataOutputQueue however.
	// Synchronize with that queue to guarantee no more buffers are in flight.
	// Once the pipeline is drained we can tear it down safely.
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	dispatch_sync( _videoDataOutputQueue, ^{
        self.currentPreviewPixelBuffer = NULL;
		NSLog( @"-[%@ %@] finished teardown", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
		[self videoPipelineDidFinishRunning];
	} );
}

- (void)videoPipelineWillStartRunning {
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	NSAssert( _pipelineRunningTask == UIBackgroundTaskInvalid, @"should not have a background task active before the video pipeline starts running" );
	_pipelineRunningTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		NSLog( @"video capture pipeline background task expired" );
	}];
}

- (void)videoPipelineDidFinishRunning {
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	NSAssert( _pipelineRunningTask != UIBackgroundTaskInvalid, @"should have a background task active when the video pipeline finishes running" );
	[[UIApplication sharedApplication] endBackgroundTask:_pipelineRunningTask];
	_pipelineRunningTask = UIBackgroundTaskInvalid;
}

// call under @synchronized( self )
- (void)outputPreviewPixelBuffer:(CVPixelBufferRef)previewPixelBuffer {
	if ( self.delegate ) {
		// Keep preview latency low by dropping stale frames that have not been picked up by the delegate yet
		self.currentPreviewPixelBuffer = previewPixelBuffer;
		dispatch_async( _delegateCallbackQueue, ^{
			@autoreleasepool {
				CVPixelBufferRef currentPreviewPixelBuffer = NULL;
				@synchronized( self ) {
					currentPreviewPixelBuffer = self.currentPreviewPixelBuffer;
					if ( currentPreviewPixelBuffer ) {
						CFRetain( currentPreviewPixelBuffer );
						self.currentPreviewPixelBuffer = NULL;
					}
				}
				if ( currentPreviewPixelBuffer ) {
					[self.delegate capturePipeline:self previewPixelBufferReadyForDisplay:currentPreviewPixelBuffer];
				}
			}
		} );
	}
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate callback

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (_orientationFlag) {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;
        [connection setVideoOrientation:orientation];
        _orientationFlag = NO;
    }
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
    @synchronized( self ) {
        if ( pixelBuffer ) {
            [self outputPreviewPixelBuffer:pixelBuffer];
        }
    }
}
@end
