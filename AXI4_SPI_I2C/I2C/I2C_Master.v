`timescale 1ns / 1ps

module I2C_Master(
    input clk,
    input reset,
    input [7:0] tx_data,
    output tx_done,
    output ready,
    input start,
    input stop,
    input I2C_en,
    output reg SCL,
    inout SDA
);

    localparam IDLE   = 0, START1 = 1, START2 = 2, HOLD = 3,
               DATA1  = 4, DATA2  = 5, DATA3  = 6, DATA4 = 7,
               ACK1   = 8, ACK2   = 9, ACK3   = 10, ACK4 = 11,
               STOP1  = 12, STOP2 = 13;

    reg [3:0] state, state_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [$clog2(500)-1:0] clk_count_reg, clk_count_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg flag_reg, flag_next;
    reg rd_wr_reg, rd_wr_next;
    reg tx_done_reg, tx_done_next;
    reg ready_reg, ready_next;
    reg sda_in_reg, sda_in_next;

    assign tx_done = tx_done_reg;
    assign ready   = ready_reg;

    // SDA ���� (Ǯ�� ��ü ���)
    reg sda_out;
    reg sda_oe_reg, sda_oe_next;
    assign SDA = sda_oe_reg ? sda_out : 1'bz;  // Ǯ�� ���� ���� 1 ����
    wire sda_in = SDA;

    // ���� �������� ������Ʈ
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            temp_tx_data_reg <= 0;
            clk_count_reg <= 0;
            bit_count_reg <= 0;
            flag_reg <= 0;
            rd_wr_reg <= 0;
            tx_done_reg <= 0;
            sda_oe_reg <= 0;
            sda_out <= 1;
            ready_reg <= 1;
            sda_in_reg <= 0;
        end else begin
            state <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            clk_count_reg <= clk_count_next;
            bit_count_reg <= bit_count_next;
            flag_reg <= flag_next;
            rd_wr_reg <= rd_wr_next;
            tx_done_reg <= tx_done_next;
            sda_oe_reg <= sda_oe_next;
            sda_out <= sda_out;
            ready_reg <= ready_next;
            sda_in_reg <= sda_in_next;
        end
    end

    // ���±��
    always @(*) begin
        // �⺻�� ����
        state_next = state;
        temp_tx_data_next = temp_tx_data_reg;
        clk_count_next = clk_count_reg;
        bit_count_next = bit_count_reg;
        flag_next = flag_reg;
        rd_wr_next = rd_wr_reg;
        tx_done_next = tx_done_reg;
        ready_next = ready_reg;
        sda_in_next = sda_in_reg;

        sda_out = 1'b1;
        sda_oe_next = sda_oe_reg;
        SCL = 1'b1;

        case (state)
            IDLE: begin
                ready_next = 1;
                tx_done_next = 0;
                if (start && I2C_en) begin
                    state_next = START1;
                    ready_next = 0;
                    temp_tx_data_next = tx_data;
                end
            end

            START1: begin
                sda_out = 0;
                sda_oe_next = 1;
                SCL = 1;
                clk_count_next = (clk_count_reg == 499) ? 0 : clk_count_reg + 1;
                if (clk_count_reg == 499) state_next = START2;
            end

            START2: begin
                sda_out = 0;
                sda_oe_next = 1;
                SCL = 0;
                clk_count_next = (clk_count_reg == 499) ? 0 : clk_count_reg + 1;
                if (clk_count_reg == 499) state_next = HOLD;
            end

            HOLD: begin
                SCL = 0;
                sda_out = 0;
                sda_oe_next = 1;
                if (I2C_en) begin
                    if (sda_in_reg || stop)
                        state_next = STOP1;
                    else if (!start && !stop) begin
                        temp_tx_data_next = tx_data;
                        state_next = DATA1;
                    end
                end else state_next = STOP1;
            end

            DATA1: begin
                SCL = 0;
                sda_out = temp_tx_data_reg[7];  // �׻� 0�� ����� �غ�
                sda_oe_next = 1;
                clk_count_next = (clk_count_reg == 249) ? 0 : clk_count_reg + 1;
                if (clk_count_reg == 249) state_next = DATA2;
            end

            DATA2: begin
                SCL = 1;
                sda_out = temp_tx_data_reg[7];  // �׻� 0�� ����� �غ�
                sda_oe_next = 1;
                // sda_oe_next = 1;
                clk_count_next = (clk_count_reg == 249) ? 0 : clk_count_reg + 1;
                if (clk_count_reg == 249) state_next = DATA3;
            end

            DATA3: begin
                SCL = 1;
                sda_out = temp_tx_data_reg[7];  // �׻� 0�� ����� �غ�
                sda_oe_next = 1;
                // sda_oe_next = 1;
                clk_count_next = (clk_count_reg == 249) ? 0 : clk_count_reg + 1;
                if (clk_count_reg == 249) state_next = DATA4;
            end

            DATA4: begin
                SCL = 0;
                sda_out = temp_tx_data_reg[7];  // �׻� 0�� ����� �غ�
                sda_oe_next = 1;
                // sda_oe_next = 1;
                if (clk_count_reg == 249) begin
                    clk_count_next = 0;
                    if (bit_count_reg == 7) begin
                        tx_done_next = 1;
                        bit_count_next = 0;
                        sda_oe_next = 1;  // release SDA for ACK
                        state_next = ACK1;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        state_next = DATA1;
                    end
                end else clk_count_next = clk_count_reg + 1;
            end

            ACK1: begin SCL = 0; clk_count_next = clk_count_reg + 1; tx_done_next = 0; sda_oe_next = 1; sda_out = 0;
                         if (clk_count_reg == 249) begin clk_count_next = 0; state_next = ACK2; sda_oe_next = 0;end end
            ACK2: begin SCL = 1; clk_count_next = clk_count_reg + 1; sda_oe_next = 0; sda_out = 0;
                         if (clk_count_reg == 249) begin sda_in_next = sda_in; clk_count_next = 0; state_next = ACK3; end end
            ACK3: begin SCL = 1; clk_count_next = clk_count_reg + 1; sda_oe_next = 0; sda_out = 0;
                         if (clk_count_reg == 249) begin clk_count_next = 0; state_next = ACK4; end end
            ACK4: begin SCL = 0; clk_count_next = clk_count_reg + 1; sda_oe_next = 1;sda_oe_next = 1; sda_out = 0;
                         if (clk_count_reg == 249) begin clk_count_next = 0; state_next = HOLD; end end

            STOP1: begin
                SCL = 1;
                sda_out = 0;
                sda_oe_next = 1;
                clk_count_next = clk_count_reg + 1;
                if (clk_count_reg == 499) begin clk_count_next = 0; state_next = STOP2; sda_oe_next = 0;  end
            end

            STOP2: begin
                SCL = 1;
                sda_out = 1;
                sda_oe_next = 1; 
                clk_count_next = clk_count_reg + 1;
                if (clk_count_reg == 499) begin clk_count_next = 0; state_next = IDLE; end
            end
        endcase
    end
endmodule