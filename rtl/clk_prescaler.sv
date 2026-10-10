//==============================================================================
// File: clk_prescaler.sv
// Module: clk_prescaler
// Description: Multi-Stage Cascaded Frequency Prescaler for PPA Optimization.
//              - Stage 1: Divides 1 MHz system clock down to 1 kHz sampling tick (tick_1khz).
//              - Stage 2: Enabled by tick_1khz, divides 1 kHz down to 1 Hz timebase (sec_tick).
//              - PPA Optimization:
//                * Reduces high-frequency (1 MHz) switching counter width from 20-bit to 10-bit.
//                * Stage 2 counter switches at 1 kHz (1000x toggle rate reduction).
//                * Debouncer modules sample on tick_1khz with small 5-bit counters.
//                * Shortens adder critical path for timing closure / higher Fmax.
//                * Pure synchronous single-clock domain design.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module clk_prescaler #(
    parameter int CLK_FREQ_HZ       = 1_000_000,                                                     // System Clock (1 MHz)
    parameter int TICK_1KHZ_FREQ_HZ = 1_000,                                                         // 1 kHz sampling rate
    parameter int TICK_1HZ_FREQ_HZ  = 1,                                                             // 1 Hz timebase rate
    parameter int DIV_1KHZ_MAX      = (CLK_FREQ_HZ >= TICK_1KHZ_FREQ_HZ) ? ((CLK_FREQ_HZ / TICK_1KHZ_FREQ_HZ) - 1) : 0,
    parameter int DIV_1HZ_MAX       = (TICK_1KHZ_FREQ_HZ >= TICK_1HZ_FREQ_HZ) ? ((TICK_1KHZ_FREQ_HZ / TICK_1HZ_FREQ_HZ) - 1) : 0,
    parameter int CNT_1KHZ_WIDTH    = (DIV_1KHZ_MAX > 0) ? $clog2(DIV_1KHZ_MAX + 1) : 1,
    parameter int CNT_1HZ_WIDTH     = (DIV_1HZ_MAX > 0) ? $clog2(DIV_1HZ_MAX + 1) : 1
)(
    input  logic clk,        // System Clock (1 MHz)
    input  logic rstn,       // Reset, Active-Low
    output logic tick_1khz,  // 1 kHz periodic tick (1-cycle pulse)
    output logic sec_tick    // 1 Hz periodic tick (1-cycle pulse)
);

    //--------------------------------------------------------------------------
    // Stage 1: Modulo-(DIV_1KHZ_MAX + 1) Counter (1 MHz -> 1 kHz)
    //--------------------------------------------------------------------------
    logic [CNT_1KHZ_WIDTH-1:0] r_cnt_1khz;
    logic                      w_tick_1khz;

    generate
        if (DIV_1KHZ_MAX == 0) begin : gen_div1_stage1
            always_ff @(posedge clk) begin
                r_cnt_1khz <= '0;
            end
            assign w_tick_1khz = 1'b1;
        end else begin : gen_cnt_stage1
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    r_cnt_1khz <= '0;
                end else begin
                    if (r_cnt_1khz >= DIV_1KHZ_MAX[CNT_1KHZ_WIDTH-1:0]) begin
                        r_cnt_1khz <= '0;
                    end else begin
                        r_cnt_1khz <= r_cnt_1khz + 1'b1;
                    end
                end
            end
            assign w_tick_1khz = (r_cnt_1khz == DIV_1KHZ_MAX[CNT_1KHZ_WIDTH-1:0]);
        end
    endgenerate

    assign tick_1khz = w_tick_1khz;

    //--------------------------------------------------------------------------
    // Stage 2: Modulo-(DIV_1HZ_MAX + 1) Counter (1 kHz -> 1 Hz, enabled by tick_1khz)
    //--------------------------------------------------------------------------
    logic [CNT_1HZ_WIDTH-1:0] r_cnt_1hz;
    logic                     w_sec_tick;

    generate
        if (DIV_1HZ_MAX == 0) begin : gen_div1_stage2
            always_ff @(posedge clk) begin
                r_cnt_1hz <= '0;
            end
            assign w_sec_tick = w_tick_1khz;
        end else begin : gen_cnt_stage2
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    r_cnt_1hz <= '0;
                end else begin
                    if (w_tick_1khz) begin
                        if (r_cnt_1hz >= DIV_1HZ_MAX[CNT_1HZ_WIDTH-1:0]) begin
                            r_cnt_1hz <= '0;
                        end else begin
                            r_cnt_1hz <= r_cnt_1hz + 1'b1;
                        end
                    end
                end
            end
            assign w_sec_tick = w_tick_1khz && (r_cnt_1hz == DIV_1HZ_MAX[CNT_1HZ_WIDTH-1:0]);
        end
    endgenerate

    assign sec_tick = w_sec_tick;

endmodule
