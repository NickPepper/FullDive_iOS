#import "OGLCameraControl.h"
#import <OpenGLES/EAGL.h>
#import "FDWorldParameters.h"
#import "FDUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@interface OGLCameraControl () {
    GLuint _glProgram;
    FDWorldParameters *_worldParams;
	CVOpenGLESTextureCacheRef _textureCache;
    CVPixelBufferRef pixelBuffer;
    GLuint _texCoord;
    GLuint _rectangle;
}
@end

@implementation OGLCameraControl

- (instancetype) init {
    self = [super init];
    if (self) {
    }
    return self;
}


-(void)initControl {
    [self setSize:14.0f height:14.0f * 0.5625]; // проверить разрешение с камеры
    [self setPosition:0.0f y:0.0f z:-5.0f];
    _glProgram = glCreateProgram();
    [self initShader];
    [self initTextureCache];
    _worldParams = [[FDWorldParameters alloc] initWithProgram:_glProgram];
    [self recalculatePosition];
}

- (void)initTextureCache {
    //  Create a new CVOpenGLESTexture cache
    CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &_textureCache );
    if ( err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
    }
}

- (void) updatePixelBuffer: (CVPixelBufferRef) pBufferRef {
    if (pixelBuffer) CFRelease(pixelBuffer);
    pixelBuffer = pBufferRef;
}


- (void) draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective {
    
    if ( pixelBuffer == NULL ) {
        return;
    }
    
    // Create a CVOpenGLESTexture from a CVPixelBufferRef
    CVOpenGLESTextureRef texture = NULL;
    size_t frameHeight = CVPixelBufferGetHeight( pixelBuffer );
    size_t frameWidth = CVPixelBufferGetWidth( pixelBuffer );
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
                                                                _textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (GLsizei)frameWidth,
                                                                (GLsizei)frameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture );
    if ( ! texture || err ) {
        NSLog( @"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err );
        return;
    }
    glUseProgram(_glProgram);
    GLCheckForError();
    glEnableVertexAttribArray(_worldParams->mPositionParam);
    glEnableVertexAttribArray(_worldParams->mTextureCoordParam);
    
    glBindBuffer(GL_ARRAY_BUFFER, _texCoord);
    glVertexAttribPointer(_worldParams->mTextureCoordParam, 2, GL_FLOAT, GL_FALSE, 4 * 2, BUFFER_OFFSET(0));
    
    _modelViewProjection = GLKMatrix4Multiply(perspective, _model);
    
    glBindBuffer(GL_ARRAY_BUFFER, _rectangle);
    glVertexAttribPointer(_worldParams->mPositionParam, 3, GL_FLOAT, GL_FALSE, GL_FALSE, BUFFER_OFFSET(0));
    
    // Set the ModelViewProjection matrix in the shader.
    glUniformMatrix4fv(_worldParams->mModelViewProjectionParam, 1, GL_FALSE, _modelViewProjection.m);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture( CVOpenGLESTextureGetTarget( texture ), CVOpenGLESTextureGetName( texture ) );

    glUniform1i(_worldParams->mTextureParam, 0);
    // Set texture parameters
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableVertexAttribArray(_worldParams->mTextureCoordParam);
    
    GLCheckForError();
    
    glUseProgram(0);
    glBindTexture( CVOpenGLESTextureGetTarget( texture ), 0 );
    glBindTexture( GL_TEXTURE_2D, 0 );
    CFRelease( texture );
}

- (void)flushPixelBufferCache {
	if ( _textureCache ) {
		CVOpenGLESTextureCacheFlush(_textureCache, 0);
	}
}

-(void) initShader{
    GLuint vertexShader = [FDUtils loadShader:@"texture_vertex" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [FDUtils loadShader:@"texture_fragment" type:GL_FRAGMENT_SHADER];
    
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

- (void)dispose {
    [super dispose];
    glDeleteProgram( _glProgram );
    CFRelease(pixelBuffer);
    CFRelease( _textureCache );
}

- (void) saveCurrentPixelBuffer {
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
    ciImage = [ciImage imageByApplyingTransform: transform];
    CGImageRef cgimg = [temporaryContext createCGImage:ciImage fromRect:[ciImage extent]];
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeImageToSavedPhotosAlbum:cgimg metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        CGImageRelease(cgimg);
    }];
}



@end
