//==============================================================================
// File: second_counter.sv
// Module: second_counter
// Description: Modulo-60 Second Counter (0..59) supporting:
//              - Real-time increment on sec_tick in MODE_RUN
//              - Bidirectional adjustment with wrap-around in MODE_ADJ_SEC
//              - Synchronous rollover flag generation (sec_rollover)
//              - Snapshot capture upon entering adjust mode
//              - Automatic rollback to snapshot upon cancel_pulse (Timeout 5s)
//              - Simultaneous button press conflict resolution (Hold)
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module second_counter #(
    parameter int SEC_WIDTH = 6
)(
    input  logic                 clk,          // System Clock (1 MHz)
    input  logic                 rstn,         // Asynchronous Reset, Active-Low
    input  logic [1:0]           adj_mode,     // Current Mode from mode_controller
    input  logic                 sec_tick,     // 1-Cycle Pulse from Prescaler (1 Hz)
    input  logic                 sel_pulse,    // 1-Cycle Pulse from Select Button (Debounced)
    input  logic                 up_pulse,     // 1-Cycle Pulse from Up Button (Debounced)
    input  logic                 down_pulse,   // 1-Cycle Pulse from Down Button (Debounced)
    input  logic                 cancel_pulse, // 1-Cycle Pulse to Rollback Snapshot
    output logic [SEC_WIDTH-1:0] s_out,        // Second Output (0..59)
    output logic                 sec_rollover  // 1-Cycle Rollover Enable to Minute Counter
);

    // Mode encodings
    localparam logic [1:0] MODE_RUN     = 2'b00;
    localparam logic [1:0] MODE_ADJ_SEC = 2'b01;

    // Internal register and Snapshot Shadow register
    logic [SEC_WIDTH-1:0] r_sec;
    logic [SEC_WIDTH-1:0] r_sec_bak;

    //--------------------------------------------------------------------------
    // Second Counter Sequential Logic (Posedge clk, Asynchronous rstn)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_sec     <= '0;
            r_sec_bak <= '0;
        end else begin
            // 1. Capture snapshot upon transitioning from RUN to Adjust Mode
            if ((adj_mode == MODE_RUN) && sel_pulse) begin
                r_sec_bak <= r_sec;
            end

            // 2. Rollback to snapshot if uncommitted timeout occurs
            if (cancel_pulse) begin
                r_sec <= r_sec_bak;
            end else begin
                case (adj_mode)
                    MODE_RUN: begin
                        if (sec_tick) begin
                            if (r_sec >= 6'd59) begin
                                r_sec <= '0;
                            end else begin
                                r_sec <= r_sec + 1'b1;
                            end
                        end
                    end

                    MODE_ADJ_SEC: begin
                        if (up_pulse && !down_pulse) begin
                            // Increment with wrap-around: 59 -> 0
                            if (r_sec >= 6'd59) begin
                                r_sec <= '0;
                            end else begin
                                r_sec <= r_sec + 1'b1;
                            end
                        end else if (down_pulse && !up_pulse) begin
                            // Decrement with wrap-around: 0 -> 59
                            if (r_sec == '0) begin
                                r_sec <= 6'd59;
                            end else begin
                                r_sec <= r_sec - 1'b1;
                            end
                        end
                        // If both up_pulse and down_pulse are active, hold current value
                    end

                    default: begin
                        // Hold value in MODE_ADJ_MIN and MODE_ADJ_HOUR
                        r_sec <= r_sec;
                    end
                endcase
            end
        end
    end

    //--------------------------------------------------------------------------
    // Output Data & Rollover Enable Generation
    // sec_rollover is only generated during MODE_RUN when r_sec == 59 and sec_tick occurs.
    // In any adjustment mode, sec_rollover is strictly gated to 0.
    //--------------------------------------------------------------------------
    assign s_out        = r_sec;
    assign sec_rollover = (adj_mode == MODE_RUN) && (sec_tick) && (r_sec == 6'd59);

endmodule
