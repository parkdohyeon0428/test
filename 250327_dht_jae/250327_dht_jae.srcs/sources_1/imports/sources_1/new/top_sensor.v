`timescale 1ns / 1ps

module top_sensor (
    input clk,
    input reset,
    inout data,
    input start_trigger,
    output [4:0] led,
    output [7:0] seg_out,
    output [3:0] seg_comm,
    output tx
);
    wire [39:0] w_o_data;
    wire [15:0] w_o_data2;
    wire [ 5:0] data_count;
    assign w_o_data2 = {w_o_data[39:32], w_o_data[23:16]};
    wire w_finish_tick;
    wire [5:0] w_o_state;

    /*
    ila_0 uila (
        .clk(clk),
        .probe0(data_in),
        .probe1(w_o_data[39:25]),
        .probe2(data_count),
        .probe3(w_o_state)
    ); */

    IOBUF uIO (
        .I (data_out),  // 출력 데이터가 입력으로
        .O (data_in),   // 입력 데이터로 감
        .IO(data),
        .T (data_t)      // 입출력 모드 전환 (여기선 1이 입력모드 0이 출력모드)
    );

    sensor_cu u_sen (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .start_trigger(w_start_trigger | w_tick10sec),
        .finish_tick(w_finish_tick),
        .o_data(w_o_data),
        .led(led[4]),
        .o_state(w_o_state),
        .data_in(data_in),
        .data_out(data_out),
        .data_t(data_t),
        .data_count(data_count)
    );

    tick_1us u_tick (
        .clk  (clk),
        .reset(reset),
        .tick (w_tick)
    );
    tick_10sec u_tick10 (
        .clk  (clk),
        .reset(reset),
        .tick (w_tick10sec)
    );

    btn_debounce ubtn (
        .i_btn(start_trigger),
        .clk  (clk),
        .reset(reset),
        .o_btn(w_start_trigger)
    );
    fnd_controlloer ufnd (  //control anod segments
        .clk(clk),
        .reset(reset),
        .count(w_o_data2),
        .seg_out(seg_out),
        .seg_comm(seg_comm)
    );
    uart_clock uuart_clock (
        .reset(reset),
        .clk(clk),
        .finish_tick(w_finish_tick),
        .start_trigger(w_start_trigger | w_tick10sec),
        .tx(tx),
        .sensor_data(w_o_data2)

    );
endmodule



module sensor_cu (
    input clk,
    input reset,
    input tick,   // 1us tick
    input start_trigger,  // btn_start
    input data_in,    // 센서 입력 데이터
    output data_out,  // 센서 출력 데이터
    output data_t,    // 데이터 방향 제어 (입력 or 출력 모드)
    output start_tick,   // 미상
    output [39:0] o_data,  // 수집된 센서 데이터
    output finish_tick,   //데이터 수집 완료 신호
    output led,            
    output [3:0] o_state,    // 현재 상태 표시
    output reg [5:0] data_count  // 데이터 카운트   

);

    parameter IDLE = 4'b0000, START = 4'b0001, WAIT = 4'b0010, WAIT2 = 4'b0011, WAIT3 = 4'b0100;
    parameter SYNC = 4'b0101, DATA = 4'b0110, PAR = 4'b0111, WAIT4 = 4'b1110,DATA2 = 4'b1111;
    reg [3:0] state, next;
    reg [15:0] tick_count, tick_count_next;
    reg data_reg, data_next;    //출력 데이터
    reg [39:0] o_data_reg, o_data_next;
    reg start_tick_reg, start_tick_next;
    reg finish_tick_reg, finish_tick_next;
    reg [5:0] data_count_next;
    reg led_reg, led_next;
    reg io_state, io_state_next;
    reg [7:0] real_count, real_count_next;
    assign data_out = data_reg;
    assign data_t = ~io_state;  // 1이면 입력모드, 0이면 출력모드 (IOBUF에서 1=High-Z)

    assign start_tick = start_tick_reg;
    assign finish_tick = finish_tick_reg;
    assign led = led_reg;
    assign o_state = state;
    assign o_data = o_data_reg;
    // out 3state on/off
    // assign data = (io_state) ? data_reg : 1'bz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            tick_count <= 0;
            data_reg <= 1;
            start_tick_reg <= 0;
            finish_tick_reg <= 0;
            led_reg <= 0;
            io_state <= 0;
            o_data_reg <= 0;
            data_count <= 0;
            real_count <= 0;
        end else begin
            state <= next;
            tick_count <= tick_count_next;
            data_reg <= data_next;
            start_tick_reg <= start_tick_next;
            finish_tick_reg <= finish_tick_next;
            led_reg <= led_next;
            io_state <= io_state_next;
            o_data_reg <= o_data_next;
            data_count <= data_count_next;
            real_count <= real_count_next;
        end
    end

    always @(*) begin
        next = state;
        data_next = data_reg;
        tick_count_next = tick_count;
        start_tick_next = start_tick_reg;
        finish_tick_next = 0;
        led_next = led_reg;
        io_state_next = io_state;
        o_data_next = o_data_reg;
        data_count_next = data_count;
        real_count_next = real_count;
        case (state)

            IDLE: begin
                data_next = 1;
                io_state_next = 1;
                if (start_trigger == 1) begin
                    next = START;
                    data_count_next = 0;
                    real_count_next = 0;
                    o_data_next = 0;
                end
            end
            START:
            if (tick == 1) begin
                data_next = 0;
                tick_count_next = tick_count + 1;
                if (tick_count_next == 18000) begin
                    next = WAIT;
                    data_next = 1;
                    tick_count_next = 0;
                end
            end
            WAIT:
            if (tick == 1) begin
                tick_count_next = tick_count + 1;
                if (tick_count_next == 15) begin
                    next = WAIT2;
                    tick_count_next = 0;
                    io_state_next = 0;  //입력 모드 전환
                end
            end
            WAIT2: begin                   // sync low
                if (tick == 1) begin
                    tick_count_next = tick_count + 1;
                    if (tick_count_next == 50) begin
                        tick_count_next = 0;
                        if (data_in == 1) begin
                            next = WAIT3;
                        end
                    end

                end
            end
            WAIT3: begin                 // sync high
                if (data_in == 0) begin
                    next = SYNC;
                end
            end

            SYNC: begin
                if (data_count == 40) begin
                    data_count_next = 0;
                    next = PAR;
                end else if (data_in == 1) begin
                    real_count_next = real_count + 1;
                    if (real_count_next == 100) begin
                        next = DATA;
                        tick_count_next = 0;
                        real_count_next = 0;
                    end

                end
            end
            DATA: begin
                if (data_in == 1) begin
                    if (tick == 1) begin
                        tick_count_next = tick_count + 1;
                        if (tick_count_next > 200) begin
                            tick_count_next = 0;
                            next = IDLE;
                        end
                    end
                end else if (data_in == 0) begin
                    next = DATA2;
                end
            end
            DATA2: begin
                if (tick_count_next < 50) begin
                    next = SYNC;
                    o_data_next[39-data_count] = 0;
                    data_count_next = data_count + 1;
                    tick_count_next = 0;
                end else begin
                    next = SYNC;
                    o_data_next[39-data_count] = 1;
                    data_count_next = data_count + 1;
                    tick_count_next = 0;
                end
            end
            PAR: begin                    //STOP
                io_state_next = 1;       // 다시 출력모드
                if (tick == 1) begin
                    tick_count_next = tick_count + 1;
                end
                if (tick_count_next == 50) begin
                    data_next = 1;    //???
                    if( o_data_reg[39:32] + o_data_reg[31:24] + o_data_reg[23:16] +o_data_reg[15:8] != o_data_reg[7:0])
                    begin
                        led_next = 1;
                    end else begin
                        led_next = 0;
                        finish_tick_next = 1;     //uart 로 감
                    end
                    tick_count_next = 0;
                    next = IDLE;
                end
            end


        endcase
    end
endmodule


module tick_1us (
    input  clk,
    input  reset,
    output tick
);

    parameter BAUD_RATE = 9600;
    localparam BAUD_COUNT = 100;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;

    reg tick_reg, tick_next;
    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end


    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule



module tick_10sec (
    input  clk,
    input  reset,
    output tick
);

    parameter BAUD_RATE = 9600;
    localparam BAUD_COUNT = 1000_000_000;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;

    reg tick_reg, tick_next;
    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end


    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule
