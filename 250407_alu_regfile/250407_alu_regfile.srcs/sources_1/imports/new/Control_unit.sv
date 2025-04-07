`timescale 1ns / 1ps

module Control_unit(
    input logic clk,
    input logic reset,
    output logic RFSrcMuxSel,
    output logic [2:0] readAddr1,
    output logic [2:0] readAddr2,
    output logic [2:0] writeAddr,
    output logic writeEn,
    output logic outBuf,
    output logic [2:0] aluOP,
    input logic iLe10
);

    localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6, S7 = 7, S8 = 8,
               S9 = 9, S10 = 10, S11 = 11;
    logic [3:0] state, next;

    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            state <= S0;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        RFSrcMuxSel = 0;
        readAddr1 = 0;
        readAddr2 = 0;
        writeAddr = 0;
        writeEn = 0;
        outBuf = 0;
        aluOP = 0;
        case (state)
            S0: begin
                RFSrcMuxSel = 1;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 1;   // R1(1)
                writeEn = 1;
                outBuf = 0;
                aluOP = 0;
                next = S1;
            end
            S1: begin
                RFSrcMuxSel = 0;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 2;    // R2(0)
                writeEn = 1;
                outBuf = 0;
                aluOP = 0;
                next = S2;
            end
            S2: begin
                RFSrcMuxSel = 0;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 3;    // R3(0)
                writeEn = 1;
                outBuf = 0;
                aluOP = 0;
                next = S3;
            end
            S3: begin
                RFSrcMuxSel = 0;
                readAddr1 = 1;
                readAddr2 = 1;
                writeAddr = 4;   //R4 sum
                writeEn = 1;
                outBuf = 1;
                aluOP = 0;
                next = S4;
            end
            S4: begin
                RFSrcMuxSel = 0;
                readAddr1 = 4;
                readAddr2 = 4;
                writeAddr = 5;    //R5 sum
                writeEn = 1;
                outBuf = 1;
                aluOP = 0;
                next = S5;
            end
            S5: begin
                RFSrcMuxSel = 0;
                readAddr1 = 5;
                readAddr2 = 1;
                writeAddr = 6;    //R6 -
                writeEn = 1;
                outBuf = 1;
                aluOP = 1;
                next = S6;
            end
            S6: begin
                RFSrcMuxSel = 0;
                readAddr1 = 6;
                readAddr2 = 4;
                writeAddr = 2;   //R2
                writeEn = 1;
                outBuf = 1;
                aluOP = 2;
                next = S7;
            end
            S7: begin
                RFSrcMuxSel = 0;
                readAddr1 = 2;
                readAddr2 = 5;
                writeAddr = 3;   //R3
                writeEn = 1;
                outBuf = 1;
                aluOP = 3;
                next = S8;
            end
            S8: begin
                RFSrcMuxSel = 0;
                readAddr1 = 3;
                readAddr2 = 2;
                writeAddr = 7;   //R7
                writeEn = 1;
                outBuf = 1;
                aluOP = 4;
                next = S9;
            end
            S9: begin
                RFSrcMuxSel = 0;
                readAddr1 = 7;
                readAddr2 = 0;
                writeAddr = 4;    //not
                writeEn = 1;
                outBuf = 1;
                aluOP = 5;
                next = S10;
            end
            S10: begin
                RFSrcMuxSel = 0;
                readAddr1 = 7;
                readAddr2 = 4;
                writeAddr = 0;          //ip
                writeEn = 0;
                outBuf = 0;
                aluOP = 0;
                if (iLe10) begin
                    next = S4;
                end else begin
                    next = S11;
                end
            end
            S11: begin
                RFSrcMuxSel = 0;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 0;
                writeEn = 0;
                outBuf = 0;
                aluOP = 0;
                next = S11;
            end
        endcase
    end
endmodule
