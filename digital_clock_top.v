module digital_clock_top (
    input wire clk,           // System clock (assumed 1Hz for seconds)
    input wire rst,           // Reset
    input wire mode,          // Mode button
    input wire sel,           // Select button  
    input wire inc,           // Increment button
    input wire ring_off,      // Alarm off button
    input wire mode_1224,     // 12/24 hour mode switch
    output wire [6:0] tens_sec_o,   // 7-segment display for seconds units
    output wire [6:0] units_sec_o,   // 7-segment display for seconds tens
    output wire [6:0] tens_min_o,   // 7-segment display for minutes units
    output wire [6:0] units_min_o,   // 7-segment display for minutes tens
    output wire [6:0] tens_hour_o,   // 7-segment display for hours units
    output wire [6:0] units_hour_o,   // 7-segment display for hours tens
    output wire [6:0] tens_day_o,   // 7-segment display for day units
    output wire [6:0] units_day_o,   // 7-segment display for day tens
    output wire [6:0] tens_month_o,   // 7-segment display for month units
    output wire [6:0] units_month_o,   // 7-segment display for month tens
    output wire [6:0] thous_year_o,  // 7-segment display for year units
    output wire [6:0] hunds_year_o,  // 7-segment display for year tens
    output wire [6:0] tens_year_o,  // 7-segment display for year hundreds
    output wire [6:0] units_year_o,  // 7-segment display for year thousands
    output wire am_pm,        // AM/PM indicator
    output wire ring          // Alarm ring output
);

    // Internal wires for counter connections
    wire [5:0] sec_count, min_count, hour_count, day_count, month_count;
    wire [6:0] th_year_count, tu_year_count;
    wire sec_flag, min_flag, hour_flag, day_flag, month_flag, tu_year_flag;
    
    // Wires for set_time module
    wire [5:0] set_min, set_hour, set_day, set_month;
    wire [6:0] set_th_year, set_tu_year;
    wire en_min, en_hour, en_day, en_month, en_th_year, en_tu_year;
    
    // Wires for set_alarm module
    wire [5:0] alarm_min, alarm_hour, alarm_day, alarm_month;
    wire [6:0] alarm_th_year, alarm_tu_year;
    
    // Wires for controller modules
    wire [2:0] en_set_time_ctrl, en_set_alarm_ctrl;
    wire [1:0] mode_state;
    
    // Wires for data extraction
    wire [5:0] extract_sec, extract_min, extract_hour, extract_day, extract_month;
    wire [6:0] extract_th_year, extract_tu_year;
    
    // Wires for max day calculation
    wire [5:0] max_day;
    wire [13:0] full_year = {th_year_count, tu_year_count};
    
    // Wires for 12/24 hour conversion
    wire [5:0] hour_display;
    
    // Wires for BCD conversion
    wire [3:0] sec_tens, sec_units, min_tens, min_units;
    wire [3:0] hour_tens, hour_units, day_tens, day_units;
    wire [3:0] month_tens, month_units;
    wire [3:0] year_th_tens, year_th_units, year_tu_tens, year_tu_units;
    
    // Second counter (base counter)
    counter_sec sec_counter (
        .clk(clk),
        .rst(rst),
        .counter_o(sec_count),
        .flag_o(sec_flag)
    );
    
    // Minute counter
    counter_min min_counter (
        .clk(sec_flag),
        .rst(rst),
        .counter_i(set_min),
        .en_i(en_min),
        .counter_o(min_count),
        .flag_o(min_flag)
    );
    
    // Hour counter
    counter_hour hour_counter (
        .clk(min_flag),
        .rst(rst),
        .counter_i(set_hour),
        .en_i(en_hour),
        .counter_o(hour_count),
        .flag_o(hour_flag)
    );
    
    // Max day calculation
    day_of_month day_calc (
        .month_w(month_count),
        .year_w(full_year),
        .clk(clk),
        .rst(rst),
        .max_day(max_day)
    );
    
    // Day counter
    counter_day day_counter (
        .clk(hour_flag),
        .rst(rst),
        .counter_i(set_day),
        .en_i(en_day),
        .max_day(max_day),
        .counter_o(day_count),
        .flag_o(day_flag)
    );
    
    // Month counter
    counter_month month_counter (
        .clk(day_flag),
        .rst(rst),
        .counter_i(set_month),
        .en_i(en_month),
        .counter_o(month_count),
        .flag_o(month_flag)
    );
    
    // Year counter (tens-units)
    counter_tu_year tu_year_counter (
        .clk(month_flag),
        .rst(rst),
        .counter_i(set_tu_year),
        .en_i(en_tu_year),
        .counter_o(tu_year_count),
        .flag_o(tu_year_flag)
    );
    
    // Year counter (thousands-hundreds)
    counter_th_year th_year_counter (
        .clk(tu_year_flag),
        .rst(rst),
        .counter_i(set_th_year),
        .en_i(en_th_year),
        .counter_o(th_year_count)
    );
    
    // Mode controller
    controller_mode mode_ctrl (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .sel(sel),
        .en_set_time(en_set_time_ctrl),
        .en_set_alarm(en_set_alarm_ctrl),
        .mode_state(mode_state)
    );
    
    // Set time module
    set_time time_setter (
        .clk(clk),
        .rst(rst),
        .inc(inc),
        .en_set_time(en_set_time_ctrl),
        .mode_state(mode_state),
        .set_min_out(set_min),
        .set_hour_out(set_hour),
        .set_day_out(set_day),
        .set_month_out(set_month),
        .set_th_year_out(set_th_year),
        .set_tu_year_out(set_tu_year),
        .set_sel(set_sel),
        .en_min(en_min),
        .en_hour(en_hour),
        .en_day(en_day),
        .en_month(en_month),
        .en_th_year(en_th_year),
        .en_tu_year(en_tu_year)
    );
    
    // Set alarm module
    set_alarm alarm_setter (
        .clk(clk),
        .rst(rst),
        .inc(inc),
        .en_set_alarm(en_set_alarm_ctrl),
        .mode_state(mode_state),
        .sec_in(sec_count),
        .min_in(min_count),
        .hour_in(hour_count),
        .day_in(day_count),
        .month_in(month_count),
        .th_year_in(th_year_count),
        .tu_year_in(tu_year_count),
        .ring_off(ring_off),
        .min_alarm(alarm_min),
        .hour_alarm(alarm_hour),
        .day_alarm(alarm_day),
        .month_alarm(alarm_month),
        .th_year_alarm(alarm_th_year),
        .tu_year_alarm(alarm_tu_year),
        .ring(ring)
    );
    
    // Controller extract module
    controller_extract min_extract(
        .mode_state(mode_state),
        .counter_data(min_count),
        .set_time_data(set_min),
        .alarm_data(alarm_min),
        .extract_data(extract_min)
    );

    controller_extract hour_extract(
        .mode_state(mode_state),
        .counter_data(hour_count),
        .set_time_data(set_hour),
        .alarm_data(alarm_hour),
        .extract_data(extract_hour)
    );

    controller_extract day_extract(
        .mode_state(mode_state),
        .counter_data(day_count),
        .set_time_data(set_day),
        .alarm_data(alarm_day),
        .extract_data(extract_day)
    );

    controller_extract month_extract(
        .mode_state(mode_state),
        .counter_data(month_count),
        .set_time_data(set_month),
        .alarm_data(alarm_month),
        .extract_data(extract_month)
    );

    controller_extract th_year_extract(
        .mode_state(mode_state),
        .counter_data(th_year_count),
        .set_time_data(set_th_year),
        .alarm_data(alarm_th_year),
        .extract_data(extract_th_year)
    );

    controller_extract tu_year_extract(
        .mode_state(mode_state),
        .counter_data(tu_year_count),
        .set_time_data(set_tu_year),
        .alarm_data(alarm_tu_year),
        .extract_data(extract_tu_year)
    );
    
    
    // 12/24 hour format conversion
    set_1224 hour_format (
        .mode_1224(mode_1224),
        .hour_w(hour_count),
        .am_pm(am_pm),
        .hour_set1224(hour_display)
    );
    
    assign extract_hour = hour_display;
    
    // BCD conversion for all time components
    extract_bits sec_bcd (
        .numb_i(extract_sec),
        .tens_o(sec_tens),
        .units_o(sec_units)
    );
    
    extract_bits min_bcd (
        .numb_i(extract_min),
        .tens_o(min_tens),
        .units_o(min_units)
    );
    
    extract_bits hour_bcd (
        .numb_i(extract_hour),
        .tens_o(hour_tens),
        .units_o(hour_units)
    );
    
    extract_bits day_bcd (
        .numb_i(extract_day),
        .tens_o(day_tens),
        .units_o(day_units)
    );
    
    extract_bits month_bcd (
        .numb_i(extract_month),
        .tens_o(month_tens),
        .units_o(month_units)
    );
    
    extract_bits_y th_year_bcd (
        .numb_i(extract_th_year),
        .thos_o(year_th_tens),
        .huns_o(year_th_units)
    );
    
    extract_bits_y tu_year_bcd (
        .numb_i(extract_tu_year),
        .thos_o(year_tu_tens),
        .huns_o(year_tu_units)
    );
    
    // 7-segment display drivers
    led7_segs seg_sec_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(sec_units),
        .out_o(units_sec_o)
    );
    
    led7_segs seg_sec_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(sec_tens),
        .out_o(tens_sec_o)
    );
    
    led7_segs seg_min_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(min_units),
        .out_o(units_min_o)
    );
    
    led7_segs seg_min_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(min_tens),
        .out_o(tens_min_o)
    );
    
    led7_segs seg_hour_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(hour_units),
        .out_o(units_hour_o)
    );
    
    led7_segs seg_hour_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(hour_tens),
        .out_o(tens_hour_o)
    );
    
    led7_segs seg_day_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(day_units),
        .out_o(units_day_o)
    );
    
    led7_segs seg_day_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(day_tens),
        .out_o(tens_day_o)
    );
    
    led7_segs seg_month_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(month_units),
        .out_o(units_month_o)
    );
    
    led7_segs seg_month_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(month_tens),
        .out_o(tens_month_o)
    );
    
    led7_segs seg_year_tu_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(year_tu_units),
        .out_o(units_year_o)
    );
    
    led7_segs seg_year_tu_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(year_tu_tens),
        .out_o(tens_year_o)
    );
    
    led7_segs seg_year_th_units (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(year_th_units),
        .out_o(hunds_year_o)
    );
    
    led7_segs seg_year_th_tens (
        .en(1'b1),
        .clk(clk),
        .rst(rst),
        .inp_i(year_th_tens),
        .out_o(thous_year_o)
    );

endmodule