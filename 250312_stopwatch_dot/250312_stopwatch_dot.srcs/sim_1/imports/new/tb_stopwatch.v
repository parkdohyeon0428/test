`timescale 1ns / 1ps


module tb_stopwatch ();

    reg clk, reset, run, clear, sw_mode;
    wire [6:0] msec,sec,min,hour;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;


    stopwatch_dp Ustop (
        .clk(clk),
        .reset(reset),
        .run(run),
        .clear(clear),
        .msec(msec),
        .sec(sec), 
        .min(min),
        .hour(hour)
    );
    fnd_controller Ufnd (
        .clk(clk),
        .reset(reset),
        .sw_mode(sw_mode),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );


    always #0.05 clk = ~clk;
    initial begin
        clk   = 0;
        reset = 1;
        run   = 0;
        clear = 0;
        sw_mode = 0;
        #10;
        reset = 0;
        run   = 1;
        #10;
        wait(min ==1);
        #1000000;   
        run = 0;
        clear =1;
        

      #100000;
        #10;



    end

endmodule
