#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FDControl.h"
#import <CoreVideo/CoreVideo.h>

@interface OGLCameraControl : FDControl <FDIControl>
// custom public methods
- (instancetype)init;
- (void) updatePixelBuffer: (CVPixelBufferRef) pixelBuffer;
- (void) saveCurrentPixelBuffer;
// inherited methods
- (void) recalculatePosition;
- (void) initControl;
- (void) draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective;
@end
