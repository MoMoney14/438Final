//
//  CreateWorkoutViewController.swift
//  Pump
//
//  Created by Mahoto Sasaki on 11/16/20.
//  Copyright © 2020 mo3aru. All rights reserved.
//

import UIKit
import FirebaseFirestore
class CreateWorkoutViewController: UIViewController, UITextFieldDelegate {
    
    struct Post: Codable {
        var exercises: [Exercise]
        var likes: Int
        var title: String
        var userId: String
    }
    
    struct Exercise: Codable {
        var exerciseName: String
        var reps: Int
        var sets: Int
    }
    
    @IBOutlet weak var tableView: UITableView!
    var numTableViewSections = 6
    var numExerciseComponents = 4
    var fontSize:CGFloat = 14
    var tableTextField:[String] = []
    var tableData:[String] = ["", "", "", "1" ,"1"]
    
    var pickerView = UIPickerView()
    var pickerViewDoneButton = UIButton()
    var pickerViewData = [Int]()
    var pickerViewVisible = true
    var chosenCellPickerViewSection = 0
    var pickerViewHistory = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        
        for i in 1...50 {
            pickerViewData.append(i)
        }
        
        let x = tableView.frame.origin.x
        let y = tableView.frame.origin.y
        let height = tableView.frame.height
        let width = tableView.frame.width
        
        pickerView = UIPickerView(frame: CGRect(x: x, y: y + height / 2 + 40, width: width, height: height / 2 - 40))
        pickerView.backgroundColor = UIColor.systemGray
        view.addSubview(pickerView)

        pickerViewDoneButton = UIButton(frame: CGRect(x: x, y: y + height / 2, width: width, height: 40))
        pickerViewDoneButton.setTitle("Done", for: .normal)
        pickerViewDoneButton.backgroundColor = UIColor.green
        pickerViewDoneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        view.addSubview(pickerViewDoneButton)
        
        pickerView.delegate = self
        pickerView.dataSource = self
                
