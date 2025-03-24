// module clock_cu (
//     input clk, reset,
//     input i_btn_start,
//     input [1:0] sw,
//     output reg o_start
// );
//     localparam STOP = 1'b0, RUN = 1'b1;    
//     reg state, next;

//     // state register
//     always @(posedge clk, posedge reset) begin
//         if(reset) begin
//             state <= STOP;
//         end else begin
//             state <= next;
//         end
//     end

//     always @(*) begin
//         next <= state;
//         case (state)
//            STOP :begin
//               if (i_btn_start == 1 && sw[1] == 1) begin
//                 next <= RUN;
//               end
//            end
//     endcase
//     end

//     always @(*) begin
//         o_start = 1'b0;
//         case (state)
//            STOP : begin
//               o_start = 1'b0;
//            end
//            RUN : begin
//               o_start = 1'b1;
//            end
//     endcase
//     end

// endmodule