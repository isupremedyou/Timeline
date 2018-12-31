//
//  PostController.swift
//  Timeline
//
//  Created by Travis Chapman on 11/7/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import UIKit
import CloudKit


// MARK: - Class Declaration

class PostController {
    
    // MARK: - Notifications
    
    static let PostsChangedNotification = NSNotification.Name("PostsChangedNotification")
    static let PostCommentsChangedNotification = NSNotification.Name("PostCommentsChangedNotification")
    
    // MARK: - Singleton Class/Static Property
    
    static let shared = PostController()
    private init() { subscribeToNewPosts(completion: nil) }
    
    // MARK: - Source of truth
    
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PostController.PostsChangedNotification, object: nil)
            }
        }
    }
    let publicDB = CKContainer.default().publicCloudDatabase
    
    // MARK: - Functions
    
    func addComment(toPost post: Post, withText text: String, completion: @escaping (Comment?) -> Void) {
        
        // Initialize a comment object
        let comment = Comment(withText: text, post: post)
        
        // Get and unwrap the index of the post argument
        guard let index = posts.index(of: post) else {
            print("Could not locate post in array of posts")
            completion(nil)
            return
        }
        
        let ckRecord = comment.cloudKitRecord
        
        CloudKitManager.shared.saveRecordToCloudKit(record: ckRecord, database: publicDB) { (record, error) in
            if let error = error {
                print("Error: \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion(nil)
                return
            }
            
            comment.cloudKitRecordID = record?.recordID
            // Append the comments array for the post at the index matching the above post
            self.posts[index].comments.append(comment)
            completion(comment)
        }
        
    }
    
    func createPostWith(image: UIImage, andCaption caption: String, completion: @escaping (Post?) -> Void) {
        
        guard let photoData = image.pngData() else { completion(nil) ; return }
        
        let post = Post(withCaption: caption, photoData: photoData)
        
        let ckRecord = post.cloudKitRecord
        
        CloudKitManager.shared.saveRecordToCloudKit(record: ckRecord, database: publicDB) { (record, error) in
            
            if let error = error {
                print("Error: \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion(nil)
                return
            }
            
            post.cloudKitRecordID = record?.recordID
            
            self.posts.append(post)
            completion(post)
        }
    }
    
    // MARK: - Subscription Functions
    
    func subscribeToNewPosts(completion: ((Bool, Error?) -> Void)? = nil) {

        CloudKitManager.shared.subscribeToCreationOfRecordsOf(type: "Post", database: publicDB, subscriptionID: "AllNewPosts", withNotificationTitle: "New Post", alertBody: "A new post has been added to Timeline, check it out!", andSoundName: nil) { (subscription, error) in
            if let error = error {
                print("Error: could not save subscription \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion?(false, error)
                return
            }
            
            guard let _ = subscription else { completion?(false, nil) ; return }
            
            completion?(true, nil)
        }
    }
    
    func checkSubscriptionToPostComments(forPost post: Post, completion: ((Bool) -> Void)? = nil) {
        
        guard let recordID = post.cloudKitRecordID?.recordName else { completion?(false) ; return}
        
        CloudKitManager.shared.checkForSubscriptionWith(subscriptionID: recordID, database: publicDB) { (subscription, error) in
            if let error = error {
                print("Error: while trying to check for subscription \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion?(false)
                return
            }
            
            guard subscription != nil else { completion?(false) ; return }
            
            completion?(true)
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Bool, Error?) -> Void)? = nil) {
        
        checkSubscriptionToPostComments(forPost: post) { (isSubscribed) in
            
            if isSubscribed {
                self.removeSubscriptionTo(commentsForPost: post, completion: { (wasRemoved, error) in
                    if let error = error {
                        print("Error: while trying to remove subscription \n\(#function)\n\(error)\n\(error.localizedDescription)")
                        completion?(false, true, error)
                        return
                    }
                    
                    completion?(true, false, nil)
                })
            } else {
                self.addSubscriptionTo(commentsForPost: post, alertBody: nil, completion: { (successful, error) in
                    if let error = error {
                        print("Error: while trying to create a subscription \n\(#function)\n\(error)\n\(error.localizedDescription)")
                        completion?(false, false, error)
                        return
                    }
                    
                    completion?(true, true, nil)
                })
            }
        }
    }
    
    func addSubscriptionTo(commentsForPost post: Post, alertBody: String?, completion: ((Bool, Error?) -> Void)? = nil) {
        
        guard let recordID = post.cloudKitRecordID else { completion?(false, nil) ; return}
        
        let predicate = NSPredicate(format: "postRef == %@", recordID)
        
        CloudKitManager.shared.subscribeToCreationOfRecordsOf(type: "Comment", database: publicDB, predicate: predicate, subscriptionID: recordID.recordName, withNotificationTitle: "New Comment!", alertBody: "A new comment was posted on a post you follow, check it out!", andSoundName: nil) { (subscription, error) in
            
            if let error = error {
                print("Error: could not save subscription \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion?(false, error)
                return
            }
            
            guard let _ = subscription else { completion?(false, nil) ; return }
            
            completion?(true, nil)
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> Void)? = nil) {
        
        guard let postRecordID = post.cloudKitRecordID?.recordName else { completion?(false, nil) ; return }
        
        CloudKitManager.shared.deleteSubscriptionWith(subscriptionID: postRecordID, database: publicDB) { (subscriptionID, error) in
            if let error = error {
                print("Error: could not save subscription \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion?(false, error)
                return
            }
            
            if subscriptionID != nil {
                print("Success deleting the subscription!")
                completion?(true, error)
            } else {
                completion?(false, nil)
            }
        }
    }
    
    // MARK: - Fetching Functions
    
    func fetchPosts(completion: @escaping (Bool) -> () = {_ in }) {
        
        let predicate = NSPredicate(value: true)
        
        CloudKitManager.shared.fetchRecordsOf(type: "Post", predicate: predicate, database: publicDB, zoneID: nil) { (records, error) in
            if let error = error {
                print("Error: \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let records = records else { completion(false) ; return }
            
            let posts = records.compactMap({ Post(ckRecord: $0) })
            
            let group = DispatchGroup()
            
            for post in posts {
                
                group.enter()
                self.fetchCommentsFor(post: post, completion: { (success) in
                    
                    if success {
                        group.leave()
                    }
                })
            }
            
            group.notify(queue: .main, execute: {
                self.posts = posts
                completion(true)
            })
        }
    }
    
    func fetchCommentsFor(post: Post, completion: @escaping (Bool) -> () = {_ in }) {
        
        let ckReference = CKRecord.Reference(recordID: post.cloudKitRecordID!, action: .deleteSelf)
        
        let predicate = NSPredicate(format: "%K == %@", Comment.postCKRef, ckReference)
        
        CloudKitManager.shared.fetchRecordsOf(type: "Comment", predicate: predicate, database: publicDB, zoneID: nil) { (records, error) in
            if let error = error {
                print("Error: \n\(#function)\n\(error)\n\(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let comments = records?.compactMap({ Comment(ckRecord: $0, post: post) }) else { completion(false) ; return }
            
            post.comments = comments
            
            completion(true)
        }
    }
}