        hidePickerView()
        //tap gesture obtained from https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        hidePickerView()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        tableData[textField.tag] = textField.text ?? ""
    }
    
    @IBAction func postButtonPressed(_ sender: UIButton) {
        hidePickerView()
        //print(tableData)
        
        
        //adding a post without struct
        let db = Firestore.firestore()
        var i = 2
        var exArr  = [[ : ]]
        exArr.removeAll()
        var exDic: [String: AnyObject] = [:]
        while i < tableData.count {
            exDic["exercise"] = tableData[i] as AnyObject
            i = i+1
            exDic["reps"] = tableData[i] as AnyObject
            i = i+1
            exDic["sets"] = tableData[i] as AnyObject
            i = i+2
            exArr.append(exDic)
        }
        //need to fix so we add actual user id
        db.collection("posts").addDocument(data: ["duration": 1, "exercises":exArr, "likes":0 , "title":tableData[0], "userid": "currentuser"]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        
        //adding a post with the struct
        //need to figure out decodable stuff
        var myPost: Post
        myPost.likes = 0
        myPost.title = tableData[0]
        //need to get actual user id
        myPost.userId = "currentUser"
        var j = 1
        while j < tableData.count {
            var ex: Exercise
            ex.exerciseName = tableData[j]
            j = j+1
            ex.reps = Int(tableData[j]) ?? 0
            j = j+1
            ex.sets = Int(tableData[j]) ?? 0
            j = j+1
            myPost.exercises.append(ex)
        }
        
        db.collection("posts").addDocument(data: myPost) {(err) in
        
            if err != nil{
                print("error adding to posts collection")
                print(err!)
            }
        }//
    }
    
    @objc func doneButtonPressed(){
        hidePickerView()
    }
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension CreateWorkoutViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return numTableViewSections
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 || (section % numExerciseComponents == 0) {
            return 40
        }
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:LabelCellTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as! LabelCellTableViewCell
        cell.label?.font = UIFont.systemFont(ofSize: fontSize)
        cell.rightLabel.font  = UIFont.systemFont(ofSize: fontSize)
        
        if indexPath.section % numExerciseComponents == 0 {
            if indexPath.section == 0 {
                let cell:TextFieldTableViewCell = tableView.dequeueReusableCell(withIdentifier: "workoutCell") as! TextFieldTableViewCell
                cell.workoutTitleTextField.delegate = self
                cell.workoutTitleTextField.tag = indexPath.section
                cell.workoutTitleTextField.text = tableData[indexPath.section]
                return cell
            }
            cell.label?.text = "Reps"
            cell.rightLabel.text = tableData[indexPath.section]
            //tableData[indexPath.section] = cell.label.text ?? ""
            
        } else if indexPath.section % numExerciseComponents == 1 {
            if indexPath.section == numTableViewSections - 1 {
                cell.label?.text = "Add Exercise"
                cell.rightLabel.text = ""
                return cell
            }
            
            let exerciseCell:DeleteWorkoutTableViewCell = tableView.dequeueReusableCell(withIdentifier: "exerciseCell") as! DeleteWorkoutTableViewCell
            exerciseCell.exerciseLabel.text = "Exercise \(indexPath.section / numExerciseComponents + 1)"
            exerciseCell.deleteButton.tag = indexPath.section
            exerciseCell.deleteButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
            if indexPath.section == 1 {
                exerciseCell.deleteButton.isHidden = true
            } else {
                exerciseCell.deleteButton.isHidden = false
            }
            
            tableData[indexPath.section] = exerciseCell.exerciseLabel.text ?? ""
            return exerciseCell
        } else if indexPath.section % numExerciseComponents == 2 {
            let cell:TextFieldTableViewCell = tableView.dequeueReusableCell(withIdentifier: "workoutCell") as! TextFieldTableViewCell
            cell.workoutTitleTextField.placeholder = "Exercise Title"
            cell.workoutTitleTextField.delegate = self
            cell.workoutTitleTextField.tag = indexPath.section
            cell.workoutTitleTextField.text = tableData[indexPath.section]
            return cell
        } else if indexPath.section % numExerciseComponents == 3 {
            cell.label?.text = "Sets"
            cell.rightLabel.text = tableData[indexPath.section]
            //tableData[indexPath.section] = cell.label.text ?? ""
        }
        return cell
    }
    
    @objc func buttonClicked(sender:UIButton){
        for _ in 1...numExerciseComponents {
            tableData.remove(at: sender.tag)
        }
        
        numTableViewSections -= numExerciseComponents
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hidePickerView()
        if indexPath.section == numTableViewSections - 1 {
            numTableViewSections += numExerciseComponents
            
            for i in 1...numExerciseComponents {
                if i == numExerciseComponents - 1 || i == numExerciseComponents {
                    tableData.append("0")
                } else {
                    tableData.append("")
                }
            }
            tableView.reloadData()
        } else if indexPath.section % numExerciseComponents == 3 {
            showPickerView(section: indexPath.section)
            chosenCellPickerViewSection = indexPath.section
        } else if indexPath.section % numExerciseComponents == 0 && indexPath.section != 0 {
            showPickerView(section: indexPath.section)
            chosenCellPickerViewSection = indexPath.section
        }
    }
    
}

extension CreateWorkoutViewController: UIPickerViewDataSource, UIPickerViewDelegate  {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerViewData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(pickerViewData[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let data = pickerViewData[row]
        updatePickerViewHistory(index: chosenCellPickerViewSection, value: data)
        tableData[chosenCellPickerViewSection] = "\(data)"
        tableView.reloadData()
    }
        
    func hidePickerView(){
        pickerView.isHidden = true
        pickerViewDoneButton.isHidden = true
    }
    
    func showPickerView(section:Int){
        pickerView.isHidden = false
        pickerViewDoneButton.isHidden = false
        
        pickerView.selectRow(getPickerViewHistory(index: section), inComponent: 0, animated: true)
    }
    
    func getPickerViewHistory(index:Int) -> Int{
        var newIndex = index
        if index != 0 {
            if index % numExerciseComponents == 0 {
                newIndex = (newIndex - 2) / 2
            } else if index % numExerciseComponents == 3 {
                newIndex = (newIndex - 3) / 2
            }
            
            if newIndex > pickerViewHistory.count - 1 {
                for _ in pickerViewHistory.count...newIndex {
                    pickerViewHistory.append(1)
                }
            }
        }
        return pickerViewHistory[newIndex] - 1
    }
    
    func updatePickerViewHistory(index:Int, value:Int){
        /*
         0 3
         2 7
         4 11
         6 15
         x * 2 + 3 -> y
         
         1 4
         3 8
         5 12
         7 16
         x * 2 + 2 -> y
         */
        
        var newIndex = index
        if index != 0 {
            if index % numExerciseComponents == 0 {
                newIndex = (newIndex - 2) / 2
            } else if index % numExerciseComponents == 3 {
                newIndex = (newIndex - 3) / 2
            }
            pickerViewHistory[newIndex] = value
        }
        print("UPDATE")
        print(pickerViewHistory)
    }
}


