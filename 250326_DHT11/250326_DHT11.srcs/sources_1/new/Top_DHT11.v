`timescale 1ns / 1ps

module Top_DHT11 (
    input clk,
    input reset,
    input btn_start,
    inout dht_io,
    output [4:0] led,
    output [7:0] seg,
    output [3:0] seg_comm
    //output [3:0] fsm_state,
    //output dht_response
);
    wire w_tick_1us, w_btn_start;
    wire [7:0] w_humi, w_temp;

    tick_gen_1us U_TICk_GEN (
        .clk(clk),
        .rst(reset),
        .baud_tick(w_tick_1us)
    );
    btn_debounce U_btn (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_start),
        .o_btn(w_btn_start)
    );
    dnt11_controller U_DNT_CTRL (
        .clk(clk),
        .reset(reset),
        .tick_gen_1us(w_tick_1us),
        .btn_start(w_btn_start),
        .dht_io(dht_io),
        .led(led),
        .humi(w_humi),
        .temp(w_temp)
    );
    fnd_controller U_FND (
        .clk(clk),
        .reset(reset),
        .bcd({w_humi, w_temp}),
        .seg(seg),
        .seg_comm(seg_comm)
    );
endmodule

module dnt11_controller (
    input            clk,
    input            reset,
    input            tick_gen_1us,  // tick 발생기
    input            btn_start,     // 버튼 
    inout            dht_io,        // 센서 inout data
    output     [4:0] led,
    output reg [7:0] humi,          // 습도
    output reg [7:0] temp           // 온도
);
    parameter START_CNT = 18000, WAIT_CNT = 30; //SYNC_CNT = 8, //DATASYNC = 5, 
                //DATA_01 = 4, S//TOP_CNT = 5, //TIME_OUT = 2000;
    localparam IDLE = 4'b0000, START = 4'b0001, WAIT = 4'b0010, SYNC_HIGH = 4'b1000, DATA_SYNC = 4'b0011,
               SYNC_LOW = 4'b0100, DATA_DC = 4'b0111, STOP = 4'b1111;


    reg [3:0] state, next;
    reg [14:0]
        tick_count_reg, tick_count_next;  // tick 카운터터
    reg io_oe_reg, io_oe_next;  // 입출력 모드 변환
    reg dht_io_reg, dht_io_next;  // 출력 모드 tick
    reg [5:0] data_count_reg, data_count_next;
    reg [39:0] data_reg, data_next;  // 40비트 데이터터
    reg [7:0] humi_next, temp_next;
    reg led_reg, led_next;

    assign led = {state, led_reg};

    // out 3state on/off
    assign dht_io = (io_oe_reg) ? dht_io_reg : 1'bz;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            tick_count_reg <= 0;
            data_reg <= 0;
            data_count_reg <= 0;
            io_oe_reg <= 0;
            humi <= 0;
            temp <= 0;
            led_reg <= 0;
            dht_io_reg <= 1;  // idle일때 high
        end else begin
            state <= next;
            tick_count_reg <= tick_count_next;
            data_reg <= data_next;
            data_count_reg <= data_count_next;
            led_reg <= led_next;
            io_oe_reg <= io_oe_next;
            dht_io_reg <= dht_io_next;
            humi <= humi_next;
            temp <= temp_next;
        end
    end

    //next logic
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        data_next = data_reg;
        data_count_next = data_count_reg;
        led_next = led_reg;
        dht_io_next = dht_io_reg;
        io_oe_next = io_oe_reg;
        humi_next = humi;
        temp_next = temp;
        case (state)
            IDLE: begin
                dht_io_next = 1'b1;
                io_oe_next  = 1'b1;
                if (btn_start == 1) next = START;
                tick_count_next = 0;
            end
            START: begin
                dht_io_next = 0;
                if (tick_gen_1us == 1) begin
                    if (tick_count_reg == START_CNT) begin
                        next = WAIT;
                        tick_count_next = 0;
                        dht_io_next = 1;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (tick_gen_1us == 1) begin
                    if (tick_count_reg == WAIT_CNT) begin
                        io_oe_next = 1'b0;
                        tick_count_next = 0;
                        next = SYNC_LOW;
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
                    next = DATA_SYNC;
                end
            end
            DATA_SYNC: begin
                if (data_count_reg == 40) begin
                    data_count_next = 0;
                    io_oe_next = 1'b1;
                    next = STOP;
                end else if (dht_io == 1) begin
                    next = DATA_DC;
                end
            end
            DATA_DC: begin
                if (tick_gen_1us == 1) begin
                    tick_count_next = tick_count_reg + 1;
                end
                if (dht_io == 0) begin
                    if (tick_count_reg < 45) begin
                        data_next [39-data_count_next] = 1'b0;
                        //data_next = {data_reg[38:0], 1'b0};
                        data_count_next = data_count_reg + 1;
                        tick_count_next = 0;
                        next = DATA_SYNC;
                    end else begin
                        data_next [39-data_count_next] = 1'b1;
                        //data_next = {data_reg[38:0], 1'b1};
                        data_count_next = data_count_reg + 1;
                        tick_count_next = 0;
                        next = DATA_SYNC;
                    end
                end
            end
            STOP: begin
                io_oe_next = 1;
                if (tick_gen_1us == 1) begin
                    tick_count_next = tick_count_reg + 1;
                end
                if (tick_count_next == 50) begin
                    if (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8] != data_reg[7:0]) begin
                    led_next = 1;
                    end
                end
                    humi_next = data_reg[39:32];
                    temp_next = data_reg[23:16];
                    tick_count_next = 0;
                    next = IDLE;
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
