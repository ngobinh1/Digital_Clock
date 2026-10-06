# Design Intent & Architectural Decisions (v2.3.0 Output Switch & Zero-Drift Clock)

## 1. Objective & Scope
The `HMS_Timer` IP Core is designed to provide an accurate, robust, power/area-optimized, and synthesizable digital time-keeping solution for ASIC/FPGA designs operating on a synchronous 1 MHz clock domain with Integrated Clock Gating (ICG).

---

## 2. Key Architectural Decisions (Why vs What)

### 2.1 Integrated Clock Gating (ICG) on Low-Frequency Counters
- **Problem:** When feeding a 1 MHz clock continuously to 1 Hz, 1/60 Hz, and 1/3600 Hz counters, the internal clock pin inverters of all Flip-Flops toggle at 1 MHz, wasting significant dynamic power ($P_{clk\_pin} = C_{clk} V_{DD}^2 f_{clk}$).
- **Decision:** Instantiate glitch-free Integrated Clock Gating (ICG) cells (`icg_cell.sv`) for each sub-module:
  - `gated_clk_1khz` for Prescaler Stage 2 and Debouncers (1,000 toggles/s).
  - `gated_clk_sec` for Second Counter (1 toggle/s in RUN mode / load).
  - `gated_clk_min` for Minute Counter (1 toggle/60s in RUN mode / load).
  - `gated_clk_hour` for Hour Counter (1 toggle/3600s in RUN mode / load).
  - `gated_clk_fsm` for Mode Controller.
- **Glitch Immunity & STA Synchronicity:** Each ICG cell utilizes an active-low transparent latch to hold the enable signal stable during the positive half of the clock cycle, preventing any runt pulses/glitches. Gated clocks are derived directly from the root 1 MHz clock, maintaining a 100% single synchronous clock domain with zero CDC risk.
- **DFT / Scan Testability:** Each ICG cell includes a `test_mode` port that forces the gate open during ATPG scan tests, guaranteeing 100% test coverage.

### 2.2 Multi-Stage Cascaded Prescaler & Frequency Matching (PPA Optimization)
- **Decision:** 2-stage cascaded frequency divider (`clk_prescaler`):
  - Stage 1: Modulo-1000 (10-bit) dividing 1 MHz to 1 kHz (`tick_1khz`).
  - Stage 2: Modulo-1000 (10-bit) dividing 1 kHz to 1 Hz (`sec_tick`).
  - Debouncers: Sample at 1 kHz (`gated_clk_1khz`) using 5-bit counters (0..17) instead of 15-bit counters at 1 MHz.
- **Rationale:** Reduces 1 MHz toggling counter bits from 65 bits down to 10 bits (84.6% reduction). Debouncer logic and Stage 2 prescaler only switch at 1 kHz (99.9% lower switching activity).

### 2.3 2-Stage Synchronizer + 1kHz-Sampled 20ms Debounce with ±10% Tolerance & Auto-Repeat
- **Decision:** Asynchronous push buttons (`sel_in`, `up_in`, `down_in`) pass through a 2-FF synchronizer followed by a 1kHz-sampled 20ms continuous-hold counter with $\pm 10\%$ tolerance band ($18\text{ ms} \dots 22\text{ ms}$).
- **Rationale:** Mechanical push buttons bounce for 5–20 ms, and noise glitches can cause false triggers. Requiring a stable 18ms active level filters 100% of contact bounce and noise while allowing reasonable clock/button tolerance.
- **Auto-repeat Behavior:** Once a button is held for 18ms, a 1-clock-cycle pulse is emitted, and the counter immediately resets to 0. If the user continues holding the button, pulses are generated periodically every 18ms, allowing rapid adjustments. If released early (< 18ms), the counter clears to 0 immediately.

### 2.4 Decoupled Time Edit Buffer & Dedicated Output Switch (`output_switch`)
- **Problem:** If top-level outputs directly tap background counters, adjusting the time either requires halting the real-time clock (causing drift) or mutating live counters directly without immediate visual isolation.
- **Decision:**
  - Create a dedicated combinational multiplexer module `output_switch.sv`.
  - Maintain an independent scratchpad edit buffer (`adj_sec`, `adj_min`, `adj_hour`) inside `mode_controller.sv`.
  - In `MODE_ADJ_*`, `output_switch` routes `adj_sec, adj_min, adj_hour` to top outputs for responsive visual feedback.
  - In `MODE_RUN`, `output_switch` routes background real-time counters `s_cnt, m_cnt, h_cnt` to top outputs.
  - **Commit on Loop Exit:** When the user completes adjustment (`ADJ_HOUR` $\rightarrow$ `MODE_RUN` via `sel_in`), `mode_controller` asserts `load_en = 1` for 1 cycle to synchronously parallel load the edit buffer into all counters simultaneously.

### 2.5 Continuous Background Real-Time Counters (Zero-Drift Clock)
- **Decision:** Background counters (`second_counter`, `minute_counter`, `hour_counter`) run continuously in real-time at 1 Hz, 1/60 Hz, 1/3600 Hz regardless of whether the user is browsing adjustment menus.
- **Area & Power Optimization:** Removing the old shadow snapshot registers (`r_*_bak`) saves 17 Flip-Flops and multiplexers across all 3 counter modules.

### 2.6 Simultaneous Up & Down Conflict Resolution
- **Decision:** When both `up_pulse` and `down_pulse` are active simultaneously, the edit buffer in `mode_controller` holds its current value.
- **Rationale:** Prevents nondeterministic behavior and race conditions when multiple buttons are pressed or noisy inputs arrive together.

### 2.7 Inactivity Timeout (5s) & Automatic Rollback
- **Decision:** If the user stays in any adjustment mode (`ADJ_SEC`, `ADJ_MIN`, `ADJ_HOUR`) for 5 consecutive seconds without any button activity, the system automatically exits to `MODE_RUN` with `load_en = 0`.
- **Rationale:** Discards uncommitted buffer changes and seamlessly returns the display to the accurate background counter.

### 2.8 Reset Synchronization & Metastability Prevention (`reset_sync`)
- **Problem:** When an asynchronous external reset signal (`rstn`) is deasserted asynchronously, its rising edge can violate the recovery or removal time of flip-flops in downstream modules (`clk_prescaler`, `button_controller`, `mode_controller`, counters), causing metastability and unpredictable system startup states.
- **Decision:** Implement a dedicated 2-stage Flip-Flop Reset Synchronizer (`reset_sync.sv`):
  - **Asynchronous Assert:** Drops `rstn_sync = 0` immediately when `rstn = 0` without waiting for clock edges, guaranteeing immediate reset.
  - **Synchronous Deassert:** Propagates `rstn_sync = 1` synchronously on the 2nd rising edge of `clk` (2 µs delay), ensuring all downstream flip-flops release from reset simultaneously and cleanly with zero recovery/removal violations.
  - **Synthesis Attributes:** Applies `(* async_reg = "true" *)` to keep synchronizer flip-flops in close physical proximity and prevent unwanted shift-register optimization.
  - **DFT Scan Bypass:** Integrates a static `test_mode` multiplexer to bypass the synchronizer during ATPG scan testing for full fault controllability.
