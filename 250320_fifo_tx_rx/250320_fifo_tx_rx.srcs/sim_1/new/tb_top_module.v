`timescale 1ns / 1ps

module tb_uart_fifo();
    reg clk;
    reg rst;
    reg rx;
    wire tx;

    Top_module U_top_module(
        .clk(clk),
        .reset(rst),
        .rx(rx),
        .tx(tx)
    );

    // uart_tx_done = w_tx_done
    // uart_rx_done = w_rx_done
    // fifo_tx_rdata = w_tx_data
    // fifo_rx_rdata = w_rx_data
    /////////////////
    always #5 clk = ~clk;

        initial begin
            clk = 0;
            rst = 1;
            rx = 1;

            #50 rst = 0;
            #10000;

            send_data(8'h72);
            send_data(8'h73);
            send_data(8'h74);
            send_data(8'h75);
            //wait_for_rx();

            #100000;

            //wait(uart_tx_done); //w_tx_done
            //wait(!uart_tx_done);  
        end


        // Task: 데이터 송신 시뮬레이션 (TX -> RX LoopBack)
        task send_data(input [7:0] data);
            integer i;
            begin
                $display("Sending data: %h", data);

                // Start bit (Low)
                rx = 0;
                #(10 * 10417);  // Baud Rate에 따른 시간 지연 (9600bps 기준)

                // Data bits (LSB first)
                for (i = 0; i < 8; i = i + 1) begin
                    rx = data[i];
                    #(10 * 10417);  // 각 비트 전송 시간 지연
                end

                // Stop bit (High)
                rx = 1;
                #(10 * 10417);  // 정지 비트 시간 지연

                $display("Data sent: %h", data);
            end
        endtask
/*
        task wait_for_rx();
            begin
                wait(uart_rx_done);
                if (fifo_rx_rdata !== fifo_tx_rdata) begin
                    $display
                end
            end
        endtask*/

endmodule
