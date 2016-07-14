import Foundation

class CameraController : NSObject, IDrawableControl, CameraCapturePipelineDelegate {
    
    var cameraCapturePipeline : CameraCapturePipeline;
    var cameraScreen: CameraScreen;
    var cameraMenuScreen: CameraMenuScreen?;
    var _homeCallback: EmptyDelegate?
    var _galleryCallback: EmptyDelegate?
    var shouldExecuteDispatchBlock : Bool;
    var isMenuScreenShown: Bool;
    var delayed_task_counter : UInt;
    var latestTapTime : Double;
    
    override init() {
        self.cameraCapturePipeline = CameraCapturePipeline();
        self.cameraScreen = CameraScreen();
        self.shouldExecuteDispatchBlock = true;
        self.isMenuScreenShown = false;
        latestTapTime = 0;
        delayed_task_counter = 0;
        super.init();
        self.cameraMenuScreen = CameraMenuScreen(cameraController: self);
        self.cameraCapturePipeline.setDelegate(self, callbackQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (UInt(0))));
    }
    
    func initControl() {
        self.cameraCapturePipeline.startPreview();
        self.cameraScreen.initControl();
        self.cameraMenuScreen!.initControl();
        self.cameraMenuScreen!.hide();
    }
    
    func update(delta: CLong) {
        self.cameraMenuScreen!.update(delta);
    }

    func draw(view: GLKMatrix4, headView: GLKMatrix4, perspective: GLKMatrix4) {
        objc_sync_enter(self.cameraScreen);
        self.cameraScreen.draw(view, headView: headView, perspective: perspective);
        objc_sync_exit(self.cameraScreen);
        self.cameraMenuScreen!.draw(view, headView: headView, perspective: perspective);
    }
    
    func dispose() {
        self.cameraCapturePipeline.stopPreview();
    }
    
    func show() {
        
    }
    
    func hide() {
        
    }
    
    func click() {
        if (self.isMenuScreenShown) {
            self.cameraMenuScreen!.click();
            return;
        }
        if ((Double(NSDate.timeIntervalSinceReferenceDate()) - latestTapTime) > 0.3) {
            self.latestTapTime = NSDate.timeIntervalSinceReferenceDate();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(Double(0.3) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                if (self.delayed_task_counter == 1) {
                    if (self.shouldExecuteDispatchBlock) {
                        objc_sync_enter(self.cameraScreen);
                        self.cameraScreen.click();
                        objc_sync_exit(self.cameraScreen);
                    } else {
                        self.shouldExecuteDispatchBlock = true;
                    }
                }
                self.delayed_task_counter--;
            };
            delayed_task_counter++;
        } else {
            self.shouldExecuteDispatchBlock = false;
            showMenuScreen();
        }
        
    }

    func setCallbacks(homeCallback: EmptyDelegate, galleryCallback: EmptyDelegate){
        self._homeCallback = homeCallback;
        self._galleryCallback = galleryCallback;
    }

    @objc func capturePipeline(capturePipeline: CameraCapturePipeline, didStopRunningWithError: NSError) {
        
    }
    
    @objc func capturePipeline(capturePipeline: CameraCapturePipeline, previewPixelBufferReadyForDisplay: CVPixelBufferRef) {
        objc_sync_enter(self.cameraScreen);
        self.cameraScreen.currentPixelBuffer = previewPixelBufferReadyForDisplay;
        objc_sync_exit(self.cameraScreen);
    }
    
    func showMenuScreen() {
        self.cameraMenuScreen!.show();
        self.isMenuScreenShown = true;
    }
    
    func hideMenuScreen() {
        self.cameraMenuScreen!.hide();
        self.isMenuScreenShown = false;
    }

    func navigateToGallery() {
        self._galleryCallback!.invoke()
    }

    func navigateToHome(){
        self._homeCallback!.invoke()
    }
}