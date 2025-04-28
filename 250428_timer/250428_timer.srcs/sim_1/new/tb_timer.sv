`timescale 1ns / 1ps

module tb_timer ();
    logic        PCLK;
    logic        PRESET;
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic [31:0] count_data;

    timer_Periph dut(
    // global signal
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PRDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .count_data(count_data)
    );

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0;
        PRESET = 1;
        #10;
        PRESET = 0;
        PADDR = 0;
        PWRITE = 1;
        PENABLE = 1;
        PSEL = 1;
        wait(PREADY);
    end


endmodule
