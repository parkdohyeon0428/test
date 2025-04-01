`timescale 1ns / 1ps

module tb_test();
    reg clk, reset, sw;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;

    main_top UUT(
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

    always #5 clk = ~clk;
    initial begin
        clk =0;
        reset = 1;
        sw= 0;
    #1000
    reset = 0;
    #10000000;
        sw =1;
        
        #1000;
    end


endmodule
