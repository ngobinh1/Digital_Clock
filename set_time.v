module set_time (
    input clk,
    input rst,
    input inc,
    input [2:0] en_set_time,
    input [1:0] mode_state,
    output reg [5:0] set_min_out,
    output reg [5:0] set_hour_out,
    output reg [5:0] set_day_out,
    output reg [5:0] set_month_out,
    output reg [6:0] set_th_year_out,
    output reg [6:0] set_tu_year_out,
    output reg en_min,
    output reg en_hour,
    output reg en_day,
    output reg en_month,
    output reg en_th_year,
    output reg en_tu_year
);

// Previous mode state to detect transition
reg [1:0] prev_mode_state;

// Edge detection for inc signal
//reg inc_prev;
//wire inc_edge;
//assign inc_edge = inc & ~inc_prev;

// Function to determine if a year is leap year
function [5:0] get_max_day;
        input [5:0] month;
        input [6:0] th_year;
        input [6:0] tu_year;
        reg is_leap_year;
        begin
            
            
            // Simple leap year calculation for years 2000-2099
            
                is_leap_year = ((tu_year % 4) == 0);
            
            
            case (month)
                6'd1, 6'd3, 6'd5, 6'd7, 6'd8, 6'd10, 6'd12: get_max_day = 6'd31; // Jan, Mar, May, Jul, Aug, Oct, Dec
                6'd4, 6'd6, 6'd9, 6'd11: get_max_day = 6'd30; // Apr, Jun, Sep, Nov
                6'd2: begin // February
                    if (is_leap_year)
                        get_max_day = 6'd29;
                    else
                        get_max_day = 6'd28;
                end
                default: get_max_day = 6'd31;
            endcase
        end
    endfunction

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset outputs
        set_min_out <= 6'd0;
        set_hour_out <= 6'd0;
        set_day_out <= 6'd1;
        set_month_out <= 6'd1;
        set_th_year_out <= 7'd20;
        set_tu_year_out <= 7'd25;
        
        // Reset enable signals
        en_min <= 1'b0;
        en_hour <= 1'b0;
        en_day <= 1'b0;
        en_month <= 1'b0;
        en_th_year <= 1'b0;
        en_tu_year <= 1'b0;
        
        prev_mode_state <= 2'b00;
        //inc_prev <= 1'b0;
    end else begin
        //inc_prev <= inc;
        
        // Only allow setting when in set time mode (mode_state == 2'b01)
        if (mode_state == 2'b01) begin
            if (inc) begin
                case (en_set_time)
                    3'b001: begin // Set minute
                        if (set_min_out == 6'd59)
                            set_min_out <= 6'd0;
                        else
                            set_min_out <= set_min_out + 1;
                    end
                    3'b010: begin // Set hour
                        if (set_hour_out == 6'd23)
                            set_hour_out <= 6'd0;
                        else
                            set_hour_out <= set_hour_out + 1;
                    end
                    3'b011: begin // Set day
                        if (set_day_out >= get_max_day(set_month_out, set_th_year_out, set_tu_year_out))
                            set_day_out <= 6'd1;
                        else
                            set_day_out <= set_day_out + 1;
                    end
                    3'b100: begin // Set month
                        if (set_month_out == 6'd12)
                            set_month_out <= 6'd1;
                        else
                            set_month_out <= set_month_out + 1;
                        
                        // Adjust day if current day exceeds max days of new month
                        if (set_day_out > get_max_day(set_month_out + 1, set_th_year_out, set_tu_year_out))
                            set_day_out <= get_max_day(set_month_out + 1, set_th_year_out, set_tu_year_out);
                    end
                    3'b101: begin // Set thousand-hundred year
                        if (set_th_year_out == 7'd99)
                            set_th_year_out <= 7'd0;
                        else
                            set_th_year_out <= set_th_year_out + 1;
                        
                        // Adjust day if current day exceeds max days of current month in new year
                        if (set_day_out > get_max_day(set_month_out, set_th_year_out + 1, set_tu_year_out))
                            set_day_out <= get_max_day(set_month_out, set_th_year_out + 1, set_tu_year_out);
                    end
                    3'b110: begin // Set ten-unit year
                        if (set_tu_year_out == 7'd99)
                            set_tu_year_out <= 7'd0;
                        else
                            set_tu_year_out <= set_tu_year_out + 1;
                        
                        // Adjust day if current day exceeds max days of current month in new year
                        if (set_day_out >= get_max_day(set_month_out, set_th_year_out , set_tu_year_out + 1))
                            set_day_out <= get_max_day(set_month_out, set_th_year_out , set_tu_year_out + 1);
                    end
                    default: begin
                        // No increment for other cases
                    end
                endcase
            end
        end
        
        // Detect transition from set mode (01) to alarm mode (10)
        // This is when we output the set values
        if (prev_mode_state == 2'b01 && mode_state == 2'b10) begin
            // Generate enable signals for all components
            en_min <= 1'b1;
            en_hour <= 1'b1;
            en_day <= 1'b1;
            en_month <= 1'b1;
            en_th_year <= 1'b1;
            en_tu_year <= 1'b1;
        end else begin
            // Clear enable signals after one clock cycle
            en_min <= 1'b0;
            en_hour <= 1'b0;
            en_day <= 1'b0;
            en_month <= 1'b0;
            en_th_year <= 1'b0;
            en_tu_year <= 1'b0;
        end
        
        prev_mode_state <= mode_state;
    end
end

endmodule

