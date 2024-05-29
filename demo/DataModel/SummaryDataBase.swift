//
//  DataModel.swift
//  demo
//
//  Created by 박준영 on 2022/11/02.
//

import Foundation
import SQLite
import Combine

//typealias summaryPublisher = AnyPublisher<summary, Never>


protocol SummaryDataBaseDelegate:AnyObject{
    func summaryDataBase(_ summaryDataBase:SummaryDataBase)
}


class SummaryDataBase{
    
    weak var delegate: SummaryDataBaseDelegate!{
        didSet{ createTable() }
    }
    
    static let `default` = SummaryDataBase()
    
    private var db: Connection! {
        didSet { createTable() }
    }
    
    private let workout_table = Table("workout")
    
    private let summary_table = Table("summary")
    
    private let workrout_type = type_workout()
    
    private let summary_type = type_summary()
    
    @Published var summarys:[summary] = []
    @Published var days:[workout] = []
    
    let dateFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "yyMMdd"
        return format
    }()
    
    init(){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/db.sqlite3"
        do{
            let db = try Connection(path)
            self.db = db
            print("Database initialized at path \(path)")
            createTable()
        }catch{
            print(error)
        }//cath
    }//init
    
    private func createTable(){
        do{
            try db.run(workout_table.create(ifNotExists: true){ t in
                t.column(workrout_type.id, primaryKey: true)
                t.column(workrout_type.day, unique: true)
                print("make work tblae create.....")
            })
            
            try db.run(summary_table.create(ifNotExists:true){ t in
                t.column(summary_type.id, primaryKey: true)
                t.column(summary_type.count)
                t.column(summary_type.result)
                t.column(summary_type.filename)
                t.column(summary_type.day_id)
                t.foreignKey(summary_type.day_id, references: workout_table, workrout_type.id, update: .setNull)
                print("make summary table......")
            })
            
        }catch{
            print(error)
        }
    }
}

extension SummaryDataBase{
    func addDay(_ date: Date){
        do{
            let day = dateFormatter.string(from: date)
            try db.run(workout_table.insert(workrout_type.day <- day))
        }catch{
            print(error)
        }
    }
    func addSummary(_ day:String, _ count: Int64, _ result: String, _ filename:String){
        let query = workout_table
            .filter(workrout_type.day == day)
        print("\(day), \(count), \(result)")
        for i in try! db.prepare(query){
            do{
                try db.run(summary_table.insert(summary_type.count <- count, summary_type.result <- result, summary_type.filename <- filename, summary_type.day_id <- i[workrout_type.id]))
            }catch{
                print(error)
            }
        }
    }
}

extension SummaryDataBase{
    
    func fetchDays(){
        var temp:[workout] = []
        let query = workout_table
            .order(workrout_type.day.asc)
        for item in try! db.prepare(query){
            temp.append(workout(id: item[workrout_type.id], day: item[workrout_type.day]))
        }
        print("fetching data....")
        days = temp
    }
    
    func fetchSummarys(_ day: String){
        var temp:[summary] = []
        var int = 0
        let query = summary_table
            .join(workout_table, on: summary_type.day_id == workout_table[workrout_type.id])
            .filter(workrout_type.day == day)
        for i in try! db.prepare(query){
            temp.append(summary(id: i[summary_table[summary_type.id]], count: i[summary_type.count], result: i[summary_type.result], filename: i[summary_type.filename], day_id: i[summary_type.day_id]))
            int += 1
        }
        summarys = temp
        
    }
}

extension SummaryDataBase{
    
    func deleteDays(){
        do{
            try db.run(summary_table.delete())
            try db.run(workout_table.delete())
        }catch{
            print(error)
        }
    }
    
    func deleteDay(_ day: String){
        let dayQuery = workout_table
            .filter(workrout_type.day == day)
        try! db.run(dayQuery.delete())
        }
    
    func deleteSummarys(_ day: String){
//        let query = summary_table
//            .join(workout_table, on: summary_type.day_id == workout_table[workrout_type.id])
//            .filter(workrout_type.day == day)
//        do{
//            try db.run(query.delete())
//        }catch _ as NSError{
//
//        }
        
        try! db.run(summary_table.delete())
    }
    
    func deleteSummary(_ id: Int64){
        let query = summary_table
            .filter(summary_type.id == id)
        do{
            try db.run(query.delete())
        }catch{
            print(error)
        }
    }
    
    func dropTable(){
        do {
            
            try db.run(summary_table.drop(ifExists: true))
            try db.run(workout_table.drop(ifExists: true))
            
        }catch{
            print(error)
        }
    }
}



    
    

