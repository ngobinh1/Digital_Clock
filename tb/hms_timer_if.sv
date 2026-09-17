//==============================================================================
// File: hms_timer_if.sv
// Interface: hms_timer_if
// Description: SystemVerilog Verification Interface for HMS_Timer IP Core,
//              equipped with Clocking Blocks, Modports and SVA Concurrent Assertions.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`timescale 1ns / 1ps

interface hms_timer_if #(
    parameter int SEC_WIDTH  = 6,
    parameter int MIN_WIDTH  = 6,
    parameter int HOUR_WIDTH = 5
)(
    input logic clk
);
    // Asynchronous / Control inputs
    logic                  rstn;
    logic                  sel_in;
    logic                  up_in;
    logic                  down_in;

    // Time outputs
    logic [HOUR_WIDTH-1:0] h_out;
    logic [MIN_WIDTH-1:0]  m_out;
    logic [SEC_WIDTH-1:0]  s_out;

    // Internal probe signals for deep-cycle verification
    logic                  sel_pulse;
    logic                  up_pulse;
    logic                  down_pulse;
    logic                  sec_tick;
    logic [1:0]            adj_mode;
    logic                  sec_rollover;
    logic                  min_rollover;

    //--------------------------------------------------------------------------
    // Driver Clocking Block (Synchronous stimulus driving)
    //--------------------------------------------------------------------------
    clocking cb_drv @(posedge clk);
        default input #1ns output #1ns;
        output sel_in;
        output up_in;
        output down_in;
        input  rstn;
        input  h_out;
        input  m_out;
        input  s_out;
        input  adj_mode;
    endclocking

    //--------------------------------------------------------------------------
    // Monitor Clocking Block (Cycle-accurate output sampling)
    //--------------------------------------------------------------------------
    clocking cb_mon @(posedge clk);
        default input #1ns;
        input rstn;
        input sel_in;
        input up_in;
        input down_in;
        input h_out;
        input m_out;
        input s_out;
        input sel_pulse;
        input up_pulse;
        input down_pulse;
        input sec_tick;
        input adj_mode;
        input sec_rollover;
        input min_rollover;
    endclocking

    // Modports
    modport DRV (clocking cb_drv, output rstn, output sel_in, output up_in, output down_in);
    modport MON (clocking cb_mon);
    modport DUT (
        input  clk, rstn, sel_in, up_in, down_in,
        output h_out, m_out, s_out
    );

    //==========================================================================
    // SVA (SystemVerilog Assertions) - Formal & Dynamic Verification Rules
    //==========================================================================

    // A1: Seconds Output Range Check (0 <= s_out <= 59)
    property p_s_out_range;
        @(posedge clk) disable iff (!rstn)
        (s_out <= 6'd59);
    endproperty
    assert_s_out_range: assert property (p_s_out_range)
        else $error("[SVA FAIL] s_out out of range (0..59): %0d", s_out);

    // A2: Minutes Output Range Check (0 <= m_out <= 59)
    property p_m_out_range;
        @(posedge clk) disable iff (!rstn)
        (m_out <= 6'd59);
    endproperty
    assert_m_out_range: assert property (p_m_out_range)
        else $error("[SVA FAIL] m_out out of range (0..59): %0d", m_out);

    // A3: Hours Output Range Check (0 <= h_out <= 23)
    property p_h_out_range;
        @(posedge clk) disable iff (!rstn)
        (h_out <= 5'd23);
    endproperty
    assert_h_out_range: assert property (p_h_out_range)
        else $error("[SVA FAIL] h_out out of range (0..23): %0d", h_out);

    // A4: Synchronous Reset Clear Check
    property p_reset_state;
        @(posedge clk)
        (!rstn) |-> (s_out == 6'd0 && m_out == 6'd0 && h_out == 5'd0);
    endproperty
    assert_reset_state: assert property (p_reset_state)
        else $error("[SVA FAIL] Outputs not zero during reset: H=%0d M=%0d S=%0d", h_out, m_out, s_out);

    // A5: Rollover Gating Check in Adjust Modes
    property p_sec_rollover_gated;
        @(posedge clk) disable iff (!rstn)
        (adj_mode != 2'b00) |-> (!sec_rollover);
    endproperty
    assert_sec_rollover_gated: assert property (p_sec_rollover_gated)
        else $error("[SVA FAIL] sec_rollover active during Adjust Mode!");

    property p_min_rollover_gated;
        @(posedge clk) disable iff (!rstn)
        (adj_mode != 2'b00) |-> (!min_rollover);
    endproperty
    assert_min_rollover_gated: assert property (p_min_rollover_gated)
        else $error("[SVA FAIL] min_rollover active during Adjust Mode!");

endinterface
