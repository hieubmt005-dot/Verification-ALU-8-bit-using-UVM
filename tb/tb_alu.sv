// ----------------------------------------------------------------------------
// File   : tb_alu.sv
// Desc   : Self-checking testbench for alu.sv
//   Phase 1 - directed corner cases (0, 1, 7F, 80, FF) on every opcode,
//             waveform dumped for debug.
//   Phase 2 - EXHAUSTIVE: all 16 opcodes x 256 x 256 = 1,048,576 vectors.
//             For an 8-bit combinational block this is cheap, so it gives
//             100% input-space coverage -> no need for random tests.
//   Checker - reference model written with 32-bit 'int' math (a different
//             style from the RTL), so the TB does not copy RTL bugs.
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_alu;
  import alu_pkg::*;

  localparam int W    = 8;
  localparam int SMAX =  (1 << (W-1)) - 1;   //  127
  localparam int SMIN = -(1 << (W-1));       // -128
  localparam int SHW  = $clog2(W);
  localparam int MAX_ERR_PRINT = 10;

  // DUT signals
  logic [W-1:0] a, b, y;
  logic [3:0]   op;
  logic         c, v, z, n;

  int n_chk = 0;
  int n_err = 0;

  alu #(.WIDTH(W)) dut (
    .i_a(a), .i_b(b), .i_op(op),
    .o_y(y), .o_carry(c), .o_overflow(v), .o_zero(z), .o_neg(n)
  );

  // --------------------------------------------------------------------------
  // Reference model + compare. Call after inputs have settled.
  // --------------------------------------------------------------------------
  task automatic check();
    int ua, ub, sa, sb, sh, r;
    logic [W-1:0] ey;
    logic         ec, ev, ez, en;

    ua = int'(a);            // zero-extend
    ub = int'(b);
    sa = int'($signed(a));   // sign-extend
    sb = int'($signed(b));
    sh = int'(b[SHW-1:0]);
    ec = 1'b0;
    ev = 1'b0;

    case (op)
      OP_ADD: begin
        r  = ua + ub;
        ey = r[W-1:0];
        ec = (r >= (1 << W));
        ev = ((sa + sb) > SMAX) || ((sa + sb) < SMIN);
      end
      OP_SUB: begin
        r  = ua - ub;
        ey = r[W-1:0];                       // low bits of 2's complement
        ec = (ua < ub);                      // borrow
        ev = ((sa - sb) > SMAX) || ((sa - sb) < SMIN);
      end
      OP_AND:  ey = a & b;
      OP_OR:   ey = a | b;
      OP_XOR:  ey = a ^ b;
      OP_NOT:  ey = ~a;
      OP_SLL:  begin r = ua * (1 << sh); ey = r[W-1:0]; end   // multiply instead of <<
      OP_SRL:  begin r = ua / (1 << sh); ey = r[W-1:0]; end   // divide instead of >>
      OP_SRA:  begin r = sa >>> sh;      ey = r[W-1:0]; end   // 32-bit signed shift
      OP_SLT:  ey = (sa < sb) ? W'(1) : W'(0);
      OP_SLTU: ey = (ua < ub) ? W'(1) : W'(0);
      default: ey = '0;
    endcase

    ez = (ey == '0);
    en = ey[W-1];

    n_chk++;
    if ({y, c, v, z, n} !== {ey, ec, ev, ez, en}) begin   // !== also catches X/Z
      n_err++;
      if (n_err <= MAX_ERR_PRINT)
        $display("[ERR] t=%0t op=%0d a=%h b=%h | got y=%h c=%b v=%b z=%b n=%b | exp y=%h c=%b v=%b z=%b n=%b",
                 $time, op, a, b, y, c, v, z, n, ey, ec, ev, ez, en);
    end
  endtask

  // Apply one vector, wait for combinational logic to settle, then check
  task automatic drive(input logic [3:0] t_op, input logic [W-1:0] t_a, t_b);
    op = t_op;
    a  = t_a;
    b  = t_b;
    #1;
    check();
  endtask

  // --------------------------------------------------------------------------
  // Stimulus
  // --------------------------------------------------------------------------
  logic [W-1:0] corner [5] = '{8'h00, 8'h01, 8'h7F, 8'h80, 8'hFF};

  initial begin
    $dumpfile("tb_alu.vcd");
    $dumpvars(0, tb_alu);

    // ---- Phase 1: directed corner cases ----
    $display("Phase 1: directed corner cases");
    for (int o = 0; o < 16; o++)
      foreach (corner[i])
        foreach (corner[j])
          drive(o[3:0], corner[i], corner[j]);

    // A few hand-picked "classic" cases, easy to read in the waveform
    drive(OP_ADD, 8'h7F, 8'h01);   // 127 + 1  -> signed overflow, y=80
    drive(OP_ADD, 8'hFF, 8'h01);   // 255 + 1  -> carry, y=00, zero
    drive(OP_SUB, 8'h80, 8'h01);   // -128 - 1 -> signed overflow
    drive(OP_SUB, 8'h00, 8'h01);   // 0 - 1    -> borrow, y=FF
    drive(OP_SRA, 8'h80, 8'h07);   // -128 >>> 7 -> FF
    drive(OP_SLT, 8'hFF, 8'h01);   // -1 < 1 signed   -> 1
    drive(OP_SLTU,8'hFF, 8'h01);   // 255 < 1 unsigned -> 0

    $dumpoff;   // exhaustive phase would make the VCD ~hundreds of MB

    // ---- Phase 2: exhaustive ----
    $display("Phase 2: exhaustive (16 ops x 256 x 256)");
    for (int o = 0; o < 16; o++)
      for (int i = 0; i < (1 << W); i++)
        for (int j = 0; j < (1 << W); j++)
          drive(o[3:0], i[W-1:0], j[W-1:0]);

    // ---- Report ----
    $display("--------------------------------------------");
    $display("Checks: %0d   Errors: %0d", n_chk, n_err);
    if (n_err == 0) $display("*** TEST PASSED ***");
    else            $display("*** TEST FAILED ***");
    $display("--------------------------------------------");
    $finish;
  end

endmodule
