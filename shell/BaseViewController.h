#import <UIKit/UIKit.h>
#import "CardboardSDK.h"
#import "SwiftBridge.h"


@protocol FDIControl;

@interface BaseViewController : CBDViewController
-(void) setControl: (FullDiveAppManager*) ctrl;
@end
