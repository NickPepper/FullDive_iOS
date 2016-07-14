import Foundation
import AssetsLibrary
import UIKit

class ImageBucket {
    init(title: String, group: NSURL!, image: UIImage, count: Int){
        self.title = title
        self.group = group
        self.image = image
        self.count = count
    }
    var title : String
    var group : NSURL!
    var image : UIImage
    var count : Int
}


class BucketClick: IItemClickDelegate {
    var _bucket: ImageBucket;
    var _callback: (b: ImageBucket) -> ();
    init(bucket: ImageBucket, callback: (b: ImageBucket)->()){
        self._bucket = bucket;
        self._callback = callback;
    }
    func click(_: ISceneControl) {
        self._callback(b: self._bucket);
    }
}

class GalleryScreen : BaseScreen {
    var albums: Array<ImageBucket> = Array<ImageBucket>();
    var _navigation: IImageGalleryNavigationController;

    init (navigation: IImageGalleryNavigationController){
        self._navigation = navigation;
    }

    override func initControl(){
        self.getBuckets(self.setupBuckets, noBucketsBlock: self.showNoImages);
        super.initControl();
    }

    func setupBuckets(){
        self.controls.removeAll(keepCapacity: true);

        for x: ImageBucket in self.albums {
            var img = NativeControlFactory.createImage(x.image);
            img.delegate = BucketClick(bucket: x, callback: self.bucketClick);
            self.controls.append(img);
        }

        let imgSize: Float = 20.0;
        let layout = AngleLayout(radius: 30.0,
                itemWidth: imgSize, itemHeight: imgSize,
                spaceVertical: 22.0, spaceHorizontal: 22.0, maxColumns: 7,
                isHorizontalRound: true, isVerticalRound: false);

        layout.arrange(self.controls);

        for x : IDrawableControl in self.controls {
            x.initControl()
        }

        var homeButton = NativeControlFactory.createButton("gallery_home_button.png")
        homeButton.delegate = ItemClickDelegate(callback: {(c : ISceneControl) in self._navigation.navigateToHome() })
        homeButton.setSize(8.0, height: 8.0)
        homeButton.setPosition(0.0, y: 12.0, z: -10.0)
        homeButton.setRotation(0.0, yAngle: 0.0)

        homeButton.initControl()
        self.controls.append(homeButton)
    }

    func showNoImages(){
        self.controls.removeAll(keepCapacity: true);

        var imgCtrl = NativeControlFactory.createImage(UIImage(named: "gallery_noimagestodisplay_button.png")!)
        imgCtrl.setPosition(0, y: 0, z:-10.0)
        imgCtrl.setSize(20, height: 2)
        imgCtrl.initControl();

        self.controls.append(imgCtrl);
    }

    func bucketClick(b: ImageBucket) {
        self._navigation.navigateToGallery(b);
    }

    func getBuckets(continueBlock:()->(), noBucketsBlock: ()->()){
        let photoLibrary = ALAssetsLibrary();
        var buckets = Array<ImageBucket>();

        photoLibrary.enumerateGroupsWithTypes(
            ALAssetsGroupType(Int(ALAssetsGroupAll.hashValue)),
            usingBlock: {
                (group : ALAssetsGroup!, stop) in
                if group != nil {
                    let n = group.numberOfAssets() - 1;
                    if n > 0 {
                        let idx = NSIndexSet(index: n);
                        group.enumerateAssetsAtIndexes(idx,
                                options: NSEnumerationOptions.Reverse,
                                usingBlock: {
                                    (asset: ALAsset!, _, __) in
                                    if asset != nil {
                                        let name = group.valueForProperty(ALAssetsGroupPropertyName) as? String;
                                        let url = group.valueForProperty(ALAssetsGroupPropertyURL) as? NSURL;
                                        let count = group.numberOfAssets();
                                        let unsafeImg = UIImage(CGImage: asset.thumbnail().takeUnretainedValue())!;
                                        let b = ImageBucket(title: name!, group: url!, image: unsafeImg, count: count);
                                        buckets.append(b);
                                    }
                                });
                    }
                } else {
                    if buckets.count >  0 {
                        self.albums = buckets
                        continueBlock()
                    }else {
                        noBucketsBlock()
                    }
                }
            },
            failureBlock: {
                myerror in
                println("error occurred: \(myerror.localizedDescription)")
            })
    }
}


