`timescale 1ns / 1ps

module SPI_Master (
    // global signals
    input            clk,
    input            reset,
    // internal signals
    input            CPOL,
    input            CPHA,
    input            start,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output reg       done,
    output reg       ready,
    // external port
    output           SCLK,
    output           MOSI,
    input            MISO
);
    localparam IDLE = 0, CP_DELAY = 1, CP0 = 2, CP1 = 3;

    wire r_sclk;
    reg [1:0] state, next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [5:0] sclk_counter_next, sclk_counter_reg;
    reg [2:0] bit_counter_next, bit_counter_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;

    //assign tx_data = temp_tx_data_reg;
    assign MOSI = temp_tx_data_reg[7];
    assign rx_data = temp_rx_data_reg;

    assign r_sclk = ((next == CP1) && ~CPHA) || 
                    ((next == CP0) && CPHA);
    assign SCLK = CPOL ? ~r_sclk : r_sclk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
        end else begin
            state            <= next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
        end
    end

    always @(*) begin
        next              = state;
        ready             = 0;
        done              = 0;
        temp_rx_data_next = temp_rx_data_reg;
        temp_tx_data_next = temp_tx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        case (state)
            IDLE: begin
                temp_tx_data_next = 0;
                ready             = 1;
                done              = 0;
                if (start) begin
                    next = CPHA ? CP_DELAY : CP0; // 삼항연산자 잘 쓰기
                    temp_tx_data_next = tx_data;
                    ready = 0;
                    sclk_counter_next = 0;
                    bit_counter_next = 0;
                end
            end
            CP_DELAY: begin
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 0;
                    next = CP0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP0: begin
                if (sclk_counter_reg == 49) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MISO};
                    sclk_counter_next = 0;
                    next = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                if (sclk_counter_reg == 49) begin
                    if (bit_counter_reg == 7) begin
                        done = 1;
                        bit_counter_next = 0;
                        next = IDLE;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        sclk_counter_next = 0;
                        bit_counter_next = bit_counter_reg + 1;
                        next = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule
