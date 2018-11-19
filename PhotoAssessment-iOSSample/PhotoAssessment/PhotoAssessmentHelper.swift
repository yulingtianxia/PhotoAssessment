//
//  PhotoAssessmentHelper.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/19.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

open class PhotoAssessmentResult: CustomStringConvertible {
    public var edgeDetect: (mean: Int8, variance: Int8)?
    public var hsb: (h: CGFloat, s: CGFloat, b: CGFloat)?
    public var fingerprint: [UInt16]?
    public var contentScore: Double?
    
    public var description: String {
        var text = ""
        if let edgeDetect = edgeDetect {
            text += "edgeDetect: \(String(describing: edgeDetect))"
        }
        if let hsb = hsb {
            text += String(format: "\nhsb: h(%.3f), s(%.3f), b(%.3f)", hsb.h, hsb.s, hsb.b)
        }
        if let fingerprint = fingerprint {
            let fingerprintStr = fingerprint.map({ (value) -> String in
                return String(format: "%x", value)
            })
            text += "\nfingerprint: \(String(describing: fingerprintStr.hashValue))"
        }
        if let contentScore = contentScore {
            text += String(format: "\ncontentScore: %.3f", contentScore)
        }
        return text
    }
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoAssessmentHelper {
    
    private let mpsProcessor = PhotoMPSProcessor()
    private let mlProcessor = PhotoMLProcessor()
    private let processQueue = DispatchQueue(label: "com.photoassessment.helper")
    
    public func requestMLAssessmentScore(for image: CGImage, completionHandler: @escaping (Double) -> Void) {
        let start = Date()
        mlProcessor.process(image: image, completionHandler: { (score) in
            print("ml process duration:\(Date().timeIntervalSince(start))")
            completionHandler(score)
        })
    }
    
    public func requestMPSAssessmentScore(for image: CGImage, completionHandler: @escaping (PhotoAssessmentResult) -> Void) {
        var start = Date()
        let imagePixels = image.rgbPixels()
        print("rgb pixels duration:\(Date().timeIntervalSince(start))")
        let totalResult = PhotoAssessmentResult()
        DispatchQueue.main.async {
            start = Date()
            let side = 8
            let group = DispatchGroup()
            group.enter()
            self.mpsProcessor?.downsample(imagePixels: imagePixels, width: image.width, height: image.height, scaleDimension: side, { (result) in
                if let pixels = result {
                    let fingerprint = fingerprintFor(imagePixels: pixels, width: side, height: side)
                    print("finger print duration:\(Date().timeIntervalSince(start))")
                    
                    start = Date()
                    let hsb = meanHSBFor(imagePixels: pixels, width: side, height: side)
                    print("hsb duration:\(Date().timeIntervalSince(start))")
                    
                    self.processQueue.async {
                        totalResult.fingerprint = fingerprint
                        totalResult.hsb = hsb
                        group.leave()
                    }
                }
            })
            group.enter()
            start = Date()
            self.mpsProcessor?.edgeDetect(imagePixels: imagePixels, width: image.width, height: image.height, { (mean, variance) in
                print("fuzzy degree duration:\(Date().timeIntervalSince(start))")
                self.processQueue.async {
                    totalResult.edgeDetect = (mean ?? 0, variance ?? 0)
                    group.leave()
                }
            })
            
            group.notify(queue: self.processQueue) {
                completionHandler(totalResult)
            }
        }
    }
}
