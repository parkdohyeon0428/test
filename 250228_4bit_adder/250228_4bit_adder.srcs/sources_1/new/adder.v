`timescale 1ns / 1ps

module calculator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] btn,
    output c_led,
    output [7:0] seg,
    output [3:0] seg_comm
);
    wire [7:0] w_sum;
    fnd_controller U_controller(
        .bcd(w_sum),
        .seg_sel(btn),
        .seg(seg),
        .seg_comm(seg_comm)

);
    fa_8 U_8(
        .a(a),
        .b(b),
        .s(w_sum),
        .c(c_led)
    );


endmodule

module fa_8 (
    input [7:0] a, // 4bit vector 형
    input [7:0] b,
    //input cin,
    output [7:0] s,
    output c
);
    wire [7:0] w_c;
    full_adder U_fa0(
        .a(a[0]),
        .b(b[0]),
        .cin(1'b0),
        .s(s[0]),
        .c(w_c[0])
    );
    full_adder U_fa1(
        .a(a[1]),
        .b(b[1]),
        .cin(w_c[0]),
        .s(s[1]),
        .c(w_c[1])
    );
    full_adder U_fa2(
        .a(a[2]),
        .b(b[2]),
        .cin(w_c[1]),
        .s(s[2]),
        .c(w_c[2])
    );
    full_adder U_fa3(
        .a(a[3]),
        .b(b[3]),
        .cin(w_c[2]),
        .s(s[3]),
        .c(w_c[3])
    );
    full_adder U_fa4(
        .a(a[4]),
        .b(b[4]),
        .cin(w_c[3]),
        .s(s[4]),
        .c(w_c[4])
    );
    full_adder U_fa5(
        .a(a[5]),
        .b(b[5]),
        .cin(w_c[4]),
        .s(s[5]),
        .c(w_c[5])
    );
    full_adder U_fa6(
        .a(a[6]),
        .b(b[6]),
        .cin(w_c[5]),
        .s(s[6]),
        .c(w_c[6])
    );
    full_adder U_fa7(
        .a(a[7]),
        .b(b[7]),
        .cin(w_c[6]),
        .s(s[7]),
        .c(c)
    );
    

endmodule

module full_adder (
    input a,
    input b,
    input cin,
    output s,
    output c
    
);
    wire w_s, w_c1, w_c2;
    assign c = w_c1 | w_c2;

    half_adder U_ha1(
        .a( a ),
        .b( b ),
        .sum(w_s),
        .c( w_c1 )
    );
    half_adder U_ha2(
        .a( w_s ),
        .b( cin ),
        .sum( s ),
        .c( w_c2 )
    );

endmodule

module half_adder (
    input  a,    // 1bit wire
    input  b,
    output sum,
    output c
);

    //assign sum = a ^ b;
    //assign c = a & b;
    // 게이트 프리미티브 : Verilog lib 기본 
    xor (sum, a, b); // (출력, 입력0, 입력1 ...)
    and (c, a, b);



endmodule
