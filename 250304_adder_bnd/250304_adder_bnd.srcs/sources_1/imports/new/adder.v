`timescale 1ns / 1ps


module calculator(
    input clk,
    input reset,
    // adder_8
    input [7:0] a,
    input [7:0] b,
    // 7-seg 출력력
    output [3:0] seg_comm,
    output [7:0] seg
);

    wire w_c; 
    wire [7:0] w_s;     

    FA_8bit U_FA_8bit(
        .a(a), 
        .b(b),
        .s(w_s),
        .c(w_c)
    );

    fnd_controller U_fnd_controller(
        .clk(clk),
        .reset(reset),
        .bcd({w_c, w_s}),      // 9bit
        .seg(seg),
        .seg_comm(seg_comm)
    );

endmodule

// adder core
module FA_8bit(
    input [7:0] a,
    input [7:0] b,
    output [7:0] s,
    output c
);

    wire w_c;

    FA_4bit U_FA_4_upper(
        .a(a[7:4]), 
        .b(b[7:4]),
        .cin(w_c),
        .s(s[7:4]),
        .c(c)
    );

    FA_4bit U_FA_4_lower(
        .a(a[3:0]), 
        .b(b[3:0]),
        .cin(1'b0),
        .s(s[3:0]),
        .c(w_c)
    );

endmodule

module FA_4bit(
    input [3:0] a, 
    input [3:0] b,
    input cin,
    output [3:0] s,
    output c
);
    
    wire [3:0] w_c;
    assign c = w_c[3];

    full_adder U_FA0(
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .s(s[0]),
        .c(w_c[0])
    );

    full_adder U_FA1(
        .a(a[1]),
        .b(b[1]),
        .cin(w_c[0]),
        .s(s[1]),
        .c(w_c[1])
    );

    full_adder U_FA2(
        .a(a[2]),
        .b(b[2]),
        .cin(w_c[1]),
        .s(s[2]),
        .c(w_c[2])
    );

    full_adder U_FA3(
        .a(a[3]),
        .b(b[3]),
        .cin(w_c[2]),
        .s(s[3]),
        .c(w_c[3])
    );

endmodule

module full_adder(
    input a,
    input b,
    input cin,
    output s,
    output c
);

    wire w_s;
    wire w_c1, w_c2;
    assign c =  w_c1 | w_c2;
    
    half_adder U_HA1(
        .a(a),
        .b(b),
        .s(w_s),
        .c(w_c1)
    );


    half_adder U_HA2(
        .a(w_s),
        .b(cin),
        .s(s),
        .c(w_c2)
    );

    
endmodule

module half_adder(
    input a,  // 1bit wire
    input b,

    output s,
    output c
);

    // assign s = a ^ b;
    // assign c = a & b;

    // 게이트 프리미티브 방식 : verilog에서 제공됨
    xor(s, a, b);   // xor(output, input0, input1, ...)
    and(c, a, b);   // and(output, input0, input1, ...)

endmodule
