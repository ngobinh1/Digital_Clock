//==============================================================================
// File: reset_sync.sv
// Module: reset_sync
// Description: Standard 2-Stage Flip-Flop Reset Synchronizer with
//              Asynchronous Assert and Synchronous Deassert architecture.
//              - Guarantees immediate asynchronous assertion to reset all registers without clock delay.
//              - Synchronizes reset release to posedge clk (after 2 clock cycles), eliminating
//                recovery/removal violations and preventing metastability across downstream blocks.
//              - Incorporates DFT Scan test_mode bypass mux for complete ATPG scan controllability.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module reset_sync (
    input  logic clk,        // System Master Clock (1 MHz)
    input  logic rstn_async, // Asynchronous Reset Input, Active-Low
    input  logic test_mode,  // DFT / Scan Test Bypass Enable (Active-High)
    output logic rstn_sync   // Synchronized Reset Output, Active-Low
);

    // 2-Stage Synchronizer Flip-Flops
    // Attributes to prevent logic optimization / shift register merging during synthesis
    (* async_reg = "true" *) logic r_sync_stage1;
    (* async_reg = "true" *) logic r_sync_stage2;

    always_ff @(posedge clk or negedge rstn_async) begin
        if (!rstn_async) begin
            r_sync_stage1 <= 1'b0;
            r_sync_stage2 <= 1'b0;
        end else begin
            r_sync_stage1 <= 1'b1;
            r_sync_stage2 <= r_sync_stage1;
        end
    end

    // DFT Scan Test Mode Bypass Multiplexer
    assign rstn_sync = (test_mode) ? rstn_async : r_sync_stage2;

endmodule
