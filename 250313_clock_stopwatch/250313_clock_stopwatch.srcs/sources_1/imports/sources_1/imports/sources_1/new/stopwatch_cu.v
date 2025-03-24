`timescale 1ns / 1ps

module stopwatch_cu (
    input  clk,
    input  reset,
    input  i_btn_run,
    input  [1:0] sw,
    input  i_btn_clear,
    output reg o_run,
    output reg o_clear
);
    

    //fsm 구조로 CU설계
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    reg[1:0] state, next;

    // state register
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= STOP;
        end else begin
            state <= next;
        end
    end
    
    //next
    always @(*) begin
        next <= state;
        
        case (state)
           STOP :begin
              if (i_btn_run == 1 && sw[1] == 0) begin
                next <= RUN;
              end else if (i_btn_clear == 1) begin
                next <= CLEAR;
              end
           end
           RUN : begin
              if (i_btn_run == 1 && sw[1] == 0) begin
                next <= STOP;
              end
           end
           CLEAR : begin
              if (i_btn_clear == 0 && sw[1] == 0) begin
                next <= STOP;
              end
           end
        endcase
    end

    // output
    always @(*) begin
        o_run = 1'b0;
        o_clear = 1'b0;
        case (state)
           STOP : begin
              o_run = 1'b0;
              o_clear = 1'b0;
           end
           RUN : begin
             o_run = 1'b1;
             o_clear = 1'b0;
           end
           CLEAR : begin
                o_clear = 1'b1;
            end
        endcase
    end
endmodule