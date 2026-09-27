//==============================================================================
// File: output_switch.sv
// Module: output_switch
// Description: Combinational Display Multiplexer selecting between:
//              - Real-time background counter values (when in MODE_RUN)
//              - Interactive edit buffer values from mode_controller (when in MODE_ADJ_*)
//              Pure zero-latency combinational logic (no flip-flops).
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module output_switch #(
    parameter int SEC_WIDTH  = 6,
    parameter int MIN_WIDTH  = 6,
    parameter int HOUR_WIDTH = 5
)(
    input  logic [1:0]            adj_mode, // Current Operating Mode (00:RUN, 01:SEC, 10:MIN, 11:HOUR)
    input  logic [SEC_WIDTH-1:0]  s_cnt,    // Real-Time Second from Background Counter
    input  logic [MIN_WIDTH-1:0]  m_cnt,    // Real-Time Minute from Background Counter
    input  logic [HOUR_WIDTH-1:0] h_cnt,    // Real-Time Hour from Background Counter
    input  logic [SEC_WIDTH-1:0]  s_adj,    // Adjusted Second from Edit Buffer
    input  logic [MIN_WIDTH-1:0]  m_adj,    // Adjusted Minute from Edit Buffer
    input  logic [HOUR_WIDTH-1:0] h_adj,    // Adjusted Hour from Edit Buffer
    output logic [SEC_WIDTH-1:0]  s_out,    // Top-Level Second Display Output
    output logic [MIN_WIDTH-1:0]  m_out,    // Top-Level Minute Display Output
    output logic [HOUR_WIDTH-1:0] h_out     // Top-Level Hour Display Output
);

    localparam logic [1:0] MODE_RUN = 2'b00;

    assign s_out = (adj_mode == MODE_RUN) ? s_cnt : s_adj;
    assign m_out = (adj_mode == MODE_RUN) ? m_cnt : m_adj;
    assign h_out = (adj_mode == MODE_RUN) ? h_cnt : h_adj;

endmodule
