//
// Created by Alexey Suvorov on 5/14/15.
//

import Foundation

class YouTubeController : BaseController, SequenceType {
    var screen : YouTubeScreen = YouTubeScreen()

    override init() {
        super.init()
    }

    func generate() -> GeneratorOf<IDrawableControl> {
        var b = true;
        return GeneratorOf {
            if(b){
                b = false;
                return self.screen;
            }
            return nil
        }
    }

    override func getControls() -> SequenceOf<IDrawableControl> {
        return SequenceOf(self)
    }

    override func click() {
        self.screen.click()
    }
}