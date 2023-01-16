# Tcl script to synthesize logic and generate bitstream. Expects four arguments:
# 1. Output directory for storing reports
# 2. Part number for the target FPGA
# 3. Directory containing HDL source files
# 4. Design constraint file (.xdc)

if { $argc != 4 } {
  puts "Error: Expecting four inputs."
  exit 2
}
set outDir [lindex $argv 0]
set_part [lindex $argv 1]
set srcDir [lindex $argv 2]
set constraints [lindex $argv 3]
# Clean up from previous builds
set prevOut [glob -nocomplain "$outDir/*"]
if {[llength $prevOut] != 0} {
  # Clear directory contents
  puts "Deleting contents of $outDir from previous build"
  file delete -force {*}[glob -directory $outDir *]; 
} else {
  puts "$outDir is empty"
}
# STEP 1: setup design sources and constraints
while {[llength $srcDir]} {
  # The name variable holds the next directory we will check for further sub- 
  # directories
  set srcDir [lassign $srcDir name]
  # Append any subdirectories in the current directory to the master srcDir list
  lappend srcDir {*}[glob -nocomplain -directory $name -type d *]
  # Append any source files in the current directory to the srcFiles list
  lappend srcFiles {*}[glob -nocomplain -directory $name -type f *{.sv,.v}]
}
read_verilog -sv $srcFiles
read_xdc $constraints
# STEP 2: run synthesis, report utilization and timing estimates, write checkpoint design
synth_design -top [lindex [find_top -files $srcFiles] 0]
write_checkpoint -force $outDir/post_synth
report_utilization -file $outDir/post_synth_util.rpt
report_timing -sort_by group -max_paths 5 -path_type summary -file $outDir/post_synth_timing.rpt
# STEP 3: run placement and logic optimization, report utilization and timing estimates
opt_design
power_opt_design
place_design
phys_opt_design
write_checkpoint -force $outDir/post_place
report_clock_utilization -file $outDir/clock_util.rpt
report_utilization -file $outDir/post_place_util.rpt
report_timing -sort_by group -max_paths 5 -path_type summary -file $outDir/post_place_timing.rpt
# STEP 4: run router, report actual utilization and timing, write checkpoint design, run DRCs
route_design
write_checkpoint -force $outDir/post_route
report_timing_summary -file $outDir/post_route_timing_summary.rpt
report_utilization -file $outDir/post_route_util.rpt
report_power -file $outDir/post_route_power.rpt
report_methodology -file $outDir/post_impl_checks.rpt
report_drc -file $outDir/post_imp_drc.rpt
write_verilog -force $outDir/impl_netlist.v
write_xdc -no_fixed_only -force $outDir/impl.xdc
# STEP 5: generate a bitstream
write_bitstream $outDir/design.bit
# STEP 6: program device
open_hw_manager
connect_hw_server
current_hw_target [lindex [get_hw_targets] 0]
open_hw_target
# Use the first available hardware device. This works if there is only one 
# device connected; for multiple devices, consider specifying the device, e.g., 
# [get_hw_devices xc7a35t_0]
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE $outDir/design.bit [current_hw_device]
program_hw_devices [current_hw_device]
close_hw_target
disconnect_hw_server
close_hw_manager
