`timescale 1ns / 1ps

module timer_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // export signals
    output logic [31:0] count_data
);

    logic [ 1:0] TCR;
    logic [31:0] TCNT;
    logic [31:0] PSC;
    logic [31:0] ARR;

    assign en = TCR[0];
    assign clear = TCR[1];

    APB_SlaveIntf_timer U_APB_Intf_timer (.*);
    timer U_timer_IP (.*);
endmodule

module APB_SlaveIntf_timer (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic [ 1:0] TCR,
    input  logic [31:0] TCNT,
    output logic [31:0] PSC,
    output logic [31:0] ARR

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign TCR = slv_reg0[1:0];
    assign slv_reg1[31:0] = TCNT;
    assign PSC = slv_reg2[31:0];
    assign ARR = slv_reg3[31:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        //2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module timer (
    input logic PCLK,
    input logic PRESET,
    input logic en,
    input logic clear,
    input logic [31:0] PSC,
    input logic [31:0] ARR,
    output logic [31:0] count_data
);
    logic tick;

    clk_div U_Clk_Div (.*);
    counter U_Counter (.*);
endmodule

module clk_div (
    input logic PCLK,
    input logic PRESET,
    input logic en,
    input logic clear,
    input logic [31:0] PSC,
    output logic tick
);
    logic [31 : 0] div_counter;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            div_counter <= 0;
            tick <= 0;
        end else begin
            if (clear) begin
                div_counter <= 0;
                tick <= 0;
            end else begin
                if (en) begin
                    if (div_counter == PSC - 1) begin
                        div_counter <= 0;
                        tick <= 1;
                    end else begin
                        div_counter = div_counter + 1;
                        tick <= 0;
                    end
                end
            end
        end
    end
endmodule

module counter (
    input logic PCLK,
    input logic PRESET,
    input logic tick,
    input logic clear,
    input logic [31:0] ARR,
    output logic [31:0] count_data
);
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            count_data <= 0;
        end else begin
            if (clear) begin
                count_data <= 0;
            end else begin
                if (count_data == ARR - 1) begin
                    count_data <= 0;
                end else begin
                    if (tick) begin
                        count_data = count_data + 1;
                    end
                end
            end
        end
    end
endmodule
