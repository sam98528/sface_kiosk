# EDSDK 설정 가이드

Canon EDSDK를 Flutter Windows 프로젝트에 통합하기 위한 파일 배치 가이드입니다.

## 📁 디렉토리 구조

```
sface_kiosk/
└── windows/
    ├── include/          # EDSDK 헤더 파일들
    │   ├── EDSDK.h
    │   ├── EDSDKTypes.h
    │   └── EDSDKErrors.h
    ├── libs/            # EDSDK DLL 파일들 (런타임)
    │   ├── EDSDK.dll
    │   ├── EdsImage.dll
    │   └── MLib.dll
    └── libs/x64/        # EDSDK 라이브러리 파일들 (링킹)
        ├── EDSDK.lib
        └── EdsImage.lib
```

## 🚀 설정 단계

### 1단계: 디렉토리 생성
이미 생성되었습니다:
- `windows/include/` - 헤더 파일용
- `windows/libs/` - DLL 파일용
- `windows/libs/x64/` - 라이브러리 파일용

### 2단계: EDSDK 파일 복사

Canon EDSDK를 다운로드한 후, 다음 파일들을 복사하세요:

#### 헤더 파일 복사:
```
EDSDK/Header/ → windows/include/
- EDSDK.h
- EDSDKTypes.h
- EDSDKErrors.h
```

#### DLL 파일 복사:
```
EDSDK/DLL/ → windows/libs/
- EDSDK.dll
- EdsImage.dll
- MLib.dll
```

#### 라이브러리 파일 복사:
```
EDSDK/Library/ → windows/libs/x64/
- EDSDK.lib
- EdsImage.lib
```

### 3단계: CMakeLists.txt 확인
`windows/CMakeLists.txt`에 EDSDK 설정이 이미 추가되었습니다:
- 헤더 파일 경로 포함
- 라이브러리 링킹 설정
- 런타임 DLL 복사 설정

### 4단계: 빌드 테스트
```bash
flutter build windows
```

## ⚠️ 주의사항

1. **64비트 빌드**: 프로젝트는 64비트로 빌드되므로 x64 버전의 라이브러리를 사용해야 합니다.

2. **Canon SDK 라이센스**: EDSDK 사용 시 Canon의 라이센스 조건을 준수해야 합니다.

3. **파일 경로**: DLL 파일들은 실행 파일과 같은 디렉토리에 있어야 합니다.

4. **선택사항**: `OPTIONAL` 플래그로 인해 EDSDK 파일이 없어도 빌드는 가능하지만, 카메라 기능은 작동하지 않습니다.

## 🔧 문제해결

### 빌드 오류 시:
1. 파일 경로가 올바른지 확인
2. 64비트 라이브러리 버전인지 확인
3. Visual Studio 2019/2022가 설치되어 있는지 확인

### 런타임 오류 시:
1. DLL 파일들이 실행 파일 디렉토리에 있는지 확인
2. Canon EOS Utility가 실행 중이 아닌지 확인 (포트 충돌)
3. 카메라가 USB로 연결되고 ON 상태인지 확인

## 📝 다음 단계

1. Native 플러그인 C++ 코드 작성
2. MethodChannel을 통한 Flutter-Native 통신 설정
3. 카메라 연결 및 세션 관리 구현
4. 라이브 뷰 스트리밍 구현