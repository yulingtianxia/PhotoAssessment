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
    
    
    let helper = PhotoAssessmentHelper()
    
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
        assessmentLabel.text = "Processing..."
        detailLabel.text = ""
        if let url = info[.imageURL] as? URL {
            DispatchQueue.global().async {
                var start = Date()
                let downsampleDimension = 500
                start = Date()
                if let downsampleImage = downsample(url: url, maxDimension: downsampleDimension) {
                    print("downsample duration:\(Date().timeIntervalSince(start))")
                    self.helper.requestMLAssessmentScore(for: downsampleImage, completionHandler: { (score) in
                        DispatchQueue.main.async {
                            self.assessmentLabel.text = String(format: "Assessment Score:%0.5f", score)
                        }
                    })
                    self.helper.requestMPSAssessmentScore(for: downsampleImage, completionHandler: { (result) in
                        DispatchQueue.main.async {
                            self.detailLabel.text = result.description
                        }
                    })
                }
            }
        }
    }
    
}

