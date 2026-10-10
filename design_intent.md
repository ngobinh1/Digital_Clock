# Design Intent & Architectural Decisions (v2.4.0 Universal Synchronous Architecture)

## 1. Objective & Scope
The `HMS_Timer` IP Core is designed to provide an accurate, robust, power/area-optimized, and synthesizable digital time-keeping solution universally portable across both FPGA and ASIC designs. It operates on a single synchronous 1 MHz master clock domain with single-cycle Pulse Clock Enables (Tick Generation), zero Clock Domain Crossing (CDC), zero clock skew, and 100% pure structural top-level wiring.

---

## 2. Key Architectural Decisions (Why vs What)

### 2.1 Universal Synchronous Single-Clock Domain Architecture with Pulse Clock Enable
- **Problem with Manual ICG:** 
  - Instantiating discrete Integrated Clock Gating (ICG) cells in RTL creates multiple gated clock branches (`gated_clk_*`). On FPGA architectures (Xilinx 7-Series/UltraScale, Intel Cyclone/MAX), discrete clock gating fragments the clock tree, exhausts limited global clock buffers (`BUFG`), introduces significant clock skew, and causes Design Rule Check (DRC) violations due to transparent latch primitives.
  - Furthermore, maintaining separate architectures or parameter switches (`TARGET_FPGA`) complicates design validation and cross-technology portability.
- **Decision:**
  - Standardize 100% of the design on a **Single Synchronous 1 MHz Clock Domain** (`clk`) with single-cycle pulse Clock Enables (`CE`).
  - Eliminate all manual ICG cells (`icg_cell.sv`) and the centralized clock control unit (`clock_control_unit.sv`).
  - All registers in sub-modules (`button_debouncer`, `mode_controller`, `second_counter`, `minute_counter`, `hour_counter`) run on `posedge clk`, gating updates via native clock enables (`tick_1khz`, `sec_tick`, `sec_rollover`, `min_rollover`, `load_en`).
- **FPGA Benefits:**
  - Consumes exactly **1 Global Clock Buffer (BUFG)** for the entire chip.
  - Maps directly into native Flip-Flop Clock Enable (`CE`) pins in FPGA logic slices (e.g., AMD/Xilinx `FDRE` primitives).
  - Guarantees zero clock skew, zero hold-time violations across branches, and zero CDC risks.
- **ASIC Benefits (Automatic Clock Gating Insertion - ACGI):**
  - Modern ASIC synthesis compilers (Synopsys Design Compiler with `compile_ultra -gate_clock`, Cadence Genus with `set_db lp_insert_clock_gating true`, OpenLane/Yosys) natively infer clock gating on registers controlled by `if (clk_en)` conditions.
  - The synthesis tool automatically inserts technology-matched PDK standard cell ICGs (e.g., `sky130_fd_sc_hd__dlclkp_*`) balanced within the clock tree during Clock Tree Synthesis (CTS), achieving the exact same dynamic power reduction (>99.9% clock pin power saved on counters) without non-portable manual RTL constructs.

### 2.2 Multi-Stage Cascaded Prescaler & Frequency Matching (PPA Optimization)
- **Decision:** 2-stage cascaded frequency divider (`clk_prescaler`):
  - Stage 1: Modulo-1000 (10-bit) dividing 1 MHz to produce a 1-cycle 1 kHz pulse (`tick_1khz`).
  - Stage 2: Modulo-1000 (10-bit) dividing 1 kHz to produce a 1-cycle 1 Hz pulse (`sec_tick`).
  - Debouncers: Sample at 1 kHz using `tick_1khz` as clock enable with 5-bit counters (0..17) on the 1 MHz clock, instead of 15-bit counters at 1 MHz.
- **Rationale:** Reduces 1 MHz toggling counter bits from 65 bits down to 10 bits (84.6% reduction). Debouncer logic and Stage 2 prescaler only switch when `tick_1khz` is asserted (99.9% lower switching activity).

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

### 2.8 Universal 2-Stage Synchronous Reset Synchronizer (`reset_sync`)
- **Problem:** Asynchronous reset deassertion can violate recovery and removal timing on downstream flip-flops, leading to metastability and inconsistent startup states.
- **Decision:** Implement a clean universal 2-stage Flip-Flop Synchronous Reset Synchronizer (`reset_sync.sv`):
  - Cascaded 2 D-flip-flops running on `posedge clk`.
  - Filters asynchronous transients and aligns `rstn_sync` to the clock domain.
  - Synthesis attributes `(* async_reg = "true" *)` prevent SRL inference and keep registers adjacent in physical placement.
  - Downstream modules utilize clean synchronous reset (`if (!rstn)`) mapping directly to synchronous reset control sets on FPGA and high-performance ASIC standard cell libraries.

### 2.9 Pure Structural Top-Level Interconnect (`hms_timer`)
- **Decision:** `hms_timer.sv` contains 0 `assign` statements and 0 `always` blocks.
- **Rationale:** Eliminates glue logic at the top level, ensuring that `hms_timer` is strictly a structural harness interconnecting self-contained sub-modules. Any internal control logic is encapsulated within its respective functional module.
