//
//  CameraScreen.swift
//  FullDive
//
//  Created by Станислав Райцин on 28.05.15.
//
//

import Foundation

class CameraScreen: BaseScreen {
    var oglCameraController: OGLCameraControl;
    var currentPixelBuffer: CVPixelBufferRef? {
        get {
            return self.currentPixelBuffer;
        }
        set (newVal) {
            oglCameraController.updatePixelBuffer(newVal);
        }
    }
    
    override init() {
        self.oglCameraController = OGLCameraControl();
        super.init();
    }
    
    override func initControl() {
        self.oglCameraController.initControl();
    }
    
    override func update(delta: CLong) {
        
    }
    
    override func draw(view : GLKMatrix4, headView: GLKMatrix4, perspective: GLKMatrix4) {
        self.oglCameraController.draw(view, headView: headView, perspective: perspective);
       
    }
    
    override func dispose() {
        self.oglCameraController.dispose();
    }
    
    override func click() {
        self.oglCameraController.saveCurrentPixelBuffer();
    }

}