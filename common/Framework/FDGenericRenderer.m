#import "FDGenericRenderer.h"

@implementation FDGenericRenderer{
    FullDiveAppManager* _ctrl;
    double_t _lastUpdateTime;
}

- (instancetype)initWithControl: (FullDiveAppManager*) ctrl
{
    self = [super init];
    if (!self) { return nil; }

    _ctrl = ctrl;
    _objectDistance = 12.0f;
    _cameraZ = 0.01f;
    _timeDelta = 1.0f;
    _lastUpdateTime = 0.0;
    
    return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    [EAGLContext setCurrentContext:glView.context];
    
    // Etc
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Dark background so text shows up well.

    // Object first appears directly in front of user.
    _model = GLKMatrix4Identity;
    _model = GLKMatrix4Translate(_model, 0, 0, -_objectDistance);

    [_ctrl initApp];

    GLCheckForError();
}


- (void)shutdownRendererWithView:(GLKView *)glView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    double_t time = [NSDate timeIntervalSinceReferenceDate] * 1000;
    if (_lastUpdateTime != 0) {
        long delta = (long)(time - _lastUpdateTime);
        [_ctrl update:delta];
    }

    _lastUpdateTime = time;

    // Build the Model part of the ModelView matrix
    _model = GLKMatrix4Rotate(_model, GLKMathDegreesToRadians(_timeDelta), 0.5f, 0.5f, 1.0f);
    
    // Build the camera matrix and apply it to the ModelView.
    _camera = GLKMatrix4MakeLookAt(0, 0, _cameraZ,
                                   0, 0, 0,
                                   0, 1.0f, 0);
    _headView = headViewMatrix;
    
    GLCheckForError();
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLCheckForError();
    
    // Apply the eye transformation to the camera
    _view = GLKMatrix4Multiply([eye eyeViewMatrix], _camera);
    
    const float zNear = 0.1f;
    const float zFar = 100.0f;
    _perspective = [eye perspectiveMatrixWithZNear:zNear zFar:zFar];

    [_ctrl draw:_view headView:_headView perspective:_perspective];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}

// Check if user is looking at object by calculating where the object is in eye-space.
// @return true if the user is looking at the object.
//- (BOOL)isLookingAtCube
//{
//    GLKVector4 initVector = { 0, 0, 0, 1.0f };
//
//    // Convert object space to camera space. Use the headView from onNewFrame.
//    _modelView = GLKMatrix4Multiply(_headView, _model);
//    GLKVector4 objectPositionVector = GLKMatrix4MultiplyVector4(_modelView, initVector);
//
//    float pitch = atan2f(objectPositionVector.y, -objectPositionVector.z);
//    float yaw = atan2f(objectPositionVector.x, -objectPositionVector.z);
//
//    const float yawLimit = 0.12f;
//    const float pitchLimit = 0.12f;
//
//    return fabs(pitch) < pitchLimit && fabs(yaw) < yawLimit;
//}

-(void)click {
    [_ctrl click];
}

@end
