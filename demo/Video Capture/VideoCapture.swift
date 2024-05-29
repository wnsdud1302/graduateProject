//
//  VideoCapture.swift
//  demo
//
//  Created by 박준영 on 2022/10/31.
//
import AVFoundation
import UIKit
import Combine

typealias Frame = CMSampleBuffer
typealias FramePublisher = AnyPublisher<Frame, Never>

protocol VideoCaptureDelegate: AnyObject{
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher)
}

class VideoCapture:NSObject{
    
    weak var delegate: VideoCaptureDelegate! {
        didSet { createVideoFramePublisher() }
    }
    
    static let shared = VideoCapture()

    
    private let captureSession = AVCaptureSession()
    
    var framePulisher: PassthroughSubject<Frame, Never>?
    
    private let videoCaptureQueue = DispatchQueue(label: "Video Cpature Queue",
                                                  qos: .userInitiated)
        
    private var videoStabilizationEnabled = true
    
    private var cameraPosition = AVCaptureDevice.Position.front{
        didSet{ createVideoFramePublisher()}
    }
    
    private var horizontalFlip: Bool {
        // Instruct the capture session to horizontally flip the image when the
        // user selects the front-facing camera.
        cameraPosition == .front
    }

    
    var isEnabled = true {
        didSet { isEnabled ? enableCaptureSession() : disableCaptureSession() }
    }
    
    private var orientation = AVCaptureVideoOrientation.portrait{
        didSet { createVideoFramePublisher() }
    }

    func toggleCameraSelection() {
        cameraPosition = cameraPosition == .back ? .front : .back
    }
    
    func updateDeviceOrientation() {
        // Retrieve the device's orientation from UIKit.
        let currentPhysicalOrientation = UIDevice.current.orientation

        // Use the device's physical orientation to orient the camera.
        switch currentPhysicalOrientation {

        // Default to portrait if face up, face down, or unknown.
        case .portrait, .faceUp, .faceDown, .unknown:
            // Use portrait for "flat" orientations.
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            // UIKit's "left" is the equivalent to AVFoundation's "right."
            orientation = .landscapeRight
        case .landscapeRight:
            // UIKit's "right" is the equivalent to AVFoundation's "left."
            orientation = .landscapeLeft

        // Use portrait as the default for any future, unknown cases.
        @unknown default:
            orientation = .portrait
        }
    }

    
    private func enableCaptureSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }

    private func disableCaptureSession() {
        if captureSession.isRunning { captureSession.stopRunning() }
    }
    
}

extension VideoCapture:AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput frame: Frame, from connection: AVCaptureConnection) {
        framePulisher?.send(frame)
    }
}

extension VideoCapture{
    
    private func createVideoFramePublisher(){
        guard let videoDataOutput = configureSession() else{
            return
        }
        let subject = PassthroughSubject<Frame, Never>()
        self.framePulisher = subject
        videoDataOutput.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        let genericPublisher = subject.eraseToAnyPublisher()
        
        delegate.videoCapture(self, didCreate: genericPublisher)
        
    }
    
    func configureSession() -> AVCaptureVideoDataOutput? {
        disableCaptureSession()
        guard isEnabled else {
            print("capture session is disabled")
            return nil
        }
        
        defer { enableCaptureSession() }
        
        captureSession.beginConfiguration()
        
        defer { captureSession.commitConfiguration() }
        
        let input = AVCaptureDeviceInput.createCameraInput(position: cameraPosition, frameRate: 60.0)
        let output = AVCaptureVideoDataOutput()
        
        let success = configureCaptureConnection(input, output)
        
        
        return success ? output : nil
        
    }
    
    private func configureCaptureConnection(_ input: AVCaptureDeviceInput?,
                                            _ output: AVCaptureVideoDataOutput?) -> Bool {

        guard let input = input else { return false }
        guard let output = output else { return false }

        // Clear inputs and outputs from the capture session.
        captureSession.inputs.forEach(captureSession.removeInput)
        captureSession.outputs.forEach(captureSession.removeOutput)

        guard captureSession.canAddInput(input) else {
            print("The camera input isn't compatible with the capture session.")
            return false
        }

        guard captureSession.canAddOutput(output) else {
            print("The video output isn't compatible with the capture session.")
            return false
        }

        // Add the input and output to the capture session.
        captureSession.addInput(input)
        captureSession.addOutput(output)

        // This capture session must only have one connection.
        guard captureSession.connections.count == 1 else {
            let count = captureSession.connections.count
            print("The capture session has \(count) connections instead of 1.")
            return false
        }

        // Configure the first, and only, connection.
        guard let connection = captureSession.connections.first else {
            print("Getting the first/only capture-session connection shouldn't fail.")
            return false
        }

        if connection.isVideoOrientationSupported {
            // Set Cthe video capture's orientation to match that of the device.
            connection.videoOrientation = orientation
        }

        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = horizontalFlip
        }

        if connection.isVideoStabilizationSupported {
            if videoStabilizationEnabled {
                connection.preferredVideoStabilizationMode = .standard
            } else {
                connection.preferredVideoStabilizationMode = .off
            }
        }

        // Discard newer frames if the app is busy with an earlier frame.
        output.alwaysDiscardsLateVideoFrames = true

        return true
    }

}

