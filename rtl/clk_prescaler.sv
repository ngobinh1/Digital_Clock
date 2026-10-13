//==============================================================================
// File: clk_prescaler.sv
// Module: clk_prescaler
// Description: Multi-Stage Cascaded Frequency Prescaler for PPA Optimization.
//              - Stage 1: Divides 1 MHz system clock down to 1 kHz sampling pulse (pulse_1khz).
//              - Stage 2: Enabled by pulse_1khz, divides 1 kHz down to 1 Hz timebase (sec_pulse).
//              - PPA Optimization:
//                * Reduces high-frequency (1 MHz) switching counter width from 20-bit to 10-bit.
//                * Stage 2 counter switches at 1 kHz (1000x toggle rate reduction).
//                * Debouncer modules sample on pulse_1khz with small 5-bit counters.
//                * Shortens adder critical path for timing closure / higher Fmax.
//                * Pure synchronous single-clock domain design.
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module clk_prescaler #(
    parameter int P_CLK_FREQ_HZ       = 1_000_000,                                                     // System Clock (1 MHz)
    parameter int P_PULSE_1KHZ_FREQ_HZ = 1_000,                                                         // 1 kHz sampling rate
    parameter int P_PULSE_1HZ_FREQ_HZ  = 1,                                                             // 1 Hz timebase rate
    parameter int P_DIV_1KHZ_MAX      = (P_CLK_FREQ_HZ >= P_PULSE_1KHZ_FREQ_HZ) ? ((P_CLK_FREQ_HZ / P_PULSE_1KHZ_FREQ_HZ) - 1) : 0,
    parameter int P_DIV_1HZ_MAX       = (P_PULSE_1KHZ_FREQ_HZ >= P_PULSE_1HZ_FREQ_HZ) ? ((P_PULSE_1KHZ_FREQ_HZ / P_PULSE_1HZ_FREQ_HZ) - 1) : 0,
    parameter int P_CNT_1KHZ_WIDTH    = (P_DIV_1KHZ_MAX > 0) ? $clog2(P_DIV_1KHZ_MAX + 1) : 1,
    parameter int P_CNT_1HZ_WIDTH     = (P_DIV_1HZ_MAX > 0) ? $clog2(P_DIV_1HZ_MAX + 1) : 1
)(
    input  logic clk,        // System Clock (1 MHz)
    input  logic rstn,       // Reset, Active-Low
    output logic pulse_1khz, // 1 kHz periodic pulse (1-cycle enable)
    output logic sec_pulse   // 1 Hz periodic pulse (1-cycle enable)
);

    //--------------------------------------------------------------------------
    // Stage 1: Modulo-(P_DIV_1KHZ_MAX + 1) Counter (1 MHz -> 1 kHz)
    //--------------------------------------------------------------------------
    logic [P_CNT_1KHZ_WIDTH-1:0] r_cnt_1khz;
    logic                        w_pulse_1khz;

    generate
        if (P_DIV_1KHZ_MAX == 0) begin : gen_div1_stage1
            always_ff @(posedge clk) begin
                r_cnt_1khz <= '0;
            end
            assign w_pulse_1khz = 1'b1;
        end else begin : gen_cnt_stage1
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    r_cnt_1khz <= '0;
                end else begin
                    if (r_cnt_1khz >= P_DIV_1KHZ_MAX[P_CNT_1KHZ_WIDTH-1:0]) begin
                        r_cnt_1khz <= '0;
                    end else begin
                        r_cnt_1khz <= r_cnt_1khz + 1'b1;
                    end
                end
            end
            assign w_pulse_1khz = (r_cnt_1khz == P_DIV_1KHZ_MAX[P_CNT_1KHZ_WIDTH-1:0]);
        end
    endgenerate

    assign pulse_1khz = w_pulse_1khz;

    //--------------------------------------------------------------------------
    // Stage 2: Modulo-(P_DIV_1HZ_MAX + 1) Counter (1 kHz -> 1 Hz, enabled by pulse_1khz)
    //--------------------------------------------------------------------------
    logic [P_CNT_1HZ_WIDTH-1:0] r_cnt_1hz;
    logic                       w_sec_pulse;

    generate
        if (P_DIV_1HZ_MAX == 0) begin : gen_div1_stage2
            always_ff @(posedge clk) begin
                r_cnt_1hz <= '0;
            end
            assign w_sec_pulse = w_pulse_1khz;
        end else begin : gen_cnt_stage2
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    r_cnt_1hz <= '0;
                end else begin
                    if (w_pulse_1khz) begin
                        if (r_cnt_1hz >= P_DIV_1HZ_MAX[P_CNT_1HZ_WIDTH-1:0]) begin
                            r_cnt_1hz <= '0;
                        end else begin
                            r_cnt_1hz <= r_cnt_1hz + 1'b1;
                        end
                    end
                end
            end
            assign w_sec_pulse = w_pulse_1khz && (r_cnt_1hz == P_DIV_1HZ_MAX[P_CNT_1HZ_WIDTH-1:0]);
        end
    endgenerate

    assign sec_pulse = w_sec_pulse;

endmodule
