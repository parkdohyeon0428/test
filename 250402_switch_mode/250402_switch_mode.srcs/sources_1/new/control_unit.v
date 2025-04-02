`timescale 1ns / 1ps

module control_unit(
    input clk,
    input reset,
    input [2:0] mode,
    output reg o_run,
    output reg o_clear
);
    parameter stop = 2'b00, run = 2'b01, clear = 2'b10;

    reg [1:0] state, next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= stop;
        end else begin
            state <= next;
        end
    end

    always @(*) begin
        next = state;
        case (state)     
            stop: begin
                if (mode[1] == 1) 
                    next = run;
                else if (mode[2] == 1)
                    next = clear;
                end 
            run : begin
                if (mode[1] == 0) 
                    next = stop;
                else if (mode[2] == 1)
                    next = clear;
                end
            clear : begin
                if (mode[2] == 0 && mode[1] == 0)
                    next = stop;
                else if (mode[2] == 0 && mode[1] == 1)
                    next = run;
                end
        endcase
    end

    always @(*) begin
        o_run = 0;
        o_clear = 0;
        case (state)
           stop : begin
            o_run = 0;
            o_clear = 0;
           end 
           run : begin
            o_run = 1;
            o_clear = 0;
           end
           clear : begin
            o_clear = 1;
           end
        endcase
    end
endmodule
