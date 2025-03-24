`timescale 1ns / 1ps


module tb_fifo2();
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
    integer rand_rd;
    integer rand_wr;
    reg [7:0]compare_data[2**4-1:0];
    integer write_count = 0;
    integer read_count = 0;
        
    initial begin
        clk = 0;
        reset = 1;
        wdata = 0;
        wr = 0;
        rd = 0;
        #10; 
        reset = 0;
        #10; 
        //쓰기기
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
        wr = 0;
        #10;
        rd = 0;
        #20; // empty 만들고 delay
        // 랜덤 쓰기 및 읽기 테스트 반복
        for (i=0; i<50; i=i+1) begin
            @(negedge clk);             // 쓰기 data를 negedge에서 시작하기 위함.
            rand_wr=$random%2;          // wr 랜덤으로 1,0 만들기
            if (~full&rand_wr) begin   // full 아니면서 wr이 1일 때만 새로운 wdata 생성.
                wr <= 1;
                wdata = $random&256; // 1bye 전체 값이 다들어감
                compare_data[write_count%2**4] = wdata;  // read data와 비교하기 위함
                write_count = write_count + 1;
            end else begin
                wr <= 0;
            end

            rand_rd = $random%2;       // rd random 으로 생성 0,1
            if (~empty&rand_rd) begin  // read test
                #2;
                rd <= 1;
                if(rdata===compare_data[read_count%16]) begin   // rdata와 compare_data 를 비교하여 출력
                    $display("pass");
                end else begin
                    $display("fail: rdata= %h, compare_data=%h", rdata, compare_data[read_count%16]);
                end
                read_count = read_count + 1;
            end else begin
                rd <= 0;
            end
        end
    end  
endmodule