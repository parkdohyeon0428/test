`timescale 1ns / 1ps
module Top_Upcounter (
    input clk,
    input reset,
    input [1:0] sw,
    output [3:0] seg_comm,
    output [7:0] seg
);

    wire [13:0] w_count;
    wire w_clk_10, w_run_stop, w_clear;

    assign w_run_stop = clk & sw[0];
    assign w_clear = reset | sw[1];

    clk_div_10hz U_Clk_div_10hz (
        .clk(w_run_stop),
        .reset(w_clear),
        .o_clk_10hz(w_clk_10)
    );

    counter_10000 U_counter_10000 (
        .clk(w_clk_10),
        .reset(w_clear),
        .count(w_count)
    );

    fnd_controller U_fnd_cntl (
        .clk(clk),
        .reset(reset),
        .bcd(w_count),
        .seg(seg),
        .seg_comm(seg_comm)
    );

endmodule

module clk_div_10hz (
    input  clk,
    input  reset,
    output o_clk_10hz
);

    reg [$clog2(10_000_000)-1:0] r_counter;
    reg r_clk_10hz;
    
    assign o_clk_10hz= r_clk_10hz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  // 리셋상태
            //r_clk <= 1'b0;
        end else begin
            // clock divide 계산, 
            if (r_counter == (10_000_000 - 1)) begin
                r_counter <= 0;
                r_clk_10hz <= 1'b1;
                //r_clk <= 1'b1;  // r_clk : 0->1
            end else if (r_counter == (10_000_000/2)-1) begin
                // duty radio 50%
                r_clk_10hz <= 1'b0;
                r_counter <= r_counter + 1;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
    end

endmodule

module counter_10000 (
    input clk,
    input reset,
    output [13:0] count
);
    //reg [$clog2(10000)-1:0] r_counter;
    reg [13:0] r_counter;
    assign count = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            if (r_counter == 10000 - 1) begin
                r_counter <= 0;
            end else begin
                r_counter <= r_counter + 1;
            end
            
        end
    end

endmodule
