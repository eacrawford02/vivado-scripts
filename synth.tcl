# Tcl script to synthesize logic and generate detailed utilization reports.
# Expects four arguments:
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

