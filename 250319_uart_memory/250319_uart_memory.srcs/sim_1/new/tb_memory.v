`timescale 1ns / 1ps

module tb_memory();

    parameter ADDR_WIDTH = 4, DATA_WIDTH = 8;
    
    reg clk;
    reg [ADDR_WIDTH-1:0] waddr;
    reg [DATA_WIDTH-1:0] wdata;
    reg wr;
    wire [DATA_WIDTH-1:0] rdata;


    ram_ip DUT(
        .clk(clk),
        .waddr(waddr),
        .wdata(wdata),
        .wr(wr),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    integer i;
    reg [DATA_WIDTH-1:0] rand_data;
    reg [ADDR_WIDTH-1:0] rand_addr;
    initial begin
        clk = 0;
        waddr = 4'h0;
        wdata = 8'h00;
        wr = 0;
        #10;
        for (i=0; i<50; i = i + 1) begin
            @(posedge clk);
            // 난수 발생기
            rand_addr = $random%16; // 난수의 모수가 16
            rand_data = $random%256; // 난수의 모수가 256
            //쓰기
            wr = 1;
            waddr = rand_addr;
            wdata = rand_data;
            @(posedge clk);
            //읽기
            waddr = rand_addr;
            #10;
            // == 값비교, === case 비교 (0,1,x,z 다 비교)
            if(rdata === wdata) begin // 출력과 입력이 같은지 비교
                $display("pass"); 
            end else begin
                $display("fail addr = %d, data = %h", waddr, rdata);
            end
        end
        #10;
        $stop;
    end
endmodule
