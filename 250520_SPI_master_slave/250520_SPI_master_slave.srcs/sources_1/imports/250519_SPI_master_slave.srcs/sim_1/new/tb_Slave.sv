`timescale 1ns / 1ps

module tb_Slave ();

    logic reset;
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic SS;
    logic done;
    logic write;
    logic [1:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;

    SPI_Slave_Intf dut (.*);

    always #500 SCLK = ~SCLK;

    initial begin
        SCLK = 0;
        reset = 1;
        #10 reset = 0;
        rdata = 8'hff;
        // address byte
        repeat (3) @(posedge SCLK);
        SS = 0;

            
        //@(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 0; ;
         @(negedge SCLK);


         @(negedge SCLK);
        MOSI = 1; rdata = 8'h44;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 0;
         @(negedge SCLK);

          @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
         @(negedge SCLK);

          @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 0;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        @(negedge SCLK);
        MOSI = 1;
        
        #50 $finish;
    end

endmodule
