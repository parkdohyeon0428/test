`timescale 1ns / 1ps
module Top_Upcounter (
    input clk,
    input reset,
    input [2:0] sw,
    output [3:0] seg_comm,
    output [7:0] seg
);

    wire [13:0] w_count;
    wire w_clk_10, w_run_stop, w_clear;
    wire w_tick_100hz;

      tick_100hz U_Tick_100hz (
        .clk(clk),  // 100Mhz
        .reset(reset),
        .run_stop(w_run_stop),
        .o_tick_100hz(w_tick_100hz)

    );
    counter_10000 U_counter_10000 (
        .clk(w_clk_10),
        .reset(reset),
        .clear(w_clear),            // clear
        .count(w_count)          // 14비트
    );

    fnd_controller U_fnd_cntl (
        .clk(clk),
        .reset(reset),
        .bcd(w_count),
        .seg(seg),
        .seg_comm(seg_comm)
    );
        control_unit U_ConTrol_unit (
        .clk(clk),
        .reset(reset),
        .i_run_stop(sw[0]),
        .i_clear(sw[1]),
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

module counter_10000 (
    input clk,
    input reset,
    input clear,
    output [13:0] count
);
    //reg [$clog2(10000)-1:0] r_counter;
    reg [13:0] r_counter;
    assign count = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            if (r_counter == 10000 - 1) begin
                r_counter <= 0;
            end else begin
                r_counter <= r_counter + 1;
            end
            if (clear == 1'b1) begin
                r_counter <= 0;
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
                if(i_run_stop == 1'b0) begin
                    next = STOP;
                end else begin
                    next = state;
                end
            end
            STOP: begin
                if (i_clear == 1'b0) begin
                    next = STOP;
                end 
            end
            default: begin 
                next  = STOP;
            end
        endcase
    end

    

    // combination output logic
    always @(*) begin
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
                o_run_stop = 1'b0;
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





