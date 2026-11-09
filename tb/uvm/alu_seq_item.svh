// ----------------------------------------------------------------------------
// alu_seq_item: one ALU operation (stimulus + observed response)
// ----------------------------------------------------------------------------
class alu_seq_item extends uvm_sequence_item;
  `uvm_object_utils(alu_seq_item)

  // Stimulus - randomized. 'bit' (2-state) is enough for stimulus.
  rand bit [W-1:0] a;
  rand bit [W-1:0] b;
  rand bit [3:0]   op;

  // Response - filled by the monitor. 'logic' (4-state) so X/Z is visible.
  logic [W-1:0] y;
  logic         c, v, z, n;

  // ~95% legal opcodes, ~5% reserved (11..15)
  constraint c_op_dist {
    op dist { [0:10] :/ 95, [11:15] :/ 5 };
  }

  // Bias operands toward corner values. Ranges must not overlap.
  // (Literals assume W = 8.)
  constraint c_a_dist {
    a dist { 8'h00 := 5, 8'h01 := 5, 8'h7F := 5, 8'h80 := 5, 8'hFF := 5,
             [8'h02:8'h7E] :/ 40, [8'h81:8'hFE] :/ 35 };
  }
  constraint c_b_dist {
    b dist { 8'h00 := 5, 8'h01 := 5, 8'h7F := 5, 8'h80 := 5, 8'hFF := 5,
             [8'h02:8'h7E] :/ 40, [8'h81:8'hFE] :/ 35 };
  }

  function new(string name = "alu_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("op=%-4s a=%h b=%h | y=%h c=%b v=%b z=%b n=%b",
                     op_name(op), a, b, y, c, v, z, n);
  endfunction

    // Plain case instead of enum .name(): xsim crashed on the cast + .name()
  static function string op_name(bit [3:0] o);
    case (o)
      OP_ADD:  return "ADD";
      OP_SUB:  return "SUB";
      OP_AND:  return "AND";
      OP_OR:   return "OR";
      OP_XOR:  return "XOR";
      OP_NOT:  return "NOT";
      OP_SLL:  return "SLL";
      OP_SRL:  return "SRL";
      OP_SRA:  return "SRA";
      OP_SLT:  return "SLT";
      OP_SLTU: return "SLTU";
      default: return $sformatf("RSV%0d", o);
    endcase
  endfunction

endclass
