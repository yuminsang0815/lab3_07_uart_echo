# 실험 후 레포트: PC-FPGA UART 에코 통신

작성일 2026-10-07.

[실험 전 레포트](../pre/07_uart_echo.md) · [해시·입력 기록](../../build/sim/result.json)

## Vivado GUI 과정과 사전 결과 비교

v2.0.2 템플릿 환경에서 Vivado 2026.1 GUI의 New Project를 실행하여 `lab3_uart_echo` 프로젝트를 생성했습니다. 타깃 부품은 Spartan-7 `xc7s75fgga484-1`입니다.

RTL 설계 파일 `src/uart.v`와 `src/lab3_uart_echo.v`를 Design Sources로 등록하고, 기능 검증용 테스트벤치 `sim/tb_uart_echo.sv`를 Simulation Sources에, 제약 파일 `constraints/lab3_uart_echo.xdc`를 Constraints에 추가했습니다. 이때 Copy sources into project 옵션을 해제하여 VS Code 작업 폴더의 원본 파일을 직접 참조하도록 설정했습니다.

Project Summary에서 설계 최상위(Design Top)는 `lab3_uart_echo`로, 시뮬레이션 최상위(Simulation Top)는 `tb_uart_echo`로 분리 지정했습니다.

Run Simulation → Run Behavioral Simulation을 실행하여 실제 GUI 시뮬레이션 Tcl Console에서 `LAB3_UART_ECHO_PASS checks=3` 출력과 9910 ns($finish called at 9910000 ps) 정상 종료를 확인했습니다. VS Code(Icarus Verilog/VaporView)의 사전 시뮬레이션 결과와 비교했을 때, 0x41('A'), 0x5A('Z'), 0x0A('\n') 3개 바이트에 대한 Start 비트 검출, LSB-first 데이터 래치, 송신 에코 직렬 출력, LED 값 갱신 및 framing error 부재 검증 결과가 100% 동일함을 대조했습니다.

## 합성·구현·bit

Flow Navigator에서 Run Synthesis → Run Implementation → Generate Bitstream을 순차 실행하였으며, Design Runs 패널에서 `synth_design Complete!` 및 `write_bitstream Complete!` 상태를 확인했습니다. GUI 빌드 로그를 보관했습니다.

* **생성 파일**: `vivado/lab3_uart_echo.runs/impl_1/lab3_uart_echo.bit`
* **배포 파일**: lab3_uart_echo.bit (SHA-256 해시값 기록 완료)
* **핀 배치 확인**: Elaborated Design 및 Implemented Design의 I/O Ports 창에서 주 클록(`clk_50mhz`=B6), 리셋(`rst_p`=K4), UART 수신(`uart_rxd`=C6), UART 송신(`uart_txd`=F6), 출력 LED 8핀(`led[7:0]`=L4, M4, M2, N7, M7, M3, M1, N5)이 XDC 명세대로 `LVCMOS33` 규격과 지정 핀에 올바르게 할당되었음을 확인했습니다.

### 타이밍 및 경고(Warning) 분석

1. **내부 클록 타이밍 결과**:
   * 메인 50 MHz 클록(`clk_50mhz`, 주기 20.000 ns) 제약 조건에서 Open Implemented Design → Timing Summary를 확인한 결과, Setup WNS = 14.617 ns, Hold WHS = 0.080 ns, Failing Endpoints = 0개(전체 239개)로 50 MHz 고속 클록 환경의 타이밍 요구 조건을 안정적으로 충족했습니다.
2. **TIMING-18 경고**:
   * 외부 입출력 지연(I/O delay) 제약 누락 관련 경고입니다. 리셋과 비동기 직렬 입력(`uart_rxd`)은 XDC에서 `set_false_path`로 예외 처리하였고, `uart_txd` 및 `led[7:0]` 포트는 외부 비동기 수신기 및 관찰용 표시등으로 전달되므로 타이밍 제약을 추가하지 않아 발생한 정상적인 경고임을 확인했습니다.
3. **DRC 경고 (CFGBVS-1)**:
   * Bank 0의 전압 속성(CFGBVS/CONFIG_VOLTAGE)이 지정되지 않아 발생한 경고입니다. 보드 회로도 규격을 확인한 뒤 임의의 값을 넣지 않았으며, 비트스트림이 정상 생성되었음을 확인했습니다.

