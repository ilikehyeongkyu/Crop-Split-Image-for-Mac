import SwiftUI

// 선택 오버레이: 이미지 위에 크롭 영역을 표시하고 이동/리사이즈 동작을 처리합니다.
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

    // 모서리 핸들 뷰: 드래그로 크롭 박스 크기를 조정하는 원형 핸들입니다.
    @ViewBuilder
    private func handleView(at point: CGPoint) -> some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.red, lineWidth: 1))
            .frame(width: handleSize, height: handleSize)
            .position(x: point.x, y: point.y)
    }

    // 크기 조정 시 사용할 코너 열거형
    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

    // 특정 코너를 드래그할 때의 리사이즈 제스처를 반환합니다.
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
