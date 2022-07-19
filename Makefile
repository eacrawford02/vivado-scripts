part-num:=xc7a35ticsg324-1l
build-tcl:=$(CURDIR)/build.tcl
xdc-file:=$(CURDIR)/Arty-A7-35-Master.xdc
out-dir:=$(CURDIR)/out
src-dir:=$(CURDIR)/src
tb-top:=$(CURDIR)/sim/tb-top.sv
#=== DELETE IF NOT ON WSL ===#
usbipd-dir:=C:\Program Files\usbipd-win\usbipd
busid:=2-7 # Run `usbipd wsl list` on host to obtain busid

#=== Default config - build project and program device over JTAG ===#
.PHONY : build
build :
	@echo "### CONNECTING USB DEVICE ###"
	cmd.exe /C "$(usbipd-dir)" wsl detach --busid $(busid)
	cmd.exe /C "$(usbipd-dir)" wsl attach --busid $(busid)
	@echo "### BUILDING PROJECT ###"
	vivado -mode batch -source $(build-tcl) -tclargs $(out-dir) $(part-num)\
	 $(src-dir) $(xdc-file)

#==== WAVEFORM DRAWING ====#
.PHONY : waves
waves : sim_snapshot.wdb
	@echo
	@echo "### OPENING WAVES ###"
	xsim --gui sim_snapshot.wdb

#=== COMPILIATION, ELABORATION, AND SIMULATION TARGETS ===#
.PHONY : simulate
simulate : sim_snapshot.wdb

.PHONY : elaborate
elaborate : .elab-timestamp

.PHONY : compile
compile : .compile-timestamp

#==== SIMULATION ====#
sim_snapshot.wdb : .elab-timestamp
	@echo
	@echo "### RUNNING SIMULATION ###"
	xsim -tclbatch xsim_cfg.tcl tb-top_snapshot

#==== ELABORATION ====#
.elab-timestamp : .compile-timestamp
	@echo
	@echo "### ELABORATING ###"
	xelab -debug all -snapshot tb-top_snapshot $(tb-top)
	touch .elab-timestamp

#==== COMPILING SYSTEMVERILOG ====#
.compile-timestamp : $(src-dir)/*.sv
	@echo
	@echo "### COMPILING SYSTEMVERILOG ###"
	xvlog -sv -incr $(src-dir)/*.sv
	touch .compile-timestamp

#=== Clean up project directory ===#
.PHONY : clean
clean :
	rm -rf *.jou *.log *.pb *.wdb xsim.dir
	rm -rf .*-timestamp
