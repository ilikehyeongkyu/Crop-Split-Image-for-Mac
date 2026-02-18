import SwiftUI
import AppKit
import UniformTypeIdentifiers

// 메인 뷰: 이미지 로드, 크롭 크기 입력, 프리셋 선택, 분할 설정과 미리보기 영역을 포함합니다.
struct ContentView: View {
    @State private var nsImage: NSImage? = nil
    @State private var imageSize: CGSize = .zero
    @State private var imageURL: URL? = nil

    @State private var cropWidthText: String = ""
    @State private var cropHeightText: String = ""
    @State private var lockAspect: Bool = false
    @State private var selectedPreset: Preset? = nil

    @State private var cols: Int = 1
    @State private var rows: Int = 1

    @State private var selectionCenter: CGPoint = .zero // image-pixel coords
    @State private var selectionSize: CGSize = .zero // image-pixel size for interactive resize
    // 프리셋 목록: ContentView에서 중앙 관리합니다.
    let presets: [Preset] = [
        Preset(name: "Instagram Vertical (4:5)", ratio: CGSize(width: 4, height: 5), cols: 1, rows: 1),
        Preset(name: "Instagram Square (1:1)", ratio: CGSize(width: 1, height: 1), cols: 1, rows: 1),
        Preset(name: "Instagram Two Across (8:5)", ratio: CGSize(width: 8, height: 5), cols: 2, rows: 1),
        Preset(name: "Instagram Three Across (12:5)", ratio: CGSize(width: 12, height: 5), cols: 3, rows: 1),
        Preset(name: "Instagram Four Across (16:5)", ratio: CGSize(width: 16, height: 5), cols: 4, rows: 1)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            ControlsView(presets: presets, cropWidthText: $cropWidthText, cropHeightText: $cropHeightText, lockAspect: $lockAspect, selectedPreset: $selectedPreset, cols: $cols, rows: $rows, imageSize: imageSize, loadImage: loadImage, applyPreset: applyPreset, cropAndSave: cropAndSave)

            Divider()

            GeometryReader { geo in
                ZStack {
                    Color.secondary.opacity(0.05)
                    if let img = nsImage {
                        // calculate displayed image frame
                        let imgSize = img.size
                        let scale = min(geo.size.width / imgSize.width, geo.size.height / imgSize.height)
                        let dispSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
                        let origin = CGPoint(x: (geo.size.width - dispSize.width) / 2, y: (geo.size.height - dispSize.height) / 2)
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: dispSize.width, height: dispSize.height)
                            .position(x: origin.x + dispSize.width/2, y: origin.y + dispSize.height/2)
                            .overlay(
                                SelectionOverlay(
                                    imageSize: imgSize,
                                    dispOrigin: origin,
                                    dispSize: dispSize,
                                    selectionCenter: $selectionCenter,
                                    selectionSize: $selectionSize,
                                    lockAspect: $lockAspect,
                                    cols: cols,
                                    rows: rows,
                                    cropSizeProvider: { computedCropSizeInImagePixels() },
                                    onChange: { newSize, newCenter in
                                        DispatchQueue.main.async {
                                            cropWidthText = "\(Int(max(1, round(newSize.width))))"
                                            cropHeightText = "\(Int(max(1, round(newSize.height))))"
                                            selectionCenter = newCenter
                                        }
                                    }
                                )
                            )
                    } else {
                        Text("Load an image.")
                            .foregroundColor(.secondary)
                    }
                }
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
            }
        }
        .onChange(of: nsImage) { _, new in
            if let im = new {
                imageSize = im.size
                selectionCenter = CGPoint(x: im.size.width/2, y: im.size.height/2)
                if cropWidthText.isEmpty && cropHeightText.isEmpty {
                    cropWidthText = "\(Int(im.size.width))"
                    cropHeightText = "\(Int(im.size.height))"
                }
                selectionSize = computedCropSizeInImagePixels()
            } else {
                imageSize = .zero
            }
        }
        .onChange(of: cropWidthText) { _, _ in
            selectionSize = computedCropSizeInImagePixels()
        }
        .onChange(of: cropHeightText) { _, _ in
            selectionSize = computedCropSizeInImagePixels()
        }
    }

    // 프리셋을 적용하여 크롭 비율과 분할(cols/rows)을 설정합니다.
    private func applyPreset(_ p: Preset) {
        if imageSize.width > 0 {
            let w = imageSize.width
            let ratio = p.ratio
            let desiredWidth = min(w, w)
            let desiredHeight = desiredWidth * (ratio.height / ratio.width)
            cropWidthText = "\(Int(desiredWidth))"
            cropHeightText = "\(Int(desiredHeight))"
            // apply split from preset
            cols = p.cols
            rows = p.rows
        }
    }

    // 현재 입력값과 잠금(비율)을 고려해 이미지 픽셀 단위의 크롭 사이즈를 계산합니다.
    private func computedCropSizeInImagePixels() -> CGSize {
        var cw = CGFloat(Int(cropWidthText) ?? 0)
        var ch = CGFloat(Int(cropHeightText) ?? 0)
        if lockAspect {
            if let p = selectedPreset {
                let ratio = p.ratio
                if cw > 0 { ch = cw * ratio.height / ratio.width }
                else if ch > 0 { cw = ch * ratio.width / ratio.height }
                else { cw = imageSize.width; ch = imageSize.height }
            } else {
                if cw > 0 && ch > 0 { }
                else if cw > 0 { ch = cw * (imageSize.height / imageSize.width) }
                else if ch > 0 { cw = ch * (imageSize.width / imageSize.height) }
                else { cw = imageSize.width; ch = imageSize.height }
            }
        } else {
            if cw == 0 { cw = imageSize.width }
            if ch == 0 { ch = imageSize.height }
        }
        return CGSize(width: max(1, min(cw, imageSize.width)), height: max(1, min(ch, imageSize.height)))
    }

    // 파일 열기 패널을 띄워 이미지를 선택하고 로드합니다.
    private func loadImage() {
        let panel = NSOpenPanel()
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        } else {
            panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic", "tiff"]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            nsImage = img
            imageURL = url
        }
    }

    // 드래그 앤 드롭으로 전달된 파일 URL을 처리하여 이미지를 로드합니다.
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                        if let data = item as? Data, let str = String(data: data, encoding: .utf8) {
                            // data is a file URL string like file:///...
                            if let url = URL(string: str), let img = NSImage(contentsOf: url) {
                                DispatchQueue.main.async {
                                    self.nsImage = img
                                    self.imageURL = url
                                }
                            }
                        } else if let url = item as? URL, let img = NSImage(contentsOf: url) {
                            DispatchQueue.main.async {
                                self.nsImage = img
                                self.imageURL = url
                            }
                        }
                }
                return true
            }
        }
        return false
    }

    // 현재 선택 영역을 기준으로 크롭 및 분할한 이미지를 선택한 디렉터리에 저장합니다.
    private func cropAndSave() {
        guard let img = nsImage else { return }
        let cropSize = computedCropSizeInImagePixels()

        var originX = selectionCenter.x - cropSize.width/2
        var originY = selectionCenter.y - cropSize.height/2
        originX = max(0, min(originX, imageSize.width - cropSize.width))
        originY = max(0, min(originY, imageSize.height - cropSize.height))

        let cropRect = CGRect(x: originX, y: imageSize.height - originY - cropSize.height, width: cropSize.width, height: cropSize.height)

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK, let dir = panel.url {
            do {
                let base: String
                if let u = imageURL {
                    base = "\(u.deletingPathExtension().lastPathComponent)_crop"
                } else {
                    base = "crop"
                }
                let saved = try ImageProcessor.cropAndSplitAndSave(image: img, cropRectInImagePixels: cropRect, cols: max(1, cols), rows: max(1, rows), directory: dir, baseName: base)
                print("Saved: \(saved)")
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}



#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
