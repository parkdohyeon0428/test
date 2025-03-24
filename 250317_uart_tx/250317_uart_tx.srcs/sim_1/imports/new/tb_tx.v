`timescale 1ns / 1ps

module tb_tx();
    reg clk, rst, btn_start;
    wire tx;


    /*uart_tx U_tx (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .start_triger(start_triger),
        .data_in(data_in),
        .o_tx(o_tx)
    ); */
    send_tx_btn U_Send_tx (
        .clk(clk),
        .rst(rst),
        .btn_start(btn_start),
        .tx(tx)
    );

    always #0.05 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        btn_start = 1'b0;

        #20 rst = 1'b0;
        #100000;
        #100000 btn_start = 1'b1;
        #100000 btn_start = 1'b0;
        #100000 btn_start = 1'b1;
        #100000 btn_start = 1'b0;
        
    end
endmodule
