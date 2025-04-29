//uart.v // 교수님코드
`timescale 1ns / 1ps

// UART 모듈
module uart_fsm (
    input        clk,         // 시스템 클럭 입력
    input        rst,         // 비동기 리셋 신호
    // tx
    input        btn_start,   // 데이터 전송 시작 트리거
    input  [7:0] tx_data_in,
    output       tx_done,
    output       tx,
    //rx
    input        rx,
    output       rx_done,     // UART 송신 신호 (시리얼 출력) 
    output [7:0] rx_data
);

    wire w_tick;  // Baud rate tick 신호

    // UART 송신기 인스턴스화
    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .start_trigger(btn_start),
        .data_in(tx_data_in),  // ASCII 코드 '0' (0x30)을 송신
        .o_tx_done(tx_done),
        .o_tx(tx)
    );

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

// UART 송신기 모듈
module uart_tx (
    input clk,  // 시스템 클럭
    input rst,  // 비동기 리셋
    input tick,  // Baud rate tick 신호
    input start_trigger,  // 전송 시작 신호
    input [7:0] data_in,  // 송신할 8비트 데이터
    output o_tx_done,
    output o_tx  // UART 송신 신호 (1비트, 시리얼 데이터)
);
    // FSM 상태 정의
    parameter IDLE = 0, SEND = 1, START = 2, DATA = 3, STOP = 4;

    reg [3:0] state, next;
    reg tx_reg, tx_next;
    reg tx_done_reg, tx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [3:0] tick_count_reg, tick_count_next;
    assign o_tx_done = tx_done_reg;
    assign o_tx = tx_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            tx_reg <= 1'b1;
            tx_done_reg <= 0;
            bit_count_reg <= 0;
        end else begin
            state <= next;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // 상태 전이 로직 (FSM)
    always @(*) begin
        next = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        bit_count_next = bit_count_reg;
        tick_count_next = tick_count_reg;
        case (state)
            IDLE: begin
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                tick_count_next = 4'h0;
                if (start_trigger) begin
                    next = SEND;
                end
            end
            SEND: begin
                if (tick == 1'b1) begin
                    next = START;
                end
            end
            START: begin
                tx_done_next = 1'b1;
                tx_next = 1'b0;  // 출력을 0으로 유지.
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        next = DATA;
                        bit_count_next = 1'b0;
                        tick_count_next = 1'b0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            DATA: begin
                if (tick == 1'b1) begin
                    tx_next = data_in[bit_count_reg];
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0; // 다음 상태로 가기전에 초기화화
                        if (bit_count_next == 7) begin
                            next = STOP;
                            bit_count_next = 0;
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (tick == 1'b1) begin
                    if (tick_count_next == 15) begin
                        next = IDLE;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

// UART RX
module uart_rx (
    input clk,  // 시스템 클럭
    input rst,  // 비동기 리셋
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
);
    //parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state, next;
    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [4:0] tick_count_reg, tick_count_next; // rx tick max count
    reg [7:0] rx_data_reg, rx_data_next;
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
    input  clk,       // 시스템 클럭
    input  rst,       // 비동기 리셋
    output baud_tick  // Baud rate tick 신호 출력
);
    parameter BAUD_RATE = 9600;  // 전송 속도 (9600bps) //BAUD_RATE_19200 = 19200;
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE)/16; // Baud rate 계산 (100MHz 기준)
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

module fifo_tx (
    input clk,
    input reset,
    // write
    input [7:0] wdata,
    input wr,
    output full,
    // read
    input rd,
    output [7:0] rdata,
    output empty
);
    // module instance
    wire [3:0] waddr, raddr;

    register_file U_REG_FILE_tx (
        .clk(clk),
        .waddr(waddr), 
        .wdata(wdata),
        .wr({~full&wr}),
        .raddr(raddr),
        .rdata(rdata)
    );

    fifo_control_unit U_FIFO_CU_tx (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .waddr(waddr),
        .full(full),
        .rd(rd),
        .raddr(raddr),
        .empty(empty)
    );
    


endmodule

// data path
module register_file (
    input clk,
    // write
    input [3:0] waddr,  // 4bit
    input [7:0] wdata,  // 8bit
    input wr,
    // read
    input [3:0] raddr,
    output [7:0] rdata
);
    reg [7:0] mem[0:2**4-1];  // 4bit address

    // write
    always @(posedge clk) begin
        if (wr) begin
            mem[waddr] <= wdata;
        end
    end

    // read
    assign rdata = mem[raddr];

endmodule

module fifo_control_unit (
    input clk,
    input reset,
    // write
    input wr,
    output [3:0] waddr,  //
    output full,
    // read
    input rd,
    output [3:0] raddr,
    output empty
);

    // 1bit 상태 output
    reg full_reg, full_next, empty_reg, empty_next;
    // W,R address 관리
    reg [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;

    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            full_reg  <= 0;
            empty_reg <= 1; // empty 초기값 1.
            wptr_reg  <= 0;
            rptr_reg  <= 0;
        end else begin
            full_reg  <= full_next;
            empty_reg <= empty_next;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
        end
    end

    // next
    always @(*) begin
        full_next  = full_reg;
        empty_next = empty_reg;
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        case ({wr, rd})     // state 외부에서 입력으로 변경됨.
            2'b01: begin // rd가 1일때, read
                if(empty_reg == 1'b0) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end

                end
            end 
            2'b10: begin    // wr == 1일때, write
                if (full_reg == 1'b0) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end 
            end
            2'b11: begin
                if (empty_reg == 1'b1) begin    // 이전 플롯과 다르게 empty_reg == 1'b0가 조건이 아닌 이유는, 구조상 더 간단하게 하기 위함.
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
endmodule

module fifo_rx (
    input clk,
    input reset,
    // write
    input [7:0] wdata,
    input wr,
    output full,
    // read
    input rd,
    output [7:0] rdata,
    output empty
);
    // module instance
    wire [3:0] waddr, raddr;

    register_file_rx U_REG_FILE_rx (
        .clk(clk),
        .waddr(waddr), 
        .wdata(wdata),
        .wr({~full&wr}),
        .raddr(raddr),
        .rdata(rdata)
    );

    fifo_control_unit_rx U_FIFO_CU_rx (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .waddr(waddr),
        .full(full),
        .rd(rd),
        .raddr(raddr),
        .empty(empty)
    );
    


endmodule

// data path
module register_file_rx (
    input clk,
    // write
    input [3:0] waddr,  // 4bit
    input [7:0] wdata,  // 8bit
    input wr,
    // read
    input [3:0] raddr,
    output [7:0] rdata
);
    reg [7:0] mem[0:2**4-1];  // 4bit address

    // write
    always @(posedge clk) begin
        if (wr) begin
            mem[waddr] <= wdata;
        end
    end

    // read
    assign rdata = mem[raddr];

endmodule

module fifo_control_unit_rx (
    input clk,
    input reset,
    // write
    input wr,
    output [3:0] waddr,  //
    output full,
    // read
    input rd,
    output [3:0] raddr,
    output empty
);

    // 1bit 상태 output
    reg full_reg, full_next, empty_reg, empty_next;
    // W,R address 관리
    reg [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;

    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            full_reg  <= 0;
            empty_reg <= 1; // empty 초기값 1.
            wptr_reg  <= 0;
            rptr_reg  <= 0;
        end else begin
            full_reg  <= full_next;
            empty_reg <= empty_next;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
        end
    end

    // next
    always @(*) begin
        full_next  = full_reg;
        empty_next = empty_reg;
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        case ({wr, rd})     // state 외부에서 입력으로 변경됨.
            2'b01: begin // rd가 1일때, read
                if(empty_reg == 1'b0) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end

                end
            end 
            2'b10: begin    // wr == 1일때, write
                if (full_reg == 1'b0) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end 
            end
            2'b11: begin
                if (empty_reg == 1'b1) begin    // 이전 플롯과 다르게 empty_reg == 1'b0가 조건이 아닌 이유는, 구조상 더 간단하게 하기 위함.
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase


    end

endmodule

module data_save(
    input clk,
    input reset,
    input rd,
    input [7:0] data_in,
    output [7:0] data_out
    );
    reg [7:0] data_reg,data_next;
    assign data_out = data_reg;
    always @(posedge clk) begin
        if (reset) begin
            data_reg <=0;
        end
        else begin
            data_reg <= data_next;
        end
    end
    always@(*) begin
        data_next = data_reg;
        if(rd) begin
            data_next = data_in;
        end
    end
endmodule