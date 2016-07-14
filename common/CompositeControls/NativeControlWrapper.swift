//
// Created by Alexey Suvorov on 4/22/15.
//

import Foundation
import UIKit
import GLKit

@objc
class NativeControlWrapper : NSObject, ISceneControl, FDClickDelegate {
    internal var _ctrl : FDIControl;
    internal var _delegate: IItemClickDelegate?

    init(ctrl : FDIControl){
        self._ctrl = ctrl;

        super.init();
        self._ctrl.delegate = self;
    }

    func update(delta: CLong){
        self._ctrl.update(delta);
    }

    func draw(view : GLKMatrix4, headView: GLKMatrix4, perspective: GLKMatrix4){
        self._ctrl.draw(view, headView: headView, perspective: perspective);
    }

    func initControl(){
        self._ctrl.initControl();
    }

    func dispose(){
        self._ctrl.dispose();
    }

    func setSize(width: Float, height: Float){
        self._ctrl.setSize(width, height: height);
    }

    func setPosition(x: Float, y: Float, z: Float) {
        self._ctrl.setPosition(x, y:y, z:z);
    }

    func setRotation(xAngle: Float, yAngle: Float) {
        self._ctrl.setRotation(xAngle, angleY: yAngle);
    }

    func getNativeInstance()->FDIControl{
        return _ctrl;
    }

    func isLookingAtObject(headView: GLKMatrix4 )-> Bool {
        return _ctrl.isLookingAtObject(headView);
    }

    func recalculatePosition(){
        _ctrl.recalculatePosition();
    }

    func focus() {
        _ctrl.focus();
    }

    func unfocus() {
        _ctrl.unfocus();
    }

    func show() {
        _ctrl.show();
    }

    func hide() {
        _ctrl.hide();
    }

    func click(){
        if let d = _delegate {
            d.click(self)
        }
    }

    internal func click(ctrl: FDIControl){
        if let d = _delegate {
            d.click(self)
        }
    }

    var delegate: IItemClickDelegate? {
        get{
            return _delegate;
        }
        set(x) {
            _delegate = x;
        }
    }
}

class NativeControlFactory {
    class func createImage(img: UIImage) -> ISceneControl {
        let ctrl = FDImage(image: img);
        return NativeControlWrapper(ctrl: ctrl);
    }

    class func createButton(resourceName: String) -> ISceneControl {
        let ctrl = FDButton(resourceImage: resourceName);
        return NativeControlWrapper(ctrl: ctrl);
    }

    class func createPlayer() -> ISceneControl {
        let ctrl = FDPlayerControl()
        return NativeControlWrapper(ctrl: ctrl)
    }
}
