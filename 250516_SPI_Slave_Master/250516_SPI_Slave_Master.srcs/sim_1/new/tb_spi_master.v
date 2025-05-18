`timescale 1ns / 1ps


module tb_spi_master();

    reg clk;
    reg reset;
    reg btn;
    reg [15:0] sw;
    // reg start;
    // reg [7:0] tx_data;
    // wire [7:0] rx_data;
    // wire done;
    // wire ready;
    wire SCLK;
    wire MOSI;
    reg MISO;
    wire CS;

    TOP_SPI_Master dut(
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .sw(sw),
        // .start(start),
        // .tx_data(tx_data),
        // .rx_data(rx_data),
        // .done(done),
        // .ready(ready),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS)
    );

    
    // TOP_SPI_Master dut(
    //     .clk(clk),
    //     .reset(reset),
    //     .btn(btn),
    //     .sw(sw),
    //     .SCLK(SCLK),
    //     .MOSI(MOSI),
    //     .MISO(MISO),
    //     .CS(CS)
    // );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        // start = 0;
        // tx_data = 0;
        sw = 16'hff11;
        //MISO = 0;
        #20;
        reset = 0;
        
        // 버튼 눌러 첫 전송 시작
        btn = 1;
        #20;
        btn = 0;
        //start = 1;
        #20;
        //tx_data = 8'hff;
        

    end
endmodule
