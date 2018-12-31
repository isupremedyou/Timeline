//
//  Post.swift
//  Timeline
//
//  Created by Travis Chapman on 11/6/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

// MARK: - Imports

import UIKit
import CloudKit

// MARK: - Class Declaration

class Post {
    
    // MARK: - Constants
    
    static let captionKey = "caption"
    static let photoDataKey = "photoData"
    static let timestampKey = "timestamp"
    
    // MARK: - Properties
    
    let caption: String
    let timestamp: Date
    let photoData: Data?
    var comments: [Comment] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PostController.PostCommentsChangedNotification, object: self)
            }
        }
    }
    var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
    var recordType: String {
        return "Post"
    }
    private var temporaryPhotoURL: URL {
        
        // Must write to temporary directory to be able to pass image file path url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        
        let temporaryDirectoryURL = URL(fileURLWithPath: temporaryDirectory)
        
        let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        
        try? photoData?.write(to: fileURL, options: [.atomic])
        
        return fileURL
        
    }
    var cloudKitRecordID: CKRecord.ID?
    var cloudKitRecord: CKRecord {
        
        let ckAsset = CKAsset(fileURL: temporaryPhotoURL)
        
        if let cloudKitRecordID = cloudKitRecordID {
            
            let ckRecord = CKRecord(recordType: recordType, recordID: cloudKitRecordID)
            ckRecord.setValue(timestamp, forKey: Post.timestampKey)
            ckRecord.setValue(caption, forKey: Post.captionKey)
            ckRecord.setValue(ckAsset, forKey: Post.photoDataKey)
            return ckRecord
        } else {
            
            let ckRecord = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: UUID().uuidString))
            ckRecord.setValue(timestamp, forKey: Post.timestampKey)
            ckRecord.setValue(caption, forKey: Post.captionKey)
            ckRecord.setValue(ckAsset, forKey: Post.photoDataKey)
            return ckRecord
        }
    }
    
    // MARK: - Initializers
    
    init(withCaption caption: String, photoData: Data,
         timestamp: Date = Date(), comments: [Comment] = [Comment]()) {
        
        self.caption = caption
        self.timestamp = timestamp
        self.photoData = photoData
        self.comments = comments
    }
    
    convenience init?(ckRecord: CKRecord) {
        
        guard let caption = ckRecord[Post.captionKey] as? String,
            let ckAsset = ckRecord[Post.photoDataKey] as? CKAsset,
            let timestamp = ckRecord[Post.timestampKey] as? Date
            else { return nil }
        
        do {
            let data = try Data(contentsOf: ckAsset.fileURL)
            self.init(withCaption: caption, photoData: data, timestamp: timestamp, comments: [])
            self.cloudKitRecordID = ckRecord.recordID
        } catch let error {
            print("Error getting CKasset data from CloudKit: \n\(#function)\n\(error)\n\(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Post Class Extensions

extension Post: Equatable {
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return  lhs.timestamp == rhs.timestamp
        
    }
}

extension Post: SearchableRecord {
    
    func matches(searchTerm: String) -> Bool {
        
        let spacesAndPuncCharSet = NSMutableCharacterSet.whitespace()
        spacesAndPuncCharSet.formUnion(with: .punctuationCharacters)
        
        let wordsFromCaption = self.caption.components(separatedBy: spacesAndPuncCharSet as CharacterSet)
        
        for word in wordsFromCaption {
            
            if word == searchTerm {
                return true
            }
        }
        
        for comment in self.comments {
            
            return comment.matches(searchTerm: searchTerm)
        }
        
        return false
    }
}
