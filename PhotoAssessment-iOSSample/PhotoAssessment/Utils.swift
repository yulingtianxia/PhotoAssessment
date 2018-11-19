//
//  Utils.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/18.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

public func fingerprintFor(imagePixels: [Int32], width: Int, height: Int) -> [UInt16] {
    
    func downsample(component: UInt8) -> UInt16 {
        return UInt16(component / 16)
    }
    
    let result: [UInt16] = imagePixels.map { (pixel) -> UInt16 in
        let color = pixel
        let r = downsample(component: color.r()) << 12
        let g = downsample(component: color.g()) << 8
        let b = downsample(component: color.b()) << 4
        let a = downsample(component: color.a())
        let fingerprint = r | g | b | a
        return fingerprint
    }
    return result
}

public func meanHSBFor(imagePixels: [Int32], width: Int, height: Int) -> (CGFloat, CGFloat, CGFloat) {
    let hsbPixels = imagePixels.map { (pixel) -> (CGFloat, CGFloat, CGFloat) in
        return UIColor(red: CGFloat(pixel.r()), green: CGFloat(pixel.g()), blue: CGFloat(pixel.b()), alpha: CGFloat(pixel.a())).hsb
    }
    let result = hsbPixels.reduce((0, 0, 0)) { (result, hsb) -> (CGFloat, CGFloat, CGFloat) in
        let (h, s, b) = hsb
        return (result.0 + h, result.1 + s, result.2 + b)
    }
    let count = CGFloat(hsbPixels.count)
    return (result.0 / count, result.1 / count, result.2 / count)
}

public func downsample(url: URL, maxDimension: Int) -> CGImage? {
    let sourceOpt = [kCGImageSourceShouldCache : false] as CFDictionary
    
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOpt) else {
        return nil
    }
    let downsampleOpt = [kCGImageSourceCreateThumbnailFromImageAlways : true,
                         kCGImageSourceShouldCacheImmediately : true ,
                         kCGImageSourceCreateThumbnailWithTransform : true,
                         kCGImageSourceThumbnailMaxPixelSize : maxDimension] as CFDictionary
    let downsampleImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOpt)!
    
    return downsampleImage
}

extension CGImage {
    func grayPixels() -> [Int16] {
        var pixels = [Int16](repeatElement(0, count: width * height))
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 16, bytesPerRow: 2 * width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
    
    func rgbPixels() -> [Int32] {
        var pixels = [Int32](repeatElement(0, count: width * height))
        // Apple's bug(Only Swift): wrong bytesPerRow. Use workaround.
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
}

extension UIColor {
    var hsb:(h: CGFloat, s: CGFloat,b: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        return (h: h, s: s, b: b)
    }
}

extension Int32 {
    func mask8() -> UInt8 {
        return UInt8(self & 0xFF)
    }
    
    func r() -> UInt8 {
        return (self >> 24).mask8()
    }
    
    func g() -> UInt8 {
        return (self >> 16).mask8()
    }
    
    func b() -> UInt8 {
        return (self >> 8).mask8()
    }
    
    func a() -> UInt8 {
        return mask8()
    }
}
