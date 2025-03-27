`timescale 1ns / 1ps

module TB_DHT_CU ();
    localparam  
                WAIT  = 4'b0010,
                SYNC_LOW = 4'b0100;


    reg clk;
    reg reset;
    reg btn_start;
    wire dht_io;
    reg dht_io_reg;
    wire [3:0] led;
    reg io_reg;



    Top_DHT11 uut (
        .clk(clk),
        .reset(reset),
        .dht_io(dht_io),
        .btn_start(btn_start),
        .led(led),
        .seg(seg),
        .seg_comm(seg_comm)
        //.tx(tx)
    );

    assign dht_io = (io_reg) ? dht_io_reg : 1'bz;


    task send_data(input [39:0] data);
        integer i;
        begin
            $display("Sending data: %d", data);
            
            for (i = 0; i < 40; i = i + 1) begin
                dht_io_reg =0;
                #50000;
                if (data[39-i] == 0) begin
                    dht_io_reg =1;
                    #30000;
                end else if (data[39-i] == 1) begin
                    dht_io_reg =1;
                    #70000;
                end
            end
        end

    endtask
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        io_reg = 0;
        #100 reset = 0;
        io_reg = 0;
        btn_start = 0;
        btn_start = 1;
        wait (uut.U_btn.o_btn);
        btn_start = 0;
        wait (uut.U_DNT_CTRL.state == SYNC_LOW);
        io_reg  = 1; 
        #10;
        dht_io_reg = 0;
        #80000;
        dht_io_reg = 1;
        #80000;
        send_data(40'd300000);
        dht_io_reg =0;
        #50000;
        io_reg = 0;
    end

endmodule






