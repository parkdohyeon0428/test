interface adder_if();
    logic clk;
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] y;
endinterface //adder_if()

`include "uvm_macros.svh"
import uvm_pkg::*;

class adder_seq_item extends uvm_sequence_item;
    rand bit [7:0] a;
    rand bit [7:0] b;
         bit [8:0] y;
    function new(string name = "ITEM");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(adder_seq_item)
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end

endclass

class adder_sequence extends uvm_sequence #(adder_seq_item);
    `uvm_object_utils(adder_sequence) // 왜 object util이냐면 uvm_sequence는 uvm_component에서 받아오는게 아님
    // uvm 클래스 구성도 보면 나와 있음
    function new(string name = "SEQ"); // component 상속이 아니니까 인스턴스도 name만 적으면 됨
        super.new(name);
    endfunction

    adder_seq_item adder_item;

    virtual task body();
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");
        
        for (int i=0;i<10;i++) begin
            start_item(adder_item); // 등록록

            adder_item.randomize();
            `uvm_info("SEQ", $sformatf("adder item to driver a:%0d, b:%0d", adder_item.a, adder_item.b), UVM_NONE)
            //adder_item.print(uvm_default_line_printer);
            finish_item(adder_item);
        end
    endtask

endclass

class adder_driver extends uvm_driver #(adder_seq_item);
    `uvm_component_utils(adder_driver)

    function new(string name = "DRV", uvm_component parent);
        super.new(name, parent);
    endfunction

    adder_seq_item adder_item;
    virtual adder_if a_if;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");

        if(!uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if))
            `uvm_fatal("DRV", "adder_if not found in uvm_config_db");
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(adder_item); // 대기
            @(posedge a_if.clk);

            a_if.a = adder_item.a;
            a_if.b = adder_item.b;
            `uvm_info("DRV", $sformatf("Drive DUT a:%0d, b:%0d", adder_item.a, adder_item.b), UVM_LOW)
            //adder_item.print(uvm_default_line_printer);

            seq_item_port.item_done(); // 다 받았다고 event 던지기 sqr에
           // #10;
        end
    endtask

endclass

class adder_monitor extends uvm_monitor;
    `uvm_component_utils(adder_monitor)
    
    uvm_analysis_port #(adder_seq_item) send; // item을 tr이라고 생각하고 mbox에 send한다고 생각하면 됨
    
    function new(string name = "MON", uvm_component parent);
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction

    adder_seq_item adder_item; // handler
    virtual adder_if a_if;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");
        if(!uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if))
            `uvm_fatal("MON", "adder_if not found in uvm_config_db");
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            //#10;
            @(posedge a_if.clk);
            #1;
            adder_item.a = a_if.a;
            adder_item.b = a_if.b;
            adder_item.y = a_if.y;

            `uvm_info("MON", 
                $sformatf("sampled a:%0d, b:%0d, y:%0d", adder_item.a, adder_item.b, adder_item.y), UVM_LOW)
            //adder_item.print(uvm_default_line_printer);

            send.write(adder_item); // send to scoreboard
        end
    endtask

endclass

class adder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(adder_scoreboard)
    // mbox
    uvm_analysis_imp #(adder_seq_item, adder_scoreboard) recv;

    adder_seq_item adder_item;

    function new(string name = "SCO", uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");
    endfunction

    virtual function void write(adder_seq_item item);
        adder_item = item;
        `uvm_info("SCO", $sformatf("Received a:%0d, b:%0d, y:%0d", item.a, item.b, item.y), UVM_LOW)
        //adder_item.print(uvm_default_line_printer);

        if(adder_item.y == adder_item.a + adder_item.b)
            `uvm_info("SCO", "*** TEST PASSED ***", UVM_NONE)
        else
            `uvm_error("SCO", "*** TEST FAILED ***");
    endfunction

endclass

class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent)
    function new(string name = "AGT", uvm_component parent);
        super.new(name, parent);
    endfunction

    adder_monitor adder_mon; // handler 생성
    adder_driver adder_drv;
    uvm_sequencer #(adder_seq_item) adder_sqr;

    virtual function void build_phase(uvm_phase phase); // 핸들러 만든거에 인스턴스 한 값을 넣어주기
        super.build_phase(phase);
        adder_mon = adder_monitor::type_id::create("MON", this);
        adder_drv = adder_driver::type_id::create("DRV", this);
        adder_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SQR", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_drv.seq_item_port.connect(adder_sqr.seq_item_export);
    endfunction

endclass

class adder_envirenment extends uvm_env;
    `uvm_component_utils(adder_envirenment) // Factory에 등록

    function new(string name = "ENV", uvm_component parent);
        super.new(name, parent);
    endfunction

    adder_scoreboard adder_sco;
    adder_agent adder_agt;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_sco = adder_scoreboard::type_id::create("SCO", this);
        adder_agt = adder_agent::type_id::create("AGT", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase); // agt안의 mon과 scb 사이 연결 통로를 만들어줘야 함
        super.connect_phase(phase);
        adder_agt.adder_mon.send.connect(adder_sco.recv); // TLM Port 연결 transaction level modeling
    endfunction

endclass

class test extends uvm_test; // uvm_test 라이브러리 상속 받기
    `uvm_component_utils(test) // Factory에 등록 매크로

    function new(string name = "TEST", uvm_component parent);
        super.new(name, parent);
    endfunction

    adder_sequence adder_seq;
    adder_envirenment adder_env;

    virtual function void build_phase(uvm_phase phase); // overriding -> 부모 클래스가 함수 이름만 가지고
        super.build_phase(phase);
        adder_seq = adder_sequence::type_id::create("SEQ", this); // adder_seq = new(); 이거랑 비슷한 거임
        adder_env = adder_envirenment::type_id::create("ENV", this); // -> "Factory에서 실행됐다"
    endfunction

    virtual task run_phase(uvm_phase phase); // overriding 자식이 그 함수 구현을 하는 것
        phase.raise_objection(phase); // drop 전까지 시뮬 멈추지 않게
        adder_seq.start(adder_env.adder_agt.adder_sqr); // seq -> sequence / sqr -> sequnecer 둘이 다른 거임
        phase.drop_objection(phase); // objection 해제, run phase 종료
    endtask

endclass

module tb_adder;
    test adder_test;
    adder_if a_if();

    adder dut(
        .a(a_if.a),
        .b(a_if.b),
        .y(a_if.y)
    );

    always #5 a_if.clk = ~a_if.clk;

    initial begin
        a_if.clk = 0;

        adder_test = new("TEST", null); // test class 생성
        uvm_config_db #(virtual adder_if)::set(null, "*", "a_if", a_if); // interface 연결

        run_test();
    end

endmodule
