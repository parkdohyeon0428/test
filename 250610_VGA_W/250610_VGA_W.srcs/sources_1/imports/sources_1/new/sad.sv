`timescale 1ns / 1ps

module sad_matcher_top (
    input  logic        clk,
    input  logic        pclk,
    input  logic        rst,
    input  logic [7:0]  left_rgb,
    input  logic [7:0]  right_rgb,
    input  logic        de,
    input  logic [9:0]  x,
    input  logic [9:0]  y,
    input  logic        btn_p1_up,
    input  logic        btn_p1_down,
    input  logic        btn_p2_up,
    input  logic        btn_p2_down,
    output logic [4:0]  disparity
);

    // ===== Parameters =====
    localparam IMG_WIDTH         = 320;
    localparam MAX_DISPARITY     = 31;
    localparam TEXTURE_THRESHOLD = 16'd150;
    localparam UNIQUENESS_MARGIN = 16'd2;

    // ===== Runtime Adjustable Penalties =====
    logic [8:0] P1_reg, P2_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            P1_reg <= 9'd4;
            P2_reg <= 9'd16;
        end else begin
            if (btn_p1_up   && P1_reg < 9'd32) P1_reg <= P1_reg + 1;
            if (btn_p1_down && P1_reg > 0)     P1_reg <= P1_reg - 1;
            if (btn_p2_up   && P2_reg < 9'd64) P2_reg <= P2_reg + 1;
            if (btn_p2_down && P2_reg > 0)     P2_reg <= P2_reg - 1;
        end
    end

    // ===== Internal Variables =====
    logic [7:0] left_buf  [0:IMG_WIDTH-1];
    logic [7:0] right_buf [0:IMG_WIDTH-1];
    logic [4:0] disparity_buffer [0:IMG_WIDTH-1];

    logic [15:0] prev_Lr_horz [0:MAX_DISPARITY];
    logic [15:0] prev_Lr_vert [0:MAX_DISPARITY];
    logic [15:0] Lr_array     [0:MAX_DISPARITY];

    logic [15:0] Ld_minus1, Ld, Ld_plus1, penalty_val;
    logic [15:0] sad, Lr_horz, Lr_vert, Lr_total;
    logic [15:0] minL_horz, minL_vert;
    logic [15:0] best_cost, second_best_cost;
    logic [5:0]  best_disp;

    logic [9:0] proc_x;
    logic [5:0] d;
    logic [4:0] disparity_reg;

    logic line_ready, line_ready_sync1, line_ready_sync2, line_start;

    typedef enum logic [2:0] {
        IDLE, COMPARE, AGGREGATE, SELECT, WRITE
    } fsm_t;

    fsm_t cur_state, next_state;

    // ===== ABS =====
    function automatic [15:0] abs_diff(input [7:0] a, input [7:0] b);
        abs_diff = (a > b) ? (a - b) : (b - a);
    endfunction

    // ===== Buffering =====
    always_ff @(posedge pclk) begin
        if (de) begin
            left_buf[x]  <= left_rgb;
            right_buf[x] <= right_rgb;
        end
        line_ready <= (de && x == IMG_WIDTH - 1);
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            line_ready_sync1 <= 0;
            line_ready_sync2 <= 0;
        end else begin
            line_ready_sync1 <= line_ready;
            line_ready_sync2 <= line_ready_sync1;
        end
    end
    assign line_start = line_ready_sync1 & ~line_ready_sync2;

    // ===== FSM State Control =====
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_state <= IDLE;
            proc_x    <= 1;
            d         <= 0;
            best_cost <= 16'hFFFF;
            second_best_cost <= 16'hFFFF;
            best_disp <= 0;
        end else begin
            cur_state <= next_state;

            case (cur_state)
                IDLE: if (line_start) begin
                    proc_x <= 1;
                    d <= 0;
                    best_cost        <= 16'hFFFF;
                    second_best_cost <= 16'hFFFF;
                    best_disp        <= 0;
                end

                COMPARE: if (proc_x >= 1 && proc_x + d + 1 < IMG_WIDTH && proc_x + 1 < IMG_WIDTH) begin
                    sad <= abs_diff(left_buf[proc_x-1], right_buf[proc_x-1 + d]) +
                           abs_diff(left_buf[proc_x],   right_buf[proc_x   + d]) +
                           abs_diff(left_buf[proc_x+1], right_buf[proc_x+1 + d]);
                end else begin
                    sad <= 16'hFFFF;
                end

                AGGREGATE: begin
                    // Horizontal Aggregation
                    minL_horz = prev_Lr_horz[0];
                    for (int i = 1; i <= MAX_DISPARITY; i++)
                        if (prev_Lr_horz[i] < minL_horz)
                            minL_horz = prev_Lr_horz[i];

                    Ld_minus1 = (d > 0)             ? prev_Lr_horz[d-1] + P1_reg : 16'hFFFF;
                    Ld        =                      prev_Lr_horz[d];
                    Ld_plus1  = (d < MAX_DISPARITY) ? prev_Lr_horz[d+1] + P1_reg : 16'hFFFF;
                    penalty_val = minL_horz + P2_reg;

                    Lr_horz = sad + (
                        (Ld_minus1 < Ld && Ld_minus1 < Ld_plus1 && Ld_minus1 < penalty_val) ? Ld_minus1 :
                        (Ld < Ld_plus1 && Ld < penalty_val) ? Ld :
                        (Ld_plus1 < penalty_val) ? Ld_plus1 : penalty_val
                    ) - minL_horz;

                    // Vertical Aggregation
                    minL_vert = prev_Lr_vert[0];
                    for (int i = 1; i <= MAX_DISPARITY; i++)
                        if (prev_Lr_vert[i] < minL_vert)
                            minL_vert = prev_Lr_vert[i];

                    Ld_minus1 = (d > 0)             ? prev_Lr_vert[d-1] + P1_reg : 16'hFFFF;
                    Ld        =                      prev_Lr_vert[d];
                    Ld_plus1  = (d < MAX_DISPARITY) ? prev_Lr_vert[d+1] + P1_reg : 16'hFFFF;
                    penalty_val = minL_vert + P2_reg;

                    Lr_vert = sad + (
                        (Ld_minus1 < Ld && Ld_minus1 < Ld_plus1 && Ld_minus1 < penalty_val) ? Ld_minus1 :
                        (Ld < Ld_plus1 && Ld < penalty_val) ? Ld :
                        (Ld_plus1 < penalty_val) ? Ld_plus1 : penalty_val
                    ) - minL_vert;

                    // Aggregated Cost
                    Lr_total = (Lr_horz + Lr_vert) >> 1;
                    Lr_array[d] <= Lr_total;
                end

                SELECT: begin
                    if (Lr_array[d] < best_cost) begin
                        second_best_cost <= best_cost;
                        best_cost        <= Lr_array[d];
                        best_disp        <= d;
                    end else if (Lr_array[d] < second_best_cost) begin
                        second_best_cost <= Lr_array[d];
                    end
                end

                WRITE: begin
                    if (d == MAX_DISPARITY) begin
                        if (best_cost < TEXTURE_THRESHOLD &&
                            (second_best_cost - best_cost) > UNIQUENESS_MARGIN)
                            disparity_buffer[proc_x] <= best_disp;
                        else
                            disparity_buffer[proc_x] <= 0;

                        for (int i = 0; i <= MAX_DISPARITY; i++) begin
                            prev_Lr_horz[i] <= Lr_array[i];
                            prev_Lr_vert[i] <= Lr_array[i];
                        end

                        proc_x <= (proc_x >= IMG_WIDTH - MAX_DISPARITY - 2) ? 1 : proc_x + 1;
                        d      <= 0;
                        best_cost        <= 16'hFFFF;
                        second_best_cost <= 16'hFFFF;
                        best_disp        <= 0;
                    end else begin
                        d <= d + 1;
                    end
                end
            endcase
        end
    end

    // ===== FSM Transition =====
    always_comb begin
        next_state = cur_state;
        case (cur_state)
            IDLE:      if (line_start) next_state = COMPARE;
            COMPARE:                   next_state = AGGREGATE;
            AGGREGATE:                next_state = SELECT;
            SELECT:                   next_state = WRITE;
            WRITE:                    next_state = COMPARE;
        endcase
    end

    // ===== Output =====
    always_ff @(posedge pclk)
        disparity_reg <= disparity_buffer[x];
    assign disparity = disparity_reg;

endmodule
