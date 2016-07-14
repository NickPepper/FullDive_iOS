//
//  FDGlowingFrame.h
//  FullDive
//
//  Created by Станислав Райцин on 19.06.15.
//
//

#import <Foundation/Foundation.h>
#import "FDControl.h"
#import "FDIFreezeControlHandler.h"

@interface FDGlowingFrame : FDControl <FDIFreezeControlHandler>
- (instancetype)initWithBorder: (GLfloat)border padding: (GLfloat)padding;
- (void) update: (long) delta;
- (void) draw: (GLKMatrix4)view headView: (GLKMatrix4)headView perspective: (GLKMatrix4)perspective;
- (void) initControl;
- (void) dispose;
- (void) setPosition: (GLfloat)x y: (GLfloat)y z: (GLfloat)z;
- (void) setSize: (GLfloat)width height: (GLfloat)height;
- (void) setRotation: (GLfloat)angleX angleY: (GLfloat)angleY;
- (bool) isLookingAtObject: (GLKMatrix4) headView;
- (void) recalculatePosition;
- (void) focus;
- (void) unfocus;
- (void) show;
- (void) hide;
- (void) click;
- (void) freeze;
- (void) unfreeze;
- (void) colorChanged: (UIColor*)color;
@end
