//
//  CloudKitManager.swift
//  Timeline
//
//  Created by Travis Chapman on 11/11/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

import UIKit
import CloudKit

class CloudKitManager {
    
    static let shared = CloudKitManager()
    
    // MARK: - Fetch Records
    
    func fetchRecordsOf(type: String,
                        predicate: NSPredicate = NSPredicate(value: true),
                        database: CKDatabase,
                        zoneID: CKRecordZone.ID? = nil,
                        completion: @escaping ([CKRecord]?, Error?) -> Void) {
        
        let query = CKQuery(recordType: type, predicate: predicate)
        
        database.perform(query, inZoneWith: zoneID, completionHandler: completion)
    }
    
    func fetchRecord(withID recordID: CKRecord.ID, database: CKDatabase, completion: ((_ record: CKRecord?, _ error: Error?) -> Void)?) {
        
        database.fetch(withRecordID: recordID) { (record, error) in
            
            completion?(record, error)
        }
    }
    
    // MARK: - Create Records
    
    func saveRecordToCloudKit(record: CKRecord, database: CKDatabase, completion: @escaping (CKRecord?, Error?) -> Void) {
        
        database.save(record, completionHandler: completion)
    }
    
    func saveRecordsToCloudKit(records: [CKRecord], database: CKDatabase, perRecordCompletion: ((CKRecord?, Error?) -> Void)?, completion: (([CKRecord]?, [CKRecord.ID]?, Error?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        operation.queuePriority = .high
        operation.qualityOfService = .userInteractive
        operation.savePolicy = .changedKeys
        
        operation.perRecordCompletionBlock = perRecordCompletion
        operation.modifyRecordsCompletionBlock = completion
        
        database.add(operation)
    }
    
    // MARK: - Delete Records
    
    func deleteRecordWithID(_ recordID: CKRecord.ID, database: CKDatabase, completion: ((_ recordID: CKRecord.ID?, _ error: Error?) -> Void)?) {
        
        database.delete(withRecordID: recordID) { (recordID, error) in
            completion?(recordID, error)
        }
    }
    
    func deleteRecordsWithID(_ recordIDs: [CKRecord.ID], database: CKDatabase, completion: ((_ records: [CKRecord]?, _ recordIDs: [CKRecord.ID]?, _ error: Error?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .ifServerRecordUnchanged
        
        operation.modifyRecordsCompletionBlock = completion
        
        database.add(operation)
    }
    
    // MARK: - Subscriptions
    
    func subscribeToCreationOfRecordsOf(type: String,
                                        database: CKDatabase,
                                        predicate: NSPredicate = NSPredicate(value: true),
                                        subscriptionID: String,
                                        withNotificationTitle title: String?,
                                        alertBody: String?,
                                        andSoundName soundName: String?,
                                        completion: @escaping (CKSubscription?, Error?) -> Void) {
        
        let subscription = CKQuerySubscription(recordType: type, predicate: predicate, subscriptionID: subscriptionID, options: .firesOnRecordCreation)
        
        
        // Notification info lets us choose what will be displayed on the banner (if anything at all)
        let notificationInfo = CKSubscription.NotificationInfo()
        
        notificationInfo.title = title
        notificationInfo.alertBody = alertBody
        notificationInfo.soundName = soundName
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription, completionHandler: completion)
    }
    
    func checkForSubscriptionWith(subscriptionID: String, database: CKDatabase, completion: @escaping (CKSubscription?, Error?) -> Void) {
        
        database.fetch(withSubscriptionID: subscriptionID, completionHandler: completion)
    }
    
    func deleteSubscriptionWith(subscriptionID: String, database: CKDatabase,
                                completion: @escaping (String?, Error?) -> Void) {
        
        database.delete(withSubscriptionID: subscriptionID, completionHandler: completion)
    }
    
    
    // MARK: - User Discoverability
    
    /// Fetches the `Users` CKRecord of the user that is currently signed in to iCloud on their device
    func fetchLoggedInUserRecord(_ completion: ((_ record: CKRecord?, _ error: Error? ) -> Void)?) {
        
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            
            if let error = error,
                let completion = completion {
                completion(nil, error)
            }
            
            if let recordID = recordID,
                let completion = completion {
                
                // Apple `Users` records can only exist on the Public Database
                self.fetchRecord(withID: recordID, database: CKContainer.default().publicCloudDatabase, completion: completion)
            }
        }
    }
    
    
    /// Fetches all user identities that meet these requirements:
    ///  1. Have granted User Discoverability permission
    ///  2. They exist in the current user's contacts list.
    ///
    /// - Remark: You should be aware of these limitations (especially the latter) when choosing to use User Discoverability.
    
    func fetchAllDiscoverableUsers(completion: @escaping ((_ userInfoRecords: [CKUserIdentity]?) -> Void) = { _ in }) {
        
        let operation = CKDiscoverAllUserIdentitiesOperation()
        
        var userIdenties = [CKUserIdentity]()
        operation.userIdentityDiscoveredBlock = { userIdenties.append($0) }
        operation.discoverAllUserIdentitiesCompletionBlock = { error in
            if let error = error {
                NSLog("Error discovering all user identies: \(error)")
                completion(nil)
                return
            }
            
            completion(userIdenties)
        }
        
        CKContainer.default().add(operation)
    }
    
    func fetchUserIdentityWith(email: String, completion: @escaping (CKUserIdentity?, Error?) -> Void) {
        CKContainer.default().discoverUserIdentity(withEmailAddress: email, completionHandler: completion)
    }
    
    func fetchUserIdentityWith(phoneNumber: String, completion: @escaping (CKUserIdentity?, Error?) -> Void) {
        CKContainer.default().discoverUserIdentity(withPhoneNumber: phoneNumber, completionHandler: completion)
    }
    
    
    /**
     Requests permission from the user to allow User Discoverability on their iCloud account. This permission from the user is required in order to use User Discoverability.
     
     This function will call the `handleCloudKitPermissionStatus` function (and by extension, the  `displayCloudKitPermissionsNotGrantedError` function) to make a potential error message and display it to the user if they either denied permission or there was an error of some sort.
     
     */
    
    func requestDiscoverabilityPermission() {
        
        CKContainer.default().status(forApplicationPermission: .userDiscoverability) { (permissionStatus, error) in
            
            if permissionStatus == .initialState {
                CKContainer.default().requestApplicationPermission(.userDiscoverability, completionHandler: { (permissionStatus, error) in
                    
                    self.handleCloudKitPermissionStatus(permissionStatus, error: error)
                })
            } else {
                self.handleCloudKitPermissionStatus(permissionStatus, error: error)
            }
        }
    }
    
    /// Based on the permission status passed in from the `requestDiscoverabilityPermission` function, an `errorText` String will be created if the `permissionStatus` is not `granted`. If the function makes `errorText`, it will then be passed into the `displayCloudKitPermissionsNotGrantedError` function to be displayed to the user.
    private func handleCloudKitPermissionStatus(_ permissionStatus: CKContainer_Application_PermissionStatus, error: Error?) {
        
        if permissionStatus == .granted {
            print("User Discoverability permission granted. User may proceed with full access.")
        } else {
            var errorText = "Synchronization is disabled\n"
            if let error = error {
                print("handleCloudKitUnavailable ERROR: \(error)")
                print("An error occured: \(error.localizedDescription)")
                errorText += error.localizedDescription
            }
            
            switch permissionStatus {
            case .denied:
                errorText += "You have denied User Discoverability permissions. You may be unable to use certain features that require User Discoverability."
            case .couldNotComplete:
                errorText += "Unable to verify User Discoverability permissions. You may have a connectivity issue. Please try again."
            default:
                break
            }
            
            displayCloudKitPermissionsNotGrantedError(errorText)
        }
    }
    
    /// Creates and presents a `UIAlertController` with the error message made in the `handleCloudKitPermissionStatus` function so the user can see what the problem is, and potentially be able to fix it.
    private func displayCloudKitPermissionsNotGrantedError(_ errorText: String) {
        
        DispatchQueue.main.async(execute: {
            
            let alertController = UIAlertController(title: "CloudKit Permissions Error", message: errorText, preferredStyle: .alert)
            
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil);
            
            alertController.addAction(dismissAction)
            
            if let appDelegate = UIApplication.shared.delegate,
                let appWindow = appDelegate.window!,
                let rootViewController = appWindow.rootViewController {
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    
    // MARK: - Sharing
    
    var sharingZoneID: CKRecordZone.ID = {
        return CKRecordZone.ID(zoneName: "SharingZone", ownerName: CKCurrentUserDefaultName)
    }()
    
    private let sharedRecordZoneIDsKey = "sharedRecordZoneIDs"
    
    /// In order to share `CKRecords` through `CKShare` objects, the original records must be stored in a custom `CKRecordZone` in the private `CKDatabase`. This function will create that zone in preparation for the records to be saved there. It also ensures that the zone is only created once.
    ///
    /// - Remark:
    /// If this function does not get called (thus the custom `CKRecordZone` never gets created), when you try to save records to it, it will fail. Make sure this function is called before you try to save records to the custom zone.
    
    func createSharingZone() {
        
        let sharingZoneHasBeenCreatedKey = "sharingZoneHasBeenCreated"
        
        guard UserDefaults.standard.bool(forKey: sharingZoneHasBeenCreatedKey) == false else { return }
        
        let sharingZone = CKRecordZone(zoneID: sharingZoneID)
        
        let modifyZonesOperation = CKModifyRecordZonesOperation(recordZonesToSave: [sharingZone], recordZoneIDsToDelete: nil)
        
        modifyZonesOperation.modifyRecordZonesCompletionBlock = { (_, _, error) in
            
            if let error = error {
                print("Error saving sharing zone to CloudKit: \(error.localizedDescription)")
            } else {
                UserDefaults.standard.set(true, forKey: sharingZoneHasBeenCreatedKey)
            }
        }
        
        CKContainer.default().privateCloudDatabase.add(modifyZonesOperation)
    }
    
    func createCloudSharingControllerWith(cloudKitSharable: CloudKitSharable) -> UICloudSharingController {
        
        let cloudSharingController = UICloudSharingController { (cloudSharingController, preparationCompletionHandler) in
            
            cloudSharingController.availablePermissions = []
            
            let share = CKShare(rootRecord: cloudKitSharable.cloudKitRecord)
            
            share.setValue(cloudKitSharable.title, forKey: CKShare.SystemFieldKey.title)
            share.setValue(kCFBundleIdentifierKey, forKey: CKShare.SystemFieldKey.shareType)
            
            CloudKitManager.shared.saveRecordsToCloudKit(records: [cloudKitSharable.cloudKitRecord, share], database: CKContainer.default().privateCloudDatabase, perRecordCompletion: nil, completion: { (_, _, error) in
                
                if let error = error {
                    print("Error saving share: \(error.localizedDescription)")
                }
                
                preparationCompletionHandler(share, CKContainer.default(), error)
            })
        }
        
        return cloudSharingController
    }
    
    
    /// This function will save the zoneID of the shared record the user just accepted to UserDefaults. This allows us to fetch the shared records in that zone at any time afterwards using the `fetchSharedRecordsOf(type: ...)` function in the `CloudKitManager`.
    ///
    /// - Remark: This should go in the body of the AppDelegate `userDidAcceptCloudKitShareWith` function.
    func acceptShareWith(cloudKitShareMetadata: CKShare.Metadata, completion: @escaping () -> Void) {
        
        let acceptShareOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        
        acceptShareOperation.qualityOfService = .userInteractive
        
        let savedRecordZoneIDDictionaries: [[String: String]] = UserDefaults.standard.value(forKey: sharedRecordZoneIDsKey) as? [[String: String]] ?? []
        
        var savedRecordZoneIDs = savedRecordZoneIDDictionaries.compactMap({ CKRecordZone.ID(dictionary: $0) })
        
        acceptShareOperation.perShareCompletionBlock = { (metadata, share, error) in
            
            if let error = error { print(error.localizedDescription) }
            
            let zoneIDToSave = metadata.rootRecordID.zoneID
            
            /* This makes sure that we don't accidentally add a duplicate zone ID.
             This would happen if the user accepts the same share more than once. */
            guard !savedRecordZoneIDs.contains(zoneIDToSave) else { return }
            
            savedRecordZoneIDs.append(zoneIDToSave)
        }
        
        acceptShareOperation.acceptSharesCompletionBlock = { error in
            
            if let error = error { print(error.localizedDescription) }
            
            let updatedSavedRecordZoneIDDictionaries = savedRecordZoneIDs.flatMap({ $0.dictionaryRepresentation })
            
            UserDefaults.standard.set(updatedSavedRecordZoneIDDictionaries, forKey: self.sharedRecordZoneIDsKey)
            
            completion()
        }
        
        CKContainer(identifier: cloudKitShareMetadata.containerIdentifier).add(acceptShareOperation)
    }
    
    /// This will fetch all records of a type that have been shared with and have been accepted by the user.
    func fetchSharedRecordsOf(type: String, predicate: NSPredicate = NSPredicate(value: true), completion: @escaping ([CKRecord]) -> Void) {
        
        
        guard let zoneIDDictionaries = UserDefaults.standard.value(forKey: sharedRecordZoneIDsKey) as? [[String: String]],
            zoneIDDictionaries.count > 0 else { completion([]); return }
        
        let zoneIDs = zoneIDDictionaries.compactMap({ CKRecordZone.ID(dictionary: $0) })
        
        let query = CKQuery(recordType: type, predicate: predicate)
        
        var sharedRecords: [CKRecord] = []
        
        let group = DispatchGroup()
        
        for zoneID in zoneIDs {
            
            group.enter()
            
            CKContainer.default().sharedCloudDatabase.perform(query, inZoneWith: zoneID) { (records, error) in
                if let error = error { print("Error fetching shared records: \(error.localizedDescription)") }
                
                guard let records = records else { return }
                
                sharedRecords.append(contentsOf: records)
                
                group.leave()
            }
            
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(sharedRecords)
        }
    }
}
extension CKRecordZone.ID {
    
    static var zoneNameKey = "zoneName"
    static var ownerNameKey = "ownerName"
    
    var dictionaryRepresentation: [String: String] {
        return [CKRecordZone.ID.zoneNameKey: zoneName, CKRecordZone.ID.ownerNameKey: ownerName]
    }
    
    convenience init?(dictionary: [String: String]) {
        guard let zoneName = dictionary[CKRecordZone.ID.zoneNameKey],
            let ownerName = dictionary[CKRecordZone.ID.ownerNameKey] else { return nil}
        
        self.init(zoneName: zoneName, ownerName: ownerName)
    }
}
protocol CloudKitSharable {
    var title: String { get set }
    var cloudKitRecord: CKRecord { get }
}
