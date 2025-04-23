`timescale 1ns / 1ps

class transaction; // APB 버스 통해 DUT에 한 번 접근할 때 쓰는 데이터 묶음

    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;   // dut out data
    logic             PREADY;   // dut out data
    // inport signals
    logic      [ 3:0] fndCom;   // dut out data
    logic      [ 7:0] fndFont;  // dut out data

    // 제약조건
    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    // 주소는 FCR/FMR/FDR 중 하나
    constraint c_wdata {PWDATA < 10;}
    // 데이터는 0~9

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
            if (!fnd_tr.randomize()) $error("Randomization fail"); // 랜덤값 생성
            fnd_tr.display("GEN");    // 상태 출력
            Gen2Drv_mbox.put(fnd_tr); // dirver로 전달
            @(gen_next_event);  // wait a event from driver, 다음 신호 대기
        end
    endtask  //run
endclass  //generater

class driver; // 생성된 트랜잭션을 실제 APB 신호로 만들어 DUT에 전달
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);       // 트랜잭션 받아옴
            fnd_tr.display("DRV");          // 디버깅 출력
            @(posedge fnd_intf.PCLK);       // 클럭 동기화
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
            @(posedge fnd_intf.PCLK); // DUT 반응 대기
            @(posedge fnd_intf.PCLK); // 한 클럭 더 대기
            ->gen_next_event;  // event trigger , Generator에게 다음 트랜잭션 준비시키기
        end
    endtask  //run
endclass  //driver

class envirnment; // Generator 와 Driver 연결하고 동시에 실행 
                  // generator 가 만든 트랜잭션을 driver가 처리
    mailbox #(transaction) Gen2Drv_mbox;
    generator fnd_gen;
    driver fnd_drv;
    event gen_next_event;

    function new(virtual APB_Slave_Interface fnd_intf);
        Gen2Drv_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox, gen_next_event);
    endfunction 

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
        join_any
    endtask //run
endclass //envirnment

module tb_fndController_APB ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf(); // interface는 new를 만들어주지 않음

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    Fnd_Ctrl_Periph dut (
    // global signal
        .PCLK(fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),

        .PADDR(fnd_intf.PADDR),
        .PWDATA(fnd_intf.PWDATA),
        .PWRITE(fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),

        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
    // inport signals
        .fndCom(fnd_intf.fndCom),
        .fndFont(fnd_intf.fndFont)
    );

    initial begin
        fnd_intf.PCLK = 0; fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(10);
        #30;
        $finish;
    end
endmodule

