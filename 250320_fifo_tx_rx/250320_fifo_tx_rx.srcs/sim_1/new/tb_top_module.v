`timescale 1ns / 1ps

module tb_uart_fifo();
    reg clk;
    reg reset;
    reg rx;
    reg [1:0] sw;
    reg btn_run_hour;
    reg btn_clear_start;
    reg btn_sec;
    reg btn_min;
    wire tx;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;
    wire [1:0] led;

    Real_Top U_real (
        .clk(clk),
        .reset(reset),
        .tx(tx),
        .sw(sw),
        .btn_run_hour(btn_run_hour),
        .btn_clear_start(btn_clear_start),
        .btn_sec(btn_sec),
        .btn_min(btn_min),
        .rx(rx),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font),
        .led(led)
    );
    always #5 clk = ~clk;

        initial begin
            clk = 0;
            reset= 1;
            rx = 1;
            sw = 2'b00;
            btn_run_hour = 0;
            btn_clear_start = 0;
            btn_min = 0;
            btn_sec = 0;

            #50 reset = 0;
            #1;

            send_data(8'h52); // "R" run
            send_data(8'h43); // "C" clear
            sw = 2'b10;       // 시계 모드
            send_data(8'h42); // "B" start
            send_data(8'h53); // "S" sec 증가
            send_data(8'h4D); // "M" min 증가
            send_data(8'h48); // "H" hour 증가

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
