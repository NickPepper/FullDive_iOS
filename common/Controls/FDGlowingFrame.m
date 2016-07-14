//
//  FDGlowingFrame.m
//  FullDive
//
//  Created by Станислав Райцин on 19.06.15.
//
//

#import "FDGlowingFrame.h"
#import "FDUtils.h"

@implementation FDGlowingFrame {
    GLuint _glProgram;
    GLuint _aPositionLocation;
    GLuint _uMVPLocation;
    GLuint _uSizeLocation;
    GLuint _uColorLocation;
    GLuint _uBorderLocation;
    GLuint _uScreenPaddingLocation;
    
    GLfloat _scale;
    GLfloat _border;
    GLfloat _padding;
    UIColor *_color;
    
    GLuint _rectangle;
    
    BOOL _visible;
    BOOL _frozen;
}

static const GLuint COORDS_PER_VERTEX = 3;

- (instancetype)initWithBorder: (GLfloat)border padding: (GLfloat)padding {
    self = [super init];
    if (self) {
        _scale = 1.0f;
        _border = border;
        _padding = padding;
        _color = [UIColor whiteColor];
        _visible = YES;
        _frozen = NO;
    }
    return self;
}

- (void) colorChanged: (UIColor*)color {
    _color = color;
}

#pragma mark - FDIControl methods

- (void) initControl {
    _glProgram = glCreateProgram();
    [self initShader];
    _aPositionLocation = glGetAttribLocation(_glProgram, "a_Position");
    _uMVPLocation = glGetUniformLocation(_glProgram, "u_MVP");
    _uSizeLocation = glGetUniformLocation(_glProgram, "u_Size");
    _uColorLocation = glGetUniformLocation(_glProgram, "u_Color");
    _uBorderLocation = glGetUniformLocation(_glProgram, "u_Border");
    _uScreenPaddingLocation = glGetUniformLocation(_glProgram, "u_ScreenPadding");
    [self recalculatePosition];

}

- (void) setPosition: (GLfloat)x y: (GLfloat)y z: (GLfloat)z {
    [super setPosition:x y:y z:z];
}

- (void) setSize: (GLfloat)width height: (GLfloat)height {
    _width = width + _border;
    _height = height + _border;
}

- (void) setRotation: (GLfloat)angleX angleY: (GLfloat)angleY {
    [super setRotation:angleX angleY:angleY];
}

- (void) update: (long) delta {
    
}

- (void) draw: (GLKMatrix4)view headView: (GLKMatrix4)headView perspective: (GLKMatrix4)perspective {
    if(!_visible) return;
    
    glUseProgram(_glProgram);
    GLCheckForError();
    
    glEnableVertexAttribArray(_aPositionLocation);
    GLCheckForError();

    glBindBuffer(GL_ARRAY_BUFFER, _rectangle);
    glVertexAttribPointer(_aPositionLocation, COORDS_PER_VERTEX, GL_FLOAT, GL_FALSE, GL_FALSE, BUFFER_OFFSET(0));
    
    if (!_frozen) {
        _modelView = GLKMatrix4Multiply(view, _model);
        _modelViewProjection = GLKMatrix4Multiply(perspective, _modelView);
    } else {
        _modelViewProjection = GLKMatrix4Multiply(perspective, _model);
    }
    
    _modelViewProjection = GLKMatrix4Scale(_modelViewProjection, _scale, _scale, 1.0f);
    
    // Set the ModelViewProjection matrix in the shader.
    glUniformMatrix4fv(_uMVPLocation, 1, GL_FALSE, _modelViewProjection.m);
    glUniform2f(_uSizeLocation, _width, _height);
    CGColorRef colorRef = _color.CGColor;
    const CGFloat *components = CGColorGetComponents(colorRef);
    glUniform3f(_uColorLocation, components[0], components[1], components[2]);
    glUniform1f(_uBorderLocation, _border);
    glUniform1f(_uScreenPaddingLocation, _padding);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
    GLCheckForError();
    glDisable(GL_BLEND);
    glUseProgram(0);
}

- (void) dispose {
    [super dispose];
}


- (bool)isLookingAtObject:(GLKMatrix4)headView {
    if(!_visible) return false;
    return [super isLookingAtObject:headView];
}

- (void) show {
    _visible = true;
}

- (void) hide {
    _visible = false;
}

- (void) focus {
}

- (void) unfocus {
}

- (void) click {
}


#pragma mark - FDIFreezeControlHandler methods

- (void) freeze {
    _frozen = YES;
}

- (void) unfreeze {
    _frozen = NO;
}

#pragma mark - Private methods

- (void) initShader {
    GLuint vertexShader = [FDUtils loadShader:@"glowing_wall_vertex" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [FDUtils loadShader:@"glowing_wall_fragment" type:GL_FRAGMENT_SHADER];
    
    glAttachShader(_glProgram, vertexShader);
    glAttachShader(_glProgram, fragmentShader);
    GLLinkProgram(_glProgram);
    
    GLCheckForError();
}

-(void)recalculatePosition {
    const GLfloat coordsArr[] = {
        _width, -_height, 0.0f,
        -_width, -_height, 0.0f,
        _width, _height, 0.0f,
        -_width, _height, 0.0f
    };
    
    glGenBuffers(1, &_rectangle);
    glBindBuffer(GL_ARRAY_BUFFER, _rectangle);
    glBufferData(GL_ARRAY_BUFFER, sizeof(coordsArr), coordsArr, GL_STATIC_DRAW);
}

@end