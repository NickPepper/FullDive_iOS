//
//  CameraMenuScreen.swift
//  FullDive
//
//  Created by Станислав Райцин on 10.06.15.
//
//

import Foundation
class CameraMenuScreen : DrawableCompositeControl, SequenceType {
    private var menuControls = Array<ISceneControl>();
    private var _cameraController: CameraController;

    init(cameraController: CameraController) {
        _cameraController = cameraController;
        super.init();
    }
    
    override func initControl() {
        var menuBackgrounControl = NativeControlFactory.createImage(UIImage(named: "menu_background.png")!);
        menuBackgrounControl.setSize(5.0, height: 3.0);
        menuBackgrounControl.setPosition(0.0, y: 0.0, z: -4.1);
        self.menuControls.append(menuBackgrounControl);
        
        var closeMenuButton = NativeControlFactory.createButton("back_button_medium.png");
        closeMenuButton.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self._cameraController.hideMenuScreen(); })
        closeMenuButton.setSize(1.0, height: 1.0)
        closeMenuButton.setPosition(-1.5, y: 0.0, z: -4.0)
        self.menuControls.append(closeMenuButton)
        
        var homeButton = NativeControlFactory.createButton("home_icon.png");
        homeButton.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self._cameraController.navigateToHome(); })
        homeButton.setSize(1.0, height: 1.0)
        homeButton.setPosition(0.0, y: 0.0, z: -4.0)
        self.menuControls.append(homeButton)
        
        var galleryButton = NativeControlFactory.createButton("shell_gallery_button.png");
        galleryButton.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self._cameraController.navigateToGallery(); })
        galleryButton.setSize(1.0, height: 1.0)
        galleryButton.setPosition(1.5, y: 0.0, z: -4.0)
        self.menuControls.append(galleryButton)
        
        for iSC in self.menuControls {
            iSC.initControl();
        }
    }
    
    override func getControls() -> SequenceOf<IDrawableControl> {
        return SequenceOf(self);
    }
    
    override func click() {
        for x in menuControls {
            if let h = _headView {
                if(x.isLookingAtObject(h)) {
                    if (x.delegate != nil) {
                        x.click();
                        return;
                    }
                }
            }
        }
    }
    
    func generate() -> GeneratorOf<IDrawableControl> {
        var i = 0;
        return GeneratorOf<IDrawableControl> {
            if (i >= self.menuControls.count) {
                return .None
            } else {
                return self.menuControls[i++]
            }
        }
    }
    
    override func update(delta: CLong) {
        super.update(delta)
        
        for x in menuControls {
            if let h = _headView {
                if (x.isLookingAtObject(h)) {
                    x.focus();
                } else {
                    x.unfocus();
                }
            }
        }
    }
}