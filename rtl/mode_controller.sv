//==============================================================================
// File: mode_controller.sv
// Module: mode_controller
// Description: Finite State Machine (FSM) for Mode Control with 5s Inactivity Timeout:
//              - 2'b00 (MODE_RUN): Normal Real-Time Counting
//              - 2'b01 (MODE_ADJ_SEC): Second Adjustment Mode
//              - 2'b10 (MODE_ADJ_MIN): Minute Adjustment Mode
//              - 2'b11 (MODE_ADJ_HOUR): Hour Adjustment Mode
//              - Inactivity Timeout: Khi ở các mode chỉnh sửa, nếu sau 5 giây liên tục
//                (dựa trên sec_tick) không có thao tác phím nào (sel/up/down), FSM
//                tự động nhảy về MODE_RUN và phát xung cancel_pulse để hủy thay đổi.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module mode_controller #(
    parameter int TIMEOUT_SEC = 5 // Inactivity timeout in seconds (Default 5s)
)(
    input  logic       clk,           // System Clock (1 MHz)
    input  logic       rstn,          // Asynchronous Reset, Active-Low
    input  logic       sel_pulse,     // 1-Cycle Pulse from Select Button (Debounced)
    input  logic       up_pulse,      // 1-Cycle Pulse from Up Button (Debounced)
    input  logic       down_pulse,    // 1-Cycle Pulse from Down Button (Debounced)
    input  logic       sec_tick,      // 1-Cycle Pulse from Prescaler (1 Hz)
    output logic [1:0] adj_mode,      // Current Operating Mode State Output
    output logic       cancel_pulse   // 1-Cycle Pulse indicating 5s Timeout Rollback
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

    state_t state_reg;

    // Width of timeout counter
    localparam int TIMEOUT_CNT_WIDTH = (TIMEOUT_SEC > 1) ? $clog2(TIMEOUT_SEC + 1) : 1;
    logic [TIMEOUT_CNT_WIDTH-1:0] timeout_cnt;

    // Detect any button activity
    logic any_button;
    assign any_button = sel_pulse | up_pulse | down_pulse;

    //--------------------------------------------------------------------------
    // FSM & Inactivity Timeout Sequential Logic (Posedge clk, Asynchronous rstn)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state_reg    <= MODE_RUN;
            timeout_cnt  <= '0;
            cancel_pulse <= 1'b0;
        end else begin
            cancel_pulse <= 1'b0; // Default inactive

            case (state_reg)
                MODE_RUN: begin
                    timeout_cnt <= '0;
                    if (sel_pulse) begin
                        state_reg <= MODE_ADJ_SEC;
                    end
                end

                MODE_ADJ_SEC: begin
                    if (any_button) begin
                        timeout_cnt <= '0; // Reset inactivity timer on user action
                        if (sel_pulse) begin
                            state_reg <= MODE_ADJ_MIN;
                        end
                    end else if (sec_tick) begin
                        if (timeout_cnt >= (TIMEOUT_SEC - 1)) begin
                            // 5s Inactivity reached: Auto-exit & Cancel uncommitted edits
                            state_reg    <= MODE_RUN;
                            cancel_pulse <= 1'b1;
                            timeout_cnt  <= '0;
                        end else begin
                            timeout_cnt <= timeout_cnt + 1'b1;
                        end
                    end
                end

                MODE_ADJ_MIN: begin
                    if (any_button) begin
                        timeout_cnt <= '0; // Reset inactivity timer on user action
                        if (sel_pulse) begin
                            state_reg <= MODE_ADJ_HOUR;
                        end
                    end else if (sec_tick) begin
                        if (timeout_cnt >= (TIMEOUT_SEC - 1)) begin
                            // 5s Inactivity reached: Auto-exit & Cancel uncommitted edits
                            state_reg    <= MODE_RUN;
                            cancel_pulse <= 1'b1;
                            timeout_cnt  <= '0;
                        end else begin
                            timeout_cnt <= timeout_cnt + 1'b1;
                        end
                    end
                end

                MODE_ADJ_HOUR: begin
                    if (any_button) begin
                        timeout_cnt <= '0; // Reset inactivity timer on user action
                        if (sel_pulse) begin
                            state_reg <= MODE_RUN; // User explicitly confirms/commits changes
                        end
                    end else if (sec_tick) begin
                        if (timeout_cnt >= (TIMEOUT_SEC - 1)) begin
                            // 5s Inactivity reached: Auto-exit & Cancel uncommitted edits
                            state_reg    <= MODE_RUN;
                            cancel_pulse <= 1'b1;
                            timeout_cnt  <= '0;
                        end else begin
                            timeout_cnt <= timeout_cnt + 1'b1;
                        end
                    end
                end

                default: begin
                    state_reg    <= MODE_RUN;
                    timeout_cnt  <= '0;
                    cancel_pulse <= 1'b0;
                end
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Output Assignment
    //--------------------------------------------------------------------------
    assign adj_mode = state_reg;

endmodule
