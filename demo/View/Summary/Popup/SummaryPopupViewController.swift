//
//  SummaryPopupViewController.swift
//  demo
//
//  Created by 박준영 on 2022/11/03.
//

import UIKit

protocol PopupDelegate:AnyObject{
    func popUp(day:Date,count: String?, result: String?, filename:String?)
    
}

class SummaryPopupViewController: UIViewController {
    
    weak var delegate: PopupDelegate?
    
    let videoProcessingChain = VideoProcessingChain.shared

    @IBOutlet weak var popupView: UIView!
        
    @IBOutlet weak var ButtonStack: UIStackView!
    
    @IBOutlet weak var countTextField: UITextField!
    
    @IBOutlet weak var resultPicker: UIPickerView!
    
    @IBOutlet weak var dayPicker: UIDatePicker!
    
    @IBOutlet weak var inputStack: UIStackView!
    
    var fileName: String?
    
    var result:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultPicker.delegate = self
        resultPicker.dataSource = self
        
        countTextField.delegate = self
        
        ButtonStack.distribution = .fillEqually
        ButtonStack.alignment = .fill
        ButtonStack.spacing = 0.0
        
        dayPicker.center = .zero
        
        inputStack.distribution = .fillEqually
        inputStack.alignment = .fill

        // Do any additional setup after loading the view.
    }


    @IBAction func dismissView(){
        modalTransitionStyle = .crossDissolve
        dismiss(animated: true)
    }
    
    @IBAction func pushData(){
        

        self.delegate?.popUp(day: dayPicker.date,count: countTextField.text, result: result, filename: fileName)
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

extension SummaryPopupViewController:UIPickerViewDelegate, UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return front_perform_type.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return front_perform_type.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        result = front_perform_type.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickLabel = view as? UILabel
        
        if  pickLabel == nil {
            pickLabel = UILabel()
            pickLabel?.font = .systemFont(ofSize: 10)
            pickLabel?.textAlignment = NSTextAlignment.center
        }
        
        pickLabel?.text = front_perform_type.allCases[row].rawValue
        
        return pickLabel!
    }
    
    
}

extension SummaryPopupViewController:UITextFieldDelegate{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
