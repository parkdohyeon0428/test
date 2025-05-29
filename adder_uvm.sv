interface spi_if();
    // global signals
    logic clk;
    logic reset;
    // internal signals
    logic CPOL;
    logic CPHA;
    logic start;
    logic SS;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic done;
    logic ready;
endinterface //spi_if()

`include "uvm_macros.svh"
import uvm_pkg::*;

class spi_seq_item extends uvm_sequence_item;
    rand bit [7:0] tx_data;
         bit [7:0] rx_data;
         bit       done;

    `uvm_object_utils_begin(spi_seq_item)
    `uvm_field_int(tx_data, UVM_DEFAULT)
    `uvm_field_int(rx_data, UVM_DEFAULT)
    `uvm_field_int(done, UVM_DEFAULT)
    `uvm_object_utils_end

    // function void do_pack();
    //     tx_data = {wr, data, addr};
    // endfunction

    function new(string name = "ITEM");
        super.new(name);
    endfunction

endclass

class spi_sequence extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_sequence) // 왜 object util이냐면 uvm_sequence는 uvm_component에서 받아오는게 아님
    // uvm 클래스 구성도 보면 나와 있음
    function new(string name = "SEQ"); // component 상속이 아니니까 인스턴스도 name만 적으면 됨
        super.new(name);
    endfunction

    spi_seq_item spi_item;

    virtual task body();
        // write 
        spi_item = spi_seq_item::type_id::create("write");
        repeat (100)  begin       
            `uvm_info(get_type_name(), 
            "Starting SPI sequence", UVM_MEDIUM)
            start_item(spi_item);
            if (!spi_item.randomize()) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            `uvm_info(get_type_name(), 
            $sformatf("Sent tx_data = %0d", spi_item.tx_data), UVM_MEDIUM)
            finish_item(spi_item);
        end
    endtask
endclass       

