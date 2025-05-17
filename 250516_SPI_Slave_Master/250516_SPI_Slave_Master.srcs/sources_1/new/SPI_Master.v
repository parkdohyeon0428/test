`timescale 1ns / 1ps

module TOP_SPI_Master (
    input clk,
    input reset,

    input btn,
    input [15:0] sw,

    output SCLK,
    output MOSI,
    input MISO,
    output CS
);
    wire [7:0] w_tx_data, W_rx_data;
    wire w_start, w_done, w_ready;

    SPI_Master U_spi_master(
        .clk(clk),
        .reset(reset),
        .start(w_start),
        .tx_data(w_tx_data),
        .rx_data(W_rx_data),
        .done(w_done),
        .ready(w_ready),
        //() SPI
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS)
    );
    SPI_Master_FSM U_spi_fsm(
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .sw(sw),
        .start(w_start),
        .tx_data(w_tx_data),
        .rx_data(W_rx_data),
        .done(w_done),
        .ready(w_ready)
    );
endmodule

module SPI_Master (
    input clk,
    input reset,
    input start,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg done,
    output reg ready,
    // SPI
    output reg SCLK,
    output MOSI,
    input MISO,
    output reg CS
);
    parameter IDLE = 2'b00, CP0 = 2'b01, CP1 = 2'b10;

    //reg [9:0] counter;
    reg [1:0] state, next;
    reg [7:0] temp_tx_data, temp_tx_data_next;
    //reg [5:0] sclk_counter;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg done_next, ready_next, CS_next;
    reg rx_data_next;
    reg [6:0] sclk_counter, sclk_counter_next;

    assign MOSI = temp_tx_data[7];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            //counter <= 0;
            //SCLK <= 0;
            state <= IDLE;
            temp_tx_data <= 0;
            bit_counter_reg <= 0;
            ready <= 0;
            done <= 0;
            CS <= 1;
            rx_data <= 0;
            sclk_counter <= 0;
        end else begin
            state <= next;
            temp_tx_data <= temp_tx_data_next;
            bit_counter_reg <= bit_counter_next;
            ready <= ready_next;
            done <= done_next;
            CS <= CS_next;
            rx_data <= rx_data_next;
            sclk_counter <= sclk_counter_next;
        end
    end

    always @(*) begin
            next = state;
            temp_tx_data_next = temp_tx_data;
            //sclk_counter = 0;
            ready_next = ready;
            done_next = done;
            CS_next = CS;
            bit_counter_next = bit_counter_reg;
            rx_data_next = rx_data;
            sclk_counter_next = sclk_counter;
            case (state)
                IDLE: begin
                    temp_tx_data_next = 8'hz;
                    done_next = 0;
                    CS_next = 1;
                    if (start) begin
                        temp_tx_data_next = tx_data;
                        ready_next = 0;
                        next = CP0;
                    end
                end
                CP0: begin
                    CS_next = 0;
                    SCLK = 0;
                    if (sclk_counter == 49) begin
                        rx_data_next = {rx_data[6:0], MISO};
                        next = CP1;
                        sclk_counter_next = 0;
                    end else begin
                        sclk_counter_next = sclk_counter + 1;
                        next = CP0;
                    end
                end
                CP1: begin
                    CS_next = 0;
                    SCLK = 1;
                    if (sclk_counter == 49) begin
                        sclk_counter_next = 0;
                        if (bit_counter_reg == 7) begin
                            done_next = 1;
                            ready_next = 1;
                            //CS_next =1;
                            next = IDLE;
                            sclk_counter_next = 0;
                        end else begin
                            bit_counter_next = bit_counter_reg + 1;
                            temp_tx_data_next = {temp_tx_data[6:0], 1'b0};
                            next = CP0;
                        end
                    end else begin
                        sclk_counter_next = sclk_counter + 1;
                        next = CP1;
                    end
                end
            endcase
        end
endmodule

module SPI_Master_FSM (
    input clk,
    input reset,
    input btn,
    input [15:0] sw,
    output reg start,
    output reg [7:0] tx_data,
    input [7:0] rx_data,
    input done,
    input ready
);
    parameter IDLE = 0, DOWN = 1, UP = 2;

    reg [1:0] state, next;
    reg start_next;
    reg tx_data_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            start <= 0;
            tx_data <= 0;
        end else begin
            state <= next;
            start <= start_next;
            tx_data <= tx_data_next;
        end
    end  

    always @(*) begin
        next = state;
        start_next = start;
        tx_data_next = tx_data;
        case (state)
            IDLE: begin
                if (btn) begin
                    next = DOWN;
                end
            end
            DOWN: begin
                tx_data = sw[7:0];
                start_next = 1;
                next = UP;
            end
            UP: begin
                if (done == 1) begin
                    tx_data = sw[15:8];
                    start_next = 1;
                    next = IDLE;
                end else begin
                    next = UP;
                end
            end
        endcase
    end
endmodule