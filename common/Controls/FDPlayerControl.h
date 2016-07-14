//
//  FDPlayerControl.h
//  FullDive
//
//  Created by Alexey Suvorov on 06/26/15.
//  Completed by Nick Pershin on 07/06/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FDIControl.h"
#import "FDControl.h"

// ------------------- Constants -----------------------------

static const float_t MAX_LAG_THRESHOLD = 5000.0f;
static const float PLAYER_VOLUME_DEFAULT = 1.0f;

static NSString* const kStatusKey   = @"status";
static NSString* const kTracksKey   = @"tracks";
static NSString* const kRateKey     = @"rate";

// Used to specify that playback should start
// from the current position when calling the load and play methods.
static const float VIDEO_PLAYBACK_CURRENT_POSITION = -1.0f;

// Media states
typedef enum tagMEDIA_STATE {
    REACHED_END,
    PAUSED,
    STOPPED,
    PLAYING,
    READY,
    PLAYING_FULLSCREEN,
    NOT_READY,
    ERROR
} MEDIA_STATE;




// ------------------- Interface -----------------------------

@interface FDPlayerControl : FDControl <FDIControl>

@property (nonatomic) AVPlayerItemVideoOutput *videoOutput;

- (BOOL)load:(NSString*)videoURL playImmediately:(BOOL)playOnTextureImmediately fromPosition:(float)seekPosition;
- (BOOL)loadMediaURL:(NSURL*)url;
//- (BOOL)loadLocalMediaFromURL:(NSURL*)url;
- (BOOL)prepareAssetForPlayback;

// the stuff from https://docs.google.com/document/d/1yueRzXM91fWTAQY9q_aoAsxG7Gj4fTVQ5rd75zwWwAo/edit?pli=1
/*
 - (void) setSource: (NSURL *) url;
 - (void) setSurface: (GLuint) textureId;// TODO: not sure, maybe is should be a callback
 - (void) reset;
 - (void) play;
 - (void) pause;
 - (float) getStreamLength;
 //- (void) setStreamPosition: (float) position;
 //- (void) setVolumeLevel: (int) percent;
 //- (int) getVolumeLevel;
 */


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////// OLD Alexey's methods ////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)init;
- (void)recalculatePosition;
- (void)initControl;
- (void)update:(long)delta;
- (void)draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective;
- (void)focus;
- (void)unfocus;

@end
