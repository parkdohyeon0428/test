`timescale 1ns / 1ps

module TB_DHT_CU ();
    localparam  
                WAIT  = 4'b0010;


    reg clk;
    reg rst;
    reg start_trigger;
    wire data;
    reg data_in;
    wire [3:0] led;
    reg data_t;

    assign data = (data_t) ? data_in : 1'bz;


    top_sensor uut (
        .clk(clk),
        .reset(rst),
        .data(data),
        .start_trigger(start_trigger),
        .led(led),
        .seg_out(seg_out),
        .seg_comm(seg_comm),
        .tx(tx)
    );


    task send_data(input [39:0] data);
        integer i;
        begin
            $display("Sending data: %d", data);
            
            for (i = 0; i < 40; i = i + 1) begin
                data_in =0;
                #50000;
                if (data[39-i] == 0) begin
                    data_in =1;
                    #30000;
                end else if (data[39-i] == 1) begin
                    data_in =1;
                    #70000;
                end
            end
        end

    endtask
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        data_t = 0;
        start_trigger = 0;
        #100 rst = 0;
        start_trigger = 1;
        wait (uut.ubtn.o_btn);
        start_trigger = 0;
        wait (uut.u_sen.state == WAIT);
        data_t = 1; 
        #10;
        data_in = 0;
        #80000;
        data_in = 1;
        #80000;
        send_data(40'd300000);
        data_in =0;
        #10000;
    end

endmodule






