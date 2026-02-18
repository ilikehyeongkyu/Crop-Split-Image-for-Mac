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

    let presets: [Preset] = [
        Preset(name: "Instagram Vertical (4:5)", ratio: CGSize(width: 4, height: 5), cols: 1, rows: 1),
        Preset(name: "Instagram Square (1:1)", ratio: CGSize(width: 1, height: 1), cols: 1, rows: 1),
        Preset(name: "Instagram Two Across (8:5)", ratio: CGSize(width: 8, height: 5), cols: 2, rows: 1),
        Preset(name: "Instagram Three Across (12:5)", ratio: CGSize(width: 12, height: 5), cols: 3, rows: 1),
        Preset(name: "Instagram Four Across (16:5)", ratio: CGSize(width: 16, height: 5), cols: 4, rows: 1)
    ]

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
    }
}

// Preview용 더미 뷰입니다.
#if DEBUG
struct ControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ControlsView(cropWidthText: .constant("800"), cropHeightText: .constant("600"), lockAspect: .constant(false), selectedPreset: .constant(nil), cols: .constant(1), rows: .constant(1), imageSize: CGSize(width: 800, height: 600), loadImage: {}, applyPreset: { _ in }, cropAndSave: {})
    }
}
#endif
