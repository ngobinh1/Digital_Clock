//==============================================================================
// File: minute_counter.sv
// Module: minute_counter
// Description: Modulo-60 Real-Time Minute Counter (0..59) supporting:
//              - Continuous background real-time counting enabled by sec_rollover
//              - Synchronous parallel load from mode_controller when load_en = 1
//              - Synchronous rollover flag generation (min_rollover)
//              - Synchronous reset on 1 MHz master clock
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module minute_counter #(
    parameter int MIN_WIDTH = 6
)(
    input  logic                 clk,          // System Master Clock (1 MHz)
    input  logic                 rstn,         // Reset, Active-Low
    input  logic                 sec_rollover, // 1-Cycle Rollover Enable from second_counter
    input  logic                 load_en,      // 1-Cycle Pulse to Load Parallel Value
    input  logic [MIN_WIDTH-1:0] load_val,     // Parallel Load Value from mode_controller
    output logic [MIN_WIDTH-1:0] m_out,        // Minute Output (0..59)
    output logic                 min_rollover  // 1-Cycle Rollover Enable to Hour Counter
);

    logic [MIN_WIDTH-1:0] r_min;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r_min <= '0;
        end else if (load_en) begin
            // Priority 1: Synchronous parallel load upon committing adjusted time
            r_min <= load_val;
        end else if (sec_rollover) begin
            // Priority 2: Rollover Clock Enable from second counter
            if (r_min >= 6'd59) begin
                r_min <= '0;
            end else begin
                r_min <= r_min + 1'b1;
            end
        end
    end

    assign m_out        = r_min;
    assign min_rollover = (r_min == 6'd59) & sec_rollover & ~load_en;

endmodule
