`timescale 1ns / 1ps

module tb_SPI();

    reg clk;
    reg reset;
    reg btn;
    reg [15:0] sw;
    wire [3:0] fndcom;
    wire [7:0] fndfont;    
    
    SPI dut(
    .clk(clk),
    .reset(reset),
    .btn(btn),
    .sw(sw),
    .fndcom(fndcom),
    .fndfont(fndfont)
    );
    
    always #5 clk = ~clk;
    

    initial begin
        clk = 0;
        reset = 1;
        btn = 0;
        sw = 0;
        #10;
        reset = 0;
        sw = 16'h1234;
        #10;
        btn = 1;
        #10;
        btn = 0;

    end

endmodule
