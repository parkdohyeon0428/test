`timescale 1ns / 1ps

module spi(
        // global signals
    input            clk,
    input            reset,
    input            start,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output           done,
    output           ready,
    // SPI signals
    input            cpol,     // clock polarity
    input            cpha     // clock phase
);
    wire SCLK, MOSI, MISO, SS;

    SPI_Master dut(
    // global signals
        .clk(clk),
        .reset(reset),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done(done),
        .ready(ready),
    // SPI signals
        .cpol(cpol),     // clock polarity
        .cpha(cpha),     // clock phase
    // external port
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .SS(SS)
    );

    SPI_Slave dutt(

    //global signals
        .clk(clk),
        .reset(reset),
    //SPI signals
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .SS(SS)
    );
endmodule