class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    function new(string name = "DRV", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_seq_item spi_item;
    virtual spi_if a_if;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_item = spi_seq_item::type_id::create("spi_ITEM");

        if(!uvm_config_db#(virtual spi_if)::get(this, "*", "a_if", a_if))
            `uvm_fatal("DRV", "spi_if not found in uvm_config_db");
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(spi_item); // 대기
            // 초기
            //  @(posedge a_if.clk);
            //  @(posedge a_if.clk);
             
            // `uvm_info("DRV", "Waiting for a_if.reset to become 1", UVM_MEDIUM)
            // wait (a_if.reset == 0);  // write 주소 전송
            // `uvm_info("DRV", "Detected reset == 1", UVM_MEDIUM)
            a_if.CPOL <= 1'b0;
            a_if.CPHA <= 1'b0;
            a_if.start <= 1'b0;
            a_if.tx_data <= {1'b1,spi_item.tx_data[6:0]}; // write 주소 전송
            //@(posedge a_if.clk);
            a_if.SS <= 1'b1;
            @(posedge a_if.clk);
            // spi start addr 
            a_if.SS <= 1'b0;
            //@(posedge a_if.clk);
            a_if.start <= 1'b1;
            @(posedge a_if.clk);
            a_if.start <= 1'b0;
            // wait
            //`uvm_info("DRV", "Waiting for first done to become 1", UVM_MEDIUM)
            wait (a_if.done == 1);  // write 주소 전송 끝
            //`uvm_info("DRV", "Detected first done == 1", UVM_MEDIUM)
            @(posedge a_if.clk);
            a_if.tx_data <= spi_item.tx_data;
            `uvm_info("DRV", $sformatf("Drive DUT addr:%0d, data:%0d", spi_item.tx_data[1:0], spi_item.tx_data), UVM_LOW)
            // spi data start
            //@(posedge a_if.clk);
            a_if.start <= 1'b1;
            @(posedge a_if.clk);
            a_if.start <= 1'b0;
            // wait


            wait (a_if.done == 1);  // write 끝 
            @(posedge a_if.clk); 
            a_if.tx_data <= {1'b0,spi_item.tx_data[6:0]}; // read 주소 전송
            //@(posedge a_if.clk);
            a_if.SS <= 1'b1; 
            @(posedge a_if.clk);
            // spi start addr 
            a_if.SS <= 1'b0;
           // @(posedge a_if.clk);
            a_if.start <= 1'b1;
            @(posedge a_if.clk);
            a_if.start <= 1'b0;
            // wait
            wait (a_if.done == 1);  
            @(posedge a_if.clk);
            a_if.tx_data <= 8'b10101010;  // dummy data 전송
            // spi data start
            //@(posedge a_if.clk);
            a_if.start <= 1'b1;
            @(posedge a_if.clk);
            a_if.start <= 1'b0;
            // wait
            wait (a_if.done == 1);
            `uvm_info("DRV", "read data send done ", UVM_MEDIUM)
            @(posedge a_if.clk);
            a_if.SS <= 1'b1; // read 끝

            //spi_item.print(uvm_default_line_printer);
            @(posedge a_if.clk);
            #1;
            seq_item_port.item_done(); // 다 받았다고 event 던지기 sqr에
           // #10;
        end
    endtask
endclass

class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)
    
    uvm_analysis_port #(spi_seq_item) send; // item을 tr이라고 생각하고 mbox에 send한다고 생각하면 됨
    spi_seq_item spi_item; // handler
    virtual spi_if a_if;

    function new(string name = "MON", uvm_component parent);
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_item = spi_seq_item::type_id::create("SPI_ITEM");
        if(!uvm_config_db#(virtual spi_if)::get(this, "", "a_if", a_if))
            `uvm_fatal("MON", "spi_if not found in uvm_config_db");
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            //#10;
            @(posedge a_if.done);
            @(posedge a_if.done);
            spi_item.tx_data = a_if.tx_data; // write 한 data scoreboard에 전송

            @(posedge a_if.done);
            @(posedge a_if.done);
            spi_item.rx_data = a_if.rx_data; // read한 data scoreboard에 전송

            `uvm_info("MON", 
                $sformatf("sampled tx_data:%0d, rx_data:%0d", spi_item.tx_data, spi_item.rx_data), UVM_LOW)
            //adder_item.print(uvm_default_line_printer);

            send.write(spi_item); // send to scoreboard
        end
    endtask
endclass

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) recv;
    spi_seq_item spi_item;

    int total_cnt = 0;
    int pass_cnt  = 0;
    int fail_cnt  = 0;

    function new(string name = "SCO", uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_item = spi_seq_item::type_id::create("spi_ITEM");
    endfunction

    virtual function void write(spi_seq_item item);
        spi_item = item;
        total_cnt++;
        if (spi_item.rx_data === spi_item.tx_data) begin
            pass_cnt++;
            `uvm_info("SCOREBOARD", $sformatf("PASS  tx_data=%0d == rx_data=%0d",
                                               spi_item.tx_data, spi_item.rx_data), UVM_LOW)
        end else begin
            fail_cnt++;
            `uvm_error("SCOREBOARD", $sformatf("FAIL  tx_data=%0d != rx_data=%0d",
                                                spi_item.tx_data, spi_item.rx_data))
        end
    endfunction

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("SCOREBOARD", "================== SPI TEST REPORT ==================", UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL: %0d | PASS: %0d | FAIL: %0d",
                                           total_cnt, pass_cnt, fail_cnt), UVM_NONE)
        `uvm_info("SCOREBOARD", "======================================================", UVM_NONE)
    endfunction

endclass

class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)
    function new(string name = "AGT", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_monitor spi_mon; // handler 생성
    spi_driver spi_drv;
    uvm_sequencer #(spi_seq_item) spi_sqr;

    virtual function void build_phase(uvm_phase phase); // 핸들러 만든거에 인스턴스 한 값을 넣어주기
        super.build_phase(phase);
        spi_mon = spi_monitor::type_id::create("MON", this);
        spi_drv = spi_driver::type_id::create("DRV", this);
        spi_sqr = uvm_sequencer#(spi_seq_item)::type_id::create("SQR", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        spi_drv.seq_item_port.connect(spi_sqr.seq_item_export);
        //spi_mon.send.connect(env.scoreboard.recv);
    endfunction

endclass

class spi_environment extends uvm_env;
    `uvm_component_utils(spi_environment) // Factory에 등록

    function new(string name = "ENV", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_scoreboard spi_sco;
    spi_agent spi_agt;
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_sco = spi_scoreboard::type_id::create("SCO", this);
        spi_agt = spi_agent::type_id::create("AGT", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase); // agt안의 mon과 scb 사이 연결 통로를 만들어줘야 함
        super.connect_phase(phase);
        spi_agt.spi_mon.send.connect(spi_sco.recv); // TLM Port 연결 transaction level modeling
    endfunction

endclass

class test extends uvm_test; // uvm_test 라이브러리 상속 받기
    `uvm_component_utils(test) // Factory에 등록 매크로

    function new(string name = "TEST", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_sequence spi_seq;
    spi_environment spi_env;

    virtual function void build_phase(uvm_phase phase); // overriding -> 부모 클래스가 함수 이름만 가지고
        super.build_phase(phase);
        spi_seq = spi_sequence::type_id::create("SEQ", this); // spi_seq = new(); 이거랑 비슷한 거임
        spi_env = spi_environment::type_id::create("ENV", this); // -> "Factory에서 실행됐다"
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase); // overriding 자식이 그 함수 구현을 하는 것
        phase.raise_objection(this); // drop 전까지 시뮬 멈추지 않게
        spi_seq.start(spi_env.spi_agt.spi_sqr); // seq -> sequence / sqr -> sequnecer 둘이 다른 거임
        phase.drop_objection(this);  // objection 해제, run phase 종료
    endtask
endclass

module tb_spi;
    //test spi_test;
    spi_if a_if();

    spi dut(
        .clk(a_if.clk),
        .reset(a_if.reset),
        .CPOL(a_if.CPOL),
        .CPHA(a_if.CPHA),
        .start(a_if.start),
        .wr_cnt(a_if.wr_cnt)
        .rd_cnt(a_if.rd_cnt),
        .tx_data(a_if.tx_data),
        .rx_data(a_if.rx_data),
        .done(a_if.done),
        .ready(a_if.ready)
    );
    always #5 a_if.clk = ~a_if.clk;

    initial begin       
        uvm_config_db#(virtual spi_if)::set(null, "*", "a_if", a_if);
        a_if.clk = 0;
        run_test(); 
       
    end

    initial begin
        a_if.reset = 1;
        #5;
        a_if.reset = 0;
    end

endmodule



