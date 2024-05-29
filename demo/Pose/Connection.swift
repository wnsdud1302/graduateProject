//
//  Connection.swift
//  demo
//
//  Created by 박준영 on 2022/11/01.
//

import UIKit


extension Pose{
    struct Connection{
        static let width:CGFloat = 12.0
        
        static let colors = [UIColor.systemGreen.cgColor,
                             UIColor.systemYellow.cgColor,
                             UIColor.systemOrange.cgColor,
                             UIColor.systemRed.cgColor,
                             UIColor.systemPurple.cgColor,
                             UIColor.systemBlue.cgColor
        ] as CFArray

        static let gradientColorSpace = CGColorSpace(name: CGColorSpace.sRGB)

        static let gradient = CGGradient(colorsSpace: gradientColorSpace,
                                         colors: colors,
                                         locations: [0, 0.2, 0.33, 0.5, 0.66, 0.8])!
        
        private let point1: CGPoint
        
        private let point2: CGPoint
        
        init(_ one: CGPoint, _ two: CGPoint){ point1 = one; point2 = two }
        
        func drawContext(_ context: CGContext, applying transform: CGAffineTransform? = nil,
                         at scale:CGFloat = 1.0){
            let start = point1.applying(transform ?? .identity)
            let end = point2.applying(transform ?? .identity)
            context.saveGState()
            
            defer{ context.restoreGState() }
            
            context.setLineWidth(Connection.width * scale)
            context.move(to: start)
            context.addLine(to: end)
            context.replacePathWithStrokedPath()
            context.clip()
            context.drawLinearGradient(Connection.gradient, start: start, end: end, options: .drawsAfterEndLocation)
        }
        
        func distance() -> Double{
            return point1.distance(to: point2)
        }
        
        func angle() -> Double{
            return atan2(point1.y - point2.y, point1.x - point2.x)
        }
    }
    
    static let jointPairs: [(joint1: JointName, joint2: JointName)] = [
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),

        // The left leg's connections.
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),

        // The right arm's connections.
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),

        // The right leg's connections.
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),

        // The torso's connections.
        (.leftShoulder, .neck),
        (.rightShoulder, .neck),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip)    ]
    
    static let squatJointPairs: [(joint1: JointName, joint2: JointName)] = [
        (.leftKnee, .rightKnee),
        (.leftAnkle, .rightAnkle),
        
        (.rightHip, .rightKnee),
        (.rightAnkle, .rightKnee),
        
        (.leftHip, .leftKnee),
        (.leftAnkle, .leftKnee),
        
        (.rightShoulder, .rightHip),
        (.rightKnee, .rightHip)
        

    ]
}

extension CGPoint{
    func distance(to point:CGPoint) -> Double {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
