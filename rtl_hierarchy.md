# RTL Module Hierarchy & Interconnect Matrix (v1.1.0)

## 1. Top-Level Module: `hms_timer`

### 1.1 Parameters
| Parameter | Default Value | Description |
| :--- | :---: | :--- |
| `CLK_FREQ_HZ` | `1_000_000` | System clock frequency (1 MHz) |
| `PSC_COUNT_MAX` | `CLK_FREQ_HZ - 1` | Prescaler terminal count ($10^6 - 1$) |
| `PSC_WIDTH` | `20` | Bit width of prescaler counter |
| `DEBOUNCE_TIME_MS` | `20` | Button debounce hold time in ms (Default 20ms) |
| `DEBOUNCE_CYCLES` | `(CLK_FREQ_HZ / 1000) * DEBOUNCE_TIME_MS` | Debounce counter terminal count (20,000 cycles) |
| `DEBOUNCE_WIDTH` | `15` | Bit width of debounce counter ($clog2(20,000) = 15$) |
| `TIMEOUT_SEC` | `5` | Inactivity timeout threshold in seconds (Default 5s) |
| `SEC_WIDTH` | `6` | Bit width of second counter ($0 \dots 59$) |
| `MIN_WIDTH` | `6` | Bit width of minute counter ($0 \dots 59$) |
| `HOUR_WIDTH` | `5` | Bit width of hour counter ($0 \dots 23$) |

### 1.2 Top-Level I/O Ports
| Port Name | Direction | Width | Type | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | Clock | 1 MHz synchronous system clock |
| `rstn` | Input | 1 | Reset | Asynchronous active-low reset |
| `sel_in` | Input | 1 | Async Control | Mode select button input (20ms debounce) |
| `up_in` | Input | 1 | Async Control | Increment button input (20ms debounce) |
| `down_in` | Input | 1 | Async Control | Decrement button input (20ms debounce) |
| `h_out` | Output | 5 | Data Out | Real-time hours ($0 \dots 23$) |
| `m_out` | Output | 6 | Data Out | Real-time minutes ($0 \dots 59$) |
| `s_out` | Output | 6 | Data Out | Real-time seconds ($0 \dots 59$) |

---

## 2. Sub-module Hierarchy Tree

```text
hms_timer (Top)
├── u_debouncer_sel       [button_debouncer.sv]
│   ├── sync_reg[1:0]      (2-FF Synchronizer)
│   └── timer_cnt[14:0]    (20ms Debounce & Auto-Repeat Counter)
├── u_debouncer_up        [button_debouncer.sv]
│   ├── sync_reg[1:0]      (2-FF Synchronizer)
│   └── timer_cnt[14:0]    (20ms Debounce & Auto-Repeat Counter)
├── u_debouncer_down      [button_debouncer.sv]
│   ├── sync_reg[1:0]      (2-FF Synchronizer)
│   └── timer_cnt[14:0]    (20ms Debounce & Auto-Repeat Counter)
├── u_prescaler_1hz       [prescaler_1hz.sv]
│   └── r_count[19:0]      (Modulo-1,000,000 Prescaler Counter)
├── u_mode_controller     [mode_controller.sv]
│   ├── state_reg[1:0]     (4-State FSM: RUN, ADJ_SEC, ADJ_MIN, ADJ_HOUR)
│   └── timeout_cnt[2:0]   (5-Second Inactivity Timer -> cancel_pulse)
├── u_second_counter      [second_counter.sv]
│   ├── r_sec[5:0]         (Modulo-60 Counter + Gated Rollover Flag)
│   └── r_sec_bak[5:0]     (Snapshot Shadow Register for Rollback)
├── u_minute_counter      [minute_counter.sv]
│   ├── r_min[5:0]         (Modulo-60 Counter + Gated Rollover Flag)
│   └── r_min_bak[5:0]     (Snapshot Shadow Register for Rollback)
└── u_hour_counter        [hour_counter.sv]
    ├── r_hour[4:0]        (Modulo-24 Counter)
    └── r_hour_bak[4:0]    (Snapshot Shadow Register for Rollback)
```

---

## 3. Internal Interconnect Matrix

| Internal Signal | Width | Driver Module | Receiver Module(s) | Function |
| :--- | :---: | :--- | :--- | :--- |
| `sel_pulse` | 1 | `u_debouncer_sel` | `u_mode_controller`, `u_second_counter`, `u_minute_counter`, `u_hour_counter` | 1-cycle active-high pulse on 20ms held `sel_in` |
| `up_pulse` | 1 | `u_debouncer_up` | `u_mode_controller`, `u_second_counter`, `u_minute_counter`, `u_hour_counter` | 1-cycle active-high pulse on 20ms held `up_in` |
| `down_pulse` | 1 | `u_debouncer_down` | `u_mode_controller`, `u_second_counter`, `u_minute_counter`, `u_hour_counter` | 1-cycle active-high pulse on 20ms held `down_in` |
| `sec_tick` | 1 | `u_prescaler_1hz` | `u_second_counter`, `u_mode_controller` | 1 Hz periodic 1-cycle time base pulse |
| `adj_mode[1:0]` | 2 | `u_mode_controller` | `u_second_counter`, `u_minute_counter`, `u_hour_counter` | FSM mode indicator |
| `cancel_pulse` | 1 | `u_mode_controller` | `u_second_counter`, `u_minute_counter`, `u_hour_counter` | 1-cycle pulse triggered by 5s inactivity timeout to rollback |
| `sec_rollover` | 1 | `u_second_counter` | `u_minute_counter` | 1-cycle pulse when $r\_sec == 59 \land sec\_tick \land RUN$ |
| `min_rollover` | 1 | `u_minute_counter` | `u_hour_counter` | 1-cycle pulse when $r\_min == 59 \land sec\_rollover \land RUN$ |
