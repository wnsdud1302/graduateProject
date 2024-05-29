//
//  Pose.swift
//  demo
//
//  Created by 박준영 on 2022/11/01.
//

import Foundation
import Vision
import UIKit

typealias Observation = VNHumanBodyPoseObservation

let squatJoint:[Observation.JointName] = [.leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .leftHip, .rightHip, .leftShoulder, .rightShoulder]

struct Pose {
    let landmarks: [Landmark]
    
    let squatLandmarks: [Landmark]
    
    private var connections: [Connection]!
    
    var squatConnection: [Connection]!
    
    
    let multiArray: MLMultiArray?
    
    let area:CGFloat
    
    init?(_ observation: Observation){
        landmarks = observation.availableJointNames.compactMap{
            guard $0 != JointName.root else { return nil }
            guard let point = try? observation.recognizedPoint($0) else { return nil }
            return Landmark(point)
        }
        squatLandmarks = observation.availableJointNames.compactMap{
            guard squatJoint.contains($0) else { return nil }
            guard let point = try? observation.recognizedPoint($0) else { return nil }
            return Landmark(point)
            
        }
        
        
        guard !landmarks.isEmpty else { return nil }
        
        area = Pose.areaEstimateOfLandmarks(landmarks)
        
        multiArray = try? observation.keypointsMultiArray()
        
        buildConnection()
        
        buildLegConnection()
        
    }
    
    private var drawingScale: CGFloat {
        /// The typical size of a dominant pose.
        ///
        /// The sample's author empirically derived this value.
        let typicalLargePoseArea: CGFloat = 0.35

        /// The largest scale is 100%.
        let max: CGFloat = 1.0

        /// The smallest scale is 60%.
        let min: CGFloat = 0.6

        /// The area's ratio relative to the typically large pose area.
        let ratio = area / typicalLargePoseArea

        let scale = ratio >= max ? max : (ratio * (max - min)) + min
        return scale
    }
    
    func drawWireframeContext(_ context: CGContext,
                              applying transform: CGAffineTransform? = nil){
        let scale = drawingScale

        // Draw the connection lines first.
        connections.forEach {
            line in line.drawContext(context,
                                       applying: transform,
                                       at: scale)

        }

        // Draw the landmarks on top of the lines' endpoints.
        landmarks.forEach { landmark in
            landmark.drawContext(context,
                                   applying: transform,
                                   at: scale)
        }
    }
    
    
}

extension Pose{
    
    mutating func buildConnection() {
        guard connections == nil else {
            return
        }
        
        connections = [Connection]()
        
        let joints = landmarks.map{ $0.name }
        let locations = landmarks.map{ $0.location }
        let zippedPairs = zip(joints, locations)
        let jointLocations = Dictionary(uniqueKeysWithValues: zippedPairs)
        
        for jointpair in Pose.jointPairs {
            guard let one = jointLocations[jointpair.joint1] else { continue }
            
            guard let two = jointLocations[jointpair.joint2] else { continue }
            
            
            connections.append(Connection(one, two))
        }
    }
    
    mutating func buildLegConnection() {
        guard squatConnection == nil else {
            return
        }
        
        squatConnection = [Connection]()
        
        let joints = squatLandmarks.map{ $0.name }
        let locations = squatLandmarks.map{ $0.location }
        let zippedPairs = zip(joints, locations)
        let jointLocations = Dictionary(uniqueKeysWithValues: zippedPairs)
        
        for jointpair in Pose.squatJointPairs {
            guard let one = jointLocations[jointpair.joint1] else { continue }
            guard let two = jointLocations[jointpair.joint2] else { continue }
            
            squatConnection.append(Connection(one, two))
        }
    }
    
    static func fromObservation(_ observations: [Observation]?) -> [Pose]?{
        observations?.compactMap{
            Pose($0)
        }
    }
    
    static func areaEstimateOfLandmarks(_ landmarks: [Landmark]) -> CGFloat {
        let xCoordinates = landmarks.map { $0.location.x }
        let yCoordinates = landmarks.map { $0.location.y }

        guard let minX = xCoordinates.min() else { return 0.0 }
        guard let maxX = xCoordinates.max() else { return 0.0 }

        guard let minY = yCoordinates.min() else { return 0.0 }
        guard let maxY = yCoordinates.max() else { return 0.0 }

        let deltaX = maxX - minX
        let deltaY = maxY - minY

        return deltaX * deltaY
    }
}
