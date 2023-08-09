# Tcl script to run optimization, placement, and routing tools. Expects one
# argument:
# 1. Output directory for storing reports

if { $argc != 1 } {
  puts "Error: Expecting one input."
  exit 2
}
set outDir [lindex $argv 0]
open_checkpoint $outDir/post_synth.dcp
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

