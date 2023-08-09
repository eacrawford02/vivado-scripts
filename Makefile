part-num:=xc7a35ticsg324-1l
build-tcl:=$(CURDIR)/build.tcl
schm-tcl:=$(CURDIR)/schm.tcl
synth-tcl:=$(CURDIR)/synth.tcl
pnr-tcl:=$(CURDIR)/place-route.tcl
xdc-file:=$(CURDIR)/Arty-A7-35-Master.xdc
out-dir:=$(CURDIR)/out
src-dir:=$(CURDIR)/src
sim-dir:=$(CURDIR)/sim
tb:=tb
# Design checkpoint to launch GUI with, can be one of {synth, route}
impl-dcp:=synth
#=== DELETE IF NOT ON WSL ===#
usbipd-dir:=C:\Program Files\usbipd-win\usbipd
busid:=2-7 # Run `usbipd wsl list` on host to obtain busid

# ------------------------
# Implementation Flow
# ------------------------

#=== Default config - build project and program device over JTAG ===#
.PHONY : build
build :
	@echo "### CONNECTING USB DEVICE ###"
	cmd.exe /C "$(usbipd-dir)" wsl detach --busid $(busid)
	cmd.exe /C "$(usbipd-dir)" wsl attach --busid $(busid)
	@echo "### BUILDING PROJECT ###"
	vivado -mode batch -source $(build-tcl) -tclargs $(out-dir) $(part-num)\
	 $(src-dir) $(xdc-file)

#=== VIEW SCHEMATIC ===#
.PHONY : schematic schm
schematic schm : $(out-dir)/post_$(impl-dcp).dcp
	@echo
	@echo "### OPENING SCHEMATIC ###"
	vivado -mode gui -source $(schm-tcl) $(out-dir)/post_$(impl-dcp).dcp

#=== PLACE AND ROUTE TARGET ===#
.PHONY : place-route pnr
place-route pnr : $(out-dir)/post_route.dcp

$(out-dir)/post_route.dcp : $(out-dir)/post_synth.dcp
	@echo
	@echo "### RUNNING PLACE AND ROUTE ###"
	vivado -mode batch -source $(pnr-tcl) -tclargs $(out-dir)

#=== SYNTHESIS TARGET ===#
.PHONY : synthesis synth
synthesis synth : $(out-dir)/post_synth.dcp

$(out-dir)/post_synth.dcp : $(src-dir)/*.sv
	@echo
	@echo "### SYNTHESIZING DESIGN, GENERATING REPORTS ###"
	vivado -mode batch -source $(synth-tcl) -tclargs $(out-dir) $(part-num)\
	 $(src-dir) $(xdc-file)

# ------------------------
#  Verification Flow
# ------------------------

#==== WAVEFORM DRAWING ====#
.PHONY : waves
waves : $(tb)_snapshot.wdb
	@echo
	@echo "### OPENING WAVES ###"
	xsim --gui $(tb)_snapshot.wdb

#=== COMPILIATION, ELABORATION, AND SIMULATION TARGETS ===#
.PHONY : simulate sim
simulate sim : $(tb)_snapshot.wdb

.PHONY : elaborate elab
elaborate elab : .elab-timestamp

.PHONY : compile comp
compile comp : .compile-timestamp

#==== SIMULATION ====#
$(tb)_snapshot.wdb : .elab-timestamp
	@echo
	@echo "### RUNNING SIMULATION ###"
	xsim -tclbatch xsim_cfg.tcl $(tb)_snapshot

#==== ELABORATION ====#
.elab-timestamp : .compile-timestamp
	@echo
	@echo "### ELABORATING ###"
	xelab -debug all -snapshot $(tb)_snapshot $(tb)
	touch .elab-timestamp

#==== COMPILING SYSTEMVERILOG ====#
.compile-timestamp : $(src-dir)/*.sv
	@echo
	@echo "### COMPILING SYSTEMVERILOG ###"
	xvlog -sv -incr `find -regextype posix-extended -regex '.*\.(sv|v)'`
	touch .compile-timestamp

#=== Clean up project directory ===#
.PHONY : clean
clean :
	rm -rf out/*
	rm -rf *.jou *.log *.pb *.wdb *.str xsim.dir
	rm -rf .*-timestamp
