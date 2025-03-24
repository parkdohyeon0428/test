`timescale 1ns / 1ps


module fsm_led(
    input clk,
    input reset,
    input [2:0] sw,
    output [1:0] led
);
    reg [1:0] r_led;
    
    assign led = r_led;

    parameter [1:0] IDLE = 2'b00, LED01 = 2'b10, LED02 = 2'b01;
 
 
    reg [1:0] state, next;

    // state를 저장

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= 0;
            //next <= 0;
        end else begin
            // 상태관리, next를 현재상태로 바꿔라
            state <= next; 
        end
    end

    // next combinational logic
    // 다음 상태로 가기위한 로직.
    always @(*) begin
        next = state;
        case (state) // 현재 상태.
            IDLE: begin
                // 다음 상태로 가기 위한 조건 
                if (sw == 3'b001) begin // next 로 가기위한 조건건
                next = LED01;
                end
            end 
            LED01: begin
                if (sw == 3'b011) begin
                    next = LED02; 
                end
            end
            LED02: begin
                if (sw == 3'b110) begin
                    next = LED01;
                end else if (sw == 3'b111) begin
                    next = IDLE;
                end else  begin
                    next = state;
                end
            end
            default: next = state;
        endcase
    end

    // output combinational logic
    always @(*) begin
        case (state)
            IDLE: begin
                r_led = 2'b00;
            end
            LED01: begin
                r_led = 2'b10;
            end 
            LED02: begin
                r_led = 2'b01;
            end
            default: begin
                r_led = 2'b00;
            end
        endcase
        
    end

endmodule
