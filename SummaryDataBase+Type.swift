//
//  SummaryDataBase+Type.swift
//  demo
//
//  Created by 박준영 on 2022/11/03.
//

import SQLite

struct workout:Identifiable{
    var id: Int64
    var day: String
}

struct summary:Identifiable{
    var id: Int64
    var count: Int64
    var result: String
    var filename: String
    var day_id: Int64
}

struct type_workout{
    let id = Expression<Int64>("id")
    let day = Expression<String>("day")
}

struct type_summary{
    let id = Expression<Int64>("id")
    let count = Expression<Int64>("count")
    var result = Expression<String>("result")
    var filename = Expression<String>("filename")
    var day_id = Expression<Int64>("day_id")
}
