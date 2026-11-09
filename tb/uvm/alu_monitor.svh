// ----------------------------------------------------------------------------
// alu_monitor: passively observes the interface, rebuilds transactions and
// broadcasts them via an analysis port. It knows nothing about the expected
// result - that is the scoreboard's job.
// ----------------------------------------------------------------------------
class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)

  virtual alu_if vif;
  uvm_analysis_port #(alu_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual alu_if not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    alu_seq_item tr;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.valid === 1'b1) begin   // === : X/Z valid counts as "not valid"
        tr    = alu_seq_item::type_id::create("tr");
        tr.a  = vif.mon_cb.a;
        tr.b  = vif.mon_cb.b;
        tr.op = vif.mon_cb.op;
        tr.y  = vif.mon_cb.y;
        tr.c  = vif.mon_cb.c;
        tr.v  = vif.mon_cb.v;
        tr.z  = vif.mon_cb.z;
        tr.n  = vif.mon_cb.n;
        `uvm_info("MON", tr.convert2string(), UVM_HIGH)
        ap.write(tr);                        // send to scoreboard + coverage
      end
    end
  endtask
endclass
