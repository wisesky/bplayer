import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let item: PlaylistItem
    @EnvironmentObject private var playlistStore: PlaylistStore

    @State private var player: AVPlayer = AVPlayer()
    @State private var isPlaying: Bool = false
    @State private var timeObserver: Any?
    @State private var isReady: Bool = false
    @State private var accessedURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            VideoPlayer(player: player)
                .onAppear { prepareAndPlay() }
                .onDisappear { cleanupPlayer() }
                .background(Color.black)
                .overlay(alignment: .topTrailing) {
                    AirPlayView()
                        .padding(12)
                }

            controls
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button(action: togglePlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
            }
            .buttonStyle(.bordered)

            Button(action: seekBackward) {
                Image(systemName: "gobackward.10")
            }

            Button(action: seekForward) {
                Image(systemName: "goforward.10")
            }

            Spacer()
        }
        .padding()
    }

    private func prepareAndPlay() {
        guard let url = item.displayURL else { return }

        var playableURL = url
        if url.isFileURL {
            _ = url.startAccessingSecurityScopedResource()
            accessedURL = url
        }

        let playerItem = AVPlayerItem(url: playableURL)
        player.replaceCurrentItem(with: playerItem)

        addPeriodicTimeObserver()

        if item.lastPlaybackTime > 2 {
            let time = CMTime(seconds: item.lastPlaybackTime, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        player.play()
        isPlaying = true
    }

    private func cleanupPlayer() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        if let accessedURL {
            accessedURL.stopAccessingSecurityScopedResource()
            self.accessedURL = nil
        }

        player.pause()
        isPlaying = false
    }

    private func togglePlay() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func seekBackward() {
        let current = player.currentTime().seconds
        let target = max(0, current - 10)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    private func seekForward() {
        let current = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? .infinity
        let target = min(duration, current + 10)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let seconds = time.seconds
            playlistStore.update(item: item, playbackTime: seconds)
        }
    }
}

private struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = true
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) { }
}