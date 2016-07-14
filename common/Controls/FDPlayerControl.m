//
//  FDPlayerControl.m
//  FullDive
//
//  Created by Alexey Suvorov on 06/26/15.
//  Completed by Nick Pershin on 07/06/15.
//

#import "FDUtils.h"
#import "FDWorldParameters.h"
//#import "FDImage.h"
//#import "FDButton.h"
#import "FDPlayerControl.h"


@implementation FDPlayerControl
{
/////////////////////////////////// OLD Alexey's CODE ////////////////////////////////////////////
    FDWorldParameters*  _worldParams;
    
    GLuint              _glProgram;
    GLuint              _texture;
    NSString*           _imageName;
    
    float_t _scale;
    float_t _targetScale;
    float_t _scaleSpeed;
    
    GLuint _texCoord;
    GLuint _rectangle;
    
    BOOL _visible;
    
/////////////////////////////////// NEW Pepper's CODE ////////////////////////////////////////////
    // AVPlayer
    AVPlayer*   _player;
    CMTime      _playerCursorStartPosition;
    
    // Asset
    NSURL*      _mediaURL;
    AVURLAsset* _asset;
    BOOL        _playImmediately;
    float       _requestedCursorPosition;
    
    // Playback status
    MEDIA_STATE _mediaState;
    
    // Timing
    CFTimeInterval _playerCursorPosition;
    
    // Video properties
    CGSize  _videoSize;
    Float64 _videoLengthSeconds;
    
    // Audio properties
    float   _currentVolume;
    BOOL    _playAudio;
    
    // OpenGL data
    GLuint _videoTextureHandle;
}

#pragma mark - Player

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////// NEW Pepper's CODE ///////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)load:(NSString*)videoURL playImmediately:(BOOL)playOnTextureImmediately fromPosition:(float)seekPosition
{
    NSLog(@"load(): videoURL = %@, playImmediately = %d, fromPosition = %f", videoURL, playOnTextureImmediately, seekPosition);
    
    BOOL ret = NO;

///////////////////////////////////////////////////////////////
    NSLog(@"_mediaState = %u", _mediaState);
    NSLog(@"status = %u", [self getStatus]);

    _mediaURL = [[NSURL alloc] initWithString:videoURL];
    if (playOnTextureImmediately) {
        _playImmediately = playOnTextureImmediately;
    }
        
    if (seekPosition >= 0.0f) {
        // If a valid position has been requested, update the player cursor, which will allow playback to begin from the correct position
        [self updatePlayerCursorPosition:seekPosition];
    }
        
    ret = [self loadMediaURL:_mediaURL];
///////////////////////////////////////////////////////////////
/*
    // Load only if there is no media currently loaded
    if (NOT_READY != _mediaState && ERROR != _mediaState) {
        NSLog(@"Media already loaded.  Unload current media first.");
    }
    else {
        
        _mediaURL = [[NSURL alloc] initWithString:videoURL];
        if (playOnTextureImmediately) {
            _playImmediately = playOnTextureImmediately;
        }
        
        if (seekPosition >= 0.0f) {
            // If a valid position has been requested, update the player cursor, which will allow playback to begin from the correct position
            [self updatePlayerCursorPosition:seekPosition];
        }
        
        ret = [self loadMediaURL:_mediaURL];
    }
*/
    if (!ret) {
        // Some error occurred
        _mediaState = ERROR;
    }

    return ret;
}



