`timescale 1ns / 1ps

module fsm_r();
    reg clk,reset,din_bit;
    wire dout_bit;

    fsm_rd0 dut (
    .clk(clk),
    .reset(reset),
    .din_bit(din_bit),
    .dout_bit(dout_bit)
    );

    
    initial begin
        clk =0;
        forever begin
             clk = ~clk; 
             #1;
        end
    end
    initial begin
        
        din_bit = 0;
        reset = 1; 
        #5 reset = 0;  
        
        
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 1;
        @(posedge clk) din_bit = 0;
        @(posedge clk) din_bit = 0;

        
        #20;
       
    end
endmodule


// 교수님 버전
  //  (forever, always 상관없음) #5 clk = ~clk;