//
// Created by Alexey Suvorov on 6/9/15.
//

import Foundation

class EmptyDelegate {
    var _callback : ()->()
    init(callback: ()->()) {
        self._callback = callback;
    }

    func invoke() {
        self._callback();
    }
}

class BaseController : DrawableCompositeControl {
    var _homeCallback : EmptyDelegate?

    override init() {
        super.init()
    }

    func setHomeCallback(callback: EmptyDelegate){
        self._homeCallback = callback;
    }
}
