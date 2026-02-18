macOS Crop & Split (SwiftUI)

설명
- macOS용 SwiftUI 기반 샘플 앱입니다.
- 이미지를 로드하고, 원하는 크기/비율로 크롭한 다음 균등 분할하여 저장할 수 있습니다.

설치 및 실행
1. Xcode에서 "File > New > Project..." 를 선택합니다.
2. Template에서 "App"을 선택하고, Interface는 "SwiftUI", Language는 "Swift", Platform은 "macOS"로 설정합니다.
3. 생성된 프로젝트에서 `ContentView.swift`와 `App` 파일을 삭제하거나 교체한 뒤, 아래 파일들을 프로젝트에 추가하세요:
   - `CropSplitApp.swift` (앱 진입점)
   - `ContentView.swift` (메인 UI)
   - `ImageProcessor.swift` (이미지 처리 유틸)
4. 빌드하여 실행하세요.

간단 사용법
- "Load Image" 버튼으로 PNG/JPEG 파일을 엽니다.
- 원본 이미지 크기가 플레이스홀더로 표시됩니다.
- 크롭 크기를 입력하거나 비율 고정을 활성화하고 프리셋을 선택하세요.
- 마우스로 선택 영역을 드래그하여 위치를 조정하세요.
- "Crop & Save"를 누르면 저장할 폴더를 선택하고, 분할 개수(가로/세로)를 지정하면 파일들이 저장됩니다.

비율 프리셋
- 인스타그램 세로: 4:5
- 정사각형: 1:1
- 인스타그램 세로를 가로로 두장 이어붙인 비율: 8:5 (4:5 두 장을 가로로 붙인 비율)

참고
- 이 샘플은 실제 Xcode 프로젝트 내에 파일을 복사/붙여넣어 바로 사용하도록 설계되었습니다.
- 필요하면 `.xcodeproj` 자동 생성 및 더 상세한 빌드 설정을 도와드릴게요.

Tuist로 프로젝트 생성
- Tuist 설치 (한번만):

```bash
curl -Ls https://install.tuist.io | bash
```

- 매니페스트가 있는 폴더로 이동 후 워크스페이스 생성:

```bash
cd /Users/hyeongkyulee/work/crop-and-split-image
tuist generate
open CropSplitWorkspace.xcworkspace
```

위 작업은 `Project.swift`와 `Workspace.swift` 매니페스트를 사용하여 Xcode 워크스페이스를 생성합니다. 소스는 `Sources/CropSplitApp/`에 있습니다.