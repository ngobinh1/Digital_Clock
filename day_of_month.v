module day_of_month(month_i, year_i, clk, rst, max_day);
    input [5:0] month_i;
    input [13:0] year_i;
    input clk;
    input rst;
    output reg [5:0] max_day;
    
    always @(clk) begin
        if(rst) begin
            max_day <= 6'd31;
        end
        else begin
            case(month_i)
                6'd1, 6'd3, 6'd5, 6'd7, 6'd8, 6'd10, 6'd12: begin
                    max_day <= 6'd31;
                end
                6'd2: begin
                    if(year_i % 4 == 0)begin
                        max_day <= 6'd29;
                    end
                    else begin
                        max_day <= 6'd28;
                    end
                end
                6'd4, 6'd6, 6'd9, 6'd11: begin
                    max_day <= 6'd30;
                end
                default : max_day <= 6'd31;
            endcase
        end
    end
endmodule