Flutter + Dart 프로젝트를 시작하련다.
나의 개발 환경은 아래와 같아.

D:\User\Private\Projects\ai_english> dart --version
Dart SDK version: 3.2.3 (stable) (Tue Dec 5 17:58:33 2023 +0000) on "windows_x64"
D:\User\Private\Projects\ai_english> flutter --version
Flutter 3.16.5   channel stable    https://github.com/flutter/flutter.git
Framework revision 78666c8dc5 (1 year, 3 months ago) 2023-12-19 16:14:14 -0800
Engine revision 3f3e560236
Tools Dart 3.2.3 • DevTools 2.28.4

이 프로젝트의 Target Device는 Android와 iOS에서 실행 가능한 App을 개발하는 목적이다.
기능은 아래와 같아:

1. Claude AI 음성인식 API를 활용해서 휴대폰으로 영어 대화 연습을 할 수 있는  App.
2. 사용자의 음성을 인식하여 질문(혹은 답변)에 따라 이어지는 대화를 AI가 dynamic하게 생성해서 자연스럽게 영어 회화를 연습할 수 있도록 해.
3. 초기 메뉴 화면에서 주제를 바탕으로한 대화 시나리오(예: 전화예약, 인터뷰, 병원 검진 등)를 선택하면,
    - 사용자의 역할(예: 직원, 손님 등)과 시나리오를 더욱 상세하게 정의할 수 있는 키워드(레스토랑, 학교, 취업, 시민권 등)를 입력 받는다.
    - AI에게 주어진 역할에 따라 적절한 답변(혹은 질문)을 dynamic 하게 생성해서 대화를 이어가도록 해.
    - 대화중에 사용자가 어색한 문장(혹은 발음)을 사용하는 경우, 적절한 문장(혹은 발음)을 추천해 주는 기능도 포함되어야 해.
    - 대화 연습을 시작하기 전에 사용자가 연습하고 싶은 문장들을 입력 가능하도록 해서, 해당 문장들을 사용자가 말하게끔 유도하는 기능이 있으면 좋겠어.
4. 주제를 바탕으로 한 대화 시나리오 외에도, QnA 대화 기능이 있어서 묻고 답하기 형식의 대화를 진행하는 기능도 있어야 해.
    - QnA 대화 기능은 문답집을 바탕으로 진행되는데, 초기 메뉴화면에서 문답집 목록 중 하나를 선택하도록 해야 하고,
    - 문답집에는 복수개의 질문과 각 질문에 대한 복수개의 가능한 답변이 포함되어 있어.
    - AI는 이 문답집을 바탕으로 질문을 하고, 사용자의 답변을 평가해야 해.
    - 사용자의 답변이 적절하지 않은 경우, AI는 문답집에 서술된 적절한 답변들을 제시해 준 후, 다음 질문으로 넘어가도록 해.
5. 모든 대화는 history로 기록되어 대화 종료 이후에 리뷰 가능해야 하고, 이 기록을 바탕으로 반복 연습할 수 있는 기능도 있으면 좋겠어.


이 프로젝트를 설명하는 몇 가지 파일들을 첨부했다.
- README.md: 이 파일
- pubspec.yaml: Flutter 프로젝트의 설정 파일
- lib/main.dart: Flutter 프로젝트의 시작점
- project-structure.txt: 프로젝트 디렉토리 구조
- US_Citizenship_100q.pdf: 문답집 원시자료 파일 (예시)