//==============================================================================
// File: hms_scoreboard.sv
// Class: hms_scoreboard
// Description: Scoreboard and Golden Reference Model for HMS_Timer verification.
//              Compares DUT outputs against Golden reference states and generates
//              formal verification scorecards.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef HMS_SCOREBOARD_SV
`define HMS_SCOREBOARD_SV

class hms_scoreboard;
    virtual hms_timer_if vif;

    int total_checks;
    int passed_checks;
    int failed_checks;

    // Golden Reference Model State
    int exp_h;
    int exp_m;
    int exp_s;
    hms_mode_e exp_mode;

    function new(virtual hms_timer_if vif);
        this.vif = vif;
        this.total_checks  = 0;
        this.passed_checks = 0;
        this.failed_checks = 0;
        reset_golden();
    endfunction

    // Reset Golden Model
    function void reset_golden();
        exp_h    = 0;
        exp_m    = 0;
        exp_s    = 0;
        exp_mode = MODE_RUN;
    endfunction

    // Set Golden Model Time manually
    function void set_golden_time(int h, int m, int s);
        exp_h = h;
        exp_m = m;
        exp_s = s;
    endfunction

    // Increment Reference Model Seconds
    function void inc_second();
        if (exp_s >= 59) begin
            exp_s = 0;
        end else begin
            exp_s++;
        end
    endfunction

    // Decrement Reference Model Seconds
    function void dec_second();
        if (exp_s == 0) begin
            exp_s = 59;
        end else begin
            exp_s--;
        end
    endfunction

    // Increment Reference Model Minutes
    function void inc_minute();
        if (exp_m >= 59) begin
            exp_m = 0;
        end else begin
            exp_m++;
        end
    endfunction

    // Decrement Reference Model Minutes
    function void dec_minute();
        if (exp_m == 0) begin
            exp_m = 59;
        end else begin
            exp_m--;
        end
    endfunction

    // Increment Reference Model Hours
    function void inc_hour();
        if (exp_h >= 23) begin
            exp_h = 0;
        end else begin
            exp_h++;
        end
    endfunction

    // Decrement Reference Model Hours
    function void dec_hour();
        if (exp_h == 0) begin
            exp_h = 23;
        end else begin
            exp_h--;
        end
    endfunction

    // Real-Time 1-Second Cascade Tick
    function void advance_one_second_cascade();
        if (exp_s == 59) begin
            exp_s = 0;
            if (exp_m == 59) begin
                exp_m = 0;
                if (exp_h == 23) begin
                    exp_h = 0;
                end else begin
                    exp_h++;
                end
            end else begin
                exp_m++;
            end
        end else begin
            exp_s++;
        end
    endfunction

    // Check DUT outputs against specific expected values
    task check_time(int expected_h, int expected_m, int expected_s, string tag = "");
        total_checks++;
        if (vif.h_out === expected_h[4:0] &&
            vif.m_out === expected_m[5:0] &&
            vif.s_out === expected_s[5:0]) begin
            passed_checks++;
            log_pass($sformatf("[%s] MATCH: DUT Time=%02d:%02d:%02d (Expected=%02d:%02d:%02d)",
                               tag, vif.h_out, vif.m_out, vif.s_out,
                               expected_h, expected_m, expected_s));
        end else begin
            failed_checks++;
            log_fail($sformatf("[%s] MISMATCH! DUT Time=%02d:%02d:%02d | Expected=%02d:%02d:%02d",
                               tag, vif.h_out, vif.m_out, vif.s_out,
                               expected_h, expected_m, expected_s));
        end
    endtask

    // Check DUT mode
    task check_mode(logic [1:0] expected_mode, string tag = "");
        total_checks++;
        if (vif.adj_mode === expected_mode) begin
            passed_checks++;
            log_pass($sformatf("[%s] Mode MATCH: %s", tag, mode2str(vif.adj_mode)));
        end else begin
            failed_checks++;
            log_fail($sformatf("[%s] Mode MISMATCH! DUT Mode=%s | Expected=%s",
                               tag, mode2str(vif.adj_mode), mode2str(expected_mode)));
        end
    endtask

    // Display Final Scorecard Report
    function void report_summary();
        $display("\n================================================================================");
        $display("                   VERIFICATION SCORECARD & SUMMARY REPORT                      ");
        $display("================================================================================");
        $display(" TOTAL ASSERTIONS & CHECKS RUN : %0d", total_checks);
        $display(" TOTAL PASSED CHECKS           : %0d", passed_checks);
        $display(" TOTAL FAILED CHECKS           : %0d", failed_checks);
        $display("--------------------------------------------------------------------------------");
        if (failed_checks == 0 && total_checks > 0) begin
            $display("%s >>> VERIFICATION STATUS: 100%% PASSED (TAPE-OUT READY QUALITY) <<< %s", COLOR_GREEN, COLOR_RESET);
        end else begin
            $display("%s >>> VERIFICATION STATUS: FAILED (%0d FAILURES DETECTED) <<< %s", COLOR_RED, failed_checks, COLOR_RESET);
        end
        $display("================================================================================\n");
    endfunction

endclass

`endif // HMS_SCOREBOARD_SV
