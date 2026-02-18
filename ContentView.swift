import SwiftUI
import AppKit

struct Preset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ratio: CGSize
}

struct ContentView: View {
    @State private var nsImage: NSImage? = nil
    @State private var imageSize: CGSize = .zero

    @State private var cropWidthText: String = ""
    @State private var cropHeightText: String = ""
    @State private var lockAspect: Bool = false
    @State private var selectedPreset: Preset? = nil

    @State private var cols: Int = 1
    @State private var rows: Int = 1

    @State private var selectionCenter: CGPoint = .zero // image-pixel coords

    let presets: [Preset] = [
        Preset(name: "인스타그램 세로 (4:5)", ratio: CGSize(width: 4, height: 5)),
        Preset(name: "정사각형 (1:1)", ratio: CGSize(width: 1, height: 1)),
        Preset(name: "가로로 두장 이어붙임 (8:5)", ratio: CGSize(width: 8, height: 5))
    ]

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                Button("Load Image") { loadImage() }
                Text("원본: \(Int(imageSize.width)) x \(Int(imageSize.height))")
                    .frame(minWidth: 160, alignment: .leading)
                HStack(spacing: 8) {
                    TextField("width", text: $cropWidthText)
                        .frame(width: 80)
                    Text("x")
                    TextField("height", text: $cropHeightText)
                        .frame(width: 80)
                    Toggle("비율 고정", isOn: $lockAspect)
                        .toggleStyle(.button)
                }
                Picker("프리셋", selection: Binding(get: { selectedPreset }, set: { new in
                    selectedPreset = new
                    if let p = new {
                        lockAspect = true
                        applyPreset(p)
                    }
                })) {
                    Text("없음").tag(Optional<Preset>.none)
                    ForEach(presets) { p in
                        Text(p.name).tag(Optional(p))
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                Stepper("가로: \(cols)", value: $cols, in: 1...10)
                Stepper("세로: \(rows)", value: $rows, in: 1...10)
                Button("Crop & Save") { cropAndSave() }
            }
            .padding()

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
                                SelectionOverlay(imageSize: imgSize, dispOrigin: origin, dispSize: dispSize, selectionCenter: $selectionCenter, cropSizeProvider: { computedCropSizeInImagePixels() })
                            )
                    } else {
                        Text("이미지를 로드하세요.")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: nsImage) { new in
            if let im = new {
                imageSize = im.size
                selectionCenter = CGPoint(x: im.size.width/2, y: im.size.height/2)
                if cropWidthText.isEmpty && cropHeightText.isEmpty {
                    cropWidthText = "\(Int(im.size.width))"
                    cropHeightText = "\(Int(im.size.height))"
                }
            } else {
                imageSize = .zero
            }
        }
    }

    private func applyPreset(_ p: Preset) {
        // apply by using image width as reference when possible
        if imageSize.width > 0 {
            let w = imageSize.width
            let ratio = p.ratio
            // choose width so that it fits within image
            let desiredWidth = min(w, w)
            let desiredHeight = desiredWidth * (ratio.height / ratio.width)
            cropWidthText = "\(Int(desiredWidth))"
            cropHeightText = "\(Int(desiredHeight))"
        }
    }

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
                // maintain current numbers if both exist
                if cw > 0 && ch > 0 { /* keep */ }
                else if cw > 0 { /* keep cw, ch unknown -> maintain original aspect */ ch = cw * (imageSize.height / imageSize.width) }
                else if ch > 0 { cw = ch * (imageSize.width / imageSize.height) }
                else { cw = imageSize.width; ch = imageSize.height }
            }
        } else {
            if cw == 0 { cw = imageSize.width }
            if ch == 0 { ch = imageSize.height }
        }
        return CGSize(width: max(1, min(cw, imageSize.width)), height: max(1, min(ch, imageSize.height)))
    }

    private func loadImage() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic", "tiff"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            nsImage = img
        }
    }

    private func cropAndSave() {
        guard let img = nsImage else { return }
        let cropSize = computedCropSizeInImagePixels()

        // compute crop rect in image pixels centered at selectionCenter
        var originX = selectionCenter.x - cropSize.width/2
        var originY = selectionCenter.y - cropSize.height/2
        // clamp
        originX = max(0, min(originX, imageSize.width - cropSize.width))
        originY = max(0, min(originY, imageSize.height - cropSize.height))

        // CGImage coordinates origin is top-left, but NSImage coordinate is bottom-left; ImageProcessor expects CG coords where origin is (0,0) at top-left.
        // We'll convert by flipping Y
        let cropRect = CGRect(x: originX, y: imageSize.height - originY - cropSize.height, width: cropSize.width, height: cropSize.height)

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK, let dir = panel.url {
            do {
                let base = "crop"
                let saved = try ImageProcessor.cropAndSplitAndSave(image: img, cropRectInImagePixels: cropRect, cols: max(1, cols), rows: max(1, rows), directory: dir, baseName: base)
                print("Saved: \(saved)")
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

// Overlay view that shows selection rectangle and handles dragging
struct SelectionOverlay: View {
    let imageSize: CGSize
    let dispOrigin: CGPoint
    let dispSize: CGSize
    @Binding var selectionCenter: CGPoint // in image pixels
    var cropSizeProvider: () -> CGSize // in image pixels

    @State private var dragStartCenter: CGPoint = .zero

    var body: some View {
        GeometryReader { _ in
            let cropSize = cropSizeProvider()
            let scale = dispSize.width / imageSize.width
            let selDispSize = CGSize(width: cropSize.width * scale, height: cropSize.height * scale)
            let selCenterDisp = CGPoint(x: dispOrigin.x + (selectionCenter.x * scale), y: dispOrigin.y + ( (imageSize.height - selectionCenter.y) * scale))

            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: selDispSize.width, height: selDispSize.height)
                .position(x: selCenterDisp.x, y: selCenterDisp.y)
                .background(Color.black.opacity(0.001))
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            let dx = v.translation.width / scale
                            let dy = -v.translation.height / scale // flip
                            var newCenter = CGPoint(x: dragStartCenter.x + dx, y: dragStartCenter.y + dy)
                            // clamp within image
                            newCenter.x = max(cropSize.width/2, min(newCenter.x, imageSize.width - cropSize.width/2))
                            newCenter.y = max(cropSize.height/2, min(newCenter.y, imageSize.height - cropSize.height/2))
                            selectionCenter = newCenter
                        }
                        .onEnded { _ in }
                        .onChanged { _ in }
                        .onEnded { _ in }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in }
                        .onEnded { _ in }
                )
                .onAppear {
                    // ensure selectionCenter is reasonable
                    if selectionCenter == .zero {
                        selectionCenter = CGPoint(x: imageSize.width/2, y: imageSize.height/2)
                    }
                }
                .onTapGesture {}
                .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
                    if pressing { dragStartCenter = selectionCenter }
                }, perform: {})
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
