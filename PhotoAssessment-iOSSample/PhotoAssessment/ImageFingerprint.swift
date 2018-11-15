//
//  ImageFingerprint.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/14.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

extension UIImage {
    func fingerprint() -> Dictionary<Int, Int> {
        var result = Dictionary<Int, Int>()
        downsample(scale: 0.1)
        return result
    }
    
    fileprivate func downsample(scale: CGFloat) -> CGImage? {
        let sourceOpt = [kCGImageSourceShouldCache : false] as CFDictionary
        guard let data = self.pngData() else {
            return nil
        }
        
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOpt) else {
            return nil
        }
        
        let maxDimension = max(self.size.width, self.size.height) * scale
        let downsampleOpt = [kCGImageSourceCreateThumbnailFromImageAlways : true,
                             kCGImageSourceShouldCacheImmediately : true ,
                             kCGImageSourceCreateThumbnailWithTransform : true,
                             kCGImageSourceThumbnailMaxPixelSize : maxDimension] as CFDictionary
        let downsampleImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOpt)!
        return downsampleImage
    }
}

extension CGImage {
    func fingerprint() -> Dictionary<Int, Int> {
        var result = Dictionary<Int, Int>()
        let pixels = calloc(self.width * self.height, MemoryLayout<Int>.size)
        
        let context = CGContext(data: pixels, width: self.width, height: self.height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: self.bitsPerPixel * self.width, space: self.colorSpace ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: self.bitmapInfo.rawValue)
        context?.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        
        free(pixels)
        return result
    }
}
