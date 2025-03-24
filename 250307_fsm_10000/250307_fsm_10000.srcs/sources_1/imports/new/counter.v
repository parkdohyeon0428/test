`timescale 1ns / 1ps
module Top_Upcounter (
    input clk,
    input reset,
    // input [2:0] sw,
    input BTN_run_stop,
    input BTN_clear,
    output [3:0] seg_comm,
    output [7:0] seg
);

    wire [13:0] w_count;
    wire w_clk_10, w_run_stop, w_clear;
    wire o_btn_run_stop, o_btn_clear;
    wire w_tick_100hz;
    wire w_tick_msec;

      tick_100hz U_Tick_100hz (
        .clk(clk),  // 100Mhz
        .reset(reset),
        .run_stop(w_run_stop),
        .o_tick_100hz(w_tick_100hz)

    );
    counter_tick U_Counter_Tick (
        .clk(clk),
        .reset(reset),
        .tick(w_tick_100hz),
        .clear(w_clear),
        .counter(w_count),
        .o_tick(w_tick_msec)
    );
    /*
    counter_tick #(.TICK_COUNT (60))U_Counter_Tick (
        .clk(clk),
        .reset(reset),
        .tick(w_tick_100hz),
        .clear(w_clear),
        .counter(w_count)
    ); */
    fnd_controller U_fnd_cntl (
        .clk(clk),
        .reset(reset),
        .bcd(w_count),
        .seg(seg),
        .seg_comm(seg_comm)
    );
    btn_debounce U_Btn_Debounce_RUN_STOP(
        .clk(clk),
        .reset(reset),
        .i_btn(BTN_run_stop),  // from btn
        .o_btn(o_btn_run_stop) // to control unit
    );
    btn_debounce U_Btn_Debounce_CLEAR(
        .clk(clk),
        .reset(reset),
        .i_btn(BTN_clear),
        .o_btn(o_btn_clear)
    );
    control_unit U_ConTrol_unit (
        .clk(clk),
        .reset(reset),
        .i_run_stop(o_btn_run_stop),
        .i_clear(o_btn_clear),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );
    
endmodule

//tick generater
module tick_100hz (
    input  clk,  // 100Mhz
    input  reset,
    input run_stop,
    output o_tick_100hz
);

    reg [$clog2(1_000_000)-1:0] r_counter;
    reg r_tick_100hz;

    assign o_tick_100hz = r_tick_100hz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  // 리셋상태
            r_tick_100hz <= 0;
            //r_clk <= 1'b0;
        end else begin
            if (run_stop == 1'b1) begin
                // clock divide 계산, 
                if (r_counter == (1_000_000 - 1)) begin
                    r_counter  <= 0;
                    r_tick_100hz <= 1'b1;
                    //r_clk <= 1'b1;  // r_clk : 0->1
                end else begin
                    r_counter <= r_counter + 1;
                    r_tick_100hz <= 1'b0;
                end
            end 
        end
    end

endmodule

module counter_tick #(parameter TICK_COUNT = 10_000) (    //100hz
    input clk,
    input reset,
    input tick,
    input clear,
    output [$clog2(TICK_COUNT)-1:0] counter,
    output o_tick   //100진 나갈 때때 마다 출력
);
    //       state                           next
    reg [$clog2(TICK_COUNT)-1:0]counter_reg, counter_next;
    reg r_tick;
    assign counter = counter_reg;
    assign o_tick = r_tick;
    // state
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end 
    end

    // next
    always @(*) begin
        counter_next = counter_reg;
        r_tick = 1'b0;
        if(clear == 1'b1) begin
            counter_next = 0;
        end else if (tick == 1'b1) begin  // tick count
            if (counter_reg == TICK_COUNT-1) begin
                counter_next = 0;
                r_tick = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                r_tick = 1'b0;
            end
        end
    end

endmodule

module control_unit (
    input clk,
    input reset,
    input i_run_stop,
    input i_clear,
    output reg o_run_stop,
    output reg o_clear
);
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010;
    // state 관리
    reg [2:0] state, next;

    // state sequencial logic
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
        end else begin
            state <= next;
        end
    end

    // next combinational logic
    always @(*) begin
        next = state;
        
        case (state)
            STOP: begin
                if (i_run_stop == 1'b1) begin
                    next = RUN;
                end else if (i_clear == 1'b1) begin
                    next = CLEAR;
                end else begin
                    next = state;
                end
            end 
            RUN: begin
                if(i_run_stop == 1'b1) begin
                    next = STOP;
                end else if (i_clear == 1'b1) begin
                    next = CLEAR;
                end else begin
                    next = state;
                end
            end
            CLEAR: begin
                if (i_clear == 1'b0) begin
                    next = STOP;
                end 
            end
            default: begin 
                next  = state;
            end
        endcase
    end

    

    // combination output logic
    always @(*) begin
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        case (state)
            STOP: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
            end 
             RUN: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
            end 
            CLEAR: begin
         //       o_run_stop = 1'b1;
                o_clear = 1'b1;
            end
            default: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
            end
        endcase
        
    end
endmodule

            // clock divide 계산, 
            /*if (r_counter == (10_000_000 - 1)) begin
                r_counter  <= 0;
                r_clk_10hz <= 1'b1;
                //r_clk <= 1'b1;  // r_clk : 0->1
            end else if (r_counter == (10_000_000 / 2) - 1) begin
                // duty radio 50%
                r_clk_10hz <= 1'b0;
                r_counter  <= r_counter + 1;
            end else begin
                r_counter <= r_counter + 1;
            end*/
      
/*
module clk_100hz_tick (
    input clk,
    input reset,
    input run_stop,
    output o_tick_100hz
);
    parameter FCOUNT = 1_000_000;
    parameter RUN = 1'b1, STOP = 1'b0;
    reg state, next;
    
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk_100hz;
    // always 구문에 reg 출력을 위해서
    assign o_tick_100hz = r_clk_100hz;  

    // state 저장
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= 0;
        end else begin
            state <= next;
        end 
    end
    // next combinattion
    always @(*) begin
        next = state; // latch 제거용용
        case (state)
           STOP : begin
              if(run_stop == 1'b1) begin
                 next = RUN;
            end 
           end 
           RUN : begin
              if (run_stop == 1'b0) begin
                  next = STOP;
              end
           end
            default: next = state;
        endcase
    end

    always @(*) begin
        r_counter = 0;
        case (state)
           RUN : begin
            if(r_counter == (FCOUNT -1)) begin   // 100hz
                r_counter = 0;
                r_clk_100hz = 1'b1; // 출력 클럭을 high
            end else begin
                r_counter = r_counter + 1;
                r_clk_100hz = 1'b0;
            end
           end 
            default: 
        endcase
    end

endmodule */





