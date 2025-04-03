`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    input        btnL,
    input        btnR,
    input        btnD,
    input        btnU,
    output [3:0] fndCom,
    output [7:0] fndFont,
    output       tx,
    input        rx
);
    wire [13:0] fndData, w_count, w_stopwatch_count;
    wire [ 3:0] fndDot, w_stopwatch_dot, w_count_dot;
    wire uart_en, uart_clear, uart_mode, main_mode;
    wire btn_en, btn_clear, btn_mode;
    wire [7:0] rx_data;
    wire rx_done;
    wire [7:0] tx_data;
    wire tx_start;
    wire tx_busy;
    wire tx_done;
    wire w_btnL, w_btnR, w_btnD, w_btnU;


    btn_debounce U_btnL(  // run stop
        .clk(clk),
        .reset(reset),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );
    btn_debounce U_btnR(  // clear
        .clk(clk),
        .reset(reset),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );
    btn_debounce U_btnD(  // stopwatch or count mode
        .clk(clk),
        .reset(reset),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );
    btn_debounce U_btnU(  // up down mode
        .clk(clk),
        .reset(reset),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );
    uart U_Uart (
        .clk(clk),
        .reset(reset),
        //tx
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx(tx),
        //rx
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    btn_control_unit U_BTN_CU(
        .clk(clk),
        .reset(reset),
        .run_stop(w_btnL),
        .btn_clear(w_btnR),
        .btnD(w_btnD),
        .updown(w_btnU),
        //data path
        .en(btn_en),
        .clear(btn_clear),
        .mode(btn_mode),
        .main_mode(main_mode)
    );
    control_unit U_ControlUnit (
        .clk     (clk),
        .reset   (reset),
        
        //tx
        .tx_data (tx_data),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        //rx
        .rx_data (rx_data),
        .rx_done (rx_done),
        .en      (uart_en),
        .clear   (uart_clear),
        .mode    (uart_mode)
        
    );

    counter_up_down U_Counter_Up_Down (
        .clk     (clk),
        .reset   (reset),
        .en      ((uart_en || btn_en) && (main_mode == 1)),
        .clear   ((uart_clear || btn_clear) && (main_mode == 1)),
        .mode    ((uart_mode || btn_mode) && (main_mode == 1)),
        .count   (w_count),
        .dot_data(w_count_dot)
    );

    counter_stopwatch U_STOPWATCH(
        .clk(clk),
        .reset(reset),
        .en((uart_en || btn_en) && (main_mode == 0)),
        .clear((uart_clear || btn_clear) && (main_mode == 0)),
        .count(w_stopwatch_count),
        .dot_data(w_stopwatch_dot)
    );
    fndController U_FndController (
        .clk    (clk),
        .reset  (reset),
        .fndData(fndData),
        .fndDot (fndDot),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );
    mux U_mux(
        .main_mode(main_mode),
        .stopwatch_count(w_stopwatch_count),
        .count(w_count),
        .o_count(fndData)
    );
    mux_dot U_Dot(
        .main_mode(main_mode),
        .stopwatch_dot(w_stopwatch_dot),
        .count_dot(w_count_dot),
        .fndDot(fndDot)
    );
endmodule

module mux (
    input main_mode,
    input [13:0] stopwatch_count,
    input [13:0] count,
    output reg [13:0] o_count
);

    always @(*) begin
        o_count = count;
        case (main_mode)
            0: begin 
                o_count = stopwatch_count;
                end
            1: begin
                o_count = count;
            end
        endcase
    end
endmodule

module mux_dot (
    input main_mode,
    input [3:0] stopwatch_dot,
    input [3:0] count_dot,
    output reg [3:0] fndDot
);
    always @(*) begin
        fndDot = count_dot;
        case (main_mode)
            0: begin 
                fndDot = stopwatch_dot;
                end
            1: begin
                fndDot = count_dot;
            end
        endcase
    end
endmodule

module control_unit (
    input            clk,
    input            reset,
    //input            btnD,
    //tx
    output reg [7:0] tx_data,
    output reg       tx_start,
    input            tx_busy,
    input            tx_done,
    //rx
    input      [7:0] rx_data,
    input            rx_done,
    //data path
    output reg       en,
    output reg       clear,
    output reg       mode
    //output reg       main_mode
);
    localparam STOP = 0, RUN = 1, CLEAR = 2;
    localparam UP = 0, DOWN = 1;
    //localparam STOPWATCH = 0, COUNT = 1;
    localparam IDLE = 0, ECHO = 1;
    reg [1:0] state, state_next;
    reg mode_state, mode_state_next;
    reg echo_state, echo_state_next;
    //reg main_mode_state, main_mode_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
            mode_state <= UP;
            echo_state <= IDLE;
            //main_mode_state <= STOPWATCH;
        end else begin
            state <= state_next;
            mode_state <= mode_state_next;
            echo_state <= echo_state_next;
            //main_mode_state <= mode_state_next;
        end
    end

    always @(*) begin
        echo_state_next = echo_state;
        tx_start = 1'b0;
        case (echo_state)
            IDLE: begin
                tx_data = 0;
                tx_start = 1'b0;
               if (rx_done) begin
                echo_state_next = ECHO;
               end 
            end 
            ECHO: begin
                if (tx_done) begin
                    echo_state_next = IDLE;
                end else begin
                    tx_data = rx_data;
                    tx_start = 1'b1;
                end
            end
        endcase
    end

    always @(*) begin
        mode_state_next = mode_state;
        mode = 1'b0;
        case (mode_state)
            UP: begin
                mode = 1'b0;
                if (rx_done) begin
                    if (rx_data == 8'h6d) mode_state_next = DOWN;
                end
            end 
            DOWN: begin
                mode = 1'b1;
                if (rx_done) begin
                    if (rx_data == 8'h6d) mode_state_next = UP;
                end
            end
        endcase
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        case (state)
            STOP: begin
                en = 1'b0;
                clear = 1'b0;
                if (rx_done) begin
                    if (rx_data == 8'h72) state_next = RUN;
                    else if (rx_data == 8'h63) state_next = CLEAR;
                end
            end
            RUN: begin
                en = 1'b1;
                clear = 1'b0;
                if (rx_data == 8'h73) state_next = STOP;
            end
            CLEAR: begin
                en = 1'b0;
                clear = 1'b1;
                state_next = STOP;
            end
        endcase
    end
endmodule





module counter_up_down (
    input         clk,
    input         reset,
    input         en,
    input         clear,
    input         mode,
    input         main_mode,
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .en   (en),
        .clear(clear)
    );

    counter U_Counter (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .mode (mode),
        .main_mode(main_mode),
        .en   (en),
        .clear(clear),
        .count(count)
    );

    comp_dot U_Comp_Dot (
        .count(count),
        .dot_data(dot_data)
    );
endmodule


module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         main_mode,
    input         en,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (clear) begin
                counter <= 0;
            end else begin
                if (en) begin
                    if (mode == 1'b0) begin
                        if (tick) begin
                            if (counter == 9999) begin
                                counter <= 0;
                            end else begin
                                counter <= counter + 1;
                            end
                        end
                    end else begin 
                        if (mode == 1'b1) begin
                            if (tick) begin
                                if (counter == 0) begin
                                    counter <= 9999;
                                end else begin
                                    counter <= counter - 1;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
endmodule

module clk_div_10hz (
    input  wire clk,
    input  wire reset,
    input  wire en,
    input  wire clear,
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (en) begin
                if (div_counter == 10_000_000 - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
            if (clear) begin
                div_counter <= 0;
                tick <= 1'b0;
            end
        end
    end
endmodule

module comp_dot (
    input  [13:0] count,
    output [ 3:0] dot_data
);
    assign dot_data = ((count % 10) < 5) ? 4'b1101 : 4'b1111;
endmodule