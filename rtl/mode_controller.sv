//==============================================================================
// File: mode_controller.sv
// Module: mode_controller
// Description: Finite State Machine (FSM) for Mode Control:
//              - 2'b00 (MODE_RUN): Normal Real-Time Counting
//              - 2'b01 (MODE_ADJ_SEC): Second Adjustment Mode
//              - 2'b10 (MODE_ADJ_MIN): Minute Adjustment Mode
//              - 2'b11 (MODE_ADJ_HOUR): Hour Adjustment Mode
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module mode_controller (
    input  logic       clk,           // System Clock (1 MHz)
    input  logic       rstn,          // Asynchronous Reset, Active-Low
    input  logic       sel_pulse,     // 1-Cycle Pulse from Select Button Edge
    output logic [1:0] adj_mode       // Current Operating Mode State Output
);

    //--------------------------------------------------------------------------
    // State Encoding Definitions
    //--------------------------------------------------------------------------
    typedef enum logic [1:0] {
        MODE_RUN      = 2'b00,  // Real-time normal counting
        MODE_ADJ_SEC  = 2'b01,  // Second adjustment
        MODE_ADJ_MIN  = 2'b10,  // Minute adjustment
        MODE_ADJ_HOUR = 2'b11   // Hour adjustment
    } state_t;

    state_t state_reg, state_next;

    //--------------------------------------------------------------------------
    // State Register (Posedge clk, Asynchronous rstn)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state_reg <= MODE_RUN;
        end else begin
            state_reg <= state_next;
        end
    end

    //--------------------------------------------------------------------------
    // Next State Combinational Logic
    //--------------------------------------------------------------------------
    always_comb begin
        state_next = state_reg;
        if (sel_pulse) begin
            case (state_reg)
                MODE_RUN:      state_next = MODE_ADJ_SEC;
                MODE_ADJ_SEC:  state_next = MODE_ADJ_MIN;
                MODE_ADJ_MIN:  state_next = MODE_ADJ_HOUR;
                MODE_ADJ_HOUR: state_next = MODE_RUN;
                default:       state_next = MODE_RUN;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Output Assignment
    //--------------------------------------------------------------------------
    assign adj_mode = state_reg;

endmodule
