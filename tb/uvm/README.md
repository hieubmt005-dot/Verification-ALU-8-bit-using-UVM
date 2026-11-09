# tb/uvm/ — Testbench UVM

## Structure 

```
tb_top (module): clock, DUT, interface
└── test
    └── env
        ├── agent
        │   ├── sequencer → driver → DUT
        │   └── monitor ← DUT
        ├── scoreboard  ← monitor   (kết quả có đúng không?)
        └── coverage    ← monitor   (đã test đủ chưa?)
```

## Files

| File | Thành phần | Nhiệm vụ |
|------|------------|----------|
| `alu_if.sv` | interface | Gom các tín hiệu của DUT để các class truy cập |
| `alu_seq_item.svh` | seq_item | Một phép toán ALU (a, b, op + kết quả). Giá trị random được ưu tiên rơi vào các giá trị biên. |
| `alu_sequences.svh` | sequences | Sinh nhiều item: corner, random, exhaustive |
| `alu_driver.svh` | driver | Đưa mỗi item lên chân DUT, mỗi clock một item |
| `alu_monitor.svh` | monitor | Quan sát chân DUT, gửi những gì thấy được sang scoreboard + coverage |
| `alu_scoreboard.svh` | scoreboard | Tính kết quả mong đợi và so sánh |
| `alu_coverage.svh` | coverage | Ghi nhận những trường hợp đã được test |
| `alu_agent.svh` | agent | Gom sequencer + driver + monitor |
| `alu_env.svh` | env | Gom agent + scoreboard + coverage |
| `alu_tests.svh` | tests | Chọn sequence nào sẽ chạy |
| `alu_uvm_pkg.sv` | package | Include tất cả các file class |
| `tb_top.sv` | top | Clock, DUT, khởi động UVM |

**ALU không có clock, vậy tại sao TB lại có?** Driver và monitor cần một
thời điểm chung để hoạt động. Driver đổi input ngay sau mỗi cạnh clock.
Monitor đọc chân DUT ngay trước cạnh clock kế tiếp, lúc output đã ổn định.

---

## Các test

| Test | Stimulus | Số item |
|------|----------|---------|
| `alu_corner_test` | Giá trị biên 00, 01, 7F, 80, FF với mọi op | 400 |
| `alu_rand_test` | Corner + random (`N_ITEMS`, mặc định 5000) | 5,400 |
| `alu_exhaustive_test` | Mọi input | 1,048,576 (chậm) |

```bash
make uvm TEST=alu_corner_test
make uvm TEST=alu_rand_test SEED=random N_ITEMS=20000
grep -E "\[SB\]|\[COV\]" uvm_alu_rand_test.log
```

- `SEED` quyết định các giá trị random. Cùng một seed luôn cho cùng một test,
  nên lỗi có thể được tái hiện. Với `SEED=random`, seed thực tế được in ra
  trong log.
- Tiêu chí pass: log có `TEST PASSED` **và** `UVM_ERROR : 0`.

---

## Kết quả

| Test | Số lần check | Lỗi | Coverage |
|------|--------------|-----|----------|
| alu_corner_test | 400 | 0 | 83.14 % |
| alu_rand_test | 5,400 | 0 | 100 % |
| alu_rand_test, N_ITEMS=20000 | 20,400 | 0 | 100 % |
| alu_rand_test, seed 1–5 | 5,400 mỗi seed | 0 | PASS |

---

## Chi tiết coverage

### Những gì được đo

| Coverpoint | Kiểm tra điều gì | Bin |
|------------|------------------|-----|
| `cp_op`     | Mọi opcode đều đã được dùng | 11 (mỗi op một bin) + 1 bin cho nhóm dự phòng 11–15 |
| `cp_a`      | `a` thuộc loại giá trị nào | zero (00), one (01), smax (7F), smin (80), ones (FF), pos (02–7E), neg (81–FE) |
| `cp_b`      | Tương tự cho `b` | 7 bin như trên |
| `cp_shamt`  | Mọi shift amount đều đã dùng với SLL/SRL/SRA | 0, 1, …, 7 |
| `cp_arith`  | ADD và SUB đều đã được dùng | add, sub |
| `cp_carry`  | Flag carry đã xuất hiện cả 0 lẫn 1 | 0, 1 |
| `cp_ovf`    | Flag overflow đã xuất hiện cả 0 lẫn 1 | 0, 1 |
| `cx_op_a_b` | Mọi op × mọi loại `a` × mọi loại `b` | 12 × 7 × 7 = 588 |
| `cx_arith_carry` | ADD có carry 0/1, SUB có borrow 0/1 | 4 |
| `cx_arith_ovf`   | ADD và SUB, mỗi phép có overflow 0/1 | 4 |

Một **bin** là một trường hợp cần thấy ít nhất một lần.
Một **cross** (`cx_`) là tổ hợp của nhiều coverpoint.

### Vì sao corner test cho đúng 83.14 %

Con số tổng là **trung bình của 10 item ở trên**, không phải trung bình trên
tất cả các bin:

| Item | Bin đã hit | % |
|------|------------|---|
| cp_op | 12 / 12 | 100 |
| cp_a | 5 / 7 (thiếu pos, neg) | 71.43 |
| cp_b | 5 / 7 (thiếu pos, neg) | 71.43 |
| cp_shamt | 3 / 8 (chỉ có 0, 1, 7) | 37.5 |
| cp_arith | 2 / 2 | 100 |
| cp_carry | 2 / 2 | 100 |
| cp_ovf | 2 / 2 | 100 |
| cx_op_a_b | 12 × 5 × 5 = 300 / 588 | 51.02 |
| cx_arith_carry | 4 / 4 | 100 |
| cx_arith_ovf | 4 / 4 | 100 |
| **Trung bình** | | **83.14** |

Vì sao một số item thấp:
- Các giá trị biên không bao giờ rơi vào khoảng `pos` hoặc `neg`.
- `b[2:0]` của 00, 01, 7F, 80, FF chỉ là 0, 1 hoặc 7, nên thiếu 5 shift amount.

Giá trị random lấp các lỗ hổng này, vì vậy `alu_rand_test` đạt 100 %.

Bài học: cross lớn (588 bin, chỉ đạt 51 %) có trọng số ngang với một
coverpoint nhỏ chỉ có 2 bin. Vì thế 83 % nghe có vẻ cao trong khi vẫn còn
288 trường hợp chưa được test. Luôn xem từng item, đừng chỉ nhìn con số tổng.

---

## Testbench có thực sự bắt được bug không? (mutation test)

0 lỗi và 100 % coverage chỉ cho biết các trường hợp đã được chạy. Chúng không
chứng minh checker hoạt động đúng. Để kiểm tra checker, hãy cố tình làm sai RTL:

```bash
cp rtl/alu.sv rtl/alu.sv.bak
sed -i 's/\$signed(i_a) >>> shamt/i_a >>> shamt/' rtl/alu.sv   # SRA thành SRL
make uvm TEST=alu_rand_test
grep -E "got:|exp:" uvm_alu_rand_test.log | head
mv rtl/alu.sv.bak rtl/alu.sv                                    # khôi phục
```

Kết quả: scoreboard báo mismatch.

```
got: op= SRA a=80 b=01 | y=40 ... n=0
exp: op= SRA a=80 b=01 | y=c0 ... n=1
```

Mọi lỗi đều có op = SRA, `a` âm và shift amount lớn hơn 0, đúng những chỗ mà
bug này lộ ra. Testbench hoạt động đúng.

---


