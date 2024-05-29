//
//  VideoProcessingChain+CheckSquat.swift
//  demo
//
//  Created by 박준영 on 2022/11/02.
//

import Vision
import UIKit

enum squat_type: String{
    case narrow
    case normal
    case wide
}

enum front_perform_type: String, CaseIterable{
    case right
    case ankleDistanceProblem
    case hipUp
    case goodMorning
    case lessDepth
    
}

enum side_result_type:String{
    case right
    case hipUp
    case roundBack
    case goodMorning
    case lessDepth
}

struct frontSquat{
        
    private var landmarks: [Pose.Landmark]!
    
    private var connections: [Pose.Connection]!
    
    init?(_ poses:[Pose]?){
        
        guard poses != nil else { return nil }
        
        guard poses?.first?.squatLandmarks != nil && poses?.first?.squatLandmarks.count == 8 else { return nil }
        guard poses?.first?.squatConnection != nil && poses?.first?.squatConnection.count == 8 else { return nil}
        
        self.landmarks = poses?.first?.squatLandmarks
        self.connections = poses?.first?.squatConnection
        
    }
    
    
    func countSquats() -> Bool{
        
        let firstAngle = connections[2].angle()
        let secondAngle = connections[3].angle()
        let angleDiff = (firstAngle + abs(secondAngle)) * 180 / .pi
        if angleDiff < 100 {
            return true
        }
        return false
    }
    
    func checkBodyState() -> squat_type{
        
        let firstAngle = connections[2].angle()
        let secondAngle = connections[3].angle()
        let angleDiff = (firstAngle + abs(secondAngle)) * 180 / .pi
        
        if angleDiff > 190 {
            return .wide
        }
        else if angleDiff < 180 {
            return .narrow
        }
        
        return .normal
    }
    
    func checkPerform(_ isBottom: Bool, _ initSquat: frontSquat?) -> front_perform_type{
        
        //initsquat 관련 변수
        let initSHdistance = (initSquat?.getSHdistance())! * 0.635
        
        
        // squat 거리
        let kneeDistance = connections[0].distance()
        let ankleDistance = connections[1].distance()
        let SHdistance = connections[6].distance()
        
        
        //squat 각도
        let kneeAngle = (abs(connections[2].angle()) + abs(connections[3].angle())) * 180 / .pi
        let SHangle = 180 - abs(connections[6].angle() * 180 / .pi)
        let HKangle = 180 - abs(connections[7].angle() * 180 / .pi)
        if !isBottom{
            if SHdistance < initSHdistance{
                return .goodMorning
            }
            return .lessDepth
        }
        
        if kneeDistance < ankleDistance { return .ankleDistanceProblem }
        
        if SHdistance < initSHdistance { return .goodMorning }
        
        return .right
    }
    
    func getSHdistance() -> Double{
        return connections[6].distance()
    }
}
