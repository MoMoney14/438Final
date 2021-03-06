//
//  HomepageViewController.swift
//  Pump
//
//  Created by Reshad Hamauon on 12/10/20.
//  Copyright © 2020 mo3aru. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreSwift
import FirebaseStorage

// View Controller for home page
class HomepageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var workoutCollectionView: UICollectionView!
    var animating = false
    let db = Firestore.firestore()
    let spinner = UIActivityIndicatorView()
    var userFollowing: [String] = []
    var followingUsers: [User] = []
    var posts: [Post] = []
    
    override func viewDidLoad() {
        //setup()
        workoutCollectionView.delegate = self
        workoutCollectionView.dataSource = self
        workoutCollectionView.register(PostCell.self, forCellWithReuseIdentifier: "postCell")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }
    
    // Clear data
    func setup(){
        animating = true
        spinner.center = self.view.center
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.startAnimating()
        userFollowing = []
        followingUsers = []
        posts = []
        getFollowingIds()
    }
    
    // Get user IDs of all users the current uesr follows
    func getFollowingIds(){
        DispatchQueue.global().async {
            do {
                
                let results = self.db.collection("users").whereField("uid", isEqualTo: userID)
                
                results.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("No results: \(err)")
                    } else {
                        for document in querySnapshot!.documents{
                            var userInfo: User?
                            try? userInfo = document.data(as:User.self)
                            
                            self.userFollowing = userInfo?.following ?? []
                        }
                    }
                    DispatchQueue.main.async {
                        if(!self.userFollowing.isEmpty){
                            self.fetchFollowingUsersObj()
                        } else {
                            self.workoutCollectionView.reloadData()
                            self.spinner.stopAnimating()
                        }
                    }
                }
            }
        }
        
    }
    
    // Get actual user information for given user IDs
    func fetchFollowingUsersObj() {
        DispatchQueue.global().async {
            do {
                let followingRef = self.db.collection("users")
                
                let results = followingRef.whereField("uid", in: self.userFollowing)
                results.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("No results: \(err)")
                    } else {
                        
                        for document in querySnapshot!.documents {
                            var userInfo: User?
                            try? userInfo = document.data(as:User.self)
                            
                            self.followingUsers.append(userInfo ?? User(experience: "err", following: ["err"], height: 0, name: "err", profile_pic: "err", uid: "err", username: "err", weight: 0, email: "err"))
                        }
                    }
                    //updating table
                    DispatchQueue.main.async {
                        for user in self.followingUsers {
                            self.fetchPosts(user: user)
                        }
                    }
                }
            }
        }
    }
    
    // Get all posts from followed users
    func fetchPosts(user:User) {
        DispatchQueue.global().async {
            do {
                let postsRef = self.db.collection("posts")
                
                let results = postsRef.whereField("userId", isEqualTo: user.uid)
                results.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("No results: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            var postInfo: Post?
                            try? postInfo = document.data(as:Post.self)
                            self.posts.append(postInfo ?? Post(id: "err", exercises: [], likes:0, title: "err", userId: "err", username: " ", picturePath: ""))
                        }
                    }
                    //updating table
                    DispatchQueue.main.async {
                        self.spinner.stopAnimating()
                        self.animating = false
                        self.workoutCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.workoutCollectionView.frame.size.width*0.8, height: 350)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = workoutCollectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCell
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
    
    // Move to detailed view when workout clicked on
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!animating){
            self.performSegue(withIdentifier: "fromHomeToPost", sender: posts[indexPath.row].id)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == "fromHomeToPost") {
            let detailedPostView = segue.destination as? DetailedPostViewController
            detailedPostView?.postId = sender as? String
        }
    }
    
}
