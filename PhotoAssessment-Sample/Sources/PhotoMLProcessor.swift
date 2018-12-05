//
//  PhotoMLProcessor.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/19.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import Foundation
import CoreML
import Vision

private var model: VNCoreMLModel = {
    do {
        let model = try VNCoreMLModel(for: NIMANasnet().model)
        return model
    } catch {
        fatalError("Failed to load Vision ML model NIMANasnet: \(error)")
    }
}()

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoMLProcessor: NSObject {
    
    private lazy var assessmentRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill
        return request
    }()
    
    private lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest()
        return request
    }()
    
    private func processNIMA(for request: VNRequest) -> Double {
        
        guard let assessments = request.results as? [VNCoreMLFeatureValueObservation] else {
            return 0
        }
        
        if assessments.isEmpty {
            return 0
        } else if let scores = assessments.first?.featureValue.multiArrayValue {
            let count = scores.count
            var result = 0.0
            for index in 0 ..< count {
                result += scores[index].doubleValue * Double(index + 1)
            }
            return result
        }
        return 0
    }
    
    private func processFaceDetection(for request: VNRequest) -> Double {
        
        guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
            let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation] else {
                return 0
        }
        
        if faceDetectionResults.isEmpty {
            return 0
        }
        return 1
    }
    
    @objc public func process(image: CGImage, completionHandler: @escaping (Double) -> Void) {
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(cgImage: image)
            do {
                try handler.perform([self.assessmentRequest, self.faceDetectionRequest])
            } catch {
                print("Failed to perform Assessment.\n\(error.localizedDescription)")
            }
            let score = self.processNIMA(for: self.assessmentRequest) + self.processFaceDetection(for: self.faceDetectionRequest)
            completionHandler(score)
        }
    }
}
