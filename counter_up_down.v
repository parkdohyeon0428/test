`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    input        rx,
    output tx,
    output [3:0] fndCom,
    output [7:0] fndFont

);
    wire [13:0] fndData;
    wire [3:0] w_dot_data;
    wire run;
    wire clear;
    wire [7:0] rx_data;
    counter_up_down U_Counter (
        .clk  (clk),
        .reset(reset),
        .mode (o_updown),
        .count(fndData),
        .run  (run),
        .clear(clear)
    );

    fndController U_FndController (
        .clk(clk),
        .reset(reset),
        .fndData(fndData),
        .fndCom(fndCom),
        .fndFont(fndFont),
        .dot_data(w_dot_data)
    );

    comp_dot u_comp_dot (
        .count   (fndData),
        .dot_data(w_dot_data)
    );
    cu u_cu (
        .run     (w_run),
        .stop    (w_stop),
        .clear   (w_clear),
        .mode    (w_updown),
        .clk     (clk),
        .reset   (reset),
        .o_updown(o_updown),
        .o_run   (run),
        .o_clear (clear)
    );

    ASCII u_ASCII (
        .data   (rx_data),
        .rx_done(rx_done),
        .clk    (clk),
        .reset  (reset),
        .run    (w_run),
        .stop   (w_stop),
        .clear  (w_clear),
        .updown (w_updown)
    );
    uart uuart (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx(rx),
        .tick(tick),
        .rx_done(rx_done)
    );
        uart_tx u_uart_tx (
        .clk    (clk),
        .reset  (reset),
        .data   (rx_data),
        .tick   (tick),
        .trigger(rx_done),
        .tx     (tx),
        .tx_done(tx_done)
    );



endmodule

module ASCII (
    input [7:0] data,
    input rx_done,
    input clk,
    input reset,
    output reg run,
    output reg stop,
    output reg clear,
    output reg updown
);


    reg run_next;
    reg stop_next;
    reg clear_next;
    reg updown_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            run <= 0;
            stop <= 0;
            clear <= 0;
            updown <= 0;
        end else begin
            run <= run_next;
            stop <= stop_next;
            clear <= clear_next;
            updown <= updown_next;
        end
    end
    always @(*) begin
        run_next = 0;
        stop_next = 0;
        clear_next = 0;
        updown_next = 0;
        if (rx_done) begin
            case (data)
                "r": run_next = 1;
                "s": stop_next = 1;
                "c": clear_next = 1;
                "u": updown_next = 1;
            endcase
        end
    end



endmodule


module comp_dot (
    input  [13:0] count,
    output [ 3:0] dot_data
);
    assign dot_data = count % 10 < 5 ? 4'b1101 : 4'b1111;
endmodule

module counter_up_down (
    input         clk,
    input         reset,
    input         run,
    input         clear,
    input         mode,
    output [13:0] count
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    counter U_Counter_Up_Down (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .mode (mode),
        .run  (run),
        .clear(clear),
        .count(count)
    );


endmodule

module cu (
    input run,
    input clear,
    input clk,
    input reset,
    input stop,
    input mode,
    output reg o_updown,
    output reg o_run,
    output reg o_clear
);

    reg [3:0] state, next;
    reg o_run_next;
    reg o_clear_next;
    reg o_updown_next;
    parameter RUN = 4'b0000, STOP = 4'b0001, CLEAR = 4'b0010;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            o_clear <= 0;
            o_run <= 0;
            o_updown <= 0;
        end else begin
            state <= next;
            o_run <= o_run_next;
            o_clear <= o_clear_next;
            o_updown <= o_updown_next;
        end
    end
    always @(*) begin
        next = state;
        o_run_next = o_run;
        o_clear_next = o_clear;
        o_updown_next = o_updown;
        case (state)
            STOP: begin
                o_run_next   = 0;
                o_clear_next = 0;
                if (clear == 1) begin
                    next = CLEAR;
                end else if (run == 1) begin
                    next = RUN;
                end
                 if (mode == 1) begin
                        if (o_updown == 1) begin
                            o_updown_next = 0;
                        end else begin
                            o_updown_next = 1;
                        end
                    end
            end
            RUN: begin
                o_run_next   = 1;
                o_clear_next = 0;
                if (clear == 1) begin
                    next = CLEAR;
                end else if (stop == 1) begin
                    next = STOP;
                end else begin
                    if (mode == 1) begin
                        if (o_updown == 1) begin
                            o_updown_next = 0;
                        end else begin
                            o_updown_next = 1;
                        end
                    end
                end
            end


            CLEAR: begin
                o_clear_next = 1;
                if (clear == 0) begin
                    next = STOP;
                end
            end

        endcase




    end
endmodule
module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         run,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (clear == 1) begin
                counter <= 0;
            end else if (run == 0) begin
                counter <= counter;
            end else begin
                if (mode == 1'b0) begin
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
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (div_counter == 10_000_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule
