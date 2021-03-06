//
//  ProfilePageViewController.swift
//  Pump
//
//  Created by Akash Kaul on 11/25/20.
//  Copyright © 2020 mo3aru. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import CoreData
import FirebaseAuth

// View controller for own user profile pages
class ProfilePageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var userPosts = [Post]()
    var userStructure: User?
    let db = Firestore.firestore()
    
    var posts: [Post] = []
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // https://stackoverflow.com/questions/27880607/how-to-assign-an-action-for-uiimageview-object-in-swift
        
        profileImage.layer.borderWidth=1.0
        profileImage.layer.masksToBounds = false
        profileImage.layer.borderColor = UIColor.black.cgColor
        profileImage.layer.cornerRadius = profileImage.frame.size.height/2
        profileImage.clipsToBounds = true
        profileImage.isUserInteractionEnabled = true
        
        editButton.layer.cornerRadius = 10
        editButton.backgroundColor = UIColor.systemTeal
        editButton.setTitleColor(.white, for: .normal)
        
        picker.delegate = self
        picker.allowsEditing = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: "postCell")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }
    
    // Get user data from Core Data
    func setup(){
        posts = []
        fetchUser()
        fetchUserPosts()
        var array = [NSManagedObject]()
        array = CoreDataFunctions.getData()
        if array.count > 0{
            for i in 0..<array.count {
                if(array[i].value(forKey: "uid") as? String ?? "uid" == userID){
                    if let base64image = array[i].value(forKey: "profile_pic") as? String {
                        let data = Data(base64Encoded: base64image, options: .init(rawValue: 0))!
                        self.profileImage.image = UIImage(data: data)
                    }
                    self.profileName.text = array[i].value(forKey: "name") as? String ?? "name"
                }
                
            }
        }
    }
    
    // Return to main page on sign out
    @IBAction func signOutUser(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try? firebaseAuth.signOut()
        }
        self.performSegue(withIdentifier: "signOut", sender: nil)
        
    }
    
    // Transition to edit profile page with button click
    @IBAction func editProfile(_ sender: UIButton) {
        if let user = userStructure {
            self.performSegue(withIdentifier: "toEditProfile", sender: user)
        }
    }
    
    // Fetch user information from Firebase
    func fetchUser () {
        DispatchQueue.global().async {
            do {
                let userRef = self.db.collection("users")
                let call = userRef.whereField("uid", isEqualTo: userID)
                call.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("No results: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            try? self.userStructure = document.data(as: User.self)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                    }
                }
            }
        }
    }
    
    // Fetch posts for current user
    func fetchUserPosts () {
        DispatchQueue.global().async {
            do {
                let postsRef = self.db.collection("posts")
                let results = postsRef.whereField("userId", isEqualTo: userID)
                results.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("No results: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            var postInfo: Post?
                            try? postInfo = document.data(as:Post.self)
                            self.posts.append(postInfo ?? Post(id: "", exercises: [], likes: 0, title: "err", userId: "err", username: "err", picturePath: "" ))
                        }
                    }
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
}

// Configures collection view for posts
extension ProfilePageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width*0.8, height: 350)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCell
        if let imageURL = posts[indexPath.row].picturePath {
            if imageURL == "" {
                let rect = CGRect(x: 0,y: 0,width: 120,height: 200)
                UIGraphicsBeginImageContextWithOptions(CGSize(width: 120, height: 200), true, 1.0)
                UIColor.gray.set()
                UIRectFill(rect)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                cell.imageView.image = image
            } else {
                let ref = Storage.storage().reference(forURL: imageURL)
                
                ref.downloadURL {(url, error) in
                    if error != nil {
                        print("uh oh")
                    }
                    else {
                        let data = try? Data(contentsOf: url!)
                        let image = UIImage(data: data! as Data)
                        cell.imageView.image = image
                    }
                }
            }
        }
        else {
            let rect = CGRect(x: 0,y: 0,width: 120,height: 200)
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 120, height: 200), true, 1.0)
            UIColor.gray.set()
            UIRectFill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            cell.imageView.image = image
        }
        cell.titleLabel.text = posts[indexPath.row].title
        cell.likesLabel.text = "\(posts[indexPath.row].likes) likes"
        cell.usernameLabel.text = posts[indexPath.row].username
        
        return cell
    }
    
    // Transitions from post to detailed view of post
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "fromProfileToDetailedVC", sender: posts[indexPath.row].id)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "fromProfileToDetailedVC") {
            let detailedPostView = segue.destination as? DetailedPostViewController
            detailedPostView?.postId = sender as? String
        }
        if(segue.identifier == "toEditProfile") {
            let editProf = segue.destination as? EditProfileViewController
            editProf?.userStruc = sender as? User
        }
    }
    
    
    
}

