`timescale 1ns / 1ps

module fsm_rd0(
    input clk,
    input reset,
    input din_bit,
    output reg dout_bit
    );
    reg [2:0] state, next;
    parameter start = 3'b000, rd0_once = 3'b001, rd1_once = 3'b010, rd0_twice = 3'b011, rd1_twice = 3'b100;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= start;
        end else begin
            state <= next;
        end
    end 
    
    always @(*) begin
        next = state;
        case (state)
           start : begin
            if (din_bit == 0) begin
                next = rd0_once;
            end else if (din_bit == 1) begin
                next = rd1_once;
            end else begin
                next = state;
            end
           end
           rd0_once : begin
            if (din_bit == 1) begin
                next = rd1_once;
            end else if (din_bit == 0) begin
                next = rd0_twice;
            end else begin
                next = state;
            end
           end
           rd0_twice : begin
            if (din_bit == 1) begin
                next = rd1_once;
            end else if (din_bit == 0) begin
                next = rd0_twice;
            end else begin
                next = state;
            end
           end
           rd1_once : begin
            if (din_bit == 1) begin
                next = rd1_twice;
            end else if (din_bit == 0) begin
                next = rd0_once;
            end else begin
                next = state;
            end
           end
           rd1_twice : begin
            if (din_bit == 1) begin
                next = rd1_twice;
            end else if (din_bit == 0) begin
                next = rd0_once;
            end else begin
                next = state;
            end
           end
            default: next = start;
        endcase
    end
    
    always @(*) begin
        case (state)
           start : begin
            if (din_bit == 0) begin
                dout_bit = 0;
            end else if (din_bit == 1) begin
                dout_bit = 0;
            end else begin
                dout_bit = 0;
            end
           end
           rd0_once : begin
            if (din_bit == 0) begin
                dout_bit = 1;
            end else if (din_bit == 1) begin
                dout_bit = 0;
            end else begin
                dout_bit = 0;
            end
           end
           rd0_twice : begin
            if (din_bit == 0) begin
                dout_bit = 1;
            end else if (din_bit == 1) begin
                dout_bit = 0;
            end else begin
                dout_bit = 0;
            end
           end
           rd1_once : begin
            if (din_bit == 1) begin
                dout_bit = 1;
            end else if (din_bit == 0) begin
                dout_bit = 0;
            end else begin
                dout_bit = 0;
            end
           end
           rd1_twice : begin
            if (din_bit == 1) begin
                dout_bit = 1;
            end else if (din_bit == 0) begin
                dout_bit = 0;
            end else begin
                dout_bit = 0;
            end
           end
        endcase
    end



endmodule
