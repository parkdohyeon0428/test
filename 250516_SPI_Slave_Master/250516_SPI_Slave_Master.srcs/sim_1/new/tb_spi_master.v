`timescale 1ns / 1ps


module tb_spi_master();

    reg clk;
    reg reset;
    reg btn;
    reg [13:0] sw;
    wire start;
    wire [7:0] tx_data;
    reg [7:0] rx_data;
    reg done;
    reg ready;
    // SPI
    // wire SCLK;
    // wire MOSI;
    // reg MISO;
    // wire CS;

    // SPI_Master dut(
    //     .clk(clk),
    //     .reset(reset),
    //     .start(start),
    //     .tx_data(tx_data),
    //     .rx_data(rx_data),
    //     .done(done),
    //     .ready(ready),
    //     .SCLK(SCLK),
    //     .MOSI(MOSI),
    //     .MISO(MISO),
    //     .CS(CS)
    // );
    SPI_Master_FSM dut(
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .sw(sw),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done(done),
        .ready(ready)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        done = 0;
        sw = 0;
        #10;
        reset = 0;
        #10;
        btn = 1;
       
        sw = 14'b11111100000011;
        #10;
        done = 1;
    end

endmodule
