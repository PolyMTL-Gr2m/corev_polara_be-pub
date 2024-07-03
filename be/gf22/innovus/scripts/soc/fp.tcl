##########################################################################
#  File        : fp.tcl
#  Authors     : Yoan Fournier  <yoan.fournier@polymtl.ca>
#  Company     : GRM, Polytechnique Montreal
#  Description : Floorplan script for soc
##########################################################################

#########################
#  PREPARATORY CLEANUP #
########################

unplaceAllBlocks
deleteFiller -prefix ENDCAP
deleteFiller -prefix WELLTAP
deletePlaceBlockage -all
deleteRouteBlk -all
deleteHaloFromBlock -allBlock
source ./scripts/common/fillperi-remove.tcl

########################
# FLOORPLAN DIMENSIONS #
########################
set socWidth  2972
set socHeight 2972
set dieMargin 26

set HALO_TILE 5.76
set HALO_FLL  26

floorPlan -coreMarginsBy io -d [list $socWidth $socHeight $dieMargin $dieMargin $dieMargin $dieMargin] -noSnapToGrid
loadIoFile ./source/soc/soc.io

# Connect I/Os
set cell_list [get_object_name [get_cells oci_inst/pad_v*]]
foreach cell $cell_list {
    attachTerm $cell BIAS    oci_inst/BIAS_S
    attachTerm $cell IOPWROK oci_inst/IOPWROK_S
    attachTerm $cell RETC    oci_inst/RETC_S
    attachTerm $cell PWROK   oci_inst/PWROK_S
}

set dieBox [dbFPlanBox [dbHeadFPlan]]
set die_ll_x [dbDBUToMicrons [lindex $dieBox 0]]
set die_ll_y [dbDBUToMicrons [lindex $dieBox 1]]
set die_ur_x [dbDBUToMicrons [lindex $dieBox 2]]
set die_ur_y [dbDBUToMicrons [lindex $dieBox 3]]

set coreBox   [dbFPlanCoreBox [dbHeadFPlan  [dbgHead]]]
set core_ll_x      [dbDBUToMicrons [lindex $coreBox 0]]
set core_ll_y      [dbDBUToMicrons [lindex $coreBox 1]]
set core_ur_x      [dbDBUToMicrons [lindex $coreBox 2]]
set core_ur_y      [dbDBUToMicrons [lindex $coreBox 3]]

set fp_box [dbFPlanCoreBox [dbHeadFPlan]]
set fp_x0 [dbDBUToMicrons [lindex $fp_box 0]]
set fp_y0 [dbDBUToMicrons [lindex $fp_box 1]]
set fp_x1 [dbDBUToMicrons [lindex $fp_box 2]]
set fp_y1 [dbDBUToMicrons [lindex $fp_box 3]]
set fp_dx [expr $fp_x1 - $fp_x0]
set fp_dy [expr $fp_y1 - $fp_y0]

set fp_die_box [dbFPlanBox [dbHeadFPlan]]
set fp_die_x0 [dbDBUToMicrons [lindex $fp_die_box 0]]
set fp_die_y0 [dbDBUToMicrons [lindex $fp_die_box 1]]
set fp_die_x1 [dbDBUToMicrons [lindex $fp_die_box 2]]
set fp_die_y1 [dbDBUToMicrons [lindex $fp_die_box 3]]

# Removing around the corners
set pad_fix 64
cutRow -area  $core_ll_x  $core_ll_y [expr $core_ll_x + $pad_fix] [expr $core_ll_x + $pad_fix]
cutRow -area  $core_ur_x  $core_ll_y [expr $core_ur_x - $pad_fix] [expr $core_ll_x + $pad_fix]
cutRow -area  $core_ur_x  $core_ur_y [expr $core_ur_x - $pad_fix] [expr $core_ur_y - $pad_fix]
cutRow -area  $core_ll_x  $core_ur_y [expr $core_ll_x + $pad_fix] [expr $core_ur_y - $pad_fix]
 
redraw

#########
# TILES #
#########
set tile0 [get_object_name [get_cells -hierarchical tile0*]]
set tile1 [get_object_name [get_cells -hierarchical tile1*]]
set tile2 [get_object_name [get_cells -hierarchical tile2*]]
set tile3 [get_object_name [get_cells -hierarchical tile3*]]

set tileWidth   [dbGet [dbGetInstByName $tile0].box_urx]
set tileHeight  [dbGet [dbGetInstByName $tile0].box_ury]
set tileXOffset 100
set tileYOffset 145
set tileYspace 28
set endCapX 0.936
set endCapY 0.645

placeInstance $tile0 [list [expr $tileXOffset]                              [expr $tileHeight + $tileYOffset + $tileYspace]] -fixed
placeInstance $tile1 [list [expr $socWidth - ($tileWidth + $tileXOffset)]   [expr $tileHeight + $tileYOffset + $tileYspace]] -fixed
placeInstance $tile2 [list [expr $tileXOffset]                              [expr $tileYOffset]]               -fixed
placeInstance $tile3 [list [expr $socWidth - ($tileWidth + $tileXOffset)]   [expr $tileYOffset]]               -fixed

addHaloToBlock $HALO_TILE $HALO_TILE $HALO_TILE $HALO_TILE $tile0
addHaloToBlock $HALO_TILE $HALO_TILE $HALO_TILE $HALO_TILE $tile1
addHaloToBlock $HALO_TILE $HALO_TILE $HALO_TILE $HALO_TILE $tile2
addHaloToBlock $HALO_TILE $HALO_TILE $HALO_TILE $HALO_TILE $tile3

createPlaceBlockage -type soft -box [list 0 0 $socWidth [expr 2*$tileHeight + $tileYOffset + $tileYspace + $HALO_TILE]]

