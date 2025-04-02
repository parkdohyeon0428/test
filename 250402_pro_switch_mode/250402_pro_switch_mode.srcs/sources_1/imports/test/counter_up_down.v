`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    input        rx,
    output       tx,
    output [3:0] fndCom,
    output [7:0] fndFont,
    output [1:0] state_led
);
    wire [13:0] fndData;
    wire [ 3:0] w_dot;
    wire en, clear, mode;
    wire w_run, w_stop, w_clear, w_mode, rx_done;
    wire [7:0] rx_data;

    control_unit U_CU (
        .clk(clk),
        .reset(reset),
        .rx_run(w_run),
        .rx_stop(w_stop),
        .rx_clear(w_clear),
        .rx_mode(w_mode),
        .en(en),
        .mode(mode),
        .clear(clear),
        .state_led(state_led)
    );
    uart U_Uart (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .start(rx_done),
        .tx_data(rx_data),
        .tx(tx),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    uart_cu U_Uart_CU (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .run(w_run),
        .stop(w_stop),
        .clear(w_clear),
        .mode(w_mode)
    );
    counter_up_down U_Counter (
        .clk(clk),
        .reset(reset),
        .en(en),
        .clear(clear),
        .mode(mode),
        .count(fndData),
        .dot_data(w_dot)
    );
    fndController U_FndController (
        .clk(clk),
        .reset(reset),
        .fndData(fndData),
        .fndDot(w_dot),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );
endmodule

module control_unit (
    input clk,
    input reset,
    input rx_run,
    input rx_stop,
    input rx_clear,
    input rx_mode,
    output reg en,
    output reg clear,
    output reg mode,
    output [1:0] state_led
);

    localparam STOP = 0, RUNUP = 1, RUNDOWN = 2, CLEAR = 3;
    reg [1:0] state, next;
    reg mode_next, en_next, clear_next;

    assign state_led = state;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
            mode  <= 0;
            en <= 0;
            clear <= 0;
        end else begin
            state <= next;
            mode  <= mode_next;
            en <= en_next;
            clear <= clear_next;
        end
    end

    always @(*) begin
        next = state;
        en_next = en;
        clear_next = clear;
        mode_next = mode;
        case (state)
            STOP: begin
                en_next = 1'b0;
                clear_next = 1'b0;
                if (rx_run) begin
                    if (mode == 1) begin
                        next = RUNUP;
                    end else if (mode == 0) begin
                        next = RUNDOWN;
                    end
                end else if (rx_mode) begin
                    if(mode)begin
                        mode_next = 0;
                    end else begin
                        mode_next = 1;
                    end
                end
                else if (rx_clear) begin
                    next = CLEAR;
                end
            end
            RUNUP: begin
                en_next = 1'b1;
                clear_next = 1'b0;
                mode_next = 1'b1;
                if (rx_clear) next = CLEAR;
                else if (rx_mode) next = RUNDOWN;
                else if (rx_stop) next = STOP;
            end
            RUNDOWN: begin
                en_next = 1'b1;
                clear_next = 1'b0;
                mode_next = 1'b0;
                if (rx_clear) next = CLEAR;
                else if (rx_mode) next = RUNUP;
                else if (rx_stop) next = STOP;
            end
            CLEAR: begin
                en_next = 1'b0;
                clear_next = 1'b1;
                if (rx_clear == 1'b0) next = STOP;
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
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk(clk),
        .reset(reset),
        .en(en),
        .clear(clear),
        .tick(tick)
    );

    counter U_Counter (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .clear(clear),
        .mode (mode),
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
                if (mode == 1'b1) begin
                    if (tick) begin
                        if (counter == 9999) begin
                            counter <= 0;
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                end else begin
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
endmodule

module clk_div_10hz (
    input  wire clk,
    input  wire reset,
    input       en,
    input       clear,
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

