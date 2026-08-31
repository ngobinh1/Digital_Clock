module counter_sec(
    input clk,
    input rst,
    output reg [5:0] counter_o,
    output reg flag_o
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_o <= 6'd0;
            flag_o <= 1'b0;
        end
        else begin
            if (counter_o == 6'd59) begin
                counter_o <= 6'd0;
                flag_o <= 1'b1;
            end
            else begin
                counter_o <= counter_o + 1'b1;
                flag_o <= 1'b0;
            end
        end
    end
endmodule