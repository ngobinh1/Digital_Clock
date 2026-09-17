//==============================================================================
// File: hms_timer.sv
// Module: hms_timer (Top-Level IP Core)
// Description: Hour-Minute-Second Real-Time Timer IP Core with:
//              - Single synchronous 1 MHz clock domain
//              - Asynchronous active-low reset (rstn)
//              - 2-FF synchronization & edge detection on button inputs
//              - 1 Hz prescaler timebase generator
//              - 4-State Mode FSM (Run, Adj Sec, Adj Min, Adj Hour)
//              - Cascaded Modulo-60/60/24 real-time counters
//              - Bidirectional time adjustment with wrap-around
//              - Rollover gating during time adjustment
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module hms_timer #(
    parameter int CLK_FREQ_HZ   = 1_000_000,       // System Clock Frequency (1 MHz)
    parameter int PSC_COUNT_MAX = CLK_FREQ_HZ - 1, // Prescaler Terminal Count
    parameter int PSC_WIDTH     = 20,              // Prescaler Bit Width
    parameter int SEC_WIDTH     = 6,               // Second Output Bit Width (0..59)
    parameter int MIN_WIDTH     = 6,               // Minute Output Bit Width (0..59)
    parameter int HOUR_WIDTH    = 5                // Hour Output Bit Width (0..23)
)(
    input  logic                  clk,      // System Clock (1 MHz)
    input  logic                  rstn,     // Asynchronous Reset, Active-Low
    input  logic                  sel_in,   // Mode Selection Button (Edge-triggered)
    input  logic                  up_in,    // Value Increment Button (Edge-triggered)
    input  logic                  down_in,  // Value Decrement Button (Edge-triggered)
    output logic [HOUR_WIDTH-1:0] h_out,    // Real-Time Hour Output (0..23)
    output logic [MIN_WIDTH-1:0]  m_out,    // Real-Time Minute Output (0..59)
    output logic [SEC_WIDTH-1:0]  s_out     // Real-Time Second Output (0..59)
);

    //--------------------------------------------------------------------------
    // Internal Interconnect Signals
    //--------------------------------------------------------------------------
    logic       sel_pulse;     // Synchronized 1-cycle pulse for sel_in
    logic       up_pulse;      // Synchronized 1-cycle pulse for up_in
    logic       down_pulse;    // Synchronized 1-cycle pulse for down_in
    logic       sec_tick;      // 1 Hz 1-cycle pulse from prescaler
    logic [1:0] adj_mode;      // Operating mode state from mode_controller
    logic       sec_rollover;  // Rollover enable pulse from second to minute counter
    logic       min_rollover;  // Rollover enable pulse from minute to hour counter

    //--------------------------------------------------------------------------
    // Submodule 1: Synchronizer & Positive Edge Detector
    //--------------------------------------------------------------------------
    sync_edge_detector u_sync_edge_detector (
        .clk        (clk),
        .rstn       (rstn),
        .sel_in     (sel_in),
        .up_in      (up_in),
        .down_in    (down_in),
        .sel_pulse  (sel_pulse),
        .up_pulse   (up_pulse),
        .down_pulse (down_pulse)
    );

    //--------------------------------------------------------------------------
    // Submodule 2: 1 Hz Time Base Prescaler
    //--------------------------------------------------------------------------
    prescaler_1hz #(
        .CLK_FREQ_HZ   (CLK_FREQ_HZ),
        .PSC_COUNT_MAX (PSC_COUNT_MAX),
        .PSC_WIDTH     (PSC_WIDTH)
    ) u_prescaler_1hz (
        .clk      (clk),
        .rstn     (rstn),
        .sec_tick (sec_tick)
    );

    //--------------------------------------------------------------------------
    // Submodule 3: Mode Controller & FSM
    //--------------------------------------------------------------------------
    mode_controller u_mode_controller (
        .clk       (clk),
        .rstn      (rstn),
        .sel_pulse (sel_pulse),
        .adj_mode  (adj_mode)
    );

    //--------------------------------------------------------------------------
    // Submodule 4: Modulo-60 Second Counter
    //--------------------------------------------------------------------------
    second_counter #(
        .SEC_WIDTH (SEC_WIDTH)
    ) u_second_counter (
        .clk          (clk),
        .rstn         (rstn),
        .adj_mode     (adj_mode),
        .sec_tick     (sec_tick),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .s_out        (s_out),
        .sec_rollover (sec_rollover)
    );

    //--------------------------------------------------------------------------
    // Submodule 5: Modulo-60 Minute Counter
    //--------------------------------------------------------------------------
    minute_counter #(
        .MIN_WIDTH (MIN_WIDTH)
    ) u_minute_counter (
        .clk          (clk),
        .rstn         (rstn),
        .adj_mode     (adj_mode),
        .sec_rollover (sec_rollover),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .m_out        (m_out),
        .min_rollover (min_rollover)
    );

    //--------------------------------------------------------------------------
    // Submodule 6: Modulo-24 Hour Counter
    //--------------------------------------------------------------------------
    hour_counter #(
        .HOUR_WIDTH (HOUR_WIDTH)
    ) u_hour_counter (
        .clk          (clk),
        .rstn         (rstn),
        .adj_mode     (adj_mode),
        .min_rollover (min_rollover),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .h_out        (h_out)
    );

endmodule
