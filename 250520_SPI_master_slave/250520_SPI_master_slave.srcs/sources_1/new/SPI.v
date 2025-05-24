`timescale 1ns / 1ps

module SPI (
    // global signals
    input            clk,
    input            reset,
    // internal signals
    input            CPOL,
    input            CPHA,
    input            start,
    input            SS,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output           done,
    output           ready
);
    wire w_ss, SCLK, MOSI, MISO;

    SPI_Master U_master(
    // global signals
        .clk(clk),
        .reset(reset),
    // internal signals
        .CPOL(CPOL),
        .CPHA(CPHA),
        .start(start),
        .SS(SS),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done(done),
        .ready(ready),
    // external port
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .ss(w_ss)
    );
    SPI_Slave U_slave(

    //global signals
        .clk(clk),
        .reset(reset),
    //SPI signals
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .SS(w_ss)
    );

endmodule

module SPI_Master (
    // global signals
    input            clk,
    input            reset,
    // internal signals
    input            CPOL,
    input            CPHA,
    input            start,
    input            SS,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output reg       done,
    output reg       ready,
    // external port
    output           SCLK,
    output           MOSI,
    input            MISO,
    output           ss
);
    localparam IDLE = 0, CP_DELAY = 1, CP0 = 2, CP1 = 3;

    wire r_sclk;
    reg [1:0] state, next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [5:0] sclk_counter_next, sclk_counter_reg;
    reg [2:0] bit_counter_next, bit_counter_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;

    //assign tx_data = temp_tx_data_reg;
    assign MOSI = temp_tx_data_reg[7];
    assign rx_data = temp_rx_data_reg;

    assign ss = SS;

    assign r_sclk = ((next == CP1) && ~CPHA) || 
                    ((next == CP0) && CPHA);
    assign SCLK = CPOL ? ~r_sclk : r_sclk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
        end else begin
            state            <= next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
        end
    end

    always @(*) begin
        next              = state;
        ready             = 0;
        done              = 0;
        temp_rx_data_next = temp_rx_data_reg;
        temp_tx_data_next = temp_tx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        case (state)
            IDLE: begin
                temp_tx_data_next = 0;
                ready             = 1;
                done              = 0;
                if (start) begin
                    next = CPHA ? CP_DELAY : CP0; // 삼항연산자 잘 쓰기
                    temp_tx_data_next = tx_data;
                    ready = 0;
                    sclk_counter_next = 0;
                    bit_counter_next = 0;
                end
            end
            CP_DELAY: begin
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 0;
                    next = CP0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP0: begin
                if (sclk_counter_reg == 49) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MISO};
                    sclk_counter_next = 0;
                    next = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                if (sclk_counter_reg == 49) begin
                    if (bit_counter_reg == 7) begin
                        done = 1;
                        bit_counter_next = 0;
                        next = IDLE;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        sclk_counter_next = 0;
                        bit_counter_next = bit_counter_reg + 1;
                        next = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule

module SPI_Slave (

    //global signals
    input             clk,
    input             reset,
    //SPI signals
    input             SCLK,
    input             MOSI,
    output            MISO,
    input             SS
);
    //internal signals
           wire [7:0] si_data;
           wire       si_done;
           wire [7:0] so_data;
           wire       so_start;
           wire       so_done;

    SPI_Slave_Intf U_SPI_Slave_Intf (
        //global signals
        .clk(clk),
        .reset(reset),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .SS(SS),
        .si_data(si_data),
        .si_done(si_done),
        .so_data(so_data),
        .so_start(so_start),
        .so_done(so_done)
    );

    SPI_Slave_Reg U_SPI_Slave_Reg (
        //global signals
        .clk(clk),
        .reset(reset),
        .SCLK(SCLK),
        .ss_n(SS),
        .si_data(si_data),
        .si_done(si_done),
        .so_data(so_data),
        .so_start(so_start),
        .so_done(so_done)
    );

endmodule

module SPI_Slave_Intf (
    //global signals
    input        clk,
    input        reset,
    //SPI signals
    input        SCLK,
    input        MOSI,
    output       MISO,
    input        SS,
    //internal signals
    output [7:0] si_data,
    output       si_done,
    input  [7:0] so_data,
    input        so_start,
    output       so_done
    //output       so_ready
);
    reg sclk_sync0, sclk_sync1;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 1'b0;
            sclk_sync1 <= 1'b0;
        end else begin
            sclk_sync0 <= SCLK;
            sclk_sync1 <= sclk_sync0;
        end
    end

    wire sclk_rising = sclk_sync0 & ~sclk_sync1;
    wire sclk_falling = ~sclk_sync0 & sclk_sync1;

    // Slave Input Circuit (MOSI) ==> Master Out
    localparam SI_IDLE = 0, SI_PHASE = 1;
    reg si_state, si_state_next;
    reg [7:0] si_data_reg, si_data_next;
    reg [2:0] si_bit_count_reg, si_bit_count_next;
    reg si_done_reg, si_done_next;

    assign si_data = si_data_reg;
    assign si_done = si_done_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            si_state         <= SI_IDLE;
            si_data_reg      <= 0;
            si_bit_count_reg <= 0;
            si_done_reg      <= 0;
        end else begin
            si_state         <= si_state_next;
            si_data_reg      <= si_data_next;
            si_bit_count_reg <= si_bit_count_next;
            si_done_reg      <= si_done_next;
        end
    end

    always @(*) begin
        si_state_next     = si_state;
        si_data_next      = si_data_reg;
        si_bit_count_next = si_bit_count_reg;
        si_done_next      = si_done_reg;
        case (si_state)
            SI_IDLE: begin
                si_done_next = 0;
                if (!SS) begin
                    si_bit_count_next = 0;
                    si_state_next     = SI_PHASE;
                end
            end
            SI_PHASE: begin
                if (!SS) begin
                    if (sclk_rising) begin
                        si_data_next = {si_data_reg[6:0], MOSI};
                        if (si_bit_count_reg == 7) begin
                            si_bit_count_next = 0;
                            si_done_next      = 1'b1;
                            si_state_next     = SI_IDLE;
                        end else begin
                            si_bit_count_next = si_bit_count_reg + 1;
                        end
                    end
                end else begin
                    si_state_next = SI_IDLE;
                end
            end
        endcase
    end

    // Slave Output Circuit (MI_SO) ==> Master in
    localparam SO_IDLE = 0, SO_PHASE = 1, SO_DELAY = 2;
    reg [1:0] so_state, so_state_next;
    reg [7:0] so_data_reg, so_data_next;
    reg [2:0] so_bit_count_reg, so_bit_count_next;
    reg so_done_reg, so_done_next;


    assign so_done = so_done_reg;
    assign MISO = SS ? 1'bz : so_data_reg[7];


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            so_state         <= SO_IDLE;
            so_data_reg      <= 0;
            so_bit_count_reg <= 0;
            so_done_reg      <= 0;
        end else begin
            so_state         <= so_state_next;
            so_data_reg      <= so_data_next;
            so_bit_count_reg <= so_bit_count_next;
            so_done_reg      <= so_done_next;
        end
    end

    always @(*) begin
        so_state_next     = so_state;
        so_bit_count_next = so_bit_count_reg;
        so_done_next      = so_done_reg;
        so_data_next      = so_data_reg;
        case (so_state)
            SO_IDLE: begin
                so_done_next = 1'b0;
                if (!SS && so_start) begin
                    so_bit_count_next = 0;
                    so_data_next      = so_data;
                    so_state_next     = SO_PHASE;
                end
            end
            SO_PHASE: begin
                if (!SS) begin
                    if (sclk_falling) begin
                        so_data_next = {so_data_reg[6:0], 1'b0};
                        if (so_bit_count_reg == 7) begin
                            so_bit_count_next = 0;
                            so_done_next      = 1'b1;
                            so_state_next     = SO_DELAY;
                            // so_state_next     = SO_IDLE;
                        end else begin
                            so_bit_count_next = so_bit_count_reg + 1;
                        end
                    end
                end else begin
                    so_state_next = SO_IDLE;
                end
            end

            SO_DELAY : begin
               
                so_state_next = SO_IDLE;
                so_done_next = 1'b0;
            end
        endcase
    end
endmodule

module SPI_Slave_Reg (
    //global signals
    input            clk,
    input            reset,
    // internal signals
    input SCLK,
    input            ss_n,
    input      [7:0] si_data,
    input            si_done,
    //input            so_ready,
    output reg [7:0] so_data,
    output           so_start,
    input            so_done
    //output reg r_done
);

    localparam IDLE = 0, ADDR_PHASE = 1, WRITE_PHASE = 2, READ_PHASE = 3, READ_DELAY_PHASE=4;

    reg [2:0] state, state_next;
    reg [7:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    reg [1:0] addr_reg, addr_next;
    reg so_start_reg, so_start_next;

    reg prev_SCLK;

    reg prev_so_done;
    assign so_done_rising = ~prev_so_done & so_done;

    assign so_start = so_start_reg;

    assign sclk_falling = prev_SCLK & ~SCLK;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            addr_reg     <= 0;
            so_start_reg <= 1'b0;
            prev_so_done <=0;
            prev_SCLK<=0;
        end else begin
            state        <= state_next;
            addr_reg     <= addr_next;
            so_start_reg <= so_start_next;
            prev_so_done <= so_done;
            prev_SCLK <= SCLK;
        end
    end

    always @(*) begin
        state_next    = state;
        addr_next     = addr_reg;
        so_start_next = so_start_reg;
        so_data       = 8'b0;
        case (state)
            IDLE: begin
                so_start_next = 1'b0;
                if (!ss_n) begin
                    state_next = ADDR_PHASE;
                end
            end
            ADDR_PHASE: begin
                if (!ss_n) begin
                    if (si_done) begin
                        addr_next = si_data[1:0];  // address
                        if (si_data[7]) begin  // write operation
                            state_next = WRITE_PHASE;
                        end else begin  // read operation
                            state_next = READ_DELAY_PHASE;
                            // so_start_next = 1'b1;
                           
                        end
                    end
                end else begin
                    state_next = IDLE;
                end
            end
            READ_DELAY_PHASE : begin
                if (sclk_falling) begin
                    state_next = READ_PHASE;
                end
            end
            
            WRITE_PHASE: begin  // write operation
                if (!ss_n) begin
                    if (si_done) begin
                        case (addr_reg)
                            2'd0: slv_reg0 <= si_data;
                            2'd1: slv_reg1 <= si_data;
                            2'd2: slv_reg2 <= si_data;
                            2'd3: slv_reg3 <= si_data;
                        endcase
                        if (addr_reg == 2'd3) begin
                            addr_next = 0;
                        end else begin
                            addr_next = addr_reg + 1;
                        end
                    end
                end else begin
                    state_next = IDLE;
                end
            end
            READ_PHASE: begin  // read operation
                if (!ss_n) begin
                    //if (so_ready) begin
                    so_start_next = 1'b1;
                    case (addr_reg)
                        2'd0: so_data = slv_reg0;
                        2'd1: so_data = slv_reg1;
                        2'd2: so_data = slv_reg2;
                        2'd3: so_data = slv_reg3;
                    endcase
                    //end
                    if (so_done_rising) begin
                        if (addr_reg == 2'd3) begin
                            addr_next = 0;
                        end else begin
                            addr_next = addr_reg + 1;
                        end
                    end
                end else begin
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule
