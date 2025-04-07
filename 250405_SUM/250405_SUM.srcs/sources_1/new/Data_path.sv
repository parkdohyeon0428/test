`timescale 1ns / 1ps

module Data_path(
    input logic clk,
    input logic reset,
    input logic AsrcSel,
    input logic AEn,
    output logic Alt11,
    input logic outBuf,
    output logic [7:0] OutPort
    );

    logic [7:0] w_d, w_q, w_sum, w_a_d, w_a_q, w_a_sum;  

    mux_sum_2x1 U_Mux_Sum(
        .a(0),
        .sum(w_sum),
        .AsrcSel(AsrcSel),
        .d(w_d)
    );
    register_sum U_Regi(
        .clk(clk),
        .reset(reset),
        .d(w_d),
        .AEn(AEn),
        .q(w_q)
    );
    sum_adder U_Sum_Adder(
        .a(w_q),
        .b(w_a_sum),
        .sum(w_sum)
    );
    mux_a_2x1 U_A_Mux(
        .zero(0),
        .a(w_a_sum),
        .AsrcSel(AsrcSel),
        .a_d(w_a_d) 
    );
    register_a U_Regi_A(
        .clk(clk),
        .reset(reset),
        .AEn(AEn),
        .a_d(w_a_d),
        .a_q(w_a_q)
    );
    adder_a U_Adder_A(
        .a(w_a_q),
        .b(1),
        .a_sum(w_a_sum)
    );
    comparator U_Compara(
        .a(w_a_q),
        .b(10),
        .Alt11(Alt11)
    );
    OutBuf U_OUTBUF(
        .clk(clk),
        .reset(reset),
        .outBuf(outBuf),
        .q(w_sum),
        .o_q(OutPort)
    );
endmodule

module mux_sum_2x1 (
    input logic a,
    input logic [7:0] sum,
    input logic AsrcSel,
    output logic [7:0] d
);
    always @(*) begin
        d = a;
        case (AsrcSel)
            0: d = a;
            1: d = sum;
        endcase
    end
endmodule

module register_sum (
    input clk,
    input reset,
    input logic [7:0] d,
    input logic AEn,
    output logic [7:0] q
);
    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (AEn) begin
                q <= d;
            end
        end
    end
endmodule

module sum_adder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    assign sum = a + b;    
endmodule

module mux_a_2x1 (
    input logic zero,
    input logic [7:0] a,
    input logic AsrcSel,
    output logic [7:0] a_d 
);
    always @(*) begin
        a_d = zero;
        case (AsrcSel)
            0: a_d = zero;
            1: a_d = a; 
        endcase
    end
endmodule

module register_a (
    input logic clk,
    input logic reset,
    input logic AEn,
    input logic [7:0] a_d,
    output logic [7:0] a_q
);
    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            a_q <= 0;
        end else begin
            if (AEn) begin
                a_q <= a_d;
            end
        end
    end
endmodule

module adder_a (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] a_sum
);
    assign a_sum = a + b;
endmodule

module comparator (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic Alt11
);
    assign Alt11 = (a < b);
endmodule

module OutBuf (
    input logic clk,
    input logic reset,
    input logic outBuf,
    input logic [7:0] q,
    output logic [7:0] o_q
);
    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            o_q <= 0;
        end else begin
            if (outBuf) begin
                o_q <= q;
            end
        end
    end
endmodule
