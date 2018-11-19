//
//  PhotoMLProcessor.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/19.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit
import CoreML
import Vision

class PhotoMLProcessor {
    
    fileprivate var score: Double = 0
    fileprivate let processQueue = DispatchQueue(label: "com.photoassessment.mlprocessor")
    
    init?() {
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
            
        }
        else {
            return nil
        }
    }
    
    fileprivate lazy var assessmentRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: NIMANasnet().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.score += self?.processNIMA(for: request, error: error) ?? 0
            })
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to load Vision ML model NIMANasnet: \(error)")
        }
    }()
    
    fileprivate lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] (request, error) in
            self?.score += self?.processFaceDetection(for: request, error: error) ?? 0
        })
        return request
    }()
    
    fileprivate func processNIMA(for request: VNRequest, error: Error?) -> Double {
        if error != nil {
            print("Vision ML NIMANasnet error: \(String(describing: error)).")
        }
        
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
    
    fileprivate func processFaceDetection(for request: VNRequest, error: Error?) -> Double {
        if error != nil {
            print("FaceDetection error: \(String(describing: error)).")
        }
        
        guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
            let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation] else {
                return 0
        }
        
        if faceDetectionResults.isEmpty {
            return 0
        }
        return 1
    }
    
    func process(image: CGImage, completionHandler: @escaping (Double) -> Void) {
        processQueue.async {
            self.score = 0
            let handler = VNImageRequestHandler(cgImage: image)
            do {
                try handler.perform([self.assessmentRequest, self.faceDetectionRequest])
            } catch {
                print("Failed to perform Assessment.\n\(error.localizedDescription)")
            }
            completionHandler(self.score)
        }
    }
}
