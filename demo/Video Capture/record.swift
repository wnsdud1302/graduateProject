//
//  record.swift
//  demo
//
//  Created by 박준영 on 2022/11/05.
//

import AVFoundation
import UIKit
import Photos

struct RenderSettings {
    
    var size : CGSize = .zero
    var fps: Int32 = 30   // frames per second
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = UUID().uuidString + "-" + db.dateFormatter.string(from: Date())
    var videoFilenameExt = "mov"
    
    
    var outputURL: URL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
        }
        fatalError("URLForDirectory() failed")
    }
}

class Recorder{
    private var settings: RenderSettings
    var assetWriter: AVAssetWriter!
    var assetWriterInput: AVAssetWriterInput!
    var adapter: AVAssetWriterInputPixelBufferAdaptor!
    
    var avOutputSettings: [String: Any]
    var frameNum = 0
    static let kTimescale: Int32 = 600
    
    var isReadyForData: Bool {
        return assetWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    init(settings: RenderSettings){
        self.settings = settings
        self.avOutputSettings = [
            AVVideoCodecKey: settings.avCodecKey,
            AVVideoWidthKey: NSNumber(value: Float(settings.size.width)),
            AVVideoHeightKey: NSNumber(value: Float(settings.size.height))
        ]
        
    }
    
    func pixelBufferFromImage(image: CGImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        
        var pixelBufferOut: CVPixelBuffer?
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x:0,y: 0,width: size.width,height: size.height))
        
        let horizontalRatio = size.width / settings.size.width
        let verticalRatio = size.height / settings.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        
        let newSize = CGSize(width: settings.size.width * aspectRatio, height: settings.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        context?.draw(image, in: CGRect(x:x,y: y, width: newSize.width, height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        
        var pixelBufferOut: CVPixelBuffer?
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x:0,y: 0,width: size.width,height: size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        context?.draw(image.cgImage!, in: CGRect(x:x,y: y, width: newSize.width, height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func start(){
        assetWriter = createAssetWriter(outputURL: settings.outputURL)
        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        
        if assetWriter.canAdd(assetWriterInput){
            assetWriter.add(assetWriterInput)
        }else{
            fatalError("AVAssetWriter() failed")
        }
        
        createPixelBufferAdaptor()
        if assetWriter.startWriting() == false {
            fatalError("starting() failed")
        }
        
        assetWriter.startSession(atSourceTime: .zero)
    }
    
    
    private func createAssetWriter(outputURL: URL) -> AVAssetWriter {
        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter() failed")
        }
        
        guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
            fatalError("canApplyOutputSettings() failed")
        }
        
        return assetWriter
    }
    
    private func createPixelBufferAdaptor() {
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(settings.size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(settings.size.height))
        ]
        adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
    }
    
    private func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        precondition(adapter != nil, "Call start() to initialize the writer")
        
        guard adapter.pixelBufferPool != nil else { return false }
        
        let pixelBuffer = pixelBufferFromImage(image: image, pixelBufferPool: adapter.pixelBufferPool!, size: settings.size)
        
        return adapter.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    private func addImage(image: CGImage, withPresentationTime presentationTime: CMTime) -> Bool {
        precondition(adapter != nil, "Call start() to initialize the writer")
        
        guard adapter.pixelBufferPool != nil else { return false }
        
        let pixelBuffer = pixelBufferFromImage(image: image, pixelBufferPool: adapter.pixelBufferPool!, size: settings.size)
        
        return adapter.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func appendPixelBuffer(image: UIImage) -> Bool{
        let frameDuration = CMTimeMake(value: Int64(Recorder.kTimescale / settings.fps), timescale: Recorder.kTimescale)
        
        if isReadyForData == true {
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = addImage(image: image, withPresentationTime: presentationTime)
            //print(success)
            if success == false {
                return false
            }
            frameNum += 1
        }
        else {
            return false
        }
        return true
    }
    
    func appendPixelBuffer(image: CGImage) -> Bool{
        let frameDuration = CMTimeMake(value: Int64(Recorder.kTimescale / settings.fps), timescale: Recorder.kTimescale)
        
        if isReadyForData == true {
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = addImage(image: image, withPresentationTime: presentationTime)
            //print(success)
            if success == false {
                return false
            }
            frameNum += 1
        }
        else {
            return false
        }
        return true
    }
    
    func finish(){
        guard isReadyForData == true, assetWriter.status != .failed else { return }
        assetWriterInput.markAsFinished()
        assetWriter.finishWriting { [weak self] in
            self?.assetWriter = nil
            self?.assetWriterInput = nil
            print(self?.settings.outputURL)
            self?.saveToLibrary(videoURL: (self?.settings.outputURL)!)
        }
    }
    
    func removeFileAtURL(fileURL: URL){
        do{
            try FileManager.default.removeItem(at: fileURL)
            }catch _ as NSError{
        }
    }
    
    func saveToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:", error)
                }
                //self.removeFileAtURL(fileURL: self.settings.outputURL)
            }
        }
    }
}
