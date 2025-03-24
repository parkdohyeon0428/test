`timescale 1ns / 1ps

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
    );

    // state 
    // reg state, next;
    localparam DEBOUNCE_COUNT = 1000;

    reg [7:0] q_reg, q_next; // shift register
    reg edge_detect;
    wire btn_debounce;

    // 1khz clk
    reg [$clog2(DEBOUNCE_COUNT)-1:0] counter;   //테벤용 : 1_000_000 // 1_000 (교수님)
    reg r_1khz;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1khz <= 0;
        end else begin
            if (counter == DEBOUNCE_COUNT - 1) begin  //테벤용 : 10_000 // 1_000 (교수님)
                counter <= 0;
                r_1khz <= 1'b1;
            end else begin      // 1khz 1tick.
                // 다음번 카운트에는 현재 카운트 값에 1을 더해라
                counter <= counter + 1;
                r_1khz <= 1'b0;   
            end 
        end
    end

    // state logic, shift register
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    // next logic
    always @(i_btn, r_1khz) begin
            // q_reg 현재의 상위 7비트를 다음 하위 7비트에 넣고, 
            // 최상에는 i_btn을 넣어라
            q_next = {i_btn, q_reg[7:1]};      // 8shift의 동작 설명
    end

    //8input AND gate
    assign btn_debounce =  & q_reg;

    // edge _ detector , 100Mhz
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 1'b0;
        end else begin
            edge_detect <= btn_debounce;
        end
    end
    // 최종 출력
    assign o_btn = btn_debounce & (~edge_detect);

endmodule
