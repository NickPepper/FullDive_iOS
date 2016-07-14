//
// Created by Alexey Suvorov on 4/13/15.
//

#import <GLKit/GLKit.h>
#import "FDControl.h"
#import "FDIControl.h"

@implementation FDControl {
    GLKVector3 _rayVectorStart;
    GLKVector3 _rayVectorDirect;
}

-(FDControl *)init {
    self = [super init];
    if (!self) { return nil; }

    _rayVectorStart = GLKVector3Make(0.0f, 0.0f, 1.0f);
    _rayVectorDirect = GLKVector3Make(0.0f, 0.0f, 0.0f);

    _x = 0;
    _y = 0;
    _z = 0;

    _width = 3;
    _height = 3;
    _focusable = true;

    return self;
};

-(void) setPosition: (GLfloat) x
                  y: (GLfloat) y
                  z: (GLfloat) z
{
    _model = GLKMatrix4Identity;
    _model = GLKMatrix4Translate(_model, x, y, z);

    _x = x;
    _y = y;
    _z = z;
}


-(void) setSize: (GLfloat) width
         height: (GLfloat) height
{
    _width = width / 2.0f;
    _height = height / 2.0f;
}

-(void) setRotation: (GLfloat) angleX
             angleY: (GLfloat) angleY
{
    _angleX = (float) (((double)angleX * 180.0) / M_PI);
    _angleY = (float) (((double)angleY * 180.0) / M_PI);

    _model = GLKMatrix4Identity;
    if(_angleY != 0.0f){
        _model = GLKMatrix4Rotate(_model, _angleY, 0, 1, 0);
    }

    if(_angleX != 0.0f){
        _model = GLKMatrix4Rotate(_model, _angleX, 1, 0, 0);
    }

    _model = GLKMatrix4Translate(_model, _x, _y, _z);
}

-(bool) isLookingAtObject: (GLKMatrix4) headView {
    GLKVector3 cursor = [self getCursorPosition:headView];
    return cursor.z >= 0.0;
}

-(GLKVector3) getCursorPosition: (GLKMatrix4) headView {
    _modelView = GLKMatrix4Multiply(headView, _model);

    GLKVector4 s1Vec = GLKVector4Make(_width, -_height, 0, 1.0);
    GLKVector4 s2Vec = GLKVector4Make(_width, _height, 0, 1.0);
    GLKVector4 s3Vec = GLKVector4Make(-_width, -_height, 0, 1.0);

    GLKVector4 objS1Vec = GLKMatrix4MultiplyVector4(_modelView, s1Vec);
    GLKVector4 objS2Vec = GLKMatrix4MultiplyVector4(_modelView, s2Vec);
    GLKVector4 objS3Vec = GLKMatrix4MultiplyVector4(_modelView, s3Vec);

    GLKVector3 s1 = GLKVector3Make(objS1Vec.x, objS1Vec.y, objS1Vec.z);
    GLKVector3 s2 = GLKVector3Make(objS2Vec.x, objS2Vec.y, objS2Vec.z);
    GLKVector3 s3 = GLKVector3Make(objS3Vec.x, objS3Vec.y, objS3Vec.z);

    return [self intersectRayWithSquare:s1 s2:s2 s3:s3];
}

-(GLKVector3) intersectRayWithSquare: (GLKVector3) s1
                                  s2: (GLKVector3) s2
                                  s3: (GLKVector3) s3
{
    GLKVector3 R1 = _rayVectorStart;
    GLKVector3 R2 = _rayVectorDirect;

    GLKVector3 dS21 = GLKVector3Subtract(s2, s1);
    GLKVector3 dS31 = GLKVector3Subtract(s3, s1);
    GLKVector3 n = GLKVector3CrossProduct(dS21, dS31);

    GLKVector3 dr = GLKVector3Subtract(R1, R2);

    float_t ndotdR = GLKVector3DotProduct(n, dr);

    if (ABS(ndotdR) >= 1e-25f) { // Choose your tolerance
        GLKVector3 tmp = GLKVector3Subtract(R1, s1);

        float_t t = -GLKVector3DotProduct(n, tmp) / ndotdR;
        dr = GLKVector3MultiplyScalar(dr, t);
        GLKVector3 M = GLKVector3Make(R1.x + dr.x, R1.y + dr.y, R1.z + dr.z);

        GLKVector3 dMS1 = GLKVector3Subtract(M, s1);
        float_t u = GLKVector3DotProduct(dMS1, dS21);
        float_t v = GLKVector3DotProduct(dMS1, dS31);

        float_t max_u = GLKVector3DotProduct(dS21, dS21);
        float_t max_v = GLKVector3DotProduct(dS31, dS31);


        //return (u >= 0.0 && u <= dS21.dot(dS21) && v >= 0.0 && v <= dS31.dot(dS31) && t < 0);
        if (t < 0 &&  u >= 0.0f && max_u > u && max_v > v && u <= max_u && v >= 0.0 && v <= max_v) {
            return GLKVector3Make((u / max_u), (v / max_v), 0.0);
        }
    }

    return GLKVector3Make(0, 0, -1);;
}

- (void) recalculatePosition{
}

- (void) initControl{
}

- (void) draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective{
}

-(void) update:(long)delta{
}

-(void) dispose {
}

-(void)focus {
}

-(void)unfocus {
}


-(void)hide {
}

-(void)show {
}

-(void) click{
    [self.delegate click:self];
}

@end