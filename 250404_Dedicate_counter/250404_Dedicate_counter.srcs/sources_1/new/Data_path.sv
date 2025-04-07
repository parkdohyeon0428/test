`timescale 1ns / 1ps

module Data_path(
    input logic clk,
    input logic reset,
    input logic AsrcSel,
    input logic en,
    output logic alt10,
    input logic outbuf,
    output logic [7:0] outPort
);
    logic [7:0] w_d, w_q, w_sum;

    mux_2x1 U_mux(
        .a(0),
        .sum(w_sum),
        .AsrcSel(AsrcSel),
        .d(w_d)
    );
    out_buffer U_outBuf(
        .clk(clk),
        .reset(reset),
        .data(w_q),
        .OutBuf(outbuf),
        .o_data(outPort)
    );
    register U_regi(
        .clk(clk),
        .reset(reset),
        .en(en),
        .d(w_d),
        .q(w_q)
    );
    adder U_Adder(
        .a(w_q),
        .b(1),
        .sum(w_sum)
    );
    comparator U_compara(
        .a(w_q),
        .b(10),
        .lt(alt10)
    );
endmodule

module mux_2x1 (
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

module out_buffer (
    input logic clk,
    input logic reset,
    input logic [7:0] data,
    input logic OutBuf,
    output logic [7:0] o_data
);
    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            o_data <= 0;
        end else begin
            if (OutBuf) begin
                o_data <= data;
            end
        end 
    end
endmodule 

module register (
    input logic clk,
    input logic reset,
    input logic en,
    input logic [7:0] d,
    output logic [7:0] q
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) begin
                q <= d;
            end
        end
    end
endmodule

module adder (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;
endmodule


module comparator (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic lt
);
    assign lt = a < b;
endmodule

