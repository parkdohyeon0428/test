`timescale 1ns / 1ps


module tb_four_bit_adder;
    reg [3:0] A;
    reg [3:0] B;
    reg Cin;
    wire [3:0] Sum;
    wire Cout;
    
    four_bit_adder UUT (.A(A), .B(B), .Cin(Cin), .Sum(Sum), .Cout(Cout));
    
    initial begin
        $monitor("A = %b, B = %b, Cin = %b, Sum = %b, Cout = %b", A, B, Cin, Sum, Cout);
        
        A = 4'b0000; B = 4'b0000; Cin = 0; #10;
        A = 4'b0001; B = 4'b0001; Cin = 0; #10;
        A = 4'b0011; B = 4'b0011; Cin = 0; #10;
        A = 4'b0101; B = 4'b0011; Cin = 0; #10;
        A = 4'b1111; B = 4'b1111; Cin = 1; #10;
        
        $finish;
    end
endmodule

