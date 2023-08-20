////
//  CAEDE467-6165-4B58-B0C1-DE2A7652E210: 2:20 PM 8/14/23
//  ContentView.swift by Gab
//  

import SwiftUI
import AVFoundation

struct ContentView: View {
    let session = VideoSession()
    
    var body: some View {
        VideoPreview(session: session)
            .task(priority: .background) {
                let videoInputs = await session.listVideoInputs()
                let audioInputs = await session.listAudioInputs()
                
                if let externalVideo = videoInputs.first, let externalVideoInput = try? AVCaptureDeviceInput(device: externalVideo),
                   let externalAudio = audioInputs.first, let externalAudioInput = try? AVCaptureDeviceInput(device: externalAudio) {
                    session.addInput(externalVideoInput).addInput(externalAudioInput).establishRotationCoordinator(on: externalVideo).unflipAllConnections()
                }
                
                await session.startRunnning()
            }
    }
}

#Preview {
    ContentView()
}
