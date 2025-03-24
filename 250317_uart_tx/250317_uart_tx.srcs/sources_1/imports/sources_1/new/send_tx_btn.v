//send_tx_btn.v
`timescale 1ns / 1ps

module send_tx_btn (
    input  clk,
    input  rst,
    input  btn_start,
    output tx
);

    wire w_start, w_tx_done;
    reg [7:0] send_tx_data_reg, send_tx_data_next;

    btn_debounce U_Start_btn (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(w_start)
    );

    uart_fsm U_UART (
        .clk       (clk),               // 시스템 클럭 입력
        .rst       (rst),               // 비동기 리셋 신호
        .btn_start (w_start),           // 데이터 전송 시작 트리거
        .tx_data_in(send_tx_data_reg),
        .tx_done   (w_tx_done),
        .tx        (tx)                 // UART 송신 신호 (시리얼 출력)
    );

    // send tx ascii to PC : ascii 버튼이 눌렸을 때 아스키 코드가 나가게
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            send_tx_data_reg <= 8'h30;  //"0"; 둘 다 가능
        end else begin
            send_tx_data_reg <= send_tx_data_next;
        end
    end
    always @(*) begin
        send_tx_data_next = send_tx_data_reg;
        if (w_start == 1'b1) begin  //from debounce
            if (send_tx_data_reg == "z") begin
                send_tx_data_next = "0";
            end else begin
            send_tx_data_next = send_tx_data_reg + 1;   // increase 1 for ASCII
        end
        end
    end

endmodule