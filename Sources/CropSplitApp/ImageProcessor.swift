import Cocoa

struct ImageProcessor {
    static func cgImage(from ns: NSImage) -> CGImage? {
        var rect = NSRect(origin: .zero, size: ns.size)
        return ns.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    static func crop(nsImage: NSImage, rect: CGRect) -> NSImage? {
        guard let cg = cgImage(from: nsImage) else { return nil }
        guard let cropped = cg.cropping(to: rect) else { return nil }
        let size = CGSize(width: cropped.width, height: cropped.height)
        return NSImage(cgImage: cropped, size: size)
    }

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

    static func cropAndSplitAndSave(image: NSImage, cropRectInImagePixels: CGRect, cols: Int, rows: Int, directory: URL, baseName: String) throws -> [URL] {
        guard let cropped = crop(nsImage: image, rect: cropRectInImagePixels) else { return [] }
        let parts = split(nsImage: cropped, cols: cols, rows: rows)
        let saved = try save(nsImages: parts, directory: directory, baseName: baseName)
        return saved
    }
}
