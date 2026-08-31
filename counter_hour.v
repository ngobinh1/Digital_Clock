module counter_hour(
    input clk,
    input rst,
    input [5:0] counter_i,
    input en_i,
    output reg [5:0] counter_o,
    output reg flag_o
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_o <= 6'd0;    // Reset về 0 giờ
            flag_o <= 1'b0;
        end
        else if (en_i) begin     // Nếu có tín hiệu ghi đè
            counter_o <= counter_i;
            flag_o <= 1'b0;
        end
        else begin       // Nếu được phép đếm
            if (counter_o == 6'd23) begin  // Nếu đạt 23 giờ
                counter_o <= 6'd0;         // Reset về 0
                flag_o <= 1'b1;            // Báo tràn
            end
            else begin
                counter_o <= counter_o + 1'b1; // Tăng giờ
                flag_o <= 1'b0;
            end
        end
    end
endmodule