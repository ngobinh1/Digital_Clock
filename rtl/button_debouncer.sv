//==============================================================================
// File: button_debouncer.sv
// Module: button_debouncer (Pure 1 kHz Single-Clock Architecture with ±10% Tolerance)
// Description: Pure 1 kHz Clock-Driven 20ms Debounce & Auto-Repeat IP Core with ±10% Tolerance.
//              - Single-Clock Domain: Runs 100% on the 1 kHz clock (clk).
//                No 1 MHz master clock is routed into this module.
//              - 2-Stage D-FF Synchronizer: Samples asynchronous button at 1 kHz
//                to eliminate contact bounce and metastability.
//              - ±10% Tolerance Parameterization: Calculates effective threshold:
//                EFFECTIVE_TICKS = DEBOUNCE_TICKS - (DEBOUNCE_TICKS * DEBOUNCE_TOL_PCT / 100)
//                Default: 20 ticks - 10% = 18 ticks (18 ms at 1 kHz).
//              - Glitch Rejection: Presses < 18ms are strictly ignored.
//              - Auto-Repeat: Emits 1-cycle-of-1kHz pulse (btn_event) every 18ms
//                when button is held continuously.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module button_debouncer #(
    parameter int DEBOUNCE_TICKS   = 20,                                                      // Nominal cycles of 1 kHz = 20 ms
    parameter int DEBOUNCE_TOL_PCT = 10,                                                      // Tolerance percentage (±10%)
    localparam int DEBOUNCE_MIN_TICKS = (DEBOUNCE_TICKS > 0) ?                                // Lower threshold (18 ticks)
        (DEBOUNCE_TICKS - (DEBOUNCE_TICKS * DEBOUNCE_TOL_PCT / 100)) : 1,
    localparam int EFFECTIVE_TICKS = (DEBOUNCE_MIN_TICKS > 0) ? DEBOUNCE_MIN_TICKS : 1,      // 18 ticks = 18 ms
    localparam int CNT_WIDTH       = (EFFECTIVE_TICKS > 1) ? $clog2(EFFECTIVE_TICKS) : 1      // 5 bits for 18 ticks
)(
    input  logic clk,        // 1 kHz Low-Frequency Clock (gated_clk_1khz)
    input  logic rstn,       // Asynchronous Reset, Active-Low
    input  logic btn_in,     // Asynchronous Button Input (Active-High)
    output logic btn_event   // 1-Cycle Pulse on 1 kHz clock domain (Active for 1ms)
);

    //--------------------------------------------------------------------------
    // 2-Stage Synchronizer at 1 kHz sampling rate
    //--------------------------------------------------------------------------
    logic [1:0] sync_reg;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_reg <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], btn_in};
        end
    end

    logic btn_sync;
    assign btn_sync = sync_reg[1];

    //--------------------------------------------------------------------------
    // 5-bit Debounce Counter & Auto-Repeat Logic (100% 1 kHz Clocked)
    //--------------------------------------------------------------------------
    generate
        if (EFFECTIVE_TICKS <= 1) begin : gen_passthrough
            // Edge detector / passthrough mode for 1-cycle debounce
            logic btn_d;
            always_ff @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    btn_d     <= 1'b0;
                    btn_event <= 1'b0;
                end else begin
                    btn_d     <= btn_sync;
                    btn_event <= btn_sync & ~btn_d;
                end
            end
        end else begin : gen_debouncer
            logic [CNT_WIDTH-1:0] timer_cnt;

            always_ff @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    timer_cnt <= '0;
                    btn_event <= 1'b0;
                end else begin
                    if (btn_sync) begin
                        if (timer_cnt >= (EFFECTIVE_TICKS - 1)) begin
                            btn_event <= 1'b1; // Emit 1-cycle-of-1kHz event pulse
                            timer_cnt <= '0;   // Reset counter for auto-repeat
                        end else begin
                            btn_event <= 1'b0;
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end else begin
                        timer_cnt <= '0;
                        btn_event <= 1'b0;
                    end
                end
            end
        end
    endgenerate

endmodule
