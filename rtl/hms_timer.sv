//==============================================================================
// File: hms_timer.sv
// Module: hms_timer (Top-Level IP Core)
// Description: Hour-Minute-Second Real-Time Timer IP Core with:
//              - Single synchronous 1 MHz clock domain
//              - Asynchronous active-low reset (rstn)
//              - 2-FF synchronization & 20ms Debounce with Auto-repeat on button inputs
//              - 1 Hz prescaler timebase generator
//              - 4-State Mode FSM with 5s Inactivity Timeout & Rollback
//              - Modulo-60/60/24 real-time counters with Snapshot registers
//              - Bidirectional time adjustment with wrap-around
//              - Rollover gating during time adjustment
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module hms_timer #(
    parameter int CLK_FREQ_HZ      = 1_000_000,                                                  // System Clock Frequency (1 MHz)
    parameter int PSC_COUNT_MAX    = CLK_FREQ_HZ - 1,                                            // Prescaler Terminal Count
    parameter int PSC_WIDTH        = 20,                                                         // Prescaler Bit Width
    parameter int DEBOUNCE_TIME_MS = 20,                                                         // Debounce Time in ms (20ms)
    parameter int DEBOUNCE_CYCLES  = (longint'(CLK_FREQ_HZ) * DEBOUNCE_TIME_MS) / 1000,         // Debounce count
    parameter int TIMEOUT_SEC      = 5,                                                          // Inactivity timeout in seconds (5s)
    parameter int SEC_WIDTH        = 6,                                                          // Second Output Bit Width (0..59)
    parameter int MIN_WIDTH        = 6,                                                          // Minute Output Bit Width (0..59)
    parameter int HOUR_WIDTH       = 5                                                           // Hour Output Bit Width (0..23)
)(
    input  logic                  clk,      // System Clock (1 MHz)
    input  logic                  rstn,     // Asynchronous Reset, Active-Low
    input  logic                  sel_in,   // Mode Selection Button (20ms Debounced)
    input  logic                  up_in,    // Value Increment Button (20ms Debounced)
    input  logic                  down_in,  // Value Decrement Button (20ms Debounced)
    output logic [HOUR_WIDTH-1:0] h_out,    // Real-Time Hour Output (0..23)
    output logic [MIN_WIDTH-1:0]  m_out,    // Real-Time Minute Output (0..59)
    output logic [SEC_WIDTH-1:0]  s_out     // Real-Time Second Output (0..59)
);

    //--------------------------------------------------------------------------
    // Internal Interconnect Signals
    //--------------------------------------------------------------------------
    logic       sel_pulse;     // Synchronized & Debounced 1-cycle pulse for sel_in
    logic       up_pulse;      // Synchronized & Debounced 1-cycle pulse for up_in
    logic       down_pulse;    // Synchronized & Debounced 1-cycle pulse for down_in
    logic       sec_tick;      // 1 Hz 1-cycle pulse from prescaler
    logic [1:0] adj_mode;      // Operating mode state from mode_controller
    logic       cancel_pulse;  // 5s Inactivity Timeout Rollback pulse
    logic       sec_rollover;  // Rollover enable pulse from second to minute counter
    logic       min_rollover;  // Rollover enable pulse from minute to hour counter

    //--------------------------------------------------------------------------
    // Submodule 1: Button Debouncers with 20ms Hold & Auto-Repeat
    //--------------------------------------------------------------------------
    button_debouncer #(
        .CLK_FREQ_HZ      (CLK_FREQ_HZ),
        .DEBOUNCE_TIME_MS (DEBOUNCE_TIME_MS),
        .DEBOUNCE_CYCLES  (DEBOUNCE_CYCLES)
    ) u_debouncer_sel (
        .clk       (clk),
        .rstn      (rstn),
        .btn_in    (sel_in),
        .btn_pulse (sel_pulse)
    );

    button_debouncer #(
        .CLK_FREQ_HZ      (CLK_FREQ_HZ),
        .DEBOUNCE_TIME_MS (DEBOUNCE_TIME_MS),
        .DEBOUNCE_CYCLES  (DEBOUNCE_CYCLES)
    ) u_debouncer_up (
        .clk       (clk),
        .rstn      (rstn),
        .btn_in    (up_in),
        .btn_pulse (up_pulse)
    );

    button_debouncer #(
        .CLK_FREQ_HZ      (CLK_FREQ_HZ),
        .DEBOUNCE_TIME_MS (DEBOUNCE_TIME_MS),
        .DEBOUNCE_CYCLES  (DEBOUNCE_CYCLES)
    ) u_debouncer_down (
        .clk       (clk),
        .rstn      (rstn),
        .btn_in    (down_in),
        .btn_pulse (down_pulse)
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
    // Submodule 3: Mode Controller & Inactivity Timeout FSM
    //--------------------------------------------------------------------------
    mode_controller #(
        .TIMEOUT_SEC (TIMEOUT_SEC)
    ) u_mode_controller (
        .clk          (clk),
        .rstn         (rstn),
        .sel_pulse    (sel_pulse),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .sec_tick     (sec_tick),
        .adj_mode     (adj_mode),
        .cancel_pulse (cancel_pulse)
    );

    //--------------------------------------------------------------------------
    // Submodule 4: Modulo-60 Second Counter with Snapshot Rollback
    //--------------------------------------------------------------------------
    second_counter #(
        .SEC_WIDTH (SEC_WIDTH)
    ) u_second_counter (
        .clk          (clk),
        .rstn         (rstn),
        .adj_mode     (adj_mode),
        .sec_tick     (sec_tick),
        .sel_pulse    (sel_pulse),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .cancel_pulse (cancel_pulse),
        .s_out        (s_out),
        .sec_rollover (sec_rollover)
    );

    //--------------------------------------------------------------------------
    // Submodule 5: Modulo-60 Minute Counter with Snapshot Rollback
    //--------------------------------------------------------------------------
    minute_counter #(
        .MIN_WIDTH (MIN_WIDTH)
    ) u_minute_counter (
        .clk          (clk),
        .rstn         (rstn),
        .adj_mode     (adj_mode),
        .sec_rollover (sec_rollover),
        .sel_pulse    (sel_pulse),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .cancel_pulse (cancel_pulse),
        .m_out        (m_out),
        .min_rollover (min_rollover)
    );

    //--------------------------------------------------------------------------
    // Submodule 6: Modulo-24 Hour Counter with Snapshot Rollback
    //--------------------------------------------------------------------------
    hour_counter #(
        .HOUR_WIDTH (HOUR_WIDTH)
    ) u_hour_counter (
        .clk          (clk),
        .rstn         (rstn),
        .adj_mode     (adj_mode),
        .min_rollover (min_rollover),
        .sel_pulse    (sel_pulse),
        .up_pulse     (up_pulse),
        .down_pulse   (down_pulse),
        .cancel_pulse (cancel_pulse),
        .h_out        (h_out)
    );

endmodule
