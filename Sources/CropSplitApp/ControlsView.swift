import SwiftUI
import AppKit

// 프리셋 모델: 크롭 비율과 기본 분할(cols, rows)을 함께 보관합니다.
struct Preset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ratio: CGSize
    let cols: Int
    let rows: Int
}

// 상단 컨트롤 뷰: 이미지 로드, 크롭 사이즈 입력, 프리셋 선택, 분할 설정 및 저장 버튼을 포함합니다.
struct ControlsView: View {
    @Binding var cropWidthText: String
    @Binding var cropHeightText: String
    @Binding var lockAspect: Bool
    @Binding var selectedPreset: Preset?
    @Binding var cols: Int
    @Binding var rows: Int
    let imageSize: CGSize

    var loadImage: () -> Void
    var applyPreset: (Preset) -> Void
    var cropAndSave: () -> Void

    // 프리셋은 부모 뷰(ContentView)에서 전달됩니다.
    let presets: [Preset]

    var body: some View {
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
                    // Picker selection을 배열 인덱스(Int)로 처리하여 태그/비교 문제를 방지합니다.
                    let selectionBinding = Binding<Int?>(
                        get: { selectedPreset.flatMap { p in presets.firstIndex(where: { $0.id == p.id }) } },
                        set: { newIndex in
                            if let idx = newIndex, presets.indices.contains(idx) {
                                let p = presets[idx]
                                selectedPreset = p
                                lockAspect = true
                                applyPreset(p)
                            } else {
                                selectedPreset = nil
                            }
                        }
                    )

                    Picker("Presets:", selection: selectionBinding) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(presets.indices, id: \.self) { idx in
                            let p = presets[idx]
                            Text(p.name).tag(Optional(idx))
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
    }
}

// Preview용 더미 뷰입니다.
#if DEBUG
struct ControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ControlsView(presets: [
            Preset(name: "Instagram Vertical (4:5)", ratio: CGSize(width: 4, height: 5), cols: 1, rows: 1)
        ], cropWidthText: .constant("800"), cropHeightText: .constant("600"), lockAspect: .constant(false), selectedPreset: .constant(nil), cols: .constant(1), rows: .constant(1), imageSize: CGSize(width: 800, height: 600), loadImage: {}, applyPreset: { _ in }, cropAndSave: {})
    }
}
#endif
