//
//  PhotoSelectViewController.swift
//  Timeline
//
//  Created by Travis Chapman on 11/11/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import UIKit

protocol PhotoSelectViewControllerDelegate: class {
    
    func photoSelectViewControllerSelected(image: UIImage)
}

// MARK: - Class Declaration

class PhotoSelectViewController: UIViewController {
    
    // MARK: - Variables
    
    weak var delegate: PhotoSelectViewControllerDelegate?

    // MARK: - Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func selectImageButtonTapped(_ sender: UIButton) {
    
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePickerController.sourceType = .savedPhotosAlbum
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Extensions

extension PhotoSelectViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let photo = info[.originalImage] as? UIImage else {
            print("Error getting selected image")
            return
        }
        
        photoImageView.image = photo
        
        delegate?.photoSelectViewControllerSelected(image: photo)
        
        picker.dismiss(animated: true, completion: nil)
    }
}
