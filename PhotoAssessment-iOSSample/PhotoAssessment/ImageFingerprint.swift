//
//  ImageFingerprint.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/14.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

extension UIImage {
    func fingerprint() -> Dictionary<Int, Double> {
        return downsample(scale: 0.01)?.fingerprint() ?? [0: 0]
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
    func fingerprint() -> Dictionary<Int, Double> {
        var result = Dictionary<Int, Double>()
        if let pixels = calloc(width * height, MemoryLayout<Int32>.size) {
            let context = CGContext(data: pixels, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)
            context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
            var currentPixel = pixels
            var pixelBucket = Dictionary<Int, Int>()
            for j in 0 ..< height {
                for i in 0 ..< width {
                    let color = currentPixel.load(as: UInt32.self)
                    let r = downsample(component: color.r())
                    let g = downsample(component: color.g()) << 4
                    let b = downsample(component: color.b()) << 8
                    let loction = downsample(x: i, y: j) << 12
                    let fingerprint = Int(r | g | b | loction)
                    pixelBucket[fingerprint] = (pixelBucket[fingerprint] ?? 0) + 1
                    currentPixel += 4
                }
            }
            free(pixels)
            for (fingerprint, count) in pixelBucket {
                result[fingerprint] = Double(count) / Double(height * width)
            }
        }
        return result
    }
    
    func downsample(component: UInt8) -> UInt16 {
        return UInt16(component / 16)
    }
    
    func downsample(x: Int, y: Int) -> UInt16 {
        let rowCount: Int = 4
        let countPerRow: Int = 4
        let hStep = self.width / countPerRow
        let vStep = self.height / rowCount
        let row = y / vStep
        let col = x / hStep
        return UInt16(row * countPerRow + col);
    }
}

extension UInt32 {
    func mask8() -> UInt8 {
        return UInt8(self & 0xFF)
    }
    
    func r() -> UInt8 {
        return UInt8(mask8())
    }
    
    func g() -> UInt8 {
        return UInt8(mask8() >> 8)
    }
    
    func b() -> UInt8 {
        return UInt8(mask8() >> 16)
    }
}
