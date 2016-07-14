import Foundation
import GLKit
import AudioToolbox

@objc
class FullDiveAppManager {
    private var _controller: IDrawableControl?;

    func initApp() {
        self.switchToHome()
    }

    func update(delta: CLong){
        _controller!.update(delta);
    }

    func draw(view : GLKMatrix4, headView: GLKMatrix4, perspective: GLKMatrix4){
        _controller!.draw(view, headView: headView, perspective: perspective);
    }

    func click(){
        _controller!.click();
    }

    func getAppItems() -> Array<ShellControllerCallback> {
        var res = Array<ShellControllerCallback>()
        var galleryCallback = ShellControllerCallback(name: "Gallery", callback: self.switchToGallery, image: "shell_gallery_button.png")
        var cameraCallback = ShellControllerCallback(name: "Camera", callback: self.switchToCamera, image: "shell_camera_button.png")
        res.append(galleryCallback)
        res.append(cameraCallback)
        return res
    }

    func switchToGallery(ctrl : ISceneControl) {
        self.switchToGallery()
    }

    func switchToCamera(ctrl : ISceneControl) {
        let ctrl = CameraController()
        ctrl.setCallbacks(EmptyDelegate(callback: self.switchToHome), galleryCallback: EmptyDelegate(callback: self.switchToGallery))
        self._controller = ctrl
        self._controller!.initControl()
    }

    func switchToGallery() {
        let ctrl = GallerryController()
        ctrl.setHomeCallback(EmptyDelegate(callback: self.switchToHome))
        self._controller = ctrl
        self._controller!.initControl()
    }

    func switchToHome() {
        let ctrl = YouTubeController() //ShellController()
        //ctrl.setItems(self.getAppItems())
        self._controller = ctrl
        self._controller!.initControl()
    }
}

@objc
public class AppFactory {
    static func create() -> FullDiveAppManager {
        return FullDiveAppManager();
    }
}

