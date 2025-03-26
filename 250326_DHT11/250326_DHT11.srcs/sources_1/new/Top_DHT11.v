`timescale 1ns / 1ps

module Top_DHT11 (
    input clk,
    input reset,
    input btn_start,
    inout dht_io,
    output [3:0] led
    //output [3:0] fsm_state,
    //output dht_response
);
    wire w_tick_1us;

    tick_gen_1us U_TICk_GEN (
        .clk(clk),
        .rst(reset),
        .baud_tick(w_tick_1us)
    );
    dnt11_controller U_DNT_CTRL(
        .clk(clk),
        .reset(reset),
        .tick_gen_1us(w_tick_1us),
        .btn_start(btn_start),
        .dht_io(dht_io),
        .led(led),
        .humi(),
        .temp()
    );
endmodule

module dnt11_controller (
    input clk,
    input reset,
    input tick_gen_1us, // tick 발생기
    input btn_start,    // 버튼 
    inout dht_io,       // 센서 inout data
    output [3:0] led,  
    output reg [15:0] humi,  // 습도
    output reg [15:0] temp   // 온도
);
    parameter START_CNT = 1800, WAIT_CNT = 3, SYNC_CNT = 8, DATASYNC = 5, 
                DATA_01 = 4, STOP_CNT = 5, TIME_OUT = 2000;
    localparam IDLE = 4'b0000, START = 4'b0001, WAIT = 4'b0010, SYNC_HIGH = 4'b0100,
               SYNC_LOW = 4'b1000, DATA_DC = 4'b0011, STOP = 4'b1100, TIME = 4'b0111;


    reg [3:0] state, next;
    reg [$clog2(TIME_OUT-1):0] tick_count_reg, tick_count_next;
    reg io_oe_reg, io_oe_next;
    reg dht_io_reg, dht_io_next;
    reg o_data_reg, o_data_next;
    reg [39:0] data_reg, date_next;
    reg led_reg, led_next;

    assign led  = {state, led_reg};
    
    // out 3state on/off
    assign dht_io = (io_oe_reg) ? dht_io_reg:1'bz;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            tick_count_reg <= 0;
            o_data_reg <= 0;
            io_oe_reg <= 0;
            led_reg <= 0;
            dht_io_reg <= 1;   // idle일때 high
        end else begin
            state <= next;
            tick_count_reg <= tick_count_next;
            o_data_reg <= o_data_next;
            led_reg <= led_next;
            io_oe_reg <= io_oe_next;
            dht_io_reg <= dht_io_next;
        end
    end

    //next logic
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        o_data_next = o_data_reg;
        led_next = led_reg;
        dht_io_next = dht_io_reg;
        io_oe_next = io_oe_reg;
        case (state)
            IDLE: begin
                dht_io_next = 1'b1;
                io_oe_next = 1'b1;
                if (btn_start == 1) 
                    next = START;
                    tick_count_next = 0;
            end
            START: begin
                dht_io_next = 0;
                if (tick_gen_1us == 1) begin
                    if (tick_count_reg == START_CNT) begin
                        next = WAIT;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT: begin
                dht_io_next = 1;
                if (tick_gen_1us == 1) begin
                    if (tick_count_reg == WAIT_CNT) begin
                        next = SYNC_LOW;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            SYNC_LOW: begin
                io_oe_next = 1'b0;
                //io oe change , output open, high Z
                if (dht_io == 1) begin
                    next = SYNC_HIGH;
                    end
            end
            SYNC_HIGH: begin
                if (dht_io == 0) begin
                    next = DATA_DC;
                    end
            end
            DATA_DC: begin 
                if (dht_io == 1) begin       //판별별
                    if (tick_gen_1us < 40) begin
                        //o_data_next [data_next] = 1'b0;
                        data_reg = {data_reg[39:1], 1'b0};
                        next = STOP;
                    end
                    else begin
                        data_reg = {data_reg[39:1], 1'b1};
                        next = STOP;
                        //o_data_next [data_next] = 1'b1;
                    end
                end
            end
            STOP: begin
            if (tick_count_reg == 10) begin
                humi = data_reg[39:24];  // 예시: 습도 (상위 16비트)
                temp = data_reg[23:8];    // 예시: 온도 (하위 16비트)
                next = IDLE;  // IDLE 상태로 돌아가서 대기
                tick_count_next = 0;  // 타이머 리셋
            end else begin
                tick_count_next = tick_count_reg + 1;
                next = STOP;  // 계속 STOP 상태를 유지
            end
        end
        endcase
    end
endmodule





module tick_gen_1us (
    input  clk,       // 시스템 클럭
    input  rst,       // 비동기 리셋
    output baud_tick  // Baud rate tick 신호 출력
);
    //parameter BAUD_RATE = 9600;  // 전송 속도 (9600bps) //BAUD_RATE_19200 = 19200;
    localparam BAUD_COUNT = 1000;  // Baud rate 계산 (100MHz 기준)
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
