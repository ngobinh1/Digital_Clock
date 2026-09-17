//==============================================================================
// File: hms_timer_types_pkg.sv
// Package: hms_timer_types_pkg
// Description: Type definitions, Enumerations, Loggers and Utility functions
//              for HMS_Timer SystemVerilog Verification Environment.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`timescale 1ns / 1ps

package hms_timer_types_pkg;

    // Operating mode state enumeration
    typedef enum logic [1:0] {
        MODE_RUN      = 2'b00,  // Normal Real-Time Running Mode
        MODE_ADJ_SEC  = 2'b01,  // Adjust Seconds Mode
        MODE_ADJ_MIN  = 2'b10,  // Adjust Minutes Mode
        MODE_ADJ_HOUR = 2'b11   // Adjust Hours Mode
    } hms_mode_e;

    // Time container structure
    typedef struct {
        int hour;
        int minute;
        int second;
    } hms_time_t;

    // Transaction item for testbench
    class hms_transaction;
        rand hms_mode_e mode;
        rand int        press_duration_cycles;
        rand int        inter_press_delay_cycles;
        rand bit        press_sel;
        rand bit        press_up;
        rand bit        press_down;

        hms_time_t      observed_time;
        realtime        timestamp;

        constraint c_duration {
            press_duration_cycles inside {[2:10]};
            inter_press_delay_cycles inside {[2:15]};
        }

        function void display(string prefix = "TX");
            $display("[%0t ns] [%s] SEL=%0b UP=%0b DOWN=%0b (Duration=%0d cyc, Delay=%0d cyc) Time=%02d:%02d:%02d",
                     timestamp, prefix, press_sel, press_up, press_down,
                     press_duration_cycles, inter_press_delay_cycles,
                     observed_time.hour, observed_time.minute, observed_time.second);
        endfunction
    endclass

    // String formatting helper for modes
    function automatic string mode2str(logic [1:0] mode);
        case (mode)
            MODE_RUN:      return "MODE_RUN (00)";
            MODE_ADJ_SEC:  return "MODE_ADJ_SEC (01)";
            MODE_ADJ_MIN:  return "MODE_ADJ_MIN (10)";
            MODE_ADJ_HOUR: return "MODE_ADJ_HOUR (11)";
            default:       return "MODE_UNKNOWN";
        endcase
    endfunction

    // ANSI Color Escape Codes for Terminal Output
    localparam string COLOR_RESET  = "\033[0m";
    localparam string COLOR_RED    = "\033[1;31m";
    localparam string COLOR_GREEN  = "\033[1;32m";
    localparam string COLOR_YELLOW = "\033[1;33m";
    localparam string COLOR_BLUE   = "\033[1;34m";
    localparam string COLOR_CYAN   = "\033[1;36m";
    localparam string COLOR_BOLD   = "\033[1m";

    // Logging helpers
    function automatic void log_info(string msg);
        $display("%s[INFO] [%0t ns] %s%s", COLOR_CYAN, $time, msg, COLOR_RESET);
    endfunction

    function automatic void log_pass(string msg);
        $display("%s[PASS] [%0t ns] %s%s", COLOR_GREEN, $time, msg, COLOR_RESET);
    endfunction

    function automatic void log_fail(string msg);
        $display("%s[FAIL] [%0t ns] %s%s", COLOR_RED, $time, msg, COLOR_RESET);
    endfunction

    function automatic void log_warn(string msg);
        $display("%s[WARN] [%0t ns] %s%s", COLOR_YELLOW, $time, msg, COLOR_RESET);
    endfunction

endpackage
