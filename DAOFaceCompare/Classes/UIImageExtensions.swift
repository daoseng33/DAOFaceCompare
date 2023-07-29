//
//  UIImageExtensions.swift
//  TestVision
//
//  Created by DAO on 2023/7/28.
//

import UIKit.UIImage

extension UIImage {
    func imageByApplyingClippingBezierPath(_ path: UIBezierPath) -> UIImage? {
        // Mask image using path
        guard let maskedImage = imageByApplyingMaskingBezierPath(path) else { return nil }

        // Crop image to frame of path
        let croppedImage = UIImage(cgImage: maskedImage.cgImage!.cropping(to: path.bounds)!)
        
        return croppedImage
    }
    
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage? {
        // Define graphic context (canvas) to paint on
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        // Set the clipping mask
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()

        // Restore previous drawing context
        context?.restoreGState()
        UIGraphicsEndImageContext()

        return maskedImage
    }
    
    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
