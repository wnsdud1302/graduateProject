//
//  SampleVisionViewController.swift
//  demo
//
//  Created by 박준영 on 2022/11/05.
//

import UIKit
import AVKit
import PhotosUI

class SampleVisionViewController: UIViewController {
    
    //비디오관련 변수들
    let videoCapture = VideoCapture.shared
    
    private var readerProcessor: VideoReaderProcessor!
    
    var settings: RenderSettings!
    
    var videoAsset: AVAsset!
    
    var recorder:Recorder!
    
    var canRecord = true
    
    
    // UI관련 변수
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var selectedButton: UIButton!
    
    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var ButtonStack: UIStackView!
    
    @IBOutlet weak var recordSgControl: UISegmentedControl!
    
    
    
    
    // squat관련 변수들
    var squatCount: Int!
    
    private var isBottom = true
    
    var squatType = squat_type.normal
    
    var result = front_perform_type.right
    
    var initSquat: frontSquat?
    
    
    
    
    
    
    
    private enum RecordState{
        case idle , start, end
    }
    
    private var recordState = RecordState.idle
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let views = [ButtonStack, countLabel, selectedButton]
        views.forEach{
            $0?.layer.cornerRadius = 10
            view.bringSubviewToFront($0!)
        }
        

        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        videoCapture.isEnabled = true
        
        guard readerProcessor != nil else { return }
        readerProcessor.stopDisplaying()
    }

   
    @IBAction func photoButtonTapped(_: Any){
        
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        let newFilter = PHPickerFilter.any(of: [.videos])
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        configuration.filter = newFilter
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        squatCount = 0
        present(picker, animated: true)
        
        guard readerProcessor != nil else {
            return
        }
        readerProcessor.stopDisplaying()
        
        countLabel.text = String(0)
        
        initSquat = nil
    }

}

extension SampleVisionViewController: VideoReaderProcessorDelegate{
    func checkSquat(didPredict squat: frontSquat?) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            guard let squat = squat else { return }
            guard initSquat != nil else { initSquat = squat; return }
            let inBottom = squat.countSquats()
            if isBottom != inBottom{ return }
            if isBottom{
                squatCount += 1
            }
            isBottom = !isBottom
            
            DispatchQueue.main.async { [self] in
                countLabel.text = String(squatCount)
            }
        }
    }
    
    func displayFrame(in frame: CGImage, didDetect poses: [Pose]?, with squat: frontSquat?) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            let buffer = drawPoses(poses, onto: frame)
            if !canRecord{ return }
            guard let squat = squat else { return }
            let inBottom = squat.countSquats()
            let result = squat.checkPerform(inBottom, initSquat)
            self.result = result
            if result == .right || result == .lessDepth{
                recordState = .end
                return
            }
            record(buffer, self.result)
            recordState = .start
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
}



extension SampleVisionViewController: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        
        guard let provider = results.first?.itemProvider else { return }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier){ url, error in
                guard url != nil else { return }
            let av = AVAsset(url: url!)
            self.readerProcessor = VideoReaderProcessor(videoAsset: av)
            self.readerProcessor.delegate = self
            self.readerProcessor.readAndDisplayFrame()
        }
    }
    
    
}

extension SampleVisionViewController{
    
    func record(_ image: UIImage, _ type: front_perform_type){
        switch recordState{
        case .start:
            guard recorder != nil else {
                startRecord(image)
                return
            }
            if !recorder.appendPixelBuffer(image: image){
                recordState = .end
            }
        case .end:
            guard recorder == nil else {
                finishRecord(type)
                return
            }
        default:
            break
        }
    }
    
    func startRecord(_ image: UIImage){
            settings = RenderSettings(size: image.size)
            settings.videoFilename += ("-" + String(squatCount))
            recorder = Recorder(settings: settings)
            recorder.start()
    }
    
    func finishRecord(_ result: front_perform_type){
        print(settings.outputURL)
        recorder.finish()
        db.addDay(Date())
        db.addSummary(db.dateFormatter.string(from: Date()), Int64(squatCount), result.rawValue, settings.videoFilename)
        recorder = nil
    }
    
    @IBAction func disableRecord(segment: UISegmentedControl){
        canRecord = segment.selectedSegmentIndex != 1
        if !canRecord{
            countLabel.layer.isHidden = true
        }else{
            countLabel.layer.isHidden = false
        }
    }
    
}
