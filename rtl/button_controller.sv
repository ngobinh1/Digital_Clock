//==============================================================================
// File: button_controller.sv
// Module: button_controller
// Description: Multi-Channel Button Controller & Pulse Alignment Subsystem.
//              - Integrates 3 independent 1 kHz pure-clock debouncers (sel, up, down)
//              - Filters mechanical switch contact bounce with 20ms ±10% tolerance (18 ticks)
//              - Implements continuous auto-repeat pulse generation
//              - Aligns 1 kHz debouncer events to clean single-cycle 1 MHz pulses (1 µs)
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module button_controller #(
    parameter int DEBOUNCE_TICKS   = 20,                                                      // Nominal 20ms debounce threshold
    parameter int DEBOUNCE_TOL_PCT = 10                                                       // Tolerance Percentage (±10% -> 18 ticks)
)(
    input  logic clk,            // System Master Clock (1 MHz)
    input  logic rstn,           // Asynchronous Reset, Active-Low
    input  logic gated_clk_1khz, // 1 kHz Gated Clock from clock_control_unit
    input  logic sel_in,         // Asynchronous Mode Select Button Input
    input  logic up_in,          // Asynchronous Increment Button Input
    input  logic down_in,        // Asynchronous Decrement Button Input
    output logic sel_pulse,      // Synchronized 1-cycle active-high pulse (1 MHz domain)
    output logic up_pulse,       // Synchronized 1-cycle active-high pulse (1 MHz domain)
    output logic down_pulse      // Synchronized 1-cycle active-high pulse (1 MHz domain)
);

    //--------------------------------------------------------------------------
    // Internal Signals
    //--------------------------------------------------------------------------
    logic sel_event_1k;
    logic up_event_1k;
    logic down_event_1k;

    logic sel_event_d;
    logic up_event_d;
    logic down_event_d;

    //--------------------------------------------------------------------------
    // Sub-module Instances: 3-Channel 1 kHz Debouncers
    //--------------------------------------------------------------------------
    button_debouncer #(
        .DEBOUNCE_TICKS   (DEBOUNCE_TICKS),
        .DEBOUNCE_TOL_PCT (DEBOUNCE_TOL_PCT)
    ) u_debouncer_sel (
        .clk        (gated_clk_1khz),
        .rstn       (rstn),
        .btn_in     (sel_in),
        .btn_event  (sel_event_1k)
    );

    button_debouncer #(
        .DEBOUNCE_TICKS   (DEBOUNCE_TICKS),
        .DEBOUNCE_TOL_PCT (DEBOUNCE_TOL_PCT)
    ) u_debouncer_up (
        .clk        (gated_clk_1khz),
        .rstn       (rstn),
        .btn_in     (up_in),
        .btn_event  (up_event_1k)
    );

    button_debouncer #(
        .DEBOUNCE_TICKS   (DEBOUNCE_TICKS),
        .DEBOUNCE_TOL_PCT (DEBOUNCE_TOL_PCT)
    ) u_debouncer_down (
        .clk        (gated_clk_1khz),
        .rstn       (rstn),
        .btn_in     (down_in),
        .btn_event  (down_event_1k)
    );

    //--------------------------------------------------------------------------
    // 1 MHz Single-Cycle Pulse Alignment / Edge Detection
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sel_event_d  <= 1'b0;
            up_event_d   <= 1'b0;
            down_event_d <= 1'b0;
            sel_pulse    <= 1'b0;
            up_pulse     <= 1'b0;
            down_pulse   <= 1'b0;
        end else begin
            sel_event_d  <= sel_event_1k;
            up_event_d   <= up_event_1k;
            down_event_d <= down_event_1k;
            sel_pulse    <= sel_event_1k  & ~sel_event_d;
            up_pulse     <= up_event_1k   & ~up_event_d;
            down_pulse   <= down_event_1k & ~down_event_d;
        end
    end

endmodule
