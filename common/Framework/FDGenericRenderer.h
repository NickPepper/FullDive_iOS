#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/glext.h>
#include "CardboardSDK.h"
#import "SwiftBridge.h"
#import "FDIControl.h"

@interface FDGenericRenderer : NSObject
{
    GLKMatrix4 _perspective;
    GLKMatrix4 _model;
    GLKMatrix4 _camera;
    GLKMatrix4 _view;
    GLKMatrix4 _headView;
    
    float _cameraZ;
    float _timeDelta;

    float _objectDistance;
}

- (instancetype)initWithControl: (FullDiveAppManager *) ctrl;
- (void)setupRendererWithView:(GLKView *)glView;
- (void) shutdownRendererWithView:(GLKView *)glView;
- (void) prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix;
- (void) drawEyeWithEye:(CBDEye *)eye;
- (void) finishFrameWithViewportRect:(CGRect)viewPort;
- (void) renderViewDidChangeSize:(CGSize)size;
- (void) click;

@end