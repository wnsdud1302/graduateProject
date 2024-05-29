//
//  RecordViewController.swift
//  demo
//
//  Created by 박준영 on 2022/11/05.
//

import UIKit
import AVKit
import AVFoundation

@available(iOS 16.0, *)
class RecordViewController: UIViewController {

    @IBOutlet var tableview: UITableView!
    
    @IBOutlet var deleteBarItem: UIBarButtonItem!
    
    private let videoProcessingChain = VideoProcessingChain.shared
    
    private let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    
    private var contents: [URL]!
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        loadContents()
        
        let nibName = UINib(nibName: "RecordCell", bundle: nil)
        tableview.register(nibName, forCellReuseIdentifier: "RecordCell")
        
        navigationItem.rightBarButtonItem = deleteBarItem
        
        tableview.delegate = self
        tableview.dataSource = self
        
        initrefresh()
    }


    func initrefresh(){
        
        refreshControl.attributedTitle = NSAttributedString(string: "pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        tableview.refreshControl = refreshControl
    }
    
    @objc func refresh(sender:UIRefreshControl){
        print("새로고침 시작")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            db.fetchDays()
            self.tableview.reloadData()
            self.refreshControl.endRefreshing()
        }
        
    }
    
    @IBAction func deleteContents(){
        for url in contents{
            try! FileManager.default.removeItem(at: url)
        }
        loadContents()
        tableview.reloadData()
    }


}

@available(iOS 16.0, *)
extension RecordViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordCell
        
        cell.nameLabel.text = contents[indexPath.row].lastPathComponent
        let av = AVAsset(url: contents[indexPath.row])
        let duraton = av.duration.seconds
        cell.lenLabel.text = String(round(duraton))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = contents[indexPath.row]
        print(content)
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: content)
        present(vc, animated: true){
            vc.player?.play()
            
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            do{
                try FileManager.default.removeItem(at: contents[indexPath.row])
                loadContents()
            }catch _ as NSError{
            }
        }
    }
    
    func loadContents(){
        do{
            contents = try FileManager.default.contentsOfDirectory(at: documentPath!, includingPropertiesForKeys: nil)
            contents = contents.filter({$0.path().hasSuffix("mov")})
            tableview.reloadData()
        }catch{
            print(error)
        }
    }
}