- (BOOL)loadMediaURL:(NSURL*)url
{
    NSLog(@"loadMediaURL(): %@", url);
    
    BOOL ret = NO;
    _asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    if (_asset != nil) {
        // We can now attempt to load the media, so report success.
        // We will discover if the load actually completes successfully when we are called back by the system.
        ret = YES;
        
        [_asset loadValuesAsynchronouslyForKeys:@[kTracksKey] completionHandler: ^{
            // Completion handler block (dispatched on main queue when loading completes)
            dispatch_async(dispatch_get_main_queue(),^{
                NSError *error = nil;
                AVKeyValueStatus status = [_asset statusOfValueForKey:kTracksKey error:&error];
                
                
                NSDictionary *settings = @{(id) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
                AVPlayerItemVideoOutput *output = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
                self.videoOutput = output;
                
                
                if (status == AVKeyValueStatusLoaded) {
                    // Asset loaded, retrieve info and prepare for playback
                    if (![self prepareAssetForPlayback]) {
                        _mediaState = ERROR;
                    }
                }
                else {
                    // Error
                    _mediaState = ERROR;
                }
            });
        }];
    }
    
    return ret;
}


/*
 - (BOOL)loadLocalMediaFromURL:(NSURL*)url
 {
 NSLog(@"loadLocalMediaFromURL(): %@", url);
 
 BOOL ret = NO;
 _asset = [[AVURLAsset alloc] initWithURL:url options:nil];
 
 if (nil != _asset) {
 // We can now attempt to load the media, so report success.
 // We will discover if the load actually completes successfully when we are called back by the system.
 ret = YES;
 
 [_asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:kTracksKey] completionHandler:
 ^{
 // Completion handler block (dispatched on main queue when loading completes)
 dispatch_async(dispatch_get_main_queue(),
 ^{
 NSError *error = nil;
 AVKeyValueStatus status = [_asset statusOfValueForKey:kTracksKey error:&error];
 
 if (status == AVKeyValueStatusLoaded) {
 // Asset loaded, retrieve info and prepare for playback
 if (NO == [self prepareAssetForPlayback]) {
 NSLog(@"ERROR: Unable to prepare media for playback");
 _mediaState = ERROR;
 }
 }
 else {
 // Error
 NSLog(@"ERROR: The asset's tracks were not loaded: %@", [error localizedDescription]);
 _mediaState = ERROR;
 }
 });
 }];
 }
 
 return ret;
 }
 */



/*
 * Prepare the AVPlayer object for media playback
 */
- (void)prepareAVPlayer
{
    NSLog(@"prepareAVPlayer()");
    
    // Create a player item
    AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:_asset];
    
    //    // Add player item status KVO observer
    //    NSKeyValueObservingOptions opts = NSKeyValueObservingOptionNew;
    //    [item addObserver:self forKeyPath:kStatusKey options:opts context:AVPlayerItemStatusObservationContext];
    
    // Create an AV player
    _player = [[AVPlayer alloc] initWithPlayerItem:item];
    [item addOutput:self.videoOutput];
    
    //    // Add player rate KVO observer
    //    [_player addObserver:self forKeyPath:kRateKey options:opts context:AVPlayerRateObservationContext];
}



/*
 * Prepare the AVURLAsset for playback
 */
- (BOOL)prepareAssetForPlayback
{
    NSLog(@"prepareAssetForPlayback()");
    
    // Get video properties
    NSArray *videoTracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = videoTracks[0];
    _videoSize = videoTrack.naturalSize;
    
    _videoLengthSeconds = CMTimeGetSeconds([_asset duration]);
    
    // Start playback at time 0.0
    _playerCursorStartPosition = kCMTimeZero;
    
    // Start playback at full volume (audio mix level, not system volume level)
    _currentVolume = PLAYER_VOLUME_DEFAULT;
    
    // Create asset tracks for reading
    BOOL ret = [self prepareAssetForReading:_playerCursorStartPosition];
    
    if (ret) {
        // Prepare the AVPlayer to play the audio
        [self prepareAVPlayer];
        // Inform our client that the asset is ready to play
        _mediaState = READY;
    }
    
    return ret;
}



/*
 * Prepare the AVURLAsset for reading so we can obtain video frame data from it
 */
