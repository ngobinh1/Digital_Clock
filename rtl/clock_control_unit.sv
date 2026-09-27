//==============================================================================
// File: clock_control_unit.sv
// Module: clock_control_unit
// Description: Centralized Clock Management & Low-Power Integrated Clock Gating (ICG) Unit.
//              - Encapsulates condition-based clock gating logic formulas (en_1khz, en_sec, en_min, en_hour, en_fsm)
//              - Instantiates 5 latch-based glitch-free ICG cells
//              - Supports DFT/Scan test_mode bypass
//              - Eliminates >99.99% of dynamic clock pin toggle power on low-frequency counters & FSM
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module clock_control_unit (
    input  logic clk,            // System Master Clock (1 MHz)
    input  logic test_mode,      // DFT / Scan Test Bypass Enable
    input  logic tick_1khz,      // 1 kHz sampling pulse from prescaler
    input  logic sec_tick,       // 1 Hz real-time pulse from prescaler
    input  logic sec_rollover,   // 1-cycle rollover enable pulse from second_counter
    input  logic min_rollover,   // 1-cycle rollover enable pulse from minute_counter
    input  logic sel_pulse,      // Synchronized 1-cycle pulse for sel_in
    input  logic up_pulse,       // Synchronized 1-cycle pulse for up_in
    input  logic down_pulse,     // Synchronized 1-cycle pulse for down_in
    input  logic load_en,        // Synchronous parallel load commit pulse from mode_controller
    output logic gated_clk_1khz, // 1 kHz Gated Clock (Debouncers & Prescaler Stage 2)
    output logic gated_clk_sec,  // 1 Hz / Load Gated Clock (Second Counter)
    output logic gated_clk_min,  // 1/60 Hz / Load Gated Clock (Minute Counter)
    output logic gated_clk_hour, // 1/3600 Hz / Load Gated Clock (Hour Counter)
    output logic gated_clk_fsm   // Event / 1 Hz Gated Clock (Mode Controller FSM)
);

    //--------------------------------------------------------------------------
    // ICG Clock Enable Formulas (Condition-Based Gating)
    //--------------------------------------------------------------------------
    logic en_1khz;
    logic en_sec;
    logic en_min;
    logic en_hour;
    logic en_fsm;

    // Prescaler Stage 2 & Debouncers: Enabled during 1 kHz tick
    assign en_1khz = tick_1khz;

    // Second Counter: Gated ON during sec_tick (1 toggle/s) or synchronous load_en
    assign en_sec  = sec_tick | load_en;

    // Minute Counter: Gated ON during sec_rollover (1 toggle/60s) or synchronous load_en
    assign en_min  = sec_rollover | load_en;

    // Hour Counter: Gated ON during min_rollover (1 toggle/3600s) or synchronous load_en
    assign en_hour = min_rollover | load_en;

    // FSM Mode Controller: Gated ON during any button event, 1 Hz sec_tick, or load_en pulse clearing
    assign en_fsm  = sec_tick | sel_pulse | up_pulse | down_pulse | load_en;

    //--------------------------------------------------------------------------
    // Integrated Clock Gating (ICG) Cells
    //--------------------------------------------------------------------------
    icg_cell u_icg_1khz (
        .clk_in    (clk),
        .en        (en_1khz),
        .test_mode (test_mode),
        .clk_out   (gated_clk_1khz)
    );

    icg_cell u_icg_sec (
        .clk_in    (clk),
        .en        (en_sec),
        .test_mode (test_mode),
        .clk_out   (gated_clk_sec)
    );

    icg_cell u_icg_min (
        .clk_in    (clk),
        .en        (en_min),
        .test_mode (test_mode),
        .clk_out   (gated_clk_min)
    );

    icg_cell u_icg_hour (
        .clk_in    (clk),
        .en        (en_hour),
        .test_mode (test_mode),
        .clk_out   (gated_clk_hour)
    );

    icg_cell u_icg_fsm (
        .clk_in    (clk),
        .en        (en_fsm),
        .test_mode (test_mode),
        .clk_out   (gated_clk_fsm)
    );

endmodule
