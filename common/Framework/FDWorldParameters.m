//
// Created by Alexey Suvorov on 4/21/15.
//
#import <OpenGLES/ES2/glext.h>
#import "FDWorldParameters.h"


@implementation FDWorldParameters

-(instancetype)initWithProgram: (GLuint) glPrograms {
    self = [super init];
    if (self) {
        mTextureParam = glGetAttribLocation(glPrograms, "v_Texture");
        mTextureCoordParam = glGetAttribLocation(glPrograms, "v_TextCoord");
        mModelViewProjectionParam = glGetUniformLocation(glPrograms, "u_MVP");
        mLightPosParam = glGetUniformLocation(glPrograms, "u_LightPos");
        mModelViewParam = glGetUniformLocation(glPrograms, "u_MVMatrix");
        mModelParam = glGetUniformLocation(glPrograms, "u_Model");
        mIsFloorParam = glGetUniformLocation(glPrograms, "u_IsFloor");
        mPositionParam = glGetAttribLocation(glPrograms, "a_Position");
        mNormalParam = glGetAttribLocation(glPrograms, "a_Normal");
        mColorParam = glGetAttribLocation(glPrograms, "u_Color");
    }

    return self;
}
@end