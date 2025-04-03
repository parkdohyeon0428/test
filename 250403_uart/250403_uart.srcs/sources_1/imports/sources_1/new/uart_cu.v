`timescale 1ns / 1ps

module uart_cu(
    input clk,
    input reset,
    input [7:0] rx_data,
    input rx_done,
    output reg run,
    output reg stop,
    output reg clear,
    output reg mode
);
    reg done_prev;
    wire done_1clk;

    assign done_1clk = rx_done & ~done_prev;

     always @(posedge clk, posedge reset) begin
        if (reset) begin
            run <= 0;
            stop <= 0;
            clear <= 0;
            mode <= 0;
        end else begin
            done_prev <= rx_done;
            if (done_1clk) begin
                run <= 0;
                stop <= 0;
                clear <= 0;
                mode <= 0;
            case (rx_data)
                "r": run <= 1;
                "s": stop <= 1;
                "c": clear <= 1;
                "m": mode <= 1;
            endcase 
            end else begin
                run <= 0;
                stop <= 0;
                clear <= 0;
                mode <= 0;
            end
        end
    end    







    // always @(*) begin
    //     run   = 1'b0;
    //     stop  = 1'b0;
    //     clear = 1'b0;
    //     mode  = 1'b0;
    //     case (rx_data)
    //         "r": run = rx_done;
    //         "s": stop = rx_done;
    //         "c": clear = rx_done;
    //         "m": mode = rx_done;
    //     endcase
    // end
endmodule
