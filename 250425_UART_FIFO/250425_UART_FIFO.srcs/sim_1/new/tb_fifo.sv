`timescale 1ns / 1ps

interface fifo_interface (
    input logic clk,
    input logic reset
);
    logic [7:0] wdata;
    logic       wr_en;
    logic       full;

    logic [7:0] rdata;
    logic       rd_en;
    logic       empty;

    clocking drv_cb @(posedge clk); // test bench 기준으로 방향을 정한다.
        default input #1 output #1;
        // write
        output wdata; // tb -> fifo 로 데이터 출력
        output wr_en; // tb -> fifo 로 데이터 출력
        input full;   // fifo 의 full 신호 읽음
        // read 
        input rdata;  // fifo에서 읽은 데이터 tb로 전달
        output rd_en; // 읽기 신호를 fifo에 보냄
        input empty;  // fifo에서 읽은 데이터 tb로 전달
    endclocking

    clocking mon_cb @(posedge clk); // FIFO 모듈에서 신호의 방향을 설정하고, 모니터링하는 데 사용
        default input #2 output #1;
        // write
        input wdata;  // FIFO에서 읽은 wdata 신호를 가져옴
        input wr_en;  // FIFO에서 읽은 wr_en 신호를 가져옴
        input full;   // FIFO에서 읽은 full  신호를 가져옴
        // read 
        input rdata;  // FIFO에서 읽은 rdata 신호를 가져옴 
        input rd_en;  // FIFO에서 읽은 rd_en 신호를 가져옴
        input empty;  // FIFO에서 읽은 empty 신호를 가져옴
    endclocking

     // input , output의 방향성 정의
    modport drv_mport(clocking drv_cb, input reset); 
    modport mon_mport(clocking mon_cb, input reset);
endinterface  //ram_intf

class transaction;
    rand logic       oper;  // write(1) or read(0) operator
    // write
    rand logic [7:0] wdata;
    rand logic       wr_en;
    logic            full;
    // read
    logic      [7:0] rdata;
    rand logic       rd_en;
    logic            empty;

    constraint oper_ctrl { oper dist { 1 :/ 80, 0 :/ 20};} // 1 = 80 : 20 = 0

    task display(string name);
        $display(
            "[%S] oper=%h, wdata=%h, wr_en=%h, full=%d, rdata=%h, rd_en=%h, empty=%h",
            name, oper, wdata, wr_en, full, rdata, rd_en, empty);
    endtask  //
endclass  //transaction

class generator;
    mailbox #(transaction) GenToDrv_mbox;
    event gen_next_event;
    transaction fifo_tr;

    function new(mailbox#(transaction) GenToDrv_mbox, event gen_next_event);
        this.GenToDrv_mbox  = GenToDrv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        repeat (repeat_counter) begin
            fifo_tr = new();
            if (!fifo_tr.randomize()) $error("Randomization failed!!!");
            fifo_tr.display("GEN");
            GenToDrv_mbox.put(fifo_tr);
            @(gen_next_event);
        end
    endtask  //
endclass  //generator

class driver;
    mailbox #(transaction) GenToDrv_mbox;
    virtual fifo_interface.drv_mport fifo_if;
    transaction fifo_tr;

    function new(mailbox#(transaction) GenToDrv_mbox,
                 virtual fifo_interface.drv_mport fifo_if);
        this.GenToDrv_mbox = GenToDrv_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task write();
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.wdata <= fifo_tr.wdata;
        fifo_if.drv_cb.wr_en <= 1'b1;
        fifo_if.drv_cb.rd_en <= 1'b0;
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.wr_en <= 1'b0;
    endtask  //write

    task read();
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.rd_en <= 1'b1;
        fifo_if.drv_cb.wr_en <= 1'b0;
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.rd_en <= 1'b0;
    endtask  //read

    task run();
        forever begin
            GenToDrv_mbox.get(fifo_tr);
            if (fifo_tr.oper == 1'b1) write();
            else read();
            fifo_tr.display("DRV");
        end
    endtask
endclass  //driver

class monitor;
    mailbox #(transaction) MonToSCB_mbox;
    virtual fifo_interface.mon_mport fifo_if;
    transaction fifo_tr;

    function new(mailbox#(transaction) MonToSCB_mbox,
                 virtual fifo_interface.mon_mport fifo_if);
        this.MonToSCB_mbox = MonToSCB_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task run();
        forever begin
            @(fifo_if.mon_cb);
            @(fifo_if.mon_cb);
            fifo_tr       = new();
            fifo_tr.wdata = fifo_if.mon_cb.wdata;
            fifo_tr.wr_en = fifo_if.mon_cb.wr_en;
            fifo_tr.full  = fifo_if.mon_cb.full;

            fifo_tr.rdata = fifo_if.mon_cb.rdata;
            fifo_tr.rd_en = fifo_if.mon_cb.rd_en;
            fifo_tr.empty = fifo_if.mon_cb.empty;

            MonToSCB_mbox.put(fifo_tr);
            fifo_tr.display("MON");
        end
    endtask  //

endclass  //monitor

class scoreboard;
    mailbox #(transaction) MonToSCB_mbox;
    event gen_next_event;
    transaction fifo_tr;

    // reference model
    logic [7:0] scb_fifo[$]; // 8bit queue 선언 , $만 넣으면 무한대로 넣어질 수 있다
                             // 이 큐는 FIFO 모듈이 쓰기를 할 때 데이터를 저장하고, 
                             // 읽기를 할 때 데이터를 반환하는데 사용
                             // 소프트웨어적으로 구현된 FIFO로, 하드웨어 FIFO와 동일한 역할
    logic [7:0] pop_data;    // fifo에서 데이터 읽을 때, 꺼내는 값 저장하는 변수

    function new(mailbox#(transaction) MonToSCB_mbox, event gen_next_event);
        this.MonToSCB_mbox  = MonToSCB_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            MonToSCB_mbox.get(fifo_tr);
            fifo_tr.display("SCB");
            if (fifo_tr.wr_en == 1'b1) begin
                if (fifo_tr.full == 1'b0) begin
                    scb_fifo.push_back(fifo_tr.wdata); // fifo_tr.wdata 값을 scb_fifo 큐의 끝에 추가
                    // push_back : 배열의 뒤쪽에 값을 추가하는 함수
                    $display("[SCB] : DATA Stored in queue : %h, %h",
                             fifo_tr.wdata, scb_fifo);
                end else begin
                    $display("[SCB] : FIFO is full, %h", scb_fifo);
                end
            end
            if (fifo_tr.rd_en == 1'b1) begin
                if (fifo_tr.empty == 1'b0) begin
                    pop_data = scb_fifo.pop_front();
                    // pop_front : 큐나 동적 배열의 앞쪽에서 데이터를 꺼내는 함수
                    if (fifo_tr.rdata == pop_data) begin
                        $display("[SCB] : DATA matched %h == %h",
                                 fifo_tr.rdata, pop_data);
                    end else begin
                        $display("[SCB] : DATA missmatched %h != %h",
                                 fifo_tr.rdata, pop_data);
                    end
                end else begin
                    $display("[SCB] : FIFO is empty");
                end
            end
            ->gen_next_event; // event trigger
        end
    endtask  
endclass  //scoreboard

class envirnment;
    mailbox #(transaction) GenToDrv_mbox;
    mailbox #(transaction) MonToSCB_mbox;
    event                  gen_next_event;
    generator              fifo_gen;
    driver                 fifo_drv;
    monitor                fifo_mon;
    scoreboard             fifo_scb;

    function new(virtual fifo_interface fifo_if);
        GenToDrv_mbox = new();
        MonToSCB_mbox = new();
        fifo_gen = new(GenToDrv_mbox, gen_next_event);
        fifo_drv = new(GenToDrv_mbox, fifo_if);
        fifo_mon = new(MonToSCB_mbox, fifo_if);
        fifo_scb = new(MonToSCB_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            fifo_gen.run(count);
            fifo_drv.run();
            fifo_mon.run();
            fifo_scb.run();
        join_any
    endtask  //
endclass  //envirnment

module tb_fifo ();
    logic clk, reset;

    envirnment env;
    fifo_interface fifo_if (
        clk,
        reset
    );

    fifo dut (
        .clk  (clk),
        .reset(reset),
        .wdata(fifo_if.wdata),
        .wr_en(fifo_if.wr_en),
        .full (fifo_if.full),
        .rdata(fifo_if.rdata),
        .rd_en(fifo_if.rd_en),
        .empty(fifo_if.empty)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        @(posedge clk);
        reset = 0;
        env   = new(fifo_if);
        env.run(100);
        #50;
        $finish;
    end

endmodule
