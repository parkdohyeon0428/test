`timescale 1ns / 1ps


interface uart_interface;
    // global signal
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        tx;
    logic        rx;

endinterface  //uart_interface


class transaction;
    // global signal
    logic             PCLK;
    logic             PRESET;
    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;
    logic             PREADY;
    logic             tx;
    logic             rx;

    constraint c_padder {
        PADDR inside {4'h0, 4'h4, 4'hC};
    } 
    constraint c_padder_4 {
        if (PADDR == 4'b0100) PWDATA < 10;
    } 
    constraint c_padder_0 {  // rx
        if (PADDR == 0)
        PWDATA inside {2'b01, 2'b00};
    }
    constraint c_padder_C {  // tx
        if (PADDR == 4'hC)
        PWDATA inside {2'b10, 2'b00};
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h,tx = %h, rx = %h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, tx, rx);
    endtask  //

endclass  //transaction

class generator;
    mailbox #(transaction) GenToDrv_mbox;
    event gen_next_event;
    transaction uart_tr;

    function new(mailbox#(transaction) GenToDrv_mbox, event gen_next_event);
        this.GenToDrv_mbox  = GenToDrv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        repeat (repeat_counter) begin
            tx_tr = new();
            if (!tx_tr.randomize()) 
            $error("Randomization failed!!!");
            tx_tr.display("GEN");
            tx_tr.PADDR  = 4'h4;
            tx_tr.PWRITE = 1;
            GenToDrv_mbox.put(tx_tr);
            @(gen_next_event);
            #(104170 * 10);
            rx_tr = new();
            rx_tr.PADDR = 4'h8;
            rx_tr.PWRITE = 0;
            rx_tr.display("GEN");
            GenToDrv_mbox.put(rx_tr);
            @(gen_next_event);
        end
    endtask
endclass  //generator

class driver;
    virtual uart_interface uart_if;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction uart_tr;
    event mon_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox,
                 virtual uart_interface uart_if, event mon_next_event);
        this.uart_if = uart_if;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.mon_next_event = mon_next_event;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(uart_tr);
            uart_tr.display("DRV");
            @(posedge uart_if.PCLK);
            uart_if.PADDR   <= uart_tr.PADDR;
            uart_if.PWDATA  <= uart_tr.PWDATA;
            uart_if.PWRITE  <= uart_tr.PWRITE;
            uart_if.PENABLE <= 1'b0;  //SETUP
            uart_if.PSEL    <= 1'b1;
            @(posedge uart_if.PCLK);
            uart_if.PADDR   <= uart_tr.PADDR;
            uart_if.PWDATA  <= uart_tr.PWDATA;
            uart_if.PWRITE  <= uart_tr.PWRITE;
            uart_if.PENABLE <= 1'b1;  //ACCESS
            uart_if.PSEL    <= 1'b1;
            wait (uart_if.PREADY == 1'b1);
            if (uart_if.PWRITE == 1) begin
                #(104170 * 10);
            end
            ->mon_next_event;
        end


    endtask
endclass  //driver

class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual uart_interface uart_if;
    transaction uart_tr;
    event mon_next_event;

    function new(mailbox#(transaction) Mon2SCB_mbox,
                 virtual uart_interface uart_if, event mon_next_event);
        this.uart_if = uart_if;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
        this.mon_next_event = mon_next_event;
    endfunction  //new()

    task run();
        forever begin
            uart_tr = new();
            @(mon_next_event);
            @(posedge uart_if.PCLK);
            #1;
            uart_tr.PADDR   = uart_if.PADDR;
            uart_tr.PWDATA  = uart_if.PWDATA;
            uart_tr.PWRITE  = uart_if.PWRITE;
            uart_tr.PENABLE = uart_if.PENABLE;
            uart_tr.PSEL    = uart_if.PSEL;
            if (!uart_if.PWRITE) begin
                uart_tr.PRDATA = uart_if.PRDATA;
            end else begin
                uart_tr.PRDATA = 'x; 
            end
            uart_tr.PREADY  = uart_if.PREADY;
            uart_tr.display("MON");
            Mon2SCB_mbox.put(uart_tr);
            #(104170 * 10);
            @(posedge uart_if.PCLK);
        end
    endtask  //
endclass  //monitor


class scoreboard;
    mailbox #(transaction) MonToSCB_mbox;
    event gen_next_event;
    transaction uart_tr;

    logic [7:0] scb_wdata[$];
    logic [7:0] expected;
    logic [7:0] received;

    logic [6:0] pass_cnt;
    logic [6:0] fail_cnt;
    logic [6:0] total_cnt;

    function new(mailbox#(transaction) MonToSCB_mbox, event gen_next_event);
        this.MonToSCB_mbox  = MonToSCB_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        pass_cnt  = 0;
        fail_cnt  = 0;
        total_cnt = 0;
        forever begin
            MonToSCB_mbox.get(uart_tr);
            uart_tr.display("SCB");
            if (uart_tr.PWRITE == 1) begin
                scb_wdata.push_back(uart_tr.PWDATA[7:0]);
                $display("[SCB] : DATA Stored in queue : %h, %h",
                         uart_tr.PWDATA, scb_wdata[0]);
            end else begin
                expected = scb_wdata.pop_front();
                received = uart_tr.PRDATA[7:0];
                if (expected == received) begin
                    $display("[SCB] pass TX_PWDATA : %h, RX_PRDATA : %h", expected, received);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[SCB] fail TX_PWDATA : %h, RX_PRDATA : %h", expected, received);
                    fail_cnt = fail_cnt + 1;
                end
                total_cnt = total_cnt + 1;
            end
            #(104170 * 10);
            ->gen_next_event;  // event triggering
        end
    endtask  //

    task report();
        $display("===============================");
        $display("==        Final Report       ==");
        $display("===============================");
        $display("      PASS Test  : %0d", pass_cnt);
        $display("      Fail Test  : %0d", fail_cnt);
        $display("      Total Test : %0d", total_cnt);
        $display("===============================");
        $display("==   test bench is finished  ==");
        $display("===============================");
    endtask  //report


endclass  //scoreboard

class envirnment;
    mailbox #(transaction) GenToDrv_mbox;
    mailbox #(transaction) MonToSCB_mbox;
    event                  gen_next_event;
    event                  mon_next_event;
    generator              uart_gen;
    driver                 uart_drv;
    monitor                uart_mon;
    scoreboard             uart_scb;

    function new(virtual uart_interface uart_if);
        GenToDrv_mbox = new();
        MonToSCB_mbox = new();
        uart_gen = new(GenToDrv_mbox, gen_next_event);
        uart_drv = new(GenToDrv_mbox, uart_if, mon_next_event);
        uart_mon = new(MonToSCB_mbox, uart_if, mon_next_event);
        uart_scb = new(MonToSCB_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            uart_gen.run(count);
            uart_drv.run();
            uart_mon.run();
            uart_scb.run();
        join_any
            uart_scb.report();
    endtask  //
endclass  //envirnment

module tb_uart_SystemVerilog ();
    envirnment uart_env;
    uart_interface uart_intf ();

    assign uart_intf.rx = uart_intf.tx;

    always #5 uart_intf.PCLK = ~uart_intf.PCLK;

    uart_Periph DUT (
        // global signal
        .PCLK(uart_intf.PCLK),
        .PRESET(uart_intf.PRESET),
        // APB Interface signals
        .PADDR(uart_intf.PADDR),
        .PWDATA(uart_intf.PWDATA),
        .PWRITE(uart_intf.PWRITE),
        .PENABLE(uart_intf.PENABLE),
        .PSEL(uart_intf.PSEL),
        .PRDATA(uart_intf.PRDATA),
        .PREADY(uart_intf.PREADY),
        // outport signals
        .tx(uart_intf.tx),
        .rx(uart_intf.rx)
    );

    initial begin
        uart_intf.PCLK   = 0;
        uart_intf.PRESET = 1;

        #20;
        uart_intf.PRESET = 0;
        uart_env = new(uart_intf);
        uart_env.run(10);
        #30;
        $finish;
    end
endmodule
