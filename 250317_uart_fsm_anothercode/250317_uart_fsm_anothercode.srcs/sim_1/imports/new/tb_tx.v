`timescale 1ns / 1ps

module tb_tx();
    reg clk, rst, rx; //btn_start,
    wire tx;
    //wire w_tick, w_rx_done;
    //wire [7:0] rx_data;

    /*uart_tx U_tx (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .start_triger(start_triger),
        .data_in(data_in),
        .o_tx(o_tx)
    ); */
    /*
    send_tx_btn U_Send_tx (
        .clk(clk),
        .rst(rst),
        .btn_start(btn_start),
        .tx(tx)
    ); */
    /*
    uart_rx U_uart_rx (
        .clk(clk),  // 시스템 클럭
        .rst(rst),  // 비동기 리셋
        .tick(w_tick),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(rx_data)
    );
    baud_tick_gen U_Baud_TICK (
        .clk(clk),       // 시스템 클럭
        .rst(rst),       // 비동기 리셋
        .baud_tick(w_tick)  // Baud rate tick 신호 출력
    ); */

    TOP_UART U_top_uart(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx)
    );


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;
        #100    
        rst = 0;
        rx = 1;
        #100;
        rx = 0;
        #104160;
        rx = 1;
        #104160;
        rx = 0;
        #104160;
        rx = 1;
        #104160;
        rx = 0;
        #104160;
        rx = 1;
        #104160;
        rx = 1;
        #104160;
        rx = 0;
        #104160;
        rx = 0;
        #104160;
        rx = 1;
        #104160;


    end
endmodule

      /*
        btn_start = 1'b0;

        #20 rst = 1'b0;
        #100000;
        #100000 btn_start = 1'b1;
        #100000 btn_start = 1'b0;
        #100000 btn_start = 1'b1;
        #100000 btn_start = 1'b0;
        
    end
endmodule */
