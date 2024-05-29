//
//  SummaryViewController.swift
//  demo
//
//  Created by 박준영 on 2022/11/02.
//

import UIKit

let dateFormatter1: DateFormatter = {
    let format = DateFormatter()
    format.dateFormat = "yyMMdd"
    return format
}()

@available(iOS 16.0, *)
class SummaryViewController: UIViewController {
    
    @IBOutlet weak var addSummary: UIBarButtonItem!
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var recordButton: UIBarButtonItem!
    
    let refreshControl = UIRefreshControl()
    
    var reciveCount:String?
    var reciveResult:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationController?.title = "summary"
                
        tableView.dataSource = self
        tableView.delegate = self
        
        let nibName = UINib(nibName: "SummaryCellTableViewCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "SummaryCellTableViewCell")
        
        db.fetchDays()
        initrefresh()
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        db.fetchDays()
        tableView.reloadData()
    }
    
    @IBAction func recordButtonTapped(){
        let vc = RecordViewController(nibName: "RecordViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension SummaryViewController:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return db.days.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCellTableViewCell", for: indexPath) as! SummaryCellTableViewCell
        cell.DateLabel?.text = db.days[indexPath.row].day
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let main = UIStoryboard(name: "Main", bundle: nil)
        let vc = main.instantiateViewController(withIdentifier: "SummaryCellViewController") as! SummaryCellViewController
        let day = db.days[indexPath.row].day
        print(day)
        vc.day = day
        navigationController?.pushViewController(vc, animated: true)

    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            
            db.deleteDay(db.days[indexPath.row].day)

            
            let contents = try! FileManager.default.contentsOfDirectory(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!, includingPropertiesForKeys: nil)
            
            contents.forEach{
                if $0.path().contains(db.days[indexPath.row].day){
                    do{
                        try FileManager.default.removeItem(at: $0)
                    }catch _ as NSError{
                    }
                }
            }
            db.days.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
    }
    
    @objc func refresh(sender:UIRefreshControl){
        print("새로고침 시작")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            db.fetchDays()
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
        
    }
    
    func initrefresh(){
        
        refreshControl.attributedTitle = NSAttributedString(string: "pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
        
}

extension SummaryViewController{
    
    @IBAction func openAlert(){
        let alertController = UIAlertController(title: "Title", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter name"
        }
        alertController.addTextField{(textField: UITextField) -> Void in
            textField.placeholder = "Enter email"
        }


        let saveAction = UIAlertAction(title: "save", style: .default, handler: { alert -> Void in
            if let textField = alertController.textFields?[0] {
                if textField.text!.count > 0 {
                    print("Text :: \(textField.text ?? "")")
                }
            }
        })

        let cancelAction = UIAlertAction(title: "cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in })

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        alertController.preferredAction = saveAction

        self.present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func showAlert(){
        let alert = SummaryPopupViewController(nibName: "SummaryPopupViewController", bundle: nil)
        alert.delegate = self
        alert.modalPresentationStyle = .overCurrentContext
        alert.modalTransitionStyle = .crossDissolve
        present(alert, animated: true)
        }
    

}

extension SummaryViewController:PopupDelegate{
    
    
    func popUp(day: Date, count: String?, result: String?, filename: String?) {
        guard count != nil else {return}
        guard result != nil else {return}
        let name = "demo"
        let days = db.dateFormatter.string(from: day)
        guard let count = Int64(count ?? "0") else {return}
        db.addDay(day)
        db.addSummary(days, count, result!, name)
        db.fetchDays()
        tableView.reloadData()
    }
}

