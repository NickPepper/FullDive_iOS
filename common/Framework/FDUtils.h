//
// Created by Alexey Suvorov on 4/21/15.
//

#import <Foundation/Foundation.h>
#import "GLHelpers.h"

@interface FDUtils : NSObject

+(GLuint)loadShader: (NSString*)resourcePath
               type: (GLenum) type;

+(void) drawCross: (float) x
                y: (float) y;
@end