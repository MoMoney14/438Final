//
//  SignUpViewController.swift
//  Pump
//
//  Created by Akash Kaul on 11/25/20.
//  Copyright © 2020 mo3aru. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreData

// View controller for new user sign up page
class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var experienceField: UITextField!
    
    @IBOutlet weak var weightField: UITextField!
    
    @IBOutlet weak var heightField: UITextField!
    
    @IBOutlet weak var displayNameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    var imageURL = ""
    
    let imagePicker = UIImagePickerController()
    
    let pickerOptions = ["Beginner", "Intermediate", "Advanced"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create gesture for image view to allow changing profile image
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profileImage.layer.borderWidth=1.0
        profileImage.layer.masksToBounds = false
        profileImage.layer.borderColor = UIColor.black.cgColor
        profileImage.layer.cornerRadius = profileImage.frame.size.height/2
        profileImage.clipsToBounds = true
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(tapGestureRecognizer)
        
        // Create picker for skill level
        let expPicker = UIPickerView()
        expPicker.delegate = self
        expPicker.dataSource = self
        expPicker.backgroundColor = UIColor.systemGray4
        experienceField.inputView = expPicker
        experienceField.tintColor = UIColor.clear
        
        signUpButton.layer.cornerRadius = 10
        signUpButton.backgroundColor = UIColor.systemTeal
        signUpButton.setTitleColor(.white, for: .normal)
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        //https://stackoverflow.com/questions/31728680/how-to-make-an-uipickerview-with-a-done-button
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(selectDone))
        
        toolbar.setItems([doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        experienceField.inputAccessoryView = toolbar
        // Do any additional setup after loading the view.
    }
    
    @objc func selectDone() {
        if (!pickerOptions.contains(experienceField.text ?? "")) {
            experienceField.text = pickerOptions[0]
        }
        experienceField.resignFirstResponder()
    }
    
    // Function called when you tap on the profile image view
    @objc func imageTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Choose Image", message: "Choose an image from your camera roll or take a picture", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { _ in
            self.openLibrary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Opens camera to take a picture
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Camera Unavailable", message: "The camera cannot be accessed on this device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Opens photo library to select an image
    func openLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Selects image from Image Picker
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else {return}
        profileImage.image = image
        dismiss(animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        experienceField.text = pickerOptions[row]
    }
    
    // SEND USER INFO TO USER COLLECTION
    func sendToFirebase(_ uid:String) {
        let height = Double(self.heightField.text ?? "0.0")
        let weight = Double(self.weightField.text ?? "0.0")
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData(["uid": uid, "username": self.displayNameField.text ?? "", "following": [uid], "height": height ?? 0.0, "weight": weight ?? 0.0, "experience": self.experienceField.text ?? "Beginner", "email": self.emailField.text!, "name": self.nameField.text!, "profile_pic": self.imageURL]) {(err) in
            
            if err != nil{
                let alert = UIAlertController(title: "Error", message: "\(err?.localizedDescription ?? "Unknown error.") Please try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let user = User(experience: self.experienceField.text ?? "Beginner", following: [uid], height: height ?? 0.0, name: self.nameField.text ?? "", profile_pic: self.profileImage.image?.pngData()?.base64EncodedString() ?? "", uid: uid, username: self.displayNameField.text ?? "", weight: weight ?? 0.0, email: self.emailField.text!)
            
            CoreDataFunctions.save(user)
            
            userID = uid
            USERNAME = user.username
        }
    }
    
    // ADD USER TO FIREBASE USER AUTH
    func signUpUser(){
        // add users to user auth
        Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { res, err  in
            if err != nil{
                let alert = UIAlertController(title: "Error", message: "\(err?.localizedDescription ?? "Unknown error") Please try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
                
            }
            else {
                // add user to users collection
                if let image = self.profileImage.image {
                    let ref = Storage.storage().reference().child("userImages\(res!.user.uid).jpg")
                    ref.putData(image.pngData()!, metadata: nil) { (metadata, error) in
                        if error != nil {
                            print("error saving image")
                        }
                        else {
                            ref.downloadURL { (url, error2) in
                                if error2 != nil {
                                    print("error grabbing image url")
                                }
                                else {
                                    guard let downloadURL = url else {return}
                                    self.imageURL = downloadURL.absoluteString
                                    self.sendToFirebase(res!.user.uid)
                                }
                            }
                        }
                    }
                }
                else {
                    self.sendToFirebase(res!.user.uid)
                }
                
            }
            self.performSegue(withIdentifier: "showTabBar", sender: self)
        }
    }
    
    // VALIDATE EMAIL, PASSWORD, DISPLAY NAME
    func validateSignUp() -> Bool{
        return checkEmail(emailField.text ?? "") && checkPassword(passwordField.text ?? "") && checkDisplayName(displayNameField.text ?? "")
    }
    
    // CHECK FIELDS ARE FILLED
    func checkFields() -> Bool {
        return (nameField.text?.count ?? 0 > 0) && (passwordField.text?.count ?? 0 > 0) && (emailField.text?.count ?? 0 > 0) && (displayNameField.text?.count ?? 0 > 0)
    }
    
    // EMAIL REGEX
    func checkEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // PASSWORD REGEX
    func checkPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,}$"
        
        let passPred = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        return passPred.evaluate(with: password)
    }
    
    // DISPLAY NAME REGEX AND UNIQUENESS
    func checkDisplayName(_ displayName: String) -> Bool{
        
        let displayNameRegex = "^\\w{7,18}$"
        
        let displayPred = NSPredicate(format:"SELF MATCHES %@", displayNameRegex)
        
        if !displayPred.evaluate(with: displayName){
            return false
        }
        
        var flag = true
        
        let db = Firestore.firestore()
        
        db.collection("users").whereField("username", isEqualTo: displayNameField.text!).getDocuments { (res, err) in
            if(res?.count != 0){
                flag = false
            }
        }
        
        return flag
    }
    
    
    // ACTION ON SIGN UP BUTTON TAPPED
    @IBAction func signUp(_ sender: UIButton) {
        if checkFields(){
            
            if validateSignUp() {
                errorLabel.text = nil
                signUpUser()
            }
            else {
                if !checkEmail(emailField.text ?? "") && !checkPassword(passwordField.text ?? ""){
                    errorLabel.text = "Please enter a valid email and password"
                }
                else if !checkEmail(emailField.text ?? "") {
                    errorLabel.text = "Please enter a valid email"
                }
                else if !checkPassword(passwordField.text ?? ""){
                    errorLabel.text = "Please enter a valid password"
                } else {
                    errorLabel.text = "Pleae enter a valid username"
                }
            }
        }
        else {
            errorLabel.text = "One or more required fields is blank"
        }
    }
    
}
