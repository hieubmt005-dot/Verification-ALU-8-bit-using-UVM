// ----------------------------------------------------------------------------
// alu_agent: groups sequencer + driver + monitor for one interface.
// ACTIVE  = drives stimulus (sqr + drv + mon)
// PASSIVE = observes only (mon) - reused when this block sits inside an SoC
// ----------------------------------------------------------------------------
typedef uvm_sequencer #(alu_seq_item) alu_sequencer;

class alu_agent extends uvm_agent;
  `uvm_component_utils(alu_agent)

  alu_sequencer sqr;
  alu_driver    drv;
  alu_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = alu_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = alu_sequencer::type_id::create("sqr", this);
      drv = alu_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
