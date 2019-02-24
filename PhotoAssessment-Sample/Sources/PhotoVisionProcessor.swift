//
//  PhotoVisionProcessor.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/12/26.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif
import Vision

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoVisionProcessor: NSObject {
    private lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest()
        return request
    }()
    
    private func processFaceDetection(for request: VNRequest) -> [CGRect] {
        
        guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
            let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation] else {
                return [CGRect]()
        }
        
        let faceFrames = faceDetectionResults.map { (faceObservation) -> CGRect in
            return faceObservation.boundingBox
        }
        
        return faceFrames
    }
    
    @objc public func faceRectangles(image: CGImage, completionHandler: @escaping ([CGRect]) -> Void) {
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(cgImage: image)
            do {
                try handler.perform([self.faceDetectionRequest])
            } catch {
                print("Failed to perform Assessment.\n\(error.localizedDescription)")
            }
            let result = self.processFaceDetection(for: self.faceDetectionRequest)
            completionHandler(result)
        }
    }
}
