//
//  Utility.swift
//  TestVision
//
//  Created by DAO on 2023/7/17.
//

import CoreGraphics
import UIKit.UIImage

public struct Utility {
    private class EmptyClass { }
    
    func convertUnitToPoint(originalImageRect: CGRect, targetRect: CGRect) -> CGRect {
        var pointRect = targetRect
        
        pointRect.origin.x = originalImageRect.origin.x + (targetRect.origin.x * originalImageRect.size.width)
        pointRect.origin.y = originalImageRect.origin.y + (1 - targetRect.origin.y - targetRect.height) * originalImageRect.size.height
        pointRect.size.width *= originalImageRect.size.width
        pointRect.size.height *= originalImageRect.size.height
        
        return pointRect
    }
    
    func filePath(forResourceName name: String, extension ext: String) -> String? {
        // For cocoapods resources.
        // see more: https://juejin.im/post/5a77fb8df265da4e99576702
        let bundle = Bundle(for: Utility.EmptyClass.self)
        let assetsBundleName = "/DAOFaceCompare.bundle"
        
        guard let resourceBundlePath = bundle.resourcePath?.appending(assetsBundleName),
                let resourceBundle = Bundle(path: resourceBundlePath) else {
            return nil
        }
        
        let bundlePath = resourceBundle.path(forResource: "FaceNet", ofType: "tflite")
        
        return bundlePath
    }
    
    func convertUIImageToBitmapRGBA8(_ image: UIImage) -> UnsafeMutablePointer<UInt8>? {
        guard let imageRef = image.cgImage else {
            return nil
        }

        // Create a bitmap context to draw the uiimage into
        guard let context = newBitmapRGBA8Context(from: imageRef) else {
            return nil
        }

        let width = imageRef.width
        let height = imageRef.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        // Draw image into the context to get the raw image data
        context.draw(imageRef, in: rect)

        // Get a pointer to the data
        let bitmapData = context.data

        // Copy the data and release the memory (return memory allocated with new)
        let bytesPerRow = context.bytesPerRow
        let bufferLength = bytesPerRow * height

        var newBitmap: UnsafeMutablePointer<UInt8>? = nil

        if let bitmapData = bitmapData {
            newBitmap = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
            newBitmap?.initialize(from: bitmapData.bindMemory(to: UInt8.self, capacity: bufferLength), count: bufferLength)
        } else {
            print("Error getting bitmap pixel data\n")
        }

        return newBitmap
    }

    private func newBitmapRGBA8Context(from imageRef: CGImage) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = imageRef.width
        let height = imageRef.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            return nil
        }

        return context
    }
}
