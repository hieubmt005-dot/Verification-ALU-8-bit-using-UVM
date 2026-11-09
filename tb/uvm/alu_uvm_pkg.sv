// ----------------------------------------------------------------------------
// File   : alu_uvm_pkg.sv
// Desc   : All UVM classes for the ALU testbench. Order matters: a class must
//          be included after every class it uses.
// ----------------------------------------------------------------------------
package alu_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import alu_pkg::*;

  localparam int W = 8;

  `include "alu_seq_item.svh"
  `include "alu_sequences.svh"
  `include "alu_driver.svh"
  `include "alu_monitor.svh"
  `include "alu_scoreboard.svh"
  `include "alu_coverage.svh"
  `include "alu_agent.svh"
  `include "alu_env.svh"
  `include "alu_tests.svh"
endpackage
