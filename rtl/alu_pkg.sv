// ----------------------------------------------------------------------------
// File   : alu_pkg.sv
// Desc   : Opcode definitions shared by RTL and testbench.
//          Sharing one package avoids RTL/TB opcode mismatch bugs.
// ----------------------------------------------------------------------------
package alu_pkg;

  typedef enum logic [3:0] {
    OP_ADD  = 4'd0,   // y = a + b
    OP_SUB  = 4'd1,   // y = a - b
    OP_AND  = 4'd2,   // y = a & b
    OP_OR   = 4'd3,   // y = a | b
    OP_XOR  = 4'd4,   // y = a ^ b
    OP_NOT  = 4'd5,   // y = ~a          (b ignored)
    OP_SLL  = 4'd6,   // y = a << b[2:0] (logical)
    OP_SRL  = 4'd7,   // y = a >> b[2:0] (logical)
    OP_SRA  = 4'd8,   // y = a >>> b[2:0] (arithmetic, keeps sign)
    OP_SLT  = 4'd9,   // y = (signed a < signed b) ? 1 : 0
    OP_SLTU = 4'd10   // y = (unsigned a < unsigned b) ? 1 : 0
    // 11..15: reserved -> y = 0
  } alu_op_e;

endpackage
