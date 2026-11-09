# ----------------------------------------------------------------------------
# Makefile for alu8
#   make lint      - Verilator lint on RTL only
#   make sim       - Vivado xsim (default simulator)
#   make sim_vl    - Verilator simulation (needs Verilator >= 5 for --timing)
#   make wave      - open VCD in GTKWave
#   make clean
# ----------------------------------------------------------------------------
TOP     := tb_alu
# Order matters: package must be compiled before files that import it
RTL     := rtl/alu_pkg.sv rtl/alu.sv
TB      := tb/tb_alu.sv

# ---- UVM (Vivado xsim, built-in UVM 1.2 library) ----
UVM_DIR := tb/uvm
UVM_SRC := $(UVM_DIR)/alu_if.sv $(UVM_DIR)/alu_uvm_pkg.sv $(UVM_DIR)/tb_top.sv
# Comments kept on their own lines: a trailing "# ..." after a value would
# leave trailing spaces inside the variable (classic Make gotcha).
# TEST: alu_corner_test | alu_rand_test | alu_exhaustive_test
TEST    ?= alu_rand_test
# SEED: use SEED=random for a new seed each run
SEED    ?= 1
N_ITEMS ?= 5000

.PHONY: lint sim sim_vl wave clean uvm_comp uvm

lint:
	# -Wall: all warnings; --top-module: which module is the root
	verilator --lint-only -Wall $(RTL) --top-module alu

sim:
	# xvlog: compile SV sources into the xsim work library
	xvlog -sv $(RTL) $(TB)
	# xelab: elaborate top into snapshot 'tb_alu_snap'; -debug typical keeps signals visible
	xelab $(TOP) -s tb_alu_snap -debug typical --timescale 1ns/1ps
	# xsim: run snapshot to the end ($finish)
	xsim tb_alu_snap -runall

sim_vl:
	# --binary: build an executable; --timing: support #delays in TB
	# -Wno-fatal: TB-only width warnings shouldn't stop the build
	verilator --binary --timing --assert -Wno-fatal $(RTL) $(TB) \
	          --top-module $(TOP) -o sim_$(TOP)
	./obj_dir/sim_$(TOP)

uvm_comp:
	# -L uvm: link Vivado's precompiled UVM library
	# --include: search path for the `include "*.svh" files in the package
	xvlog -sv -L uvm --include $(UVM_DIR) $(RTL) $(UVM_SRC)
	xelab tb_top -L uvm -s tb_top_snap -debug typical --timescale 1ns/1ps

uvm: uvm_comp
	# -testplusarg passes +UVM_TESTNAME / +N_ITEMS into the simulation
	# -sv_seed: seed for randomize(); same seed = same stimulus (reproducible)
	xsim tb_top_snap -runall -sv_seed $(SEED) \
	     -testplusarg UVM_TESTNAME=$(TEST) -testplusarg N_ITEMS=$(N_ITEMS) \
	     -log uvm_$(TEST).log

wave:
	gtkwave tb_alu.vcd &

clean:
	rm -rf obj_dir xsim.dir *.jou *.log *.pb *.wdb *.vcd .Xil
