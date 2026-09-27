//==============================================================================
// File: mode_controller.sv
// Module: mode_controller
// Description: Finite State Machine (FSM) for Mode Control with:
//              - 4 Operating Modes: MODE_RUN (00), MODE_ADJ_SEC (01),
//                MODE_ADJ_MIN (10), MODE_ADJ_HOUR (11)
//              - Dedicated Edit Buffer Registers (r_adj_sec, r_adj_min, r_adj_hour)
//              - Snapshot capture from real-time counters upon entering adjust mode
//              - Inactivity Timeout (5s without button activity): Auto-exit to MODE_RUN
//                without asserting load_en (discarding uncommitted edits)
//              - Commit on Exit: Asserting 1-cycle load_en pulse when completing
//                the adjustment loop (HOUR -> RUN via sel_pulse)
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module mode_controller #(
    parameter int TIMEOUT_SEC = 5,
    parameter int SEC_WIDTH   = 6,
    parameter int MIN_WIDTH   = 6,
    parameter int HOUR_WIDTH  = 5
)(
    input  logic                  clk,          // System Clock (gated_clk_fsm)
    input  logic                  rstn,         // Asynchronous Reset, Active-Low
    input  logic                  sel_pulse,    // 1-Cycle Pulse from Select Button (Debounced)
    input  logic                  up_pulse,     // 1-Cycle Pulse from Up Button (Debounced)
    input  logic                  down_pulse,   // 1-Cycle Pulse from Down Button (Debounced)
    input  logic                  sec_tick,     // 1-Cycle Pulse from Prescaler (1 Hz)
    input  logic [SEC_WIDTH-1:0]  s_cur,        // Current Real-Time Second from Counter
    input  logic [MIN_WIDTH-1:0]  m_cur,        // Current Real-Time Minute from Counter
    input  logic [HOUR_WIDTH-1:0] h_cur,        // Current Real-Time Hour from Counter
    output logic [1:0]            adj_mode,     // Current Operating Mode State Output
    output logic [SEC_WIDTH-1:0]  adj_sec,      // Adjusted Second Edit Buffer Output
    output logic [MIN_WIDTH-1:0]  adj_min,      // Adjusted Minute Edit Buffer Output
    output logic [HOUR_WIDTH-1:0] adj_hour,     // Adjusted Hour Edit Buffer Output
    output logic                  load_en       // 1-Cycle Pulse to Synchronously Load Counters
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

    // Time edit scratchpad registers
    logic [SEC_WIDTH-1:0]  r_adj_sec;
    logic [MIN_WIDTH-1:0]  r_adj_min;
    logic [HOUR_WIDTH-1:0] r_adj_hour;
    logic                  r_load_en;

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
            r_load_en    <= 1'b0;
            r_adj_sec    <= '0;
            r_adj_min    <= '0;
            r_adj_hour   <= '0;
        end else begin
            r_load_en <= 1'b0; // Default inactive 1-cycle pulse

            case (state_reg)
                MODE_RUN: begin
                    timeout_cnt <= '0;
                    if (sel_pulse) begin
                        state_reg  <= MODE_ADJ_SEC;
                        r_adj_sec  <= s_cur;
                        r_adj_min  <= m_cur;
                        r_adj_hour <= h_cur;
                    end
                end

                MODE_ADJ_SEC: begin
                    if (any_button) begin
                        timeout_cnt <= '0; // Reset inactivity timer on user action
                        if (sel_pulse) begin
                            state_reg <= MODE_ADJ_MIN;
                        end else begin
                            if (up_pulse && !down_pulse) begin
                                if (r_adj_sec >= 6'd59) begin
                                    r_adj_sec <= '0;
                                end else begin
                                    r_adj_sec <= r_adj_sec + 1'b1;
                                end
                            end else if (down_pulse && !up_pulse) begin
                                if (r_adj_sec == '0) begin
                                    r_adj_sec <= 6'd59;
                                end else begin
                                    r_adj_sec <= r_adj_sec - 1'b1;
                                end
                            end
                            // If both up_pulse and down_pulse are active, hold value
                        end
                    end else if (sec_tick) begin
                        if (timeout_cnt >= (TIMEOUT_SEC - 1)) begin
                            // 5s Inactivity reached: Auto-exit & Cancel uncommitted edits
                            state_reg   <= MODE_RUN;
                            timeout_cnt <= '0;
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
                        end else begin
                            if (up_pulse && !down_pulse) begin
                                if (r_adj_min >= 6'd59) begin
                                    r_adj_min <= '0;
                                end else begin
                                    r_adj_min <= r_adj_min + 1'b1;
                                end
                            end else if (down_pulse && !up_pulse) begin
                                if (r_adj_min == '0) begin
                                    r_adj_min <= 6'd59;
                                end else begin
                                    r_adj_min <= r_adj_min - 1'b1;
                                end
                            end
                            // If both up_pulse and down_pulse are active, hold value
                        end
                    end else if (sec_tick) begin
                        if (timeout_cnt >= (TIMEOUT_SEC - 1)) begin
                            // 5s Inactivity reached: Auto-exit & Cancel uncommitted edits
                            state_reg   <= MODE_RUN;
                            timeout_cnt <= '0;
                        end else begin
                            timeout_cnt <= timeout_cnt + 1'b1;
                        end
                    end
                end

                MODE_ADJ_HOUR: begin
                    if (any_button) begin
                        timeout_cnt <= '0; // Reset inactivity timer on user action
                        if (sel_pulse) begin
                            // User committed changes by completing adjustment loop
                            state_reg   <= MODE_RUN;
                            r_load_en   <= 1'b1; // Trigger parallel load to counters
                            timeout_cnt <= '0;
                        end else begin
                            if (up_pulse && !down_pulse) begin
                                if (r_adj_hour >= 5'd23) begin
                                    r_adj_hour <= '0;
                                end else begin
                                    r_adj_hour <= r_adj_hour + 1'b1;
                                end
                            end else if (down_pulse && !up_pulse) begin
                                if (r_adj_hour == '0) begin
                                    r_adj_hour <= 5'd23;
                                end else begin
                                    r_adj_hour <= r_adj_hour - 1'b1;
                                end
                            end
                            // If both up_pulse and down_pulse are active, hold value
                        end
                    end else if (sec_tick) begin
                        if (timeout_cnt >= (TIMEOUT_SEC - 1)) begin
                            // 5s Inactivity reached: Auto-exit & Cancel uncommitted edits
                            state_reg   <= MODE_RUN;
                            timeout_cnt <= '0;
                        end else begin
                            timeout_cnt <= timeout_cnt + 1'b1;
                        end
                    end
                end

                default: begin
                    state_reg   <= MODE_RUN;
                    timeout_cnt <= '0;
                end
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Output Port Assignments
    //--------------------------------------------------------------------------
    assign adj_mode = state_reg;
    assign adj_sec  = r_adj_sec;
    assign adj_min  = r_adj_min;
    assign adj_hour = r_adj_hour;
    assign load_en  = r_load_en;

endmodule
