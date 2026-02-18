macOS Crop & Split (SwiftUI)

설명
- macOS용 SwiftUI 기반 샘플 앱입니다.
- 이미지를 로드하고, 원하는 크기/비율로 크롭한 다음 균등 분할하여 저장할 수 있습니다.

설치 및 실행
1. Tuist 워크스페이스 사용(권장):

```bash
# tuist가 설치되어 있지 않다면 설치
curl -Ls https://install.tuist.io | bash

cd /Users/hyeongkyulee/work/crop-and-split-image
tuist generate
open CropSplitWorkspace.xcworkspace
```

2. 또는 Xcode에 파일을 직접 추가:

 - Xcode에서 새 macOS SwiftUI 앱을 생성한 다음, `Sources/CropSplitApp/`에 있는 소스들을 프로젝트에 추가합니다.
 - `CropSplitApp.swift`가 앱 진입점입니다.

간단 사용법
- `Load Image` 버튼 또는 이미지 영역에 파일을 드래그하여 이미지를 로드합니다.
- 원본 이미지 크기가 표시됩니다.
- 크롭 크기를 숫자로 입력하거나 `Lock Aspect`를 켜고 프리셋을 선택하세요.
- 프리셋은 크롭 비율과 기본 분할(cols×rows)을 함께 적용합니다.
   - 예: `Instagram Two Across (8:5)`는 cols=2, rows=1을 적용합니다.
- 이미지에서 빨간 선택 박스를 드래그하거나 모서리 핸들로 크기를 조정/이동할 수 있습니다.
- `Crop & Save`를 누르면 저장 폴더를 선택하고, 선택한 크롭을 지정한 분할수로 나누어 저장합니다.

파일명 규칙
- 저장 파일명은 원본 파일명이 `photo.jpg` 였다면 `photo_crop_1.png`, `photo_crop_2.png`, ... 형식으로 저장됩니다.

프리셋(기본)
- Instagram Vertical (4:5) — cols=1, rows=1
- Instagram Square (1:1) — cols=1, rows=1
- Instagram Two Across (8:5) — cols=2, rows=1
- Instagram Three Across (12:5) — cols=3, rows=1
- Instagram Four Across (16:5) — cols=4, rows=1

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