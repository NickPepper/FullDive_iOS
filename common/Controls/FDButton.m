#import "FDImage.h"
#import "FDButton.h"
#import "FDUtils.h"
#import "FDWorldParameters.h"

@implementation FDButton {
    GLuint _glProgram;
    GLuint _texture;
    NSString *_imageName;
    FDWorldParameters *_worldParams;

    float_t _scale;
    float_t _targetScale;
    float_t _scaleSpeed;

    GLuint _texCoord;
    GLuint _rectangle;

    BOOL _visible;
}

static float_t MAX_LAG_THRESHOLD = 5000.0f;

- (instancetype)initWithResourceImage: (NSString*) name {
    self = [super init];
    if (self) {
        _targetScale = 1.0f;
        _scaleSpeed = 1.4f;
        _scale = 1.0f;
        _texture = 0;
        _imageName = name;
        _visible = true;
    }
    return self;
}

- (void)update:(long)delta {
    if (delta > 0 && _scale != _targetScale) {
        float_t tmp1 = (MIN(MAX_LAG_THRESHOLD, delta) / 1000.0f) * _scaleSpeed;
        float scale_k = MIN(tmp1, ABS(_scale - _targetScale));
        _scale += scale_k * (_scale < _targetScale ? 1.0f : -1.0f);
    }
}

- (void)draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective {
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

-(void)initControl {
    _glProgram = glCreateProgram();
    [self initShader];
    [self loadResourceTexture];
    _worldParams = [[FDWorldParameters alloc] initWithProgram:_glProgram];
    [self recalculatePosition];
}

- (void)dispose {
    [super dispose];
}

- (void)setPosition:(GLfloat)x y:(GLfloat)y z:(GLfloat)z {
    [super setPosition:x y:y z:z];
}

- (void)setSize:(GLfloat)width height:(GLfloat)height {
    [super setSize:width height:height];
}

- (void)setRotation:(GLfloat)angleX angleY:(GLfloat)angleY {
    [super setRotation:angleX angleY:angleY];
}

- (bool)isLookingAtObject:(GLKMatrix4)headView {
    if(!_visible) return false;
    return [super isLookingAtObject:headView];
}

-(void)recalculatePosition {
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


-(void) loadResourceTexture {
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

-(void) initShader{
    GLuint vertexShader = [FDUtils loadShader:@"texture_vertex" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [FDUtils loadShader:@"texture_fragment" type:GL_FRAGMENT_SHADER];

    glAttachShader(_glProgram, vertexShader);
    glAttachShader(_glProgram, fragmentShader);
    GLLinkProgram(_glProgram);

    GLCheckForError();
}

-(void) show {
    _visible = true;
}

-(void) hide {
    _visible = false;
}

-(void) focus {
    _targetScale = _scaleSpeed;
}

-(void) unfocus {
    if (_targetScale != 1) {
        _targetScale = 1.0f;
    }
}

@end