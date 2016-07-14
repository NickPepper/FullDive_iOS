//
// Created by Alexey Suvorov on 4/21/15.
//

#import <Foundation/Foundation.h>


@interface FDWorldParameters : NSObject{
    @public GLint mPositionParam;
    @public GLint mTextureCoordParam;
    @public GLint mTextureParam;
    @public GLint mNormalParam;
    @public GLint mColorParam;
    @public GLint mModelViewProjectionParam;
    @public GLint mLightPosParam;
    @public GLint mModelViewParam;
    @public GLint mModelParam;
    @public GLint mIsFloorParam;
}
-(instancetype)initWithProgram: (GLuint) glPrograms;
@end

