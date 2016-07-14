//
// Created by Alexey Suvorov on 4/14/15.
//

#import <Foundation/Foundation.h>
#import "FDControl.h"
#import "FDIControl.h"


@interface FDImage : FDControl <FDIControl>
- (instancetype)initWithImage: (UIImage*) image;
- (void) recalculatePosition;
- (void) initControl;
- (void) update:(long)delta;
- (void) draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective;
- (void) focus;
- (void) unfocus;

@end