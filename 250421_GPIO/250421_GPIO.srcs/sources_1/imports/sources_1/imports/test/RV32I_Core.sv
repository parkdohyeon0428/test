`timescale 1ns / 1ps

module RV32I_Core (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,     // ROM 에서 가져온 명령어
    output logic [31:0] instrMemAddr,  // ROM 주소
    output logic        dataWe,        // data 접근 요청 (read/write)
    output logic [31:0] dataAddr,      // data 접근 요청 (read/write)
    output logic [31:0] dataWData,     // data 접근 요청 (read/write)
    input  logic [31:0] dataRData,     // APB에서 받은 응답 데이터
    output logic        transfer,
    input  logic        ready
);
    logic        regFileWe;
    logic [ 3:0] aluControl;
    logic        aluSrcMuxSel;
    logic [ 2:0] RFWDSrcMuxSel;
    logic        branch;
    logic        jal;
    logic        jalr;
    logic        PCEn;

    ControlUnit U_ControlUnit (.*);
    DataPath U_DataPath (.*);

endmodule
