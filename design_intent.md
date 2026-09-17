# Design Intent & Architectural Decisions

## 1. Objective & Scope
The `HMS_Timer` IP Core is designed to provide an accurate, robust, and synthesizable digital time-keeping solution for ASIC/FPGA designs operating on a synchronous 1 MHz clock domain.

---

## 2. Key Architectural Decisions (Why vs What)

### 2.1 Single Clock Domain vs Ripple Clock
- **Decision:** All registers are clocked by the global `clk` signal. No sub-module generates a ripple clock for another module.
- **Rationale:** Ripple clocks cause clock skew, glitches, race conditions, and violate synchronous design rules in modern synthesis and STA (Static Timing Analysis).
- **Implementation:** Counters communicate via 1-cycle synchronous enable pulses (`sec_rollover`, `min_rollover`).

### 2.2 2-Stage Metastability Synchronizer + Positive Edge Detector
- **Decision:** Asynchronous push buttons (`sel_in`, `up_in`, `down_in`) are passed through 2 FF stages before edge detection.
- **Rationale:** Mechanical buttons or external asynchronous lines can transition arbitrarily with respect to `clk`, causing setup/hold violations and metastability. 2-FF synchronization guarantees high MTBF.
- **Implementation:** `pulse_out = sync_ff2 & ~delay_ff3`.

### 2.3 Rollover Gating in Adjustment Modes
- **Decision:** In `MODE_ADJ_SEC` and `MODE_ADJ_MIN`, `sec_rollover` and `min_rollover` are strictly gated to `0`.
- **Rationale:** When a user adjusts the seconds from 59 to 00, they intend to reset the second field, not to increment the minute field. Gating the rollover pulse completely isolates each time field during user configuration.

### 2.4 Simultaneous Up & Down Conflict Resolution
- **Decision:** When both `up_pulse` and `down_pulse` are active simultaneously, the counters hold their current value.
- **Rationale:** Prevents nondeterministic behavior and race conditions when multiple buttons are pressed or noisy inputs arrive together.
