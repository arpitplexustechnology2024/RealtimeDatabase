//
//  ViewController.swift
//  RealtimeDatabase
//
//  Created by Arpit iOS Dev. on 20/06/24.
//

import UIKit
import Photos
import FirebaseDatabase
import FirebaseStorage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnSaveProduct: UIButton!
    @IBOutlet weak var btnShowProduct: UIButton!
    @IBOutlet var weightKg: [UIButton]!
    @IBOutlet weak var weightsDrop: UIButton!
    @IBOutlet weak var weightsStackView: UIStackView!
    @IBOutlet weak var weightsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        shadowView()
        activityIndicator.isHidden = true
        activityIndicator.style = .large
        self.imageView.layer.cornerRadius = 20
        self.descriptionTextView.layer.cornerRadius = 5
        self.titleTextField.layer.cornerRadius = 5
        self.descriptionTextView.layer.borderWidth = 1
        self.titleTextField.layer.borderWidth = 1
        self.descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        self.titleTextField.layer.borderColor = UIColor.systemGray4.cgColor
        self.btnSaveProduct.layer.cornerRadius = 20
        self.btnShowProduct.layer.cornerRadius = 20
        self.weightsView.layer.borderWidth = 1
        self.weightsView.layer.borderColor = UIColor.systemGray4.cgColor
        self.weightsView.layer.cornerRadius = 5
        self.weightsStackView.layer.borderWidth = 1
        self.weightsStackView.layer.borderColor = UIColor.systemGray4.cgColor
        self.weightsStackView.layer.cornerRadius = 5
        
        weightKg.forEach { btn in
            btn.isHidden = true
            btn.alpha = 0
        }
    }
    
    @IBAction func btnDSaveProduct(_ sender: UIButton) {
        showLoader()
        guard let productName = titleTextField.text, !productName.isEmpty,
              let productDescription = descriptionTextView.text, !productDescription.isEmpty,
              let productWeight = weightTextField.text, !productWeight.isEmpty,
              let productImage = imageView.image else {
            hideLoader()
            let snackbar = TTGSnackbar(message: "Please enter valid product details and select an image.", duration: .middle)
            snackbar.show()
            return
        }
        
        guard let imageData = productImage.jpegData(compressionQuality: 0.3) else {
            hideLoader()
            print("Failed to convert image to data.")
            return
        }
        
        // Upload image to Firebase Storage
        DispatchQueue.global(qos: .background).async {
            let storageRef = Storage.storage().reference().child("productImages").child("\(UUID().uuidString).jpg")
            storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                guard let _ = metadata else {
                    DispatchQueue.main.async {
                        self.hideLoader()
                        print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                    return
                }
                
                
                storageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        self.hideLoader()
                        print("Error retrieving image URL: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    let product = [
                        "productName": productName,
                        "productDescription": productDescription,
                        "productWeight": productWeight,
                        "productImageUrl": downloadURL.absoluteString
                    ]
                    
                    let productsRef = Database.database().reference().child("products")
                    let productRef = productsRef.childByAutoId()
                    
                    productRef.setValue(product) { (error, ref) in
                        
                        if let error = error {
                            DispatchQueue.main.async {
                                self.hideLoader()
                                print("Error saving product: \(error.localizedDescription)")
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.hideLoader()
                                let snackbar = TTGSnackbar(message: "Product saved successfully.", duration: .middle)
                                snackbar.show()
                                self.clearTextFields()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func btnShowProductTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            if let productListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProductListViewController") as? ProductListViewController {
                self.navigationController?.pushViewController(productListVC, animated: true)
            }
        }
    }
    
    func showLoader() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    func hideLoader() {
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
    }
    
    func clearTextFields() {
        titleTextField.text = ""
        descriptionTextView.text = ""
        weightTextField.text = ""
        imageView.image = nil
    }
    
    
    @IBAction func btnCrashlyticsTapped(_ sender: UIButton) {
        let numbers = [0]
        let _ = numbers[1]
    }
    
    
    
    
    // MARK: - Select Image -
    @IBAction func selectImage(_ sender: UIButton) {
        checkPhotoLibraryPermission { granted in
            if granted {
                self.showImagePickerController(sourceType: .photoLibrary)
            } else {
                self.showSettingsAlert()
            }
        }
    }
    
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status == .authorized)
                }
            }
        case .limited: break
        @unknown default:
            completion(false)
        }
    }
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("\(sourceType) not available")
            return
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func showSettingsAlert() {
        let alertController = UIAlertController(
            title: "Photo Library Access Needed",
            message: "Please allow access to the photo library in settings to select a photo.",
            preferredStyle: .alert
        )
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { success in
                    print("Settings opened: \(success)")
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ pickerController: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImages = info[.originalImage] as? UIImage {
            imageView.image = selectedImages
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func wightsKg(_ sender: Any) {
        if let btn1 = (sender as AnyObject).titleLabel?.text {
            self.weightTextField.text = btn1
            animate(toggel: false)
        }
    }
    
    
    @IBAction func weightsDrop(_ sender: UIButton) {
        weightKg.forEach { btn in
            UIView.animate(withDuration: 0.5) {
                btn.isHidden = !btn.isHidden
                btn.alpha = btn.alpha == 0 ? 1 : 0
            }
            
        }
    }
    
    // MARK: - Animation Function
    func animate(toggel: Bool) {
        if toggel {
            weightKg.forEach { btn in
                UIView.animate(withDuration: 0.5) {
                    btn.isHidden = false
                    btn.alpha = btn.alpha == 0 ? 1 : 0
                }
            }
        } else {
            weightKg.forEach { btn in
                UIView.animate(withDuration: 0.5) {
                    btn.isHidden = true
                    btn.alpha = btn.alpha == 0 ? 1 : 0
                }
            }
        }
    }
}

extension ViewController {
    
    func shadowView() {
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.shadowOffset = CGSize(width: 5, height: 5)
        backgroundView.layer.shadowRadius = 10
        backgroundView.layer.shadowPath = UIBezierPath(rect: backgroundView.bounds).cgPath
        backgroundView.layer.cornerRadius = 20
    }
}


