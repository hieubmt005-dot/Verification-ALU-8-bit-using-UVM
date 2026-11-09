# tb/ — Verification

Thư mục này có hai testbench cho cùng một ALU:

| Testbench              | Vị trí                                      |
| ---------------------- | ------------------------------------------- |
| Self-checking đơn giản | `tb_alu.sv`                                 |
| UVM                    | `uvm/` → xem [uvm/README.md](uvm/README.md) |

Trang này nói về **testbench đơn giản**.

---

## Testbench đơn giản (`tb_alu.sv`)

### Ý tưởng

```
 input ──► DUT ──► output thực tế ──┐
   │                                ├──► so sánh ──► đếm lỗi ──► PASS / FAIL
   └────► reference model ──────────┘
          (output mong đợi)
```

1. Đặt giá trị input.
2. Chờ 1 ns để mạch combinational ổn định.
3. Tính kết quả mong đợi bằng reference model.
4. So sánh với output của DUT và đếm mỗi lần sai.

### Hai phase

| Phase | Nội dung | Số lượng |
|-------|----------|----------|
| 1. Directed | Giá trị biên 00, 01, 7F, 80, FF với mọi opcode, cộng thêm các case kinh điển (127+1 overflow, 255+1 carry, 0-1 borrow, …). Có lưu waveform. | ~400 |
| 2. Exhaustive | **Mọi** opcode × mọi `a` × mọi `b` | 16 × 256 × 256 = 1,048,576 |

Với block 8-bit, test toàn bộ input chỉ mất vài giây, nên không bỏ sót trường
hợp nào. Với ALU 32-bit thì không thể làm vậy, và phải dùng random kết hợp
coverage. Đó là việc của testbench UVM.



---

## Run

```bash
make sim       # Vivado xsim
make sim_vl    # Verilator (bản 5+)
make wave      # xem waveform của phase 1 trên GTKWave
```
