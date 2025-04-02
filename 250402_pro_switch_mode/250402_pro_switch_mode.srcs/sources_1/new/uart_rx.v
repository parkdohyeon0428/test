`timescale 1ns / 1ps
module uart (
    input  clk,
    input  reset,
    input  rx,
    input  start,
    input [7:0] tx_data,
    output tx,
    output run,
    output stop,
    output tx_done,
    output tx_busy,
    output [7:0] rx_data,
    output rx_done,
    output clear,
    output mode
);
    wire w_tick, w_rx_done;
    wire [7:0] w_rx_data;

    assign rx_data = w_rx_data;
    assign rx_done = w_rx_done;

    baud_rate U_Baud (
        .clk  (clk),
        .reset(reset),
        .tick (w_tick)
    );

    uart_rx U_Uart_Rx (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );
    uart_tx U_Uart_Tx(
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .start(start),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .o_tx(tx)
    );
    trans_assci U_Trans (
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .run(run),
        .stop(stop),
        .clear(clear),
        .mode(mode)
    );
endmodule

module uart_rx (
    input clk,
    input reset,
    input tick,
    input rx,
    output [7:0] rx_data,
    output rx_done
);

    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state, next;
    reg rx_done_reg, rx_done_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg [4:0] tick_count_reg, tick_count_next;
    reg [2:0] data_count_reg, data_count_next;

    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            rx_done_reg <= 0;
            rx_data_reg <= 0;
            tick_count_reg <= 0;
            data_count_reg <= 0;
        end else begin
            state <= next;
            rx_done_reg <= rx_done_next;
            rx_data_reg <= rx_data_next;
            tick_count_reg <= tick_count_next;
            data_count_reg <= data_count_next;
        end
    end

    always @(*) begin
        next = state;
        rx_done_next = 0;
        //rx_data_next = rx_data_reg;
        tick_count_next = tick_count_reg;
        data_count_next = data_count_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                data_count_next = 0;
                rx_done_next = 0;
                if (rx == 0) begin
                    next = START;
                end
            end
            START: begin
                if (tick == 1) begin
                    if (tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick == 1) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        rx_data_next[data_count_reg] = rx;
                        if (data_count_reg == 7) begin
                            next = STOP;
                            data_count_next = 0;
                        end else begin
                            next = DATA;
                            data_count_next = data_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1) begin
                    if (tick_count_reg == 23) begin
                        next = IDLE;
                        //rx_done_next = 0;
                        rx_done_next = 1;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module uart_tx (
    input clk,
    input reset,
    input tick,
    input start,
    input [7:0] tx_data,
    output tx_done,
    output tx_busy,
    output o_tx
);

    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state, next;
    reg [$clog2(15)-1:0] tick_count_reg, tick_count_next;
    reg [2:0] data_count_reg, data_count_next;
    reg done_reg, done_next;
    reg busy_reg, busy_next;
    reg tx, tx_next;

    assign tx_done = done_reg;
    assign tx_busy = busy_reg;
    assign o_tx = tx;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            done_reg <= 0;
            busy_reg <= 0;
            tick_count_reg <= 0;
            data_count_reg <= 0;
            tx <= 0;
        end else begin
            state <= next;
            done_reg <= done_next;
            busy_reg <= busy_next;
            tick_count_reg <= tick_count_next;
            data_count_reg <= data_count_next;
            tx <= tx_next;
        end
    end

    always @(*) begin
        next = state;
        done_next = 0;
        busy_next = busy_reg;
        tick_count_next = tick_count_reg;
        data_count_next = data_count_reg;
        tx_next = tx;
        case (state)
            IDLE: begin
                done_next = 0;
                busy_next = 0;
                tx_next   = 1;
                if (start == 1) begin
                    next = START;
                end
            end
            START: begin
                tx_next   = 0;
                busy_next = 1;
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        next = DATA;
                        data_count_next = 0;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = tx_data[data_count_reg];
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (data_count_reg == 7) begin
                            data_count_next = 0;
                            next = STOP;
                        end else begin
                            data_count_next = data_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1;
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        done_next = 1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module trans_assci (
    input [7:0] rx_data,
    input rx_done,
    output reg run,
    output reg stop,
    output reg clear,
    output reg mode
);
    always @(*) begin
        run   = 1'b0;
        stop  = 1'b0;
        clear = 1'b0;
        mode  = 1'b0;
        case (rx_data)
            "r": run = rx_done;
            "s": stop = rx_done;
            "b": clear = rx_done;
            "l": mode = rx_done;
        endcase
    end
endmodule

module baud_rate (
    input clk,
    input reset,
    output reg tick
);

    parameter FCOUNT = 100_000_000 / 9600 / 16;
    reg [$clog2(FCOUNT)-1:0] count;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            tick  <= 0;
            count <= 0;
        end else begin
            if (count == FCOUNT - 1) begin
                tick  <= 1;
                count <= 0;
            end else begin
                count <= count + 1;
                tick  <= 0;
            end
        end
    end
endmodule
