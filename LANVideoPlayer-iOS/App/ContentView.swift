import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var playlistStore: PlaylistStore
    @State private var urlInput: String = ""
    @State private var showFilePicker: Bool = false
    @State private var pickedFileURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("http(s):// 或 HLS 链接", text: $urlInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    Button("添加") {
                        playlistStore.addRemote(urlString: urlInput)
                        urlInput = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack(spacing: 12) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("从“文件”选择视频", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }

                List {
                    ForEach(playlistStore.items) { item in
                        NavigationLink(value: item.id) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.headline)

                                    if let url = item.displayURL {
                                        Text(url.absoluteString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    if item.lastPlaybackTime > 0 {
                                        Text(String(format: "上次播放到 %.0f 秒", item.lastPlaybackTime))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill").font(.title2)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        playlistStore.items.remove(atOffsets: indexSet)
                    }
                    .onMove { indices, newOffset in
                        playlistStore.items.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("局域网视频播放器")
            .toolbar { EditButton() }
            .navigationDestination(for: UUID.self) { id in
                if let item = playlistStore.items.first(where: { $0.id == id }) {
                    VideoPlayerView(item: item)
                } else {
                    Text("未找到条目")
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.movie, .mpeg4Movie], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do { try playlistStore.addBookmarkedFile(url: url) } catch { print("Bookmark failed: \(error)") }
            case .failure(let error):
                print("File pick failed: \(error)")
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(PlaylistStore())
}