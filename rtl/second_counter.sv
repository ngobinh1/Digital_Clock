//==============================================================================
// File: second_counter.sv
// Module: second_counter
// Description: Modulo-60 Real-Time Second Counter (0..59) supporting:
//              - Continuous background real-time counting enabled by sec_tick (1 Hz)
//              - Synchronous parallel load from mode_controller when load_en = 1
//              - Synchronous rollover flag generation (sec_rollover)
//              - Synchronous reset on 1 MHz master clock
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module second_counter #(
    parameter int SEC_WIDTH = 6
)(
    input  logic                 clk,          // System Master Clock (1 MHz)
    input  logic                 rstn,         // Reset, Active-Low
    input  logic                 sec_tick,     // 1-Cycle Pulse from Prescaler (1 Hz Clock Enable)
    input  logic                 load_en,      // 1-Cycle Pulse to Load Parallel Value
    input  logic [SEC_WIDTH-1:0] load_val,     // Parallel Load Value from mode_controller
    output logic [SEC_WIDTH-1:0] s_out,        // Second Output (0..59)
    output logic                 sec_rollover  // 1-Cycle Rollover Enable to Minute Counter
);

    logic [SEC_WIDTH-1:0] r_sec;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r_sec <= '0;
        end else if (load_en) begin
            // Priority 1: Synchronous parallel load upon committing adjusted time
            r_sec <= load_val;
        end else if (sec_tick) begin
            // Priority 2: 1 Hz Clock Enable tick
            if (r_sec >= 6'd59) begin
                r_sec <= '0;
            end else begin
                r_sec <= r_sec + 1'b1;
            end
        end
    end

    assign s_out        = r_sec;
    assign sec_rollover = (r_sec == 6'd59) & sec_tick & ~load_en;

endmodule
