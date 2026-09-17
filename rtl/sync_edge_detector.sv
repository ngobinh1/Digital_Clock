//==============================================================================
// File: sync_edge_detector.sv
// Module: sync_edge_detector
// Description: 2-stage Flip-Flop Synchronizer and Positive Edge Detector for
//              asynchronous control button inputs (sel_in, up_in, down_in).
//              Triệt tiêu hoàn toàn metastability và tạo xung đơn kỳ 1-clock cycle.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module sync_edge_detector (
    input  logic clk,        // System Clock (1 MHz)
    input  logic rstn,       // Asynchronous Reset, Active-Low
    input  logic sel_in,     // Asynchronous Select Button Input
    input  logic up_in,      // Asynchronous Up Button Input
    input  logic down_in,    // Asynchronous Down Button Input
    output logic sel_pulse,  // 1-Clock Cycle Pulse on sel_in rising edge
    output logic up_pulse,   // 1-Clock Cycle Pulse on up_in rising edge
    output logic down_pulse  // 1-Clock Cycle Pulse on down_in rising edge
);

    //--------------------------------------------------------------------------
    // Internal 2-stage Synchronizer & Edge-Detection Flip-Flop Registers
    // [FF1: Sync Stage 1, FF2: Sync Stage 2, FF3: Edge Delay Register]
    //--------------------------------------------------------------------------
    logic [2:0] sel_sync_reg;
    logic [2:0] up_sync_reg;
    logic [2:0] down_sync_reg;

    //--------------------------------------------------------------------------
    // Synchronizer & Edge Delay Logic (Posedge clk, Asynchronous rstn)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sel_sync_reg  <= 3'b000;
            up_sync_reg   <= 3'b000;
            down_sync_reg <= 3'b000;
        end else begin
            // Shift register for synchronization and edge detection
            sel_sync_reg  <= {sel_sync_reg[1:0], sel_in};
            up_sync_reg   <= {up_sync_reg[1:0], up_in};
            down_sync_reg <= {down_sync_reg[1:0], down_in};
        end
    end

    //--------------------------------------------------------------------------
    // Positive Edge Detection Equation: pulse = FF2 & ~FF3
    // sel_sync_reg[1] is FF2 (synchronized level)
    // sel_sync_reg[2] is FF3 (delayed level for 1-cycle comparison)
    //--------------------------------------------------------------------------
    assign sel_pulse  = sel_sync_reg[1]  & (~sel_sync_reg[2]);
    assign up_pulse   = up_sync_reg[1]   & (~up_sync_reg[2]);
    assign down_pulse = down_sync_reg[1] & (~down_sync_reg[2]);

endmodule
