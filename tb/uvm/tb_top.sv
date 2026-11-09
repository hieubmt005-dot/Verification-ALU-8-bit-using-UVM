// ----------------------------------------------------------------------------
// File   : tb_top.sv
// Desc   : Static top: clock, interface, DUT, hand vif to UVM, start test.
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import alu_uvm_pkg::*;

  logic clk = 1'b0;
  always #5 clk = ~clk;          // 100 MHz TB clock (sampling only)

  alu_if vif (clk);

  alu #(.WIDTH(8)) dut (
    .i_a        (vif.a),
    .i_b        (vif.b),
    .i_op       (vif.op),
    .o_y        (vif.y),
    .o_carry    (vif.c),
    .o_overflow (vif.v),
    .o_zero     (vif.z),
    .o_neg      (vif.n)
  );

  initial begin
    // Make the virtual interface visible to every component under the test
    uvm_config_db#(virtual alu_if)::set(null, "uvm_test_top.*", "vif", vif);
    run_test();                  // test name comes from +UVM_TESTNAME
  end

  // Waveform (Vivado: open the .wdb from xsim; VCD here for GTKWave)
  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
