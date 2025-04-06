`timescale 1ns / 1ps

module tb_sum();
    logic clk;
    logic reset;
    logic [7:0] OutPort;

    Top_SUM U_SUM(
        .clk(clk),
        .reset(reset),
        .OutPort(OutPort)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10
        reset = 0;
        
    end

endmodule
