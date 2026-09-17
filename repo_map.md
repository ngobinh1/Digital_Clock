# Repository Map & Architecture Mapping

## 1. Directory Structure

```text
HMS_Timer/
├── README.md                      # Overview, build instructions, test scorecard
├── Makefile                       # QuestaSim / VCS / Verilator build automation
├── repo_map.md                    # This file - Repository mapping & traceability
├── rtl_hierarchy.md               # RTL Module hierarchy & port mapping
├── design_intent.md               # Architectural decisions & rationale
├── common_failures.md             # Common bugs and debugging playbook
├── debug_checklist.md             # Pre-commit & sign-off checklist
├── docs/
│   └── SPECIFICATION.md           # Formal Top-down Architectural Specification
├── rtl/
│   ├── sync_edge_detector.sv      # Metastability synchronization & positive edge detection
│   ├── prescaler_1hz.sv           # 1 MHz -> 1 Hz timebase prescaler
│   ├── mode_controller.sv         # 4-State Mode FSM
│   ├── second_counter.sv          # Modulo-60 Second Counter with +/-1 adjustment
│   ├── minute_counter.sv          # Modulo-60 Minute Counter with +/-1 adjustment
│   ├── hour_counter.sv            # Modulo-24 Hour Counter with +/-1 adjustment
│   └── hms_timer.sv               # Top-Level IP Core Integration
└── tb/
    ├── hms_timer_types_pkg.sv     # Enums, structs, transaction classes, logging
    ├── hms_timer_if.sv            # SystemVerilog Interface with Clocking Blocks & SVA
    ├── hms_driver.sv              # Driver class for asynchronous stimulus & reset
    ├── hms_scoreboard.sv          # Cycle-accurate Scoreboard & Golden Model
    ├── hms_coverage.sv            # Covergroups for FSM, Time values & Crosses
    └── tb_hms_timer.sv            # Main testbench runner executing 11 test cases
```

## 2. File Responsibilities & Inter-dependencies

```mermaid
graph TD
    SPEC["docs/SPECIFICATION.md"] --> TOP["rtl/hms_timer.sv"]
    TOP --> SYNC["rtl/sync_edge_detector.sv"]
    TOP --> PSC["rtl/prescaler_1hz.sv"]
    TOP --> FSM["rtl/mode_controller.sv"]
    TOP --> SEC["rtl/second_counter.sv"]
    TOP --> MIN["rtl/minute_counter.sv"]
    TOP --> HR["rtl/hour_counter.sv"]

    TB["tb/tb_hms_timer.sv"] --> PKG["tb/hms_timer_types_pkg.sv"]
    TB --> IF["tb/hms_timer_if.sv"]
    TB --> DRV["tb/hms_driver.sv"]
    TB --> SCB["tb/hms_scoreboard.sv"]
    TB --> COV["tb/hms_coverage.sv"]
    TB --> TOP
```
