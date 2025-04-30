`timescale 1ns / 1ps

module tb_fifo_rx ();
    logic        PCLK;
    logic        PRESET;
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        rx;

    UART_FIFO_RX_Periph DUT (.*);

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0;
        PRESET = 1;
        rx = 1;
        #10;
        PRESET = 0;
        rx = 0;
        #10000000;
        @(posedge PCLK);
        PADDR = 4;
        PWDATA = 3;
        PWRITE = 0;
        PSEL = 1;
        PENABLE = 1;
        @(posedge PCLK);
        PSEL = 0;
        PENABLE = 0;

        wait(PREADY);
        @(posedge PCLK);
        @(posedge PCLK);
        @(posedge PCLK);
        
        PADDR = 4;
        PWDATA = 5;
        PWRITE = 0;
        PSEL = 1;
        PENABLE = 1;
        @(posedge PCLK);
        PSEL = 0;
        PENABLE = 0;
        wait(PREADY);
    end

endmodule


