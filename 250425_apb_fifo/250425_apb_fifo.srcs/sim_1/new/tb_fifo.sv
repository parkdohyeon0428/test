`timescale 1ns / 1ps

module tb_fifo();
    logic        PCLK;
    logic        PRESET;
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;

    // inport signals
    logic real_ready;

    FIFO_Periph dut(
    // global signal
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),

    // inport signals
        .real_ready(real_ready)
    );


    always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0;
        PRESET = 1;
        #10;
        @(posedge PCLK);
        PADDR = 8;
        PWDATA = 3;
        PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
        @(posedge PCLK);
        PSEL = 0;
        PENABLE = 0;
    end

endmodule
