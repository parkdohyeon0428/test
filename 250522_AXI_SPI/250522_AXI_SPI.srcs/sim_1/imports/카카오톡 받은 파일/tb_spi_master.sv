`timescale 1ns / 1ps

module tb_SPI_Master ();



    // global signals
    logic clk;
    logic reset;
    logic start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    // SPI nals
    logic done;
    logic ready;
    logic cpol;     // clock polarity
    logic cpha;     // clock phase
    // external por




    SPI U_DUT (.*);


    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;

        repeat (3) @(posedge clk);

        // address byte
       // SS = 1;
        @(posedge clk);
        tx_data = 8'b10000000;  // write first
        start = 1;
        cpol = 0;
        cpha = 0;
       // SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        // write data byte on 0x00 address
        @(posedge clk);
        tx_data = 8'h10;
        cpol = 0;
        cpha = 0;  // msb =1, write
        @(posedge clk);
        start = 1;
        //SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        // write data byte on 0x01 address
        @(posedge clk);
        tx_data = 8'h20;
        start = 1;
        cpol = 0;
        cpha = 0;
        //SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        // write data byte on 0x02 address
        @(posedge clk);
        tx_data = 8'h30;
        start = 1;
        cpol = 0;
        cpha = 0;
        //SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        // write data byte on 0x03 address
        @(posedge clk);
        tx_data = 8'h40;
        start = 1;
        cpol = 0;
        cpha = 0;
        //SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //SS = 1;

        @(posedge clk);
        //SS = 0;
        @(posedge clk);
        tx_data = 8'b0; // read & address 0x00
        start = 1;
        cpol = 0;
        cpha = 0;  // msb =0, read
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);
        
        start = 1;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);



        //SS=1;


        #300;
        $finish;
    end

endmodule


