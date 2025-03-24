`timescale 1ns / 1ps

module tb_fifo();
    reg clk;
    reg reset;
    //write
    reg [7:0] wdata;
    reg wr;
    wire full;
    //read
    reg rd;
    wire [7:0] rdata;
    wire empty;

    fifo dut(
        .clk(clk),
        .reset(reset),
        //write
        .wdata(wdata),
        .wr(wr),
        .full(full),
        //read
        .rd(rd),
        .rdata(rdata),
        .empty(empty)
);  
 
    always #5 clk = ~clk;
    integer i; 
        
    initial begin
        clk = 0;
        reset = 1;
        wdata = 0;
        wr = 0;
        rd = 0;
        #10; 
        reset = 0;
        #10; 
        //읽기기
        wr = 1;
        for (i=0; i<17; i = i + 1) begin
             wdata = i; 
             #10;
        end
        //읽기
        wr = 0;
        rd = 1;
        for (i=0; i<17; i = i + 1) begin
             #10;
        end
        wr = 0;
        rd = 0;
        #10;
        //동시 읽고 쓰기
        wr = 1;
        rd = 1;
        for (i=0; i<17; i = i + 1) begin
             wdata = i*2+1; 
             #10;
        end
    end  
endmodule
        /*
        wdata = 8'haa;
        #10;
        wdata = 8'h44;
        #10;
        wdata = 8'h55;
        #10;
        wdata = 8'h22;
        #10;
        wdata = 8'hff;
        #10;
        wdata = 8'hcc;
        #10;
        wdata = 8'hdd;
        #10;
        wdata = 8'h33;
        #10;
        wdata = 8'haa;
        #10;
        wdata = 8'h44;
        #10;
        wdata = 8'h55;
        #10;
        wdata = 8'h22;
        #10;
        wdata = 8'hff;
        #10;
        wdata = 8'hcc;
        #10;
        wdata = 8'hdd;
        #10;
        wdata = 8'h33;
        #10;
        
        #20; */
        

    /*
    integer i;
    reg [7:0] rand_data;
    reg [7:0] rand_addr;
    initial begin
        clk = 0;
        reset = 1;
        wdata = 8'h00;
        wr = 0;
        rd = 0;
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


endmodule */