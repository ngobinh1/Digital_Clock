//==============================================================================
// File: reset_sync.sv
// Module: reset_sync
// Description: Standard 2-Stage Flip-Flop Reset Synchronizer (Asynchronous Assert, Synchronous Deassert).
//              - Immediate asynchronous assertion upon rstn_async = 0 (zero clock dependency).
//              - Glitch-free synchronous deassertion after 2 clock cycles upon rstn_async release.
//              - Eliminates recovery/removal timing violations and metastability.
//              - 100% portable across ASIC and FPGA.
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

    always_ff @(posedge clk or negedge rstn_async) begin
        if (!rstn_async) begin
            r_sync_stage1 <= 1'b0;
            r_sync_stage2 <= 1'b0;
        end else begin
            r_sync_stage1 <= 1'b1;
            r_sync_stage2 <= r_sync_stage1;
        end
    end

    // Output assignment
    assign rstn_sync = r_sync_stage2;

endmodule
