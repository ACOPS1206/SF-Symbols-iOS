# SymbolShelf

SF Symbols를 검색하고 미리 본 뒤 PNG, 호환 SVG, ZIP으로 내보내는 SwiftUI iOS 앱입니다.

## 요구 사항

- Xcode 26 이상
- iOS 18 이상
- Liquid Glass는 iOS 26 이상에서 활성화되며, iOS 18–25에서는 Material UI로 대체됩니다.

## 실행

1. `SymbolShelf.xcodeproj`를 Xcode에서 엽니다.
2. Signing & Capabilities에서 Team을 선택합니다.
3. iPhone 시뮬레이터나 실제 기기에서 실행합니다.

## GitHub Actions

`main` 브랜치에 푸시하거나 Actions 화면에서 수동 실행하면 서명되지 않은
`SymbolShelf-unsigned.ipa` 아티팩트를 만듭니다. 설치 전 개인 인증서로 별도
서명해야 합니다.

## 내보내기 형식

- PNG: 128, 256, 512, 1024px
- SVG: iOS 공개 API의 한계로 PNG를 포함한 호환 SVG입니다. 원본 벡터 경로는 포함하지 않습니다.
- ZIP: 선택한 아이콘의 PNG/SVG 파일과 `manifest.json`을 저장합니다.

SF Symbols의 사용과 배포는 Apple의 라이선스 및 플랫폼 사용 지침을 따라야 합니다.
