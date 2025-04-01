`timescale 1ns / 1ps

module tb_test();
    reg clk, reset, mode;
    wire [3:0] seg_comm;
    wire [7:0] seg_font;

    top_counter_up_down UUT(
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .seg_font(seg_font),
        .seg_comm(seg_comm)
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
