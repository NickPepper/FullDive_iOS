import Foundation
import AssetsLibrary

class OneImageScreen: BaseScreen, IItemClickDelegate {
    var _img: ImageItem
    var _nav: IImageGalleryNavigationController
    let maxSize: Float = 40.0

    init(img: ImageItem, navigation: IImageGalleryNavigationController){
        self._img = img
        self._nav = navigation
    }

    override func initControl() {
        let asset: ALAsset! = self._img.image;
        let rep: ALAssetRepresentation = asset.defaultRepresentation()
        let iref = rep.fullResolutionImage()
        var imageOrientation: UIImageOrientation = .Up
        let orientValueFromImage = asset.valueForProperty("ALAssetPropertyOrientation") as! NSNumber
        imageOrientation = UIImageOrientation(rawValue: orientValueFromImage.integerValue)!
        let underlying = iref.takeUnretainedValue()

        let largeimage = UIImage(CGImage: underlying, scale: 1, orientation: imageOrientation)!
        
        let w = largeimage.size.width;
        let h = largeimage.size.height;
        var x: ISceneControl = NativeControlFactory.createImage(largeimage)
        x.setPosition(0.0, y: 0.0, z: -20.0)
        if(h > w) {
            let c = Float(w / h);
            x.setSize(self.maxSize * c, height: self.maxSize)
        } else {
            let c = Float(h / w);
            x.setSize(self.maxSize, height: self.maxSize * c)
        }

        x.initControl()
        iref.retain()

        x.delegate = self;
        self.controls.append(x)
    }

    func click(ctrl: ISceneControl) {
        self._nav.navigateToImages()
    }
}