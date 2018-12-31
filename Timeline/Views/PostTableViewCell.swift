//
//  PostTableViewCell.swift
//  Timeline
//
//  Created by Travis Chapman on 11/7/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import UIKit

// MARK: - Class Declaration

class PostTableViewCell: UITableViewCell {
    
    // MARK: - Constants & Variables
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postCaptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        postCaptionLabel.text = nil
        postImageView.image = nil
    }

    // MARK: - Functions
    
    func updateViews() {
        
        postImageView.image = post?.photo
        postCaptionLabel.text = post?.caption
    }
}
