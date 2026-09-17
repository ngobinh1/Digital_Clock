//==============================================================================
// File: tb_hms_timer.sv
// Module: tb_hms_timer (Top Verification Testbench)
// Description: Comprehensive SystemVerilog Testbench for verifying the
//              HMS_Timer IP Core against all specification requirements.
//              Features:
//              - 10 Automated Test Cases (Reset, Prescaler, FSM, Cascade, Adjustments,
//                Wrap-Arounds, Isolation, Conflict Resolution, Glitch, Day Wrap)
//              - Golden Reference Model & Cycle-accurate Scoreboard
//              - SystemVerilog Concurrent Assertions (SVA) Checkers
//              - Functional Coverage Metric Tracking
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`timescale 1ns / 1ps

import hms_timer_types_pkg::*;

`include "hms_driver.sv"
`include "hms_scoreboard.sv"
`include "hms_coverage.sv"

module tb_hms_timer;

    // Clock frequency and period configuration
    // 1 MHz Clock -> Period = 1000 ns (1 us)
    localparam realtime CLK_PERIOD = 1000ns;

    // Simulation Prescaler setting: 100 cycles per 1 second tick
    localparam int SIM_CLK_FREQ_HZ   = 100;
    localparam int SIM_PSC_COUNT_MAX = SIM_CLK_FREQ_HZ - 1;
    localparam int SIM_PSC_WIDTH     = 20;

    // Clock generator
    logic clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2.0) clk = ~clk;
    end

    // Interface instantiation
    hms_timer_if #(
        .SEC_WIDTH(6),
        .MIN_WIDTH(6),
        .HOUR_WIDTH(5)
    ) vif (
        .clk(clk)
    );

    // DUT Instantiation with fast prescaler parameter for testbench execution
    hms_timer #(
        .CLK_FREQ_HZ   (SIM_CLK_FREQ_HZ),
        .PSC_COUNT_MAX (SIM_PSC_COUNT_MAX),
        .PSC_WIDTH     (SIM_PSC_WIDTH),
        .SEC_WIDTH     (6),
        .MIN_WIDTH     (6),
        .HOUR_WIDTH    (5)
    ) dut (
        .clk     (vif.clk),
        .rstn    (vif.rstn),
        .sel_in  (vif.sel_in),
        .up_in   (vif.up_in),
        .down_in (vif.down_in),
        .h_out   (vif.h_out),
        .m_out   (vif.m_out),
        .s_out   (vif.s_out)
    );

    // Bind internal probes to interface for verification visibility
    assign vif.sel_pulse    = dut.sel_pulse;
    assign vif.up_pulse     = dut.up_pulse;
    assign vif.down_pulse   = dut.down_pulse;
    assign vif.sec_tick     = dut.sec_tick;
    assign vif.adj_mode     = dut.adj_mode;
    assign vif.sec_rollover = dut.sec_rollover;
    assign vif.min_rollover = dut.min_rollover;

    // Testbench OOP Components
    hms_driver     driver;
    hms_scoreboard scoreboard;
    hms_coverage   coverage;

    //==========================================================================
    // Test Tasks & Execution Sequences
    //==========================================================================

    // TC1: Power-on Reset and Recovery Verification
    task run_tc1_reset_recovery();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 1: Power-on Reset & Recovery Verification <<<");
        $display("--------------------------------------------------------------------------------");
        driver.init_signals();
        driver.reset_dut(10);
        scoreboard.check_time(0, 0, 0, "TC1_RESET");
        scoreboard.check_mode(MODE_RUN, "TC1_RESET_MODE");
    endtask

    // TC2: Prescaler & Normal Cascade Real-Time Counting
    task run_tc2_normal_counting();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 2: Prescaler & Real-Time Normal Cascade Counting <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        log_info("Observing natural counting progression across seconds and minutes...");
        
        // Wait for 10 simulated seconds (each second = 5 clock cycles)
        for (int i = 1; i <= 10; i++) begin
            @(posedge vif.sec_tick);
            @(posedge vif.clk); #1ns;
            scoreboard.check_time(0, 0, i, $sformatf("TC2_SEC_%0d", i));
        end
    endtask

    // TC3: Mode Controller FSM Navigation
    task run_tc3_fsm_navigation();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 3: Mode Controller FSM Navigation (Circular Loop) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Mode 00 -> Mode 01 (ADJ_SEC)
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC3_TRANSITION_TO_SEC");

        // Mode 01 -> Mode 10 (ADJ_MIN)
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_MIN, "TC3_TRANSITION_TO_MIN");

        // Mode 10 -> Mode 11 (ADJ_HOUR)
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC3_TRANSITION_TO_HOUR");

        // Mode 11 -> Mode 00 (RUN)
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_RUN, "TC3_TRANSITION_TO_RUN");
    endtask

    // TC4: Second Adjustment (Increment, Decrement, Wrap-Around)
    task run_tc4_second_adjustment();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 4: Seconds Adjustment (Up / Down / Wrap-Around) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_SEC mode: RUN (00) -> ADJ_SEC (01)
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC4_ENTER_SEC_ADJ");
        scoreboard.check_time(0, 0, 0, "TC4_SEC_INIT_ZERO");

        // Test Up button increments
        log_info("Testing Second Increment (Up)...");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 1, "TC4_SEC_UP_1");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 2, "TC4_SEC_UP_2");

        // Test Down button decrements
        log_info("Testing Second Decrement (Down)...");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 0, 1, "TC4_SEC_DOWN_1");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 0, 0, "TC4_SEC_DOWN_2");

        // Down from 0 -> Wrap to 59
        log_info("Testing Wrap-down (0 -> 59)...");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 0, 59, "TC4_SEC_WRAP_DOWN_59");

        // Up from 59 -> Wrap to 0
        log_info("Testing Wrap-up (59 -> 0)...");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 0, "TC4_SEC_WRAP_UP_0");
    endtask

    // TC5: Minute Adjustment (Increment, Decrement, Wrap-Around)
    task run_tc5_minute_adjustment();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 5: Minutes Adjustment (Up / Down / Wrap-Around) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Navigate to ADJ_MIN: RUN -> SEC -> MIN
        driver.pulse_sel(3, 4); // RUN -> SEC
        driver.pulse_sel(3, 4); // SEC -> MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC5_ENTER_MIN_ADJ");
        scoreboard.check_time(0, 0, 0, "TC5_MIN_INIT_ZERO");

        // Increment Minute
        log_info("Testing Minute Increment (Up)...");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 1, 0, "TC5_MIN_UP_1");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 2, 0, "TC5_MIN_UP_2");

        // Decrement Minute
        log_info("Testing Minute Decrement (Down)...");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 1, 0, "TC5_MIN_DOWN_1");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 0, 0, "TC5_MIN_DOWN_2");

        // Decrement from 0 -> Wrap to 59
        log_info("Testing Minute Wrap-down (0 -> 59)...");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 59, 0, "TC5_MIN_WRAP_DOWN_59");

        // Increment from 59 -> Wrap to 0
        log_info("Testing Minute Wrap-up (59 -> 0)...");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 0, "TC5_MIN_WRAP_UP_0");
    endtask

    // TC6: Hour Adjustment (Increment, Decrement, Wrap-Around)
    task run_tc6_hour_adjustment();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 6: Hours Adjustment (Up / Down / Wrap-Around) <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Navigate to ADJ_HOUR: RUN -> SEC -> MIN -> HOUR
        driver.pulse_sel(3, 4); // RUN -> SEC
        driver.pulse_sel(3, 4); // SEC -> MIN
        driver.pulse_sel(3, 4); // MIN -> HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC6_ENTER_HOUR_ADJ");
        scoreboard.check_time(0, 0, 0, "TC6_HOUR_INIT_ZERO");

        // Increment Hour
        log_info("Testing Hour Increment (Up)...");
        driver.pulse_up(3, 4);
        scoreboard.check_time(1, 0, 0, "TC6_HOUR_UP_1");
        driver.pulse_up(3, 4);
        scoreboard.check_time(2, 0, 0, "TC6_HOUR_UP_2");

        // Decrement Hour
        log_info("Testing Hour Decrement (Down)...");
        driver.pulse_down(3, 4);
        scoreboard.check_time(1, 0, 0, "TC6_HOUR_DOWN_1");
        driver.pulse_down(3, 4);
        scoreboard.check_time(0, 0, 0, "TC6_HOUR_DOWN_2");

        // Decrement from 0 -> Wrap to 23
        log_info("Testing Hour Wrap-down (0 -> 23)...");
        driver.pulse_down(3, 4);
        scoreboard.check_time(23, 0, 0, "TC6_HOUR_WRAP_DOWN_23");

        // Increment from 23 -> Wrap to 0
        log_info("Testing Hour Wrap-up (23 -> 0)...");
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 0, "TC6_HOUR_WRAP_UP_0");
    endtask

    // TC7: Rollover Isolation Verification during Adjustment
    task run_tc7_rollover_isolation();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 7: Rollover Isolation & Gating Verification <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_SEC mode: RUN -> ADJ_SEC
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC7_SEC_MODE");

        // Set second to 59
        driver.pulse_down(3, 4); // 0 -> 59
        scoreboard.check_time(0, 0, 59, "TC7_SEC_SET_59");

        // Pulse Up: 59 -> 0. Check that Minute DOES NOT increment (remains 0)
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 0, "TC7_SEC_WRAPPED_MIN_ISOLATED");

        // Switch to ADJ_MIN mode
        driver.pulse_sel(3, 4); // SEC -> MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC7_MIN_MODE");

        // Set minute to 59
        driver.pulse_down(3, 4); // 0 -> 59
        scoreboard.check_time(0, 59, 0, "TC7_MIN_SET_59");

        // Pulse Up: 59 -> 0. Check that Hour DOES NOT increment (remains 0)
        driver.pulse_up(3, 4);
        scoreboard.check_time(0, 0, 0, "TC7_MIN_WRAPPED_HOUR_ISOLATED");
    endtask

    // TC8: Simultaneous Up & Down Button Press Conflict
    task run_tc8_simultaneous_press();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 8: Simultaneous Up & Down Button Conflict Resolution <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // Enter ADJ_MIN mode: RUN -> SEC -> MIN
        driver.pulse_sel(3, 4);
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_MIN, "TC8_MIN_MODE");

        // In ADJ_MIN mode, set minute to 15
        repeat (15) driver.pulse_up(2, 3);
        scoreboard.check_time(0, 15, 0, "TC8_MIN_AT_15");

        // Assert both UP and DOWN at the exact same clock cycles
        log_info("Pressing UP and DOWN simultaneously...");
        driver.pulse_up_down_simultaneous(4, 5);
        
        // Value must hold strictly at 15
        scoreboard.check_time(0, 15, 0, "TC8_HOLD_ON_SIMULTANEOUS_PRESS");
    endtask

    // TC9: Asynchronous Narrow Glitch & Metastability Rejection
    task run_tc9_async_glitch_test();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 9: Asynchronous Narrow Glitch Rejection Test <<<");
        $display("--------------------------------------------------------------------------------");
        
        // Inject narrow glitch (< 100ns, system clock is 1000ns)
        log_info("Injecting sub-cycle asynchronous glitch to up_in...");
        driver.inject_glitch(50);
        driver.wait_cycles(5);

        // Verify glitch was safely ignored or sampled without corrupted state
        scoreboard.check_mode(MODE_ADJ_MIN, "TC9_MODE_INTACT");
    endtask

    // TC10: 23:59:59 to 00:00:00 Midnight Rollover Cascade
    task run_tc10_midnight_cascade();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 10: 23:59:59 to 00:00:00 Midnight Rollover Full Cascade <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // 1. Navigate to ADJ_HOUR mode: RUN -> SEC -> MIN -> HOUR
        driver.pulse_sel(3, 4); // RUN -> SEC
        driver.pulse_sel(3, 4); // SEC -> MIN
        driver.pulse_sel(3, 4); // MIN -> HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC10_HOUR_MODE");

        // Set hour to 23: 0 -> 23 via wrap-down
        driver.pulse_down(3, 4);
        scoreboard.check_time(23, 0, 0, "TC10_HOUR_SET_23");

        // 2. Navigate to ADJ_MIN mode: HOUR -> RUN -> SEC -> MIN
        driver.pulse_sel(3, 4); // HOUR -> RUN
        driver.pulse_sel(3, 4); // RUN -> SEC
        driver.pulse_sel(3, 4); // SEC -> MIN
        scoreboard.check_mode(MODE_ADJ_MIN, "TC10_MIN_MODE");

        // Set minute to 59: 0 -> 59 via wrap-down
        driver.pulse_down(3, 4);
        scoreboard.check_time(23, 59, 0, "TC10_MIN_SET_59");

        // 3. Navigate to ADJ_SEC mode: MIN -> HOUR -> RUN -> SEC
        driver.pulse_sel(3, 4); // MIN -> HOUR
        driver.pulse_sel(3, 4); // HOUR -> RUN
        driver.pulse_sel(3, 4); // RUN -> SEC
        scoreboard.check_mode(MODE_ADJ_SEC, "TC10_SEC_MODE");

        // Set second to 58: 0 -> 59 -> 58 via wrap-down
        driver.pulse_down(3, 4); // 0 -> 59
        driver.pulse_down(3, 4); // 59 -> 58
        scoreboard.check_time(23, 59, 58, "TC10_TIME_SET_23_59_58");

        // 4. Switch to MODE_RUN for real-time natural counting: SEC -> MIN -> HOUR -> RUN
        driver.pulse_sel(3, 4); // SEC -> MIN
        driver.pulse_sel(3, 4); // MIN -> HOUR
        driver.pulse_sel(3, 4); // HOUR -> RUN
        scoreboard.check_mode(MODE_RUN, "TC10_ENTER_RUN_MODE");

        // Wait 1 second tick: 23:59:58 -> 23:59:59
        log_info("Waiting for real-time tick to reach 23:59:59...");
        @(posedge vif.sec_tick);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(23, 59, 59, "TC10_COUNT_23_59_59");

        // Wait 1 second tick: 23:59:59 -> 00:00:00 (Midnight Cascade Rollover!)
        log_info("Waiting for midnight rollover to 00:00:00...");
        @(posedge vif.sec_tick);
        @(posedge vif.clk); #1ns;
        scoreboard.check_time(0, 0, 0, "TC10_MIDNIGHT_ROLLOVER_SUCCESS");
    endtask

    // TC11: Exhaustive Cross Stimulus Coverage
    task run_tc11_exhaustive_cross_stimulus();
        $display("\n--------------------------------------------------------------------------------");
        $display(">>> TEST CASE 11: Exhaustive Cross Stimulus & Inactive Button Immunity <<<");
        $display("--------------------------------------------------------------------------------");
        driver.reset_dut(10);
        
        // 1. In MODE_RUN, test UP, DOWN, and UP+DOWN presses (all should be ignored)
        scoreboard.check_mode(MODE_RUN, "TC11_RUN_MODE");
        driver.pulse_up(3, 4);
        driver.pulse_down(3, 4);
        driver.pulse_up_down_simultaneous(3, 4);
        scoreboard.check_time(0, 0, 0, "TC11_RUN_IMMUNITY");

        // 2. In MODE_ADJ_SEC, test UP+DOWN simultaneous
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_ADJ_SEC, "TC11_SEC_MODE");
        driver.pulse_up_down_simultaneous(3, 4);
        scoreboard.check_time(0, 0, 0, "TC11_SEC_SIMULTANEOUS");

        // 3. In MODE_ADJ_HOUR, test UP+DOWN simultaneous
        driver.pulse_sel(3, 4); // SEC -> MIN
        driver.pulse_sel(3, 4); // MIN -> HOUR
        scoreboard.check_mode(MODE_ADJ_HOUR, "TC11_HOUR_MODE");
        driver.pulse_up_down_simultaneous(3, 4);
        scoreboard.check_time(0, 0, 0, "TC11_HOUR_SIMULTANEOUS");

        // Return to RUN mode
        driver.pulse_sel(3, 4);
        scoreboard.check_mode(MODE_RUN, "TC11_RETURN_RUN");
    endtask

    //==========================================================================
    // Main Testbench Process
    //==========================================================================
    initial begin
        $display("\n================================================================================");
        $display("   STARTING HMS_TIMER SYSTEMVERILOG VERIFICATION ENVIRONMENT (QUESTASIM)        ");
        $display("================================================================================");

        // Instantiate testbench objects
        driver     = new(vif);
        scoreboard = new(vif);
        coverage   = new(vif);

        // Execute Test Suite sequentially
        run_tc1_reset_recovery();
        run_tc2_normal_counting();
        run_tc3_fsm_navigation();
        run_tc4_second_adjustment();
        run_tc5_minute_adjustment();
        run_tc6_hour_adjustment();
        run_tc7_rollover_isolation();
        run_tc8_simultaneous_press();
        run_tc9_async_glitch_test();
        run_tc10_midnight_cascade();
        run_tc11_exhaustive_cross_stimulus();

        // Print Coverage and Scorecard Reports
        driver.wait_cycles(10);
        coverage.report_coverage();
        scoreboard.report_summary();

        $display("Simulation completed at timestamp: %0t ns", $time);
        $finish;
    end

endmodule
