`timescale 1ns / 1ps

module digital_clock_top_tb;

    // Testbench signals
    reg clk;
    reg rst;
    reg mode;
    reg sel;
    reg inc;
    reg ring_off;
    reg mode_1224;
    
    // Outputs
    wire [6:0] tens_sec_o;
    wire [6:0] units_sec_o;
    wire [6:0] tens_min_o;
    wire [6:0] units_min_o;
    wire [6:0] tens_hour_o;
    wire [6:0] units_hour_o;
    wire [6:0] tens_day_o;
    wire [6:0] units_day_o;
    wire [6:0] tens_month_o;
    wire [6:0] units_month_o;
    wire [6:0] thous_year_o;
    wire [6:0] hunds_year_o;
    wire [6:0] tens_year_o;
    wire [6:0] units_year_o;
    wire am_pm;
    wire ring;

    // Clock generation - 1Hz for seconds
    initial begin
        clk = 0;
        forever #500_000_000 clk = ~clk; // 1Hz clock (1 second period)
    end
    
    // For faster simulation, use a faster clock
    // Comment out the above and uncomment below for faster simulation
    /*
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock for faster simulation
    end
    */

    // DUT instantiation
    digital_clock_top dut (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .sel(sel),
        .inc(inc),
        .ring_off(ring_off),
        .mode_1224(mode_1224),
        .tens_sec_o(tens_sec_o),
        .units_sec_o(units_sec_o),
        .tens_min_o(tens_min_o),
        .units_min_o(units_min_o),
        .tens_hour_o(tens_hour_o),
        .units_hour_o(units_hour_o),
        .tens_day_o(tens_day_o),
        .units_day_o(units_day_o),
        .tens_month_o(tens_month_o),
        .units_month_o(units_month_o),
        .thous_year_o(thous_year_o),
        .hunds_year_o(hunds_year_o),
        .tens_year_o(tens_year_o),
        .units_year_o(units_year_o),
        .am_pm(am_pm),
        .ring(ring)
    );

    // Task to wait for clock edges
    task wait_clk(input integer cycles);
        begin
            repeat(cycles) @(posedge clk);
        end
    endtask

    // Task to pulse a signal
    task pulse_signal(ref logic signal);
        begin
            signal = 1'b1;
            wait_clk(1);
            signal = 1'b0;
            wait_clk(1);
        end
    endtask

    // Task to display current time
    task display_time;
        reg [3:0] sec_tens, sec_units, min_tens, min_units;
        reg [3:0] hour_tens, hour_units, day_tens, day_units;
        reg [3:0] month_tens, month_units;
        reg [3:0] year_thousands, year_hundreds, year_tens_d, year_units_d;
        begin
            // Convert 7-segment to decimal (simplified - assumes valid 7-segment patterns)
            sec_tens = decode_7seg(tens_sec_o);
            sec_units = decode_7seg(units_sec_o);
            min_tens = decode_7seg(tens_min_o);
            min_units = decode_7seg(units_min_o);
            hour_tens = decode_7seg(tens_hour_o);
            hour_units = decode_7seg(units_hour_o);
            day_tens = decode_7seg(tens_day_o);
            day_units = decode_7seg(units_day_o);
            month_tens = decode_7seg(tens_month_o);
            month_units = decode_7seg(units_month_o);
            year_thousands = decode_7seg(thous_year_o);
            year_hundreds = decode_7seg(hunds_year_o);
            year_tens_d = decode_7seg(tens_year_o);
            year_units_d = decode_7seg(units_year_o);
            
            $display("Time: %0d%0d:%0d%0d:%0d%0d  Date: %0d%0d/%0d%0d/%0d%0d%0d%0d  AM/PM: %0d  Ring: %0d",
                hour_tens, hour_units, min_tens, min_units, sec_tens, sec_units,
                day_tens, day_units, month_tens, month_units, 
                year_thousands, year_hundreds, year_tens_d, year_units_d,
                am_pm, ring);
        end
    endtask

    // Function to decode 7-segment display to decimal
    function [3:0] decode_7seg;
        input [6:0] seg;
        begin
            case(seg)
                7'b1000000: decode_7seg = 4'd0; // 0
                7'b1111001: decode_7seg = 4'd1; // 1
                7'b0100100: decode_7seg = 4'd2; // 2
                7'b0110000: decode_7seg = 4'd3; // 3
                7'b0011001: decode_7seg = 4'd4; // 4
                7'b0010010: decode_7seg = 4'd5; // 5
                7'b0000010: decode_7seg = 4'd6; // 6
                7'b1111000: decode_7seg = 4'd7; // 7
                7'b0000000: decode_7seg = 4'd8; // 8
                7'b0010000: decode_7seg = 4'd9; // 9
                default:    decode_7seg = 4'hF; // Invalid
            endcase
        end
    endfunction

    // Test sequence
    initial begin
        $display("=== Digital Clock Testbench Started ===");
        
        // Initialize signals
        rst = 1'b1;
        mode = 1'b0;
        sel = 1'b0;
        inc = 1'b0;
        ring_off = 1'b0;
        mode_1224 = 1'b0; // Start in 24-hour mode
        
        // Wait and release reset
        wait_clk(5);
        rst = 1'b0;
        $display("Reset released");
        
        // Test 1: Normal operation - let clock run for a few seconds
        $display("\n=== Test 1: Normal Clock Operation ===");
        repeat(5) begin
            wait_clk(1);
            display_time();
        end
        
        // Test 2: Enter time setting mode
        $display("\n=== Test 2: Time Setting Mode ===");
        pulse_signal(mode); // Enter set time mode
        $display("Entered set time mode");
        wait_clk(2);
        
        // Set minutes
        $display("Setting minutes...");
        repeat(3) begin
            pulse_signal(inc);
            wait_clk(1);
            display_time();
        end
        
        // Move to hours setting
        pulse_signal(sel);
        $display("Moved to hours setting");
        wait_clk(1);
        
        // Set hours
        $display("Setting hours...");
        repeat(2) begin
            pulse_signal(inc);
            wait_clk(1);
            display_time();
        end
        
        // Move to day setting
        pulse_signal(sel);
        $display("Moved to day setting");
        wait_clk(1);
        
        // Set day
        $display("Setting day...");
        repeat(5) begin
            pulse_signal(inc);
            wait_clk(1);
            display_time();
        end
        
        // Move to month setting
        pulse_signal(sel);
        $display("Moved to month setting");
        wait_clk(1);
        
        // Set month
        $display("Setting month...");
        repeat(2) begin
            pulse_signal(inc);
            wait_clk(1);
            display_time();
        end
        
        // Test 3: Enter alarm setting mode
        $display("\n=== Test 3: Alarm Setting Mode ===");
        pulse_signal(mode); // Enter alarm mode
        $display("Entered alarm setting mode");
        wait_clk(2);
        
        // Set alarm minutes
        $display("Setting alarm minutes...");
        repeat(2) begin
            pulse_signal(inc);
            wait_clk(1);
            display_time();
        end
        
        // Move to alarm hours
        pulse_signal(sel);
        $display("Moved to alarm hours setting");
        wait_clk(1);
        
        // Set alarm hours
        $display("Setting alarm hours...");
        pulse_signal(inc);
        wait_clk(1);
        display_time();
        
        // Test 4: Return to normal mode
        $display("\n=== Test 4: Return to Normal Mode ===");
        pulse_signal(mode); // Return to normal mode
        $display("Returned to normal mode");
        wait_clk(2);
        display_time();
        
        // Test 5: Test 12/24 hour mode switching
        $display("\n=== Test 5: 12/24 Hour Mode Test ===");
        $display("Switching to 12-hour mode");
        mode_1224 = 1'b1;
        wait_clk(2);
        display_time();
        
        $display("Switching back to 24-hour mode");
        mode_1224 = 1'b0;
        wait_clk(2);
        display_time();
        
        // Test 6: Fast time simulation (if using fast clock)
        $display("\n=== Test 6: Fast Time Simulation ===");
        $display("Running clock for several cycles...");
        repeat(10) begin
            wait_clk(1);
            if ($time % 500 == 0) display_time(); // Display every few cycles
        end
        
        // Test 7: Alarm trigger test (conceptual - would need specific time setup)
        $display("\n=== Test 7: Alarm Test ===");
        $display("Note: For full alarm test, set alarm time to match current time");
        if (ring) begin
            $display("ALARM RINGING!");
            pulse_signal(ring_off);
            $display("Alarm turned off");
        end
        
        // Test 8: Reset test
        $display("\n=== Test 8: Reset Test ===");
        $display("Applying reset...");
        rst = 1'b1;
        wait_clk(3);
        rst = 1'b0;
        $display("Reset complete");
        wait_clk(2);
        display_time();
        
        $display("\n=== Testbench Complete ===");
        $finish;
    end

    // Monitor for important state changes
    initial begin
        $monitor("Time %0t: Mode_State=%b, Ring=%b", $time, dut.mode_state, ring);
    end

    // Optional: Generate VCD file for waveform viewing
    initial begin
        $dumpfile("digital_clock_top_tb.vcd");
        $dumpvars(0, digital_clock_top_tb);
    end

    // Timeout protection
    initial begin
        #100_000_000; // 100ms timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule