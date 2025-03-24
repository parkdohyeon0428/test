`timescale 1ns / 1ps
module tb;
  reg clk, rst_n, x;
  wire z;
  
  tb_fsm_moore sd(clk, rst_n, x, z);
  initial clk = 0;   
  always #2 clk = ~clk;
    
  initial begin
    x = 0;
    #10 rst_n = 0;
    #20 rst_n = 1;
    
    #10 x = 1;
    #10 x = 1;
    #10 x = 0;
    #10 x = 1;
    #10 x = 0;
    #10 x = 1;
    #10 x = 0;
    #10 x = 1;
    #10 x = 1;
    #10 x = 1;
    #10 x = 0;
    #10 x = 1;
    #10 x = 0;
    #10 x = 1;
    #10 x = 0;
    #10;
    
  end
  
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end
endmodule