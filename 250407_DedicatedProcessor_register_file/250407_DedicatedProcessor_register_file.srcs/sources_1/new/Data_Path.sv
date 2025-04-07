`timescale 1ns / 1ps

module Data_Path (
    input logic clk,
    input logic reset,
    input logic RFSrcMuxSel,
    input logic [2:0] readAddr1,
    input logic [2:0] readAddr2,
    input logic [2:0] writeAddr,
    input logic writeEn,
    input logic outBuf,
    output logic iLe10,
    output logic [7:0] outPort 
);  
    logic [7:0] w_WData, w_RData1, w_RData2, w_sum;

    mux_2x1 U_Mux(
        .RFSrcMuxSel(RFSrcMuxSel),
        .a(1),
        .b(w_sum),
        .sum(w_WData)
    );
    Regfile U_Register(
        .clk(clk),
        .readAddr1(readAddr1),
        .readAddr2(readAddr2),
        .writeAddr(writeAddr),
        .writeEn(writeEn),
        .wData(w_WData),
        .rData1(w_RData1),
        .rData2(w_RData2)
    );
    adder U_Adder(
        .rData1(w_RData1),
        .rData2(w_RData2),
        .add_Data(w_sum)
    );
    comparator U_Comp(
        .rData1(w_RData1),
        .b(10),
        .lt(iLe10)
    );

    assign outPort = outBuf ? w_RData1 : 8'bz;

endmodule

module mux_2x1 (
    input logic RFSrcMuxSel,
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum
);
    always_comb begin
        sum = 1'b1;
        case (RFSrcMuxSel)
            1: sum = a;
            0: sum = b; 
        endcase
    end
endmodule

module Regfile (
    input  logic       clk,
    input  logic [2:0] readAddr1,
    input  logic [2:0] readAddr2,
    input  logic [2:0] writeAddr,
    input  logic       writeEn,
    input  logic [7:0] wData,
    output logic [7:0] rData1,
    output logic [7:0] rData2
);
    logic [7:0] mem[0:7];

    always_ff @( posedge clk ) begin : write
        if (writeEn) begin
            mem[writeAddr] <= wData;
        end
    end

    assign rData1 = (readAddr1 == 3'b0) ? 8'b0 : mem[readAddr1];
    assign rData2 = (readAddr2 == 3'b0) ? 8'b0 : mem[readAddr2];
    
endmodule

module adder (
    input logic [7:0] rData1,
    input logic [7:0] rData2,
    output logic [7:0] add_Data
);
    assign add_Data = rData1 + rData2;
endmodule

module comparator (
    input logic [7:0] rData1,
    input logic [7:0] b,
    output logic lt
);
    assign lt = (rData1 <= b);
endmodule

