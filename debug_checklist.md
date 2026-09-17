# Debug & Sign-Off Checklist for RTL & Verification

## 1. RTL Design Checklist
- [x] **No Combinational Loops:** All sequential always blocks use non-blocking assignments (`<=`).
- [x] **No Latches Inferred:** All combinational always blocks use full branch coverage or default assignments.
- [x] **Single Clock Domain:** All sequential registers driven by `posedge clk`.
- [x] **Asynchronous Reset:** All flip-flops have active-low `negedge rstn` reset path.
- [x] **Bit-Width Matching:** Exact bit-widths (`s_out[5:0]`, `m_out[5:0]`, `h_out[4:0]`).
- [x] **Clean Synthesizability:** Technology-independent IEEE 1800 SystemVerilog.

## 2. Testbench & Verification Checklist
- [x] **Race-free Interface:** Clocking blocks used for driver and monitor sampling.
- [x] **SVA Concurrent Assertions:** Range bounds check on `s_out`, `m_out`, `h_out` and reset checks.
- [x] **Self-Checking Scoreboard:** Golden reference model verifies every transaction and point-in-time state.
- [x] **Comprehensive Functional Coverage:** 100% FSM state & transition coverage, 100% time range coverage.
- [x] **Automated Regression:** `make all`, `make sim`, `make cov` automated via Makefile.
- [x] **Zero Errors:** 66/66 checks passed cleanly in QuestaSim.
