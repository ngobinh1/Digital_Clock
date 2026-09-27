//==============================================================================
// File: hour_counter.sv
// Module: hour_counter
// Description: Modulo-24 Real-Time Hour Counter (0..23) supporting:
//              - Continuous background real-time counting on gated_clk_hour (Zero-Drift Clock)
//              - Synchronous parallel load from mode_controller when load_en = 1
//              - Daily rollover wrap-around (23 -> 0)
//              - Zero shadow registers overhead
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module hour_counter #(
    parameter int HOUR_WIDTH = 5
)(
    input  logic                  clk,          // System Clock (gated_clk_hour)
    input  logic                  rstn,         // Asynchronous Reset, Active-Low
    input  logic                  min_rollover, // 1-Cycle Rollover Enable from minute_counter
    input  logic                  load_en,      // 1-Cycle Pulse to Load Parallel Value
    input  logic [HOUR_WIDTH-1:0] load_val,     // Parallel Load Value from mode_controller
    output logic [HOUR_WIDTH-1:0] h_out         // Hour Output (0..23)
);

    // Internal register
    logic [HOUR_WIDTH-1:0] r_hour;

    //--------------------------------------------------------------------------
    // Hour Counter Sequential Logic (Posedge clk, Asynchronous rstn)
    // Clock is already gated by (min_rollover | load_en).
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_hour <= '0;
        end else begin
            if (load_en) begin
                // Synchronous parallel load upon committing adjusted time
                r_hour <= load_val;
            end else begin
                // Continuous background counting: 0 -> 23 -> 0
                if (r_hour >= 5'd23) begin
                    r_hour <= '0;
                end else begin
                    r_hour <= r_hour + 1'b1;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // Output Data Assignment
    //--------------------------------------------------------------------------
    assign h_out = r_hour;

endmodule
