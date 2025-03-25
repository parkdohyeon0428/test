`timescale 1ns / 1ps

module hc_top_module (
    input clk,
    input reset,
    input btn_start,
    input data,
    output start_tick,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
);
    ila_0 ILA (
        .clk(clk),
        .probe0(data)
    );
    wire w_tick_gen, w_start_trigger;
    wire [15:0] w_o_tick;

    btn_debounce U_BTN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_start),
        .o_btn(w_start_trigger)
    );
    tick_gen_1us U_TICK_GEN (
        .clk      (clk),        // 시스템 클럭
        .rst      (reset),      // 비동기 리셋
        .baud_tick(w_tick_gen)  // Baud rate tick 신호 출력
    );
    // hc_control_unit U_HC_CU(
    //     .clk(clk),
    //     .reset(reset),
    //     .tick_gen(w_tick_gen)
    // );
    hc_data_path U_HC_DP (
        .clk(clk),
        .reset(reset),
        .btn_start(w_start_trigger),
        .data(data),
        .tick_gen(w_tick_gen),
        .o_tick(w_o_tick),
        .start_tick(start_tick)
    );
    fnd_controller U_FND_Cntl (
        .clk(clk),
        .reset(reset),
        .bcd(w_o_tick),
        .seg(fnd_font),
        .seg_comm(fnd_comm)
    );

endmodule

// module hc_control_unit (
//     input clk,
//     input reset,
//     output tick_gen
// );
//     parameter FCOUNT = 1000;
//     reg [$clog2(FCOUNT)-1:0] clk_reg;
//     reg tick_reg;

//     assign tick_gen = tick_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             clk_reg <= 0;
//             tick_reg <= 0;
//         end else begin
//             if (clk_reg == (FCOUNT - 1)) begin
//                 clk_reg <= 0;
//                 tick_reg <= 1;   
//             end else begin
//                 clk_reg <= clk_reg + 1;
//                 tick_reg <= 1'b0;
//             end           
//         end
//     end
// endmodule

module hc_data_path (
    input clk,
    input reset,
    input tick_gen,
    input btn_start,
    input data,
    output [15:0] o_tick,
    output start_tick
    //output [1:0] led
);
    parameter IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, DATA = 2'b11;

    reg [1:0] state, next;
    reg [15:0] data_reg, data_next;
    reg [6:0] tick_reg, tick_next;
    reg start_tick_reg, start_tick_next;
    //reg done_reg, done_next;
    assign o_tick = data_reg / 58;
    assign start_tick = start_tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            data_reg <= 0;
            tick_reg <= 0;
            start_tick_reg <= 0;
        end else begin
            state <= next;
            data_reg <= data_next;
            tick_reg <= tick_next;
            start_tick_reg <= start_tick_next;
        end
    end

    //next logic
    always @(*) begin
        next = state;
        data_next = data_reg;
        tick_next = tick_reg;
        start_tick_next = start_tick_reg;
        case (state)
            IDLE: begin
                if (btn_start == 1) next = START;
            end
            START: begin
                if (tick_gen == 1'b1) begin
                    data_next = 0;
                    start_tick_next = 1;
                    tick_next = tick_reg + 1;
                    if (tick_reg == 10) begin
                        next = WAIT;
                        tick_next = 0;
                        start_tick_next = 0;
                    end
                end
            end
            WAIT: begin
                if (data == 1) begin
                    next = DATA;
                end else begin
                    next = state;
                end
            end
            DATA: begin
                if (data == 1) begin
                    if (tick_gen == 1) begin
                        data_next = data_reg + 1;
                    end
                end else if (data == 0) begin
                    next = IDLE;
                end
            end
        endcase
    end
endmodule

// Baud Rate Tick 생성기 모듈 (DP)
module tick_gen_1us (
    input  clk,       // 시스템 클럭
    input  rst,       // 비동기 리셋
    output baud_tick  // Baud rate tick 신호 출력
);
    parameter BAUD_RATE = 9600;  // 전송 속도 (9600bps) //BAUD_RATE_19200 = 19200;
    localparam BAUD_COUNT = 100;  // Baud rate 계산 (100MHz 기준)
    reg [$clog2(BAUD_COUNT)-1:0]
        count_reg, count_next;  // 카운터 레지스터
    reg tick_reg, tick_next;  // Tick 신호 레지스터

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
        tick_next  = 0;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;  // Tick 신호 생성
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule
