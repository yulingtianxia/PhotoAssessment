//
//  ViewController.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/9.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

extension CGRect {
    func normalized() -> CGRect {
        let x = max(0.0, self.origin.x)
        let y = max(0.0, self.origin.y)
        let w = min(1.0, self.size.width)
        let h = min(1.0, self.size.height)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var assessmentLabel: UILabel!
    @IBOutlet weak var emotionLabel: UILabel!
    
    var assessmentScore = 0.0
    var emotionScore = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    let scoreGroup = DispatchGroup()
    
    lazy var emotionsModel: VNCoreMLModel = {
        do {
            let model = try VNCoreMLModel(for: CNNEmotions().model)
            return model
        } catch {
            fatalError("Failed to load Vision ML model CNNEmotions: \(error)")
        }
    }()
    
    lazy var assessmentRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: NIMANasnet().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processAssessments(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to load Vision ML model NIMANasnet: \(error)")
        }
    }()
    
    lazy var faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
        
        if error != nil {
            print("FaceDetection error: \(String(describing: error)).")
        }
        
        guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
            let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation] else {
                return
        }
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceLandmarks error: \(String(describing: error)).")
            }
            
            guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                let landmarksResults = landmarksRequest.results as? [VNFaceObservation] else {
                    return
            }
            
            for landmarksResult in landmarksResults {
                guard let landmarks = landmarksResult.landmarks else {
                    continue
                }
                
                let landmarkRegions: [VNFaceLandmarkRegion2D?] = [
                    landmarks.faceContour,
                    landmarks.leftEyebrow,
                    landmarks.rightEyebrow,
                    landmarks.leftEye,
                    landmarks.rightEye,
                    landmarks.outerLips,
                    landmarks.innerLips,
                    landmarks.nose,
                    landmarks.noseCrest,
                    landmarks.medianLine,
                    landmarks.leftPupil,
                    landmarks.rightPupil
                ]
                print(landmarkRegions.count)
                //                TODO: landmarks
            }
        })
        
        faceLandmarksRequest.inputFaceObservations = faceDetectionResults
        
        DispatchQueue.main.async {
            
            if faceDetectionResults.count == 0 {
                self.emotionLabel.text = "No Emotion"
            }
            
            if let image = self.imageView.image {
                
                DispatchQueue.global().async {
                    let emotionGroup = DispatchGroup()
                    
                    let emotionRequests: [VNCoreMLRequest] = faceDetectionResults.map({ (faceObservation) -> VNCoreMLRequest in
                        emotionGroup.enter()
                        let request = VNCoreMLRequest(model: self.emotionsModel, completionHandler: { [weak self] request, error in
                            emotionGroup.leave()
                        })
                        request.regionOfInterest = faceObservation.boundingBox.normalized()
                        request.imageCropAndScaleOption = .scaleFill
                        return request
                    })
                    
                    emotionGroup.notify(queue: DispatchQueue.main, execute: {
                        self.processEmotions(for: emotionRequests, error: error)
                    })
                    
                    let orientation = CGImagePropertyOrientation(image.imageOrientation)
                    guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
                    
                    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
                    
                    var requests = [VNImageBasedRequest]()
                    requests.append(faceLandmarksRequest)
                    requests.append(contentsOf: emotionRequests)
                    
                    do {
                        try handler.perform(requests)
                    } catch let error as NSError {
                        NSLog("Failed to perform FaceLandmarkRequest: %@", error)
                    }
                }
            }
        }
    })
    
    func updateRequests(for image: UIImage) {
        assessmentLabel.text = "Processing..."
        emotionLabel.text = "Detecting Emotions..."
        assessmentScore = 0.0
        emotionScore = 0.0
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
//            let start = Date()
//            let fingerprint = image.fingerprint()
//            let duration = Date().timeIntervalSince(start)
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                self.scoreGroup.enter()
                self.scoreGroup.enter()
                try handler.perform([self.assessmentRequest, self.faceDetectionRequest])
            } catch {
                self.scoreGroup.leave()
                self.scoreGroup.leave()
                print("Failed to perform Assessment.\n\(error.localizedDescription)")
            }
            self.scoreGroup.notify(queue: DispatchQueue.main, execute: {
                self.assessmentLabel.text = String(format: "Assessment Score:%0.5f\nEmotion Score:%0.5f\nTotal Score:%0.5f", self.assessmentScore, self.emotionScore, self.assessmentScore + self.emotionScore)
            })
        }
    }
    
    func processAssessments(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.assessmentLabel.text = "Unable to evaluate image.\n\(error!.localizedDescription)"
                return
            }

            let assessments = results as! [VNCoreMLFeatureValueObservation]
            
            if assessments.isEmpty {
                self.assessmentLabel.text = "Nothing recognized."
            } else if let scores = assessments.first?.featureValue.multiArrayValue {
                let count = scores.count
                var result = 0.0
                for index in 1...count {
                    result += scores[index].doubleValue * Double(index)
                }
                self.assessmentScore = result
            }
            self.scoreGroup.leave()
        }
    }
    
    func processEmotions(for requests: [VNRequest], error: Error?) {
        DispatchQueue.main.async {
            var texts = [String]()
            let scoreForEmotions = ["Happy": 5.0, "Angry": 4.0, "Disgust": 2.5, "Fear": 4.0, "Neutral": 2.5, "Sad": 2.5, "Surprise": 4.5]
            for request in requests {
                guard let results = request.results else {
                    self.emotionLabel.text = "Unable to find emotion.\n\(error!.localizedDescription)"
                    continue
                }
                
                let emotions = results as! [VNClassificationObservation]
                
                if !emotions.isEmpty {
                    var result: VNClassificationObservation = emotions.first!
                    print(emotions)
                    for emotion in emotions
                    {
                        if result.confidence < emotion.confidence {
                            result = emotion
                        }
                    }
                    texts.append(result.identifier)
                    self.emotionScore += scoreForEmotions[result.identifier] ?? 0
                }
            }
            if requests.count == 0 {
                self.emotionLabel.text = "No Emotion"
                self.emotionScore = 0.0
            }
            else {
                self.emotionLabel.text = "Emotions:" + texts.joined(separator: ", ")
                self.emotionScore /= Double(requests.count)
            }
            self.scoreGroup.leave()
        }
    }
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image = info[.originalImage] as! UIImage
        imageView.image = image
        updateRequests(for: image)
    }
}

