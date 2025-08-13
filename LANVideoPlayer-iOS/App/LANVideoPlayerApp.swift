import SwiftUI
import AVFoundation

@main
struct LANVideoPlayerApp: App {
    @StateObject private var playlistStore = PlaylistStore()

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playlistStore)
        }
    }
}