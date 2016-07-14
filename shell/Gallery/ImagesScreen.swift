import Foundation
import AssetsLibrary

class ImageItemClickDelegate: IItemClickDelegate {
    var navigation: IImageGalleryNavigationController
    var item: ImageItem

    init(item: ImageItem, navigation: IImageGalleryNavigationController){
        self.navigation = navigation;
        self.item = item;
    }

    func click(ctrl: ISceneControl){
        self.navigation.navigateToImage(self.item);
    }
}

class ImageItem {
    init(image: ALAsset!){
        self.image = image;
    }

    var image: ALAsset!;
}

class ImagesScreen : BaseScreen, SequenceType {
    let _photoLibrary: ALAssetsLibrary = ALAssetsLibrary()

    let _itemsPerPage: Int = 39;

    var _backButton: ISceneControl?;
    var _nextButton: ISceneControl?;

    var _bucket: ImageBucket
    var _navigation: IImageGalleryNavigationController

    var _imageControls: Array<ISceneControl> = Array<ISceneControl>();
    var _offset: Int = 0
    var _itemsInGroup: Int = Int.max;

    init(bucket: ImageBucket, navigation: IImageGalleryNavigationController){
        _bucket = bucket
        _navigation = navigation
    }

    override func initControl() {
        self._itemsInGroup = self._bucket.count;
        self.reloadImages();

        var homeButton = NativeControlFactory.createButton("gallery_home_button.png")
        homeButton.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self._navigation.navigateToAlbums() })
        homeButton.setSize(5.0, height: 5.0)
        homeButton.setPosition(0.0, y: -12.0, z: -10.0)
        homeButton.setRotation(0.0, yAngle: 0.0)

        homeButton.initControl()
        self.controls.append(homeButton)

        self._backButton = NativeControlFactory.createButton("gallery_back_button.png")
        self._backButton!.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self.prev() })
        self._backButton!.setSize(5.0, height: 5.0)
        self._backButton!.setPosition(0.0, y: -12.0, z: -10.0)
        self._backButton!.setRotation(0.0, yAngle: 0.12)

        self._backButton!.initControl()
        self.controls.append(self._backButton!)
        self._backButton!.hide();

        self._nextButton = NativeControlFactory.createButton("gallery_next_button.png")
        self._nextButton!.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self.next() })
        self._nextButton!.setSize(5.0, height: 5.0)
        self._nextButton!.setPosition(0.0, y: -12.0, z: -10.0)
        self._nextButton!.setRotation(0.0, yAngle: -0.12)

        self._nextButton!.initControl()
        if(self._itemsInGroup > self._itemsPerPage) {
            self.controls.append(self._nextButton!)
        }
    }

    func reloadImages(){
        _imageControls.removeAll();
        self._photoLibrary.groupForURL(self._bucket.group,
                resultBlock: self.enumerateGroup,
                failureBlock: {
                    myerror in
                    println("error occurred: \(myerror.localizedDescription)")
                })
    }

    func enumerateGroup(group: ALAssetsGroup!){
        if group != nil {
            var length : Int = self._itemsPerPage
            if (self._offset + self._itemsPerPage > self._itemsInGroup) {
                length = self._itemsInGroup - self._offset;
            }

            let range: NSRange = NSRange(location: self._offset, length: length)
            let ids: NSIndexSet = NSIndexSet(indexesInRange: range)
            var images: Array<ImageItem> = Array<ImageItem>();
            group.enumerateAssetsAtIndexes(
                ids,
                options: nil,
                usingBlock: { (asset: ALAsset!, _, __) in
                    if asset != nil {
                        let x = ImageItem(image: asset);
                        images.append(x);
                    } else {
                        self.displayImages(images);
                    }
                })
        } else {
            println("error occurred: cannot find group for url \(self._bucket.group)")
        }
    }

    func displayImages(images: Array<ImageItem>) {
        for x in images {
            let unsafeImg = UIImage(CGImage: x.image.thumbnail().takeUnretainedValue())!;
            var img = NativeControlFactory.createImage(unsafeImg)
            img.delegate = ImageItemClickDelegate(item:x, navigation: self._navigation)
            self._imageControls.append(img)
        }

        let layout = AngleLayout(radius: 40.0,
                itemWidth: 10.0, itemHeight: 10.0,
                spaceVertical: 12.0, spaceHorizontal: 12.0, maxColumns: 13,
                isHorizontalRound: true, isVerticalRound: false)

        layout.arrange(self._imageControls)

        for x: ISceneControl in self._imageControls {
            x.initControl()
        }
    }

    func next(){
        if(_offset + _itemsPerPage < _itemsInGroup) {
            self._offset = self._offset + self._itemsPerPage
            self.reloadImages()
            println("Load images next")
        }

        if(_offset + _itemsPerPage >= _itemsInGroup){
            self._nextButton!.hide()
        } else {
            self._nextButton!.show();
        }

        if(_offset > 0){
            self._backButton!.show();
        }
    }

    func prev() {
        if((_offset - _itemsPerPage) >= 0) {
            _offset = _offset - _itemsPerPage;
            self.reloadImages()
            println("Load images prev")
        }

        if(_offset == 0){
            self._backButton!.hide();
        } else {
            self._backButton!.show();
        }

        if(_offset + _itemsPerPage < _itemsInGroup){
            self._nextButton!.show();
        }
    }

    func generate() -> GeneratorOf<IDrawableControl> {
        var n = 0;
        var n1 = self.controls.count;
        var n2 = self._imageControls.count + n1 - 1;
        return GeneratorOf {
            if(n < n1){
                n++;
                return self.controls[n-1] as IDrawableControl;
            }
            if(n < n2){
                n++;
                return self._imageControls[n - n1 - 1] as IDrawableControl;
            }
            return nil
        }
    }

    override func getControls() -> SequenceOf<IDrawableControl> {
        return SequenceOf(self)
    }

    override func isLookingAtObject(headView: GLKMatrix4) -> Bool{
        for x in self._imageControls {
            if(x.isLookingAtObject(headView)) {
                return true;
            }
        }

        return super.isLookingAtObject(headView);
    }

    override func update(delta: CLong) {
        super.update(delta)

        for x in _imageControls {
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
        for x in _imageControls {
            if let h = _headView {
                if(x.isLookingAtObject(h)) {
                    x.click();
                    return;
                }
            }
        }

        super.click();
    }
}