## 보드 기록·촬영 상태

Combo II-DLD S75 보드의 USB-to-UART 포트와 PC를 연결하고 장치 관리자에서 할당된 가상 COM 포트를 확인했습니다. Hardware Manager의 Auto Connect를 통해 `xc7s75` 디바이스에 `lab3_uart_echo.bit`를 다운로드하여 실물 동작을 검증했습니다.

PC 터미널 프로그램(Tera Term)을 9600 8N1(Baud rate: 9600, Data: 8 bit, Parity: None, Stop: 1 bit, Flow control: None) 및 Local Echo Off로 설정한 후, 키보드로 문자를 입력하여 에코 수신 문자 및 보드 LED 점등 상태를 실측하고 사진과 영상을 촬영했습니다.

| 순서 | 조작 조건 | PC 입력 문자 / Hex | 기대 에코 반환값 | 기대 LED[7:0] (이진수) | 실측 관찰 결과 | 동작 사진 |
|---|---|---|---|---|---|---|
| 1 | K4 리셋 인가 | - | - | 8'b0000_0000 | LED 전체 소등 유지 | [리셋 초기화](../../evidence/07/board/photos/step1_reset.jpg) |
| 2 | 문자 'A' 입력 | 'A' / 8'h41 | 'A' (8'h41) | 8'b0100_0001 | 터미널에 'A' 즉시 출력, LED에 0x41 점등 | [문자 A 에코](../../evidence/07/board/photos/step2_echo_A.jpg) |
| 3 | 문자 'Z' 입력 | 'Z' / 8'h5A | 'Z' (8'h5A) | 8'b0101_1010 | 터미널에 'Z' 즉시 출력, LED에 0x5A 점등 | [문자 Z 에코](../../evidence/07/board/photos/step3_echo_Z.jpg) |

[UART 에코 통신 보드 시연 영상](../../evidence/07/board/videos/demo.mp4)

* 50 MHz 클록에서 분주비 $\text{DIV} = (50,000,000 + 4,800) / 9,600 = 5,208$을 적용하여 오차율 약 0.006%의 정확한 9600 bps 전송 속도를 구현했기 때문에, 글자 깨짐이나 프레이밍 에러 없이 데이터가 안정적으로 송수신됨을 확인했습니다.
* `uart_rx` 내부의 Start 비트 하강 에지 검출 후 반주기(DIV/2) 뒤 중앙 샘플링 검증 로직을 통해 스위칭 노이즈 글리치를 원천 차단하고, LSB-first 순서로 8비트 데이터가 정확히 복원됨을 검증했습니다.
* Local Echo가 꺼진 상태에서 키보드 입력 시 FPGA를 경유하여 반환된 문자만 화면에 정확히 1회 표시되고, 보드의 `led[7:0]`에 마지막 수신 바이트의 아스키 코드가 2진수로 즉각 반영됨을 영상으로 입증했습니다.

## 결론

50 MHz 단일 클록 도메인에서 비동기 입력 2단 동기화기, Start 비트 중앙 확인 FSM, LSB-first 시프트 수신부(`uart_rx`)와 Stop/Start 프레이밍 송신부(`uart_tx`)를 갖춘 `lab3_uart_echo` 시스템을 구현했습니다.

가속 파라미터를 적용한 VS Code Icarus Verilog 사전 시뮬레이션과 Vivado GUI XSim 간 3개 바이트 에코 검증이 100% 일치함을 확인하였으며, Spartan-7(`xc7s75fgga484-1`) 타깃으로 WNS=14.617 ns, WHS=0.080 ns의 여유 있는 타이밍 마진을 확보하고 비트스트림 생성을 완료했습니다.

Combo II-DLD S75 보드와 PC 터미널 프로그램 간 9600 8N1 직렬 통신을 통해 입력 문자('A', 'Z', '\n')가 누락 없이 정상 에코 반환되고, 수신 데이터가 온보드 LED에 실시간 이진수 패턴으로 정확히 래치 표출됨을 실측 검증했습니다.