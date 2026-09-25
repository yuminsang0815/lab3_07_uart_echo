`timescale 1ns/1ps

module tb_uart_echo;
  localparam integer DIV = 8;
  reg clk_50mhz = 0, rst_p = 1, uart_rxd = 1;
  wire uart_txd;
  wire [7:0] led;
  reg [7:0] observed;
  integer checks = 0, i;

  // 50 MHz 클록 (#10 = 20 ns 주기)
  always #10 clk_50mhz = ~clk_50mhz;

  // 빠른 시뮬레이션을 위한 가속 파라미터 적용 (CLK_HZ=800, BAUD=100 -> DIV=8)
  lab3_uart_echo #(
    .CLK_HZ(800),
    .BAUD(100)
  ) dut (
    .clk_50mhz(clk_50mhz),
    .rst_p(rst_p),
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    .led(led)
  );

  // 호스트 -> FPGA 직렬 전송 태스크 (8N1, LSB-first)
  task send_byte(input [7:0] value);
    begin
      uart_rxd = 0; repeat (DIV) @(posedge clk_50mhz); // Start 비트
      for (i = 0; i < 8; i = i + 1) begin
        uart_rxd = value[i]; repeat (DIV) @(posedge clk_50mhz); // Data 비트
      end
      uart_rxd = 1; repeat (DIV) @(posedge clk_50mhz); // Stop 비트
    end
  endtask

  // FPGA -> 호스트 직렬 수신 및 에코 데이터/LED 검증 태스크
  task receive_byte(input [7:0] expected);
    begin
      observed = 0;
      @(negedge uart_txd);
      repeat (DIV + DIV / 2) @(posedge clk_50mhz); // Start 비트 통과 후 첫 데이터 중앙 이동
      for (i = 0; i < 8; i = i + 1) begin
        observed[i] = uart_txd;
        repeat (DIV) @(posedge clk_50mhz);
      end
      if (observed !== expected)
        $fatal(1, "echo=%h expected=%h", observed, expected);
      if (led !== expected)
        $fatal(1, "led=%h expected=%h", led, expected);
      checks = checks + 1;
      repeat (DIV) @(posedge clk_50mhz);
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_uart_echo);

    repeat (4) @(posedge clk_50mhz);
    rst_p = 0;

    // Check 1: 0x41 ('A') 전송 및 에코 검증
    fork
      send_byte(8'h41);
      receive_byte(8'h41);
    join

    // Check 2: 0x5A ('Z') 전송 및 에코 검증
    fork
      send_byte(8'h5a);
      receive_byte(8'h5a);
    join

    // Check 3: 0x0A ('\n') 전송 및 에코 검증
    fork
      send_byte(8'h0a);
      receive_byte(8'h0a);
    join

    if (dut.rx_framing_error)
      $fatal(1, "unexpected framing error");

    $display("LAB3_UART_ECHO_PASS checks=%0d", checks);
    $finish;
  end

  initial begin
    #50000;
    $fatal(1, "timeout");
  end

endmodule