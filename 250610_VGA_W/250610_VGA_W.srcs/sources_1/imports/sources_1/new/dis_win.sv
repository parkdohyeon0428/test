`timescale 1ns / 1ps

module disparity_generator(
    input  logic        rclk,
    input  logic        vga_clk,
    input  logic        reset,
    input  logic [44:0] wData1,
    input  logic [44:0] wData2,
    input  logic [16:0] rAddr,
    input  logic        oe,
    input  logic [9:0]  x_pixel,
    output logic [15:0] DisplayData
);

    localparam DISPARITY_MAX     = 60;
    localparam FRAME_WIDTH       = 320;
    localparam BUFFER_WIDTH      = 320;
    localparam HAMMING_THRESHOLD = 6'd8;   // ★ fallback 기준

    logic [44:0] leftBuffer [0 : BUFFER_WIDTH - 1];
    logic [44:0] rightBuffer[0 : BUFFER_WIDTH - 1];
    logic [15:0] displayBuffer[0 : BUFFER_WIDTH - 1];

    logic [44:0] rData1_d0;
    logic [44:0] rData2_0, rData2_1, rData2_2, rData2_3, rData2_4;
    logic [5:0]  h0, h1, h2, h3, h4;

    logic [1:0]  state, state_next;
    logic [5:0]  disparity, disparity_next;
    logic [5:0]  best_disp, best_disp_next;
    logic [5:0]  best_score, best_score_next;
    logic [9:0]  rAddr1, rAddr1_next;
    logic [5:0]  prev_disp; // ★ fallback용 이전 disparity 저장

    assign DisplayData = {11'd0, displayBuffer[x_pixel % 320]};

    always_ff @(posedge vga_clk) begin
        if (oe) begin
            leftBuffer[rAddr % BUFFER_WIDTH]  <= wData1;
            rightBuffer[rAddr % BUFFER_WIDTH] <= wData2;
        end
    end

    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            state       <= 0;
            disparity   <= 0;
            best_disp   <= 0;
            best_score  <= 6'd63;
            rAddr1      <= 0;
            prev_disp   <= 0; // ★ 초기화
            rData2_0 <= 0; rData2_1 <= 0; rData2_2 <= 0; rData2_3 <= 0; rData2_4 <= 0;
            for (int i = 0; i < BUFFER_WIDTH; i++)
                displayBuffer[i] <= 0;
        end else begin
            state       <= state_next;
            disparity   <= disparity_next;
            best_disp   <= best_disp_next;
            best_score  <= best_score_next;
            rAddr1      <= rAddr1_next;
            rData1_d0   <= leftBuffer[rAddr1];
            rData2_0 <= rightBuffer[(rAddr1 + disparity    ) % BUFFER_WIDTH];
            rData2_1 <= rightBuffer[(rAddr1 + disparity + 1) % BUFFER_WIDTH];
            rData2_2 <= rightBuffer[(rAddr1 + disparity + 2) % BUFFER_WIDTH];
            rData2_3 <= rightBuffer[(rAddr1 + disparity + 3) % BUFFER_WIDTH];
            rData2_4 <= rightBuffer[(rAddr1 + disparity + 4) % BUFFER_WIDTH];

            if (state == 2) begin
                // ★ fallback 적용
                if (best_score > HAMMING_THRESHOLD)
                    displayBuffer[rAddr1] <= prev_disp;
                else
                    displayBuffer[rAddr1] <= best_disp;

                prev_disp <= best_disp;
            end
        end
    end

    function automatic [5:0] popcount(input logic [44:0] bits);
        integer i;
        begin
            popcount = 0;
            for (i = 0; i < 45; i = i + 1)
                popcount += bits[i];
        end
    endfunction

    always_comb begin
        state_next        = state;
        disparity_next    = disparity;
        best_disp_next    = best_disp;
        best_score_next   = best_score;
        rAddr1_next       = rAddr1;

        h0 = popcount(rData1_d0 ^ rData2_0);
        h1 = popcount(rData1_d0 ^ rData2_1);
        h2 = popcount(rData1_d0 ^ rData2_2);
        h3 = popcount(rData1_d0 ^ rData2_3);
        h4 = popcount(rData1_d0 ^ rData2_4);

        case (state)
            0: begin
                if (rAddr % BUFFER_WIDTH == BUFFER_WIDTH - 1) begin
                    state_next        = 1;
                    rAddr1_next       = 0;
                    disparity_next    = 0;
                    best_score_next   = 6'd63;
                end
            end

            1: begin
                if (disparity + 0 <= DISPARITY_MAX && h0 < best_score_next) begin
                    best_score_next = h0;
                    best_disp_next  = disparity + 0;
                end
                if (disparity + 1 <= DISPARITY_MAX && h1 < best_score_next) begin
                    best_score_next = h1;
                    best_disp_next  = disparity + 1;
                end
                if (disparity + 2 <= DISPARITY_MAX && h2 < best_score_next) begin
                    best_score_next = h2;
                    best_disp_next  = disparity + 2;
                end
                if (disparity + 3 <= DISPARITY_MAX && h3 < best_score_next) begin
                    best_score_next = h3;
                    best_disp_next  = disparity + 3;
                end
                if (disparity + 4 <= DISPARITY_MAX && h4 < best_score_next) begin
                    best_score_next = h4;
                    best_disp_next  = disparity + 4;
                end

                if (disparity + 5 > DISPARITY_MAX) begin
                    state_next = 2;
                end else begin
                    disparity_next = disparity + 5;
                end
            end

            2: begin
                if (rAddr1 == BUFFER_WIDTH - 1) begin
                    state_next = 0;
                end else begin
                    rAddr1_next     = rAddr1 + 1;
                    disparity_next  = 0;
                    best_score_next = 6'd63;
                    state_next      = 1;
                end
            end
        endcase
    end

endmodule
