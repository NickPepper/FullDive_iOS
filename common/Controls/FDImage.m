//
// Created by Alexey Suvorov on 4/14/15.
//

#import "FDImage.h"
#import "FDUtils.h"
#import "FDWorldParameters.h"

@implementation FDImage {
    GLuint _glProgram;
    GLuint _texture;
    
    FDWorldParameters *_worldParams;
    GLfloat _pivot_x;
    GLfloat _pivot_y;

    GLuint _texCoord;
    GLuint _rectangle;
    
    // one time used variables
    // for async texture loading
    UIImage * _image;
    GLubyte * _imageData;
    CGSize _imageSize;
    BOOL _visible;
}

- (instancetype)initWithImage: (UIImage*) image {
    self = [super init];
    if (self) {
        _image = image;
        _visible = true;
        [self __init];
    }
    return self;
}

-(void) __init{
    _pivot_x = -1.0f;
    _pivot_y = -1.0f;
    _texture = 0;

}

- (void)update:(long)delta {

}

- (void)draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective {
    if(_texture == 0 || !_visible) {
        return;
    }

    glUseProgram(_glProgram);
    GLCheckForError();

    glEnableVertexAttribArray(_worldParams->mPositionParam);
    glEnableVertexAttribArray(_worldParams->mTextureCoordParam);

    glBindBuffer(GL_ARRAY_BUFFER, _texCoord);
    glVertexAttribPointer(_worldParams->mTextureCoordParam, 2, GL_FLOAT, GL_FALSE, 4 * 2, BUFFER_OFFSET(0));

    _modelView = GLKMatrix4Multiply(view, _model);
    _modelViewProjection = GLKMatrix4Multiply(perspective, _modelView);

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

    //glBindVertexArrayOES(0);
    glUseProgram(0);
}

- (void)initControl {
    _glProgram = glCreateProgram();
    [self initShaders];
    [self loadResourceTexture];
    _worldParams = [[FDWorldParameters alloc] initWithProgram:_glProgram];
    [self recalculatePosition];
}

- (void)dispose {
    [super dispose];
    glDeleteTextures(1, &_texture);
    glDeleteProgram(_glProgram);
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
    GLfloat px;
    GLfloat py;
    if (_pivot_x >= 0.0f && _pivot_y >= 0.0f) {
        px = _pivot_x;
        py = _pivot_y;
    } else {
        px = _width;
        py = _height;
    }

    GLfloat w2 = _width * 2.0f;
    GLfloat h2 = _height * 2.0f;

    const GLfloat coordsArr[] =
    {
        (w2 - px),  -py,        0.0f,
        -px,        -py,        0.0f,
        (w2 - px),  (h2 - py),  0.0f,
        -px,        (h2 - py),  0.0f,
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

- (void)focus {
    [super focus];
}

- (void)unfocus {
    [super unfocus];
}

- (void)show {
    _visible = true;
}

- (void)hide {
    _visible = false;
}

-(void)loadResourceTexture {
    _imageSize = _image.size;

    GLsizei height = (GLsizei) _imageSize.height;
    GLsizei width = (GLsizei) _imageSize.width;

    _imageData = malloc((size_t) (width * height * 4));
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(_imageData, (size_t) width, (size_t) height, 8, (size_t) (width * 4), colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, _image.size.width, _image.size.height), _image.CGImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorspace);

    GLuint tmp;
    glGenTextures(1, &tmp);
    glBindTexture(GL_TEXTURE_2D, tmp);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _imageData);

    _imageData = nil;
    _image = nil;
    _texture = tmp;

    if(_imageData) free(_imageData);
}

-(void) initShaders{
    GLuint vertexShader = [FDUtils loadShader:@"texture_vertex" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [FDUtils loadShader:@"texture_fragment" type:GL_FRAGMENT_SHADER];

    glAttachShader(_glProgram, vertexShader);
    glAttachShader(_glProgram, fragmentShader);
    GLLinkProgram(_glProgram);

    GLCheckForError();
}

@end