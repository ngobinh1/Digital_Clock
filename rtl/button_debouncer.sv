//==============================================================================
// File: button_debouncer.sv
// Module: button_debouncer (Universal Synchronous Architecture with ±10% Tolerance)
// Description: Pure Synchronous 20ms Debounce & Auto-Repeat IP Core with ±10% Tolerance.
//              - Single-Clock Domain: Runs 100% on master clock (clk) with clk_en.
//              - 2-Stage D-FF Synchronizer: Samples asynchronous button at 1 kHz (clk_en)
//                to eliminate contact bounce and metastability.
//              - ±10% Tolerance Parameterization: Calculates effective threshold:
//                PL_EFFECTIVE_PULSES = P_DEBOUNCE_PULSES - (P_DEBOUNCE_PULSES * P_DEBOUNCE_TOL_PCT / 100)
//                Default: 20 pulses - 10% = 18 pulses (18 ms at 1 kHz).
//              - Glitch Rejection: Presses < 18ms are strictly ignored.
//              - Auto-Repeat: Emits 1-cycle master clock pulse (btn_event) every 18ms
//                when button is held continuously.
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module button_debouncer #(
    parameter int P_DEBOUNCE_PULSES   = 20,                                                      // Nominal cycles of 1 kHz = 20 ms
    parameter int P_DEBOUNCE_TOL_PCT  = 10,                                                      // Tolerance percentage (±10%)
    localparam int PL_DEBOUNCE_MIN_PULSES = (P_DEBOUNCE_PULSES > 0) ?                            // Lower threshold (18 pulses)
        (P_DEBOUNCE_PULSES - (P_DEBOUNCE_PULSES * P_DEBOUNCE_TOL_PCT / 100)) : 1,
    localparam int PL_EFFECTIVE_PULSES = (PL_DEBOUNCE_MIN_PULSES > 0) ? PL_DEBOUNCE_MIN_PULSES : 1, // 18 pulses = 18 ms
    localparam int PL_CNT_WIDTH       = (PL_EFFECTIVE_PULSES > 1) ? $clog2(PL_EFFECTIVE_PULSES) : 1  // 5 bits for 18 pulses
)(
    input  logic clk,        // System Master Clock (1 MHz)
    input  logic rstn,       // Reset, Active-Low
    input  logic clk_en,     // Clock Enable (pulse_1khz from prescaler)
    input  logic btn_in,     // Asynchronous Button Input (Active-High)
    output logic btn_event   // Synchronous 1-Cycle Pulse Event Output
);

    // 2-Stage D-FF Synchronizer sampled at 1 kHz
    logic [1:0] sync_reg;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            sync_reg <= 2'b00;
        end else if (clk_en) begin
            sync_reg <= {sync_reg[0], btn_in};
        end
    end

    logic btn_sync;
    assign btn_sync = sync_reg[1];

    generate
        if (PL_EFFECTIVE_PULSES <= 1) begin : gen_passthrough
            logic btn_d;
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    btn_d     <= 1'b0;
                    btn_event <= 1'b0;
                end else if (clk_en) begin
                    btn_d     <= btn_sync;
                    btn_event <= btn_sync & ~btn_d;
                end else begin
                    btn_event <= 1'b0;
                end
            end
        end else begin : gen_debouncer
            logic [PL_CNT_WIDTH-1:0] timer_cnt;

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    timer_cnt <= '0;
                    btn_event <= 1'b0;
                end else if (clk_en) begin
                    if (btn_sync) begin
                        if (timer_cnt >= (PL_EFFECTIVE_PULSES - 1)) begin
                            btn_event <= 1'b1; // Emit 1-cycle master clock event pulse
                            timer_cnt <= '0;   // Reset counter for auto-repeat
                        end else begin
                            btn_event <= 1'b0;
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end else begin
                        timer_cnt <= '0;
                        btn_event <= 1'b0;
                    end
                end else begin
                    btn_event <= 1'b0; // Auto-clear after 1 master clock cycle
                end
            end
        end
    endgenerate

endmodule
