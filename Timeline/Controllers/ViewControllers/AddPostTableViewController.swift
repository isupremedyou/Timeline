//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Travis Chapman on 11/8/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import UIKit

// MARK: - Class Declaration

class AddPostTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var image: UIImage?
    
    // MARK: - Outlets
    
    @IBOutlet weak var captionTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    // MARK: - Actions
    
    @IBAction func addPostButtonTapped(_ sender: UIButton) {
        
        if let image = self.image, let caption = captionTextField.text, !caption.isEmpty {
            
            PostController.shared.createPostWith(image: image, andCaption: caption) { (post) in
                
                print("Succesfully submitted the post")
                DispatchQueue.main.async {
                    self.tabBarController?.selectedIndex = 1
                }
            }
        } else {
            let missingInfoAC = UIAlertController(title: "Whoops!", message: "Looks like you are either missing a caption or an image, please try again!", preferredStyle: .alert)
            
            let dismissAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            missingInfoAC.addAction(dismissAction)
            
            present(missingInfoAC, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func tableViewTapped(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    
    // MARK: - Functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "embedPhotoSelectVC" {
            guard let destinationVC = segue.destination as? PhotoSelectViewController else { return }
            
            destinationVC.delegate = self
        }
    }
}

// MARK: - Extensions

extension AddPostTableViewController: PhotoSelectViewControllerDelegate {
    
    func photoSelectViewControllerSelected(image: UIImage) {
        
        self.image = image
    }
}
