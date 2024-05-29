//
//  ViewController.swift
//  demo
//
//  Created by 박준영 on 2022/10/31.
//

import UIKit
import Combine
import PhotosUI
import AVKit
import CoreImage

enum WatchState{
    case start, stop
}

class VisionViewController: UIViewController {
    
    
    //video관련 변수
    let videoCapture = VideoCapture.shared
    
    let videoProcessingChain = VideoProcessingChain.shared
    
    var recoder:Recorder!
    
    var settings: RenderSettings!
    
    var isBottom = true
    
    private var recordState = RecordState.idle
    
    private var canRecord = true //true: 녹화 가능, false: 녹화불가능
    
    var frameValue = true // true: uiimage, false: Frame

    var fileName = ""
    
    
    //squat 관련 변수
    
    var initsqaut: frontSquat?
    
    var squatCount = 0
    
    var bodyType = squat_type.normal
    
    var performType = front_perform_type.right
    

    
    var cdTimer: CDTimer!
    
    var start:Date?
    

    
    private enum RecordState{
        case idle , start, end
    }
    

    
    private var lenRecord:Int = 0
    
    //UI 관련 변수
    
    @IBOutlet weak var ButtonStack: UIStackView!
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var PhotoButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var labelStack: UIStackView!
    
    @IBOutlet weak var recordLabel: UILabel!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var frameToggle: UISwitch! // true: uiimage, false: Frame
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let views = [ButtonStack, labelStack, cameraButton, PhotoButton, saveButton]
        
        views.forEach{ view in
            view?.layer.cornerRadius = 10
            view?.overrideUserInterfaceStyle = .dark
        }
        
        videoProcessingChain.delegate = self
        
        videoCapture.delegate = self
        
        typeLabel.text = "not define"
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        videoCapture.isEnabled = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoCapture.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoCapture.updateDeviceOrientation()
        videoCapture.isEnabled = true
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        videoCapture.updateDeviceOrientation()
    }
    
    
    @IBAction func toggleFrame(_ sender: UISwitch) {
        frameValue = frameToggle.isOn
    }
    
}

extension VisionViewController:VideoCaptureDelegate{
    func videoCapture(_ videoCapture: VideoCapture, didCreate framePublisher: FramePublisher) {
        videoProcessingChain.upstreamPublisher = framePublisher
    }
}

extension VisionViewController:VideoProcessingChainDelegate{
    func videoProcessingChain(_ chain: VideoProcessingChain, didPredict squat: frontSquat?) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            guard let squat = squat else { return }
            guard cdTimer != nil else { return }
            if !cdTimer.isOver {
                bodyType = squat.checkBodyState()
                DispatchQueue.main.async { [self] in
                    typeLabel.text = bodyType.rawValue
                }; return }
            guard initsqaut != nil else { initsqaut = squat; return }
            let inBottom = squat.countSquats()
            performType = squat.checkPerform(inBottom, initsqaut)
            DispatchQueue.main.async { [self] in
                typeLabel.text = performType.rawValue
            }
            if isBottom != inBottom { return }
            if isBottom{
                squatCount += 1
            }
            isBottom = !isBottom
            DispatchQueue.main.async {
                self.timerLabel.text = String(self.squatCount)
            }
        }
        
        
    }
    
    
    func videoProcessingChain(_ chain: VideoProcessingChain, didDetect
                              poses: [Pose]?, in frame: CGImage) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            let buffer = self.drawPoses(poses, onto: frame)
            guard cdTimer != nil else { return }
            if !cdTimer.isOver{
                DispatchQueue.main.async { [self] in
                    timerLabel.text = String(cdTimer.remain)
                }
                return
            }
            if canRecord{
                canRecord = false
                return
            }
            
            switch recordState{
            case .start:
                DispatchQueue.main.async { [self] in
                    recordLabel.text = "start recording"
                }
                if !frameValue {
                    if recoder.appendPixelBuffer(image: frame){
                        return
                    }
                    recordState = .end
                }
                if recoder.appendPixelBuffer(image: buffer){
                    return
                }
                recordState = .end
            default:
                break
            }
        }
    }
}
    

extension VisionViewController {
    

    @IBAction func CamButtonTapped(_: Any){
        videoCapture.toggleCameraSelection()
    }
    
    @IBAction func photoButtonTapped(_: Any){
        videoCapture.isEnabled = false
        let vc = SampleVisionViewController(nibName: "SampleVisionViewController", bundle: nil)
        present(vc, animated: true)

    }
    
    @IBAction func recordButtonTapped(){
        
        cdTimer = CDTimer(4, Date()) // 4초뒤 실행
        
        switch recordState{
        case .idle:
            startRecord()
        case .start:
            endRecord()
        case .end:
            startRecord()
        }
    }
    
    func drawPoses(_ poses:[Pose]?, onto frame: CGImage) -> UIImage{
        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.scale = 1.0
        let frameSize = CGSize(width: frame.width, height: frame.height)
        let poseRenderer = UIGraphicsImageRenderer(size: frameSize,
                                                   format: renderFormat)
        
        let frameWithPosesRendering = poseRenderer.image { renderContext in
            let cgContext = renderContext.cgContext
            let inverse = cgContext.ctm.inverted()
            
            cgContext.concatenate(inverse)
            
            let imageRectangle = CGRect(origin: .zero, size: frameSize)
            cgContext.draw(frame, in: imageRectangle)
            
            let pointTransform = CGAffineTransform(scaleX: frameSize.width, y: frameSize.height)
            
            guard let poses = poses else { return }
            
            for pose in poses {
                pose.drawWireframeContext(cgContext, applying: pointTransform)
            }
        }
        DispatchQueue.main.async {
            self.imageView.image = frameWithPosesRendering
        }
        return frameWithPosesRendering

    }
    
    func startRecord(){
        settings = RenderSettings(size: CGSize(width: (imageView.image?.size.width)!, height: (imageView.image?.size.height)!))
        recoder = Recorder(settings: settings)
        recoder.start()
        cdTimer.run()
        canRecord = true
        recordState = .start
        
    }
    
    func endRecord(){
        recoder.finish()
        recordState = .end
        squatCount = 0
        initsqaut = nil
        DispatchQueue.main.async { [self] in
            recordLabel.text = "end recording"
        }
    }
}