- (BOOL)prepareAssetForReading:(CMTime)startTime
{
    //    NSLog(@"prepareAssetForReading(): CMTimeGetSeconds(startTime) = %f", CMTimeGetSeconds(startTime));
    
    NSUInteger dTotalSeconds = CMTimeGetSeconds(startTime);
    NSUInteger dHours = floor(dTotalSeconds / 3600);
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);
    NSString *videoDurationText = [NSString stringWithFormat:@"%lu:%02lu:%02lu",(unsigned long)dHours, (unsigned long)dMinutes, (unsigned long)dSeconds];
    NSLog(@"prepareAssetForReading(): startTime = %@", videoDurationText);
    
    
    BOOL ret = YES;
    
    // ===== Audio =====
    // Get the first audio track
    NSArray * arrayTracks = [_asset tracksWithMediaType:AVMediaTypeAudio];
    if (0 < [arrayTracks count]) {
        _playAudio = YES;
        AVAssetTrack* assetTrackAudio = arrayTracks[0];
        
        AVMutableAudioMixInputParameters* audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:1.0f atTime:_playerCursorStartPosition];
        [audioInputParams setTrackID:[assetTrackAudio trackID]];
        
        NSArray* audioParams = @[audioInputParams];
        AVMutableAudioMix* audioMix = [AVMutableAudioMix audioMix];
        [audioMix setInputParameters:audioParams];
        
        AVPlayerItem* item = [_player currentItem];
        [item setAudioMix:audioMix];
    }
    
    return ret;
}



/*
 * Always called with dataLock locked !
 */
- (void)updatePlayerCursorPosition:(float)position
{
    NSLog(@"updatePlayerCursorPosition: %f", position);
    
    // Set the player cursor position so the native player can restart from the appropriate time if play (fullscreen) is called again
    _playerCursorPosition = position;
    
    // Set the requested cursor position to cause the on texture player to seek to the appropriate time if play (on texture) is called again
    _requestedCursorPosition = position;
}



/*
 * Get the current player state
 */
- (MEDIA_STATE)getStatus
{
    return _mediaState;
}



#pragma mark - Alexey's DUMB CODE

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////// OLD Alexey's CODE ///////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)init
{
    NSLog(@"FDPlayerControl :: init()");
    
    if (self = [super init])
    {
        _targetScale = 1.0f;
        _scaleSpeed = 1.4f;
        _scale = 1.0f;
        _texture = 0;
        _imageName = @"ok.png";
        _visible = true;
    }
    return self;
}


- (void)update:(long)delta
{
//    NSLog(@"FDPlayerControl :: update()");
    
    if (delta > 0 && _scale != _targetScale)
    {
        float_t tmp1 = (MIN(MAX_LAG_THRESHOLD, delta) / 1000.0f) * _scaleSpeed;
        float scale_k = MIN(tmp1, ABS(_scale - _targetScale));
        _scale += scale_k * (_scale < _targetScale ? 1.0f : -1.0f);
    }
}


- (void)draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective
{
//    NSLog(@"FDPlayerControl :: draw()");
    
    if(_texture == 0 || !_visible) return;

    glUseProgram(_glProgram);
    GLCheckForError();

    glEnableVertexAttribArray(_worldParams->mPositionParam);
    glEnableVertexAttribArray(_worldParams->mTextureCoordParam);

    glBindBuffer(GL_ARRAY_BUFFER, _texCoord);
    glVertexAttribPointer(_worldParams->mTextureCoordParam, 2, GL_FLOAT, GL_FALSE, 4 * 2, BUFFER_OFFSET(0));

    _modelView = GLKMatrix4Multiply(view, _model);
    _modelViewProjection = GLKMatrix4Multiply(perspective, _modelView);
    _modelViewProjection = GLKMatrix4Scale(_modelViewProjection, _scale, _scale, 1.0f);

    glBindBuffer(GL_ARRAY_BUFFER, _rectangle);
    glVertexAttribPointer(_worldParams->mPositionParam, 3, GL_FLOAT, GL_FALSE, GL_FALSE, BUFFER_OFFSET(0));

    // Set the ModelViewProjection matrix in the shader.
    glUniformMatrix4fv(_worldParams->mModelViewProjectionParam, 1, GL_FALSE, _modelViewProjection.m);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_worldParams->mTextureParam, 0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableVertexAttribArray(_worldParams->mTextureCoordParam);

    GLCheckForError();

    glUseProgram(0);
}


