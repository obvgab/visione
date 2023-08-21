////
//  CAEDE467-6165-4B58-B0C1-DE2A7652E210: 2:20 PM 8/14/23
//  ContentView.swift by Gab
//  

import SwiftUI
import AVFoundation

struct ContentView: View {
    let session = VideoSession()
    let audioEngine = AVAudioEngine()
    
    var body: some View {
        VideoPreview(session: session)
            .task(priority: .background) {
                let videoInputs = await session.listVideoInputs()
                //let audioInputs = await session.listAudioInputs()
                
                if let externalVideo = videoInputs.first, let externalVideoInput = try? AVCaptureDeviceInput(device: externalVideo)//,
                   //let externalAudio = audioInputs.first, let externalAudioInput = try? AVCaptureDeviceInput(device: externalAudio) {
                {
                    session.addInput(externalVideoInput).establishRotationCoordinator(on: externalVideo).unflipAllConnections()
                }
                
                await session.startRunnning()
                
                let audioInputNode = audioEngine.inputNode
                let audioOutputNode = audioEngine.outputNode
                
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                try? AVAudioSession.sharedInstance().setActive(true)
                
                audioEngine.connect(audioInputNode, to: audioOutputNode, format: audioInputNode.inputFormat(forBus: 0))
                
                audioEngine.prepare()
                try? audioEngine.start()
            }
    }
}

#Preview {
    ContentView()
}
