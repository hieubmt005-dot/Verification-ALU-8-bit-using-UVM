// ----------------------------------------------------------------------------
// alu_driver: takes items from the sequencer and drives them on the interface
// One item per clock cycle; valid=0 on cycles with no item.
// ----------------------------------------------------------------------------
class alu_driver extends uvm_driver #(alu_seq_item);
  `uvm_component_utils(alu_driver)

  virtual alu_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual alu_if not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.valid <= 1'b0;
    forever begin
      @(vif.drv_cb);                       // wait for posedge clk
      seq_item_port.try_next_item(req);    // non-blocking: null if no item ready
      if (req != null) begin
        vif.drv_cb.a     <= req.a;
        vif.drv_cb.b     <= req.b;
        vif.drv_cb.op    <= req.op;
        vif.drv_cb.valid <= 1'b1;
        seq_item_port.item_done();         // tell the sequence this item is done
      end else begin
        vif.drv_cb.valid <= 1'b0;          // idle cycle
      end
    end
  endtask
endclass
