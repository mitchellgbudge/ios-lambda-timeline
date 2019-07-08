//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos

class ImagePostViewController: ShiftableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageViewHeight(with: 1.0)
        
        updateViews()
    }
    
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                title = "New Post"
                return
        }
        
        title = post?.title
        
        setImageViewHeight(with: image.ratio)
        
        imageView.image = originalImage
        
        chooseImageButton.setTitle("", for: [])
    }
    
    func updateImage() {
        if let originalImage = originalImage {
            imageView.image = image(byFiltering: originalImage)
        }
    }
    
    private func image(byFiltering image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        exposureFilter.setValue(ciImage, forKey: "inputImage")
        exposureFilter.setValue(exposureSlider.value, forKey: "inputEV")
        guard let exposureCIImage = exposureFilter.outputImage else { return image }
        sepiaFilter.setValue(exposureCIImage, forKey: "inputImage")
        sepiaFilter.setValue(sepiaSlider.value, forKey: "inputIntensity")
        guard let sepiaCIImage = sepiaFilter.outputImage else { return image }
        vibranceFilter.setValue(sepiaCIImage, forKey: "inputImage")
        vibranceFilter.setValue(vibranceSlider.value, forKey: "inputAmount")
        guard let vibranceCIImage = vibranceFilter.outputImage else { return image }
        monoFilter.setValue(vibranceCIImage, forKey: "inputImage")
        monoFilter.setValue(monoSlider, forKey: "inputSharpness")
        guard let monoCIImage = monoFilter.outputImage else { return image }
        vignetteFilter.setValue(monoCIImage, forKey: "inputImage")
        vignetteFilter.setValue(vignetteSlider.value, forKey: "inputRadius")
        vignetteFilter.setValue(vignetteSlider.value, forKey: "inputIntensity")
        guard let vignetteCIImage = vignetteFilter.outputImage else { return image }
        guard let outputCGImage = context.createCGImage(vignetteCIImage, from: vignetteCIImage.extent) else { return image }
        return UIImage(cgImage: outputCGImage)
    }
    
    @IBAction func exposureValueChanged(_ sender: Any) {
        updateImage()
    }
    
    @IBAction func sepiaValueChanged(_ sender: Any) {
        updateImage()
    }
    
    @IBAction func vibranceValueChanged(_ sender: Any) {
        updateImage()
    }
    
    @IBAction func monoValueChanged(_ sender: Any) {
        updateImage()
    }
    
    @IBAction func vignetteValueChanged(_ sender: Any) {
        updateImage()
    }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
            presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
            return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        }
        presentImagePickerController()
    }
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
    
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    var originalImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    
    let exposureFilter = CIFilter(name: "CIExposureAdjust")!
    let sepiaFilter = CIFilter(name: "CISepiaTone")!
    let vibranceFilter = CIFilter(name: "CIVibrance")!
    let monoFilter = CIFilter(name: "CISharpenLuminance")!
    let vignetteFilter = CIFilter(name: "CIVignette")!
    let context = CIContext(options: nil)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    @IBOutlet weak var exposureSlider: UISlider!
    @IBOutlet weak var sepiaSlider: UISlider!
    @IBOutlet weak var vibranceSlider: UISlider!
    @IBOutlet weak var monoSlider: UISlider!
    @IBOutlet weak var vignetteSlider: UISlider!
    
}

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        originalImage = image
        
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
