`timescale 1ns / 1ps

module Uart_Periph(
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
    // inport signals
    output logic        TX,
    input  logic        RX
);

    logic [31:0] UCS; // full, empty
    logic [31:0] UTD; // tx fifo data
    logic [31:0] URD; // rx fifo data
    // fifo

    // write side

    logic [7:0] w_tx_rdata, w_rx_wdata, w_fifo_rx_tx_data;
    logic w_tx_start, w_tx_done, w_rx_done;
    logic w_full_rd, w_empty_wr;
    logic [7:0] w_tx_rx_dataout;
    logic wr_en, rd_en;

    assign wr_en = (PSEL && PENABLE &&  PWRITE && (PADDR[3:2] == 2'd1));
    assign rd_en = (PSEL && PENABLE && !PWRITE && (PADDR[3:2] == 2'd2));


    APB_SlaveIntf_Uart U_APB_Intf_Uart (
        .*,
        .UCS({28'd0, w_empty_wr, w_full_rd, w_tx_start, w_rx_done}),
        .UTD(w_fifo_rx_tx_data),
        .URD({24'd0, w_rx_wdata})
    );

    fifo_tx U_FIFO_TX (
        .clk(clk),
        .reset(reset),
    // write
        .wdata(w_fifo_rx_tx_data),
        .wr(wr_en),
        .full(w_full_rd),
    // read
        .rd(~w_tx_done & ~w_tx_start),
        .rdata(w_tx_rdata),
        .empty(w_tx_start)
    );
    
    fifo_rx U_FIFO_RX (
        .clk(clk),
        .reset(reset),
    // write
        .wdata(w_rx_wdata),
        .wr(w_rx_done),
        .full(),
    // read
        .rd(rd_en),
        .rdata(w_fifo_rx_tx_data),
        .empty(w_empty_wr)
    );
    uart_fsm U_Uart_FSM (
        .clk(clk),         // 시스템 클럭 입력
        .rst(reset),         // 비동기 리셋 신호
        // tx
        .btn_start(~w_tx_start),   // 데이터 전송 시작 트리거
        .tx_data_in(w_tx_rx_dataout),
        .tx_done(w_tx_done),
        .tx(TX),  // pc로 감
        //rx
        .rx(RX),  // pc로 감
        .rx_done(w_rx_done),     // UART 송신 신호 (시리얼 출력) 
        .rx_data(w_rx_wdata)
    );

    data_save U_Data_Save(
        .clk(clk),
        .reset(reset),
        .rd(~w_empty_wr),
        .data_in(w_fifo_rx_tx_data),
        .data_out(w_tx_rx_dataout)
    );
endmodule

module APB_SlaveIntf_Uart (
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
    // output  logic        wr_en,
    // output  logic        rd_en,
    
    input  logic [31:0] UCS,
    output logic [31:0] UTD,
    input  logic [31:0] URD
    // output logic        wr_en,
    // output logic        rd_en

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg2, slv_reg3;


    assign slv_reg0[31:0] = UCS;   
    assign UTD = slv_reg1[31:0];  // tx
    assign slv_reg2[31:0] = URD;  // rx

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            //slv_reg0 <= 0;
            slv_reg1 <= 0;
            //slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;  //slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: ;  //slv_reg2 <= PWDATA;
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