#######
# FLL #
#######
set fll [get_object_name [get_cells -hierarchical *behav_fll*]]
set fllWidth   [dbGet [dbGetInstByName $fll].box_urx]
set fllHeight  [dbGet [dbGetInstByName $fll].box_ury]

set fllX [expr 2*$tileWidth + $fllWidth] 
set fllY [expr 2*$tileHeight + 5*$fllHeight]

placeInstance $fll [list $fllX $fllY] -fixed
addHaloToBlock $HALO_FLL $HALO_FLL $HALO_FLL $HALO_FLL $fll

#############
# CDC FIFOs #
#############
set HALO_FIFO 1.28

set fifo_out_1  [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_out*fifo_1*"]]
set fifo_out_2  [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_out*fifo_2*"]]
set fifo_out_3  [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_out*fifo_3*"]]

set fifo_out_width   [dbGet [dbGetInstByName $fifo_out_1].box_urx]
set fifo_out_height  [dbGet [dbGetInstByName $fifo_out_1].box_ury]

set fifo_in_1   [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_in*fifo_1*"]]
set fifo_in_2   [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_in*fifo_2*"]]
set fifo_in_3   [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_in*fifo_3*"]]

set fifo_credit [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *chip_*_in*credit_fifo*"]]

set fifoOffset 96.4
set fifoSpace  [expr $fifo_out_width + 0.64]

set tapCellsSpace 49.92

placeInstance $fifo_out_1 [list [expr $fifoOffset + 2*$tapCellsSpace]                [expr 2*$tileHeight + 7.5*$dieMargin]]
placeInstance $fifo_out_2 [list [expr $fifoOffset + $fifoSpace + 2*$tapCellsSpace]   [expr 2*$tileHeight + 7.5*$dieMargin]]
placeInstance $fifo_out_3 [list [expr $fifoOffset + 2*$fifoSpace + 2*$tapCellsSpace] [expr 2*$tileHeight + 7.5*$dieMargin]]

placeInstance [lindex $fifo_in_1 0] [list [expr $fifoOffset + 9*$fifoSpace  + 1.5*$tapCellsSpace]  [expr 2*$tileHeight + 9*$dieMargin]]
placeInstance [lindex $fifo_in_1 1] [list [expr $fifoOffset + 10*$fifoSpace + 1.5*$tapCellsSpace]  [expr 2*$tileHeight + 9*$dieMargin]]
placeInstance [lindex $fifo_in_2 0] [list [expr $fifoOffset + 9*$fifoSpace  + 2.5*$tapCellsSpace]  [expr 2*$tileHeight + 9*$dieMargin]]
placeInstance [lindex $fifo_in_2 1] [list [expr $fifoOffset + 10*$fifoSpace + 2.5*$tapCellsSpace]  [expr 2*$tileHeight + 9*$dieMargin]]
placeInstance [lindex $fifo_in_3 0] [list [expr $fifoOffset + 9*$fifoSpace  + 3.5*$tapCellsSpace]  [expr 2*$tileHeight + 9*$dieMargin]]
placeInstance [lindex $fifo_in_3 1] [list [expr $fifoOffset + 10*$fifoSpace + 3.5*$tapCellsSpace]  [expr 2*$tileHeight + 9*$dieMargin]]

placeInstance $fifo_credit [list [expr 8.25*$dieMargin + 1.5*$tapCellsSpace] [expr 2*$tileHeight + 7*$dieMargin + $fifo_out_height]]

addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO $fifo_out_1
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO $fifo_out_2
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO $fifo_out_3
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO [lindex $fifo_in_1 0] 
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO [lindex $fifo_in_1 1]
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO [lindex $fifo_in_2 0]
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO [lindex $fifo_in_2 1]
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO [lindex $fifo_in_3 0]
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO [lindex $fifo_in_3 1]
addHaloToBlock $HALO_FIFO $HALO_FIFO $HALO_FIFO $HALO_FIFO $fifo_credit

##############
# IO FILLERS #
##############
source ./scripts/common/fillperi-insert.tcl

###############################
##   PLACE METROLOGY CELLS   ##
###############################
set metrology_pos {}
lappend metrology_pos [list [expr $socWidth/2 - 5]        [expr 3000*2/3 - 5 - (3000-$socHeight)/2] ]
lappend metrology_pos [list [expr $socWidth/2 - 5 - 1403] [expr 3000*2/3 - 5 - (3000-$socHeight)/2] ]
lappend metrology_pos [list [expr $socWidth/2 - 5 + 1403] [expr 3000*2/3 - 5 - (3000-$socHeight)/2] ]
lappend metrology_pos [list [expr $socWidth/2 - 5]        [expr 3000*1/3 - 5 - (3000-$socHeight)/2] ]
lappend metrology_pos [list [expr $socWidth/2 - 5 - 1403] [expr 3000*1/3 - 5 - (3000-$socHeight)/2] ]
lappend metrology_pos [list [expr $socWidth/2 - 5 + 1403] [expr 3000*1/3 - 5 - (3000-$socHeight)/2] ]

deleteInst TGPCI_*
set i 0
foreach pos $metrology_pos {
    addInst -physical -cell TGPCI_10M_2Mx_6Cx_2Ix_LB -inst TGPCI_$i -loc $pos
    # addHaloToBlock 2 2 2 2 TGPCI_$i
    set ptr [dbGetInstByName TGPCI_$i]
    createPlaceBlockage -box [list \
        [expr [dbGet $ptr.box_llx]-1] \
        [expr [dbGet $ptr.box_lly]-1] \
        [expr [dbGet $ptr.box_urx]+1] \
        [expr [dbGet $ptr.box_ury]+1] \
    ]
    incr i
}

redraw
