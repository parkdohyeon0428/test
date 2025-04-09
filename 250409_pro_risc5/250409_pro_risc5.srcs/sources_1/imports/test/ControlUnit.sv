`timescale 1ns / 1ps

`include "define.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        RegSrcMuxSel,
    output logic        dataWe
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [3:0] signals;
    assign {regFileWe, aluSrcMuxSel, RegSrcMuxSel, dataWe} = signals;

    always_comb begin
        signals = 4'b0;
        case (opcode)
        //  {regFileWe, aluSrcMuxSel, RegSrcMuxSel, dataWe}
            `OP_TYPE_R : signals = 4'b1_0_0_0; // R-Type
            `OP_TYPE_S : signals = 4'b0_1_0_1; // S-Type
            `OP_TYPE_L : signals = 4'b1_1_1_0; // L-Type
        endcase
    end

    always_comb begin
        aluControl = 4'bx;
        case (opcode)
            `OP_TYPE_R: aluControl = operators;  // // {func7[5], func3}
            `OP_TYPE_S: aluControl = `ADD;  // // {func7[5], func3}
            `OP_TYPE_L: aluControl = `ADD;  // // {func7[5], func3}
            
        endcase
    end

endmodule
