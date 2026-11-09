# rtl/ — Thiết kế ALU

| File | Nội dung |
|------|----------|
| `alu_pkg.sv` | Danh sách opcode (`OP_ADD`, `OP_SUB`, …). RTL và testbench dùng chung, nên opcode không bao giờ bị lệch nhau. |
| `alu.sv` | ALU. Combinational, synthesizable, parameter `WIDTH = 8`. |

---

## Port

| Port | Hướng | Độ rộng | Mô tả |
|------|-------|---------|-------|
| `i_a` | in | 8 | Toán hạng A |
| `i_b` | in | 8 | Toán hạng B (`i_b[2:0]` đồng thời là shift amount) |
| `i_op` | in | 4 | Opcode |
| `o_y` | out | 8 | Kết quả |
| `o_carry` | out | 1 | Carry-out (ADD) hoặc borrow (SUB) |
| `o_overflow` | out | 1 | Tràn số có dấu (chỉ ADD / SUB) |
| `o_zero` | out | 1 | Bằng 1 khi `o_y == 0` |
| `o_neg` | out | 1 | `o_y[7]` (bit dấu) |

Không có clock và reset: output thay đổi ngay khi input thay đổi.

---

## Opcode

| Op | Tên | Kết quả |
|----|-----|---------|
| 0 | ADD  | a + b |
| 1 | SUB  | a - b |
| 2 | AND  | a & b |
| 3 | OR   | a \| b |
| 4 | XOR  | a ^ b |
| 5 | NOT  | ~a |
| 6 | SLL  | a << b[2:0] |
| 7 | SRL  | a >> b[2:0] (chèn bit 0) |
| 8 | SRA  | a >>> b[2:0] (chèn bit dấu) |
| 9 | SLT  | 1 nếu a < b, có dấu |
| 10 | SLTU | 1 nếu a < b, không dấu |
| 11–15 | — | 0 (dự phòng) |

Với mọi op khác ADD và SUB, `o_carry` và `o_overflow` luôn bằng 0.

---

## Ghi chú thiết kế

- **Không có latch:** mọi output được gán giá trị mặc định ở đầu
  `always_comb`, nên nhánh nào cũng gán đủ mọi output.
- **Carry:** phép cộng và phép trừ được tính trên 9 bit; bit 8 là carry
  hoặc borrow.
- **Overflow:**
  - ADD tràn khi hai toán hạng cùng dấu nhưng kết quả mang dấu ngược lại.
  - SUB tràn khi hai toán hạng khác dấu và dấu của kết quả khác dấu của `a`.
- **SRA cần `$signed`:** `>>>` chỉ chèn bit dấu khi toán hạng là kiểu signed.
  Thiếu `$signed`, SRA âm thầm hoạt động giống SRL. Đây chính là bug được
  dùng để kiểm tra testbench (xem `tb/uvm/README.md`).

---

## Lint

```bash
make lint      # verilator --lint-only -Wall
```
