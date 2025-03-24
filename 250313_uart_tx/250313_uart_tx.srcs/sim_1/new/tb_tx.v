`timescale 1ns / 1ps

module tb_tx();
    reg clk, rst, start_triger;
    wire o_tx, tx_done;


    /*uart_tx U_tx (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .start_triger(start_triger),
        .data_in(data_in),
        .o_tx(o_tx)
    ); */
    uart_fsm U_fsm(
        .clk(clk),
        .rst(rst),
        .btn_start(start_triger),
        .tx_done(tx_done),
        .tx(o_tx)
    );

    always #0.05 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start_triger = 1'b0;

        #20 rst = 1'b0;
        #10000;
        #20 start_triger = 1'b1;
        #20 start_triger = 1'b0;
        
    end
endmodule
