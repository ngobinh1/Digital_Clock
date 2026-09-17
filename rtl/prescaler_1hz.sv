//==============================================================================
// File: prescaler_1hz.sv
// Module: prescaler_1hz
// Description: Clock Frequency Prescaler dividing 1 MHz system clock to generate
//              a 1 Hz periodic pulse (sec_tick) with exactly 1 clock cycle width.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module prescaler_1hz #(
    parameter int CLK_FREQ_HZ   = 1_000_000,              // 1 MHz Default Clock
    parameter int PSC_COUNT_MAX = CLK_FREQ_HZ - 1,        // Modulo Counter Maximum
    parameter int PSC_WIDTH     = 20                      // $clog2(1_000_000) = 20
)(
    input  logic clk,       // System Clock (1 MHz)
    input  logic rstn,      // Asynchronous Reset, Active-Low
    output logic sec_tick   // 1 Hz Periodic Tick (1-cycle pulse)
);

    //--------------------------------------------------------------------------
    // Prescaler Internal Counter Register
    //--------------------------------------------------------------------------
    logic [PSC_WIDTH-1:0] r_count;

    //--------------------------------------------------------------------------
    // Modulo-CLK_FREQ_HZ Counter
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            r_count <= '0;
        end else begin
            if (r_count >= PSC_COUNT_MAX[PSC_WIDTH-1:0]) begin
                r_count <= '0;
            end else begin
                r_count <= r_count + 1'b1;
            end
        end
    end

    //--------------------------------------------------------------------------
    // 1-Cycle sec_tick Output Generation on Terminal Count
    //--------------------------------------------------------------------------
    assign sec_tick = (r_count == PSC_COUNT_MAX[PSC_WIDTH-1:0]);

endmodule