- (void)initControl
{
    NSLog(@"FDPlayerControl :: initControl()");
    
    _glProgram = glCreateProgram();
    [self initShader];
    [self loadResourceTexture];
    _worldParams = [[FDWorldParameters alloc] initWithProgram:_glProgram];
    [self recalculatePosition];
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    if (NO == [self load:@"http://vjs.zencdn.net/v/oceans.mp4" playImmediately:NO fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION]) {
        NSLog(@"Failed to load media");
    } else {
        NSLog(@"OK loaded media");
    }
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}


- (void)dispose
{
    NSLog(@"FDPlayerControl :: dispose()");
    
    [super dispose];
}


- (void)setPosition:(GLfloat)x y:(GLfloat)y z:(GLfloat)z
{
//    NSLog(@"FDPlayerControl :: setPosition()");
    
    [super setPosition:x y:y z:z];
}


- (void)setSize:(GLfloat)width height:(GLfloat)height
{
//    NSLog(@"FDPlayerControl :: setSize()");
    
    [super setSize:width height:height];
}


- (void)setRotation:(GLfloat)angleX angleY:(GLfloat)angleY
{
//    NSLog(@"FDPlayerControl :: setRotation()");
    
    [super setRotation:angleX angleY:angleY];
}


- (bool)isLookingAtObject:(GLKMatrix4)headView
{
//    NSLog(@"FDPlayerControl :: isLookingAtObject()");
    
    if(!_visible) return false;
    return [super isLookingAtObject:headView];
}


- (void)recalculatePosition
{
//    NSLog(@"FDPlayerControl :: recalculatePosition()");
    
    const GLfloat coordsArr[] = {
            _width, -_height, 0.0f,
            -_width, -_height, 0.0f,
            _width, _height, 0.0f,
            -_width, _height, 0.0f
    };

    const GLfloat ttmp[] = {
            1.0f, 1.0f, 0.0f, 1.0f,
            1.0f, 0.0f, 0.0f, 0.0f
    };

    glGenBuffers(1, &_texCoord);
    glBindBuffer(GL_ARRAY_BUFFER, _texCoord);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ttmp), ttmp, GL_STATIC_DRAW);

    glGenBuffers(1, &_rectangle);
    glBindBuffer(GL_ARRAY_BUFFER, _rectangle);
    glBufferData(GL_ARRAY_BUFFER, sizeof(coordsArr), coordsArr, GL_STATIC_DRAW);
}


- (void)loadResourceTexture
{
    NSLog(@"FDPlayerControl :: loadResourceTexture()");
    
    UIImage* image = [UIImage imageNamed:_imageName];
    GLsizei height = (GLsizei)image.size.height;
    GLsizei width = (GLsizei)image.size.width;

    GLubyte* imageData = malloc((size_t) (width * height * 4));
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (size_t) width, (size_t) height, 8, (size_t) (width * 4), colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, image.size.width, image.size.height), image.CGImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorspace);

    GLuint tmp;
    glGenTextures(1, &tmp);
    glBindTexture(GL_TEXTURE_2D, tmp);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    _texture = tmp;
    if(imageData) free(imageData);
}


- (void)initShader
{
    NSLog(@"FDPlayerControl :: initShader()");
    
    GLuint vertexShader = [FDUtils loadShader:@"texture_vertex" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [FDUtils loadShader:@"texture_fragment" type:GL_FRAGMENT_SHADER];

    glAttachShader(_glProgram, vertexShader);
    glAttachShader(_glProgram, fragmentShader);
    GLLinkProgram(_glProgram);

    GLCheckForError();
}


- (void)show
{
//    NSLog(@"FDPlayerControl :: show()");
    
    _visible = true;
}


- (void)hide
{
//    NSLog(@"FDPlayerControl :: hide()");
    
    _visible = false;
}


- (void)focus
{
//    NSLog(@"FDPlayerControl :: focus()");
    
    _targetScale = _scaleSpeed;
}


- (void)unfocus
{
//    NSLog(@"FDPlayerControl :: unfocus()");

    if (_targetScale != 1) {
        _targetScale = 1.0f;
    }
}

@end
