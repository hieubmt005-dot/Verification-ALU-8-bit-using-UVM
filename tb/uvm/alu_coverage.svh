// ----------------------------------------------------------------------------
// alu_coverage: functional coverage - answers "what HAVE we tested?"
// (Scoreboard answers "was it correct?"; coverage answers "is it enough?")
// ----------------------------------------------------------------------------
class alu_coverage extends uvm_subscriber #(alu_seq_item);
  `uvm_component_utils(alu_coverage)

  covergroup cg_alu with function sample(alu_seq_item t);
    option.per_instance = 1;

    cp_op: coverpoint t.op {
      bins op[]    = {[0:10]};     // one bin per legal opcode
      bins reserved = {[11:15]};
    }

    cp_a: coverpoint t.a {
      bins zero = {8'h00};
      bins one  = {8'h01};
      bins smax = {8'h7F};
      bins smin = {8'h80};
      bins ones = {8'hFF};
      bins pos  = {[8'h02:8'h7E]};
      bins neg  = {[8'h81:8'hFE]};
    }

    cp_b: coverpoint t.b {
      bins zero = {8'h00};
      bins one  = {8'h01};
      bins smax = {8'h7F};
      bins smin = {8'h80};
      bins ones = {8'hFF};
      bins pos  = {[8'h02:8'h7E]};
      bins neg  = {[8'h81:8'hFE]};
    }

    // Every shift amount 0..7 seen on shift ops
    cp_shamt: coverpoint t.b[2:0] iff (t.op inside {OP_SLL, OP_SRL, OP_SRA});

    // Flags only meaningful for ADD/SUB
    cp_arith: coverpoint t.op {
      bins add = {OP_ADD};
      bins sub = {OP_SUB};
    }
    cp_carry: coverpoint t.c;
    cp_ovf:   coverpoint t.v;

    // Crosses
    cx_op_a_b:     cross cp_op, cp_a, cp_b;      // 12 x 7 x 7 = 588 bins
    cx_arith_carry: cross cp_arith, cp_carry;    // ADD carry, SUB borrow both 0/1
    cx_arith_ovf:   cross cp_arith, cp_ovf;      // overflow 0/1 on ADD and SUB
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_alu = new();
  endfunction

  function void write(alu_seq_item t);
    cg_alu.sample(t);
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%",
              cg_alu.get_inst_coverage()), UVM_NONE)
  endfunction
endclass
