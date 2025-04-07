`timescale 1ns / 1ps

module tb_counter();
    logic clk;
    logic reset;
    logic [7:0] outPort;

    Top_dedicate U_TOP_DEdi(
    .clk(clk),
    .reset(reset),
    .outPort(outPort)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10;
        reset = 0;
        
    end

endmodule
