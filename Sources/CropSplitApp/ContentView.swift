import SwiftUI
import AppKit

struct Preset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ratio: CGSize
    let cols: Int
    let rows: Int
}

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

    let presets: [Preset] = [
        Preset(name: "Instagram Vertical (4:5)", ratio: CGSize(width: 4, height: 5), cols: 1, rows: 1),
        Preset(name: "Instagram Square (1:1)", ratio: CGSize(width: 1, height: 1), cols: 1, rows: 1),
        Preset(name: "Instagram Two Across (8:5)", ratio: CGSize(width: 8, height: 5), cols: 2, rows: 1),
        Preset(name: "Instagram Three Across (12:5)", ratio: CGSize(width: 12, height: 5), cols: 3, rows: 1),
        Preset(name: "Instagram Four Across (16:5)", ratio: CGSize(width: 16, height: 5), cols: 4, rows: 1)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button("Load Image") { loadImage() }
                    Text("Original: \(Int(imageSize.width)) x \(Int(imageSize.height))")
                        .frame(minWidth: 160, alignment: .leading)
                    HStack(spacing: 8) {
                        Text("Crop Size:")
                        TextField("width", text: $cropWidthText)
                            .frame(width: 80)
                        Text("x")
                        TextField("height", text: $cropHeightText)
                            .frame(width: 80)
                        Toggle("Lock Aspect", isOn: $lockAspect)
                            .toggleStyle(CheckboxToggleStyle())
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Picker("Presets:", selection: Binding(get: { selectedPreset }, set: { new in
                            selectedPreset = new
                            if let p = new {
                                lockAspect = true
                                applyPreset(p)
                            }
                        })) {
                            Text("None").tag(Optional<Preset>.none)
                            ForEach(presets) { p in
                                Text(p.name).tag(Optional(p))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Text("Split:")
                    Stepper("Cols: \(cols)", value: $cols, in: 1...10)
                    Stepper("Rows: \(rows)", value: $rows, in: 1...10)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Button("Crop & Save") { cropAndSave() }
                    Spacer()
                }
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
        .onChange(of: nsImage) { new in
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
        .onChange(of: cropWidthText) { _ in
            selectionSize = computedCropSizeInImagePixels()
        }
        .onChange(of: cropHeightText) { _ in
            selectionSize = computedCropSizeInImagePixels()
        }
    }

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

    private func loadImage() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic", "tiff"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            nsImage = img
            imageURL = url
        }
    }

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

struct SelectionOverlay: View {
    let imageSize: CGSize
    let dispOrigin: CGPoint
    let dispSize: CGSize
    @Binding var selectionCenter: CGPoint
    @Binding var selectionSize: CGSize
    @Binding var lockAspect: Bool
    let cols: Int
    let rows: Int
    var cropSizeProvider: () -> CGSize
    var onChange: ((CGSize, CGPoint) -> Void)? = nil

    @State private var dragStartCenter: CGPoint = .zero
    @State private var dragStartSize: CGSize = .zero
    @State private var isDragging: Bool = false

    let handleSize: CGFloat = 10

    var body: some View {
        GeometryReader { _ in
            // use current interactive selectionSize if available, otherwise provider fallback
            let cropSize = (selectionSize.width > 0 && selectionSize.height > 0) ? selectionSize : cropSizeProvider()
            let scale = dispSize.width / imageSize.width
            let selDispSize = CGSize(width: cropSize.width * scale, height: cropSize.height * scale)
            let selCenterDisp = CGPoint(x: dispOrigin.x + (selectionCenter.x * scale), y: dispOrigin.y + ((imageSize.height - selectionCenter.y) * scale))

            // Main selection rectangle
            ZStack {
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: selDispSize.width, height: selDispSize.height)
                    .position(x: selCenterDisp.x, y: selCenterDisp.y)
                    .contentShape(Rectangle())

                // Dashed grid showing splits inside selection (drawn in a frame matching the selection)
                ZStack {
                    if cols > 1 {
                        ForEach(1..<(cols), id: \.self) { i in
                            Path { p in
                                let x = CGFloat(i) * selDispSize.width / CGFloat(cols)
                                p.move(to: CGPoint(x: x, y: 0))
                                p.addLine(to: CGPoint(x: x, y: selDispSize.height))
                            }
                            .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1, dash: [6,4]))
                        }
                    }
                    if rows > 1 {
                        ForEach(1..<(rows), id: \.self) { j in
                            Path { p in
                                let y = CGFloat(j) * selDispSize.height / CGFloat(rows)
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: selDispSize.width, y: y))
                            }
                            .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1, dash: [6,4]))
                        }
                    }
                }
                .frame(width: selDispSize.width, height: selDispSize.height)
                .position(x: selCenterDisp.x, y: selCenterDisp.y)
            }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            if !isDragging {
                                dragStartCenter = selectionCenter
                                isDragging = true
                            }
                            let dx = v.translation.width / scale
                            let dy = -v.translation.height / scale
                            var newCenter = CGPoint(x: dragStartCenter.x + dx, y: dragStartCenter.y + dy)
                            // clamp within image using current cropSize
                            newCenter.x = max(cropSize.width/2, min(newCenter.x, imageSize.width - cropSize.width/2))
                            newCenter.y = max(cropSize.height/2, min(newCenter.y, imageSize.height - cropSize.height/2))
                            selectionCenter = newCenter
                            onChange?(cropSize, newCenter)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )

            // Corner handles: top-left, top-right, bottom-left, bottom-right
            Group {
                handleView(at: CGPoint(x: selCenterDisp.x - selDispSize.width/2, y: selCenterDisp.y - selDispSize.height/2)) // top-left
                    .gesture(resizeGesture(corner: .topLeft, scale: scale, currentSize: cropSize))

                handleView(at: CGPoint(x: selCenterDisp.x + selDispSize.width/2, y: selCenterDisp.y - selDispSize.height/2)) // top-right
                    .gesture(resizeGesture(corner: .topRight, scale: scale, currentSize: cropSize))

                handleView(at: CGPoint(x: selCenterDisp.x - selDispSize.width/2, y: selCenterDisp.y + selDispSize.height/2)) // bottom-left
                    .gesture(resizeGesture(corner: .bottomLeft, scale: scale, currentSize: cropSize))

                handleView(at: CGPoint(x: selCenterDisp.x + selDispSize.width/2, y: selCenterDisp.y + selDispSize.height/2)) // bottom-right
                    .gesture(resizeGesture(corner: .bottomRight, scale: scale, currentSize: cropSize))
            }
        }
    }

    // small circular handle view
    @ViewBuilder
    private func handleView(at point: CGPoint) -> some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.red, lineWidth: 1))
            .frame(width: handleSize, height: handleSize)
            .position(x: point.x, y: point.y)
    }

    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

    private func resizeGesture(corner: Corner, scale: CGFloat, currentSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !isDragging {
                    dragStartCenter = selectionCenter
                    dragStartSize = currentSize
                    isDragging = true
                }
                let deltaX = v.translation.width / scale
                let deltaY = -v.translation.height / scale

                // compute box corners in image coords
                let halfW = dragStartSize.width / 2
                let halfH = dragStartSize.height / 2
                let left = dragStartCenter.x - halfW
                let right = dragStartCenter.x + halfW
                let top = dragStartCenter.y + halfH
                let bottom = dragStartCenter.y - halfH

                var newLeft = left
                var newRight = right
                var newTop = top
                var newBottom = bottom

                switch corner {
                case .topLeft:
                    newLeft = left + deltaX
                    newTop = top + deltaY
                case .topRight:
                    newRight = right + deltaX
                    newTop = top + deltaY
                case .bottomLeft:
                    newLeft = left + deltaX
                    newBottom = bottom + deltaY
                case .bottomRight:
                    newRight = right + deltaX
                    newBottom = bottom + deltaY
                }

                // ensure min size
                var newW = max(1, newRight - newLeft)
                var newH = max(1, newTop - newBottom)

                // apply lock aspect if needed
                if lockAspect {
                    // determine desired ratio
                    let ratio = (selectionSize.width > 0 && selectionSize.height > 0) ? (selectionSize.width / selectionSize.height) : (dragStartSize.width / dragStartSize.height)
                    if newW / newH > ratio {
                        newW = newH * ratio
                    } else {
                        newH = newW / ratio
                    }
                    // adjust left/right/top/bottom to match new sizes while anchoring opposite corner
                    let centerX = (newLeft + newRight) / 2
                    let centerY = (newTop + newBottom) / 2
                    newLeft = centerX - newW/2
                    newRight = centerX + newW/2
                    newTop = centerY + newH/2
                    newBottom = centerY - newH/2
                }

                // clamp within image bounds
                newLeft = max(0, newLeft)
                newRight = min(imageSize.width, newRight)
                newTop = min(imageSize.height, newTop)
                newBottom = max(0, newBottom)

                newW = max(1, newRight - newLeft)
                newH = max(1, newTop - newBottom)

                let newCenter = CGPoint(x: (newLeft + newRight)/2, y: (newTop + newBottom)/2)
                let newSize = CGSize(width: newW, height: newH)

                selectionCenter = newCenter
                selectionSize = newSize
                onChange?(newSize, newCenter)
            }
            .onEnded { _ in
                isDragging = false
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
