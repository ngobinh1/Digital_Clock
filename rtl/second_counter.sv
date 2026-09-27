//==============================================================================
// File: second_counter.sv
// Module: second_counter
// Description: Modulo-60 Real-Time Second Counter (0..59) supporting:
//              - Continuous background real-time counting on gated_clk_sec (Zero-Drift Clock)
//              - Synchronous parallel load from mode_controller when load_en = 1
//              - Synchronous rollover flag generation (sec_rollover)
//              - Zero shadow registers overhead
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module second_counter #(
    parameter int SEC_WIDTH = 6
)(
    input  logic                 clk,          // System Clock (gated_clk_sec)
    input  logic                 rstn,         // Asynchronous Reset, Active-Low
    input  logic                 sec_tick,     // 1-Cycle Pulse from Prescaler (1 Hz)
    input  logic                 load_en,      // 1-Cycle Pulse to Load Parallel Value
    input  logic [SEC_WIDTH-1:0] load_val,     // Parallel Load Value from mode_controller
    output logic [SEC_WIDTH-1:0] s_out,        // Second Output (0..59)
    output logic                 sec_rollover  // 1-Cycle Rollover Enable to Minute Counter
);

    // Internal register
    logic [SEC_WIDTH-1:0] r_sec;

    //--------------------------------------------------------------------------
    // Second Counter Sequential Logic (Posedge clk, Asynchronous rstn)
    // Clock is already gated by (sec_tick | load_en).
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_sec <= '0;
        end else begin
            if (load_en) begin
                // Synchronous parallel load upon committing adjusted time
                r_sec <= load_val;
            end else begin
                // Continuous background counting: 0 -> 59 -> 0
                if (r_sec >= 6'd59) begin
                    r_sec <= '0;
                end else begin
                    r_sec <= r_sec + 1'b1;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // Output Data & Rollover Enable Generation
    // sec_rollover is generated when r_sec == 59 and sec_tick occurs (and no load).
    //--------------------------------------------------------------------------
    assign s_out        = r_sec;
    assign sec_rollover = (r_sec == 6'd59) & sec_tick & ~load_en;

endmodule
