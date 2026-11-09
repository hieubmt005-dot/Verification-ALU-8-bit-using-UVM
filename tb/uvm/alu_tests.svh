// ----------------------------------------------------------------------------
// Tests: select with +UVM_TESTNAME=<name>
//   alu_corner_test     - 400 directed corner items
//   alu_rand_test       - corner + N constrained-random items (+N_ITEMS=<n>)
//   alu_exhaustive_test - all 1,048,576 combinations (slow)
// ----------------------------------------------------------------------------
class alu_base_test extends uvm_test;
  `uvm_component_utils(alu_base_test)

  alu_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = alu_env::type_id::create("env", this);
    // Stop after 20 UVM_ERRORs instead of flooding the log
    uvm_report_server::get_server().set_max_quit_count(20);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();   // print the component tree once
  endfunction

  // Each test overrides this with its own stimulus
  virtual task run_seq();
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);   // keep the simulation alive
    run_seq();
    #50ns;                         // drain: let the monitor catch the last item
    phase.drop_objection(this);    // no objections left -> run_phase ends
  endtask
endclass


class alu_corner_test extends alu_base_test;
  `uvm_component_utils(alu_corner_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_seq();
    alu_corner_seq seq = alu_corner_seq::type_id::create("seq");
    seq.start(env.agt.sqr);
  endtask
endclass


class alu_rand_test extends alu_base_test;
  `uvm_component_utils(alu_rand_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_seq();
    alu_corner_seq c_seq = alu_corner_seq::type_id::create("c_seq");
    alu_rand_seq   r_seq = alu_rand_seq::type_id::create("r_seq");
    void'($value$plusargs("N_ITEMS=%d", r_seq.n_items));   // optional override
    `uvm_info("TEST", $sformatf("corner + %0d random items", r_seq.n_items), UVM_LOW)
    c_seq.start(env.agt.sqr);   // directed first: closes corner bins quickly
    r_seq.start(env.agt.sqr);   // random: fills the rest
  endtask
endclass


class alu_exhaustive_test extends alu_base_test;
  `uvm_component_utils(alu_exhaustive_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_seq();
    alu_exhaustive_seq seq = alu_exhaustive_seq::type_id::create("seq");
    seq.start(env.agt.sqr);
  endtask
endclass
