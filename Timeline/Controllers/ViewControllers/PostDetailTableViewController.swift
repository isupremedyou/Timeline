//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Travis Chapman on 11/6/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import UIKit

// MARK: - Class Declaration

class PostDetailTableViewController: UITableViewController {
    
    // MARK: - Constants & Variables
    
    var post: Post? {
        didSet {
            self.loadViewIfNeeded()
            updateViews()
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var followPostButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshComments), name: PostController.PostCommentsChangedNotification, object: post)
    }
    
    // MARK: - Actions
    
    @IBAction func refreshControlPulled(_ sender: UIRefreshControl) {
        
        refreshComments()
    }
    
    @IBAction func commentButtonTapped(_ sender: UIButton) {
        
        let getCommentAC = UIAlertController(title: "Comment", message: "Type your comment and press \"Submit\"", preferredStyle: .alert)
        
        getCommentAC.addTextField { (commentTextField) in
            commentTextField.placeholder = "Enter your comment..."
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            guard let comment = getCommentAC.textFields?.first?.text,
                !comment.isEmpty, let post = self.post else { return }
            
            PostController.shared.addComment(toPost: post, withText: comment, completion: { (comment) in
                print("comment successfully posted")
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
        
        getCommentAC.addAction(cancelAction)
        getCommentAC.addAction(submitAction)
        
        present(getCommentAC, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        
        guard let photo = postImageView.image, let caption = captionLabel.text else { return }
        
        let activityController = UIActivityViewController(activityItems: [photo, caption], applicationActivities: nil)
        
        present(activityController, animated: true, completion: nil)
    }
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
        
        
        guard let post = post else { return }

        PostController.shared.toggleSubscriptionTo(commentsForPost: post) { (successful, isSubscribed, error) in
            if let error = error {
                print("Error: \n\(#function)\n\(error)\n\(error.localizedDescription)")
                // Present an alert controller
                return
            }
            
            DispatchQueue.main.async {
                
                if successful {
                    if isSubscribed {
                        self.followPostButton.titleLabel?.text = "Unfollow"
                        print("Subscribed!")
                    } else {
                        self.followPostButton.titleLabel?.text = "Follow"
                        print("Unsubscribed!")
                    }
                } else {
                    print("Unsuccesful")
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let post = post else { return 0 }
        return post.comments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        
        guard let post = post else { return UITableViewCell() }
        let comment = post.comments[indexPath.row]
        
        cell.textLabel?.text = comment.text
        cell.detailTextLabel?.text = comment.timestamp.asString
        
        return cell
    }
    
    
    // MARK: - Functions
    
    @objc func refreshComments() {
        
        PostController.shared.fetchCommentsFor(post: post!) { (succesful) in
            if succesful {
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func updateViews() {
        
        guard let post = post else { return }
        postImageView.image = post.photo
        captionLabel.text = post.caption
        
        PostController.shared.checkSubscriptionToPostComments(forPost: post) { (isSubscribed) in
            
            DispatchQueue.main.async {
                if isSubscribed {
                    self.followPostButton.titleLabel?.text = "Unfollow"
                } else {
                    self.followPostButton.titleLabel?.text = "Follow"
                }
            }
        }
    }
}
