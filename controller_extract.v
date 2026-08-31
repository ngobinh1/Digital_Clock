module controller_extract (
    input wire [1:0] mode_state,
    input wire [5:0] counter_data,
    input wire [5:0] set_time_data,
    input wire [5:0] alarm_data,
    output reg [5:0] extract_data
);

always @(*) begin
    case (mode_state)
        2'b00: extract_data = counter_data;    // Normal display mode
        2'b01: extract_data = set_time_data;   // Time setting mode
        2'b10: extract_data = alarm_data;      // Alarm setting mode
        default: extract_data = counter_data;  // Default to normal mode
    endcase
end

endmodule

module controller_extract_y (
    input wire [1:0] mode_state,
    input wire [6:0] counter_data,
    input wire [6:0] set_time_data,
    input wire [6:0] alarm_data,
    output reg [6:0] extract_data
);

always @(*) begin
    case (mode_state)
        2'b00: extract_data = counter_data;    // Normal display mode
        2'b01: extract_data = set_time_data;   // Time setting mode
        2'b10: extract_data = alarm_data;      // Alarm setting mode
        default: extract_data = counter_data;  // Default to normal mode
    endcase
end

endmodule