`timescale 1ns / 1ps

module uart_cu(
    input clk,
    input reset,
    input data,
    input [7:0] command,
    output reg com_run_hour,
    output reg com_clear_start,
    output reg com_sec,
    output reg com_min
);

    reg [40:0] continue;

     always @(posedge clk or posedge reset) begin
        if (reset) begin
            com_run_hour <= 0;
            com_clear_start <= 0;
            com_sec <= 0;
            com_min <= 0;
        end else begin
            if (data) begin
                continue <= 0;
                com_run_hour <= 0;
                com_clear_start <= 0;
                com_sec <= 0;
                com_min <= 0;
            case (command)
                "R", "H": com_run_hour <= 1;
                "C", "B": com_clear_start <= 1;
                "M": com_min <= 1;
                "S": com_sec <= 1;
                
            endcase
            end else if (continue < 10000000) begin
                continue <= continue + 1;
            end else begin
                com_run_hour <= 0;
                com_clear_start <= 0;
                com_sec <= 0;
                com_min <= 0;
            end
        end
    end
endmodule 
