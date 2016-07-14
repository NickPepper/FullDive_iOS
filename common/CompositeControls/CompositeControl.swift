//
// Created by Alexey Suvorov on 4/22/15.
//

import GLKit
import Foundation

protocol IDrawableControl {
    func initControl()
    func update(delta: CLong)
    func draw(view : GLKMatrix4, headView: GLKMatrix4, perspective: GLKMatrix4)
    func dispose()
    func show()
    func hide()
    func click()
}

protocol ISceneControl : IDrawableControl {
    func setSize(width: Float, height: Float)
    func setPosition(x: Float, y: Float, z: Float)
    func setRotation(xAngle: Float, yAngle: Float)

    func recalculatePosition()

    func isLookingAtObject(headView: GLKMatrix4) -> Bool
    func focus()
    func unfocus()

    var delegate: IItemClickDelegate? { get set }
}

class DrawableCompositeControl: IDrawableControl {
    internal var _headView: GLKMatrix4?;

    func initControl(){
        for x in self.getControls() { x.initControl(); }
    }

    func update(delta: CLong) {
        for x in getControls() {
            x.update(delta);
        }
    }

    func draw(view : GLKMatrix4, headView: GLKMatrix4, perspective: GLKMatrix4){
        _headView = headView;
        for x in getControls() {
            x.draw(view, headView: headView, perspective: perspective);
        }
    }

    func dispose() {
        for x in getControls() { x.dispose(); }
    }

    func getControls() -> SequenceOf<IDrawableControl> {
        fatalError("This method must be overridden")
    }

    func click() {
        fatalError("This method must be overridden")
    }

    func show() {
        for x in getControls() { x.show(); }
    }

    func hide() {
        for x in getControls() { x.hide(); }
    }
}

class BaseScreen : DrawableCompositeControl {
    var controls : Array<ISceneControl> = Array<ISceneControl>();

    func isLookingAtObject(headView: GLKMatrix4) -> Bool{
        for x in controls {
            if(x.isLookingAtObject(headView)) {
                return true;
            }
        }
        return false;
    }

    override func update(delta: CLong) {
        super.update(delta)

        for x in controls {
            if let h = _headView {
                if (x.isLookingAtObject(h)) {
                    x.focus();
                } else {
                    x.unfocus();
                }
            }
        }
    }

    override func click() {
        for x in controls {
            if let h = _headView {
                if(x.isLookingAtObject(h)) {
                    x.click();
                    return;
                }
            }
        }
    }

    override func getControls() -> SequenceOf<IDrawableControl> {
        return SequenceOf(self.controls.map { $0 as IDrawableControl })
    }
}