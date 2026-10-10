# RTL Module Hierarchy & Interconnect Matrix (Universal Synchronous Architecture)

## 1. Top-Level Module: `hms_timer`

### 1.1 Parameters
| Parameter | Default Value | Description |
| :--- | :---: | :--- |
| `CLK_FREQ_HZ` | `1_000_000` | System clock frequency (1 MHz default, scalable to 50/100 MHz) |
| `TICK_1KHZ_FREQ_HZ` | `1_000` | 1 kHz sampling rate frequency |
| `TICK_1HZ_FREQ_HZ` | `1` | 1 Hz real-time timebase frequency |
| `DIV_1KHZ_MAX` | `(CLK_FREQ_HZ / 1000) - 1` | Prescaler stage 1 terminal count (999) |
| `DIV_1HZ_MAX` | `(1000 / 1) - 1` | Prescaler stage 2 terminal count (999) |
| `DEBOUNCE_TICKS` | `20` | Nominal debounce threshold in 1 kHz ticks (20 ticks = 20ms) |
| `DEBOUNCE_TOL_PCT`| `10` | Debounce tolerance percentage (±10%, 18 ms .. 22 ms) |
| `TIMEOUT_SEC` | `5` | Inactivity timeout threshold in seconds (Default 5s) |
| `SEC_WIDTH` | `6` | Bit width of second counter (0 .. 59) |
| `MIN_WIDTH` | `6` | Bit width of minute counter (0 .. 59) |
| `HOUR_WIDTH` | `5` | Bit width of hour counter (0 .. 23) |

### 1.2 Top-Level I/O Ports
| Port Name | Direction | Width | Type | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | Clock | 1 MHz synchronous master clock |
| `rstn` | Input | 1 | Reset | Active-low asynchronous reset |
| `sel_in` | Input | 1 | Async Control | Mode select button input (20ms ±10% debounce) |
| `up_in` | Input | 1 | Async Control | Increment button input (20ms ±10% debounce) |
| `down_in` | Input | 1 | Async Control | Decrement button input (20ms ±10% debounce) |
| `h_out` | Output | 5 | Data Out | Display hours (0 .. 23) |
| `m_out` | Output | 6 | Data Out | Display minutes (0 .. 59) |
| `s_out` | Output | 6 | Data Out | Display seconds (0 .. 59) |

---

## 2. Sub-module Hierarchy Tree

```text
hms_timer (Top - Universal Synchronous Single-Clock Domain Architecture)
├── u_reset_sync           [reset_sync.sv - 2-Stage Flip-Flop Synchronous Reset Synchronizer]
│   ├── r_sync_stage1       (Stage 1 Synchronizer FF, async_reg = "true")
│   └── r_sync_stage2       (Stage 2 Synchronizer FF, async_reg = "true")
├── u_clk_prescaler        [clk_prescaler.sv - 2-Stage Cascaded Frequency Divider]
│   ├── r_cnt_1khz[9:0]     (Stage 1: Modulo-1000, 1 MHz -> 1 kHz tick_1khz)
│   └── r_cnt_1hz[9:0]      (Stage 2: Modulo-1000 clocked on 1 MHz, enabled by tick_1khz -> 1 Hz sec_tick)
├── u_button_controller   [button_controller.sv - Multi-Channel Button Controller & Pulse Alignment]
│   ├── u_debouncer_sel     (button_debouncer for sel_in)
│   ├── u_debouncer_up      (button_debouncer for up_in)
│   └── u_debouncer_down    (button_debouncer for down_in)
├── u_mode_controller      [mode_controller.sv - FSM Mode Controller & Inactivity Timer]
│   ├── state_reg[1:0]      (4-State FSM: RUN, ADJ_SEC, ADJ_MIN, ADJ_HOUR)
│   ├── timeout_cnt[2:0]    (5-Second Inactivity Timer -> auto-exit without load_en)
│   ├── r_adj_sec[5:0]      (Edit Buffer: Second)
│   ├── r_adj_min[5:0]      (Edit Buffer: Minute)
│   ├── r_adj_hour[4:0]     (Edit Buffer: Hour)
│   └── r_load_en           (1-cycle Commit Pulse to load counters)
├── u_second_counter       [second_counter.sv - Continuous Background Counter with Native Clock Enable]
│   └── r_sec[5:0]          (Modulo-60 Counter with Synchronous Load)
├── u_minute_counter       [minute_counter.sv - Continuous Background Counter with Native Clock Enable]
│   └── r_min[5:0]          (Modulo-60 Counter with Synchronous Load)
├── u_hour_counter         [hour_counter.sv - Continuous Background Counter with Native Clock Enable]
│   └── r_hour[4:0]         (Modulo-24 Counter with Synchronous Load)
└── u_output_switch        [output_switch.sv - Combinational Display Multiplexer]
    ├── Second MUX (s_out = (RUN) ? s_cnt : adj_sec)
    ├── Minute MUX (m_out = (RUN) ? m_cnt : adj_min)
    └── Hour MUX   (h_out = (RUN) ? h_cnt : adj_hour)
```

---

## 3. Internal Interconnect Matrix

| Internal Signal | Width | Driver Module | Receiver Module(s) | Function |
| :--- | :---: | :--- | :--- | :--- |
| `rstn_sync` | 1 | `u_reset_sync` | Toàn bộ các sub-module tuần tự | Synchronized active-low reset to eliminate recovery/removal violations |
| `tick_1khz` | 1 | `u_clk_prescaler` | `u_button_controller` | 1-cycle active-high pulse every 1ms (1 kHz) for debounce sampling |
| `sec_tick` | 1 | `u_clk_prescaler` | `u_second_counter`, `u_mode_controller` | 1-cycle active-high pulse every 1s (1 Hz) |
| `sel_pulse` | 1 | `u_button_controller` | `u_mode_controller` | 1-cycle pulse from debounced sel button |
| `up_pulse` | 1 | `u_button_controller` | `u_mode_controller` | 1-cycle pulse from debounced up button |
| `down_pulse` | 1 | `u_button_controller` | `u_mode_controller` | 1-cycle pulse from debounced down button |
| `adj_mode[1:0]` | 2 | `u_mode_controller` | `u_output_switch` | Current operating mode state |
| `load_en` | 1 | `u_mode_controller` | `u_second_counter`, `u_minute_counter`, `u_hour_counter` | 1-cycle commit pulse to parallel load edit buffer into counters |
| `adj_sec[5:0]` | 6 | `u_mode_controller` | `u_output_switch`, `u_second_counter` | Second value in edit buffer |
| `adj_min[5:0]` | 6 | `u_mode_controller` | `u_output_switch`, `u_minute_counter` | Minute value in edit buffer |
| `adj_hour[4:0]` | 5 | `u_mode_controller` | `u_output_switch`, `u_hour_counter` | Hour value in edit buffer |
| `s_cnt[5:0]` | 6 | `u_second_counter` | `u_output_switch`, `u_mode_controller` | Real-time second from background counter |
| `m_cnt[5:0]` | 6 | `u_minute_counter` | `u_output_switch`, `u_mode_controller` | Real-time minute from background counter |
| `h_cnt[4:0]` | 5 | `u_hour_counter` | `u_output_switch`, `u_mode_controller` | Real-time hour from background counter |
| `sec_rollover` | 1 | `u_second_counter` | `u_minute_counter` | 1-cycle rollover pulse when `s_cnt == 59 & sec_tick & ~load_en` |
| `min_rollover` | 1 | `u_minute_counter` | `u_hour_counter` | 1-cycle rollover pulse when `m_cnt == 59 & sec_rollover & ~load_en` |
