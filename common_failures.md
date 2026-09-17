# Common Failures & Debug Playbook

## 1. Fast-Simulation Clock Ratio Trap
- **Symptom:** Testcase fails because seconds increment unexpectedly during button presses.
- **Root Cause:** If `SIM_CLK_FREQ_HZ` is set too low (e.g. 5 cycles per second), a multi-cycle button press (e.g. 8 cycles) will span across a `sec_tick` event while the DUT is still in `MODE_RUN`.
- **Resolution:** Set `SIM_CLK_FREQ_HZ >= 50` so that button pulses (3 to 8 cycles) are completed well before the next natural `sec_tick`.

## 2. Rollover Enable Leakage during Adjustment
- **Symptom:** Minute counter increments unexpectedly when seconds wrap from 59 to 00 in `MODE_ADJ_SEC`.
- **Root Cause:** `sec_rollover` condition did not check for `adj_mode == MODE_RUN`.
- **Resolution:** Ensure `sec_rollover = (adj_mode == MODE_RUN) && (sec_tick) && (r_sec == 59)`.

## 3. Asynchronous Edge Glitches
- **Symptom:** Multiple increment/decrement steps occur for a single button press.
- **Root Cause:** Relying on level inputs rather than edge detection.
- **Resolution:** Positive edge detection `pulse = FF2 & ~FF3` ensures exactly 1 single-cycle pulse per physical button press.
