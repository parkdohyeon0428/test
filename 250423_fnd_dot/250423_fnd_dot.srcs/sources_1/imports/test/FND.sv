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
    output logic [ 3:0] fndComm,
    output logic [ 7:0] fndFont
);

    logic       fcr_en;
    logic [13:0] fdr;
    logic [3:0] fpr;

    APB_SlaveIntf_FND U_APB_Intf_FND (.*);
    FND U_FND_IP (.*);
endmodule

module APB_SlaveIntf_FND (
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
    output logic        fcr_en,
    output logic [13:0] fdr,
    output logic [ 3:0] fpr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2; //, slv_reg3;

    assign fcr_en = slv_reg0[0];   // 출력 여부 사용 (1: 사용 , 0: 비활성화)
    assign fdr    = slv_reg1[13:0]; // fndFont를 통해 어떤 숫자를 표시할지 선택
    assign fpr    = slv_reg2[3:0]; // fndComm을 통해 어떤 도트트

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0; //FCR
            slv_reg1 <= 0; //FMR
            slv_reg2 <= 0; //FDR
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA; //FCR
                        2'd1: slv_reg1 <= PWDATA; //FMR
                        2'd2: slv_reg2 <= PWDATA; //FDR
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;  //FCR
                        2'd1: PRDATA <= slv_reg1;  //FMR
                        2'd2: PRDATA <= slv_reg2;  //FDR
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module FND (
    input  logic       PCLK,
    input  logic       PRESET,
    
    input  logic       fcr_en,
    input  logic [13:0]  fdr,
    input  logic [3:0] fpr,
    output logic [3:0] fndComm,
    output logic [7:0] fndFont
);


    logic [7:0] w_fndFont;
    logic [3:0] digit_1, digit_10, digit_100, digit_1000, bcd;
    logic [1:0] sel;
    logic clk, dot;

    assign fndFont = {dot, w_fndFont[6:0]};

    docoder_2x4 U_decoder(
        .sel(sel),
        .fcr_en(fcr_en),
        .fndComm(fndComm)
    );

    digit_splitter U_digit(
        .fdr(fdr),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
    );
    clk_divider U_clk_div(
        .PCLK(PCLK),
        .PRESET(PRESET),
        .o_clk(clk)
    );
    counter_4 U_counter(
        .PCLK(clk),
        .PRESET(PRESET),
        .sel(sel)
    );
    mux_4x1 U_mux(
        .sel(sel),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000),
        .bcd(bcd)
    );
    bcdtoseg U_bcd(
        .bcd(bcd),
        .fndFont(w_fndFont)
    );
    dot U_dot(
        .sel(sel),
        .fpr(fpr),
        .fndDot(dot)
    );
endmodule

module digit_splitter (
    input  logic [13:0] fdr,
    output logic [3:0] digit_1,
    output logic [3:0] digit_10,
    output logic [3:0] digit_100,
    output logic [3:0] digit_1000
);
    assign digit_1 = fdr % 10;
    assign digit_10 = fdr / 10 % 10;
    assign digit_100 = fdr / 100 % 10;
    assign digit_1000 = fdr / 1000 % 10;
endmodule

module clk_divider (
    input  logic PCLK,
    input  logic PRESET,
    output logic o_clk
);

    // reg [19:0] r_counter;
    parameter FCOUNT = 100_000 ;
    reg [$clog2(FCOUNT)-1:0] r_counter;  //$clog2 : 수의 필요한 비트수 계산
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            r_counter <= 0;  // 리셋상태
            r_clk <= 1'b0;
        end else begin
            // clock divide 계산, 100Mhz -> 100hz
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;  // r_clk : 0->1
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;  // r_clk : 1->0, 0->0 : 0으로 유지
            end
        end
    end
endmodule      
                       
                          
module counter_4 (
    input logic PCLK,
    input logic PRESET,
    output logic [1:0] sel
);

    always @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            sel <= 0;
        end else begin
            sel <= sel + 1;
        end
    end

endmodule

module docoder_2x4 (
    input logic  [1:0] sel,
    input logic        fcr_en,
    output logic [3:0] fndComm
);
    // 2x4 decoder
    always @(sel) begin  // * : 모든 입력을 감시한다
        fndComm = 4'b1111;
        if (fcr_en) begin
            case (sel)
                2'b00:   fndComm = 4'b1110;
                2'b01:   fndComm = 4'b1101;
                2'b10:   fndComm = 4'b1011;
                2'b11:   fndComm = 4'b0111;
                default: fndComm = 4'b1110;
            endcase
        end
    end

endmodule

module mux_4x1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    output logic [3:0] bcd
);

    // 이러게 안하고 위에 reg 해도 됨
    always @(sel, digit_1, digit_10, digit_100, digit_1000) begin
        case (sel)
            2'b00:   bcd = digit_1;
            2'b01:   bcd = digit_10;
            2'b10:   bcd = digit_100;
            2'b11:   bcd = digit_1000;
            default: bcd = 4'bx;
        endcase
    end

endmodule

module bcdtoseg (
    input logic [3:0] bcd,
    output logic [7:0] fndFont
);
    always_comb begin
        case(bcd)
            4'h0: fndFont = 8'hc0; //8비트의 헥사c0값
            4'h1: fndFont = 8'hF9;
            4'h2: fndFont = 8'hA4;
            4'h3: fndFont = 8'hB0;
            4'h4: fndFont = 8'h99;
            4'h5: fndFont = 8'h92;
            4'h6: fndFont = 8'h82;
            4'h7: fndFont = 8'hf8;
            4'h8: fndFont = 8'h80;
            4'h9: fndFont = 8'h90;
            default: fndFont = 8'hff;
        endcase
    end

endmodule

module dot (
    input logic [1:0] sel,
    input logic [3:0] fpr,
    output logic fndDot
);
    
    always @(*) begin
        fndDot = 1'b1;
        case (sel)
           2'b00 : fndDot = fpr[0];
           2'b01 : fndDot = fpr[1];
           2'b10 : fndDot = fpr[2];
           2'b11 : fndDot = fpr[3];
        endcase
    end
endmodule

   