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


class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var assessmentLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    var assessmentScore = 0.0
    let imageProcessor = MPSImageProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    let scoreGroup = DispatchGroup()
    
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
        
        // TODO:
        self.scoreGroup.leave()
    })
    
    func updateRequests(for image: UIImage) {
        assessmentLabel.text = "Processing..."
        detailLabel.text = ""
        assessmentScore = 0.0
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
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
                self.assessmentLabel.text = String(format: "Assessment Score:%0.5f", self.assessmentScore)
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
                for index in 0 ..< count {
                    result += scores[index].doubleValue * Double(index + 1)
                }
                self.assessmentScore = result
            }
            self.scoreGroup.leave()
        }
    }
    
    func processEdgeDetection(mean: Int8, variance: Int8) {
        DispatchQueue.main.async {
            self.detailLabel.text = "mean:\(mean), variance:\(variance)"
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
        if let url = info[.imageURL] as? URL {
            
            DispatchQueue.global().async {
                var start = Date()
                
                let downsampleDimension = 500
                start = Date()
                if let downsampleImage = downsample(url: url, maxDimension: downsampleDimension) {
                    print("downsample duration:\(Date().timeIntervalSince(start))")
                    
                    start = Date()
                    let imagePixels = downsampleImage.rgbPixels()
                    print("rgb pixels duration:\(Date().timeIntervalSince(start))")
                    
                    DispatchQueue.main.async {
                        start = Date()
                        let side = 8
                        self.imageProcessor?.downsample(imagePixels: imagePixels, width: downsampleImage.width, height: downsampleImage.height, scaleDimension: side, { (result) in
                            if let pixels = result {
                                let fingerprint = fingerprintFor(imagePixels: pixels, width: side, height: side)
                                print("finger print duration:\(Date().timeIntervalSince(start))")
                                
                                start = Date()
                                let hsb = meanHSBFor(imagePixels: pixels, width: side, height: side)
                                print("hsb duration:\(Date().timeIntervalSince(start))")
                            }
                        })
                        
                        start = Date()
                        self.imageProcessor?.edgeDetect(imagePixels: imagePixels, width: downsampleImage.width, height: downsampleImage.height, { (mean, variance) in
                            print("fuzzy degree duration:\(Date().timeIntervalSince(start))")
                            self.processEdgeDetection(mean: mean ?? 0, variance: variance ?? 0)
                        })
                    }
                    
                }
            }
        }
    }
    
}

