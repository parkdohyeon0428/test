//send_tx_btn.v
`timescale 1ns / 1ps


module send_tx_btn (
    input  clk,
    input  rst,
    input  btn_start,
    output tx

);
    parameter IDLE = 0, START = 1, SEND = 2;
    reg [1:0] state, next;  // send char fsm state
    reg [7:0] send_tx_data_reg, send_tx_data_next;
    reg send_reg, send_next;  // start trigger 출력
    reg [3:0] send_count_reg, send_count_next;  // send data count
    wire w_start, w_tx_done;

    btn_debounce U_Start_btn (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(w_start)
    );

    uart_fsm U_UART (
        .clk       (clk),               // 시스템 클럭 입력
        .rst       (rst),               // 비동기 리셋 신호
        .btn_start (send_reg),          // 데이터 전송 시작 트리거
        .tx_data_in(send_tx_data_reg),
        .tx_done   (w_tx_done),
        .tx        (tx)                 // UART 송신 신호 (시리얼 출력)
    );

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            send_tx_data_reg <= 8'h30;
            state <= IDLE;  //"0"; 둘 다 가능
            send_reg <= 1'b0;
            send_count_reg <= 4'b0;
        end else begin
            send_tx_data_reg <= send_tx_data_next;
            state <= next;
            send_reg <= send_next;
            send_count_reg <= send_count_next;
        end
    end
    always @(*) begin
        send_tx_data_next = send_tx_data_reg;
        next = state;
        send_next = 1'b0;  // for 1 tick, 많이 할거면 send_reg
        send_count_next = send_count_reg;
        case (state)
            IDLE: begin
                send_next = 1'b0;
                send_count_next = 0;
                if (w_start == 1'b1) begin  //from debounce
                    next = START;
                    send_next = 1'b1;
                end
            end
            START: begin
                send_next = 1'b0;
                if (w_tx_done == 1'b1) begin
                    next = SEND;
                end
            end
            SEND: begin
                if (w_tx_done == 1'b0) begin
                    send_next = 1'b1;
                    send_count_next = send_count_reg + 1;
                    if (send_count_reg == 15) begin
                        next = IDLE;
                    end else begin
                        next = START;
                    end
                    // w_tx_done이 low로 떨어진 다음에 1번만 증기 시키기 위함.
                    if (send_tx_data_reg == "z") begin
                        send_tx_data_next = "0";
                    end else begin
                        send_tx_data_next = send_tx_data_reg + 1;   // increase 1 for ASCII
                    end
                end
            end
        endcase
    end


endmodule

