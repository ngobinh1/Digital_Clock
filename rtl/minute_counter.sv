//==============================================================================
// File: minute_counter.sv
// Module: minute_counter
// Description: Modulo-60 Real-Time Minute Counter (0..59) supporting:
//              - Continuous background real-time counting on gated_clk_min (Zero-Drift Clock)
//              - Synchronous parallel load from mode_controller when load_en = 1
//              - Synchronous rollover flag generation (min_rollover)
//              - Zero shadow registers overhead
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module minute_counter #(
    parameter int MIN_WIDTH = 6
)(
    input  logic                 clk,          // System Clock (gated_clk_min)
    input  logic                 rstn,         // Asynchronous Reset, Active-Low
    input  logic                 sec_rollover, // 1-Cycle Rollover Enable from second_counter
    input  logic                 load_en,      // 1-Cycle Pulse to Load Parallel Value
    input  logic [MIN_WIDTH-1:0] load_val,     // Parallel Load Value from mode_controller
    output logic [MIN_WIDTH-1:0] m_out,        // Minute Output (0..59)
    output logic                 min_rollover  // 1-Cycle Rollover Enable to Hour Counter
);

    // Internal register
    logic [MIN_WIDTH-1:0] r_min;

    //--------------------------------------------------------------------------
    // Minute Counter Sequential Logic (Posedge clk, Asynchronous rstn)
    // Clock is already gated by (sec_rollover | load_en).
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_min <= '0;
        end else begin
            if (load_en) begin
                // Synchronous parallel load upon committing adjusted time
                r_min <= load_val;
            end else begin
                // Continuous background counting: 0 -> 59 -> 0
                if (r_min >= 6'd59) begin
                    r_min <= '0;
                end else begin
                    r_min <= r_min + 1'b1;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // Output Data & Rollover Enable Generation
    // min_rollover is generated when r_min == 59 and sec_rollover occurs (and no load).
    //--------------------------------------------------------------------------
    assign m_out        = r_min;
    assign min_rollover = (r_min == 6'd59) & sec_rollover & ~load_en;

endmodule
