# Hour-Minute-Second Timer (`HMS_Timer`) IP Core & Verification Environment (Universal Synchronous Architecture)

[![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Verilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![EDA](https://img.shields.io/badge/Simulator-QuestaSim%20%2F%20VCS%20%2F%20Verilator-green.svg)]()
[![Status](https://img.shields.io/badge/Verification-100%25%20PASSED-brightgreen.svg)]()
[![Assertions](https://img.shields.io/badge/SVA-100%25%20PASS-success.svg)]()
[![Clock](https://img.shields.io/badge/Clock-Single%20Synchronous%20Domain%20(1MHz)-blue.svg)]()
[![Debounce](https://img.shields.io/badge/Debouncer-%C2%B110%25%20Tolerance%20(18--22ms)-blueviolet.svg)]()
[![Architecture](https://img.shields.io/badge/Architecture-Decoupled%20Buffer%20%2B%20MUX-brightgreen.svg)]()

IP Core bộ đếm thời gian thực **Giờ - Phút - Giây (Hour-Minute-Second Timer)** chuẩn công nghiệp bán dẫn, thiết kế hoàn toàn bằng ngôn ngữ phần cứng **SystemVerilog Synthesizable** và được kiểm chứng toàn diện với môi trường **SystemVerilog Verification Environment** (Interface, Clocking Blocks, Driver, Golden Model Scoreboard, Functional Coverage, SystemVerilog Assertions).

**Universal Synchronous Architecture** chuẩn hóa kiến trúc **Đơn miền xung nhịp thuần túy với Bộ tạo xung cho phép (Single-Clock Synchronous with Native Clock Enable / Tick Generator)** kết hợp **Tách biệt Bộ Đệm Chỉnh Giờ & Chuyển Mạch Hiển Thị (`output_switch`)**:
- **Đơn miền xung nhịp đồng bộ 1 MHz toàn cục (Single Clock Domain):**
  * Toàn bộ Flip-Flop trong chip chạy đồng nhất trên 1 xung nhịp gốc 1 MHz. Không tạo ra clock con, không có ripple clock, triệt tiêu 100% nguy cơ Clock Domain Crossing (CDC), Clock Skew và Hold Violations.
  * Tối ưu hoàn hảo cho cả **FPGA** (dùng 1 bộ đệm `BUFG` duy nhất, map vào chân `CE` của slice `FDRE`) và **ASIC** (tương thích 100% tính năng Automatic Clock Gating của Synopsys Design Compiler / Cadence Genus).
- **Bộ Đồng Bộ Hóa Reset (`reset_sync` - 2-Stage D-FF):**
  * Đồng bộ hóa tín hiệu reset thô bất đồng bộ ngoại vi theo sườn dương xung nhịp 1 MHz.
  * Triệt tiêu hoàn toàn vi phạm Recovery/Removal Time và chống hiện tượng bất ổn định (Metastability) toàn chip.
- **Khối Chuyển Mạch Hiển Thị Chuyên Dụng (`output_switch`)**:
  * Khi ở chế độ chỉnh sửa (`MODE_ADJ_*`), các ngõ ra hiển thị trực tiếp giá trị từ bộ đệm chỉnh sửa (`mode_controller`) giúp người dùng theo dõi trực quan và tức thời.
  * Khi ở chế độ đếm thời gian thực (`MODE_RUN`), các ngõ ra hiển thị giá trị từ các bộ đếm nền thời gian thực.
- **Bộ Đếm Nền Liên Tục Chuẩn Xác (Zero-Drift Background Clock)**:
  * Các khối `second_counter`, `minute_counter`, `hour_counter` đếm thời gian thực liên tục 24/7 ở chế độ nền. Không bị dừng hay trôi thời gian khi người dùng đang thao tác trong menu.
  * Loại bỏ hoàn toàn các thanh ghi bóng (shadow snapshot registers), tiết kiệm Flip-Flops và cổng logic.
- **Nạp Song Song Đồng Bộ Khi Xác Nhận (Commit on Loop Exit)**:
  * Khi người dùng duyệt hết chu trình chỉnh giờ (`ADJ_HOUR` -> `MODE_RUN`), `mode_controller` phát xung 1-cycle `load_en = 1`, nạp song song toàn bộ thời gian đã chỉnh vào các bộ đếm.
- **Hủy Bỏ & Khôi Phục Hiển Thị Tự Động Sau 5s (5s Inactivity Timeout)**:
  * Nếu người dùng không thao tác phím trong 5s, FSM tự động quay về `MODE_RUN` với `load_en = 0` (hủy bỏ bộ đệm), bộ MUX tự động chuyển lại hiển thị bộ đếm nền đang chạy chuẩn xác.
- **Khử rung nút bấm chuyên dụng 20ms với Dung sai ±10% (`1kHz-Sampled 20ms ±10% Debounce & Auto-Repeat`)**:
  * Tần số lấy mẫu: 1 kHz (1 ms qua `tick_1khz`). Dải dung sai: 18 ms .. 22 ms.

---

## 1. Cấu trúc thư mục dự án (Directory Structure)

```text
HMS_Timer/
├── README.md                  # Tài liệu hướng dẫn sử dụng và báo cáo kiểm chứng
├── Makefile                   # Build script cho QuestaSim / VCS / Verilator
├── docs/                      # Tài liệu thiết kế đặc tả kiến trúc
│   ├── SPECIFICATION.md       # Đặc tả thiết kế RTL chi tiết chuẩn Spec-First
│   └── SPECIFICATION.docx     # Tài liệu Word báo cáo kiến trúc và giản đồ
├── rtl/                       # Mã nguồn RTL Synthesizable (Universal Synchronous Architecture)
│   ├── reset_sync.sv          # Khối đồng bộ hóa reset 2-FF chống Metastability
│   ├── clk_prescaler.sv       # Bộ chia tần tạo xung chuẩn 1MHz -> tick_1kHz -> sec_tick (1Hz)
│   ├── button_debouncer.sv    # Khối đồng bộ 2-FF & Khử rung 20ms ±10% Tol với Clock Enable 1kHz
│   ├── button_controller.sv   # Quản lý 3 nút bấm & Căn xung 1 MHz đồng bộ
│   ├── mode_controller.sv     # FSM điều khiển 4 chế độ, bộ đệm chỉnh giờ & Timeout 5s
│   ├── second_counter.sv      # Bộ đếm Giây Modulo-60 nền & Synchronous Load
│   ├── minute_counter.sv      # Bộ đếm Phút Modulo-60 nền & Synchronous Load
│   ├── hour_counter.sv        # Bộ đếm Giờ Modulo-24 nền & Synchronous Load
│   ├── output_switch.sv       # Bộ chuyển mạch đa hợp hiển thị tổ hợp (Display MUX)
│   └── hms_timer.sv           # Top-level IP Core thuần kết nối cấu trúc (Pure Structural)
├── tb/                        # Môi trường kiểm chứng SystemVerilog
│   ├── hms_timer_types_pkg.sv # Package định nghĩa kiểu dữ liệu, enum, loggers
│   ├── hms_timer_if.sv        # Interface chứa Clocking blocks, probe signals & SVA
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

## 2. Sơ đồ khối kiến trúc kết nối Tổng quan

```text
+======================================= [ hms_timer.sv ] ==============================================+
|                                                                                                       |
|                     +----------------------------------------------------+                            |
|   sel_in ---------->|                 button_controller                  |                            |
|   up_in ----------->| (3x button_debouncer 20ms ±10% sampled on tick_1k) |                            |
|   down_in --------->| -> sel_pulse, up_pulse, down_pulse ----------------+--+                         |
|                     +----------------------------------------------------+  |                         |
|                                                                             |                         |
|                     +----------------------------------------------------+  |                         |
|                     |                  mode_controller                   |  |                         |
|                     | (FSM + 5s Timeout + Time Edit Buffer: adj_hms)     |<-+                         |
|                     | load_en -----------------------+                   |                            |
|                     | adj_mode[1:0] ─────────┐       |                   |                            |
|                     | [adj_sec, adj_min, h] ─┼───────┼───────────────────┼──┐                         |
|                     +────────────────────────┼───────┼───────────────────┼──┼─+                       |
|                                              │       │                   │  │                         |
|                     +---------------------+  │       │  +--------------+ │  │                         |
|                     |   second_counter    |  │       +-─| load_en, val | │  │                         |
|                     | (Background Mod-60) ───s_cnt───┬─>|              | │  │                         |
|                     +---------------------+  │       │  |              | │  │                         |
|                                              │       │  |    output_   | │  │                         |
|                     +---------------------+  │       │  |    switch    | │  │                         |
|                     |   minute_counter    |  │       +-─|   (Display   | │  │                         |
|                     | (Background Mod-60) ───m_cnt───┼─>|     MUX)     | │  │                         |
|                     +---------------------+  │       │  |              |<+  │                         |
|                                              │       │  |              |<───┘                         |
|                     +---------------------+  │       │  +--------------+                              |
|                     |    hour_counter     |  │       +-─| load_en, val |                              |
|                     | (Background Mod-24) ───h_cnt───┴─>| [s_out, m_out, h_out] ───────────────────>   |
|                     +---------------------+  └─────────>| (Chân ngõ ra Top)                           |
|                                                                                                       |
|   clk -------------> [Miền xung nhịp đơn đồng bộ 1 MHz toàn cục]                                      |
|   rstn ------------> [Reset tích cực mức thấp (Active-Low), qua 2-FF synchronizer]                    |
+=======================================================================================================+
```

---

## 3. Hướng dẫn Chạy Mô phỏng (Simulation & Verification)

### Biên dịch và Chạy Testbench với QuestaSim:
```bash
# Biên dịch toàn bộ RTL và Testbench
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

## 4. Kết quả Kiểm chứng Toàn diện (Verification Scorecard)

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
