//
//  Comment.swift
//  Timeline
//
//  Created by Travis Chapman on 11/6/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import Foundation
import CloudKit

// MARK: - Class Declaration

class Comment {
    
    // MARK: - Constants
    static let textKey = "text"
    static let timestampKey = "timestamp"
    static let postCKRef = "postRef"
    
    // MARK: - Properties
    
    let text: String
    let timestamp: Date
    let post: Post
    let recordType: String = {
        
        return "Comment"
    }()
    var cloudKitRecordID: CKRecord.ID?
    var postRef: CKRecord.Reference
    var cloudKitRecord: CKRecord {
        
        if let ckRecordID = cloudKitRecordID {
            let ckRecord = CKRecord(recordType: recordType, recordID: ckRecordID)
            ckRecord.setValue(text, forKey: Comment.textKey)
            ckRecord.setValue(timestamp, forKey: Comment.timestampKey)
            ckRecord.setValue(postRef, forKey: Comment.postCKRef)
            return ckRecord
        } else {
            let ckRecord = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: UUID().uuidString))
            ckRecord.setValue(text, forKey: Comment.textKey)
            ckRecord.setValue(timestamp, forKey: Comment.timestampKey)
            ckRecord.setValue(postRef, forKey: Comment.postCKRef)
            return ckRecord
        }
    }
    
    // MARK: - Initializers
    
    init(withText text: String, post: Post, timestamp: Date = Date()) {
        
        self.text = text
        self.timestamp = timestamp
        self.post = post
        self.postRef = CKRecord.Reference(recordID: post.cloudKitRecordID!, action: .deleteSelf)
    }
    
    convenience init?(ckRecord: CKRecord, post: Post) {
        
        guard let text = ckRecord[Comment.textKey] as? String,
            let timestamp = ckRecord[Comment.timestampKey] as? Date,
            let postRef = ckRecord[Comment.postCKRef] as? CKRecord.Reference
            else { return nil }
        
        self.init(withText: text, post: post, timestamp: timestamp)
        self.cloudKitRecordID = ckRecord.recordID
        self.postRef = postRef
    }
}

// MARK: - Comment Class Extensions

extension Comment: Equatable {
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.text == rhs.text &&
                lhs.timestamp == rhs.timestamp &&
                lhs.post == rhs.post
    }
}

extension Comment: SearchableRecord {
    
    func matches(searchTerm: String) -> Bool {
        
        let spacesAndPuncCharSet = NSMutableCharacterSet.whitespace()
        spacesAndPuncCharSet.formUnion(with: .punctuationCharacters)
        
        let wordsFromComment = self.text.components(separatedBy: spacesAndPuncCharSet as CharacterSet)
        
        for word in wordsFromComment {
            
            if word == searchTerm {
                return true
            }
        }
        
        return false
    }
}
