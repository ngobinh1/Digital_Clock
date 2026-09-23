//==============================================================================
// File: hour_counter.sv
// Module: hour_counter
// Description: Modulo-24 Hour Counter (0..23) supporting:
//              - Real-time increment on min_rollover in MODE_RUN
//              - Bidirectional adjustment with wrap-around in MODE_ADJ_HOUR
//              - Daily rollover wrap-around (23 -> 0)
//              - Snapshot capture upon entering adjust mode
//              - Automatic rollback to snapshot upon cancel_pulse (Timeout 5s)
//              - Simultaneous button press conflict resolution (Hold)
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module hour_counter #(
    parameter int HOUR_WIDTH = 5
)(
    input  logic                  clk,          // System Clock (1 MHz)
    input  logic                  rstn,         // Asynchronous Reset, Active-Low
    input  logic [1:0]            adj_mode,     // Current Mode from mode_controller
    input  logic                  min_rollover, // 1-Cycle Rollover Enable from minute_counter
    input  logic                  sel_pulse,    // 1-Cycle Pulse from Select Button (Debounced)
    input  logic                  up_pulse,     // 1-Cycle Pulse from Up Button (Debounced)
    input  logic                  down_pulse,   // 1-Cycle Pulse from Down Button (Debounced)
    input  logic                  cancel_pulse, // 1-Cycle Pulse to Rollback Snapshot
    output logic [HOUR_WIDTH-1:0] h_out         // Hour Output (0..23)
);

    // Mode encodings
    localparam logic [1:0] MODE_RUN      = 2'b00;
    localparam logic [1:0] MODE_ADJ_HOUR = 2'b11;

    // Internal register and Snapshot Shadow register
    logic [HOUR_WIDTH-1:0] r_hour;
    logic [HOUR_WIDTH-1:0] r_hour_bak;

    //--------------------------------------------------------------------------
    // Hour Counter Sequential Logic (Posedge clk, Asynchronous rstn)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_hour     <= '0;
            r_hour_bak <= '0;
        end else begin
            // 1. Capture snapshot upon transitioning from RUN to Adjust Mode
            if ((adj_mode == MODE_RUN) && sel_pulse) begin
                r_hour_bak <= r_hour;
            end

            // 2. Rollback to snapshot if uncommitted timeout occurs
            if (cancel_pulse) begin
                r_hour <= r_hour_bak;
            end else begin
                case (adj_mode)
                    MODE_RUN: begin
                        if (min_rollover) begin
                            if (r_hour >= 5'd23) begin
                                r_hour <= '0;
                            end else begin
                                r_hour <= r_hour + 1'b1;
                            end
                        end
                    end

                    MODE_ADJ_HOUR: begin
                        if (up_pulse && !down_pulse) begin
                            // Increment with wrap-around: 23 -> 0
                            if (r_hour >= 5'd23) begin
                                r_hour <= '0;
                            end else begin
                                r_hour <= r_hour + 1'b1;
                            end
                        end else if (down_pulse && !up_pulse) begin
                            // Decrement with wrap-around: 0 -> 23
                            if (r_hour == '0) begin
                                r_hour <= 5'd23;
                            end else begin
                                r_hour <= r_hour - 1'b1;
                            end
                        end
                        // If both up_pulse and down_pulse are active, hold current value
                    end

                    default: begin
                        // Hold value in MODE_ADJ_SEC and MODE_ADJ_MIN
                        r_hour <= r_hour;
                    end
                endcase
            end
        end
    end

    //--------------------------------------------------------------------------
    // Output Data Assignment
    //--------------------------------------------------------------------------
    assign h_out = r_hour;

endmodule
