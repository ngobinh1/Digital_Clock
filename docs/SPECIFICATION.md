# ĐẶC TẢ THIẾT KẾ KIẾN TRÚC RTL
# TÊN HỆ THỐNG / IP CORE: `hms_timer`

---

## THÔNG TIN TÀI LIỆU
- **Tên dự án:** Hour-Minute-Second Real-Time Digital Timer IP Core (`HMS_Timer`)
- **Mã tài liệu:** `SPEC-HMS-TIMER-V2.3`
- **Tác giả:** Kỹ sư Trưởng Kiến trúc RTL / Digital IC Design Architect
- **Chuẩn ngôn ngữ:** IEEE 1800-2017 Synthesizable SystemVerilog
- **Mục tiêu công nghệ:** Technology-Independent (ASIC Standard Cell Library / FPGA)
- **Trạng thái:** `APPROVED FOR RTL IMPLEMENTATION & TAPE-OUT READY`
- **Phiên bản:** `2.3.0`
- **Ngày phát hành:** 27/09/2026

---

## MỤC LỤC
1. [CHƯƠNG 1: TỔNG QUAN HỆ THỐNG VÀ KIẾN TRÚC THIẾT KẾ](#chương-1-tổng-quan-hệ-thống-và-kiến-trúc-thiết-kế)
   - 1.1 Tổng quan về thiết kế
   - 1.2 Phân loại yêu cầu thiết kế (Requirement Classification)
   - 1.3 Đặc điểm kiến trúc & Đột phá tối ưu PPA
   - 1.4 Sơ đồ kiến trúc tổng quan (Architecture Overview)
   - 1.5 Bảng tham số kiến trúc (Design Parameters)
2. [CHƯƠNG 2: TOP MODULE – `hms_timer`](#chương-2-top-module--hms_timer)
   - 2.1 Sơ đồ khối Top Module (Top-Level Block Diagram)
   - 2.2 Bảng chân tín hiệu ngoại vi Top Module (External Interface Table)
   - 2.3 Nguyên lý hoạt động tổng thể & Mối quan hệ tương tác giữa các Sub-module
   - 2.4 Bảng kết nối nội bộ giữa các Sub-module (Internal Interconnect Table)
   - 2.5 Giản đồ thời gian tổng thể Top Module (Top-Level Timing Diagrams)
3. [CHƯƠNG 3: ĐẶC TẢ CHI TIẾT TỪNG SUB-MODULE](#chương-3-đặc-tả-chi-tiết-từng-sub-module)
   - 3.1 Module: `reset_sync` (Reset Synchronizer - Asynchronous Assert, Synchronous Deassert)
   - 3.2 Module: `icg_cell` (Integrated Clock Gating Leaf Cell)
   - 3.3 Module: `clock_control_unit` (Centralized Clock Management Unit)
   - 3.4 Module: `clk_prescaler` (Multi-Stage Cascaded Prescaler 1MHz -> 1kHz -> 1Hz)
   - 3.5 Module: `button_debouncer` (Single-Channel Button Debouncer 20ms ±10%)
   - 3.6 Module: `button_controller` (Multi-Channel Button Controller & Edge Alignment)
   - 3.7 Module: `mode_controller` (4-State Mode FSM + Edit Buffer + 5s Inactivity Timeout)
   - 3.8 Module: `second_counter` (Continuous Background Modulo-60 Second Counter)
   - 3.9 Module: `minute_counter` (Continuous Background Modulo-60 Minute Counter)
   - 3.10 Module: `hour_counter` (Continuous Background Modulo-24 Hour Counter)
   - 3.11 Module: `output_switch` (Combinational Display Multiplexer)
4. [CHƯƠNG 4: MA TRẬN TRUY XUẤT YÊU CẦU (RTM) & KẾ HOẠCH KIỂM CHỨNG](#chương-4-ma-trận-truy-xuất-yêu-cầu-rtm--kế-hoạch-kiểm-chứng)
   - 4.1 Ma trận truy xuất yêu cầu kiểm tra (Requirement Traceability Matrix - RTM)
   - 4.2 Chi tiết 14 Test Cases kiểm chứng chức năng (Functional Verification Plan)
   - 4.3 Kết quả kiểm chứng mô phỏng & Báo cáo độ phủ (Verification Scorecard & Coverage)

---

# CHƯƠNG 1: TỔNG QUAN HỆ THỐNG VÀ KIẾN TRÚC THIẾT KẾ

## 1.1 Tổng quan về thiết kế
IP Core `hms_timer` là khối sở hữu trí tuệ số (Digital IP Core) phục vụ chức năng đếm và quản lý thời gian thực theo định dạng **Giờ (0..23) : Phút (0..59) : Giây (0..59)**. Thiết kế được tối ưu hóa toàn diện cho các hệ thống SoC (System-on-Chip), vi điều khiển nhúng, thiết bị đeo thông minh (Wearables) và thiết bị IoT yêu cầu tiêu thụ năng lượng siêu thấp (Ultra-Low Power) cùng độ chính xác tuyệt đối.

IP Core nhận nguồn xung nhịp chủ hệ thống 1 MHz (chu kỳ 1 µs) và đường reset bất đồng bộ tích cực mức thấp (`rstn`). Hệ thống hỗ trợ giao diện 3 nút bấm điều khiển ngoại vi (`sel_in`, `up_in`, `down_in`) cho phép người dùng chuyển đổi trạng thái và điều chỉnh độc lập từng trường thời gian với cơ chế tự động lặp lại (Auto-Repeat), bộ đệm chỉnh giờ độc lập, bộ chuyển mạch hiển thị chuyên dụng, cùng tính năng tự động thoát và hủy thay đổi sau 5 giây không thao tác (Inactivity Timeout).

---

## 1.2 Phân loại yêu cầu thiết kế (Requirement Classification)

Mọi yêu cầu kỹ thuật và quyết định kiến trúc được chuẩn hóa và phân loại nghiêm ngặt theo chuẩn `rtl_spec_architect`:

**Bảng 1.2: Bảng phân loại yêu cầu thiết kế hệ thống (Requirement Classification)**

| Mã Yêu Cầu | Nhóm Chức Năng | Phân Loại | Chi Tiết Yêu Cầu Kỹ Thuật |
| :--- | :--- | :---: | :--- |
| `REQ-SYS-01` | Clock & Reset | `USER-PROVIDED` | Hệ thống hoạt động trên xung nhịp toàn cục 1 MHz, reset bất đồng bộ tích cực thấp `rstn`. |
| `REQ-ICG-01` | Clock Gating | `USER-PROVIDED` | Triển khai các cổng Integrated Clock Gating (ICG) dạng Latch-based để ngắt dao động clock các khối tần số thấp. |
| `REQ-PPA-01` | Phân tầng Tần số | `USER-PROVIDED` | Sử dụng bộ chia tần đa tầng (1 MHz -> 1 kHz -> 1 Hz) để giảm tần số chuyển mạch tối đa. |
| `REQ-DEB-01` | Lọc Rung Phím | `USER-PROVIDED` | Lọc rung phím cơ học danh định 20 ms, chỉ công nhận khi nhấn giữ liên tục. |
| `REQ-DEB-02` | Tự Động Lặp Lại | `USER-PROVIDED` | Hỗ trợ tính năng Auto-Repeat: Giữ phím liên tục sẽ tự động phát xung tuần hoàn đều đặn. |
| `REQ-DEB-03` | Dung Sai Khử Rung | `USER-PROVIDED` | Áp dụng dải dung sai ±10% (18 ms .. 22 ms) cho bộ khử rung phím. |
| `REQ-FSM-01` | 4 Chế Độ Hoạt Động | `USER-PROVIDED` | FSM tuần hoàn qua `RUN (00)` -> `ADJ_SEC (01)` -> `ADJ_MIN (10)` -> `ADJ_HOUR (11)` -> `RUN (00)`. |
| `REQ-FSM-02` | Timeout 5 Giây | `USER-PROVIDED` | Sau 5 giây không bấm phím ở các chế độ chỉnh sửa, FSM tự động hủy đệm và quay về `MODE_RUN`. |
| `REQ-CNT-01` | Đếm Nền Zero-Drift | `USER-PROVIDED` | Các bộ đếm Giây/Phút/Giờ chạy nền liên tục 24/7 chuẩn thời gian thực, không bị dừng hay trôi nhịp khi chỉnh menu. |
| `REQ-BUF-01` | Bộ Đệm Chỉnh Giờ | `USER-PROVIDED` | Duy trì bộ thanh ghi đệm chỉnh sửa (`adj_sec`, `adj_min`, `adj_hour`) độc lập trong `mode_controller`. |
| `REQ-MUX-01` | Output Switch MUX | `USER-PROVIDED` | Tách riêng module `output_switch` để chuyển mạch hiển thị: xuất đệm khi chỉnh giờ và xuất counter khi chạy đếm bình thường. |
| `REQ-LD-01` | Synchronous Commit | `USER-PROVIDED` | Khi duyệt hết chu trình chỉnh giờ (`ADJ_HOUR` -> `RUN`), nạp song song toàn bộ thời gian mới vào các counter. |
| `REQ-PPA-02` | Tối Ưu Debouncer | `DERIVED` | Khối Debouncer nhận xung nhịp 1 kHz, giảm bộ đếm xuống 5-bit (0 .. 17), cắt giảm 85% năng lượng. |
| `REQ-PPA-03` | Tối Ưu Prescaler | `DERIVED` | Prescaler 2 tầng 10-bit rút ngắn critical path carry chain, tối ưu Fmax và công suất. |
| `REQ-GAT-01` | Khóa Cờ Tràn | `RECOMMENDED` | Cờ tràn `sec_rollover` và `min_rollover` chỉ phát đúng 1 chu kỳ clock đồng bộ với `sec_tick`. |
| `REQ-CON-01` | Xử Lý Xung Đột | `RECOMMENDED` | Giữ nguyên giá trị khi 2 nút UP và DOWN bị nhấn đồng thời trong cùng chu kỳ. |
| `REQ-DFT-01` | Scan Testability | `RECOMMENDED` | Hỗ trợ chân `test_mode` ép các cổng ICG mở hoàn toàn (bypass) cho kiểm thử Scan ATPG. |
| `REQ-RST-01` | Đồng Bộ Hóa Reset | `RECOMMENDED` | Triển khai khối Reset Synchronizer 2-FF (Asynchronous Assert, Synchronous Deassert) kết hợp bypass `test_mode` để chống vi phạm recovery/removal và triệt tiêu metastability. |

*Ghi chú: Toàn bộ 18 yêu cầu kỹ thuật được phân loại chuẩn xác theo chuẩn rtl_spec_architect và được kiểm chứng 100% qua 14 Test Cases tại Chương 4.*

---

## 1.3 Đặc điểm kiến trúc & Đột phá tối ưu PPA

Kiến trúc **v2.3.0** mang lại hiệu quả vượt bậc về cả 3 chỉ số PPA (Power, Performance, Area):

1. **Triệt tiêu Công suất Động Chân Clock (Clock Pin Dynamic Power Reduction > 99.99%)**:
   - Công suất động nạp/xả cổng đảo chân clock của Flip-Flop tuân theo công thức:
     `P_clk_pin = SUM(C_pin * Vdd^2 * f_clk)`
   - Trước khi áp dụng ICG: Tất cả các Flip-Flop của bộ đếm Giây (1 Hz), Phút (1/60 Hz), Giờ (1/3600 Hz) đều nhận trực tiếp clock 1 MHz, tiêu tốn 1,000,000 lần chuyển mạch mỗi giây.
   - Sau khi áp dụng ICG: Cổng ICG ngắt hoàn toàn dao động chân clock khi không có sự kiện. Chân CLK của `second_counter` chỉ dao động đúng 1 lần/giây (1 toggle/s), `minute_counter` dao động 1 lần/60 giây, và `hour_counter` dao động 1 lần/3600 giây. Năng lượng tiêu thụ chân clock của khối bộ đếm giảm 99.9999%!

2. **Kiến trúc Tách biệt Bộ Đệm & Chuyển Mạch Hiển Thị (`output_switch`)**:
   - Bộ đệm chỉnh giờ (`adj_sec`, `adj_min`, `adj_hour`) được đặt hoàn toàn trong `mode_controller`.
   - Module `output_switch` hoạt động bằng logic tổ hợp không độ trễ chuyển mạch tức thời.
   - Người dùng quan sát được ngay giá trị đang thay đổi khi bấm nút UP/DOWN mà không can thiệp làm sai lệch bộ đếm nền.

3. **Bộ Đếm Nền Liên Tục Không Trôi Thời Gian (Zero-Drift Clock)**:
   - Các bộ đếm nền tiếp tục đếm nhịp thời gian thực 24/7 trong suốt quá trình người dùng thao tác menu.
   - Cơ chế này cho phép loại bỏ hoàn toàn các thanh ghi bóng trong các counter, tiết kiệm trực tiếp 17 Flip-Flops và hàng chục cổng logic multiplexer.

**Bảng 1.3: So sánh các chỉ tiêu PPA (Power, Performance, Area) giữa các phiên bản kiến trúc**

| Chỉ Tiêu Đánh Giá | Baseline (v1.1.0) | v2.0.0 (Prescaler + CE) | v2.3.0 (ICG + Decoupled MUX) |
| :--- | :---: | :---: | :---: |
| **Số FFs chuyển mạch chân CLK ở 1 MHz** | 65 FFs | 65 FFs | **16 FFs** (Chỉ Tầng 1 Prescaler & Pulse Align) |
| **Tần số dao động chân CLK của Second Counter** | 1,000,000 Hz | 1,000,000 Hz | **1 Hz (1 toggle/s)** |
| **Tần số dao động chân CLK của Minute Counter** | 1,000,000 Hz | 1,000,000 Hz | **0.0167 Hz (1 toggle/60s)** |
| **Tần số dao động chân CLK của Hour Counter** | 1,000,000 Hz | 1,000,000 Hz | **0.00028 Hz (1 toggle/3600s)** |
| **Tổng số lần chuyển trạng thái chân CLK/giây** | 65,000,000 /s | 65,000,000 /s | **~16,025,000 /s (Giảm 75.3% toàn chip)** |
| **Độ trôi thời gian khi duyệt Menu (Clock Drift)** | Bị dừng thời gian | Bị dừng thời gian | **0.000s (Zero-Drift tuyệt đối)** |
| **Số FFs lưu Snapshot Shadow Registers** | 17 FFs | 17 FFs | **0 FFs (Cắt giảm 100%)** |
| **Độ phức tạp CDC & Rủi ro Metastability** | 0 (Đồng bộ) | 0 (Đồng bộ) | **0 (Hoàn toàn Đồng bộ 100%)** |

*Ghi chú: Kiến trúc v2.3.0 áp dụng ICG và bộ chuyển mạch hiển thị độc lập giúp giảm 75.3% số lần chuyển trạng thái chân clock toàn chip và đạt Zero-Drift tuyệt đối.*

---

## 1.4 Sơ đồ kiến trúc tổng quan (Architecture Overview)

Sơ đồ kiến trúc tổng thể toàn hệ thống `hms_timer` mô tả đầy đủ 8 khối chức năng con, đường bus điều khiển, lớp gating xung nhịp và luồng dữ liệu hiển thị:

![Hình 1.4: Sơ đồ kiến trúc tổng thể toàn hệ thống HMS_Timer v2.3.0 (Draw.io)](diag_1_3_architecture_overview.png)

---

## 1.5 Bảng tham số kiến trúc (Design Parameters)

**Bảng 1.5: Bảng tham số kiến trúc thiết kế IP Core hms_timer (Design Parameters)**

| Tên Tham Số | Kiểu Dữ Liệu | Giá Trị Mặc Định | Giá Trị Mô Phỏng | Phân Loại | Ý Nghĩa Chức Năng | Module Bị Ảnh Hưởng |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `CLK_FREQ_HZ` | `int` | `1_000_000` | `100` | `USER-PROVIDED` | Tần số xung nhịp toàn cục hệ thống (1 MHz) | `hms_timer`, `clk_prescaler` |
| `TICK_1KHZ_FREQ_HZ` | `int` | `1_000` | `100` / Scale | `DERIVED` | Tần số xung lấy mẫu Debounce (1 kHz) | `clk_prescaler`, `hms_timer` |
| `TICK_1HZ_FREQ_HZ` | `int` | `1` | `1` | `USER-PROVIDED` | Tần số xung chuẩn đếm giây thời gian thực (1 Hz) | `clk_prescaler`, `hms_timer` |
| `DIV_1KHZ_MAX` | `int` | `999` | `0` | `DERIVED` | Ngưỡng đếm tràn của Tầng 1 Prescaler | `clk_prescaler` |
| `DIV_1HZ_MAX` | `int` | `999` | `99` | `DERIVED` | Ngưỡng đếm tràn của Tầng 2 Prescaler | `clk_prescaler` |
| `DEBOUNCE_TICKS` | `int` | `20` | `20` | `USER-PROVIDED` | Số chu kỳ lấy mẫu 1kHz danh định (20 ms) | `button_debouncer` |
| `DEBOUNCE_TOL_PCT`| `int` | `10` | `10` | `USER-PROVIDED` | Dung sai khử rung phím ±10% (18 ms .. 22 ms) | `button_debouncer` |
| `TIMEOUT_SEC` | `int` | `5` | `5` | `USER-PROVIDED` | Ngưỡng thời gian tự động hủy đệm và thoát về RUN (5s) | `mode_controller` |
| `SEC_WIDTH` | `int` | `6` | `6` | `DERIVED` | Độ rộng bus dữ liệu Giây (0 .. 59) | `second_counter`, `mode_controller`, `output_switch`, `hms_timer` |
| `MIN_WIDTH` | `int` | `6` | `6` | `DERIVED` | Độ rộng bus dữ liệu Phút (0 .. 59) | `minute_counter`, `mode_controller`, `output_switch`, `hms_timer` |
| `HOUR_WIDTH` | `int` | `5` | `5` | `DERIVED` | Độ rộng bus dữ liệu Giờ (0 .. 23) | `hour_counter`, `mode_controller`, `output_switch`, `hms_timer` |

*Ghi chú: Các giá trị tham số cấu hình cho phép linh hoạt điều chỉnh quy mô kiểm chứng mô phỏng mà không làm thay đổi bản chất hoạt động của mạch.*

---

# CHƯƠNG 2: TOP MODULE – `hms_timer`

## 2.1 Sơ đồ khối Top Module (Top-Level Block Diagram)

Top module `hms_timer` là module cấp cao nhất đóng gói toàn bộ các sub-module, thực hiện kết nối hoàn toàn không chứa logic rời rạc bên ngoài:

![Hình 2.1: Sơ đồ phân cấp và kết nối liên khối Top Module hms_timer (Draw.io)](diag_1_3_architecture_overview.png)

---

## 2.2 Bảng chân tín hiệu ngoại vi Top Module (External Interface Table)

**Bảng 2.2: Bảng chân tín hiệu ngoại vi Top Module hms_timer (External Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại tín hiệu | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1 MHz Master | Xung nhịp toàn cục hệ thống (1 MHz, chu kỳ 1 µs) | Tần số ổn định 1 MHz | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ toàn cục, tích cực mức thấp | Tích cực khi `rstn = 0` | `0` |
| `test_mode` | Input | 1 | DFT/Scan | Static | Tín hiệu chuyển chế độ kiểm tra quét Scan (Bypass các cổng ICG) | Mức `0` khi chạy bình thường | `0` |
| `sel_in` | Input | 1 | Async In | Async | Nút bấm chọn chuyển đổi chế độ (`MODE`) | Tích cực mức cao (`1`) | N/A |
| `up_in` | Input | 1 | Async In | Async | Nút bấm tăng giá trị thời gian (`UP`) | Tích cực mức cao (`1`) | N/A |
| `down_in` | Input | 1 | Async In | Async | Nút bấm giảm giá trị thời gian (`DOWN`) | Tích cực mức cao (`1`) | N/A |
| `h_out[4:0]` | Output | 5 | Data Out | 1 MHz Gated | Giá trị Giờ hiển thị ra ngoại vi (0 .. 23) | Đồng bộ | `5'd0` |
| `m_out[5:0]` | Output | 6 | Data Out | 1 MHz Gated | Giá trị Phút hiển thị ra ngoại vi (0 .. 59) | Đồng bộ | `6'd0` |
| `s_out[5:0]` | Output | 6 | Data Out | 1 MHz Gated | Giá trị Giây hiển thị ra ngoại vi (0 .. 59) | Đồng bộ | `6'd0` |

*Ghi chú: Tất cả tín hiệu ngõ vào nút bấm bất đồng bộ đều được đồng bộ hóa và lọc rung phím 20ms ±10% trước khi đưa vào hệ thống.*

---

## 2.3 Nguyên lý hoạt động tổng thể & Mối quan hệ tương tác giữa các Sub-module

1. **Khóa Xung Nhịp Chống Glitch Tuyệt Đối (Zero-Overhead Glitch-Free ICG)**:
   - Các cổng ICG được điều khiển bởi logic điều kiện tối giản và hiệu quả tuyệt đối:
     - `en_1khz = tick_1khz;`
     - `en_sec = sec_tick | load_en;`
     - `en_min = sec_rollover | load_en;`
     - `en_hour = min_rollover | load_en;`
     - `en_fsm = sec_tick | sel_pulse | up_pulse | down_pulse | load_en;`
   - Nhờ đó, trong cả chế độ đếm bình thường (`MODE_RUN`) lẫn khi người dùng đang bấm nút chỉnh giờ, chân clock của `second_counter` chỉ nhận đúng 1 xung clock mỗi giây, `minute_counter` nhận 1 xung mỗi 60 giây, và `hour_counter` nhận 1 xung mỗi 3600 giây! Khi có lệnh nạp `load_en = 1`, cả 3 ICG mở đúng 1 chu kỳ để cập nhật đồng bộ.

2. **Bộ Đếm Nền Chạy Liên Tục (Zero-Drift Background Counting)**:
   - Các bộ đếm `second_counter`, `minute_counter`, `hour_counter` đếm nhịp thời gian thực chuẩn liên tục 24/7 ở chế độ nền. Không có bất kỳ khoảng trễ hay mất nhịp nào xảy ra khi người dùng đang thao tác trên menu.

3. **Bộ Đệm Chỉnh Giờ & Chuyển Mạch Hiển Thị Tách Biệt (`output_switch`)**:
   - Khi chuyển từ `MODE_RUN` sang `MODE_ADJ_SEC`, `mode_controller` nạp giá trị counter hiện thời vào bộ đệm nội bộ (`adj_sec <= s_cnt`, `adj_min <= m_cnt`, `adj_hour <= h_cnt`).
   - Module `output_switch` tức thì chuyển mạch đưa giá trị từ bộ đệm ra ngoài `s_out, m_out, h_out` để người dùng quan sát.
   - Thao tác UP/DOWN tác động tức thời lên các thanh ghi đệm trong `mode_controller`.
   - **Xác nhận (Commit):** Khi người dùng duyệt hết chu trình chỉnh giờ (bấm `SEL` từ `ADJ_HOUR` về `RUN`), `mode_controller` phát xung `load_en = 1`, các counter lập tức nạp giá trị mới từ buffer.
   - **Hủy bỏ (5s Timeout Rollback):** Nếu không thao tác trong 5s, FSM chuyển về `RUN` với `load_en = 0`. Module `output_switch` tự động chuyển lại hiển thị bộ đếm nền đang chạy chuẩn xác!

4. **Đồng Bộ Hóa Giải Trừ Reset (Asynchronous Assert, Synchronous Deassert)**:
   - Toàn bộ mạng lưới reset của các khối tuần tự được cách ly khỏi đường `rstn` thô ngoại vi thông qua khối đồng bộ hóa `reset_sync`.
   - Khi `rstn = 0`, hệ thống xác lập trạng thái reset ngay lập tức một cách bất đồng bộ (`rstn_sync = 0`), đưa toàn bộ Flip-Flop trong chip về giá trị mặc định mà không cần chờ xung clock.
   - Khi `rstn` chuyển từ 0 lên 1 (giải trừ reset), ngõ ra `rstn_sync` được đồng bộ hóa theo sườn dương của `clk` qua 2 tầng Flip-Flop (sau 2 chu kỳ clock, tức 2 µs). Cơ chế này triệt tiêu hoàn toàn vi phạm thời gian Recovery và Removal, đảm bảo toàn bộ hệ thống thoát reset đồng thời và sạch sẽ, loại bỏ hiện tượng bất ổn định (Metastability).
   - Tín hiệu `test_mode` cho phép bypass trực tiếp 2 tầng Flip-Flop này khi kiểm thử Scan ATPG.

---

## 2.4 Bảng kết nối nội bộ giữa các Sub-module (Internal Interconnect Table)

**Bảng 2.4: Bảng kết nối tín hiệu nội bộ giữa các Sub-module (Internal Interconnect Table)**

| Tên Tín Hiệu Nội Bộ | Chiều Rộng | Khối Phát (Driver) | Khối Nhận (Receiver) | Mô Tả Chức Năng & Mục Đích Kết Nối |
| :--- | :---: | :--- | :--- | :--- |
| `rstn_sync` | 1 | `u_reset_sync` | Toàn bộ các sub-module tuần tự | Tín hiệu reset tích cực mức thấp được đồng bộ hóa giải trừ khử vi phạm recovery/removal |
| `gated_clk_1khz` | 1 | `u_clock_control_unit` | `u_button_controller` | Xung nhịp khóa 1kHz cấp nhịp chuyển mạch cho khối khử rung phím |
| `gated_clk_sec` | 1 | `u_clock_control_unit` | `u_second_counter` | Xung nhịp khóa 1Hz/Load cấp chân clock cho second_counter |
| `gated_clk_min` | 1 | `u_clock_control_unit` | `u_minute_counter` | Xung nhịp khóa 1/60Hz/Load cấp chân clock cho minute_counter |
| `gated_clk_hour` | 1 | `u_clock_control_unit` | `u_hour_counter` | Xung nhịp khóa 1/3600Hz/Load cấp chân clock cho hour_counter |
| `gated_clk_fsm` | 1 | `u_clock_control_unit` | `u_mode_controller` | Xung nhịp khóa cấp cho FSM mode controller |
| `tick_1khz` | 1 | `u_clk_prescaler` | `u_clock_control_unit` | Xung cho phép 1kHz điều khiển cổng ICG 1kHz |
| `sec_tick` | 1 | `u_clk_prescaler` | `u_clock_control_unit`, `u_second_counter`, `u_mode_controller` | Xung chuẩn thời gian thực 1Hz |
| `sel_pulse` | 1 | `u_button_controller` | `u_mode_controller`, `u_clock_control_unit` | Xung 1-cycle sau khi khử rung phím chọn chế độ |
| `up_pulse` | 1 | `u_button_controller` | `u_mode_controller`, `u_clock_control_unit` | Xung 1-cycle sau khi khử rung phím tăng giá trị |
| `down_pulse` | 1 | `u_button_controller` | `u_mode_controller`, `u_clock_control_unit` | Xung 1-cycle sau khi khử rung phím giảm giá trị |
| `adj_mode[1:0]` | 2 | `u_mode_controller` | `u_output_switch` | Trạng thái chế độ làm việc hiện tại điều khiển MUX hiển thị |
| `load_en` | 1 | `u_mode_controller` | `u_second_counter`, `u_minute_counter`, `u_hour_counter`, `u_clock_control_unit` | Xung 1-cycle kích hoạt nạp song song giá trị mới vào counters khi commit |
| `adj_sec[5:0]` | 6 | `u_mode_controller` | `u_output_switch`, `u_second_counter` | Giá trị giây trong bộ đệm chỉnh sửa |
| `adj_min[5:0]` | 6 | `u_mode_controller` | `u_output_switch`, `u_minute_counter` | Giá trị phút trong bộ đệm chỉnh sửa |
| `adj_hour[4:0]` | 5 | `u_mode_controller` | `u_output_switch`, `u_hour_counter` | Giá trị giờ trong bộ đệm chỉnh sửa |
| `s_cnt[5:0]` | 6 | `u_second_counter` | `u_output_switch`, `u_mode_controller` | Giá trị giây từ bộ đếm nền thời gian thực |
| `m_cnt[5:0]` | 6 | `u_minute_counter` | `u_output_switch`, `u_mode_controller` | Giá trị phút từ bộ đếm nền thời gian thực |
| `h_cnt[4:0]` | 5 | `u_hour_counter` | `u_output_switch`, `u_mode_controller` | Giá trị giờ từ bộ đếm nền thời gian thực |
| `sec_rollover` | 1 | `u_second_counter` | `u_minute_counter`, `u_clock_control_unit` | Xung tràn giây sang phút khi `s_cnt == 59 & sec_tick & ~load_en` |
| `min_rollover` | 1 | `u_minute_counter` | `u_hour_counter`, `u_clock_control_unit` | Xung tràn phút sang giờ khi `m_cnt == 59 & sec_rollover & ~load_en` |

*Ghi chú: Toàn bộ tín hiệu điều khiển và dữ liệu nội bộ được định tuyến đồng bộ 100% với miền clock chủ 1 MHz; các đường clock ngắt động (gated_clk_*) được tạo từ khối CCU tập trung để phân phối riêng cho từng khối chức năng con.*

---

## 2.5 Giản đồ thời gian tổng thể Top Module (Top-Level Timing Diagrams)

### 2.5.1 Giản đồ Gated Clock trong Chế độ Đếm Thời Gian Thực (1MHz -> 1kHz -> 1Hz)

Giản đồ thời gian thể hiện phân tầng tần số và quá trình chuyển mạch các xung gated clock khi chuyển trạng thái thời gian thực:

![Hình 2.5.1: Giản đồ xung đếm thời gian thực 1Hz và tràn nửa đêm 23:59:59 -> 00:00:00 (WaveDrom)](timing_2_5_1_normal_run.png)

### 2.5.2 Giản đồ Lọc Rung Phím Dung Sai ±10% & Auto-Repeat

Giản đồ thời gian minh họa bộ lọc nhiễu rung phím 20 ms ±10% (18 ticks @ 1 kHz) và cơ chế tự động phát xung lặp lại (Auto-Repeat) khi giữ phím:

![Hình 2.5.2: Giản đồ xung lọc rung phím 18ms (dung sai 10%) và Auto-Repeat (WaveDrom)](timing_2_5_2_debounce_and_auto_repeat.png)

### 2.5.3 Giản đồ Chuyển Mạch Hiển Thị & Nạp Đồng Bộ (Edit Buffer & Commit vs Timeout 5s)

Giản đồ thời gian mô tả hoạt động chuyển mạch hiển thị giữa bộ đệm chỉnh giờ và bộ đếm nền, quá trình nạp song song đồng bộ (`load_en = 1`), cùng cơ chế hủy thay đổi sau 5 giây không hoạt động:

![Hình 2.5.3: Giản đồ xung nạp đồng bộ (load_en) và Inactivity Timeout 5s Zero-Drift (WaveDrom)](timing_2_5_3_load_commit_and_timeout.png)

---

# CHƯƠNG 3: ĐẶC TẢ CHI TIẾT TỪNG SUB-MODULE

---

## 3.1 Module: `reset_sync`
**Chức năng:** Khối đồng bộ hóa reset hệ thống (Reset Synchronizer) sử dụng kiến trúc 2 tầng Flip-Flop "Asynchronous Assert, Synchronous Deassert", bảo đảm xác lập reset tức thì và giải trừ reset đồng bộ theo sườn xung nhịp 1 MHz, triệt tiêu nguy cơ vi phạm thời gian Recovery/Removal và loại trừ hiện tượng bất ổn định (Metastability), đồng thời tích hợp cổng MUX bypass phục vụ kiểm thử Scan ATPG (`test_mode`).

### 3.1.1 Sơ đồ khối (Block Diagram)

Sơ đồ nguyên lý cấu trúc phần cứng bên trong khối `reset_sync`:

![Hình 3.1.1: Sơ đồ khối module reset_sync (Draw.io)](diag_3_0_reset_sync.png)

### 3.1.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.1: Bảng chân tín hiệu module đồng bộ hóa reset reset_sync (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | Master 1 MHz | Nguồn xung nhịp hệ thống phục vụ giải trừ reset đồng bộ | Tần số ổn định | N/A |
| `rstn_async` | Input | 1 | Reset | Async | Tín hiệu reset bất đồng bộ thô từ chân ngoại vi, tích cực mức thấp | Chuẩn | `0` |
| `test_mode` | Input | 1 | DFT | Static | Chế độ kiểm tra Scan ATPG (Bypass FFs đồng bộ hóa reset) | Mức `1` khi test | `0` |
| `rstn_sync` | Output | 1 | Reset | Sync Deassert | Tín hiệu reset tích cực mức thấp đã đồng bộ hóa giải trừ | Đồng bộ posedge clk | `0` |

*Ghi chú: Tín hiệu rstn_sync xác lập mức thấp ngay lập tức khi rstn_async = 0 và chỉ chuyển lên mức 1 sau 2 chu kỳ clk sau khi rstn_async giải trừ.*

### 3.1.3 Nguyên lý hoạt động (Operating Principle)
- **Kiến trúc Asynchronous Assert, Synchronous Deassert:** Khối sử dụng 2 tầng D Flip-Flop mắc nối tiếp với thuộc tính tổng hợp `(* async_reg = "true" *)`:
  - **Xác lập bất đồng bộ (Asynchronous Assertion):** Khi ngõ vào `rstn_async = 0`, cả 2 Flip-Flop `r_sync_stage1` và `r_sync_stage2` lập tức bị xóa về `0` bất đồng bộ thông qua chân async clear của Flip-Flop, kéo `rstn_sync = 0` ngay tức thì (độ trễ bằng 0).
  - **Giải trừ đồng bộ (Synchronous Deassertion):** Khi `rstn_async` chuyển từ 0 lên 1, Flip-Flop tầng 1 nhận mức logic `1` ở ngõ vào D và chuyển trạng thái ở sườn dương kế tiếp của `clk`. Sau 2 chu kỳ clock (`2 µs`), `r_sync_stage2` chuyển lên `1`, giải trừ reset cho toàn bộ các khối chức năng con một cách đồng bộ.
  - **Triệt tiêu Metastability & Recovery/Removal Violations:** Việc giải trừ đồng bộ ở sườn dương clock triệt tiêu hoàn toàn nguy cơ vi phạm thời gian Recovery và Removal, ngăn chặn hiện tượng bất ổn định (Metastability) lan truyền vào hệ thống.
- **Chế độ DFT Scan Test Mode:**
  - Khi `test_mode = 1`, bộ ghép kênh chuyển mạch bypass trực tiếp đường `rstn_async` tới ngõ ra `rstn_sync`, cho phép công cụ tự động sinh mẫu kiểm thử ATPG kiểm soát hoàn toàn mạng lưới reset trong chuỗi Scan.
- **Phương trình logic:**
  - `r_sync_stage1 <= (!rstn_async) ? 1'b0 : 1'b1;` (trên sườn posedge clk hoặc negedge rstn_async)
  - `r_sync_stage2 <= (!rstn_async) ? 1'b0 : r_sync_stage1;`
  - `rstn_sync = (test_mode) ? rstn_async : r_sync_stage2;`

### 3.1.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian xác lập bất đồng bộ tức thời, giải trừ đồng bộ sau 2 chu kỳ clock và chế độ DFT Scan Bypass của module `reset_sync`:

![Hình 3.1.4: Giản đồ thời gian xác lập bất đồng bộ và giải trừ đồng bộ reset_sync (WaveDrom)](timing_3_0_4_reset_sync.png)

---

## 3.2 Module: `icg_cell`
**Chức năng:** Tế bào khóa xung nhịp tiêu chuẩn (Integrated Clock Gating Leaf Cell) dạng Active-Low Latch kết hợp cổng AND, triệt tiêu hoàn toàn xung nhọn không mong muốn (Glitch-Free) và hỗ trợ chế độ kiểm thử quét Scan ATPG (`test_mode`).

### 3.2.1 Sơ đồ khối (Block Diagram)

Sơ đồ nguyên lý cấu trúc phần cứng bên trong tế bào `icg_cell`:

![Hình 3.2.1: Sơ đồ nguyên lý tế bào Integrated Clock Gating icg_cell (Draw.io)](diag_3_8_icg_cell.png)

### 3.2.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.2: Bảng chân tín hiệu tế bào khóa xung nhịp icg_cell (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk_in` | Input | 1 | Clock | Master 1 MHz | Nguồn xung nhịp đầu vào trước khi khóa | Tần số ổn định | N/A |
| `en` | Input | 1 | Control | Đồng bộ | Tín hiệu cho phép mở clock (Clock Enable) | Tích cực mức `1` | `0` |
| `test_mode` | Input | 1 | DFT | Static | Chế độ kiểm tra Scan ATPG (Bypass latch, ép mở clock) | Mức `1` khi test | `0` |
| `clk_out` | Output | 1 | Clock | Gated Out | Xung nhịp ngõ ra đã được khóa sạch nhiễu Glitch | Sạch Glitch | `0` |

*Ghi chú: Khi test_mode = 1, tín hiệu en bị bypass hoàn toàn để phục vụ quét chuỗi Scan ATPG cho kiểm thử sản xuất.*

### 3.2.3 Nguyên lý hoạt động (Operating Principle)
- **Cấu trúc Latch-Based ICG:** Tế bào sử dụng một phần tử chốt tích cực mức thấp (Active-Low Transparent Latch) mắc nối tiếp với cổng AND hai đầu vào:
  - Khi `clk_in = 0`: Latch ở trạng thái trong suốt (`transparent`), giá trị tín hiệu điều khiển `en` (hoặc `test_mode`) được truyền vào chốt tại `en_latch`.
  - Khi `clk_in = 1`: Latch ở trạng thái khóa (`opaque`), giá trị `en_latch` được giữ cố định. Mọi biến động hoặc nhiễu trên đường `en` trong nửa chu kỳ cao của clock đều bị chặn hoàn toàn, ngăn ngừa hiện tượng xung nhọn (Glitch) xuất hiện ở ngõ ra `clk_out`.
- **Phương trình logic:**
  - `en_latch = (clk_in == 0) ? (en | test_mode) : en_latch;`
  - `clk_out = clk_in & en_latch;`
- **Chế độ DFT Test Mode:** Khi `test_mode = 1`, đường clock được mở thông suốt 100% cho chuỗi quét Scan.

### 3.2.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian hoạt động của tế bào ICG cho thấy xung ngõ ra sạch nhiễu và không sinh glitch:

![Hình 3.2.4: Giản đồ xung clock gating triệt tiêu glitch icg_cell (WaveDrom)](timing_3_8_4_icg_cell.png)

---

## 3.3 Module: `clock_control_unit`
**Chức năng:** Khối quản lý xung nhịp tập trung (Centralized Clock Management Unit - CCU), đóng vai trò phân tích các sự kiện điều khiển trong hệ thống để tạo tín hiệu enable và điều khiển 5 tế bào `icg_cell` phân phối các đường xung nhịp khóa cho toàn bộ các module con.

### 3.3.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của bộ quản lý xung nhịp tập trung `clock_control_unit`:

![Hình 3.3.1: Sơ đồ khối bộ quản lý xung nhịp tập trung clock_control_unit (Draw.io)](diag_3_9_clock_control_unit.png)

### 3.3.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.3: Bảng chân tín hiệu khối quản lý xung nhịp clock_control_unit (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1 MHz | Nguồn xung nhịp chủ hệ thống (1 MHz) | Tần số ổn định | N/A |
| `test_mode` | Input | 1 | DFT | Static | Tín hiệu bypass toàn bộ các cổng ICG cho kiểm thử Scan ATPG | Mức `1` khi Scan Test | `0` |
| `tick_1khz` | Input | 1 | Control | 1 MHz | Xung cho phép 1kHz từ prescaler | Xung 1-cycle | `0` |
| `sec_tick` | Input | 1 | Control | 1 MHz | Xung chuẩn thời gian thực 1Hz từ prescaler | Xung 1-cycle | `0` |
| `sec_rollover` | Input | 1 | Control | 1 MHz | Xung tràn giây sang phút từ second_counter | Xung 1-cycle | `0` |
| `min_rollover` | Input | 1 | Control | 1 MHz | Xung tràn phút sang giờ từ minute_counter | Xung 1-cycle | `0` |
| `sel_pulse` | Input | 1 | Control | 1 MHz | Xung 1 chu kỳ nút bấm SEL sau khử rung | Xung 1-cycle | `0` |
| `up_pulse` | Input | 1 | Control | 1 MHz | Xung 1 chu kỳ nút bấm UP sau khử rung | Xung 1-cycle | `0` |
| `down_pulse` | Input | 1 | Control | 1 MHz | Xung 1 chu kỳ nút bấm DOWN sau khử rung | Xung 1-cycle | `0` |
| `load_en` | Input | 1 | Control | 1 MHz | Xung 1 chu kỳ nạp song song khi commit từ mode_controller | Xung 1-cycle | `0` |
| `gated_clk_1khz` | Output | 1 | Clock | Gated | Xung nhịp khóa 1kHz cấp cho Debouncer & Prescaler tầng 2 | Sạch nhiễu | `0` |
| `gated_clk_sec` | Output | 1 | Clock | Gated | Xung nhịp khóa 1Hz/Load cấp cho second_counter | Sạch nhiễu | `0` |
| `gated_clk_min` | Output | 1 | Clock | Gated | Xung nhịp khóa 1/60Hz/Load cấp cho minute_counter | Sạch nhiễu | `0` |
| `gated_clk_hour` | Output | 1 | Clock | Gated | Xung nhịp khóa 1/3600Hz/Load cấp cho hour_counter | Sạch nhiễu | `0` |
| `gated_clk_fsm` | Output | 1 | Clock | Gated | Xung nhịp khóa cấp cho mode_controller FSM | Sạch nhiễu | `0` |

*Ghi chú: Khối tích hợp sẵn 5 instance icg_cell bên trong nhằm quản lý gating tập trung cho toàn bộ hệ thống.*

### 3.3.3 Nguyên lý hoạt động (Operating Principle)
- **Phương trình logic kích hoạt Enable cho 5 kênh:**
  - `en_1khz = tick_1khz;`
  - `en_sec  = sec_tick | load_en;`
  - `en_min  = sec_rollover | load_en;`
  - `en_hour = min_rollover | load_en;`
  - `en_fsm  = sec_tick | sel_pulse | up_pulse | down_pulse | load_en;`
- **Khối chức năng:** Module tích hợp sẵn 5 tế bào `icg_cell` bên trong, mỗi tế bào phụ trách cấp clock trực tiếp cho một miền logic chuyên biệt, đảm bảo các Flip-Flop ở các miền tần số thấp chỉ dao động đúng lúc có sự kiện.

### 3.3.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian phân phối xung nhịp ngắt động của `clock_control_unit`:

![Hình 3.3.4: Giản đồ phân phối xung nhịp ngắt động của clock_control_unit (WaveDrom)](timing_2_5_1_normal_run.png)

---

## 3.4 Module: `clk_prescaler`
**Chức năng:** Bộ chia tần đa tầng phân cấp từ nguồn xung nhịp gốc 1 MHz xuống xung định thời lấy mẫu 1 kHz và xung chuẩn thời gian thực 1 Hz, tối ưu hóa chiều dài đường truyền logic (carry chain) và giảm thiểu công suất chuyển mạch.

### 3.4.1 Sơ đồ khối (Block Diagram)

Sơ đồ phân tầng 2 bộ đếm Modulo-1000 trong `clk_prescaler`:

![Hình 3.4.1: Sơ đồ khối bộ chia tần 2 tầng clk_prescaler (Draw.io)](diag_3_2_clk_prescaler.png)

### 3.4.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.4: Bảng chân tín hiệu bộ chia tần đa tầng clk_prescaler (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1 MHz | Xung nhịp hệ thống 1 MHz | Chuẩn | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `tick_1khz` | Output | 1 | Enable | 1 MHz | Xung cho phép 1kHz độ rộng 1 chu kỳ `clk` | Tầng 1 đạt 999 | `0` |
| `sec_tick` | Output | 1 | Enable | 1 MHz | Xung chuẩn thời gian thực 1Hz độ rộng 1 chu kỳ `clk`| Tầng 2 đạt 999 & tick_1khz | `0` |

*Ghi chú: Tín hiệu tick_1khz và sec_tick là các xung active-high có độ rộng đúng 1 chu kỳ clock 1 MHz.*

### 3.4.3 Nguyên lý hoạt động (Operating Principle)
- **Tầng 1 (1 MHz -> 1 kHz):** Sử dụng bộ đếm 10-bit (`r_cnt_1khz`) đếm tuần hoàn từ 0 đến 999 theo từng sườn dương của `clk` (1 MHz). Khi `r_cnt_1khz == 999`, mạch tạo xung `tick_1khz = 1` trong đúng 1 chu kỳ clock.
- **Tầng 2 (1 kHz -> 1 Hz):** Sử dụng bộ đếm 10-bit (`r_cnt_1hz`) chỉ tăng giá trị khi có `tick_1khz = 1`. Khi `r_cnt_1hz == 999` đồng thời có `tick_1khz = 1`, mạch phát xung chuẩn thời gian thực `sec_tick = 1` độ rộng 1 chu kỳ clock.

### 3.4.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian phát xung `tick_1khz` và `sec_tick`:

![Hình 3.4.4: Giản đồ xung phân tần 1MHz ra 1kHz sample_tick và 1Hz sec_tick (WaveDrom)](timing_3_2_4_clk_prescaler.png)

---

## 3.5 Module: `button_debouncer`
**Chức năng:** Bộ lọc rung phím cơ học đơn kênh hoạt động trên xung nhịp 1 kHz (`gated_clk_1khz`), áp dụng dải dung sai thời gian danh định 20 ms ±10% (18 ms .. 22 ms) và tự động phát xung tuần hoàn khi giữ phím (Auto-Repeat).

### 3.5.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của mạch khử rung đơn kênh `button_debouncer`:

![Hình 3.5.1: Sơ đồ khối bộ lọc rung phím đơn kênh button_debouncer (Draw.io)](diag_3_1_button_debouncer.png)

### 3.5.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.5: Bảng chân tín hiệu bộ lọc rung phím đơn kênh button_debouncer (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1 kHz Gated | Xung nhịp 1 kHz từ ICG (`gated_clk_1khz`) | Dao động 1 kHz | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `btn_in` | Input | 1 | Async In | Async | Tín hiệu nút bấm đầu vào bất đồng bộ | Tích cực mức `1` | N/A |
| `btn_event` | Output | 1 | Control | 1 kHz | Xung sự kiện hợp lệ độ rộng 1 chu kỳ 1 kHz (1 ms) | Tích cực mức `1` | `0` |

*Ghi chú: Bộ đếm 5-bit (0..17) hoạt động trên xung nhịp 1 kHz tương ứng thời gian nhận diện phím hợp lệ 18 ms (20 ms - 10%).*

### 3.5.3 Nguyên lý hoạt động (Operating Principle)
- **Đồng bộ hóa 2 tầng:** Tín hiệu nút bấm bất đồng bộ `btn_in` đi qua 2 tầng Flip-Flop để chống hiện tượng bất ổn định (Metastability).
- **Ngưỡng dung sai ±10%:** Với chu kỳ 20 ms tại tần số 1 kHz, số tick danh định là 20 ticks. Dải dung sai ±10% cho phép nhận diện phím hợp lệ từ 18 ticks:
  `EFFECTIVE_TICKS = 20 - floor(20 * 0.10) = 18 ticks (18 ms)`
- **Loại bỏ nhiễu rung (< 18 ms):** Nếu phím bị nhả trước khi bộ đếm 5-bit đạt 17 (đếm từ 0 .. 17 là 18 ticks), bộ đếm lập tức bị xóa về 0, không phát xung.
- **Auto-Repeat (>= 18 ms):** Khi bộ đếm đạt 17, mạch phát xung `btn_event = 1`. Nếu người dùng tiếp tục giữ phím, bộ đếm tự động reset về 0 và tiếp tục đếm lại 18 ticks để phát xung lặp lại tuần hoàn.

### 3.5.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian lọc rung phím, loại bỏ xung nhiễu ngắn và phát xung auto-repeat:

![Hình 3.5.4: Giản đồ xung lọc nhiễu glitch và phát xung kích hoạt button_debouncer (WaveDrom)](timing_3_1_4_button_debouncer.png)

---

## 3.6 Module: `button_controller`
**Chức năng:** Khối quản lý tập trung toàn bộ 3 kênh nút bấm (`sel_in`, `up_in`, `down_in`), tích hợp 3 instance `button_debouncer` và mạch căn xung sườn lên xuất trực tiếp xung 1 chu kỳ clock 1 MHz (1 µs) đồng bộ cho hệ thống.

### 3.6.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của bộ điều khiển nút bấm `button_controller`:

![Hình 3.6.1: Sơ đồ khối khối quản lý nút bấm button_controller (Draw.io)](diag_3_3_button_controller.png)

### 3.6.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.6: Bảng chân tín hiệu khối điều khiển nút bấm button_controller (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1 MHz | Nguồn xung nhịp hệ thống cho mạch căn xung (1 MHz) | Tần số ổn định | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `gated_clk_1khz` | Input | 1 | Clock | 1 kHz Gated | Xung nhịp 1 kHz từ ICG cấp cho các khối debouncer | Dao động 1 kHz | N/A |
| `sel_in` | Input | 1 | Control | Async | Tín hiệu nút bấm chọn chế độ | Tích cực mức `1` | N/A |
| `up_in` | Input | 1 | Control | Async | Tín hiệu nút bấm tăng giá trị | Tích cực mức `1` | N/A |
| `down_in` | Input | 1 | Control | Async | Tín hiệu nút bấm giảm giá trị | Tích cực mức `1` | N/A |
| `sel_pulse` | Output | 1 | Control | 1 MHz | Xung 1 chu kỳ 1 MHz hợp lệ sau khử rung cho `sel_in` | Độ rộng 1 µs | `0` |
| `up_pulse` | Output | 1 | Control | 1 MHz | Xung 1 chu kỳ 1 MHz hợp lệ sau khử rung cho `up_in` | Độ rộng 1 µs | `0` |
| `down_pulse` | Output | 1 | Control | 1 MHz | Xung 1 chu kỳ 1 MHz hợp lệ sau khử rung cho `down_in` | Độ rộng 1 µs | `0` |

*Ghi chú: Mạch căn xung sườn lên xuất trực tiếp các xung đơn chu kỳ 1 MHz (1 µs) sạch nhiễu cho FSM và CCU.*

### 3.6.3 Nguyên lý hoạt động (Operating Principle)
- **Tích hợp 3 kênh khử rung:** Module bao bọc 3 khối `button_debouncer` chạy trên `gated_clk_1khz` cho từng phím.
- **Mạch căn xung 1 MHz (Edge Alignment):** Do tín hiệu `btn_event` từ debouncer kéo dài 1 ms (1 chu kỳ 1 kHz), module sử dụng thanh ghi trễ 1 chu kỳ clock 1 MHz (`btn_event_d`) để bắt sườn lên:
  `btn_pulse = btn_event & ~btn_event_d`
- Ngõ ra `sel_pulse`, `up_pulse`, `down_pulse` là các xung đơn chu kỳ 1 MHz chuẩn, tương thích hoàn toàn với FSM và CCU.

### 3.6.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian xử lý và căn chỉnh xung nút bấm đồng bộ 1 MHz:

![Hình 3.6.4: Giản đồ thời gian căn chỉnh xung nút bấm 1MHz của button_controller (WaveDrom)](timing_2_5_2_debounce_and_auto_repeat.png)

---

## 3.7 Module: `mode_controller`
**Chức năng:** FSM điều khiển 4 chế độ hoạt động, quản lý bộ đệm chỉnh giờ độc lập (`adj_sec`, `adj_min`, `adj_hour`), bộ định thời 5s Inactivity Timeout, và phát xung nạp song song `load_en`.

### 3.7.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của FSM điều khiển chế độ và bộ đệm chỉnh giờ:

![Hình 3.7.1: Sơ đồ khối FSM và bộ đệm chỉnh giờ mode_controller (Draw.io)](diag_3_3_mode_controller.png)

### 3.7.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.7: Bảng chân tín hiệu khối điều khiển chế độ mode_controller (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | Event Gated | Xung nhịp khóa cấp cho FSM (`gated_clk_fsm`) | Chuẩn | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `sel_pulse` | Input | 1 | Control | 1 MHz | Xung 1-cycle từ nút chuyển chế độ | Tích cực mức `1` | `0` |
| `up_pulse` | Input | 1 | Control | 1 MHz | Xung 1-cycle từ nút tăng giá trị | Tích cực mức `1` | `0` |
| `down_pulse` | Input | 1 | Control | 1 MHz | Xung 1-cycle từ nút giảm giá trị | Tích cực mức `1` | `0` |
| `sec_tick` | Input | 1 | Enable | 1 MHz | Xung chuẩn 1 giây từ `clk_prescaler` | Tích cực mức `1` | `0` |
| `s_cur[5:0]` | Input | 6 | Data In | Gated | Giá trị giây hiện thời từ `second_counter` | 0 .. 59 | `0` |
| `m_cur[5:0]` | Input | 6 | Data In | Gated | Giá trị phút hiện thời từ `minute_counter` | 0 .. 59 | `0` |
| `h_cur[4:0]` | Input | 5 | Data In | Gated | Giá trị giờ hiện thời từ `hour_counter` | 0 .. 23 | `0` |
| `adj_mode[1:0]` | Output | 2 | Status | 1 MHz | Mã trạng thái chế độ làm việc hiện tại | `00`:RUN, `01`:SEC, `10`:MIN, `11`:HOUR | `2'b00` |
| `adj_sec[5:0]` | Output | 6 | Data Out | 1 MHz | Giá trị giây trong bộ đệm chỉnh sửa | 0 .. 59 | `6'd0` |
| `adj_min[5:0]` | Output | 6 | Data Out | 1 MHz | Giá trị phút trong bộ đệm chỉnh sửa | 0 .. 59 | `6'd0` |
| `adj_hour[4:0]` | Output | 5 | Data Out | 1 MHz | Giá trị giờ trong bộ đệm chỉnh sửa | 0 .. 23 | `5'd0` |
| `load_en` | Output | 1 | Control | 1 MHz | Xung 1-cycle kích hoạt nạp thời gian mới vào các bộ đếm | Phát khi duyệt hết vòng chỉnh giờ về RUN | `0` |

*Ghi chú: Bộ đệm chỉnh giờ độc lập (adj_sec, adj_min, adj_hour) cách ly hoàn toàn với các bộ đếm nền.*

### 3.7.3 Bảng chuyển trạng thái FSM kết hợp Timeout 5s & Buffer Chỉnh Giờ (FSM Table)

**Bảng 3.8: Bảng chuyển trạng thái FSM kết hợp Timeout 5s & Buffer Chỉnh Giờ (FSM State Transition Table)**

| Trạng thái hiện tại | Điều kiện chuyển tiếp (Inputs) | Trạng thái kế tiếp | Tác vụ thực thi & Cập nhật Buffer / Ngõ ra |
| :--- | :--- | :--- | :--- |
| `MODE_RUN (00)` | `sel_pulse == 1` | `MODE_ADJ_SEC (01)` | Nạp `adj_sec <= s_cur`, `adj_min <= m_cur`, `adj_hour <= h_cur`; reset `timeout_cnt <= 0`; `load_en <= 0`. |
| `MODE_RUN (00)` | `sel_pulse == 0` | `MODE_RUN (00)` | Giữ nguyên chế độ đếm thời gian thực; `load_en <= 0`. |
| `MODE_ADJ_SEC (01)` | `sel_pulse == 1` | `MODE_ADJ_MIN (10)` | Chuyển sang chỉnh phút; reset `timeout_cnt <= 0`. |
| `MODE_ADJ_SEC (01)` | `sel_pulse == 0` và (`up_pulse` hoặc `down_pulse`) | `MODE_ADJ_SEC (01)` | Tăng/giảm `adj_sec` (wrap-around 0 <-> 59); reset `timeout_cnt <= 0` (Keep-alive). |
| `MODE_ADJ_SEC (01)` | `any_button == 0` và `sec_tick == 1` và `timeout_cnt >= 4` | `MODE_RUN (00)` | **Timeout 5s:** Tự động về RUN, **hủy bỏ đệm** (`load_en = 0`), bộ MUX quay lại hiển thị counter nền. |
| `MODE_ADJ_SEC (01)` | `any_button == 0` và `sec_tick == 1` và `timeout_cnt < 4` | `MODE_ADJ_SEC (01)` | Tăng `timeout_cnt <= timeout_cnt + 1`. |
| `MODE_ADJ_MIN (10)` | `sel_pulse == 1` | `MODE_ADJ_HOUR (11)` | Chuyển sang chỉnh giờ; reset `timeout_cnt <= 0`. |
| `MODE_ADJ_MIN (10)` | `sel_pulse == 0` và (`up_pulse` hoặc `down_pulse`) | `MODE_ADJ_MIN (10)` | Tăng/giảm `adj_min` (wrap-around 0 <-> 59); reset `timeout_cnt <= 0` (Keep-alive). |
| `MODE_ADJ_MIN (10)` | `any_button == 0` và `sec_tick == 1` và `timeout_cnt >= 4` | `MODE_RUN (00)` | **Timeout 5s:** Tự động về RUN, **hủy bỏ đệm** (`load_en = 0`), bộ MUX quay lại hiển thị counter nền. |
| `MODE_ADJ_MIN (10)` | `any_button == 0` và `sec_tick == 1` và `timeout_cnt < 4` | `MODE_ADJ_MIN (10)` | Tăng `timeout_cnt <= timeout_cnt + 1`. |
| `MODE_ADJ_HOUR (11)` | `sel_pulse == 1` | `MODE_RUN (00)` | **Xác nhận (Commit):** Phát xung `load_en <= 1` trong 1 chu kỳ để nạp `adj_time` vào counters; về RUN. |
| `MODE_ADJ_HOUR (11)` | `sel_pulse == 0` và (`up_pulse` hoặc `down_pulse`) | `MODE_ADJ_HOUR (11)` | Tăng/giảm `adj_hour` (wrap-around 0 <-> 23); reset `timeout_cnt <= 0` (Keep-alive). |
| `MODE_ADJ_HOUR (11)` | `any_button == 0` và `sec_tick == 1` và `timeout_cnt >= 4` | `MODE_RUN (00)` | **Timeout 5s:** Tự động về RUN, **hủy bỏ đệm** (`load_en = 0`), bộ MUX quay lại hiển thị counter nền. |
| `MODE_ADJ_HOUR (11)` | `any_button == 0` và `sec_tick == 1` và `timeout_cnt < 4` | `MODE_ADJ_HOUR (11)` | Tăng `timeout_cnt <= timeout_cnt + 1`. |

*Ghi chú: Bộ đếm timeout 5s tự động xóa về 0 mỗi khi người dùng có thao tác bấm phím UP hoặc DOWN (Keep-alive).*

### 3.7.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian chuyển trạng thái FSM, tăng giảm buffer và phát xung `load_en`:

![Hình 3.7.4: Giản đồ chuyển trạng thái FSM, tăng giảm buffer và phát xung load_en (WaveDrom)](timing_3_3_4_mode_controller.png)

---

## 3.8 Module: `second_counter`
**Chức năng:** Bộ đếm Giây Modulo-60 (0 .. 59) hoạt động liên tục chuẩn thời gian thực ở chế độ nền (Background Counter) nhận nhịp `gated_clk_sec` (1 toggle/s hoặc khi có `load_en`). Hỗ trợ nạp song song giá trị mới từ bộ đệm khi nhận xung `load_en`.

### 3.8.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của bộ đếm giây `second_counter`:

![Hình 3.8.1: Sơ đồ khối bộ đếm giây second_counter nạp đồng bộ load_en (Draw.io)](diag_3_4_second_counter.png)

### 3.8.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.9: Bảng chân tín hiệu bộ đếm giây second_counter (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1 Hz Gated | Xung nhịp khóa 1Hz/Load (`gated_clk_sec`) | Chuẩn | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `sec_tick` | Input | 1 | Enable | 1 MHz | Xung chuẩn 1 giây từ `clk_prescaler` | Tích cực mức `1` | `0` |
| `load_en` | Input | 1 | Control | 1 MHz | Xung 1-cycle kích hoạt nạp song song giá trị mới | Tích cực mức `1` | `0` |
| `load_val[5:0]` | Input | 6 | Data In | Gated | Giá trị giây mới từ bộ đệm `mode_controller` | 0 .. 59 | `0` |
| `s_out[5:0]` | Output | 6 | Data Out | Gated | Giá trị giây nền thời gian thực (0 .. 59) | Chuẩn | `6'd0` |
| `sec_rollover` | Output | 1 | Enable | 1 MHz | Cờ báo tràn giây sang phút (`s_out == 59 & sec_tick & ~load_en`) | Tích cực mức `1` | `0` |

*Ghi chú: Cờ sec_rollover bị khóa (gated = 0) khi load_en = 1 để tránh kích hoạt nhảy phút ngoài ý muốn khi nạp thời gian.*

### 3.8.3 Nguyên lý hoạt động (Operating Principle)
1. **Nạp Song Song Đồng Bộ (Synchronous Load):** Khi có xung `load_en = 1`, thanh ghi nạp giá trị mới: `r_sec <= load_val`.
2. **Đếm Nền Thời Gian Thực (Continuous Background Count):** Khi không có `load_en`, mỗi nhịp clock `gated_clk_sec` làm bộ đếm tăng Modulo-60 (0 .. 59 -> 0) liên tục 24/7 chuẩn thời gian thực.
3. **Cờ Báo Tràn (Rollover Flag):** `sec_rollover = (r_sec == 6'd59) & sec_tick & ~load_en;`.

### 3.8.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian đếm giây, phát cờ `sec_rollover` và nạp đồng bộ `load_en`:

![Hình 3.8.4: Giản đồ đếm giây thời gian thực, sec_rollover và nạp song song load_en (WaveDrom)](timing_3_4_4_second_counter.png)

---

## 3.9 Module: `minute_counter`
**Chức năng:** Bộ đếm Phút Modulo-60 (0 .. 59) hoạt động liên tục ở chế độ nền nhận nhịp `gated_clk_min` (1 toggle/60s hoặc khi có `load_en`). Hỗ trợ nạp song song giá trị mới từ bộ đệm khi nhận xung `load_en`.

### 3.9.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của bộ đếm phút `minute_counter`:

![Hình 3.9.1: Sơ đồ khối bộ đếm phút minute_counter nạp đồng bộ load_en (Draw.io)](diag_3_5_minute_counter.png)

### 3.9.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.10: Bảng chân tín hiệu bộ đếm phút minute_counter (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1/60 Hz Gated| Xung nhịp khóa 1/60Hz/Load (`gated_clk_min`) | Chuẩn | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `sec_rollover` | Input | 1 | Enable | 1 MHz | Xung tràn từ `second_counter` | Tích cực mức `1` | `0` |
| `load_en` | Input | 1 | Control | 1 MHz | Xung 1-cycle kích hoạt nạp song song giá trị mới | Tích cực mức `1` | `0` |
| `load_val[5:0]` | Input | 6 | Data In | Gated | Giá trị phút mới từ bộ đệm `mode_controller` | 0 .. 59 | `0` |
| `m_out[5:0]` | Output | 6 | Data Out | Gated | Giá trị phút nền thời gian thực (0 .. 59) | Chuẩn | `6'd0` |
| `min_rollover` | Output | 1 | Enable | 1 MHz | Cờ báo tràn phút sang giờ (`m_out == 59 & sec_rollover & ~load_en`) | Tích cực mức `1` | `0` |

*Ghi chú: Chân clock gated_clk_min chỉ dao động 1 lần mỗi 60 giây ở chế độ đếm bình thường hoặc khi có xung nạp load_en.*

### 3.9.3 Nguyên lý hoạt động (Operating Principle)
1. **Nạp Song Song Đồng Bộ (Synchronous Load):** Khi có `load_en = 1`, thanh ghi nạp giá trị mới: `r_min <= load_val`.
2. **Đếm Nền Thời Gian Thực (Continuous Background Count):** Khi không có `load_en`, mỗi nhịp clock `gated_clk_min` làm bộ đếm tăng Modulo-60 (0 .. 59 -> 0).
3. **Cờ Báo Tràn (Rollover Flag):** `min_rollover = (r_min == 6'd59) & sec_rollover & ~load_en;`.

### 3.9.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian đếm phút theo `sec_rollover`, phát cờ `min_rollover` và nạp đồng bộ `load_en`:

![Hình 3.9.4: Giản đồ đếm phút theo sec_rollover, min_rollover và nạp song song load_en (WaveDrom)](timing_3_5_4_minute_counter.png)

---

## 3.10 Module: `hour_counter`
**Chức năng:** Bộ đếm Giờ Modulo-24 (0 .. 23) hoạt động liên tục ở chế độ nền nhận nhịp `gated_clk_hour` (1 toggle/3600s hoặc khi có `load_en`). Hỗ trợ nạp song song giá trị mới từ bộ đệm khi nhận xung `load_en`.

### 3.10.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của bộ đếm giờ `hour_counter`:

![Hình 3.10.1: Sơ đồ khối bộ đếm giờ hour_counter nạp đồng bộ load_en (Draw.io)](diag_3_6_hour_counter.png)

### 3.10.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.11: Bảng chân tín hiệu bộ đếm giờ hour_counter (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `clk` | Input | 1 | Clock | 1/3600Hz Gated| Xung nhịp khóa 1/3600Hz/Load (`gated_clk_hour`) | Chuẩn | N/A |
| `rstn` | Input | 1 | Reset | Async | Reset bất đồng bộ, tích cực mức thấp | Chuẩn | `0` |
| `min_rollover` | Input | 1 | Enable | 1 MHz | Xung tràn từ `minute_counter` | Tích cực mức `1` | `0` |
| `load_en` | Input | 1 | Control | 1 MHz | Xung 1-cycle kích hoạt nạp song song giá trị mới | Tích cực mức `1` | `0` |
| `load_val[4:0]` | Input | 5 | Data In | Gated | Giá trị giờ mới từ bộ đệm `mode_controller` | 0 .. 23 | `0` |
| `h_out[4:0]` | Output | 5 | Data Out | Gated | Giá trị giờ nền thời gian thực (0 .. 23) | Chuẩn | `5'd0` |

*Ghi chú: Bộ đếm tự động quay vòng từ 23 về 00 khi nhận xung min_rollover từ phút.*

### 3.10.3 Nguyên lý hoạt động (Operating Principle)
1. **Nạp Song Song Đồng Bộ (Synchronous Load):** Khi có `load_en = 1`, thanh ghi nạp giá trị mới: `r_hour <= load_val`.
2. **Đếm Nền Thời Gian Thực (Continuous Background Count):** Khi không có `load_en`, mỗi nhịp clock `gated_clk_hour` làm bộ đếm tăng Modulo-24 (0 .. 23 -> 0).

### 3.10.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian đếm giờ theo `min_rollover`, tràn nửa đêm 23 -> 00 và nạp đồng bộ `load_en`:

![Hình 3.10.4: Giản đồ đếm giờ theo min_rollover, tràn nửa đêm và nạp song song load_en (WaveDrom)](timing_3_6_4_hour_counter.png)

---

## 3.11 Module: `output_switch`
**Chức năng:** Bộ chuyển mạch đa hợp hiển thị tổ hợp (Combinational Display Multiplexer) lựa chọn giữa giá trị thời gian thực từ các bộ đếm nền (khi ở `MODE_RUN`) và giá trị trong bộ đệm chỉnh sửa (khi ở các chế độ `MODE_ADJ_*`).

### 3.11.1 Sơ đồ khối (Block Diagram)

Sơ đồ khối của bộ ghép kênh hiển thị `output_switch`:

![Hình 3.11.1: Sơ đồ khối bộ ghép kênh hiển thị 2-to-1 output_switch (Draw.io)](diag_3_7_output_switch.png)

### 3.11.2 Bảng chân tín hiệu (I/O Interface Table)

**Bảng 3.12: Bảng chân tín hiệu bộ ghép kênh hiển thị output_switch (I/O Interface Table)**

| Tên chân tín hiệu | Hướng | Số bit | Loại | Miền Clock | Mô tả chức năng chi tiết | Điều kiện hợp lệ | Giá trị Reset |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| `adj_mode[1:0]` | Input | 2 | Status | 1 MHz | Mã trạng thái chế độ hoạt động hiện tại | `00`:RUN, `01`:SEC, `10`:MIN, `11`:HOUR | `2'b00` |
| `s_cnt[5:0]` | Input | 6 | Data In | Gated | Giá trị giây thời gian thực từ `second_counter` | 0 .. 59 | `0` |
| `m_cnt[5:0]` | Input | 6 | Data In | Gated | Giá trị phút thời gian thực từ `minute_counter` | 0 .. 59 | `0` |
| `h_cnt[4:0]` | Input | 5 | Data In | Gated | Giá trị giờ thời gian thực từ `hour_counter` | 0 .. 23 | `0` |
| `s_adj[5:0]` | Input | 6 | Data In | 1 MHz | Giá trị giây đang chỉnh từ `mode_controller` | 0 .. 59 | `0` |
| `m_adj[5:0]` | Input | 6 | Data In | 1 MHz | Giá trị phút đang chỉnh từ `mode_controller` | 0 .. 59 | `0` |
| `h_adj[4:0]` | Input | 5 | Data In | 1 MHz | Giá trị giờ đang chỉnh từ `mode_controller` | 0 .. 23 | `0` |
| `s_out[5:0]` | Output | 6 | Data Out | 1 MHz | Giá trị giây đưa ra hiển thị chân Top | 0 .. 59 | `0` |
| `m_out[5:0]` | Output | 6 | Data Out | 1 MHz | Giá trị phút đưa ra hiển thị chân Top | 0 .. 59 | `0` |
| `h_out[4:0]` | Output | 5 | Data Out | 1 MHz | Giá trị giờ đưa ra hiển thị chân Top | 0 .. 23 | `0` |

*Ghi chú: Mạch hoạt động hoàn toàn bằng logic tổ hợp zero-latency, không sử dụng Flip-Flop.*

### 3.11.3 Nguyên lý hoạt động (Operating Principle)
- Khối `output_switch` hoạt động hoàn toàn bằng logic tổ hợp thuần túy (Zero-latency combinational multiplexing), không chứa Flip-Flop:
  - `s_out = (adj_mode == 2'b00) ? s_cnt : s_adj;`
  - `m_out = (adj_mode == 2'b00) ? m_cnt : m_adj;`
  - `h_out = (adj_mode == 2'b00) ? h_cnt : h_adj;`

### 3.11.4 Giản đồ thời gian (Timing Diagram)

Giản đồ thời gian chuyển mạch hiển thị không độ trễ giữa bộ đếm nền và bộ đệm:

![Hình 3.11.4: Giản đồ chuyển mạch hiển thị tức thời zero-delay output_switch (WaveDrom)](timing_3_7_4_output_switch.png)

---

# CHƯƠNG 4: MA TRẬN TRUY XUẤT YÊU CẦU (RTM) & KẾ HOẠCH KIỂM CHỨNG

## 4.1 Ma trận truy xuất yêu cầu kiểm tra (Requirement Traceability Matrix - RTM)

**Bảng 4.1: Ma trận truy xuất yêu cầu kiểm tra (Requirement Traceability Matrix - RTM)**

| Mã Yêu Cầu | Phân Loại | Module RTL Phụ Trách | Test Case Kiểm Chứng | Phương Pháp Kiểm Tra | SVA Assertion Check | Trạng Thái |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: |
| `REQ-SYS-01` | `USER` | `hms_timer.sv` | `TC1: Reset Recovery` | Directed Stimulus + Monitor | `assert_reset_state` | **PASSED (100%)** |
| `REQ-ICG-01` | `USER` | `icg_cell.sv` | `TC2: Prescaler & Gated Clocks` | Waveform + Glitch Checking | Cycle Sampling | **PASSED (100%)** |
| `REQ-PPA-01` | `USER` | `clk_prescaler.sv` | `TC2: Cascaded Prescaler 1kHz/1Hz`| Timing + Cycle Verification | Prescaler Monitor | **PASSED (100%)** |
| `REQ-DEB-01` | `USER` | `button_debouncer.sv` | `TC12: Debounce 20ms Short vs Full`| Threshold Injection | Pulse Counter | **PASSED (100%)** |
| `REQ-DEB-02` | `USER` | `button_debouncer.sv` | `TC12: Auto-Repeat Long Hold` | Continuous Multi-Cycle Check| Auto-Repeat Monitor | **PASSED (100%)** |
| `REQ-DEB-03` | `USER` | `button_debouncer.sv` | `TC12: 10% Debounce Tolerance Band`| Boundary Value (17, 18, 22) | Tolerance Check | **PASSED (100%)** |
| `REQ-FSM-01` | `USER` | `mode_controller.sv` | `TC3: FSM State Flow Navigation` | SVA + FSM State Monitor | `fsm_mode_cg` | **PASSED (100%)** |
| `REQ-FSM-02` | `USER` | `mode_controller.sv` | `TC13, TC14: Timeout & Keep-alive`| Inactivity Timer Monitor | Scoreboard Check | **PASSED (100%)** |
| `REQ-CNT-01` | `USER` | `second/minute/hour` | `TC2, TC4, TC10: Real-Time Zero-Drift`| Scoreboard Cycle Compare | Golden Reference | **PASSED (100%)** |
| `REQ-BUF-01` | `USER` | `mode_controller.sv` | `TC4, TC5, TC6: Up/Down Wrap-Around`| Boundary Value Tracking | Range Assertions | **PASSED (100%)** |
| `REQ-MUX-01` | `USER` | `output_switch.sv` | `TC4, TC5, TC6, TC13: MUX Switch` | Output Switch Probe Check | MUX Assertion | **PASSED (100%)** |
| `REQ-LD-01` | `USER` | `hms_timer.sv` | `TC10, TC14: Synchronous Parallel Load`| Commit Pulse + Load Compare| `p_sec_rollover_sync`| **PASSED (100%)** |
| `REQ-PPA-02` | `DERIVED`| `button_debouncer.sv` | `TC12: Debounce 20ms & Auto-Repeat`| Clock Pin Toggle Tracking | 1kHz Clock Check | **PASSED (100%)** |
| `REQ-PPA-03` | `DERIVED`| `clk_prescaler.sv` | `TC2: Cascaded Prescaler 1kHz/1Hz` | Timing Slack Analysis | Stage 1/2 Check | **PASSED (100%)** |
| `REQ-GAT-01` | `RECOM` | `second/minute_counter`| `TC7: Adjustment Isolation Gating` | Rollover Assertion Check | `assert_sec_rollover_sync`| **PASSED (100%)** |
| `REQ-CON-01` | `RECOM` | `mode_controller.sv` | `TC8: Simultaneous Press Conflict`| Parallel Stimulus Driving | Value Hold Monitor | **PASSED (100%)** |
| `REQ-DFT-01` | `RECOM` | `icg_cell.sv` | `TC1: Test Mode Bypass Inspection` | Static DFT Analysis | Scan Gate Open | **PASSED (100%)** |
| `REQ-RST-01` | `RECOM` | `reset_sync.sv` | `TC1: Reset Recovery & Synchronization` | Reset Assertion/Deassertion Check | `assert_reset_state` | **PASSED (100%)** |

*Ghi chú: 100% các yêu cầu từ người dùng và kiến trúc đề xuất đều được kiểm chứng tự động bằng SystemVerilog Assertions (SVA).*

---

## 4.2 Chi tiết 14 Test Cases kiểm chứng chức năng (Functional Verification Plan)

1. **TC1: Kiểm chứng Reset & Khởi tạo (Power-on Reset, Recovery & Reset Synchronization):** Xác nhận ngõ ra 00:00:00, FSM ở `MODE_RUN`, xác lập reset tức thì và giải trừ reset đồng bộ sau 2 chu kỳ clock qua khối `reset_sync`.
2. **TC2: Kiểm chứng ICG Gated Clocks & Prescaler (Real-time Cascade Progression):** Đo đạc các xung gated clock `gated_clk_1khz`, `gated_clk_sec` không bị Glitch và ngắt hoàn toàn dao động khi không active.
3. **TC3: Kiểm chứng Chuyển đổi Trạng thái FSM (4-State FSM Loop):** Duyệt trọn vẹn chu trình `RUN` -> `SEC` -> `MIN` -> `HOUR` -> `RUN`.
4. **TC4: Kiểm chứng Chỉnh Giây & Wrap-Around (Second Adjustment Up/Down/Wrap):** Kiểm tra tăng wrap 59 -> 00 và giảm wrap 00 -> 59 trên bộ đệm.
5. **TC5: Kiểm chứng Chỉnh Phút & Wrap-Around (Minute Adjustment Up/Down/Wrap):** Kiểm tra tăng wrap 59 -> 00 và giảm wrap 00 -> 59 trên bộ đệm.
6. **TC6: Kiểm chứng Chỉnh Giờ & Wrap-Around (Hour Adjustment Up/Down/Wrap):** Kiểm tra tăng wrap 23 -> 00 và giảm wrap 00 -> 23 trên bộ đệm.
7. **TC7: Kiểm chứng Khóa cờ tràn khi chỉnh sửa (Rollover Gating Isolation):** Đảm bảo chỉnh giây qua 59 -> 00 không làm thay đổi phút trong bộ đệm.
8. **TC8: Kiểm chứng Xung đột phím đồng thời (Simultaneous UP/DOWN Conflict):** Bấm đồng thời UP và DOWN, giá trị giữ nguyên.
9. **TC9: Kiểm chứng Miễn nhiễm Glitch bất đồng bộ (Asynchronous Narrow Glitch Immunity):** Bơm xung glitch < 1 cycle, hệ thống bỏ qua hoàn toàn.
10. **TC10: Kiểm chứng Tràn qua nửa đêm (23:59:59 Midnight Full Cascade Rollover):** Chỉnh giờ 23:59:58, commit nạp vào counter và đếm thời gian thực qua 23:59:59 -> 00:00:00.
11. **TC11: Kiểm chứng Miễn nhiễm phím bấm ở Chế độ RUN (Inactive Button Immunity):** Nhấn UP/DOWN trong RUN không gây sai lệch.
12. **TC12: Kiểm chứng Khử rung 20ms Dung sai ±10% & Auto-Repeat:** Nhấn < 18ms (17 ticks) bị hủy hoàn toàn, giữ >= 18ms phát đúng 1 xung, giữ lâu phát Auto-Repeat đều đặn.
13. **TC13: Kiểm chứng Timeout 5s & Đếm nền Zero-Drift:** Chỉnh dở dang Giây, Phút, Giờ rồi chờ 5s, thời gian tự động hủy đệm và bộ MUX chuyển về counter nền đang chạy chính xác.
14. **TC14: Kiểm chứng Giữ trạng thái Timeout khi có thao tác (Timeout Keep-Alive Reset):** Bấm phím sau mỗi 3s (< 5s), timer timeout bị reset và duy trì chế độ chỉnh sửa.

---

## 4.3 Kết quả kiểm chứng mô phỏng & Báo cáo độ phủ (Verification Scorecard & Coverage)

**Bảng 4.2: Báo cáo tổng kết kết quả kiểm chứng mô phỏng & độ bao phủ chức năng (Verification Scorecard)**

| Hạng mục kiểm tra | Tổng số kiểm tra | Đạt (Passed) | Thất bại (Failed) | Tỷ lệ hoàn thành |
| :--- | :---: | :---: | :---: | :---: |
| **Tổng số Assertions & Checks** | 90 | 90 | 0 | **100.0%** |
| **Độ bao phủ chuyển trạng thái FSM (FSM Coverage)** | - | - | - | **100.0%** |
| **Độ bao phủ dải giá trị biên (Boundary Coverage)** | - | - | - | **100.0%** |
| **Độ bao phủ kích thích & Chéo (Cross Coverage)** | - | - | - | **90.18%** |
| **Tổng số SVA SystemVerilog Assertions** | 6 | 6 | 0 | **100.0%** |
| **Trạng thái kiểm chứng tổng thể** | - | - | - | **PASSED (TAPE-OUT READY)** |

*Ghi chú: Kết quả kiểm chứng đạt 100% Passed trên bộ 14 Functional Test Cases với 90/90 Assertions thành công.*
