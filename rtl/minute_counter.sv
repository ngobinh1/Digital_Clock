//==============================================================================
// File: minute_counter.sv
// Module: minute_counter
// Description: Modulo-60 Minute Counter (0..59) supporting:
//              - Real-time increment on sec_rollover in MODE_RUN
//              - Bidirectional adjustment with wrap-around in MODE_ADJ_MIN
//              - Synchronous rollover flag generation (min_rollover)
//              - Rollover gating during adjustment to prevent cascade errors
//              - Snapshot capture upon entering adjust mode
//              - Automatic rollback to snapshot upon cancel_pulse (Timeout 5s)
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module minute_counter #(
    parameter int MIN_WIDTH = 6
)(
    input  logic                 clk,          // System Clock (1 MHz)
    input  logic                 rstn,         // Asynchronous Reset, Active-Low
    input  logic [1:0]           adj_mode,     // Current Mode from mode_controller
    input  logic                 sec_rollover, // 1-Cycle Rollover Enable from second_counter
    input  logic                 sel_pulse,    // 1-Cycle Pulse from Select Button (Debounced)
    input  logic                 up_pulse,     // 1-Cycle Pulse from Up Button (Debounced)
    input  logic                 down_pulse,   // 1-Cycle Pulse from Down Button (Debounced)
    input  logic                 cancel_pulse, // 1-Cycle Pulse to Rollback Snapshot
    output logic [MIN_WIDTH-1:0] m_out,        // Minute Output (0..59)
    output logic                 min_rollover  // 1-Cycle Rollover Enable to Hour Counter
);

    // Mode encodings
    localparam logic [1:0] MODE_RUN     = 2'b00;
    localparam logic [1:0] MODE_ADJ_MIN = 2'b10;

    // Internal register and Snapshot Shadow register
    logic [MIN_WIDTH-1:0] r_min;
    logic [MIN_WIDTH-1:0] r_min_bak;

    //--------------------------------------------------------------------------
    // Minute Counter Sequential Logic (Posedge clk, Asynchronous rstn)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_min     <= '0;
            r_min_bak <= '0;
        end else begin
            // 1. Capture snapshot upon transitioning from RUN to Adjust Mode
            if ((adj_mode == MODE_RUN) && sel_pulse) begin
                r_min_bak <= r_min;
            end

            // 2. Rollback to snapshot if uncommitted timeout occurs
            if (cancel_pulse) begin
                r_min <= r_min_bak;
            end else begin
                case (adj_mode)
                    MODE_RUN: begin
                        if (sec_rollover) begin
                            if (r_min >= 6'd59) begin
                                r_min <= '0;
                            end else begin
                                r_min <= r_min + 1'b1;
                            end
                        end
                    end

                    MODE_ADJ_MIN: begin
                        if (up_pulse && !down_pulse) begin
                            // Increment with wrap-around: 59 -> 0
                            if (r_min >= 6'd59) begin
                                r_min <= '0;
                            end else begin
                                r_min <= r_min + 1'b1;
                            end
                        end else if (down_pulse && !up_pulse) begin
                            // Decrement with wrap-around: 0 -> 59
                            if (r_min == '0) begin
                                r_min <= 6'd59;
                            end else begin
                                r_min <= r_min - 1'b1;
                            end
                        end
                        // If both up_pulse and down_pulse are active, hold current value
                    end

                    default: begin
                        // Hold value in MODE_ADJ_SEC and MODE_ADJ_HOUR
                        r_min <= r_min;
                    end
                endcase
            end
        end
    end

    //--------------------------------------------------------------------------
    // Output Data & Rollover Enable Generation
    // min_rollover is only generated during MODE_RUN when r_min == 59 and sec_rollover occurs.
    // In any adjustment mode, min_rollover is strictly gated to 0.
    //--------------------------------------------------------------------------
    assign m_out        = r_min;
    assign min_rollover = (adj_mode == MODE_RUN) && (sec_rollover) && (r_min == 6'd59);

endmodule
