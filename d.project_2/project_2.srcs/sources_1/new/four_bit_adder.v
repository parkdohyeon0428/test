`timescale 1ns / 1ps

module four_bit_adder(
    input [3:0] A,   // 첫 번째 4비트 입력
    input [3:0] B,   // 두 번째 4비트 입력
    input Cin,       // 입력 캐리
    output [3:0] Sum, // 합 결과
    output Cout      // 출력 캐리
);
    
    wire C1, C2, C3; // 내부 캐리 신호
    
    // 1비트 풀 애더 인스턴스화
    full_adder FA0 (.A(A[0]), .B(B[0]), .Cin(Cin), .Sum(Sum[0]), .Cout(C1));
    full_adder FA1 (.A(A[1]), .B(B[1]), .Cin(C1), .Sum(Sum[1]), .Cout(C2));
    full_adder FA2 (.A(A[2]), .B(B[2]), .Cin(C2), .Sum(Sum[2]), .Cout(C3));
    full_adder FA3 (.A(A[3]), .B(B[3]), .Cin(C3), .Sum(Sum[3]), .Cout(Cout));
    
endmodule

// 1비트 풀 애더 모듈 정의
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

