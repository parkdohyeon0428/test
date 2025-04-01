
module MUX_2X1 (
    input switch_mode,
    input [3:0] msec_sec/humidity,
    input [3:0] min_hour/temperature,
    output reg [3:0] bcd
);
    always @(*) begin
        case (switch_mode)
          1'b0 : bcd = msec_sec/humidity;
          1'b1 : bcd = min_hour/temperature;
            default: bcd = 4'hf;
        endcase
    end
endmodule

