`timescale 1ns / 1ps

module tb_test();
    reg clk, reset, mode;
    wire [3:0] fndcom;
    wire [7:0] fndfont;

    top_counter_up_down UUT(
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .fndfont(fndfont),
        .fndcom(fndcom)
    );

    always #5 clk = ~clk;
    initial begin
        clk =0;
        reset = 1;
        mode= 0;
    #100;
    reset = 0;
    #10000000;
        mode =1;
        
        #1000;
    end


endmodule
