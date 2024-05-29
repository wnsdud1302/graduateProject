//
//  Timer.swift
//  demo
//
//  Created by 박준영 on 2022/11/07.
//

import Foundation


class CDTimer {
    
    private var timer: Timer!
    
    var remain: Int!
    
    private var start: Date!
    
    var isOver: Bool = false
    
    init?(_ remain: Int?, _ start: Date){
        guard remain != nil else { return nil }
        self.remain = remain
        self.start = start
    }
    
    @objc private func timeDown(){
        let start = Date().timeIntervalSince(start)
        remain -= 1
    }
    
    private func startTimer(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeDown), userInfo: nil, repeats: true)
    }
    
    private func stopTimer(){
        timer.invalidate()
    }
            
    func run(){
        startTimer()
        DispatchQueue.global(qos: .background).async { [self] in
            while remain >= 0 {
            }
            stopTimer()
            isOver = true
        }
    }
    
}
