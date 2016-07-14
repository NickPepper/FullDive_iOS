//
// Created by Alexey Suvorov on 5/14/15.
//

import Foundation

protocol IImageGalleryNavigationController {
    func navigateToGallery(b: ImageBucket)
    func navigateToImage(img: ImageItem)
    func navigateToAlbums()
    func navigateToImages()
    func navigateToHome()
}

class GallerryController : BaseController, IImageGalleryNavigationController, SequenceType {
    var galleryScreen : GalleryScreen?;
    var imagesScreen: IDrawableControl?;
    var oneImageScreen: IDrawableControl?

    override init() {
        super.init()
        self.galleryScreen = GalleryScreen(navigation: self)
    }

    func generate() -> GeneratorOf<IDrawableControl> {
        var b = true;
        return GeneratorOf {
            if(b){
                b = false;
                return self.getActiveScreen();
            }
            return nil
        }
    }

    override func getControls() -> SequenceOf<IDrawableControl> {
        return SequenceOf(self)
    }

    override func click() {
        self.getActiveScreen().click()
    }


    func getActiveScreen() -> IDrawableControl {
        if let x = oneImageScreen {
            return x
        }

        if let x = imagesScreen {
            return x
        }

        return galleryScreen!
    }

    func navigateToGallery(b: ImageBucket){
        self.imagesScreen = ImagesScreen(bucket: b, navigation: self)
        self.imagesScreen!.initControl()
    }

    func navigateToImage(img: ImageItem) {
        self.oneImageScreen = OneImageScreen(img: img, navigation: self)
        self.oneImageScreen!.initControl()
    }

    func navigateToAlbums() {
        self.imagesScreen!.dispose()
        self.imagesScreen = nil
        self.oneImageScreen = nil
    }

    func navigateToImages() {
        self.oneImageScreen!.dispose()
        self.oneImageScreen = nil
    }

    func navigateToHome(){
        self._homeCallback!.invoke();
    }
}