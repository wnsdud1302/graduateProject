//
//  VideoProcessingChain.swift
//  demo
//
//  Created by 박준영 on 2022/10/31.
//

import CoreImage
import Combine
import Vision
import UniformTypeIdentifiers
import AVFoundation
import UIKit

enum CaptureState {
    case idle, start, capturing, end
}

protocol VideoProcessingChainDelegate:AnyObject{
    
    func videoProcessingChain(_ chain: VideoProcessingChain,
    didDetect poses: [Pose]?,
                              in frame: CGImage)
    
    func videoProcessingChain(_ chain: VideoProcessingChain, didPredict squat: frontSquat?)
}

class VideoProcessingChain{
    weak var delegate: VideoProcessingChainDelegate?
    
    static let shared = VideoProcessingChain()
    
    var upstreamPublisher: AnyPublisher<Frame, Never>!{
        didSet { buildProcessingChain() }
    }
    
    var poses:[Pose]?
    
    private var frameProcessingChain: AnyCancellable?
    
    private let humanBodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    private func buildProcessingChain(){
        guard upstreamPublisher != nil else{ return }
        frameProcessingChain = upstreamPublisher
            .compactMap(imagefromFrame)
            .map(findPoseInFrame)
            .sink(receiveValue: getFrontSquat)
    }
}

extension VideoProcessingChain{
    private func imagefromFrame(_ input: Frame) -> CGImage?{
        guard let buffer = input.imageBuffer else { return nil}
        let ciContext = CIContext(options: nil)
        let ciimage = CIImage(cvImageBuffer: buffer)
        
        guard let cgimage = ciContext.createCGImage(ciimage, from: ciimage.extent) else { return nil}
        return cgimage
    }
    
    private func findPoseInFrame(_ frame: CGImage)->[Pose]? {
        let visionRequestHandler = VNImageRequestHandler(cgImage: frame)
        
        do{
            try visionRequestHandler.perform([humanBodyPoseRequest])
        }catch{
            assertionFailure("human Pose Request failed: \(error)")
        }
        let poses = Pose.fromObservation(humanBodyPoseRequest.results)
        DispatchQueue.main.async {
            self.delegate?.videoProcessingChain(self, didDetect: poses, in: frame)
        }
        
        self.poses = poses
        
        return poses
    }
    
    private func getFrontSquat(_ poses:[Pose]?){
        let squat = frontSquat(poses)
        self.delegate?.videoProcessingChain(self, didPredict: squat)
        
    }
    
}
