module controller_mode (
    input clk,
    input rst,
    input mode,
    input sel,
    output reg [2:0] en_set_time,
    output reg [2:0] en_set_alarm,
    output reg [1:0] mode_state
);

    // state definitions
    localparam counter_mode = 2'b00;
    localparam set_time_mode = 2'b01;
    localparam set_alarm_mode = 2'b10;

    // internal signals
    reg [1:0] next_mode_state;
    reg [2:0] next_en_set_time;
    reg [2:0] next_en_set_alarm;

    // mode state transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode_state <= counter_mode;
            en_set_time <= 3'b000;
            en_set_alarm <= 3'b000;
        end else begin
            mode_state <= next_mode_state;
            en_set_time <= next_en_set_time;
            en_set_alarm <= next_en_set_alarm;
        end
    end

    // mode state and enable signals logic
    always @(*) begin
        // default values
        next_mode_state = mode_state;
        next_en_set_time = en_set_time;
        next_en_set_alarm = en_set_alarm;

        // mode button pressed - cycle through modes
        if (mode) begin
            case (mode_state)
                counter_mode: begin
                    next_mode_state = set_time_mode;
                    next_en_set_time = 3'b001; 
                end
                set_time_mode: begin
                    next_mode_state = set_alarm_mode;
                    next_en_set_alarm = 3'b001;
                    next_en_set_time = 3'b000;
                end
                set_alarm_mode: begin
                    next_mode_state = counter_mode;
                    next_en_set_alarm = 3'b000;
                end
                default: next_mode_state = counter_mode;
            endcase
        end

        // sel button pressed - cycle through settings in current mode
        if (sel) begin
            case (mode_state)
                set_time_mode: begin
                    case (en_set_time)
                        3'b000: next_en_set_time = 3'b001; // minutes
                        3'b001: next_en_set_time = 3'b010; // hours
                        3'b010: next_en_set_time = 3'b011; // day
                        3'b011: next_en_set_time = 3'b100; // month
                        3'b100: next_en_set_time = 3'b101; // year units/tens
                        3'b101: next_en_set_time = 3'b110; // year hundreds/thousands
                        3'b110: next_en_set_time = 3'b001; // wrap around to minutes
                        default: next_en_set_time = 3'b001;
                    endcase
                end
                set_alarm_mode: begin
                    case (en_set_alarm)
                        3'b000: next_en_set_alarm = 3'b001; // minutes
                        3'b001: next_en_set_alarm = 3'b010; // hours
                        3'b010: next_en_set_alarm = 3'b011; // day
                        3'b011: next_en_set_alarm = 3'b100; // month
                        3'b100: next_en_set_alarm = 3'b101; // year units/tens
                        3'b101: next_en_set_alarm = 3'b110; // year hundreds/thousands
                        3'b110: next_en_set_alarm = 3'b001; // wrap around to minutes
                        default: next_en_set_alarm = 3'b001;
                    endcase
                end
                default: begin
                    next_en_set_time = 3'b000;
                    next_en_set_alarm = 3'b000;
                end
            endcase
        end
    end

endmodule