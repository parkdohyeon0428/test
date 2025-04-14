// DataPath 모듈과 관련 서브모듈 통합 + Data Extend 추가 (LB, LH, SB, SH 지원)

`timescale 1ns / 1ps

`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    // control unit side port
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic  [2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic  [2:0] loadFunc3,   // load 시 확장 방식 제어
    input  logic  [1:0] storeFunc3,  // store 시 데이터 추출 방식 제어
    // instr memory side port
    output logic [31:0] instrMemAddr,
    input  logic [31:0] instrCode,
    // data memory side port
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData,
    input  logic [31:0] dataRData
);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] immExt, aluSrcMuxOut, RFWDSrcMuxOut;
    logic [31:0] dataRDataExt, dataWDataPacked;
    logic btaken, PC_IMM_SrcMuxSel;
    logic J_PC_SrcMuxSel;
    logic [31:0] PC_Imm_AdderResult, PC_4_AdderResult, PC_IMM_SrcMuxOut, PCSrcMuxOut;

    assign PC_IMM_SrcMuxSel = btaken & branch;
    assign J_PC_SrcMuxSel = PC_IMM_SrcMuxSel | jal;
    assign instrMemAddr = PCOutData;
    assign dataAddr     = aluResult;
    assign dataWData    = dataWDataPacked;

    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(RFWDSrcMuxOut),
        .RData1(RFData1),
        .RData2(RFData2)
    );

    mux_2x1 U_ALUSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (RFData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

    DataExtend U_DataExtend (
        .rawData(dataRData),
        .func3(loadFunc3),
        .extendedData(dataRDataExt)
    );

    StoreDataExtractor U_StoreData (
        .src(RFData2),
        .func3(storeFunc3),
        .storeData(dataWDataPacked)
    );

    mux_5x1 U_RFWDSrcMux(
        .sel(RFWDSrcMuxSel),
        .x0(aluResult),
        .x1(dataRDataExt),
        .x2(immExt),
        .x3(PC_Imm_AdderResult),
        .x4(PC_4_AdderResult),
        .y(RFWDSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a(RFData1),
        .b(aluSrcMuxOut),
        .btaken(btaken),
        .result(aluResult)
    );

    extend U_ImmExtend (
        .instrCode(instrCode),
        .immExt(immExt)
    );

    register U_PC (
        .clk(clk),
        .reset(reset),
        .d(PCSrcMuxOut),
        .q(PCOutData)
    );

    adder U_PC_Imm_Adder (
        .a(immExt),
        .b(PCOutData),
        .y(PC_Imm_AdderResult)
    );

    mux_2x1 U_PCSrcMux (
        .sel(jalr),
        .x0 (PC_IMM_SrcMuxOut),
        .x1 (aluResult),
        .y  (PCSrcMuxOut)
    );

    mux_2x1 U_PCSrc_IMM_Mux (
        .sel(J_PC_SrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PC_IMM_SrcMuxOut)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

endmodule

// 추가: DataExtend 모듈 (LB, LH 지원)
module DataExtend(
    input  logic [31:0] rawData,
    input  logic [ 2:0] func3,
    output logic [31:0] extendedData
);
    always_comb begin
        case (func3)
            3'b000: extendedData = {{24{rawData[7]}}, rawData[7:0]};   // LB
            3'b001: extendedData = {{16{rawData[15]}}, rawData[15:0]}; // LH
            3'b100: extendedData = {24'b0, rawData[7:0]};             // LBU
            3'b101: extendedData = {16'b0, rawData[15:0]};            // LHU
            default: extendedData = rawData;                          // LW or default
        endcase
    end
endmodule

// 추가: StoreDataExtractor 모듈 (SB, SH 지원)
module StoreDataExtractor(
    input  logic [31:0] src,
    input  logic [ 1:0] func3,
    output logic [31:0] storeData
);
    always_comb begin
        case (func3)
            2'b00: storeData = {24'b0, src[7:0]};    // SB
            2'b01: storeData = {16'b0, src[15:0]};   // SH
            default: storeData = src;                // SW or default
        endcase
    end
endmodule



module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        btaken,
    output logic [31:0] result
);
    always_comb begin
        case (aluControl)
            `ADD:    result = a + b;
            `SUB:    result = a - b;
            `SLL:    result = a << b;
            `SRL:    result = a >> b;
            `SRA:    result = $signed(a) >>> b[4:0];
            `SLT:    result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU:   result = (a < b) ? 1 : 0;
            `XOR:    result = a ^ b;
            `OR:     result = a | b;
            `AND:    result = a & b;
            default: result = 32'bx;
        endcase
    end

    always_comb begin : branch_processor
        btaken = 1'b0;
        case(aluControl)
            `BEQ:  btaken = (a == b);
            `BNE:  btaken = (a != b);
            `BLT:  btaken = ($signed(a) < $signed(b));
            `BGE:  btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
            default: btaken = 1'b0;
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RAddr1,
    input  logic [ 4:0] RAddr2,
    input  logic [ 4:0] WAddr,
    input  logic [31:0] WData,
    output logic [31:0] RData1,
    output logic [31:0] RData2
);
    logic [31:0] RegFile[0:2**5-1];
    initial begin
        for (int i = 0; i < 32; i++) begin
            RegFile[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        case (sel)
            1'b0:    y = x0;
            1'b1:    y = x1;
            default: y = 32'bx;
        endcase
    end
endmodule


module mux_5x1 (
    input  logic [2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin 
        case (sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
            default: y = 32'bx;
        endcase
    end
endmodule

module extend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S: immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_I:begin
                case (func3)
                    3'b001: immExt = {27'b0, instrCode[24:20]};
                    3'b101: immExt = {27'b0, instrCode[24:20]};
                    3'b011: immExt = {20'b0, instrCode[31:20]};
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B: immExt = {{20{instrCode[31]}}, instrCode[7], instrCode[30:25],instrCode[11:8],1'b0};
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};     
            `OP_TYPE_J:  immExt = {{11{instrCode[31]}}, instrCode[31], instrCode[19:12], instrCode[20], instrCode[30:21], 1'b0};
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            default: immExt = 32'bx;
        endcase
    end
endmodule
