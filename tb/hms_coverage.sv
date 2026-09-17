//==============================================================================
// File: hms_coverage.sv
// Class: hms_coverage
// Description: Functional Coverage model for HMS_Timer IP Core verification.
//              Measures coverage for FSM States, Transitions, Time Ranges,
//              Rollovers, and Button Stimulus combinations.
// Author: Antigravity - RTL Questa Expert
// Project: HMS_Timer
// Language: SystemVerilog
//==============================================================================

`ifndef HMS_COVERAGE_SV
`define HMS_COVERAGE_SV

class hms_coverage;
    virtual hms_timer_if vif;

    // Covergroup 1: FSM Operating Modes & Transitions
    covergroup cg_fsm_modes @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_fsm_modes";

        cp_mode: coverpoint vif.adj_mode {
            bins mode_run      = {MODE_RUN};
            bins mode_adj_sec  = {MODE_ADJ_SEC};
            bins mode_adj_min  = {MODE_ADJ_MIN};
            bins mode_adj_hour = {MODE_ADJ_HOUR};
        }

        cp_mode_transitions: coverpoint vif.adj_mode {
            bins cycle_run_to_sec   = (MODE_RUN => MODE_ADJ_SEC);
            bins cycle_sec_to_min   = (MODE_ADJ_SEC => MODE_ADJ_MIN);
            bins cycle_min_to_hour  = (MODE_ADJ_MIN => MODE_ADJ_HOUR);
            bins cycle_hour_to_run  = (MODE_ADJ_HOUR => MODE_RUN);
        }
    endgroup

    // Covergroup 2: Time Output Ranges & Boundary Conditions
    covergroup cg_time_values @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_time_values";

        cp_seconds: coverpoint vif.s_out {
            bins zero        = {0};
            bins mid_range   = {[1:58]};
            bins max_val     = {59};
            bins wrap_up     = (59 => 0);
            bins wrap_down   = (0 => 59);
        }

        cp_minutes: coverpoint vif.m_out {
            bins zero        = {0};
            bins mid_range   = {[1:58]};
            bins max_val     = {59};
            bins wrap_up     = (59 => 0);
            bins wrap_down   = (0 => 59);
        }

        cp_hours: coverpoint vif.h_out {
            bins zero        = {0};
            bins mid_range   = {[1:22]};
            bins max_val     = {23};
            bins wrap_up     = (23 => 0);
            bins wrap_down   = (0 => 23);
        }
    endgroup

    // Covergroup 3: Button Stimulus & Rollover Cross Coverage
    covergroup cg_stimulus_cross @(posedge vif.clk);
        option.per_instance = 1;
        option.name = "cg_stimulus_cross";

        cp_mode: coverpoint vif.adj_mode {
            bins run  = {MODE_RUN};
            bins a_s  = {MODE_ADJ_SEC};
            bins a_m  = {MODE_ADJ_MIN};
            bins a_h  = {MODE_ADJ_HOUR};
        }

        cp_up: coverpoint vif.up_pulse {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_down: coverpoint vif.down_pulse {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_sec_roll: coverpoint vif.sec_rollover {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_min_roll: coverpoint vif.min_rollover {
            bins inactive = {0};
            bins active   = {1};
        }

        // Cross: Button actions across all modes
        cross_btn_mode: cross cp_mode, cp_up, cp_down;

        // Cross: Rollovers in RUN mode
        cross_rollover_run: cross cp_mode, cp_sec_roll, cp_min_roll;
    endgroup

    function new(virtual hms_timer_if vif);
        this.vif = vif;
        cg_fsm_modes       = new();
        cg_time_values     = new();
        cg_stimulus_cross  = new();
    endfunction

    function void report_coverage();
        $display("--------------------------------------------------------------------------------");
        $display("                      FUNCTIONAL COVERAGE REPORT                                ");
        $display("--------------------------------------------------------------------------------");
        $display(" FSM Modes & Transitions Coverage : %0.2f %%", cg_fsm_modes.get_inst_coverage());
        $display(" Time Ranges & Boundary Coverage  : %0.2f %%", cg_time_values.get_inst_coverage());
        $display(" Stimulus & Cross Coverage        : %0.2f %%", cg_stimulus_cross.get_inst_coverage());
        $display("--------------------------------------------------------------------------------");
    endfunction

endclass

`endif // HMS_COVERAGE_SV
