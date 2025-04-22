`timescale 1ns / 1ps

module FND_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // export signals
    output logic [ 3:0] fnd_comm,
    output logic [ 7:0] fnd_font
);

    logic [7:0] FCR;
    logic [7:0] FMR;
    logic [7:0] FDR;

    APB_SlaveIntf U_APB_Intf (.*);
    GPO U_GPO(
        .FCR(FCR),
        .FMR(FMR),
        .fnd_comm(fnd_comm)
    );
    bcdtoseg U_BCD(
        .FDR(FDR),  // [3:0] sum 값
        .fnd_font(fnd_font)  // reg type 지정 (default: wire)
    );
endmodule

module APB_SlaveIntf (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic [ 7:0] FCR,
    output logic [ 7:0] FMR,
    output logic [ 7:0] FDR
    
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2; //, slv_reg3;

    assign FCR = slv_reg0[7:0];
    assign FMR = slv_reg1[7:0];
    assign FDR = slv_reg2[7:0];
    

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module GPO (
    input  logic [7:0] FCR,
    input  logic [7:0] FMR,
    //input  logic [7:0] FDR,
    output logic [3:0] fnd_comm
);

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin
            assign fnd_comm[i] = FCR[0] ? FMR[i] : 1'bz;
        end
    endgenerate

endmodule

// module docoder_2x4 (
//     input logic  [1:0] seg_sel,
//     output logic [3:0] fnd_comm
// );

//     // 2x4 decoder
//     always @(seg_sel) begin  // * : 모든 입력을 감시한다
//         case (seg_sel)
//             2'b00:   fnd_comm = 4'b1110;
//             2'b01:   fnd_comm = 4'b1101;
//             2'b10:   fnd_comm = 4'b1011;
//             2'b11:   fnd_comm = 4'b0111;
//             default: fnd_comm = 4'b1110;
//         endcase
//     end

// endmodule

module bcdtoseg (
    input  logic [3:0] FDR,  // [3:0] sum 값
    output logic [7:0] fnd_font  // reg type 지정 (default: wire)
);
    // always 구문은 출력으로 wire X, reg type을 가져야 한다
    always @(FDR) begin     // 항상 @(이벤트 대상) 감시. begin부터 end를 실행

        case (FDR)  // if문
            4'h0: fnd_font = 8'hC0;
            4'h1: fnd_font = 8'hF9;
            4'h2: fnd_font = 8'hA4;
            4'h3: fnd_font = 8'hB0;
            4'h4: fnd_font = 8'h99;
            4'h5: fnd_font = 8'h92;
            4'h6: fnd_font = 8'h82;
            4'h7: fnd_font = 8'hF8;
            4'h8: fnd_font = 8'h80;
            4'h9: fnd_font = 8'h90;
            4'hA: fnd_font = 8'h88;
            4'hB: fnd_font = 8'h83;
            4'hC: fnd_font = 8'hC6;
            4'hD: fnd_font = 8'hA1;
            4'hE: fnd_font = 8'h86;
            4'hF: fnd_font = 8'h8E;
            default: fnd_font = 8'hff;
        endcase
    end
endmodule

    /*
    always_comb begin
        for (int i=0; i<8; i++) begin
            outPort[i] = moder[i] ? odr[i] : 1'bz;
        end
    end
*/
    /*
    assign outPort = moder[0] ? odr[0] : 1'bz;
    assign outPort = moder[1] ? odr[1] : 1'bz;
    assign outPort = moder[2] ? odr[2] : 1'bz;
    assign outPort = moder[3] ? odr[3] : 1'bz;
    assign outPort = moder[4] ? odr[4] : 1'bz;
    assign outPort = moder[5] ? odr[5] : 1'bz;
    assign outPort = moder[6] ? odr[6] : 1'bz;
    assign outPort = moder[7] ? odr[7] : 1'bz;
    */
