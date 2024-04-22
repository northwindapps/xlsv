////
////  GoogleDriveController.swift
////  MultiDirectionCollectionView
////
////  Created by yujin on 2024/03/10.
////  Copyright © 2024 Credera. All rights reserved.
////
//
//import Foundation
//import GoogleSignIn
//import GoogleAPIClientForREST
//
//class GoogleDriveController: UIViewController {
//    let googleSignInButton = UIButton()
//    var window: UIWindow?
//    let googleDriveService = GTLRDriveService()
//    var googleUser: GIDGoogleUser?
//    var uploadFolderID: String?
//    var fileUrl : URL?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Usage example:
//        let folderName = "test"
//        let fileName = "test.txt"
//        let fileContent = "Hello, world!"
//
//        if writeToFileInSandbox(folder: folderName, filename: fileName, content: fileContent) {
//            print("File successfully written to sandbox")
//        } else {
//            print("Failed to write file to sandbox")
//        }
//        
//        let result = FileManager.default.getFileURLsInFolder(folder: "test")
//        print(result)
//        fileUrl = result?.first
//        googleInit()
//        
//    }
//    
//    func writeToFileInSandbox(folder: String, filename: String, content: String) -> Bool {
//        // Get the URL of the document directory
//        guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            print("Document directory not found")
//            return false
//        }
//        
//        // Append the folder name to the document directory URL
//        let folderURL = documentDirectoryURL.appendingPathComponent(folder)
//        
//        // Ensure that the folder exists, create it if it doesn't
//        do {
//            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
//        } catch {
//            print("Error creating folder: \(error.localizedDescription)")
//            return false
//        }
//        
//        // Append the filename to the folder URL to get the complete file URL
//        let fileURL = folderURL.appendingPathComponent(filename)
//        
//        // Write content to the file
//        do {
//            try content.write(to: fileURL, atomically: true, encoding: .utf8)
//            return true
//        } catch {
//            print("Error writing to file: \(error.localizedDescription)")
//            return false
//        }
//    }
//    
//    func uploadFile(
//        name: String,
//        folderID: String,
//        fileURL: URL,
//        mimeType: String,
//        service: GTLRDriveService) {
//        
//        let authorizer = googleUser!.fetcherAuthorizer
//        service.authorizer = authorizer
//        
//        let file = GTLRDrive_File()
//        file.name = name
//        file.parents = [folderID]
//        
//        // Optionally, GTLRUploadParameters can also be created with a Data object.
//        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
//        
//        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
//        
//        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
//            // This block is called multiple times during upload and can
//            // be used to update a progress indicator visible to the user.
//        }
//        
//        service.executeQuery(query) { (_, result, error) in
//            guard error == nil else {
//                fatalError(error!.localizedDescription)
//            }
//            
//            // Successful upload if no error is returned.
//        }
//    }
//    
//    @IBAction func back(_ sender: Any) {
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let initialViewController = storyboard.instantiateViewController(withIdentifier: "StartLine")
//          
//        self.window?.rootViewController = initialViewController
//        self.window?.frame = self.window!.bounds
//        self.window?.makeKeyAndVisible()
//    }
//    
//    @IBAction func upload(sender: Any) {
//        print(googleUser?.grantedScopes)
//        print(googleUser?.idToken)
//        print(googleUser?.accessToken)
//        
//        let fileName = "test.txt"
//        let folderID = "1DWIj1Cd5UWiIi_6d8KnzD1m67G7c5ZfU"
//        let fileURL = fileUrl!
//        
//        let mimeType = "mime/type"
//
//        // Call the uploadFile function with the specified parameters
//        uploadFile(name: fileName, folderID: folderID, fileURL: fileURL, mimeType: mimeType, service: googleDriveService)
//        
//    }
//    
//    @IBAction func getFolderId(sender: Any) {
//        let folderName = "MyFolder"
//        // Assuming you have a GTLRDriveService instance named 'driveService'
//        getFolderIDsByName(folderName: folderName, service: googleDriveService) { folderIDs, error in
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//                return
//            }
//
//            if folderIDs.isEmpty {
//                print("No folders found with the specified name.")
//            } else {
//                print("Folder IDs: \(folderIDs)")
//            }
//        }
//
//    }
//    
//    @IBAction func creatFolder(sender: Any) {
//        createFolder(name: "MyFolder", service: googleDriveService) { folderID, error in
//            if let error = error {
//                print("Error creating folder: \(error.localizedDescription)")
//                // Handle error
//            } else if let folderID = folderID {
//                print("Folder created with ID: \(folderID)")
//                // Handle success
//            } else {
//                print("Unknown error occurred while creating folder.")
//                // Handle unknown error
//            }
//        }
//    }
//    
//    func googleInit(){
//        GIDSignIn.sharedInstance.restorePreviousSignIn { [self] user, error in
//            if error == nil || user != nil {
//                self.googleUser = user
//                
//                let additionalScopes = [
//                    "https://www.googleapis.com/auth/drive.readonly",
//                    "https://www.googleapis.com/auth/drive",
//                    "https://www.googleapis.com/auth/drive.file"
//                ]
//                guard let currentUser = user else {
//                    return ;  /* Not signed in. */
//                }
//
//                currentUser.addScopes(additionalScopes, presenting: self) { signInResult, error in
//                    guard error == nil else { return }
//                    guard let signInResult = signInResult else { return }
//                    print(signInResult)
//                    // Check if the user granted access to the scopes you requested.
//                }
//                print(currentUser.grantedScopes!)
//                self.googleUser = currentUser
//                
//            }
//        }
//    }
//    
//    func createFolder(name: String, service: GTLRDriveService, completion: @escaping (String?, Error?) -> Void) {
//        let folderMetadata = GTLRDrive_File()
//        let authorizer = googleUser!.fetcherAuthorizer
//        service.authorizer = authorizer
//        folderMetadata.name = name
//        folderMetadata.mimeType = "application/vnd.google-apps.folder"
//
//        let query = GTLRDriveQuery_FilesCreate.query(withObject: folderMetadata, uploadParameters: nil)
//        service.executeQuery(query) { (_, file, error) in
//            if let error = error {
//                print("Error creating folder: \(error.localizedDescription)")
//                completion(nil, error)
//                return
//            }
//            
//            if let folder = file as? GTLRDrive_File {
//                print("Folder created with ID: \(folder.identifier ?? "Unknown")")
//                completion(folder.identifier, nil)
//            } else {
//                print("Unknown error occurred while creating folder.")
//                completion(nil, NSError(domain: "UnknownError", code: 0, userInfo: nil))
//            }
//        }
//    }
//    
//    func getFolderIDsByName(folderName: String, service: GTLRDriveService, completion: @escaping ([String], Error?) -> Void) {
//        let query = GTLRDriveQuery_FilesList.query()
//        query.q = "mimeType = 'application/vnd.google-apps.folder' and name = '\(folderName)'"
//        let authorizer = googleUser!.fetcherAuthorizer
//        service.authorizer = authorizer
//
//        service.executeQuery(query) { (_, result, error) in
//            if let error = error {
//                print("Error retrieving folder ID: \(error.localizedDescription)")
//                completion([], error)
//                return
//            }
//
//            if let fileList = (result as? GTLRDrive_FileList)?.files {
//                let folderIDs = fileList.map { $0.identifier ?? "" }
//                completion(folderIDs, nil)
//            } else {
//                print("Folder not found.")
//                completion([], nil)
//            }
//        }
//    }
//}
//
//
