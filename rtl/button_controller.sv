//==============================================================================
// File: button_controller.sv
// Module: button_controller
// Description: Multi-Channel Button Controller & Pulse Alignment Subsystem.
//              - Integrates 3 independent debouncers (sel, up, down)
//              - Filters mechanical switch contact bounce with 20ms ±10% tolerance (18 pulses)
//              - Implements continuous auto-repeat pulse generation
//              - Emits clean single-cycle 1 MHz pulses (1 µs) directly
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module button_controller #(
    parameter int P_DEBOUNCE_PULSES   = 20,                                                      // Nominal 20ms debounce threshold
    parameter int P_DEBOUNCE_TOL_PCT  = 10                                                       // Tolerance Percentage (±10% -> 18 pulses)
)(
    input  logic clk,        // System Master Clock (1 MHz)
    input  logic rstn,       // Reset, Active-Low
    input  logic pulse_1khz, // 1 kHz sampling pulse (acting as Clock Enable)
    input  logic sel_in,     // Asynchronous Mode Select Button Input
    input  logic up_in,      // Asynchronous Increment Button Input
    input  logic down_in,    // Asynchronous Decrement Button Input
    output logic sel_pulse,  // Synchronized 1-cycle active-high pulse (1 MHz domain)
    output logic up_pulse,   // Synchronized 1-cycle active-high pulse (1 MHz domain)
    output logic down_pulse  // Synchronized 1-cycle active-high pulse (1 MHz domain)
);

    //--------------------------------------------------------------------------
    // Sub-module Instances: 3-Channel Debouncers
    //--------------------------------------------------------------------------
    button_debouncer #(
        .P_DEBOUNCE_PULSES   (P_DEBOUNCE_PULSES),
        .P_DEBOUNCE_TOL_PCT  (P_DEBOUNCE_TOL_PCT)
    ) u_debouncer_sel (
        .clk        (clk),
        .rstn       (rstn),
        .clk_en     (pulse_1khz),
        .btn_in     (sel_in),
        .btn_event  (sel_pulse)
    );

    button_debouncer #(
        .P_DEBOUNCE_PULSES   (P_DEBOUNCE_PULSES),
        .P_DEBOUNCE_TOL_PCT  (P_DEBOUNCE_TOL_PCT)
    ) u_debouncer_up (
        .clk        (clk),
        .rstn       (rstn),
        .clk_en     (pulse_1khz),
        .btn_in     (up_in),
        .btn_event  (up_pulse)
    );

    button_debouncer #(
        .P_DEBOUNCE_PULSES   (P_DEBOUNCE_PULSES),
        .P_DEBOUNCE_TOL_PCT  (P_DEBOUNCE_TOL_PCT)
    ) u_debouncer_down (
        .clk        (clk),
        .rstn       (rstn),
        .clk_en     (pulse_1khz),
        .btn_in     (down_in),
        .btn_event  (down_pulse)
    );

endmodule
