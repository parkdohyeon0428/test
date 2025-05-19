`timescale 1ns / 1ps

module tb_spi_slave();
        reg clk;
        reg reset;
        reg [7:0] data;
        reg done;
        reg CS;
        wire [15:0] fnd_data;
  
    Slave_fsm dut(
        .clk(clk),
        .reset(reset),
        .data(data),
        .done(done),
        .CS(CS),
        .fnd_data(fnd_data)
    );
    always #5 clk = ~clk;
    initial begin
        clk = 0;
        reset = 1;
        CS = 1;
        data = 0;
        done = 0;
        #10;
        reset = 0;
        CS = 0;
        #10;
        data = 8'h11;
        done = 1;
        #10;
        done = 0;
        #10;
        data = 8'h22;
        done = 1;
        #10;
        done = 0;
        #10;
        data = 8'hff;
        done = 1;
        #10;
        done = 0;
        #10;
        data = 8'haa;
        done = 1;
    end

    //     SPI_Slave dut(
    //     .SCLK(SCLK),
    //     .reset(reset),
    //     .MOSI(MOSI),
    //     .MISO(MISO),
    //     .CS(CS),
    //     .data(data),
    //     .done(done)
    // );

endmodule
//     always #500 SCLK = ~SCLK;

//     initial begin
//         SCLK = 0;
//         reset = 1;
//         #10;
//         reset = 0;
//         CS = 0;
//         //@(negedge SCLK);
//         MOSI = 1;
//         @(negedge SCLK);
//         MOSI = 1;
//         @(negedge SCLK);
//         MOSI = 0;
//         @(negedge SCLK);
//         MOSI = 0;
//         @(negedge SCLK);
//         MOSI = 0;
//         @(negedge SCLK);
//         MOSI = 1;
//         @(negedge SCLK);
//         MOSI = 1;
//         @(negedge SCLK);
//         MOSI = 1;
//     end
// endmodule


// module tb_spi_slave();

//     reg clk;
//     reg reset;
//     reg SCLK;
//     reg MOSI;
//     wire MISO;
//     reg CS;

//     Top_SPI_Slave dut(
//         .clk(clk),
//         .reset(reset),
//         .SCLK(SCLK),
//         .MOSI(MOSI),
//         .MISO(MISO),
//         .CS(CS)
//     );

//     always #5 clk = ~clk;
//     always #500 SCLK = ~SCLK;

//     initial begin
//         clk = 0;
//         reset = 1;
//         #10;
//         reset = 0;
//         CS = 0;
//         SCLK = 0;
//         MOSI = 1;
//         @(posedge SCLK);
//         MOSI = 1;
//         @(posedge SCLK);
//         MOSI = 1;
//         @(posedge SCLK);
//         MOSI = 1;
//         @(posedge SCLK);
//         MOSI = 1;
//         @(posedge SCLK);
//         MOSI = 1;
//         @(posedge SCLK);
//         MOSI = 1;
//         // @(posedge SCLK);
//         // MOSI = 1;
        
//     end

// endmodule
