//
// Created by Alexey Suvorov on 6/6/15.
//

import Foundation


class ShellControllerCallback {
    init (name: String, callback: (ISceneControl)->(), image: String) {
        self.name = name;
        self.callback = callback;
        self.image = image;
    }

    var name : String
    var callback : (ISceneControl) -> ()
    var image : String
}

class ShellController : BaseScreen {
    func setItems(items : Array<ShellControllerCallback>) {
        for x : ShellControllerCallback in items {
            var ctrl = NativeControlFactory.createButton(x.image)
            ctrl.delegate = ItemClickDelegate(callback: x.callback)
            self.controls.append(ctrl)
        }

        let imgSize: Float = 20.0;
        let layout = AngleLayout(radius: 50.0,
                itemWidth: imgSize, itemHeight: imgSize,
                spaceVertical: 22.0, spaceHorizontal: 22.0, maxColumns: 7,
                isHorizontalRound: true, isVerticalRound: false);

        layout.arrange(self.controls);
    }
}