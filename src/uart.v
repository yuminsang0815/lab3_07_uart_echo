`timescale 1ns/1ps

module uart_rx #(parameter integer DIV = 5208) (
  input wire clk, rst_p, rx,
  output reg [7:0] data,
  output reg valid,
  output reg framing_error
);

  (* ASYNC_REG="TRUE" *) reg [1:0] sync;
  reg [1:0] state;
  integer timer;
  reg [2:0] bitno;
  reg [7:0] shift;

  // 비동기 RX 입력 2단 동기화 및 UART 수신 FSM
  always @(posedge clk) begin
    if (rst_p) begin
      sync          <= 2'b11;
      state         <= 2'd0;
      timer         <= 0;
      bitno         <= 3'd0;
      shift         <= 8'd0;
      data          <= 8'd0;
      valid         <= 1'b0;
      framing_error <= 1'b0;
    end else begin
      sync          <= {sync[0], rx};
      valid         <= 1'b0;
      framing_error <= 1'b0;

      case (state)
        2'd0: begin // Idle: Start 비트 하강 에지 검출
          if (!sync[1]) begin
            timer <= DIV / 2 - 1; // 비트 중앙 샘플링을 위해 반주기 대기
            state <= 2'd1;
          end
        end

        2'd1: begin // Start 비트 중앙 유효성 검증
          if (timer != 0) begin
            timer <= timer - 1;
          end else if (sync[1]) begin
            state <= 2'd0; // 글리치(노이즈)일 경우 복귀
          end else begin
            timer <= DIV - 1;
            bitno <= 3'd0;
            state <= 2'd2;
          end
        end

        2'd2: begin // 8비트 데이터 수신 (LSB-first)
          if (timer != 0) begin
            timer <= timer - 1;
          end else begin
            shift[bitno] <= sync[1];
            timer        <= DIV - 1;
            if (bitno == 3'd7) begin
              state <= 2'd3;
            end else begin
              bitno <= bitno + 1'b1;
            end
          end
        end

        2'd3: begin // Stop 비트 검증
          if (timer != 0) begin
            timer <= timer - 1;
          end else begin
            if (sync[1]) begin
              data  <= shift;
              valid <= 1'b1;
            end else begin
              framing_error <= 1'b1;
            end
            state <= 2'd0;
          end
        end
      endcase
    end
  end

endmodule


module uart_tx #(parameter integer DIV = 5208) (
  input wire clk, rst_p, valid,
  input wire [7:0] data,
  output wire ready,
  output wire tx
);

  reg [9:0] shift;
  reg [3:0] remaining;
  integer timer;

  assign ready = (remaining == 4'd0);
  assign tx = ready ? 1'b1 : shift[0];

  // UART 송신 시퀀서: Start(0) + 8비트 데이터 + Stop(1)
  always @(posedge clk) begin
    if (rst_p) begin
      shift     <= 10'h3ff;
      remaining <= 4'd0;
      timer     <= 0;
    end else if (ready) begin
      if (valid) begin
        shift     <= {1'b1, data, 1'b0}; // {Stop, Data[7:0], Start}
        remaining <= 4'd10;
        timer     <= DIV - 1;
      end
    end else if (timer != 0) begin
      timer <= timer - 1;
    end else begin
      timer     <= DIV - 1;
      shift     <= {1'b1, shift[9:1]};
      remaining <= remaining - 1'b1;
    end
  end

endmodule