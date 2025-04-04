`timescale 1ns / 1ps

module counter_stopwatch (
    input         clk,
    input         reset,
    input         en,
    input         clear,
    input         main_mode,
    output   [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;
    

    clk_div_10hz_1 U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .en   (en),
        .clear(clear)
    );
    stopwatch_counter U_STOP(
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .main_mode (main_mode),
        .en   (en),
        .clear(clear),
        .count(count)
    );
    
    comp_dot1 U_Comp_Dot (
        .count(count),
        .dot_data(dot_data)
    );
endmodule

// module counter_msec (
//     input  clk,
//     input  reset,
//     input  tick,
//     output [3:0] o_time,
//     output o_tick
// );
//     parameter TICK_COUNT = 10;
//     // BIT_WIDTH = 7
//     reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
//     //reg [BIT_WIDTH-1:0] count_reg, count_next;
//     reg tick_reg, tick_next;

//     assign o_time = count_reg;
//     assign o_tick = tick_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             count_reg <= 0;
//             tick_reg  <= 0;
//         end else begin
//             count_reg <= count_next;
//             tick_reg  <= tick_next;
//         end
//     end

//     always @(*) begin
//         count_next = count_reg;
//         tick_next  = tick_reg;
//         if (tick == 1'b1) begin
//             if (count_reg == TICK_COUNT - 1) begin
//                 count_next = 0;
//                 tick_next  = 1'b1;
//             end else begin
//                 count_next = count_reg + 1;
//                 tick_next  = 1'b0;
//             end
//         end
//     end

// endmodule


module stopwatch_counter (
    input         clk,
    input         reset,
    input         tick,
    input         main_mode,
    input         en,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (clear) begin
                counter <= 0;
            end else begin
                if (en) begin
                    if (tick) begin
                        if (counter == 10000) begin
                            counter <= 1;
                        end

                        else begin
                            if(counter % 1000 == 599) begin
                                counter <= counter + 401;
                            end
                            else begin
                            counter <= counter + 1;
                            end
                        end
                    end
                end
            end
        end


    end
endmodule



module clk_div_10hz_1 (
    input  wire clk,
    input  wire reset,
    input  wire en,
    input  wire clear,
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (en) begin
                if (div_counter == 10_000_000 - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
            if (clear) begin
                div_counter <= 0;
                tick <= 1'b0;
            end
        end
    end
endmodule

module comp_dot1 (
    input  [13:0] count,
    output [ 3:0] dot_data
);
    assign dot_data = ((count % 10) < 5) ? (4'b0111 & 4'b1101) : 4'b1111;
endmodule
