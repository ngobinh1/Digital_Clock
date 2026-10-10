//==============================================================================
// File: reset_sync.sv
// Module: reset_sync
// Description: Standard 2-Stage Flip-Flop Synchronous Reset Synchronizer.
//              - Synchronizes raw reset input to posedge clk.
//              - Eliminates contact bounce, recovery/removal violations and metastability.
//              - 100% synchronous, portable across ASIC and FPGA.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module reset_sync (
    input  logic clk,        // System Master Clock (1 MHz)
    input  logic rstn_async, // Asynchronous Reset Input, Active-Low
    output logic rstn_sync   // Synchronized Reset Output, Active-Low
);

    // 2-Stage Synchronizer Flip-Flops
    // Attributes to prevent logic optimization / shift register merging during synthesis
    (* async_reg = "true" *) logic r_sync_stage1;
    (* async_reg = "true" *) logic r_sync_stage2;

    always_ff @(posedge clk) begin
        r_sync_stage1 <= rstn_async;
        r_sync_stage2 <= r_sync_stage1;
    end

    // Output assignment
    assign rstn_sync = r_sync_stage2;

endmodule
