`timescale 1ns / 1ps

module tb_AXI4_Lite ();

    // Global Signals
    logic        ACLK;
    logic        ARESETn;
    // Write Transaction; AW Channel
    logic [ 3:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    // Write Transaction; W Channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    // Write Transaction; B Channel
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    // Read Transaction,  AR Channel
    logic [ 3:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    // Read Transaction, R channel
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;

    // internal signals
    logic        transfer;
    logic [ 3:0] addr;
    logic        ready;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    AXI4_Lite_Master DUT_MASTER (.*);
    AXI4_Lite_Slave DUT_SLAVE (.*);

    always #5 ACLK = ~ACLK;

    initial begin
        ACLK = 0;
        ARESETn = 0;
        #10;
        ARESETn = 1;
        @(posedge ACLK);
        #1; addr = 0; wdata = 10; write = 1; transfer = 1; 
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        
        @(posedge ACLK);
        #1; addr = 0; wdata = 11; write = 0; transfer = 1; 
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 8; wdata = 12; write = 1; transfer = 1; 
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 12; wdata = 13; write = 1; transfer = 1; 
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);
    
        #100; $finish;
    end

endmodule
