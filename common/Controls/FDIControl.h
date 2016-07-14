#import <Foundation/Foundation.h>
#include "CardboardSDK.h"

#import <OpenGLES/ES2/glext.h>

@protocol FDClickDelegate;

@protocol FDIControl
- (void) update: (long) delta;

- (void) draw: (GLKMatrix4) view
     headView:(GLKMatrix4) headView
  perspective: (GLKMatrix4) perspective;

- (void) initControl;

- (void) dispose;

-(void) setPosition: (GLfloat) x
                  y: (GLfloat) y
                  z: (GLfloat) z;

-(void) setSize: (GLfloat) width
         height: (GLfloat) height;

-(void) setRotation: (GLfloat) angleX
             angleY: (GLfloat) angleY;

-(bool) isLookingAtObject: (GLKMatrix4) headView;

-(void) recalculatePosition;

-(void) focus;

-(void) unfocus;

-(void) show;

-(void) hide;

- (void) click;

@property (nonatomic, assign) id <FDClickDelegate> delegate;

@end


@protocol FDClickDelegate <NSObject>
@optional
- (void) click: (id<FDIControl>)sender;
@end
