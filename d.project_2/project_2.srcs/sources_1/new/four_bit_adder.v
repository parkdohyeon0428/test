`timescale 1ns / 1ps

module four_bit_adder(
    input [3:0] A,   // ù ��° 4��Ʈ �Է�
    input [3:0] B,   // �� ��° 4��Ʈ �Է�
    input Cin,       // �Է� ĳ��
    output [3:0] Sum, // �� ���
    output Cout      // ��� ĳ��
);
    
    wire C1, C2, C3; // ���� ĳ�� ��ȣ
    
    // 1��Ʈ Ǯ �ִ� �ν��Ͻ�ȭ
    full_adder FA0 (.A(A[0]), .B(B[0]), .Cin(Cin), .Sum(Sum[0]), .Cout(C1));
    full_adder FA1 (.A(A[1]), .B(B[1]), .Cin(C1), .Sum(Sum[1]), .Cout(C2));
    full_adder FA2 (.A(A[2]), .B(B[2]), .Cin(C2), .Sum(Sum[2]), .Cout(C3));
    full_adder FA3 (.A(A[3]), .B(B[3]), .Cin(C3), .Sum(Sum[3]), .Cout(Cout));
    
endmodule

// 1��Ʈ Ǯ �ִ� ��� ����
module full_adder(
    input A,
    input B,
    input Cin,
    output Sum,
    output Cout
);
    
    assign Sum = A ^ B ^ Cin;
    assign Cout = (A & B) | (B & Cin) | (A & Cin);
    
endmodule

