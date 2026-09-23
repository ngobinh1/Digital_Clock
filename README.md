# Hour-Minute-Second Timer (`HMS_Timer`) IP Core & Verification Environment (v1.1.0)

[![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Verilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![EDA](https://img.shields.io/badge/Simulator-QuestaSim%20%2F%20VCS%20%2F%20Verilator-green.svg)]()
[![Status](https://img.shields.io/badge/Verification-100%25%20PASSED-brightgreen.svg)]()
[![Assertions](https://img.shields.io/badge/SVA-100%25%20PASS-success.svg)]()

IP Core bộ đếm thời gian thực **Giờ - Phút - Giây (Hour-Minute-Second Timer)** chuẩn công nghiệp bán dẫn, thiết kế hoàn toàn bằng ngôn ngữ phần cứng **SystemVerilog/Verilog Synthesizable** và được kiểm chứng toàn diện với môi trường **SystemVerilog Verification Environment** (Interface, Clocking Blocks, Driver, Golden Model Scoreboard, Functional Coverage, SystemVerilog Assertions).

Phiên bản **v1.1.0** tích hợp:
- **Khử rung nút bấm chuyên dụng 20ms (`20ms Button Debouncing & Auto-Repeat`)**: Cần giữ nút $20\text{ ms}$ mới kích hoạt 1 lần, sau đó tự động tính lại $20\text{ ms}$ từ đầu để auto-repeat.
- **Tự động hủy thay đổi & Thoát về Run sau 5 giây không thao tác (`5s Inactivity Timeout & Rollback`)**: Treo ở bất kỳ mode chỉnh sửa nào quá $5\text{s}$ không bấm phím sẽ tự động rollback thời gian về snapshot ban đầu và quay về `MODE_RUN`.

---

## 1. Cấu trúc thư mục dự án (Directory Structure)

```text
HMS_Timer/
├── README.md                  # Tài liệu hướng dẫn sử dụng và báo cáo kiểm chứng
├── Makefile                   # Build script cho QuestaSim / VCS / Verilator
├── docs/                      # Tài liệu thiết kế đặc tả kiến trúc
│   └── SPECIFICATION.md       # Đặc tả thiết kế RTL chi tiết chuẩn Spec-First (v1.1.0)
├── rtl/                       # Mã nguồn RTL Synthesizable
│   ├── button_debouncer.sv    # Khối đồng bộ 2-FF & Khử rung 20ms có Auto-repeat
│   ├── prescaler_1hz.sv       # Bộ chia tần số 1MHz -> 1Hz
│   ├── mode_controller.sv     # FSM điều khiển 4 chế độ & Timeout 5s Inactivity
│   ├── second_counter.sv      # Bộ đếm Giây Modulo-60 & Snapshot Rollback
│   ├── minute_counter.sv      # Bộ đếm Phút Modulo-60 & Snapshot Rollback
│   ├── hour_counter.sv        # Bộ đếm Giờ Modulo-24 & Snapshot Rollback
│   └── hms_timer.sv           # Top-level IP Core
├── tb/                        # Môi trường kiểm chứng SystemVerilog
│   ├── hms_timer_types_pkg.sv # Package định nghĩa kiểu dữ liệu, enum, loggers
│   ├── hms_timer_if.sv        # Interface chứa Clocking blocks & SVA Assertions
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
|                                           TOP: hms_timer                                              |
|                                                                                                       |
|                     +----------------------------------------------------+                            |
|                     |                  button_debouncer                  |                            |
|   sel_in ---------->| [2-FF + 20ms Counter + Auto-repeat] -> sel_pulse -+|-------+                    |
|   up_in ----------->| [2-FF + 20ms Counter + Auto-repeat] -> up_pulse --+|----+  |                    |
|   down_in --------->| [2-FF + 20ms Counter + Auto-repeat] -> down_pulse -+|--+ |  |                    |
|                     +----------------------------------------------------+  | |  |                    |
|                                                                             | |  |                    |
|                     +-------------------------------+                       | |  |                    |
|                     |        mode_controller        |                       | |  |                    |
|                     | (FSM 4 States + 5s Timer)     |<----------------------+ |  |                    |
|                     | cancel_pulse -----------------|----+                    |  |                    |
|                     | adj_mode[1:0] ----------------|--+ |                    |  |                    |
|                     +---------------+---------------+  | |                    |  |                    |
|                                     ^                  | |                    |  |                    |
|                     +---------------+-----+            | |                    |  |                    |
|                     |    prescaler_1hz    |            | |                    |  |                    |
|                     | sec_tick -----------|---+        | |                    |  |                    |
|                     +---------------------+   |        | |                    |  |                    |
|                                               |        | |                    |  |                    |
|                     +---------------------+   |        | |                    |  |                    |
|                     |   second_counter    |   |        | |                    |  |                    |
|                     | (Mod-60 + Snapshot) |<--+<-------+<+<-------------------+--+                    |
|                     | s_out[5:0] ---------|---|--------|-|----------------------------> s_out[5:0]    |
|                     | sec_rollover -------|---|---+    | |                                            |
|                     +---------------------+   |   |    | |                                            |
|                                               |   |    | |                                            |
|                     +---------------------+   |   |    | |                                            |
|                     |   minute_counter    |   |   |    | |                                            |
|                     | (Mod-60 + Snapshot) |<--+   |<---+<+<-------------------+--+                    |
|                     | m_out[5:0] ---------|---|---|----|-|----------------------------> m_out[5:0]    |
|                     | min_rollover -------|---|---|----+ |                                            |
|                     +---------------------+   |   |    | |                                            |
|                                               |   |    | |                                            |
|                     +---------------------+   |   |    | |                                            |
|                     |    hour_counter     |   |   |    | |                                            |
|                     | (Mod-24 + Snapshot) |<--+   |    |<+<-------------------+--+                    |
|                     | h_out[4:0] ---------|---|---|----|-|----------------------------> h_out[4:0]    |
|                     +---------------------+   |   |    | |                                            |
|                                                                                                       |
|   clk -------------> [Miền xung nhịp đơn đồng bộ 1 MHz toàn cục]                                      |
|   rstn ------------> [Reset bất đồng bộ tích cực mức thấp (Active-Low)]                               |
+=======================================================================================================+
```

### Điểm nổi bật trong thiết kế RTL:
1. **Khử rung 20ms & Chống Metastability:** Tín hiệu nút bấm đi qua 2-FF đồng bộ và bộ đếm $20\text{ ms}$. Cần giữ đủ $20\text{ ms}$ mới phát 1 xung; sau đó đếm lại $20\text{ ms}$ từ đầu nếu tiếp tục giữ phím (Auto-repeat).
2. **Inactivity Timeout 5s & Rollback Hủy Thay Đổi:** Ở các chế độ chỉnh sửa, nếu sau 5 giây liên tục không bấm phím nào, FSM tự động đưa hệ thống về `MODE_RUN` và hoàn tác (Rollback) lại thời gian ban đầu thông qua các thanh ghi Snapshot.
3. **Single Clock Domain:** Toàn bộ hệ thống chạy trên 1 xung nhịp `clk` duy nhất (không dùng ripple clock).
4. **Cơ chế Rollover Gating:** Khi ở các chế độ điều chỉnh thời gian (Adjust Modes), cờ `sec_rollover` và `min_rollover` được khóa cứng về `0`.
5. **Wrap-Around 2 chiều:**
   - Giây: $0 \to 1 \dots 59 \to 0$ (Up) | $0 \to 59 \dots 1 \to 0$ (Down)
   - Phút: $0 \to 1 \dots 59 \to 0$ (Up) | $0 \to 59 \dots 1 \to 0$ (Down)
   - Giờ: $0 \to 1 \dots 23 \to 0$ (Up) | $0 \to 23 \dots 1 \to 0$ (Down)
6. **Chống xung đột nút bấm:** Khi `up_in` và `down_in` bị nhấn đồng thời trong cùng 1 chu kỳ, mạch tự động giữ nguyên giá trị (Hold state).

---

## 3. Hướng dẫn Biên dịch & Chạy mô phỏng (How to Build & Run)

### 3.1 Biên dịch và Chạy mô phỏng dòng lệnh (QuestaSim / VCS / Verilator)
```bash
# Biên dịch và chạy toàn bộ testsuite
make all

# Hoặc từng bước:
make compile
make sim
```

### 3.2 Chạy mô phỏng xem dạng sóng Waveform (GUI Mode)
```bash
make wave
```

### 3.3 Thu thập & Báo cáo Coverage
```bash
make cov
```
Báo cáo HTML sẽ được tự động tạo tại thư mục `sim/cov_html/index.html`.
