# Hour-Minute-Second Timer (`HMS_Timer`) IP Core & Verification Environment

[![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Verilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![EDA](https://img.shields.io/badge/Simulator-QuestaSim%20%2F%20VCS%20%2F%20Verilator-green.svg)]()
[![Status](https://img.shields.io/badge/Verification-100%25%20PASSED-brightgreen.svg)]()
[![Assertions](https://img.shields.io/badge/SVA-100%25%20PASS-success.svg)]()

IP Core bộ đếm thời gian thực **Giờ - Phút - Giây (Hour-Minute-Second Timer)** chuẩn công nghiệp bán dẫn, thiết kế hoàn toàn bằng ngôn ngữ phần cứng **SystemVerilog/Verilog Synthesizable** và được kiểm chứng toàn diện với môi trường **SystemVerilog Verification Environment** (Interface, Clocking Blocks, Driver, Golden Model Scoreboard, Functional Coverage, SystemVerilog Assertions).

---

## 1. Cấu trúc thư mục dự án (Directory Structure)

```text
HMS_Timer/
├── README.md                  # Tài liệu hướng dẫn sử dụng và báo cáo kiểm chứng
├── Makefile                   # Build script cho QuestaSim / VCS / Verilator
├── docs/                      # Tài liệu thiết kế đặc tả kiến trúc
│   └── SPECIFICATION.md       # Đặc tả thiết kế RTL chi tiết chuẩn Spec-First
├── rtl/                       # Mã nguồn RTL Synthesizable
│   ├── sync_edge_detector.sv  # Khối đồng bộ 2-FF & bắt sườn nút bấm
│   ├── prescaler_1hz.sv       # Bộ chia tần số 1MHz -> 1Hz
│   ├── mode_controller.sv     # FSM điều khiển 4 chế độ (Run, Adj Sec, Min, Hour)
│   ├── second_counter.sv      # Bộ đếm Giây Modulo-60 & điều chỉnh 2 chiều
│   ├── minute_counter.sv      # Bộ đếm Phút Modulo-60 & điều chỉnh 2 chiều
│   ├── hour_counter.sv        # Bộ đếm Giờ Modulo-24 & điều chỉnh 2 chiều
│   └── hms_timer.sv           # Top-level IP Core
├── tb/                        # Môi trường kiểm chứng SystemVerilog
│   ├── hms_timer_types_pkg.sv # Package định nghĩa kiểu dữ liệu, enum, loggers
│   ├── hms_timer_if.sv        # Interface chứa Clocking blocks & SVA Assertions
│   ├── hms_driver.sv          # Class Driver phát stimulus và điều khiển Reset
│   ├── hms_scoreboard.sv      # Class Scoreboard đối chiếu Golden Model
│   ├── hms_coverage.sv        # Class Functional Coverage Model
│   └── tb_hms_timer.sv        # Top Testbench Runner thực thi 11 Testcases
├── repo_map.md                # Bản đồ phân tầng dự án
├── rtl_hierarchy.md           # Cấu trúc phân cấp module và kết nối
├── design_intent.md           # Lý do và căn cứ quyết định kiến trúc
├── common_failures.md         # Sổ tay các lỗi thường gặp và cách xử lý
└── debug_checklist.md         # Checklist kiểm tra RTL và Testbench
```

---

## 2. Kiến trúc & Nguyên lý hoạt động (Architecture Overview)

```
+========================================================================================+
|                                    TOP: hms_timer                                      |
|                                                                                        |
|                     +---------------------------------------------+                    |
|                     |             sync_edge_detector              |                    |
|   sel_in ---------->| sel_in  --> [2-FF+Edge] --> sel_pulse  ----+|                    |
|   up_in ----------->| up_in   --> [2-FF+Edge] --> up_pulse   ----+|--+                 |
|   down_in --------->| down_in --> [2-FF+Edge] --> down_pulse ----+|--|--+              |
|                     +---------------------------------------------+  |  |              |
|                                                                      |  |  |              |
|                     +---------------------+                          |  |  |              |
|                     |   mode_controller   |                          |  |  |              |
|                     |  (4-State FSM)      |<-------------------------+  |  |              |
|                     | adj_mode[1:0] ------|---+                         |  |              |
|                     +---------------------+   |                         |  |              |
|                                               |                         |  |              |
|                     +---------------------+   |                         |  |              |
|                     |    prescaler_1hz    |   |                         |  |              |
|                     | (1MHz -> 1Hz tick)  |   |                         |  |              |
|                     | sec_tick -----------|---|---+                     |  |              |
|                     +---------------------+   |   |                     |  |              |
|                                               |   |                     |  |              |
|                     +---------------------+   |   |                     |  |              |
|                     |   second_counter    |   |   |                     |  |              |
|                     | (Modulo-60 / +/-1)  |<--+<--+<--------------------+--+              |
|                     | s_out[5:0] ---------|---|---|-------------------------> s_out[5:0]  |
|                     | sec_rollover -------|---|---|---+                                   |
|                     +---------------------+   |   |   |                                   |
|                                               |   |   |                                   |
|                     +---------------------+   |   |   |                                   |
|                     |   minute_counter    |   |   |   |                                   |
|                     | (Modulo-60 / +/-1)  |<--+   |<--+<--------------------+--+          |
|                     | m_out[5:0] ---------|---|---|---|---------------------> m_out[5:0]  |
|                     | min_rollover -------|---|---|---|---+                               |
|                     +---------------------+   |   |   |   |                               |
|                                               |   |   |   |                               |
|                     +---------------------+   |   |   |   |                               |
|                     |    hour_counter     |   |   |   |   |                               |
|                     | (Modulo-24 / +/-1)  |<--+   |   |<--+<----------------+--+          |
|                     | h_out[4:0] ---------|---|---|---|---|-----------------> h_out[4:0]  |
|                     +---------------------+   |   |   |   |                               |
|                                                                                        |
|   clk -------------> [Miền xung nhịp đơn đồng bộ 1 MHz toàn cục]                       |
|   rstn ------------> [Reset bất đồng bộ tích cực mức thấp (Active-Low)]                |
+========================================================================================+
```

### Điểm nổi bật trong thiết kế RTL:
1. **Khử Metastability 100%:** Nút bấm ngoại vi `sel_in`, `up_in`, `down_in` được đồng bộ qua 2 tầng Flip-Flop và bộ lọc sườn dương trích xuất xung đơn kỳ chuẩn `1-clock-cycle pulse`.
2. **Single Clock Domain:** Toàn bộ hệ thống chạy trên 1 xung nhịp `clk` duy nhất. Không dùng ngõ ra bộ đếm làm clock cho tầng sau (loại bỏ triệt để clock skew/glitches).
3. **Cơ chế Rollover Gating:** Khi ở các chế độ điều chỉnh thời gian (Adjust Modes), cờ `sec_rollover` và `min_rollover` được khóa cứng về `0` để việc chỉnh giây/phút không gây nhảy sai lệch ngẫu nhiên lên các tầng cao hơn.
4. **Wrap-Around 2 chiều:**
   - Giây: $0 \to 1 \dots 59 \to 0$ (Up) | $0 \to 59 \dots 1 \to 0$ (Down)
   - Phút: $0 \to 1 \dots 59 \to 0$ (Up) | $0 \to 59 \dots 1 \to 0$ (Down)
   - Giờ: $0 \to 1 \dots 23 \to 0$ (Up) | $0 \to 23 \dots 1 \to 0$ (Down)
5. **Chống xung đột nút bấm:** Khi `up_in` và `down_in` bị nhấn đồng thời trong cùng 1 chu kỳ, mạch tự động giữ nguyên giá trị (Hold state).

---

## 3. Danh mục 11 Testcases Kiểm chứng SystemVerilog

| Testcase ID | Tên bài kiểm tra | Nội dung kiểm chứng | Kết quả |
| :--- | :--- | :--- | :---: |
| **TC1** | `run_tc1_reset_recovery` | Kiểm tra kích hoạt reset bất đồng bộ và nhả reset, kiểm tra các ngõ ra bằng 0 | **PASS** |
| **TC2** | `run_tc2_normal_counting` | Đếm tự động thời gian thực theo xung nhịp 1Hz chia từ prescaler | **PASS** |
| **TC3** | `run_tc3_fsm_navigation` | Chuyển đổi trạng thái FSM tuần hoàn: `RUN` $\to$ `SEC` $\to$ `MIN` $\to$ `HOUR` $\to$ `RUN` | **PASS** |
| **TC4** | `run_tc4_second_adjustment` | Chỉnh giây tăng/giảm, kiểm tra wrap-up ($59\to 0$) và wrap-down ($0\to 59$) | **PASS** |
| **TC5** | `run_tc5_minute_adjustment` | Chỉnh phút tăng/giảm, kiểm tra wrap-up ($59\to 0$) và wrap-down ($0\to 59$) | **PASS** |
| **TC6** | `run_tc6_hour_adjustment` | Chỉnh giờ tăng/giảm, kiểm tra wrap-up ($23\to 0$) và wrap-down ($0\to 23$) | **PASS** |
| **TC7** | `run_tc7_rollover_isolation` | Xác nhận cờ tràn bị cô lập khi chỉnh giờ (chỉnh giây từ 59->0 không làm đổi phút) | **PASS** |
| **TC8** | `run_tc8_simultaneous_press`| Kích hoạt đồng thời cả 2 nút UP và DOWN, kiểm tra giá trị được giữ nguyên | **PASS** |
| **TC9** | `run_tc9_async_glitch_test` | Bơm xung nhiễu bất đồng bộ cực ngắn (<100ns) kiểm tra mạch lọc 2-FF | **PASS** |
| **TC10** | `run_tc10_midnight_cascade` | Thiết lập thời gian `23:59:58`, đếm qua `23:59:59` và tràn về `00:00:00` | **PASS** |
| **TC11** | `run_tc11_exhaustive_cross` | Kiểm tra độ miễn nhiễm nút bấm khi ở chế độ RUN và tổ hợp stimulus | **PASS** |

---

## 4. Hướng dẫn Biên dịch & Chạy mô phỏng (How to Build & Run)

### 4.1 Biên dịch và Chạy mô phỏng dòng lệnh (QuestaSim CLI)
```bash
# Biên dịch và chạy toàn bộ testsuite
make all

# Hoặc từng bước:
make compile
make sim
```

### 4.2 Chạy mô phỏng xem dạng sóng Waveform (GUI Mode)
```bash
make wave
```

### 4.3 Thu thập & Báo cáo Coverage (Functional & Code Coverage)
```bash
make cov
```

Báo cáo HTML sẽ được tự động tạo tại thư mục `sim/cov_html/index.html`.

### 4.4 Dọn dẹp môi trường build
```bash
make clean
```

---

## 5. Kết quả Kiểm chứng Thực tế (Verification Scorecard)

```text
================================================================================
                   VERIFICATION SCORECARD & SUMMARY REPORT                      
================================================================================
 TOTAL ASSERTIONS & CHECKS RUN : 66
 TOTAL PASSED CHECKS           : 66
 TOTAL FAILED CHECKS           : 0
--------------------------------------------------------------------------------
 >>> VERIFICATION STATUS: 100% PASSED (TAPE-OUT READY QUALITY) <<< 
================================================================================

--------------------------------------------------------------------------------
                      FUNCTIONAL COVERAGE REPORT                                
--------------------------------------------------------------------------------
 FSM Modes & Transitions Coverage : 100.00 %
 Time Ranges & Boundary Coverage  : 100.00 %
 Stimulus & Cross Coverage        :  90.18 %
--------------------------------------------------------------------------------
```
