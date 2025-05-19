`timescale 1ns / 1ps

module SPI_Slave ();
endmodule

module SPI_Slave_Intf (
    input        reset,
    // external signals
    input        SCLK,
    input        MOSI,
    output       MISO,
    input        SS,
    // internal signals
    output reg   done,
    output reg   write,
    output reg [1:0] addr,
    output reg [7:0] wdata,
    input  [7:0] rdata
);

    localparam IDLE = 0, CP0 = 1, CP1 = 2;

    reg [1:0] state, next;
    reg [7:0] temp_tx_data_reg, temp_rx_data_reg;
    reg [7:0] temp_tx_data_next, temp_rx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;

    assign MISO = SS ? 1'bz : temp_tx_data_reg[7];
    // assign addr = temp_rx_data_reg[1:0];
    // assign wdata = temp_tx_data_reg;

    // MOSI sequence
    always @(posedge SCLK) begin
        if (SS == 1'b0) begin
            temp_rx_data_reg <= {temp_rx_data_reg[6:0], MOSI};
        end
    end

    // MISO Sequece
    always @(negedge SCLK) begin
        //temp_tx_data_reg <= rdata;
        if (SS == 1'b0) begin
            temp_tx_data_reg <= {rdata[6:0], 1'b0}; 
        end
    end 

    // always @(*) begin
    //     case (state)
    //     next = state;
    //     temp_tx_data_next = temp_tx_data_reg;
    //         SO_IDLE: begin
    //             if (SS == 1'b0 && rd_en) begin
    //                 temp_tx_data_next = rdata;
    //                 next = SO_DATA;
    //             end
    //         end
    //         SO_DATA: begin
    //             if (SS == 1'b0 && rd_en) begin
    //                 temp_tx_data_next = 
    //             end
    //         end 
    //     endcase
    // end

    always @(posedge SCLK, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            bit_counter_reg <= 0;
        end else begin
            state <= next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            bit_counter_reg <= bit_counter_next;
        end
    end


    always @(*) begin
        next = state;
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        bit_counter_next = bit_counter_reg;
        wdata = 0;
        addr = 0;
        write = 0;
        done = 0;
        case (state)
            IDLE: begin
                if (SS == 1'b0) begin
                   temp_tx_data_next = rdata;
                   next = CP0;
               end 
            end
            CP0: begin
                //if (SCLK == 1'b1) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MOSI};
                    next = CP1;
               // end
            end
            CP1: begin
                //if (SCLK == 1'b0) begin
                    if (bit_counter_reg == 7) begin
                        done = 1;
                        bit_counter_next = 0;
                        addr = temp_rx_data_reg[1:0];
                        wdata = temp_rx_data_reg;
                        if (temp_rx_data_reg[7] == 1) begin
                            write = 1;
                        end else begin
                            write = 0;
                        end
                        next = IDLE;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1;
                        next = CP0;
                    end
                //end
            end
        endcase
    end
endmodule
