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
    input logic iLe10
);

    localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6;
    logic [2:0] state, next;

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
        case (state)
            S0: begin
                RFSrcMuxSel = 0;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 1;   //sum
                writeEn = 1;
                outBuf = 0;
                next = S1;
            end
            S1: begin
                RFSrcMuxSel = 0;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 2;    // i
                writeEn = 1;
                outBuf = 0;
                next = S2;
            end
            S2: begin
                RFSrcMuxSel = 1;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 3;    // 1
                writeEn = 1;
                outBuf = 0;
                next = S3;
            end
            S3: begin
                RFSrcMuxSel = 0;
                readAddr1 = 1;
                readAddr2 = 2;
                writeAddr = 1;
                writeEn = 1;
                outBuf = 0;
                if (iLe10) begin
                    next = S4;
                end else begin
                    next = S6;
                end
            end
            S4: begin
                RFSrcMuxSel = 0;
                readAddr1 = 2;
                readAddr2 = 3;
                writeAddr = 2;
                writeEn = 1;
                outBuf = 0;
                next = S5;
            end
            // S5: begin
            //     RFSrcMuxSel = 0;
            //     readAddr1 = 2;
            //     readAddr2 = 1;
            //     writeAddr = 2;
            //     writeEn = 1;
            //     outBuf = 0;
            //     next = S6;
            // end
            S5: begin
                RFSrcMuxSel = 1'bx;
                readAddr1 = 2;
                readAddr2 = 0;
                writeAddr = 0;
                writeEn = 0;
                outBuf = 1;
                next = S3;
            end
            S6: begin
                RFSrcMuxSel = 0;
                readAddr1 = 0;
                readAddr2 = 0;
                writeAddr = 0;
                writeEn = 0;
                outBuf = 0;
                next = S6;
            end
        endcase
    end
endmodule
