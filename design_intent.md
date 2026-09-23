# Design Intent & Architectural Decisions (v1.1.0)

## 1. Objective & Scope
The `HMS_Timer` IP Core is designed to provide an accurate, robust, and synthesizable digital time-keeping solution for ASIC/FPGA designs operating on a synchronous 1 MHz clock domain.

---

## 2. Key Architectural Decisions (Why vs What)

### 2.1 Single Clock Domain vs Ripple Clock
- **Decision:** All registers are clocked by the global `clk` signal. No sub-module generates a ripple clock for another module.
- **Rationale:** Ripple clocks cause clock skew, glitches, race conditions, and violate synchronous design rules in modern synthesis and STA (Static Timing Analysis).
- **Implementation:** Counters communicate via 1-cycle synchronous enable pulses (`sec_rollover`, `min_rollover`).

### 2.2 2-Stage Synchronizer + 20ms Debounce Counter & Auto-Repeat
- **Decision:** Asynchronous push buttons (`sel_in`, `up_in`, `down_in`) pass through a 2-FF synchronizer followed by a 20ms continuous-hold counter.
- **Rationale:** Mechanical push buttons bounce for 5–20 ms, and noise glitches can cause false triggers. Requiring a stable 20ms active level filters 100% of contact bounce and noise.
- **Auto-repeat Behavior:** Once a button is held for 20ms, a 1-clock-cycle pulse is emitted, and the 20ms counter immediately resets to 0. If the user continues holding the button, pulses are generated periodically every 20ms, allowing rapid adjustments. If released early (< 20ms), the counter clears to 0 immediately.

### 2.3 Rollover Gating in Adjustment Modes
- **Decision:** In `MODE_ADJ_SEC` and `MODE_ADJ_MIN`, `sec_rollover` and `min_rollover` are strictly gated to `0`.
- **Rationale:** When a user adjusts the seconds from 59 to 00, they intend to reset the second field, not to increment the minute field. Gating the rollover pulse completely isolates each time field during user configuration.

### 2.4 Simultaneous Up & Down Conflict Resolution
- **Decision:** When both `up_pulse` and `down_pulse` are active simultaneously, the counters hold their current value.
- **Rationale:** Prevents nondeterministic behavior and race conditions when multiple buttons are pressed or noisy inputs arrive together.

### 2.5 Inactivity Timeout (5s) & Automatic Rollback (Cancel Changes)
- **Decision:** If the user stays in any adjustment mode (`ADJ_SEC`, `ADJ_MIN`, `ADJ_HOUR`) for 5 consecutive seconds without any button activity, the system automatically cancels all uncommitted modifications, reverts to the snapshot taken upon entering adjustment mode, and returns to `MODE_RUN`.
- **Rationale:** Prevents the device from being stuck in configuration mode indefinitely, and prevents accidental/unintended partial adjustments from corrupting the real-time clock.
- **Implementation:** 
  - When transitioning from `MODE_RUN` to `MODE_ADJ_SEC` upon a `sel_pulse`, each counter (`second_counter`, `minute_counter`, `hour_counter`) captures its current value into a shadow backup register (`_bak`).
  - `mode_controller` tracks inactivity using `sec_tick`. Any button press resets the 5-second timer.
  - If 5 seconds elapse without button presses, `mode_controller` pulses `cancel_pulse` for 1 clock cycle and transitions to `MODE_RUN`. Each counter reloads its value from `_bak`.
  - If the user explicitly cycles through to `MODE_RUN` via `sel_pulse`, the new values are committed.
