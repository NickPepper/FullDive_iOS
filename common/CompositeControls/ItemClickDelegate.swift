//
// Created by Alexey Suvorov on 5/10/15.
//

import Foundation

protocol IItemClickDelegate {
    func click(ctrl: ISceneControl)
}

class ItemClickDelegate : IItemClickDelegate {
    let _callback: (ctrl: ISceneControl) -> ()
    init(callback: (ctrl: ISceneControl) -> ()) {
        self._callback = callback;
    }

    func click(ctrl: ISceneControl){
        self._callback(ctrl: ctrl)
    }

}
