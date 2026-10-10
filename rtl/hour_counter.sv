//==============================================================================
// File: hour_counter.sv
// Module: hour_counter
// Description: Modulo-24 Real-Time Hour Counter (0..23) supporting:
//              - Continuous background real-time counting enabled by min_rollover
//              - Synchronous parallel load from mode_controller when load_en = 1
//              - Daily rollover wrap-around (23 -> 0)
//              - Synchronous reset on 1 MHz master clock
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module hour_counter #(
    parameter int HOUR_WIDTH = 5
)(
    input  logic                  clk,          // System Master Clock (1 MHz)
    input  logic                  rstn,         // Reset, Active-Low
    input  logic                  min_rollover, // 1-Cycle Rollover Enable from minute_counter
    input  logic                  load_en,      // 1-Cycle Pulse to Load Parallel Value
    input  logic [HOUR_WIDTH-1:0] load_val,     // Parallel Load Value from mode_controller
    output logic [HOUR_WIDTH-1:0] h_out         // Hour Output (0..23)
);

    logic [HOUR_WIDTH-1:0] r_hour;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r_hour <= '0;
        end else if (load_en) begin
            // Priority 1: Synchronous parallel load upon committing adjusted time
            r_hour <= load_val;
        end else if (min_rollover) begin
            // Priority 2: Rollover Clock Enable from minute counter
            if (r_hour >= 5'd23) begin
                r_hour <= '0;
            end else begin
                r_hour <= r_hour + 1'b1;
            end
        end
    end

    assign h_out = r_hour;

endmodule
