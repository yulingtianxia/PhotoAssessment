//
//  PhotoAssessmentHelper.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/19.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import Foundation
import CoreImage

open class PhotoAssessmentResult: NSObject, NSCoding {
    
    @objc public var edgeDetectMean: Int8
    @objc public var edgeDetectVariance: Int8
    @objc public var hsb: HSBColor?
    @objc public var saturation: Float
    @objc public var fingerprint: Fingerprint?
    @objc public var faceRectangles: [CGRect]?
    
    override init() {
        edgeDetectMean = 0
        edgeDetectVariance = 0
        saturation = 0
    }
    
    open override var description: String {
        var text = ""
        text += "edgeDetect: mean(\(String(describing: edgeDetectMean))), variance:(\(String(describing: edgeDetectVariance)))"
        if let hsb = hsb {
            text += String(format: "\nhsb: h(%.3f), s(%.3f), b(%.3f)", hsb.hue, hsb.saturation, hsb.brightness)
        }
        text += String(format: "\nsaturation: %.3f", saturation)
        if let faceRectangles = faceRectangles {
            text += "\nfaceRectangles: \(faceRectangles.debugDescription)"
        }
        return text
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.edgeDetectMean, forKey: "edgeDetectMean")
        aCoder.encode(self.edgeDetectVariance, forKey: "edgeDetectVariance")
        aCoder.encode(self.hsb, forKey: "hsb")
        aCoder.encode(self.saturation, forKey: "saturation")
        aCoder.encode(self.fingerprint, forKey: "fingerprint")
        aCoder.encode(self.faceRectangles, forKey: "faceRectangles")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.edgeDetectMean = aDecoder.decodeObject(forKey: "edgeDetectMean") as? Int8 ?? 0
        self.edgeDetectVariance = aDecoder.decodeObject(forKey: "edgeDetectVariance") as? Int8 ?? 0
        self.hsb = aDecoder.decodeObject(forKey: "hsb") as? HSBColor
        self.saturation = aDecoder.decodeFloat(forKey: "saturation")
        self.fingerprint = aDecoder.decodeObject(forKey: "fingerprint") as? Fingerprint
        self.faceRectangles = aDecoder.decodeObject(forKey: "faceRectangles") as? [CGRect]
    }
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoAssessmentHelper: NSObject {
    
    private let mpsProcessor = PhotoMPSProcessor()
    private let mlProcessor = PhotoMLProcessor()
    private let vnProcessor = PhotoVisionProcessor()
    private let processQueue = DispatchQueue(label: "com.photoassessment.helper")
    
    @objc public func requestSubjectiveAssessment(for image: CGImage, completionHandler: @escaping (Double) -> Void) {
        mlProcessor.process(image: image, completionHandler: { (score) in
            completionHandler(score)
        })
    }
    
    @objc public func requestObjectiveAssessment(for image: CGImage, downsampleDimension: Int = 50, completionHandler: @escaping (PhotoAssessmentResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let imagePixels = image.rgbPixels()
            let totalResult = PhotoAssessmentResult()
            let group = DispatchGroup()
            
            group.enter()
            self.mpsProcessor.meanSaturation(ofImagePixels: imagePixels, width: image.width, height: image.height, completionHandler: { (result) in
                self.processQueue.async {
                    totalResult.saturation = result
                    group.leave()
                }
            })
            
            group.enter()
            self.mpsProcessor.fingerprint(ofImagePixels: imagePixels, width: image.width, height: image.height, completionHandler: { (result) in
                self.processQueue.async {
                    totalResult.fingerprint = result
                    group.leave()
                }
            })
            
            group.enter()
            self.mpsProcessor.edgeDetect(ofImagePixels: imagePixels, width: image.width, height: image.height, completionHandler: { (mean, variance) in
                self.processQueue.async {
                    totalResult.edgeDetectMean = mean
                    totalResult.edgeDetectVariance = variance
                    group.leave()
                }
            })
            
            group.enter()
            self.vnProcessor.faceRectangles(image: image, completionHandler: { (result) in
                self.processQueue.async {
                    totalResult.faceRectangles = result
                    group.leave()
                }
            })
            
            group.notify(queue: self.processQueue) {
                completionHandler(totalResult)
            }
        }
    }
}
