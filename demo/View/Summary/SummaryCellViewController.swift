//
//  SummaryCellViewController.swift
//  demo
//
//  Created by 박준영 on 2022/11/03.
//

import UIKit
import AVKit

class SummaryCellViewController: UIViewController {

    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    var day: String = "hello world"
    
    let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    
    var contents: [URL]!
    
    @IBOutlet weak var tableView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadContents()
        
        let nibName = UINib(nibName: "SummaryCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "SummaryCell")
        
        db.fetchSummarys(day)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func deleteButtonTapped(){
        db.deleteSummarys(day)
        loadContents()
        print(db.summarys)
    }

}

extension SummaryCellViewController:UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return db.summarys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCell", for: indexPath) as! SummaryCell
        cell.DateLabel.text = day
        cell.resultLabel.text = db.summarys[indexPath.row].result
        cell.countLabel.text =  String(db.summarys[indexPath.row].count)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let content = contents.filter({ $0.path.hasSuffix(db.summarys[indexPath.row].filename + ".mov")})
            try! FileManager.default.removeItem(at: content.first!)
                db.deleteSummary(db.summarys[indexPath.row].id)
                db.summarys.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = contents.filter({ $0.path.hasSuffix(db.summarys[indexPath.row].filename + ".mov")})
        print(content)
        let player = AVPlayer(url: content.first!)
        let vc = AVPlayerViewController()
        vc.player = player
        present(vc, animated: true){
            vc.player?.play()
        }
    }
    
    func loadContents(){
        do{
            contents = try FileManager.default.contentsOfDirectory(at: documentPath!, includingPropertiesForKeys: nil)
            contents = contents.filter({$0.path().hasSuffix("mov")})
            tableView.reloadData()
        }catch{
            print(error)
        }
    }
}

