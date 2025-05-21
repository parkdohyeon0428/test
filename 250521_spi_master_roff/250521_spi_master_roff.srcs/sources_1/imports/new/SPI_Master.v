`timescale 1ns / 1ps

module SPI_Master (
    // global signals
    input            clk,
    input            reset,
    input            start,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output reg       done,
    output reg       ready,
    // SPI signals
    input            cpol,     // clock polarity
    input            cpha,     // clock phase
    // external port
    output           SCLK,
    output           MOSI,
    input            MISO,
    output  reg      SS
);

    localparam IDLE = 0, CP_DELAY = 1, CP0= 2, CP1 = 3;

    //reg r_sclk;
    wire r_sclk;
    reg [2:0] state, state_next;
    reg [5:0] sclk_counter_reg, sclk_counter_next;  //6bit
    reg [2:0] bit_counter_reg, bit_counter_next;  //3bit
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;

    assign MOSI = temp_tx_data_reg[7];
    assign rx_data = temp_rx_data_reg;
    assign r_sclk = ((state_next == CP1 &&~cpha) || (state_next == CP0 && cpha));
    // cpha = 1 이면 CP0에서 SCLK가 올라가고, cpha = 0 이면 CP1에서 SCLK가 올라감
    assign SCLK = cpol ? ~r_sclk : r_sclk; 
    // cpol = 1 이면 SCLK가 반전, cpol = 0 이면 SCLK가 그대로



    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
        end
    end

    always @(*) begin
        state_next        = state;
        done              = 1'b0;
        ready             = 1'b0;
        // r_sclk            = 1'b0;
        temp_rx_data_next = temp_rx_data_reg;
        temp_tx_data_next = temp_tx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        SS = 0;
        case (state)
            IDLE: begin
                temp_tx_data_next = 0;
                done              = 1'b0;
                ready             = 1'b1;
                SS = 1;
                if (start) begin
                    state_next        = cpha ? CP_DELAY : CP0;  // cpha = 1 이면 CP_DELAY, cpha = 0 이면 CP0 
                    temp_tx_data_next = tx_data;
                    ready             = 1'b0;
                    sclk_counter_next = 1'b0;
                    bit_counter_next  = 1'b0;
                    SS = 0;
                end
            end
            CP_DELAY: begin
                SS = 0;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 1'b0;
                    state_next        = CP0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP0: begin
               // r_sclk = 1'b0;
               SS = 0;
                if (sclk_counter_reg == 49) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MISO};
                    sclk_counter_next = 1'b0;
                    state_next        = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                // r_sclk = 1'b1;
                SS = 0;
                if (sclk_counter_reg == 49) begin
                    if (bit_counter_reg == 7) begin
                        done       = 1'b1;
                        state_next = IDLE;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        sclk_counter_next = 1'b0;
                        bit_counter_next  = bit_counter_reg + 1;
                        state_next        = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule
