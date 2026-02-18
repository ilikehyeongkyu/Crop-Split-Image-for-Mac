import Cocoa

// 이미지 처리 유틸리티: NSImage <-> CGImage 변환, 크롭, 분할, 파일 저장 기능을 제공합니다.
struct ImageProcessor {
    // NSImage에서 CGImage를 얻어옵니다.
    static func cgImage(from ns: NSImage) -> CGImage? {
        var rect = NSRect(origin: .zero, size: ns.size)
        return ns.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    // 주어진 이미지에서 픽셀 좌표 rect로 크롭한 NSImage를 반환합니다.
    static func crop(nsImage: NSImage, rect: CGRect) -> NSImage? {
        guard let cg = cgImage(from: nsImage) else { return nil }
        guard let cropped = cg.cropping(to: rect) else { return nil }
        let size = CGSize(width: cropped.width, height: cropped.height)
        return NSImage(cgImage: cropped, size: size)
    }

    // 이미지를 cols x rows로 균등 분할하여 각 조각을 NSImage 배열로 반환합니다.
    static func split(nsImage: NSImage, cols: Int, rows: Int) -> [NSImage] {
        guard cols >= 1, rows >= 1 else { return [nsImage] }
        guard let cg = cgImage(from: nsImage) else { return [nsImage] }
        let w = cg.width
        let h = cg.height
        let tileW = w / cols
        let tileH = h / rows
        var imgs: [NSImage] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let x = c * tileW
                let y = r * tileH
                let cropRect = CGRect(x: x, y: y, width: (c == cols-1) ? (w - tileW*(cols-1)) : tileW, height: (r == rows-1) ? (h - tileH*(rows-1)) : tileH)
                if let piece = cg.cropping(to: cropRect) {
                    imgs.append(NSImage(cgImage: piece, size: CGSize(width: piece.width, height: piece.height)))
                }
            }
        }
        return imgs
    }

    // NSImage 배열을 PNG로 변환해 지정 디렉터리에 baseName_1.png, baseName_2.png... 형식으로 저장하고 URL 배열을 반환합니다.
    static func save(nsImages: [NSImage], directory: URL, baseName: String) throws -> [URL] {
        var urls: [URL] = []
        for (i, img) in nsImages.enumerated() {
            guard let data = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: data),
                  let png = rep.representation(using: .png, properties: [:]) else { continue }
            let url = directory.appendingPathComponent("\(baseName)_\(i+1).png")
            try png.write(to: url)
            urls.append(url)
        }
        return urls
    }

    // 주어진 이미지와 크롭 사각형을 기준으로 크롭 → 분할 → 저장을 수행하고 저장된 파일 URL 목록을 반환합니다.
    static func cropAndSplitAndSave(image: NSImage, cropRectInImagePixels: CGRect, cols: Int, rows: Int, directory: URL, baseName: String) throws -> [URL] {
        guard let cropped = crop(nsImage: image, rect: cropRectInImagePixels) else { return [] }
        let parts = split(nsImage: cropped, cols: cols, rows: rows)
        let saved = try save(nsImages: parts, directory: directory, baseName: baseName)
        return saved
    }
}
