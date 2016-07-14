import Foundation
import AssetsLibrary

class YouTubeScreen : BaseScreen {
    override func initControl() {
        var player = NativeControlFactory.createPlayer()
        player.setSize(5.0, height: 5.0)
        player.setPosition(0.0, y: -12.0, z: -10.0)
        player.setRotation(0.0, yAngle: 0.0)

        player.initControl()
        self.controls.append(player)
    }
}