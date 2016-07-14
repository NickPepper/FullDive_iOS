//
//  FDIFreezeControlHandler.h
//  FullDive
//
//  Created by Станислав Райцин on 21.06.15.
//
//

#import <Foundation/Foundation.h>

@protocol FDIFreezeControlHandler
- (void) freeze;
- (void) unfreeze;
@end
