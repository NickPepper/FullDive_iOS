#import <AVFoundation/AVFoundation.h>

@protocol CameraCapturePipelineDelegate;

@interface CameraCapturePipeline : NSObject

// delegate is weak referenced
- (void)setDelegate:(id<CameraCapturePipelineDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue;

// These methods are synchronous
- (void)startPreview;
- (void)stopPreview;

// When set to false the GPU will not be used after the setRenderingEnabled: call returns.
@property(readwrite) BOOL renderingEnabled;

@end

@protocol CameraCapturePipelineDelegate <NSObject>

- (void)capturePipeline:(CameraCapturePipeline *)capturePipeline didStopRunningWithError:(NSError *)error;
// Preview
- (void)capturePipeline:(CameraCapturePipeline *)capturePipeline previewPixelBufferReadyForDisplay:(CVPixelBufferRef)previewPixelBuffer;
@end
