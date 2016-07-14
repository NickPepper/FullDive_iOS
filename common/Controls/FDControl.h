//
// Created by Alexey Suvorov on 4/13/15.
//

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#import <Foundation/Foundation.h>
#import "FDIControl.h"

@interface FDControl : NSObject <FDIControl> {
    @protected GLKMatrix4 _modelViewProjection;
    @protected GLKMatrix4 _modelView;
    @protected GLKMatrix4 _model;

    @protected GLfloat _x;
    @protected GLfloat _y;
    @protected GLfloat _z;

    @protected GLfloat _width;
    @protected GLfloat _height;

    @protected GLfloat _angleX;
    @protected GLfloat _angleY;
    @protected Boolean _focusable;

}

@property (nonatomic, assign) id <FDClickDelegate> delegate;

-(void) setPosition: (GLfloat) x
                  y: (GLfloat) y
                  z: (GLfloat) z;

-(void) setSize: (GLfloat) width
         height: (GLfloat) height;

-(void) setRotation: (GLfloat) angleX
             angleY: (GLfloat) angleY;

-(bool) isLookingAtObject: (GLKMatrix4) headView;

-(void) dispose;

-(void) focus;

-(void) unfocus;

-(void) click;
@end