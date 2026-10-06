//==============================================================================
// File: hms_timer.sv
// Module: hms_timer (Top-Level IP Core - v2.3.0 Decoupled & Output Switch)
// Description: Hour-Minute-Second Real-Time Timer IP Core with:
//              - Single synchronous 1 MHz clock domain with Glitch-Free ICG
//              - Asynchronous active-low reset (rstn)
//              - DFT/Scan test_mode bypass support
//              - Pure 1 kHz Clock-Driven Button Debouncers (Zero 1 MHz clock routing to debouncers)
//              - Top-level single-cycle pulse alignment (1 MHz domain)
//              - Integrated Clock Gating (ICG) on Debouncers, Prescaler Stage 2,
//                FSM, Second, Minute, and Hour Counters
//              - Clock pin toggle power reduced by >99.99% for low-frequency counters
//              - 4-State Mode FSM with 5s Inactivity Timeout & Time Edit Buffer
//              - Continuous Background Real-Time Counters (Zero-Drift Clock)
//              - Dedicated Output Switch MUX for clean display separation
//              - Synchronous parallel load commit upon exiting adjustment loop
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module hms_timer #(
    parameter int CLK_FREQ_HZ       = 1_000_000,                                                     // System Clock Frequency (1 MHz)
    parameter int TICK_1KHZ_FREQ_HZ = 1_000,                                                         // 1 kHz sampling rate
    parameter int TICK_1HZ_FREQ_HZ  = 1,                                                             // 1 Hz timebase rate
    parameter int DIV_1KHZ_MAX      = (CLK_FREQ_HZ >= TICK_1KHZ_FREQ_HZ) ? ((CLK_FREQ_HZ / TICK_1KHZ_FREQ_HZ) - 1) : 0,
    parameter int DIV_1HZ_MAX       = (TICK_1KHZ_FREQ_HZ >= TICK_1HZ_FREQ_HZ) ? ((TICK_1KHZ_FREQ_HZ / TICK_1HZ_FREQ_HZ) - 1) : 0,
    parameter int DEBOUNCE_TICKS    = 20,                                                            // 20 ticks of 1 kHz = 20ms
    parameter int DEBOUNCE_TOL_PCT  = 10,                                                            // Debounce Tolerance Percentage (±10%)
    parameter int TIMEOUT_SEC       = 5,                                                             // Inactivity timeout in seconds (5s)
    parameter int SEC_WIDTH         = 6,                                                             // Second Output Bit Width (0..59)
    parameter int MIN_WIDTH         = 6,                                                             // Minute Output Bit Width (0..59)
    parameter int HOUR_WIDTH        = 5                                                              // Hour Output Bit Width (0..23)
)(
    input  logic                  clk,        // System Master Clock (1 MHz)
    input  logic                  rstn,       // Asynchronous Reset, Active-Low
    input  logic                  test_mode,  // DFT / Scan Test Bypass Enable (Default: 0)
    input  logic                  sel_in,     // Mode Selection Button (20ms Debounced)
    input  logic                  up_in,      // Value Increment Button (20ms Debounced)
    input  logic                  down_in,    // Value Decrement Button (20ms Debounced)
    output logic [HOUR_WIDTH-1:0] h_out,      // Real-Time Hour Output (0..23)
    output logic [MIN_WIDTH-1:0]  m_out,      // Real-Time Minute Output (0..59)
    output logic [SEC_WIDTH-1:0]  s_out       // Real-Time Second Output (0..59)
);

    // Mode encodings
    localparam logic [1:0] MODE_RUN      = 2'b00;
    localparam logic [1:0] MODE_ADJ_SEC  = 2'b01;
    localparam logic [1:0] MODE_ADJ_MIN  = 2'b10;
    localparam logic [1:0] MODE_ADJ_HOUR = 2'b11;

    //--------------------------------------------------------------------------
    // Internal Interconnect Signals
    //--------------------------------------------------------------------------
    logic                  rstn_sync;     // Synchronized Active-Low Reset (from reset_sync)
    logic                  tick_1khz;     // 1 kHz 1-cycle sampling tick from prescaler
    logic                  sec_tick;      // 1 Hz 1-cycle real-time pulse from prescaler
    logic                  sel_pulse;     // Synchronized & Debounced 1-cycle pulse for sel_in (1 MHz domain)
    logic                  up_pulse;      // Synchronized & Debounced 1-cycle pulse for up_in (1 MHz domain)
    logic                  down_pulse;    // Synchronized & Debounced 1-cycle pulse for down_in (1 MHz domain)
    logic [1:0]            adj_mode;      // Operating mode state from mode_controller
    logic                  load_en;       // 1-Cycle Pulse to Synchronously Load Counters on Commit
    logic [SEC_WIDTH-1:0]  adj_sec;       // Adjusted Second value from mode_controller buffer
    logic [MIN_WIDTH-1:0]  adj_min;       // Adjusted Minute value from mode_controller buffer
    logic [HOUR_WIDTH-1:0] adj_hour;      // Adjusted Hour value from mode_controller buffer
    logic [SEC_WIDTH-1:0]  s_cnt;         // Real-Time Second from second_counter
    logic [MIN_WIDTH-1:0]  m_cnt;         // Real-Time Minute from minute_counter
    logic [HOUR_WIDTH-1:0] h_cnt;         // Real-Time Hour from hour_counter
    logic                  sec_rollover;  // Rollover enable pulse from second to minute counter
    logic                  min_rollover;  // Rollover enable pulse from minute to hour counter

    //--------------------------------------------------------------------------
    // Gated Clock Signals (Output from ICG Cells)
    //--------------------------------------------------------------------------
    logic                  gated_clk_1khz; // 1 kHz Gated Clock (Debouncers & Prescaler Stage 2)
    logic                  gated_clk_sec;  // 1 Hz / Load Gated Clock (Second Counter)
    logic                  gated_clk_min;  // 1/60 Hz / Load Gated Clock (Minute Counter)
    logic                  gated_clk_hour; // 1/3600 Hz / Load Gated Clock (Hour Counter)
    logic                  gated_clk_fsm;  // Event / 1 Hz Gated Clock (Mode Controller FSM)

    //--------------------------------------------------------------------------
    // Submodule 0: Asynchronous Assert, Synchronous Deassert Reset Synchronizer
    //--------------------------------------------------------------------------
    reset_sync u_reset_sync (
        .clk        (clk),
        .rstn_async (rstn),
        .test_mode  (test_mode),
        .rstn_sync  (rstn_sync)
    );

    //--------------------------------------------------------------------------
    // Submodule 1: Centralized Clock Management & Clock Gating Unit (CCU)
    //--------------------------------------------------------------------------
    clock_control_unit u_clock_control_unit (
        .clk            (clk),
        .test_mode      (test_mode),
        .tick_1khz      (tick_1khz),
        .sec_tick       (sec_tick),
        .sec_rollover   (sec_rollover),
        .min_rollover   (min_rollover),
        .sel_pulse      (sel_pulse),
        .up_pulse       (up_pulse),
        .down_pulse     (down_pulse),
        .load_en        (load_en),
        .gated_clk_1khz (gated_clk_1khz),
        .gated_clk_sec  (gated_clk_sec),
        .gated_clk_min  (gated_clk_min),
        .gated_clk_hour (gated_clk_hour),
        .gated_clk_fsm  (gated_clk_fsm)
    );

    //--------------------------------------------------------------------------
    // Submodule 2: Multi-Stage Cascaded Frequency Prescaler
    //--------------------------------------------------------------------------
    clk_prescaler #(
        .CLK_FREQ_HZ       (CLK_FREQ_HZ),
        .TICK_1KHZ_FREQ_HZ (TICK_1KHZ_FREQ_HZ),
        .TICK_1HZ_FREQ_HZ  (TICK_1HZ_FREQ_HZ),
        .DIV_1KHZ_MAX      (DIV_1KHZ_MAX),
        .DIV_1HZ_MAX       (DIV_1HZ_MAX)
    ) u_clk_prescaler (
        .clk       (clk),
        .rstn      (rstn_sync),
        .tick_1khz (tick_1khz),
        .sec_tick  (sec_tick)
    );

    //--------------------------------------------------------------------------
    // Submodule 3: Multi-Channel Button Controller & Pulse Alignment Subsystem
    //--------------------------------------------------------------------------
    button_controller #(
        .DEBOUNCE_TICKS   (DEBOUNCE_TICKS),
        .DEBOUNCE_TOL_PCT (DEBOUNCE_TOL_PCT)
    ) u_button_controller (
        .clk            (clk),
        .rstn           (rstn_sync),
        .gated_clk_1khz (gated_clk_1khz),
        .sel_in         (sel_in),
        .up_in          (up_in),
        .down_in        (down_in),
        .sel_pulse      (sel_pulse),
        .up_pulse       (up_pulse),
        .down_pulse     (down_pulse)
    );

    //--------------------------------------------------------------------------
    // Submodule 4: Mode Controller & Inactivity Timeout FSM (Clocked by Gated Clock)
    //--------------------------------------------------------------------------
    mode_controller #(
        .TIMEOUT_SEC (TIMEOUT_SEC),
        .SEC_WIDTH   (SEC_WIDTH),
        .MIN_WIDTH   (MIN_WIDTH),
        .HOUR_WIDTH  (HOUR_WIDTH)
    ) u_mode_controller (
        .clk        (gated_clk_fsm),
        .rstn       (rstn_sync),
        .sel_pulse  (sel_pulse),
        .up_pulse   (up_pulse),
        .down_pulse (down_pulse),
        .sec_tick   (sec_tick),
        .s_cur      (s_cnt),
        .m_cur      (m_cnt),
        .h_cur      (h_cnt),
        .adj_mode   (adj_mode),
        .adj_sec    (adj_sec),
        .adj_min    (adj_min),
        .adj_hour   (adj_hour),
        .load_en    (load_en)
    );

    //--------------------------------------------------------------------------
    // Submodule 5: Modulo-60 Second Counter (Clocked by Gated Clock 1Hz / Load)
    //--------------------------------------------------------------------------
    second_counter #(
        .SEC_WIDTH (SEC_WIDTH)
    ) u_second_counter (
        .clk          (gated_clk_sec),
        .rstn         (rstn_sync),
        .sec_tick     (sec_tick),
        .load_en      (load_en),
        .load_val     (adj_sec),
        .s_out        (s_cnt),
        .sec_rollover (sec_rollover)
    );

    //--------------------------------------------------------------------------
    // Submodule 6: Modulo-60 Minute Counter (Clocked by Gated Clock 1/60Hz / Load)
    //--------------------------------------------------------------------------
    minute_counter #(
        .MIN_WIDTH (MIN_WIDTH)
    ) u_minute_counter (
        .clk          (gated_clk_min),
        .rstn         (rstn_sync),
        .sec_rollover (sec_rollover),
        .load_en      (load_en),
        .load_val     (adj_min),
        .m_out        (m_cnt),
        .min_rollover (min_rollover)
    );

    //--------------------------------------------------------------------------
    // Submodule 7: Modulo-24 Hour Counter (Clocked by Gated Clock 1/3600Hz / Load)
    //--------------------------------------------------------------------------
    hour_counter #(
        .HOUR_WIDTH (HOUR_WIDTH)
    ) u_hour_counter (
        .clk          (gated_clk_hour),
        .rstn         (rstn_sync),
        .min_rollover (min_rollover),
        .load_en      (load_en),
        .load_val     (adj_hour),
        .h_out        (h_cnt)
    );

    //--------------------------------------------------------------------------
    // Submodule 8: Output Switch Display Multiplexer
    //--------------------------------------------------------------------------
    output_switch #(
        .SEC_WIDTH  (SEC_WIDTH),
        .MIN_WIDTH  (MIN_WIDTH),
        .HOUR_WIDTH (HOUR_WIDTH)
    ) u_output_switch (
        .adj_mode (adj_mode),
        .s_cnt    (s_cnt),
        .m_cnt    (m_cnt),
        .h_cnt    (h_cnt),
        .s_adj    (adj_sec),
        .m_adj    (adj_min),
        .h_adj    (adj_hour),
        .s_out    (s_out),
        .m_out    (m_out),
        .h_out    (h_out)
    );

endmodule
