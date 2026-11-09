// ----------------------------------------------------------------------------
// Sequences: generate streams of alu_seq_item
// ----------------------------------------------------------------------------

// Base: helper to send one item with fixed values (no randomization)
class alu_base_seq extends uvm_sequence #(alu_seq_item);
  `uvm_object_utils(alu_base_seq)

  function new(string name = "alu_base_seq");
    super.new(name);
  endfunction

  task send(bit [3:0] t_op, bit [W-1:0] t_a, bit [W-1:0] t_b);
    alu_seq_item it;
    it = alu_seq_item::type_id::create("it");
    start_item(it);        // wait until the driver asks for an item
    it.op = t_op;
    it.a  = t_a;
    it.b  = t_b;
    finish_item(it);       // hand it to the driver, wait for item_done()
  endtask
endclass


// Constrained-random: n_items items using the constraints in alu_seq_item
class alu_rand_seq extends alu_base_seq;
  `uvm_object_utils(alu_rand_seq)

  int unsigned n_items = 5000;

  function new(string name = "alu_rand_seq");
    super.new(name);
  endfunction

  task body();
    repeat (n_items) begin
      req = alu_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize())
        `uvm_fatal("RAND", "alu_seq_item randomize() failed")
      finish_item(req);
    end
  endtask
endclass


// Directed: every opcode x corner(a) x corner(b) = 16 x 5 x 5 = 400 items
class alu_corner_seq extends alu_base_seq;
  `uvm_object_utils(alu_corner_seq)

  bit [W-1:0] corner[] = '{8'h00, 8'h01, 8'h7F, 8'h80, 8'hFF};

  function new(string name = "alu_corner_seq");
    super.new(name);
  endfunction

  task body();
    for (int o = 0; o < 16; o++)
      foreach (corner[i])
        foreach (corner[j])
          send(o[3:0], corner[i], corner[j]);
  endtask
endclass


// Exhaustive: 16 x 256 x 256 = 1,048,576 items (slow in UVM, golden sign-off)
class alu_exhaustive_seq extends alu_base_seq;
  `uvm_object_utils(alu_exhaustive_seq)

  function new(string name = "alu_exhaustive_seq");
    super.new(name);
  endfunction

  task body();
    for (int o = 0; o < 16; o++)
      for (int i = 0; i < (1 << W); i++)
        for (int j = 0; j < (1 << W); j++)
          send(o[3:0], i[W-1:0], j[W-1:0]);
  endtask
endclass
