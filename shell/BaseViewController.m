#import "BaseViewController.h"
#import "FDGenericRenderer.h"
#import <AudioToolbox/AudioServices.h>

@interface BaseViewController() <CBDStereoRendererDelegate>
@property (nonatomic) FDGenericRenderer *renderer;
@end


@implementation BaseViewController{
    FullDiveAppManager* _ctrl;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {return nil; }
    self.stereoRendererDelegate = self;
    return self;
}

-(void) setControl: (FullDiveAppManager*) ctrl
{
    _ctrl = ctrl;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    if(nil == _ctrl) @throw @"Control is no initialized";

    self.renderer = [[FDGenericRenderer alloc] initWithControl: _ctrl];
    [self.renderer setupRendererWithView:glView];
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
    [self.renderer shutdownRendererWithView:glView];
}

- (void)renderViewDidChangeSize:(CGSize)size
{
    [self.renderer renderViewDidChangeSize:size];
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    [self.renderer prepareNewFrameWithHeadViewMatrix:headViewMatrix];
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    [self.renderer drawEyeWithEye:eye];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
    [self.renderer finishFrameWithViewportRect:viewPort];
}

- (void)magneticTriggerPressed
{
    [self.renderer click];
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.renderer click];
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

@end
