`timescale 1ns / 1ps

module tb_uart ();
    reg clk;
    reg reset;

    reg [7:0] tx_data;
    reg tx_start;
    wire tx_busy;
    wire tx_done;
    wire tx;

    //reg rx;
    wire [7:0] rx_data;
    wire rx_done;

    uart UUT (
        .clk(clk),
        .reset(reset),
        //tx
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx(tx),
        //rx
        .rx(tx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;

        @(posedge clk);
        #1 tx_data = 8'b11001010; tx_start = 1;
        @(posedge clk);
        #1 tx_start = 0;
        @(posedge rx_done);
        #20;
        $finish;
    end
endmodule
