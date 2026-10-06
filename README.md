# Hour-Minute-Second Timer (`HMS_Timer`) IP Core & Verification Environment (v2.3.0 Output Switch & Zero-Drift Clock)

[![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Verilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![EDA](https://img.shields.io/badge/Simulator-QuestaSim%20%2F%20VCS%20%2F%20Verilator-green.svg)]()
[![Status](https://img.shields.io/badge/Verification-100%25%20PASSED-brightgreen.svg)]()
[![Assertions](https://img.shields.io/badge/SVA-100%25%20PASS-success.svg)]()
[![ICG](https://img.shields.io/badge/ICG-Glitch--Free%20Clock%20Gating-orange.svg)]()
[![Debounce](https://img.shields.io/badge/Debouncer-%C2%B110%25%20Tolerance%20(18--22ms)-blueviolet.svg)]()
[![Architecture](https://img.shields.io/badge/Architecture-Decoupled%20Buffer%20%2B%20MUX-brightgreen.svg)]()

IP Core bộ đếm thời gian thực **Giờ - Phút - Giây (Hour-Minute-Second Timer)** chuẩn công nghiệp bán dẫn, thiết kế hoàn toàn bằng ngôn ngữ phần cứng **SystemVerilog Synthesizable** và được kiểm chứng toàn diện với môi trường **SystemVerilog Verification Environment** (Interface, Clocking Blocks, Driver, Golden Model Scoreboard, Functional Coverage, SystemVerilog Assertions).

Phiên bản **v2.3.0** nâng cấp **Kiến trúc Tách biệt Bộ Đệm Chỉnh Giờ & Chuyển Mạch Hiển Thị (`output_switch`)** kết hợp **Bộ đếm Nền Zero-Drift Real-Time Counters** và **Bộ Đồng Bộ Hóa Reset (`reset_sync`)**:
- **Bộ Đồng Bộ Hóa Giải Trừ Reset (`reset_sync` - Asynchronous Assert, Synchronous Deassert 2-FF)**:
  * Xác lập mức thấp ngay tức thì khi `rstn = 0` (zero clock delay), đảm bảo reset hệ thống kịp thời và tin cậy.
  * Giải trừ mức cao đồng bộ theo sườn dương `clk` sau 2 chu kỳ clock (2 µs), triệt tiêu hoàn toàn vi phạm Recovery/Removal Time và chống hiện tượng bất ổn định (Metastability) toàn chip.
  * Tích hợp cổng multiplexer bypass `test_mode` cho kiểm thử Scan ATPG.
- **Khối Chuyển Mạch Hiển Thị Chuyên Dụng (`output_switch`)**:
  * Khi ở chế độ chỉnh sửa (`MODE_ADJ_*`), các ngõ ra hiển thị trực tiếp giá trị từ bộ đệm chỉnh sửa (`mode_controller`) giúp người dùng theo dõi trực quan và tức thời.
  * Khi ở chế độ đếm thời gian thực (`MODE_RUN`), các ngõ ra hiển thị giá trị từ các bộ đếm nền thời gian thực.
- **Bộ Đếm Nền Liên Tục Chuẩn Xác (Zero-Drift Background Clock)**:
  * Các khối `second_counter`, `minute_counter`, `hour_counter` đếm thời gian thực liên tục 24/7 ở chế độ nền. Không bị dừng hay trôi thời gian khi người dùng đang thao tác trong menu.
  * Loại bỏ hoàn toàn các thanh ghi bóng (shadow snapshot registers), tiết kiệm 17 Flip-Flops và cổng logic.
- **Nạp Song Song Đồng Bộ Khi Xác Nhận (Commit on Loop Exit)**:
  * Khi người dùng duyệt hết chu trình chỉnh giờ (`ADJ_HOUR` -> `MODE_RUN`), `mode_controller` phát xung 1-cycle `load_en = 1`, nạp song song toàn bộ thời gian đã chỉnh vào các bộ đếm.
- **Hủy Bỏ & Khôi Phục Hiển Thị Tự Động Sau 5s (5s Inactivity Timeout)**:
  * Nếu người dùng không thao tác phím trong 5s, FSM tự động quay về `MODE_RUN` với `load_en = 0` (hủy bỏ bộ đệm), bộ MUX tự động chuyển lại hiển thị bộ đếm nền đang chạy chuẩn xác.
- **Khử rung nút bấm chuyên dụng 20ms với Dung sai ±10% (`1kHz-Sampled 20ms ±10% Debounce & Auto-Repeat`)**:
  * Tần số lấy mẫu: 1 kHz (1 ms). Dải dung sai: 18 ms .. 22 ms.
- **Khóa Xung Nhịp Chống Glitch (`Glitch-Free Integrated Clock Gating - ICG`)**:
  * Chân CLK của `second_counter` chỉ dao động **1 lần/giây** (1 toggle/s).
  * Chân CLK của `minute_counter` chỉ dao động **1 lần/60 giây**.
  * Chân CLK của `hour_counter` chỉ dao động **1 lần/3600 giây**.
  * Chân CLK của `button_debouncer` chỉ dao động **1,000 lần/giây**.

---

## 1. Cấu trúc thư mục dự án (Directory Structure)

```text
HMS_Timer/
├── README.md                  # Tài liệu hướng dẫn sử dụng và báo cáo kiểm chứng
├── Makefile                   # Build script cho QuestaSim / VCS / Verilator
├── docs/                      # Tài liệu thiết kế đặc tả kiến trúc
│   ├── SPECIFICATION.md       # Đặc tả thiết kế RTL chi tiết chuẩn Spec-First (v2.3.0)
│   └── SPECIFICATION.docx     # Tài liệu Word báo cáo kiến trúc và giản đồ
├── rtl/                       # Mã nguồn RTL Synthesizable (ICG + Decoupled PPA Optimized)
│   ├── reset_sync.sv          # Khối đồng bộ hóa reset 2-FF (Async Assert, Sync Deassert) & DFT Bypass
│   ├── icg_cell.sv            # Cổng Integrated Clock Gating chống Glitch (Latch-based)
│   ├── clock_control_unit.sv  # Khối quản lý xung nhịp tập trung & 5 cổng ICG
│   ├── clk_prescaler.sv       # Bộ chia tần đa tầng 1MHz -> 1kHz -> 1Hz
│   ├── button_debouncer.sv    # Khối đồng bộ 2-FF & Khử rung 20ms ±10% Tol Clock 1kHz (5-bit)
│   ├── button_controller.sv   # Quản lý 3 nút bấm & Căn xung 1 MHz đồng bộ
│   ├── mode_controller.sv     # FSM điều khiển 4 chế độ, bộ đệm chỉnh giờ & Timeout 5s
│   ├── second_counter.sv      # Bộ đếm Giây Modulo-60 nền & Synchronous Load (1 toggle/s)
│   ├── minute_counter.sv      # Bộ đếm Phút Modulo-60 nền & Synchronous Load (1 toggle/60s)
│   ├── hour_counter.sv        # Bộ đếm Giờ Modulo-24 nền & Synchronous Load (1 toggle/3600s)
│   ├── output_switch.sv       # Bộ chuyển mạch đa hợp hiển thị tổ hợp (Display MUX)
│   └── hms_timer.sv           # Top-level IP Core tích hợp CCU, Reset Sync & Output Switch
├── tb/                        # Môi trường kiểm chứng SystemVerilog
│   ├── hms_timer_types_pkg.sv # Package định nghĩa kiểu dữ liệu, enum, loggers
│   ├── hms_timer_if.sv        # Interface chứa Clocking blocks, ICG probes & SVA
│   ├── hms_driver.sv          # Class Driver phát stimulus và điều khiển Reset
│   ├── hms_scoreboard.sv      # Class Scoreboard đối chiếu Golden Model
│   ├── hms_coverage.sv        # Class Functional Coverage Model
│   └── tb_hms_timer.sv        # Top Testbench Runner thực thi Automated Testsuite
├── repo_map.md                # Bản đồ phân tầng dự án
├── rtl_hierarchy.md           # Cấu trúc phân cấp module và kết nối
├── design_intent.md           # Lý do và căn cứ quyết định kiến trúc
├── common_failures.md         # Sổ tay các lỗi thường gặp và cách xử lý
└── debug_checklist.md         # Checklist kiểm tra RTL và Testbench
```

---

## 2. Kiến trúc & Nguyên lý hoạt động (Architecture Overview)

```
+=======================================================================================================+
|                                    TOP: hms_timer (v2.3.0 Decoupled & Output Switch)                  |
|                                                                                                       |
|                     +----------------------------------------------------+                            |
|                     |                    clk_prescaler                   |                            |
|   clk ------------->| Stage 1 (1MHz -> 1kHz): Mod-1000 -> tick_1khz -----|----+ (1 kHz Tick)          |
|   rstn ------------>| Stage 2 (1kHz -> 1Hz) : Mod-1000 -> sec_tick ------|--+ | (1 Hz Tick)           |
|                     +----------------------------------------------------+  | |                       |
|                                                                             | |                       |
|                     +----------------------------------------------------+  | |                       |
|                     |             ICG Layer (Glitch-Free Cells)          |  | |                       |
|                     |  u_icg_1khz  -> gated_clk_1khz  (1,000 Hz)          |<-+ |                       |
|                     |  u_icg_sec   -> gated_clk_sec   (1 Hz / Load)      |<---+                       |
|                     |  u_icg_min   -> gated_clk_min   (1/60 Hz / Load)   |                            |
|                     |  u_icg_hour  -> gated_clk_hour  (1/3600 Hz / Load) |                            |
|                     |  u_icg_fsm   -> gated_clk_fsm   (Event / 1 Hz)     |                            |
|                     +----------------------------------------------------+                            |
|                                                                                                       |
|                     +----------------------------------------------------+                            |
|                     |                  button_debouncer                  |                            |
|   sel_in ---------->| [2-FF + 5-bit Counter @ 1kHz] -> sel_pulse --------|----+                       |
|   up_in ----------->| [2-FF + 5-bit Counter @ 1kHz] -> up_pulse ---------|--+ |                       |
|   down_in --------->| [2-FF + 5-bit Counter @ 1kHz] -> down_pulse -------|--+-+                       |
|                     +----------------------------------------------------+  | |                       |
|                                                                             | |                       |
|                     +----------------------------------------------------+  | |                       |
|                     |                  mode_controller                   |  | |                       |
|                     | (FSM + 5s Timeout + Time Edit Buffer: adj_hms)     |<-+ |                       |
|                     | load_en -----------------------+                   |    |                       |
|                     | adj_mode[1:0] ─────────┐       |                   |    |                       |
|                     | [adj_sec, adj_min, h] ─┼───────┼───────────────────┼──┐ |                       |
|                     +────────────────────────┼───────┼───────────────────┼──┼─+                       |
|                                              │       │                   │  │                         |
|                     +---------------------+  │       │  +--------------+ │  │                         |
|                     |   second_counter    |  │       +-─| load_en, val | │  │                         |
|                     | (Background 1 toggle/s)──s_cnt─┬─>|              | │  │                         |
|                     +---------------------+  │       │  |              | │  │                         |
|                                              │       │  |    output_   | │  │                         |
|                     +---------------------+  │       │  |    switch    | │  │                         |
|                     |   minute_counter    |  │       +-─|   (Display   | │  │                         |
|                     | (Background 1/60 Hz) ───m_cnt──┼─>|     MUX)     | │  │                         |
|                     +---------------------+  │       │  |              |<+  │                         |
|                                              │       │  |              |<───┘                         |
|                     +---------------------+  │       │  +--------------+                              |
|                     |    hour_counter     |  │       +-─| load_en, val |                              |
|                     | (Background 1/3600Hz)──h_cnt───┴─>| [s_out, m_out, h_out] ───────────────────>   |
|                     +---------------------+  └─────────>| (Chân ngõ ra Top)                           |
|                                                                                                       |
|   clk -------------> [Miền xung nhịp đơn đồng bộ 1 MHz toàn cục]                                      |
|   rstn ------------> [Reset bất đồng bộ tích cực mức thấp (Active-Low)]                               |
|   test_mode -------> [DFT / Scan Test Mode Bypass (ép ICG mở)]                                        |
+=======================================================================================================+
```

---

## 3. Bảng So sánh Định lượng Công suất Chân Clock

| Module / Flip-Flop | Tần số CLK Trước ICG | Tần số CLK Sau ICG (v2.3.0) | Mức độ Triệt tiêu Năng lượng Chân Clock |
| :--- | :---: | :---: | :---: |
| **`second_counter` (6 FFs)** | 1,000,000 Hz | **1 Hz** | **Giảm 99.9999%** |
| **`minute_counter` (6 FFs)** | 1,000,000 Hz | **0.0167 Hz (1/60 Hz)** | **Giảm 99.99998%** |
| **`hour_counter` (5 FFs)** | 1,000,000 Hz | **0.00028 Hz (1/3600 Hz)** | **Giảm 99.999999%** |
| **`button_debouncer` (15 FFs)** | 1,000,000 Hz | **1,000 Hz** | **Giảm 99.9%** |
| **`clk_prescaler` Stage 2 (10 FFs)**| 1,000,000 Hz | **1,000 Hz** | **Giảm 99.9%** |

---

## 4. Hướng dẫn Chạy Mô phỏng (Simulation & Verification)

### Biên dịch và Chạy Testbench với QuestaSim:
```bash
# Biên dịch toàn bộ RTL (gồm output_switch.sv & icg_cell.sv) và Testbench
make compile

# Chạy mô phỏng batch và xuất scorecard
make sim

# Chạy mô phỏng thu thập Code & Functional Coverage
make cov

# Mở giao diện sóng QuestaSim Waveform GUI
make wave

# Dọn dẹp môi trường
make clean
```

---

## 5. Kết quả Kiểm chứng Toàn diện (Verification Scorecard)

```text
================================================================================
                   VERIFICATION SCORECARD & SUMMARY REPORT                      
================================================================================
 TOTAL ASSERTIONS & CHECKS RUN : 90
 TOTAL PASSED CHECKS           : 90
 TOTAL FAILED CHECKS           : 0
--------------------------------------------------------------------------------
 >>> VERIFICATION STATUS: 100% PASSED (TAPE-OUT READY QUALITY) <<< 
================================================================================
```
