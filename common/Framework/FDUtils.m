//
// Created by Alexey Suvorov on 4/14/15.
//

#import <GLKit/GLKit.h>
#import "FDUtils.h"
#import "GLHelpers.h"

@implementation FDUtils

+(GLuint)loadShader: (NSString*)resourcePath
               type: (GLenum) type {

    GLuint shader = 0;
    NSString * path = [[NSBundle mainBundle] pathForResource:resourcePath ofType:@"shader"];
    if (!GLCompileShaderFromFile(&shader, type, path)) {
        NSLog(@"Failed to compile shader at %@", path);
    }

    return shader;
}

+(void) drawCross: (float) x
                y: (float) y{
    //!! draw cross, debug only
    // ================================
    const GLfloat line1[] =
    {
            y, x - 1.0f, //point A
            y, x + 1.0f, //point B
    };

    // Create an handle for a buffer object array
    GLuint bufferObjectNameArray;

    // Have OpenGL generate a buffer name and store it in the buffer object array
    glGenBuffers(1, &bufferObjectNameArray);

    // Bind the buffer object array to the GL_ARRAY_BUFFER target buffer
    glBindBuffer(GL_ARRAY_BUFFER, bufferObjectNameArray);

    // Send the line data over to the target buffer in GPU RAM
    glBufferData(
            GL_ARRAY_BUFFER,   // the target buffer
            sizeof(line1),      // the number of bytes to put into the buffer
            line1,              // a pointer to the data being copied
            GL_STATIC_DRAW);   // the usage pattern of the data


    // Enable vertex data to be fed down the graphics pipeline to be drawn
    glEnableVertexAttribArray(GLKVertexAttribPosition);

    // Specify how the GPU looks up the data
    glVertexAttribPointer(
            GLKVertexAttribPosition, // the currently bound buffer holds the data
            2,                       // number of coordinates per vertex
            GL_FLOAT,                // the data type of each component
            GL_FALSE,                // can the data be scaled
            2*4,                     // how many bytes per vertex (2 floats per vertex)
            NULL);                   // offset to the first coordinate, in this case 0

    glDrawArrays(GL_LINES, 0, 2); // render

    const GLfloat line2[] =
            {
                    y + 1.0f, x, //point A
                    y - 1.0f, x, //point B
            };

    // Create an handle for a buffer object array

    // Have OpenGL generate a buffer name and store it in the buffer object array
    glGenBuffers(1, &bufferObjectNameArray);

    // Bind the buffer object array to the GL_ARRAY_BUFFER target buffer
    glBindBuffer(GL_ARRAY_BUFFER, bufferObjectNameArray);

    // Send the line data over to the target buffer in GPU RAM
    glBufferData(
            GL_ARRAY_BUFFER,   // the target buffer
            sizeof(line2),      // the number of bytes to put into the buffer
            line2,              // a pointer to the data being copied
            GL_STATIC_DRAW);   // the usage pattern of the data

    // Enable vertex data to be fed down the graphics pipeline to be drawn
    glEnableVertexAttribArray(GLKVertexAttribPosition);

    // Specify how the GPU looks up the data
    glVertexAttribPointer(
            GLKVertexAttribPosition, // the currently bound buffer holds the data
            2,                       // number of coordinates per vertex
            GL_FLOAT,                // the data type of each component
            GL_FALSE,                // can the data be scaled
            2*4,                     // how many bytes per vertex (2 floats per vertex)
            NULL);                   // offset to the first coordinate, in this case 0

    glDrawArrays(GL_LINES, 0, 2); // render
    // ================================
}

@end