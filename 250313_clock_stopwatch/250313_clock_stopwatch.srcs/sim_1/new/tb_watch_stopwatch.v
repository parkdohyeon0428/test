`timescale 1ns / 1ps

module top_stopwatch_tb;
    reg clk;
    reg reset;
    reg btn_run_hour;
    reg btn_clear_start;
    reg btn_sec;
    reg btn_min;
    reg [1:0] sw_mode;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;
    wire [3:0] led;
    
    
    top_stopwatch UUT (
        .clk(clk),
        .reset(reset),
        .btn_run_hour(btn_run_hour),
        .btn_clear_start(btn_clear_start),
        .btn_sec(btn_sec),
        .btn_min(btn_min),
        .sw_mode(sw_mode),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font),
        .led(led)
    );
  
    // Clock generation
    always #0.05 clk = ~clk;
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        btn_run_hour = 0;
        btn_clear_start = 0;
        btn_sec = 0;
        btn_min = 0;
        sw_mode = 2'b01;
        
        // Reset pulse
        #100 reset = 0;
        
        // Wait some time
        #10000;
        
        // Start         watch by pressing btn_clear_start
        btn_run_hour = 1;
          #100000;
        btn_run_hour = 0;
        #1000000;
        btn_run_hour = 1;
          #1000000;
        btn_run_hour = 0;
        #100000;
        btn_clear_start = 1;
        #100000;
        btn_clear_start = 0;  
        
       

        // Finish simulation
        #100;

    end
endmodule
