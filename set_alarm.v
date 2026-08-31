// ===== MODULE SET_ALARM =====
module set_alarm (
    input clk,
    input rst,
    input inc,
    input [2:0] en_set_alarm,
    input [1:0] mode_state,
    input [5:0] sec_in,
    input [5:0] min_in,
    input [5:0] hour_in,
    input [5:0] day_in,
    input [5:0] month_in,
    input [6:0] th_year_in,
    input [6:0] tu_year_in,
    input ring_off,
    output reg [5:0] min_alarm,
    output reg [5:0] hour_alarm,
    output reg [5:0] day_alarm,
    output reg [5:0] month_alarm,
    output reg [6:0] th_year_alarm,
    output reg [6:0] tu_year_alarm,
    output reg ring
);

    // Internal registers
    reg alarm_enabled;
    reg [2:0] prev_en_set_alarm;
    reg [1:0] prev_mode_state;
    
    // Constants for alarm setting modes
    localparam NORMAL_MODE = 2'b00;
    localparam SET_TIME_MODE = 2'b01;
    localparam SET_ALARM_MODE = 2'b10;
    
    // en_set_alarm definitions
    localparam SET_NONE = 3'b000;
    localparam SET_MIN = 3'b001;
    localparam SET_HOUR = 3'b010;
    localparam SET_DAY = 3'b011;
    localparam SET_MONTH = 3'b100;
    localparam SET_TH_YEAR = 3'b101;
    localparam SET_TU_YEAR = 3'b110;
    
    // Function to get maximum days in a month
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
            // Reset all alarm values
            min_alarm <= 6'b0;
            hour_alarm <= 6'b0;
            day_alarm <= 6'b1;
            month_alarm <= 6'b1;
            th_year_alarm <= 7'd20;
            tu_year_alarm <= 7'd25;
            ring <= 1'b0;
            alarm_enabled <= 1'b0;
            prev_en_set_alarm <= 3'b0;
            prev_mode_state <= 2'b0;
        end
        else begin
            prev_en_set_alarm <= en_set_alarm;
            prev_mode_state <= mode_state;
            
            // Enable alarm when exiting SET_ALARM_MODE to NORMAL_MODE
            if (prev_mode_state == SET_ALARM_MODE && mode_state == NORMAL_MODE) begin
                alarm_enabled <= 1'b1;
            end
            
            // Disable alarm when entering SET_ALARM_MODE
            if (mode_state == SET_ALARM_MODE && prev_mode_state != SET_ALARM_MODE) begin
                alarm_enabled <= 1'b0;
                ring <= 1'b0;
            end
            
            // Set alarm values when in SET_ALARM_MODE
            if (mode_state == SET_ALARM_MODE && inc && (en_set_alarm != prev_en_set_alarm || inc)) begin
                case (en_set_alarm)
                    SET_NONE: begin
                        // No action when SET_NONE is selected
                    end
                    SET_MIN: begin
                        if (min_alarm == 6'd59)
                            min_alarm <= 6'b0;
                        else
                            min_alarm <= min_alarm + 1;
                    end
                    SET_HOUR: begin
                        if (hour_alarm == 6'd23)
                            hour_alarm <= 6'b0;
                        else
                            hour_alarm <= hour_alarm + 1;
                    end
                    SET_DAY: begin
                        // Get maximum day for current month and year
                        if (day_alarm >= get_max_day(month_alarm, th_year_alarm, tu_year_alarm))
                            day_alarm <= 6'b1;
                        else
                            day_alarm <= day_alarm + 1;
                    end
                    SET_MONTH: begin
                        if (month_alarm == 6'd12) begin
                            month_alarm <= 6'b1;
                            // Adjust day if it exceeds the new month's maximum
                            if (day_alarm > get_max_day(6'b1, th_year_alarm, tu_year_alarm))
                                day_alarm <= get_max_day(6'b1, th_year_alarm, tu_year_alarm);
                        end
                        else begin
                            month_alarm <= month_alarm + 1;
                            // Adjust day if it exceeds the new month's maximum
                            if (day_alarm > get_max_day(month_alarm + 1, th_year_alarm, tu_year_alarm))
                                day_alarm <= get_max_day(month_alarm + 1, th_year_alarm, tu_year_alarm);
                        end
                    end
                    SET_TH_YEAR: begin
                        if (th_year_alarm == 7'd99)
                            th_year_alarm <= 7'b0;
                        else
                            th_year_alarm <= th_year_alarm + 1;
                        // Adjust day 
                        if (day_alarm > get_max_day(month_alarm, th_year_alarm + 1, tu_year_alarm))
                            day_alarm <= get_max_day(month_alarm, th_year_alarm + 1, tu_year_alarm);
                    end
                    SET_TU_YEAR: begin
                        if (tu_year_alarm == 7'd99)
                            tu_year_alarm <= 7'b0;
                        else
                            tu_year_alarm <= tu_year_alarm + 1;
                        // Adjust day 
                        if (day_alarm > get_max_day(month_alarm, th_year_alarm, tu_year_alarm + 1))
                            day_alarm <= get_max_day(month_alarm, th_year_alarm, tu_year_alarm + 1);
                    end
                    default: begin
                        // Default case - no action
                    end
                endcase
            end
            
            // Check for alarm condition
            if (alarm_enabled && mode_state == NORMAL_MODE) begin
                if (min_in == min_alarm && 
                    hour_in == hour_alarm && 
                    day_in == day_alarm && 
                    month_in == month_alarm && 
                    th_year_in == th_year_alarm && 
                    tu_year_in == tu_year_alarm) begin
                    ring <= 1'b1;
                end
            end
            
            // Turn off ring when ring_off is pressed
            if (ring_off) begin
                ring <= 1'b0;
            end
        end
    end

endmodule