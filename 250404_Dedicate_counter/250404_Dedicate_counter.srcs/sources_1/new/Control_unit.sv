`timescale 1ns / 1ps

module control_unit (
    input logic clk,
    input logic reset,
    output logic AsrcSel,
    output logic en,
    input logic alt10,
    output logic outbuf
);
    parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4;
    logic [2:0] state,next;

    always_ff @( posedge clk, posedge reset) 
    begin 
        if(reset)begin
            state <= 0;
        end
        else begin
            state <= next;
        end
    end

    always_comb begin
        next = state;
        en = 0;
        AsrcSel = 0;
        outbuf = 0;
    case (state)
        S0: begin
            AsrcSel =0;
            en =1;
            outbuf = 0;
            next =S1;
        end 
        S1: begin
            if(alt10) begin
                AsrcSel = 1;
                en = 1;
                outbuf = 0;
                next = S2;
            end
            else begin
                next = S4;
            end
        end 
        S2: begin
            AsrcSel = 0;
            en = 0;
            outbuf = 1;
            next = S3;
        end 
        S3: begin
            AsrcSel = 1;
            en = 1;
            outbuf = 0;
            next =S1;
        end 
        S4: begin
            AsrcSel = 0;
            en = 0;
            outbuf = 0;
            next =S4;
        end         
    endcase
    end
endmodule
