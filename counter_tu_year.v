module counter_tu_year(
    input clk,
    input rst,
    input [6:0] counter_i,
    input en_i,
    output reg [6:0] counter_o,
    output reg flag_o
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_o <= 7'd0;
            flag_o <= 1'b0;
        end
        else if (en_i) begin
            counter_o <= counter_i;
            flag_o <= 1'b0;
        end
        else begin
            if (counter_o == 7'd99) begin
                counter_o <= 7'd0;
                flag_o <= 1'b1;
            end
            else begin
                counter_o <= counter_o + 1'b1;
                flag_o <= 1'b0;
            end
        end
    end
endmodule