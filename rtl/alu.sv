// ----------------------------------------------------------------------------
// File   : alu.sv
// Desc   : Parameterized combinational ALU (default 8-bit).
// Flags  : o_carry    - ADD: carry-out; SUB: borrow (1 when a < b unsigned)
//          o_overflow - signed overflow, ADD/SUB only
//          o_zero     - o_y == 0
//          o_neg      - o_y[MSB]
//          carry/overflow are 0 for all other ops.
// ----------------------------------------------------------------------------
module alu
  import alu_pkg::*;
#(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0] i_a,
  input  logic [WIDTH-1:0] i_b,
  input  logic [3:0]       i_op,
  output logic [WIDTH-1:0] o_y,
  output logic             o_carry,
  output logic             o_overflow,
  output logic             o_zero,
  output logic             o_neg
);

  localparam int SHW = $clog2(WIDTH);   // shift-amount width (3 for 8-bit)

  logic [WIDTH:0]   add_r;   // one extra bit to capture carry-out
  logic [WIDTH:0]   sub_r;   // extra bit = borrow
  logic [SHW-1:0]   shamt;

  assign add_r = {1'b0, i_a} + {1'b0, i_b};
  assign sub_r = {1'b0, i_a} - {1'b0, i_b};
  assign shamt = i_b[SHW-1:0];

  always_comb begin
    // Defaults first -> no inferred latch for any op
    o_y        = '0;
    o_carry    = 1'b0;
    o_overflow = 1'b0;

    case (i_op)
      OP_ADD: begin
        o_y        = add_r[WIDTH-1:0];
        o_carry    = add_r[WIDTH];
        // Overflow: operands same sign, result sign differs
        o_overflow = (i_a[WIDTH-1] == i_b[WIDTH-1]) &&
                     (add_r[WIDTH-1] != i_a[WIDTH-1]);
      end
      OP_SUB: begin
        o_y        = sub_r[WIDTH-1:0];
        o_carry    = sub_r[WIDTH];      // borrow
        // Overflow: operands differ in sign, result sign differs from a
        o_overflow = (i_a[WIDTH-1] != i_b[WIDTH-1]) &&
                     (sub_r[WIDTH-1] != i_a[WIDTH-1]);
      end
      OP_AND:  o_y = i_a & i_b;
      OP_OR:   o_y = i_a | i_b;
      OP_XOR:  o_y = i_a ^ i_b;
      OP_NOT:  o_y = ~i_a;
      OP_SLL:  o_y = i_a << shamt;
      OP_SRL:  o_y = i_a >> shamt;
      OP_SRA:  o_y = $signed(i_a) >>> shamt;   // operand must be signed for >>>
      OP_SLT:  o_y = {{(WIDTH-1){1'b0}}, ($signed(i_a) < $signed(i_b))};
      OP_SLTU: o_y = {{(WIDTH-1){1'b0}}, (i_a < i_b)};
      default: o_y = '0;                       // reserved opcodes
    endcase
  end

  assign o_zero = (o_y == '0);
  assign o_neg  = o_y[WIDTH-1];

endmodule
