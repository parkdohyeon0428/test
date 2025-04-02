`timescale 1ns / 1ps

module tb_test();
    
    reg clk;
    reg reset;
    reg rx;
    wire fndCom;
    wire fndFont;

    top_counter_up_down U_TOP(
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .fndCom(fndCom),
    .fndFont(fndFont)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        rx = 1;
        #100;
        reset = 0;
        rx = 0;
        #10000
        send_data(8'h72);
        send_data(8'h71);
        send_data(8'h72);
        #10000;
    end

    task send_data(input [7:0] data);
    integer  i;
    begin
    $display("sending data: %h",data);

    rx =0;
    #104170;

    for  (i=0; i<8; i=i+1) begin
       rx =data[i];
       #104170; 
    end
    rx =1;
    #104170;

    $display("Data sent:%h", data);

    end
    endtask
endmodule
