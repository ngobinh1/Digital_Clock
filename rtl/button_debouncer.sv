//==============================================================================
// File: button_debouncer.sv
// Module: button_debouncer
// Description: 2-stage Flip-Flop Synchronizer and 20ms Debounce Counter with
//              Auto-Repeat mechanism for asynchronous push button input.
//              - Triệt tiêu hoàn toàn hiện tượng metastability qua 2-FF.
//              - Yêu cầu giữ nút liên tục 20ms mới tính là 1 lần ấn (phát xung 1-cycle).
//              - Sau khi phát xung, tự động tính lại 20ms từ đầu (hỗ trợ auto-repeat).
//              - Reset bộ đếm về 0 ngay lập tức nếu nhả phím trước 20ms (lọc nhiễu / glitch).
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
// Language: SystemVerilog (IEEE 1800 Synthesizable)
//==============================================================================

`timescale 1ns / 1ps

module button_debouncer #(
    parameter int CLK_FREQ_HZ      = 1_000_000,                                                  // 1 MHz default
    parameter int DEBOUNCE_TIME_MS = 20,                                                         // 20 ms hold requirement
    parameter int DEBOUNCE_CYCLES  = (longint'(CLK_FREQ_HZ) * DEBOUNCE_TIME_MS) / 1000,         // Cycles to count (e.g. 20,000)
    parameter int CNT_WIDTH        = (DEBOUNCE_CYCLES > 1) ? $clog2(DEBOUNCE_CYCLES) : 1
)(
    input  logic clk,        // System Clock (1 MHz)
    input  logic rstn,       // Asynchronous Reset, Active-Low
    input  logic btn_in,     // Asynchronous Button Input (Active-High)
    output logic btn_pulse   // 1-Clock Cycle Pulse when held for 20ms
);

    //--------------------------------------------------------------------------
    // 2-Stage Synchronizer to prevent metastability
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
    // Debounce Counter & Auto-Repeat Logic
    //--------------------------------------------------------------------------
    logic [CNT_WIDTH-1:0] timer_cnt;

    generate
        if (DEBOUNCE_CYCLES <= 1) begin : gen_passthrough
            // For simulation or bypass mode where DEBOUNCE_CYCLES <= 1
            logic btn_d;
            always_ff @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    btn_d     <= 1'b0;
                    btn_pulse <= 1'b0;
                end else begin
                    btn_d     <= btn_sync;
                    btn_pulse <= btn_sync & ~btn_d;
                end
            end
        end else begin : gen_debouncer
            always_ff @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    timer_cnt <= '0;
                    btn_pulse <= 1'b0;
                end else begin
                    btn_pulse <= 1'b0; // Default pulse is inactive

                    if (btn_sync) begin
                        if (timer_cnt >= (DEBOUNCE_CYCLES - 1)) begin
                            btn_pulse <= 1'b1; // Emit 1-clock-cycle pulse
                            timer_cnt <= '0;   // Reset counter to count next 20ms from scratch (Auto-repeat)
                        end else begin
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end else begin
                        timer_cnt <= '0; // Clear counter immediately on key release or contact bounce
                    end
                end
            end
        end
    endgenerate

endmodule
