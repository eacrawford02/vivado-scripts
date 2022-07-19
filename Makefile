part-num:=xc7a35ticsg324-1l
build-tcl:=$(CURDIR)/build.tcl
xdc-file:=$(CURDIR)/Arty-A7-35-Master.xdc
out-dir:=$(CURDIR)/out
src-dir:=$(CURDIR)/src
#=== DELETE IF NOT ON WSL ===#
usbipd-dir:=C:\Program Files\usbipd-win\usbipd
busid:=2-7 # Run `usbipd wsl list` on host to obtain busid

.PHONY : build
build :
	@echo "### CONNECTING USB DEVICE ###"
	cmd.exe /C "$(usbipd-dir)" wsl detach --busid $(busid)
	cmd.exe /C "$(usbipd-dir)" wsl attach --busid $(busid)
	@echo "### BUILDING PROJECT ###"
	vivado -mode batch -source $(build-tcl) -tclargs $(out-dir) $(part-num)\
	 $(src-dir) $(xdc-file)
