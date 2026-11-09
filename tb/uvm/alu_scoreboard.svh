// ----------------------------------------------------------------------------
// alu_scoreboard: reference model + compare.
// The model uses 32-bit int arithmetic (different style from the RTL) so it
// does not copy RTL bugs.
// ----------------------------------------------------------------------------
class alu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_scoreboard)

  uvm_analysis_imp #(alu_seq_item, alu_scoreboard) imp;

  int unsigned n_chk = 0;
  int unsigned n_err = 0;

  localparam int SMAX =  (1 << (W-1)) - 1;
  localparam int SMIN = -(1 << (W-1));
  localparam int SHW  = $clog2(W);

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction

  // Called automatically by the monitor's ap.write()
  function void write(alu_seq_item t);
    alu_seq_item exp = predict(t);
    n_chk++;
    if ({t.y, t.c, t.v, t.z, t.n} !== {exp.y, exp.c, exp.v, exp.z, exp.n}) begin
      n_err++;
      `uvm_error("MISMATCH", $sformatf("\n  got: %s\n  exp: %s",
                 t.convert2string(), exp.convert2string()))
    end
  endfunction

  // Reference model
  function alu_seq_item predict(alu_seq_item t);
    alu_seq_item e = alu_seq_item::type_id::create("exp");
    int ua, ub, sa, sb, sh, r;

    e.a = t.a;  e.b = t.b;  e.op = t.op;
    ua = int'(t.a);
    ub = int'(t.b);
    sa = int'($signed(t.a));
    sb = int'($signed(t.b));
    sh = int'(t.b[SHW-1:0]);
    e.c = 1'b0;
    e.v = 1'b0;

    case (t.op)
      OP_ADD: begin
        r   = ua + ub;
        e.y = r[W-1:0];
        e.c = (r >= (1 << W));
        e.v = ((sa + sb) > SMAX) || ((sa + sb) < SMIN);
      end
      OP_SUB: begin
        r   = ua - ub;
        e.y = r[W-1:0];
        e.c = (ua < ub);
        e.v = ((sa - sb) > SMAX) || ((sa - sb) < SMIN);
      end
      OP_AND:  e.y = t.a & t.b;
      OP_OR:   e.y = t.a | t.b;
      OP_XOR:  e.y = t.a ^ t.b;
      OP_NOT:  e.y = ~t.a;
      OP_SLL:  begin r = ua * (1 << sh); e.y = r[W-1:0]; end
      OP_SRL:  begin r = ua / (1 << sh); e.y = r[W-1:0]; end
      OP_SRA:  begin r = sa >>> sh;      e.y = r[W-1:0]; end
      OP_SLT:  e.y = (sa < sb) ? W'(1) : W'(0);
      OP_SLTU: e.y = (ua < ub) ? W'(1) : W'(0);
      default: e.y = '0;
    endcase

    e.z = (e.y == '0);
    e.n = e.y[W-1];
    return e;
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("Checks = %0d, Errors = %0d", n_chk, n_err), UVM_NONE)
    // n_chk == 0 is a FAIL: a TB that checked nothing must not report PASS
    if (n_err == 0 && n_chk > 0)
      `uvm_info("SB", "*** TEST PASSED ***", UVM_NONE)
    else
      `uvm_error("SB", "*** TEST FAILED ***")
  endfunction
endclass
