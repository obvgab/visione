////
//  74C8A380-1E60-409B-9AD9-B7D0D6CA068C: 11:31 AM 8/15/23
//  VideoPreview.swift by Gab
//  

import Foundation
import AVFoundation
import SwiftUI

struct VideoSession {
    let gravity: AVLayerVideoGravity // Video input
    let previewLayer: AVCaptureVideoPreviewLayer
    var session: AVCaptureSession { previewLayer.session! }
    var coordinator = RotationCoordinator()
  
    class RotationCoordinator { // Rotation Observers
        var instances: [AVCaptureDevice.RotationCoordinator] = []
        var observations: [NSKeyValueObservation] = []
    }

    init(with session: AVCaptureSession = AVCaptureSession(), gravity: AVLayerVideoGravity = .resizeAspect) {
        self.gravity = gravity
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
    }
    
    // exported functions
    @discardableResult func addInput(_ input: AVCaptureInput) -> Self { if session.canAddInput(input) { session.addInput(input) }; return self }
    @discardableResult func removeInput(_ input: AVCaptureInput) -> Self { session.removeInput(input); return self }
    
    @discardableResult func addOutput(_ output: AVCaptureOutput) -> Self { if session.canAddOutput(output) { session.addOutput(output) }; return self }
    @discardableResult func removeOutput(_ input: AVCaptureOutput) -> Self { session.removeOutput(input); return self }
    
    func startRunnning() async { session.startRunning() }
    func stopRunning() async { session.stopRunning() }
    
    // provide inputs
    func ensurePermissions() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { _ in return }
        case .denied: fallthrough
        case .restricted: fallthrough
        default: return false
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: break
        case .notDetermined: AVCaptureDevice.requestAccess(for: .audio) { _ in return }
        case .denied: fallthrough
        case .restricted: fallthrough
        default: return false
        }
        
        return true
    }
    
    @discardableResult
    func unflipAllConnections() -> Self {
        session.connections.forEach { connection in
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
        return self
    }
    
    func listVideoInputs() async -> [AVCaptureDevice] {
        guard await ensurePermissions() else { return [] }
        
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified).devices
    }
    
    func listAudioInputs() async -> [AVCaptureDevice] {
        guard await ensurePermissions() else { return [] }
        
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone], mediaType: .audio, position: .unspecified).devices
    }
    
    // rotation
    @discardableResult
    func establishRotationCoordinator(on device: AVCaptureDevice) -> Self {
        let instance = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        previewLayer.connection?.videoRotationAngle = instance.videoRotationAngleForHorizonLevelPreview
        
        let observation = instance.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [self] _, change in
            guard let angle = change.newValue else { return }
            previewLayer.connection?.videoRotationAngle = angle
        }
        
        coordinator.instances.append(instance)
        coordinator.observations.append(observation)
        return self
    }
}

// MARK: Preview Layer Shenanigans
#if os(iOS) || os(tvOS)
struct VideoPreview: UIViewControllerRepresentable {
    let session: VideoSession
    
    class ViewController: UIViewController {
        let session: VideoSession
        
        init(_ session: VideoSession) {
            self.session = session
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        override func viewWillLayoutSubviews() { // Handle view layout changing
            session.previewLayer.videoGravity = session.gravity
            view.layer.addSublayer(session.previewLayer)
            session.previewLayer.frame = view.bounds
            //view.layer.addSublayer(session.displayLayer)
        }
    }
    
    func makeUIViewController(context: Context) -> some UIViewController { return ViewController(session) }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        session.previewLayer.videoGravity = session.gravity
        uiViewController.view.layer.addSublayer(session.previewLayer)
        session.previewLayer.frame = uiViewController.view.bounds
    }
}
#else
struct VideoPreview: NSViewControllerRepresentable {
    let session: VideoSession
    
    func makeNSViewController(context: Context) -> some NSViewController { return NSViewController() }
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        session.previewLayer.videoGravity = session.gravity
        if let layer = nsViewController.view.layer {
            layer.addSublayer(session.previewLayer)
        } else {
            nsViewController.view.layer = session.previewLayer
        }
        session.previewLayer.frame = nsViewController.view.bounds
    }
}
#endif
