`timescale 1ns / 1ps


module tb_test ();
    logic       clk;
    logic       reset;
    logic [7:0] outPort;

    Top_dedicate dut(
    .*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        #10; reset = 0;
        //wait(outPort = 8'd55);
    end
endmodule
