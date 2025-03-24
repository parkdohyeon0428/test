`timescale 1ns / 1ps

module mux_4x1(
    input [3:0] a,b,c,d,
    input [1:0] sel,
    output reg [3:0] mux_out
);
always @(sel,a,b,c,d) begin
    case (sel)
       0 : mux_out = a;
       1 : mux_out = b;
       2 : mux_out = c;
       3 : mux_out = d; 
        default: mux_out = 4'bx;
    endcase
end    
endmodule 

/*  
    always @(sel,a,b,c,d) begin
        if (sel ==2'b00) mux_out =a;
        else if (sel ==2'b00) mux_out =b;
        else if (sel ==2'b00) mux_out =c;
        else if (sel ==2'b00) mux_out =d;
        else mux_out = 4'bx;
    end
    
    assign mux_out = (sel == 0) ? a :         //reg 불필요
                     (sel == 0) ? b :
                     (sel == 0) ? c :
                     (sel == 0) ? d : 4'bx; */



