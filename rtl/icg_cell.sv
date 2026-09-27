//==============================================================================
// File: icg_cell.sv
// Module: icg_cell
// Description: Glitch-Free Integrated Clock Gating (ICG) Cell.
//              - Uses an active-low transparent latch to sample enable (en)
//                when clk_in is LOW.
//              - Prevents any glitch or runt pulse when enable changes.
//              - Supports test_mode / scan bypass for 100% ATPG testability.
//              - In ASIC synthesis, automatically maps to vendor standard ICG cells.
//              - In FPGA synthesis, synthesizes cleanly to glitch-free gating logic.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module icg_cell (
    input  logic clk_in,    // Master Input Clock (1 MHz)
    input  logic en,        // Clock Enable (evaluated on posedge clk_in)
    input  logic test_mode, // DFT/Scan Bypass (Forces clock open during test)
    output logic clk_out    // Gated Clock Output
);

    // Active-Low Latch: Transparent when clk_in is LOW (0)
    // When clk_in rises to 1, latch becomes opaque (latched), holding en_latch stable
    logic en_latch;

    always_latch begin
        if (!clk_in) begin
            en_latch <= en | test_mode;
        end
    end

    // Gated clock output using AND gate
    assign clk_out = clk_in & en_latch;

endmodule
