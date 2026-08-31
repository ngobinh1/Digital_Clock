module set_1224(
    input mode_1224,
    input [5:0] hour_w,
    output reg am_pm,
    output reg [5:0] hour_set1224
);

    always @(*) begin
        if (mode_1224) begin // 12-hour mode
            if (hour_w == 0) begin
                hour_set1224 = 6'd0;
                am_pm = 1'b0; // AM
            end
            else if (hour_w < 12) begin
                hour_set1224 = hour_w;
                am_pm = 1'b0; // AM
            end
            else if (hour_w == 12) begin
                hour_set1224 = 6'd0;
                am_pm = 1'b1; // PM
            end
            else if(hour_w == 24) begin
                hour_set1224 = 6'd0;
                am_pm = 1'b0; // AM
            end
            else begin
                hour_set1224 = hour_w - 12;
                am_pm = 1'b1; // PM
            end
        end
        else begin // 24-hour mode
            hour_set1224 = hour_w;
            am_pm = 1'b0; // Not used in 24-hour mode
        end
    end

endmodule