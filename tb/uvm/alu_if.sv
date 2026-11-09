// ----------------------------------------------------------------------------
// File   : alu_if.sv
// Desc   : Interface between UVM classes and the DUT.
//          The ALU itself is combinational; the TB adds a clock only to give
//          the driver/monitor a common sampling point (one transaction/cycle).
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

interface alu_if (input logic clk);

  logic [7:0] a, b, y;
  logic [3:0] op;
  logic       c, v, z, n;
  logic       valid;     // TB-only: 1 when a, b, op hold a real transaction

  // Driver: drives 1 ns AFTER posedge -> no race with sampling at the edge
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output a, b, op, valid;
  endclocking

  // Monitor: samples just BEFORE posedge (#1step) -> sees inputs driven in the
  // previous cycle and the DUT outputs already settled
  clocking mon_cb @(posedge clk);
    default input #1step;
    input a, b, op, valid, y, c, v, z, n;
  endclocking

endinterface
