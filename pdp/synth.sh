#!/bin/bash

XILINX_PATH=/opt/Xilinx/14.7/ISE_DS

source $XILINX_PATH/settings64.sh

cd /home/pdp/PDP/pdp/pdp_ISE/

xst -intstyle ise -ifn "top_ml410.xst" -ofn "top_ml410.syr"

ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc ml410.ucf -p xc4vfx60-ff1152-11 top_ml410.ngc top_ml410.ngd

map -intstyle ise -p xc4vfx60-ff1152-11 -global_opt off -cm area -ir off -pr off -c 100 -o top_ml410_map.ncd top_ml410.ngd top_ml410.pcf

par -w -intstyle ise -ol high -t 1 top_ml410_map.ncd top_ml410.ncd top_ml410.pcf

trce -intstyle ise -v 3 -tsi top_ml410.tsi -s 11 -n 3 -fastpaths -xml top_ml410.twx top_ml410.ncd -o top_ml410.twr top_ml410.pcf -ucf ml410.ucf

bitgen -intstyle ise -f top_ml410.ut top_ml410.ncd
