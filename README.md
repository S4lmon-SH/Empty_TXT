# Empty_TXT

macOS Finder에서 **폴더 안 빈 공간을 우클릭해 빈 TXT 파일을 만드는 작은 도구**입니다.

**빈 공간 우클릭 → 빈 TXT 만들기**를 선택하면 `새 텍스트 파일.txt`가 생성되고 선택됩니다. 내용을 넣지 않은 0바이트 파일이며, 같은 이름이 있으면 `새 텍스트 파일 2.txt`처럼 번호를 붙입니다. 기존 파일은 덮어쓰지 않습니다.

## 설치

필요한 것: macOS 13 이상을 대상으로 빌드할 수 있는 Mac, Python 3.9 이상, Apple Command Line Tools. 빌드 결과는 빌드한 Mac의 CPU 아키텍처용입니다. 다른 macOS 버전과 Intel Mac에서는 별도 검증이 필요합니다.

```bash
git clone https://github.com/S4lmon-SH/Empty_TXT.git
cd Empty_TXT
python3 build.py --output ./build
```

1. 생성된 `build/Blank TXT.app`을 **응용 프로그램** 폴더로 옮깁니다.
2. 옮긴 앱을 한 번 실행합니다. 앱이 Finder 확장을 등록하고 활성화합니다.
3. Finder에서 폴더를 열고 **빈 공간 우클릭 → 빈 TXT 만들기**를 선택합니다.

Command Line Tools가 없다면 먼저 `xcode-select --install`로 설치합니다. 이 저장소는 직접 빌드하는 소스 배포이며, Apple 배포용 서명·공증을 받은 설치 파일은 제공하지 않습니다.

## 폴더 아이콘 우클릭도 사용하려면

`extras/빈 TXT 만들기.workflow`는 선택 사항인 Automator 빠른 동작입니다. Finder에서 더블클릭해 설치하면 **폴더 아이콘 우클릭 → 빠른 동작 → 빈 TXT 만들기**로 사용할 수 있습니다.

빈 공간용 Finder 확장과 폴더 아이콘용 빠른 동작은 각각 독립적으로 사용할 수 있습니다.

## 어떻게 동작하나요?

Automator 빠른 동작만으로는 Finder 빈 공간의 우클릭 메뉴에 항목을 추가할 수 없어, Apple의 [Finder Sync](https://developer.apple.com/documentation/findersync) 확장을 사용했습니다.

```text
폴더 안 빈 공간 우클릭
  → Finder 확장이 메뉴와 아이콘 표시
  → 메뉴 선택 시 현재 폴더 위치를 생성 담당 앱에 전달
  → 앱이 빈 TXT 파일 생성 후 종료
```

아이콘은 메뉴를 열 때 현재 테마의 글자 색에 맞춰 그립니다. 파일 생성에는 ‘새 파일만 만들기’ 옵션을 사용해, 이름이 겹치거나 같은 이름의 심볼릭 링크가 있어도 기존 대상을 덮어쓰지 않습니다.

| 파일 | 역할 |
| --- | --- |
| `src/BlankTXTFinder.m` | 빈 공간 우클릭 메뉴와 아이콘 |
| `src/BlankTXT.m` | 빈 파일 생성, 생성 파일 선택, 확장 재활성화 |
| `build.py` | 앱 구성, 컴파일, 로컬 서명 및 서명 검증 |
| `extras/빈 TXT 만들기.workflow` | 폴더 아이콘용 빠른 동작 |

## 시스템에 미치는 영향

| 항목 | 내용 |
| --- | --- |
| 시스템 변경 | 앱과 Finder 확장 등록이 추가됩니다. macOS/Finder 원본 파일은 수정하지 않습니다. |
| 실행 과정 | Finder 확장 프로세스는 대기할 수 있으며, 생성 담당 앱은 메뉴를 실행할 때 열렸다가 종료합니다. |
| 폴더 접근 | 어느 폴더에서든 메뉴를 표시하도록 루트 경로를 등록하지만, 폴더를 순회하거나 기존 문서 내용을 읽는 코드는 없습니다. |
| 권한 | 메뉴 확장은 샌드박스 안에서, 생성 담당 앱은 일반 사용자 권한으로 실행됩니다. 관리자 권한 상승이나 전체 디스크 접근 권한을 부여하는 코드는 없습니다. |
| 네트워크 | 인터넷 통신, 정보 수집, 자동 업데이트 기능이 없습니다. |
| 자동 실행 | 별도 로그인 항목, 예약 작업, LaunchAgent를 추가하지 않습니다. Finder 확장은 macOS가 관리합니다. |

개발 환경에서 확인한 순간 측정값은 확장 프로세스 2개, CPU 각각 0%, RSS 표시 합계 약 53MiB였습니다. RSS에는 공유 메모리가 중복 포함될 수 있고, 실제 추가 점유량이나 다른 Mac의 사용량을 보장하는 수치는 아닙니다.

## 메뉴가 안 보일 때

응용 프로그램의 `Blank TXT.app`을 다시 실행하면 확장을 재등록하고 활성화합니다. 시험용 앱이 여러 위치에 중복으로 남지 않도록 정리하고, 열려 있는 우클릭 메뉴도 닫았다가 다시 열어 보세요.

## 제거

터미널에서 확장을 끄고 등록을 해제합니다.

```bash
pluginkit -e ignore -i local.codex.blanktxt.finder
pluginkit -r "/Applications/Blank TXT.app/Contents/PlugIns/BlankTXTFinder.appex"
```

그다음 응용 프로그램의 `Blank TXT.app`을 휴지통으로 옮깁니다. 선택 사항인 빠른 동작도 설치했다면 `~/Library/Services/빈 TXT 만들기.workflow`를 함께 제거합니다. 이미 생성한 TXT 파일은 그대로 남습니다.

## 확인한 동작

macOS 26.6.2 / Apple Silicon 환경에서 빌드·서명 검증, 0바이트 파일 생성, 중복 이름 처리, 기존 파일과 심볼릭 링크 보호, 실제 Finder 빈 공간 메뉴 실행, 다크 모드 아이콘 표시를 확인했습니다. 모든 macOS 버전과 환경에서의 동작을 검증한 것은 아닙니다.
