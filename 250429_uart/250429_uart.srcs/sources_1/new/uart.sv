`timescale 1ns / 1ps

module uart_main_RX(
    input  logic       clk,         // 시스템 클럭 입력
    input  logic       rst,         // 비동기 리셋 신호
    //rx
    input  logic       rx,
    output logic       rx_done,     // UART 송신 신호 (시리얼 출력) 
    output logic [7:0] rx_data
);
    logic w_tick;  // Baud rate tick 신호

    uart_rx U_Uart_rx (
        .clk(clk),  // 시스템 클럭
        .rst(rst),  // 비동기 리셋
        .tick(w_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );
    // Baud Rate 생성기 인스턴스화
    baud_tick_gen U_BAUD_Tick_Gen (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_tick)  // Baud rate tick 신호 생성
    );
endmodule



// UART RX
module uart_rx (
    input logic clk,  // 시스템 클럭
    input logic rst,  // 비동기 리셋
    input logic tick,
    input logic rx,
    output logic  rx_done,
    output logic  [7:0] rx_data
);
    //parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    logic [1:0] state, next;
    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [4:0] tick_count_reg, tick_count_next; // rx tick max count
    logic [7:0] rx_data_reg, rx_data_next;
    // output
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    // state
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            rx_done_reg <= 0;
            rx_data_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state <= next;
            rx_done_reg <= rx_done_next;
            rx_data_reg <= rx_data_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    //next
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = 1'b0;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next = 0;
                rx_done_next = 1'b0;
                if (rx == 1'b0) begin
                    next = START;
                end
            end
            START: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        // read data
                        rx_data_next [bit_count_reg] = rx;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                            tick_count_next = 0; // 다음 스테이트 가면 초기화
                        end else begin
                            next = DATA;    
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                    if (tick == 1'b1) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule





// Baud Rate Tick 생성기 모듈 (DP)
module baud_tick_gen (
    input  logic clk,       // 시스템 클럭
    input  logic rst,       // 비동기 리셋
    output logic baud_tick  // Baud rate tick 신호 출력
);
    parameter BAUD_RATE = 9600;  // 전송 속도 (9600bps) //BAUD_RATE_19200 = 19200;
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE)/16; // Baud rate 계산 (100MHz 기준)
    logic [$clog2(BAUD_COUNT)-1:0]
        count_reg, count_next;  // 카운터 레지스터
    logic tick_reg, tick_next;  // Tick 신호 레지스터

    assign baud_tick = tick_reg;  // Tick 신호 출력

    // 레지스터 업데이트
    always @(posedge clk, posedge rst) begin
        if (rst == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    // Baud rate tick 생성 로직
    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;  // Tick 신호 생성
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule
