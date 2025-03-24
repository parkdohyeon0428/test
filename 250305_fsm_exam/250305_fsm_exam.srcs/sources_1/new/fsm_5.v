`timescale 1ns / 1ps

module fsm_5(
    input clk,
    input reset,
    input [2:0] sw,
    output [2:0] led
    );
    reg [2:0] r_led;
    assign led = r_led;
    parameter [2:0] IDLE = 3'b000, LED01 = 3'b001, LED02 = 3'b010, LED03 = 3'b100, LED04 = 3'b111;
    reg [2:0] state, next;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= 0;
        end else begin
            state <= next;
        end
    end

    always @(*) begin
        if(reset) begin
            next = state;
        end else case (state)
           IDLE : begin
                if(sw == 3'b001) begin
                    next = LED01;
                end else if (sw == 3'b010) begin
                     next = LED02;
                end else begin
                    next = state; // 클럭은 들어오니 자기자신 처리 (if else문 이면 써주기기)
                end
           end
           LED01 : begin
                if(sw == 3'b010) begin
                    next = LED02;
                end
           end
           LED02 : begin
                if(sw == 3'b100) begin
                    next = LED03;
                end
           end
           LED03 : begin
                if(sw == 3'b111) begin
                    next = LED04;
                end else if (sw == 3'b001) begin
                    next = LED01;
                end else if (sw == 3'b000) begin
                    next = IDLE; 
                end else begin
                    next = state;
                end
           end
           LED04 : begin
                if(sw == 3'b100) begin
                    next = LED03;
                end
           end
            default: next = state;
        endcase
    end

    always @(*) begin              // output logic
        case (state)
           IDLE : begin
              r_led = 3'b000;
           end
           LED01 : begin
              r_led = 3'b001;
           end
           LED02 : begin
              r_led = 3'b010;
           end
           LED03 : begin
              r_led = 3'b100;
           end
           LED04 : begin
              r_led = 3'b111;
           end
            default: begin
              r_led = 3'b000;
            end
        endcase
    end
endmodule
