`timescale 1ns / 1ps

class transaction; // APB 버스 통해 DUT에 한 번 접근할 때 쓰는 데이터 묶음

    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  // dut out data
    logic             PREADY;  // dut out data
    // inport signals
    logic      [ 3:0] fndCom;  // dut out data
    logic      [ 7:0] fndFont;  // dut out data

    // 제약조건
    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    // 주소는 FCR/FMR/FDR 중 하나
    constraint c_wdata {PWDATA < 10;}
    // 데이터는 0~9
    constraint c_paddr_0 {
        if (PADDR == 0) PWDATA inside {1'b0, 1'b1};
        else if (PADDR == 4) PWDATA <= 4'b1111;
        else if (PADDR == 8) PWDATA < 10;
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndCom=%h, fndFont=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndCom,
            fndFont);
    endtask  //display
endclass  //transaction

interface APB_Slave_Interface; // DUT와 검증 환경을 연결하는 물리적 핀 역할
    // DUT에 연결된 모든 입출력 신호 정의, tb과 DUT를 연결하는 매개체
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;  // dut out data
    logic        PREADY;  // dut out data
    // inport signals
    logic [ 3:0] fndCom;  // dut out data
    logic [ 7:0] fndFont;  // dut out data

endinterface  //APB_Slave_Interface

class generator; // 임의의 테스트 데이터 만들어 드라이버로 전달
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();  // make instance
            if (!fnd_tr.randomize())
                $error("Randomization fail");  // 랜덤값 생성
            fnd_tr.display("GEN");  // 상태 출력
            Gen2Drv_mbox.put(fnd_tr);  // dirver로 전달
            @(gen_next_event);  // wait a event from driver, 다음 신호 대기
        end
    endtask  //run
endclass  //generater

class driver; // 생성된 트랜잭션을 실제 APB 신호로 만들어 DUT에 전달
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);  // 트랜잭션 받아옴
            fnd_tr.display("DRV");  // 디버깅 출력
            @(posedge fnd_intf.PCLK);  // 클럭 동기화
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);  // DUT 반응 대기
            @(posedge fnd_intf.PCLK);  // 한 클럭 더 대기
            @(posedge fnd_intf.PCLK);  // 한 클럭 더 대기
            //->gen_next_event;  // event trigger , Generator에게 다음 트랜잭션 준비시키기
        end
    endtask  //run
endclass  //driver

class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface fnd_intf;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Mon2SCB_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction

    task run();
        forever begin
            fnd_tr = new();
            @(posedge fnd_intf.PREADY);
            #1;
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            fnd_tr.PRDATA  = fnd_intf.PRDATA;
            fnd_tr.PREADY  = fnd_intf.PREADY;
            fnd_tr.fndCom  = fnd_intf.fndCom;
            fnd_tr.fndFont = fnd_intf.fndFont;
            Mon2SCB_mbox.put(fnd_tr);
            fnd_tr.display("MON");
            @(posedge fnd_intf.PCLK);
            // @(posedge fnd_intf.PCLK);  // 한 클럭 더 대기
            // // @(posedge fnd_intf.PCLK);  // 한 클럭 더 대기
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;
    event gen_next_event;

    // reference model
    logic [31:0] refFndReg[0:2];
    logic [7:0] refFndFont[0:15] = '{
        8'hC0,
        8'hF9,
        8'hA4,
        8'hB0,
        8'h99,
        8'h92,
        8'h82,
        8'hF8,
        8'h80,
        8'h90,
        8'h88,
        8'h83,
        8'hC6,
        8'hA1,
        8'h86,
        8'h8E
    };

    function new(mailbox#(transaction) Mon2SCB_mbox,  event gen_next_event);
        this.Mon2SCB_mbox = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;
        for (int i = 0; i < 3; i++) begin
            refFndReg[i] = 0;
        end
    endfunction

    task run();
        forever begin
            Mon2SCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");
            if (fnd_tr.PWRITE) begin  // write mode
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;
                if (refFndFont[refFndReg[2]] == fnd_tr.fndFont)  // pass
                    $display("FND Font PASS, %h, %h" , refFndFont[refFndReg[2]] , fnd_tr.fndCom[7:0]);
                else  // fail
                    $display("FND Font FAIL, %h, %h" , refFndFont[refFndReg[2]] , fnd_tr.fndCom[7:0]);

                if (refFndReg[0] == 0) begin // en = 0: fndCom == 4'b1111;
                    if (4'hf == fnd_tr.fndCom) $display("FND EnableComport PASS");
                    else $display("FND Enable FAIL");
                end else begin  // en == 1;
                    if (refFndReg[1][3:0] == ~fnd_tr.fndCom[3:0])
                        $display("FND Comport PASS, %h, %h" , refFndReg[1][3:0] , ~fnd_tr.fndCom[3:0]);
                    else $display("FND Comport FAIL, %h, %h" , refFndReg[1][3:0] , ~fnd_tr.fndCom[3:0]);
                end
            end else begin
            end  // read mode            
            -> gen_next_event;
        end
    endtask  //run

endclass  //scoreboard

class envirnment;  // Generator 와 Driver 연결하고 동시에 실행 
                   // generator 가 만든 트랜잭션을 driver가 처리
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;

    generator              fnd_gen;
    driver                 fnd_drv;
    monitor                fnd_mon;
    scoreboard             fnd_scb;
    event                  gen_next_event;

    function new(virtual APB_Slave_Interface fnd_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon = new(fnd_intf, Mon2SCB_mbox);
        this.fnd_scb = new(Mon2SCB_mbox, gen_next_event);
    endfunction

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
    endtask  //run
endclass  //envirnment

module tb_fndController_APB ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf(); // interface는 new를 만들어주지 않음

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FND_Periph dut (
        // global signal
        .PCLK  (fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),

        .PADDR  (fnd_intf.PADDR),
        .PWDATA (fnd_intf.PWDATA),
        .PWRITE (fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),

        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // inport signals
        .fndComm(fnd_intf.fndCom),
        .fndFont(fnd_intf.fndFont)
    );

    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);  // envirnment instance 생성
        fnd_env.run(100);  // 10번 시도
        #30;
        $display("finished");
        $finish;
    end
endmodule

