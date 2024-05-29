//
//  VideoReaderProcessor.swift
//  demo
//
//  Created by 박준영 on 2022/11/05.
//

import Foundation
import UIKit
import Vision
import AVFoundation
import Combine

protocol VideoReaderProcessorDelegate: AnyObject{
    func displayFrame(in frame: CGImage, didDetect poses: [Pose]?, with squat: frontSquat?)
    func checkSquat(didPredict squat: frontSquat?)
}


class VideoReaderProcessor{
    
    var videoAsset:AVAsset!
    
    weak var delegate:VideoReaderProcessorDelegate?
    
    private let humanBodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    private var cancelDisplay = false
    
    private var frameProcessingChain: AnyCancellable?
    
    init(videoAsset: AVAsset!) {
        self.videoAsset = videoAsset
        print("initialize processor")
    }
    
    func readAndDisplayFrame() {
        guard let videoReader = VideoReader(videoAsset: videoAsset) else {
            print("fail initialize VideoReader")
            return
        }
        guard videoReader.nextFrame() != nil else {
            print("failed to get frame")
            return
        }
        let requests = [humanBodyPoseRequest]
        var frames = 1
        
            while true{
                guard cancelDisplay == false, let frame = videoReader.nextFrame() else {
                    break
                }
                let visionRequestHnadler = VNImageRequestHandler(cgImage: frame, orientation: videoReader.orientation)

                do{
                    try visionRequestHnadler.perform(requests)
                }catch{
                    assertionFailure("human Pose Request failed: \(error)")
                }
                let poses = Pose.fromObservation(humanBodyPoseRequest.results)
                self.delegate?.displayFrame(in: frame, didDetect: poses, with: frontSquat(poses))
                self.delegate?.checkSquat(didPredict: frontSquat(poses))
                frames += 1
        }
    }
    
    func stopDisplaying(){
        cancelDisplay = true
    }
}


