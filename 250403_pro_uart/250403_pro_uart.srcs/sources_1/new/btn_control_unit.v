`timescale 1ns / 1ps

module btn_control_unit (
    input            clk,
    input            reset,
    input            run_stop,
    input            btn_clear,
    input            btnD,
    input            updown,
    //data path
    output reg       en,
    output reg       clear,
    output reg       mode,
    output reg       main_mode
);
    localparam STOP = 0, RUN = 1, CLEAR = 2;
    localparam UP = 0, DOWN = 1;
    localparam STOPWATCH = 0, COUNT = 1;
    reg [1:0] state, state_next;
    reg mode_state, mode_state_next;
    reg main_mode_state, main_mode_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
            mode_state <= UP;
            main_mode_state <= STOPWATCH;
        end else begin
            state <= state_next;
            mode_state <= mode_state_next;
            main_mode_state <= mode_state_next;
        end
    end

    

    always @(*) begin
        main_mode_next = main_mode_state;
        main_mode = 1'b0;
        case (main_mode_state)
            STOPWATCH: begin
                main_mode = 1'b0;
                if (btnD) begin
                    main_mode_next = COUNT;
                end
            end 
            COUNT: begin
                main_mode = 1'b1;
                if (btnD) begin
                    main_mode_next = STOPWATCH;
                end
            end
        endcase
    end

    always @(*) begin
        mode_state_next = mode_state;
        mode = 1'b0;
        case (mode_state)
            UP: begin
                mode = 1'b0;
                if (updown) begin
                    mode_state_next = DOWN;
                end
            end 
            DOWN: begin
                mode = 1'b1;
                if (updown) begin
                    mode_state_next = UP;
                end
            end
        endcase
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        case (state)
            STOP: begin
                en = 1'b0;
                clear = 1'b0;
                if (run_stop) begin
                    state_next = RUN;
                end
                else begin
                    if (btn_clear) state_next = CLEAR;
                end
            end
            RUN: begin
                en = 1'b1;
                clear = 1'b0;
                if (run_stop) state_next = STOP;
            end
            CLEAR: begin
                en = 1'b0;
                clear = 1'b1;
                if (btn_clear == 1'b0)
                    state_next = STOP;
            end
        endcase
    end
endmodule

