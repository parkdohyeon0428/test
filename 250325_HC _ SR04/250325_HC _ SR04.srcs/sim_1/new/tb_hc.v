`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 11:10:46
// Design Name: 
// Module Name: tb_trigger_step_generate_
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_trigger_step_generate_ ();
    reg  btn;
    reg  clk = 0;
    reg  rst;
    reg  echo_pulse=0;
    wire trigger_step;
    hc_top_module uut (
        .btn_start(btn),
        .clk(clk),
        .reset(rst),
        .echo(echo_pulse),
        .trig(trigger_step)
    );

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        #1000;                                                
        rst =0;
        // echo_pulse = 1;
        // #10000
        // echo_pulse = 0;
        btn =1;
        wait(uut.start_tick);
        btn = 0;
        wait(!uut.start_tick);
        #100000;


        $finish;
    end
endmodule
