
`timescale 1 ns / 1 ps

	module myip_spi_master_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output wire SCLK,
		output wire MOSI,
		input wire MISO,
        output wire SS,
        input wire slv_ready,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	wire [2:0] CR;
	wire [7:0] sod;
	wire [7:0] sid;
	wire [5:0] sr;

// Instantiation of Axi Bus Interface S00_AXI
	myip_spi_master_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_spi_master_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
        .CR(CR),
		.sod(sod),
		.sid(sid),
		.sr(sr)
	);


    SPI_Master U_SPI_Master(
    // global signals
        .clk(s00_axi_aclk),
        .reset(~s00_axi_aresetn),
    // SPI signals
        .start(CR[0]),
        .cpol(CR[1]),     // clock polarity
        .cpha(CR[2]),     // clock phase
        .tx_data(sod),
        .rx_data(sid),
        .ready(),
        .done(),
    // external port
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .slv_ready(slv_ready), // slave ready signal
        .SS(SS),
        .read_count (sr[2:0]),
        .write_count(sr[5:3])
);

	// User logic ends

	endmodule

`timescale 1ns / 1ps

module SPI_Master (
    // global signals
    input            clk,
    input            reset,
    input            start,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output reg       done,
    output reg       ready,
    // SPI signals
    input            cpol,     // clock polarity
    input            cpha,     // clock phase
    // external port
    input           slv_ready, // slave ready signal
    output           SCLK,
    output           MOSI,
    input            MISO,
    output reg       SS,
    input [2:0] read_count,
    input [2:0] write_count
);
    reg [2:0] rd_cnt_reg, rd_cnt_next; // 현재 read 한 개수
    reg [2:0] read_count_reg,read_count_next; // 인풋값 받아서 캡처
    reg [2:0] wr_cnt_reg, wr_cnt_next;
    reg [2:0] write_count_reg, write_count_next;

    reg rd_wr_reg, rd_wr_next;

    localparam IDLE = 0, CP_DELAY = 1, CP0= 2, CP1 = 3, BURST = 4;

    //reg r_sclk;
    wire r_sclk;
    reg [3:0] state, state_next;
    reg [5:0] sclk_counter_reg, sclk_counter_next;  //6bit
    reg [2:0] bit_counter_reg, bit_counter_next;  //3bit
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;

    assign MOSI = temp_tx_data_reg[7];
    assign rx_data = temp_rx_data_reg;
    assign r_sclk = ((state_next == CP1 &&~cpha) || (state_next == CP0 && cpha));
    // cpha = 1 이면 CP0에서 SCLK가 올라가고, cpha = 0 이면 CP1에서 SCLK가 올라감
    assign SCLK = cpol ? ~r_sclk : r_sclk; 
    // cpol = 1 이면 SCLK가 반전, cpol = 0 이면 SCLK가 그대로



    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
            rd_cnt_reg<=0;
            read_count_reg<=0;
            rd_wr_reg<=0;
            wr_cnt_reg<=0;
            write_count_reg<=0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            rd_cnt_reg <= rd_cnt_next;
            read_count_reg<=read_count_next;
            rd_wr_reg <=rd_wr_next;
            write_count_reg <= write_count_next;
            wr_cnt_reg <= wr_cnt_next;
        end
    end

    always @(*) begin
        state_next        = state;
        done              = 1'b0;
        ready             = 1'b0;
        // r_sclk            = 1'b0;
        temp_rx_data_next = temp_rx_data_reg;
        temp_tx_data_next = temp_tx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        rd_cnt_next = rd_cnt_reg;
        read_count_next = read_count_reg;
        rd_wr_next = rd_wr_reg;
        write_count_next = write_count_reg;
        wr_cnt_next = wr_cnt_reg;
        SS = 1; // SS는 기본적으로 1로 설정
        case (state)
            IDLE: begin
                SS = 1;
                temp_tx_data_next = 0;
                done              = 1'b0;
                ready             = 1'b1;
                rd_cnt_next = 0;
                wr_cnt_next = 0;
                read_count_next=0;
                write_count_next=0;
                if (start) begin
                    state_next        = cpha ? CP_DELAY : CP0;  // cpha = 1 이면 CP_DELAY, cpha = 0 이면 CP0 
                    temp_tx_data_next = tx_data;
                    rd_wr_next = tx_data[7];
                    ready             = 1'b0;
                    sclk_counter_next = 1'b0;
                    bit_counter_next  = 1'b0;
                    read_count_next = read_count;
                    write_count_next = write_count;
                end
            end
            CP_DELAY: begin
                SS = 0;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 1'b0;
                    state_next        = CP0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP0: begin
                SS = 0;
               // r_sclk = 1'b0;
                if (sclk_counter_reg == 49) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MISO};
                    sclk_counter_next = 1'b0;
                    state_next        = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                SS = 0;
                // r_sclk = 1'b1;
                if (sclk_counter_reg == 49) begin
                    if (bit_counter_reg == 7) begin
                        done       = 1'b1;
                        sclk_counter_next = 1'b0;
                        state_next = BURST;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        sclk_counter_next = 1'b0;
                        bit_counter_next  = bit_counter_reg + 1;
                        state_next        = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            BURST : begin
                SS = 0;
                 if (!rd_wr_reg) begin // read burst
                            if (read_count_reg == rd_cnt_reg) begin
                                state_next = IDLE;
                            end else begin
                                if (slv_ready) begin
                                    rd_cnt_next = rd_cnt_reg+1;
                                    temp_tx_data_next = 8'h00;
                                    state_next = CP0;
                                    bit_counter_next = 0;
                                end
                            end
                        end else begin // write burst
                            if (write_count_reg == wr_cnt_reg) begin
                                state_next = IDLE;
                            end else begin
                                if (slv_ready == 1'b1) begin
                                    wr_cnt_next = wr_cnt_reg+1;
                                    temp_tx_data_next = tx_data;
                                    state_next = CP0;
                                    bit_counter_next=0;
                                end
                            end
                        end


            end
        endcase
    end
endmodule