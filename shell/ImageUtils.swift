//
// Created by Alexey Suvorov on 6/6/15.
//

import Foundation

class ImageUtils {
    class func rotateImage(image: UIImage!, orientation: UIImageOrientation) -> UIImage! {
        UIGraphicsBeginImageContext(image.size);
        let context = UIGraphicsGetCurrentContext()!

        if (orientation == UIImageOrientation.Right) {
            CGContextRotateCTM(context, CGFloat(90 / 180 * M_PI))
        } else if (orientation == UIImageOrientation.Left) {
            CGContextRotateCTM(context, CGFloat(-90 / 180 * M_PI))
        } else if (orientation == UIImageOrientation.Down) {
            // NOTHING
        } else if (orientation == UIImageOrientation.Up) {
            CGContextRotateCTM(context, CGFloat(90 / 180 * M_PI))
        }

        image.drawAtPoint(CGPointMake(0, 0))
        let x = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return x
    }

    class func radiansFromUIImageOrientation(orientation: UIImageOrientation) -> CGFloat {
        var radians: CGFloat
        switch (orientation) {
        case UIImageOrientation.Up:
            radians = CGFloat(M_PI_2)
            break
        case UIImageOrientation.Right:
            radians = CGFloat(M_PI)
            break
        case UIImageOrientation.Down:
            radians = CGFloat(-M_PI_2)
            break
        default:
            radians = 0.0
        }

        return radians;
    }


    static func cgImageRotate(originalCGImage: CGImageRef, radians: CGFloat) -> CGImageRef {
        let imageSize: CGSize = CGSizeMake(CGFloat(CGImageGetWidth(originalCGImage)), CGFloat(CGImageGetHeight(originalCGImage)));
        var rotatedSize: CGSize

        if (radians == CGFloat(M_PI_2) || radians == CGFloat(-M_PI_2)) {
            rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
        } else {
            rotatedSize = imageSize;
        }

        let rotatedCenterX: CGFloat = (rotatedSize.width) / 2.0;
        let rotatedCenterY: CGFloat = (rotatedSize.height) / 2.0;

        UIGraphicsBeginImageContext(rotatedSize);
        let rotatedContext: CGContextRef = UIGraphicsGetCurrentContext();
        if (radians == 0.0 || radians == CGFloat(M_PI)) {
            // 0 or 180 degrees
            CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
            if (radians == 0.0) {
                CGContextScaleCTM(rotatedContext, 1.0, -1.0);
            } else {
                CGContextScaleCTM(rotatedContext, -1.0, 1.0);
            }
            CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
        } else if (radians == CGFloat(M_PI_2) || radians == CGFloat(-M_PI_2)) {
            // +/- 90 degrees
            CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
            CGContextRotateCTM(rotatedContext, radians);
            CGContextScaleCTM(rotatedContext, 1.0, -1.0);
            CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
        }

        let drawingRect: CGRect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height)
        CGContextDrawImage(rotatedContext, drawingRect, originalCGImage)
        let rotatedCGImage: CGImageRef = CGBitmapContextCreateImage(rotatedContext)

        UIGraphicsEndImageContext()
        return rotatedCGImage;
    }
}