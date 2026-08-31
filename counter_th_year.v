module counter_th_year(
    input clk,
    input rst,
    input [6:0] counter_i,
    input en_i,
    output reg [6:0] counter_o
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_o <= 7'd20; // Giả sử năm mặc định là 2000+
        end
        else if (en_i) begin
            counter_o <= counter_i;
        end
        else begin
            if (counter_o == 7'd99) begin // Giới hạn năm 9999
                counter_o <= 7'd0;
            end
            else begin
                counter_o <= counter_o + 1'b1;
            end
        end
    end
endmodule