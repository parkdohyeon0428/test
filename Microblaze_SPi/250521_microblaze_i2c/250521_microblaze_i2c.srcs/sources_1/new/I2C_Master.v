`timescale 1ns / 1ps

module I2C_Master (
    input clk,
    input reset,

    input [7:0] tx_data,
    output tx_done,
    output ready,
    input start,
    input i2c_en,
    input stop,

    output reg SCL,
    output reg SDA
);
    localparam IDLE = 0, START1 = 1, START2 = 2, DATA1 = 3, DATA2 = 4,
                DATA3 = 5, DATA4 = 6, STOP1 = 7, STOP2 = 8;

    reg [3:0] state, next;
    reg [7:0] temp_tx_data, temp_tx_data_next;
    reg [8:0] clk_counter_reg, clk_counter_next;
    reg [2:0] bit_counter_reg, bit_counter_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            temp_tx_data <= 0;
            clk_counter_reg <= 0;
            bit_counter_reg <= 0;
        end else begin
            state           <= next;
            temp_tx_data    <= temp_tx_data_next;
            clk_counter_reg <= clk_counter_next;
            bit_counter_reg <= bit_counter_next;
        end
    end

    always @(*) begin
        next              = state;
        temp_tx_data_next = temp_tx_data;
        clk_counter_next  = clk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        SDA = 0;
        SCL = 0;
        case (state)
            IDLE: begin
                SDA = 1;
                SCL = 1;
                if (start) begin
                    temp_tx_data_next = tx_data;
                    next = START1;
                end 
            end
            START1: begin
                SDA = 0;
                SCL = 1;
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    next = START2;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            START2: begin
                SDA = 0;
                SCL = 0;
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    next = DATA1;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA1: begin
                SDA = temp_tx_data[7];
                SCL = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next = DATA2;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA2: begin
                SDA = temp_tx_data[7];
                SCL = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next = DATA3;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA3: begin
                SDA = temp_tx_data[7];
                SCL = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next = DATA4;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA4: begin
                SDA = temp_tx_data[7];
                SCL = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    if (bit_counter_reg == 7) begin
                        
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        temp_tx_data_next = {tx_data[6:0], 1'b0};
                        next = DATA1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            STOP1: begin
                
            end
            STOP2: begin
                
            end
        endcase
    end
endmodule
