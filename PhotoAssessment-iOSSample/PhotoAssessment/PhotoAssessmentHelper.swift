//
//  PhotoAssessmentHelper.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/19.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

open class PhotoAssessmentResult: NSObject, NSCoding {
    
    @objc public var edgeDetectMean: Int8
    @objc public var edgeDetectVariance: Int8
    @objc public var hsb: HSBColor?
    @objc public var fingerprint: [UInt32: UInt]?
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
        text += String(format: "\ncontentScore: %.3f", contentScore)
        return text
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.edgeDetectMean, forKey: "edgeDetectMean")
        aCoder.encode(self.edgeDetectVariance, forKey: "edgeDetectVariance")
        aCoder.encode(self.hsb, forKey: "hsb")
        aCoder.encode(self.fingerprint, forKey: "fingerprint")
        aCoder.encode(self.contentScore, forKey: "contentScore")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.edgeDetectMean = aDecoder.decodeObject(forKey: "edgeDetectMean") as? Int8 ?? 0
        self.edgeDetectVariance = aDecoder.decodeObject(forKey: "edgeDetectVariance") as? Int8 ?? 0
        self.hsb = aDecoder.decodeObject(forKey: "hsb") as? HSBColor
        self.fingerprint = aDecoder.decodeObject(forKey: "fingerprint") as? [UInt32: UInt]
        self.contentScore = aDecoder.decodeObject(forKey: "contentScore") as? Double ?? 0
    }
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoAssessmentHelper: NSObject {
    
    private let mpsProcessor = PhotoMPSProcessor()
    private let mlProcessor = PhotoMLProcessor()
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
            let side = 50
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
                else {
                    group.leave()
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
