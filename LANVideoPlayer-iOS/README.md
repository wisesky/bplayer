# LANVideoPlayer-iOS

一个使用 SwiftUI + AVKit 的简洁 iOS 播放器示例，支持：

- 通过 URL 播放局域网 HTTP/HLS 视频
- 通过“文件”App 选择 SMB/NAS 上的文件（安全作用域书签）
- 播放列表持久化、断点续播
- AirPlay 输出、后台音频

## 目录结构

- `App/` 源码
  - `LANVideoPlayerApp.swift` 入口
  - `ContentView.swift` 播放列表、添加入口
  - `VideoPlayerView.swift` 播放器页面
  - `Models.swift` 播放列表与书签模型
- `Info.plist`

## 构建

1. 在 Xcode 新建 iOS App（SwiftUI + Swift），替换生成的 `App` 源码文件为本仓库 `App/` 内容，并将 `Info.plist` 也替换。
2. Targets -> Signing 里设置你的 Team 与唯一的 Bundle Identifier。
3. 运行到真机或模拟器。

> 如果需要在 HTTP（非 HTTPS）下播放，`Info.plist` 已开启 ATS 例外。

## 使用

- 在主界面粘贴局域网视频 URL（如 `http://192.168.1.10:8080/video.mp4` 或 HLS `.m3u8`），点“添加”。
- 点“从文件选择视频”可以在“文件”App 中选择 SMB/NAS 映射的文件，应用会保存安全作用域书签，下次可直接播放。
- 播放时会每 2 秒保存一次进度，返回列表后可见上次播放时间。

## 兼容性
- iOS 16+（当前使用 `NavigationStack`）。如需兼容 iOS 15，可改为 `NavigationView` + `NavigationLink(destination:)`。

## 注意
- SMB 文件的实际读取由“文件”App 提供的文件提供者完成，本示例通过书签访问选择的文件并交给 `AVPlayer` 播放。
- 若遇到某些编码无法硬解，可考虑改用第三方播放器引擎（如 VLCKit/FFmpegKit），但需额外集成。