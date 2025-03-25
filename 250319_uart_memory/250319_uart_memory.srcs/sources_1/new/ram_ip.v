`timescale 1ns / 1ps

module ram_ip #(
    parameter ADDR_WIDTH = 4,  // 주소 크기 (4비트 = 16개의 저장공간)
    parameter DATA_WIDTH = 8   // 데이터 크기 (8비트 = 1바이트)
)(
    input                   clk,       // 클럭
    input  [ADDR_WIDTH-1:0] waddr,     // 쓰기 주소 (4비트)
    input  [DATA_WIDTH-1:0] wdata,     // 쓰기 데이터 (8비트)
    input                   wr,        // 쓰기 활성화 (1이면 쓰기, 0이면 읽기)
    output [DATA_WIDTH-1:0] rdata      // 읽기 데이터 (8비트)
);
    //reg [DATA_WIDTH-1:0] rdata_reg;
    reg [DATA_WIDTH-1:0] ram[0:2**ADDR_WIDTH-1];    // 2**4 = 2의 4승  
          //해당 비트          // 저장공간         //16개의 8비트 저장공간
    // write
    always @(posedge clk) begin
        if (wr) begin
            ram[waddr] <= wdata;
        end        
    end

    assign rdata = ram[waddr];
/*
    assign rdata = rdata_reg;
    // read
    always @(posedge clk) begin
        if (!wr) begin
            rdata_reg <= ram[waddr];
        end
    end */
endmodule 
 