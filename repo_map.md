# Repository Map & Architecture Mapping (v2.4.0 Universal Synchronous Architecture)

## 1. Directory Structure

```text
HMS_Timer/
├── README.md                      # Overview, build instructions, test scorecard
├── Makefile                       # QuestaSim / VCS / Verilator build automation
├── repo_map.md                    # Repository mapping & traceability
├── rtl_hierarchy.md               # RTL Module hierarchy & port mapping
├── design_intent.md               # Architectural decisions & rationale
├── common_failures.md             # Common bugs and debugging playbook
├── debug_checklist.md             # Pre-commit & sign-off checklist
├── docs/
│   ├── SPECIFICATION.md           # Formal Top-down Architectural Specification (v2.4.0)
│   └── SPECIFICATION.docx         # Formatted Word Document with Architecture & Timing Diagrams
├── rtl/
│   ├── reset_sync.sv              # Universal 2-Stage FF Synchronous Reset Synchronizer
│   ├── clk_prescaler.sv           # Multi-stage cascaded prescaler (1 MHz -> 1 kHz tick -> 1 Hz sec_tick)
│   ├── button_debouncer.sv        # 1 MHz Clock 20ms ±10% debounce counter with tick_1khz enable (5-bit)
│   ├── button_controller.sv       # Multi-channel button controller emitting 1-cycle 1 MHz pulses
│   ├── mode_controller.sv         # 4-State Mode FSM with 5s Inactivity Timeout & Edit Buffer (1 MHz clk)
│   ├── second_counter.sv          # Modulo-60 Second Background Counter with sec_tick & load_en (1 MHz clk)
│   ├── minute_counter.sv          # Modulo-60 Minute Background Counter with sec_rollover & load_en (1 MHz clk)
│   ├── hour_counter.sv            # Modulo-24 Hour Background Counter with min_rollover & load_en (1 MHz clk)
│   ├── output_switch.sv           # Combinational Display Multiplexer (Run: Counter / Adj: Buffer)
│   └── hms_timer.sv               # Top-Level Pure Structural IP Core Interconnect (zero logic)
└── tb/
    ├── hms_timer_types_pkg.sv     # Enums, structs, transaction classes, logging
    ├── hms_timer_if.sv            # SystemVerilog Interface with Clocking Blocks & SVA
    ├── hms_driver.sv              # Driver class for stimulus & reset
    ├── hms_scoreboard.sv          # Cycle-accurate Scoreboard & Golden Model
    ├── hms_coverage.sv            # Covergroups for FSM, Time values & Crosses
    └── tb_hms_timer.sv            # Main testbench runner executing automated test cases
```

## 2. File Responsibilities & Inter-dependencies

```mermaid
graph TD
    SPEC["docs/SPECIFICATION.md"] --> TOP["rtl/hms_timer.sv"]
    TOP --> RST["rtl/reset_sync.sv"]
    TOP --> PSC["rtl/clk_prescaler.sv"]
    TOP --> BTN["rtl/button_controller.sv"]
    BTN --> DEB["rtl/button_debouncer.sv"]
    TOP --> FSM["rtl/mode_controller.sv"]
    TOP --> SEC["rtl/second_counter.sv"]
    TOP --> MIN["rtl/minute_counter.sv"]
    TOP --> HR["rtl/hour_counter.sv"]
    TOP --> MUX["rtl/output_switch.sv"]

    TB["tb/tb_hms_timer.sv"] --> PKG["tb/hms_timer_types_pkg.sv"]
    TB --> IF["tb/hms_timer_if.sv"]
    TB --> DRV["tb/hms_driver.sv"]
    TB --> SCB["tb/hms_scoreboard.sv"]
    TB --> COV["tb/hms_coverage.sv"]
    TB --> TOP
```
