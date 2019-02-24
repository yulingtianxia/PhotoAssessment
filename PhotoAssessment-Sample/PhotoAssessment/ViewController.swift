//
//  ViewController.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/9.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var assessmentLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @available (iOS 11.0, *)
    lazy var helper: PhotoAssessmentHelper = {
       return PhotoAssessmentHelper()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
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
        assessmentLabel.text = "Processing..."
        detailLabel.text = ""
        if let url = info[.imageURL] as? URL {
            DispatchQueue.global().async {
                var start = Date()
                let downsampleDimension = 500
                start = Date()
                if let downsampleImage = Utils.downsample(url: url, maxDimension: downsampleDimension) {
                    print("downsample duration:\(Date().timeIntervalSince(start))")
                    guard #available(iOS 11.0, *) else {
                        return
                    }
//                    if let cgImage = image.cgImage {
//                        let imagePixels = cgImage.rgbPixels()
//                        var date = Date()
//                        let fingerprint = Utils.meanHSBFor(imagePixels: imagePixels, width: cgImage.width, height: cgImage.height)
//                        print("cpu fingerprint cost: \(-date.timeIntervalSinceNow)")
//                        let mpsProcessor = PhotoMPSProcessor()
//                        date = Date()
//                        mpsProcessor.meanSaturation(imagePixels: imagePixels, width: cgImage.width, height: cgImage.height, completionHandler: { (result) in
//                            print("gpu fingerprint cost: \(-date.timeIntervalSinceNow)")
//                        })
//                    }
                    
                    self.helper.requestSubjectiveAssessment(for: downsampleImage, completionHandler: { (score) in
                        DispatchQueue.main.async {
                            self.assessmentLabel.text = String(format: "Assessment Score:%0.5f", score)
                        }
                    })
                    self.helper.requestObjectiveAssessment(for: downsampleImage, downsampleDimension: 4, completionHandler: { (result) in
                        DispatchQueue.main.async {
                            self.detailLabel.text = result.description
                        }
                    })
                }
            }
        }
    }
    
}

