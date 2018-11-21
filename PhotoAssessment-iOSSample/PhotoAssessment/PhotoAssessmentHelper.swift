//
//  PhotoAssessmentHelper.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/19.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

open class PhotoAssessmentResult: NSObject {
    @objc public var edgeDetectMean: Int8
    @objc public var edgeDetectVariance: Int8
    @objc public var hsb: HSBColor?
    @objc public var fingerprint: [UInt16]?
    @objc public var contentScore: Double
    
    override init() {
        edgeDetectMean = 0
        edgeDetectVariance = 0
        contentScore = 0
    }
    
    open override var description: String {
        var text = ""
        text += "edgeDetect mean: \(String(describing: edgeDetectMean)) variance: \(String(describing: edgeDetectVariance))"
        if let hsb = hsb {
            text += String(format: "\nhsb: h(%.3f), s(%.3f), b(%.3f)", hsb.hue, hsb.saturation, hsb.brightness)
        }
        if let fingerprint = fingerprint {
            let fingerprintStr = fingerprint.map({ (value) -> String in
                return String(format: "%x", value)
            })
            text += "\nfingerprint: \(String(describing: fingerprintStr.hashValue))"
        }
        text += String(format: "\ncontentScore: %.3f", contentScore)
        return text
    }
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoAssessmentHelper: NSObject {
    
    private let mpsProcessor = PhotoMPSProcessor()
    private let mlProcessor = PhotoMLProcessor()
    private let utils = Utils()
    private let processQueue = DispatchQueue(label: "com.photoassessment.helper")
    
    @objc public func requestMLAssessmentScore(for image: CGImage, completionHandler: @escaping (Double) -> Void) {
        let start = Date()
        mlProcessor.process(image: image, completionHandler: { (score) in
            print("ml process duration:\(Date().timeIntervalSince(start))")
            completionHandler(score)
        })
    }
    
    @objc public func requestMPSAssessmentScore(for image: CGImage, completionHandler: @escaping (PhotoAssessmentResult) -> Void) {
        var start = Date()
        let imagePixels = image.rgbPixels()
        print("rgb pixels duration:\(Date().timeIntervalSince(start))")
        let totalResult = PhotoAssessmentResult()
        DispatchQueue.main.async {
            start = Date()
            let side = 16
            let group = DispatchGroup()
            group.enter()
            self.mpsProcessor.downsample(imagePixels: imagePixels, width: image.width, height: image.height, scaleDimension: side, { (result) in
                if let pixels = result {
                    let fingerprint = Utils.fingerprintFor(imagePixels: pixels, width: side, height: side)
                    print("finger print duration:\(Date().timeIntervalSince(start))")
                    
                    start = Date()
                    let hsb = Utils.meanHSBFor(imagePixels: pixels, width: side, height: side)
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
            self.mpsProcessor.edgeDetect(imagePixels: imagePixels, width: image.width, height: image.height, { (mean, variance) in
                print("fuzzy degree duration:\(Date().timeIntervalSince(start))")
                self.processQueue.async {
                    totalResult.edgeDetectMean = mean
                    totalResult.edgeDetectVariance = variance
                    group.leave()
                }
            })
            
            group.notify(queue: self.processQueue) {
                completionHandler(totalResult)
            }
        }
    }
}
