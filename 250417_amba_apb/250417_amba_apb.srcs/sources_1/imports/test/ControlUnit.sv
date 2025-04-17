`timescale 1ns / 1ps

`include "defines.sv"

module ControlUnit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        PCEn
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [9:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, branch, jal, jalr, PCEn} = signals;

    parameter Fetch = 0, Decode = 1;
    parameter R_EXE = 2, I_EXE = 3, S_EXE = 4 , L_EXE = 5, B_EXE = 6, LU_EXE = 7, AU_EXE = 8, J_EXE = 9, JL_EXE = 10;
    parameter S_MemAcc = 11, L_MemAcc = 12, L_WBack = 13;

    logic [3:0] state, next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= Fetch;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        next = state;
        signals = 10'b0;
        case (state)
            Fetch: begin
                signals = 10'b0_0_0_000_0_0_0_1;
                next = Decode;
            end
            Decode: begin
                signals = 10'b0_0_0_000_0_0_0_0;
                case (opcode)
                    `OP_TYPE_R:  next = R_EXE;
                    `OP_TYPE_I:  next = I_EXE;
                    `OP_TYPE_S:  next = S_EXE;
                    `OP_TYPE_L:  next = L_EXE;
                    `OP_TYPE_B:  next = B_EXE;
                    `OP_TYPE_LU: next = LU_EXE;
                    `OP_TYPE_AU: next = AU_EXE;
                    `OP_TYPE_J:  next = J_EXE;
                    `OP_TYPE_JL: next = JL_EXE;
                endcase
            end
            //exe
            R_EXE: begin
                signals = 10'b1_0_0_000_0_0_0_0;
                next = Fetch;
                aluControl = operators;
            end
            I_EXE: begin
                signals = 10'b1_1_0_000_0_0_0_0;
                next = Fetch;
                if (operators == 4'b1101)
                     aluControl = operators;  // {1'b1, func3}
                else aluControl = {1'b0, operators[2:0]};
            end
            S_EXE: begin
                signals = 10'b0_1_0_000_0_0_0_0;
                next = S_MemAcc;
                aluControl = `ADD;
            end
            L_EXE: begin
                signals = 10'b1_1_0_001_0_0_0_0;
                next = L_MemAcc;
                aluControl = `ADD;
            end
            B_EXE: begin
                signals = 10'b0_0_0_000_1_0_0_0;
                next = Fetch;
                aluControl = operators;
            end
            LU_EXE: begin
                signals = 10'b1_0_0_010_0_0_0_0;
                next = Fetch;
                aluControl = operators;
            end
            AU_EXE: begin
                signals = 10'b1_0_0_011_0_0_0_0;
                next = Fetch;
                aluControl = operators;
            end
            J_EXE: begin
                signals = 10'b1_0_0_100_0_1_0_0;
                next = Fetch;
                aluControl = operators;
            end
            JL_EXE: begin
                signals = 10'b1_0_0_100_0_1_1_0;
                next = Fetch;
                aluControl = `ADD;
            end
            //memAcc
            S_MemAcc: begin
                signals = 10'b0_0_1_000_0_0_0_0;
                next = Fetch;
            end
            L_MemAcc: begin
                signals = 10'b0_0_0_000_0_0_0_0;
                next = L_WBack;
            end
            //write back
            L_WBack: begin
                signals = 10'b1_0_0_001_0_0_0_0;
                next = Fetch;
            end
        endcase
    end

    /*
    always_comb begin
        signals = 10'b0;
        case (opcode)
            // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel(3), branch, jal, jalr, PCEn} = signals
            `OP_TYPE_R:  signals = 10'b1_0_0_000_0_0_0_1;
            `OP_TYPE_I:  signals = 10'b1_1_0_000_0_0_0_1;
            `OP_TYPE_S:  signals = 10'b0_1_1_000_0_0_0_1;
            `OP_TYPE_L:  signals = 10'b1_1_0_001_0_0_0_1;
            `OP_TYPE_B:  signals = 10'b0_0_0_000_1_0_0_1;
            `OP_TYPE_LU: signals = 10'b1_0_0_010_0_0_0_1;
            `OP_TYPE_AU: signals = 10'b1_0_0_011_0_0_0_1;
            `OP_TYPE_J:  signals = 10'b1_0_0_100_0_1_0_1;
            `OP_TYPE_JL: signals = 10'b1_0_0_100_0_1_1_1;
        endcase
    end */

    // always_comb begin
    //     aluControl = 4'bx;
    //     case (opcode)
    //         `OP_TYPE_S: aluControl = `ADD;
    //         `OP_TYPE_L: aluControl = `ADD;
    //         `OP_TYPE_JL: aluControl = `ADD;  // {func7[5], func3}
    //         `OP_TYPE_I: begin
    //             if (operators == 4'b1101)
    //                 aluControl = operators;  // {1'b1, func3}
    //             else aluControl = {1'b0, operators[2:0]};  // {1'b0, func3}
    //         end
    //         default: aluControl = operators;  // {func7[5], func3}
    //         // `OP_TYPE_R:  aluControl = operators;  // {func7[5], func3}
    //         // `OP_TYPE_B:  aluControl = operators;  // {func7[5], func3}
    //         // `OP_TYPE_LU: aluControl = operators;  // {func7[5], func3}
    //         // `OP_TYPE_AU: aluControl = operators;  // {func7[5], func3}
    //         // `OP_TYPE_J:  aluControl = operators;  // {func7[5], func3}
    //     endcase
    // end
endmodule
