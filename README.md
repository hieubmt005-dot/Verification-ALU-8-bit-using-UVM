# alu8 — ALU 8-bit + Verification

## Mục đích

Một project nhỏ để học flow front-end cơ bản:

1. **Design** một ALU 8-bit bằng SystemVerilog, synthesizable.
2. **Verify** bằng một testbench self-checking đơn giản.
3. **Verify** lại bằng một testbench UVM cơ bản, có thêm random stimulus,
   scoreboard và functional coverage.
4. **Chứng minh testbench hoạt động đúng** bằng cách cố tình cài bug vào RTL
   và kiểm tra testbench có bắt được không.

Tool: Vivado 2024.2 (xsim), Ubuntu 22.04.

---

## Cấu trúc project

```
alu8/
├── README.md          ← file này (tổng quan)
├── Makefile           # tất cả lệnh build / run
├── rtl/               # design                → xem rtl/README.md
│   ├── alu_pkg.sv
│   └── alu.sv
└── tb/                # verification          → xem tb/README.md
    ├── tb_alu.sv      # testbench đơn giản
    └── uvm/           # testbench UVM         → xem tb/uvm/README.md
```

---

## Các bước thực hiện

```
 Spec ──► RTL (alu.sv) ──► TB đơn giản ──► UVM TB ──► Cài bug ──► Xong
                            exhaustive      random +    (mutation test)
                            PASS/FAIL       coverage
```

1. Viết spec gồm 11 phép toán và 4 flag (xem `rtl/README.md`).
2. Viết RTL dạng combinational, không có latch.
3. Testbench đơn giản: thử **toàn bộ** input có thể có (khoảng 1 triệu trường
   hợp) và so sánh từng output với reference model.
4. Testbench UVM: chạy random test với nhiều seed, đo coverage để chắc chắn
   mọi trường hợp đã được test.
5. Mutation test: cố tình làm sai RTL, và testbench báo lỗi. Điều này chứng
   minh checker thực sự hoạt động.

---

## Chạy nhanh

```bash
make sim                         # testbench đơn giản
make uvm TEST=alu_rand_test      # testbench UVM
make clean
```

---

## Kết quả

| Testbench | Test | Số lần check | Lỗi | Coverage |
|-----------|------|--------------|-----|----------|
| Đơn giản  | directed + exhaustive | 1,048,576+ | 0 | toàn bộ input |
| UVM       | alu_corner_test | 400 | 0 | 83 % |
| UVM       | alu_rand_test (5 seed) | 5,400 mỗi seed | 0 | 100 % |
| UVM       | cài bug vào SRA | — | **bắt được** | — |

**Kết luận:** ALU đúng spec, và testbench có khả năng phát hiện bug thật.

---

## Đọc tiếp

| Thư mục | Nội dung |
|---------|----------|
| [`rtl/`](rtl/README.md) | Spec ALU: port, opcode, flag, ghi chú thiết kế |
| [`tb/`](tb/README.md) | Testbench self-checking đơn giản |
| [`tb/uvm/`](tb/uvm/README.md) | Cấu trúc UVM, chi tiết coverage, mutation test, các lỗi đã gặp |

## References
https://chipverify.com/
https://www.accellera.org/downloads/standards/uvm
