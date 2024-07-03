##########################################################################
#  File        : fp.tcl
#  Authors     : Yoan Fournier  <yoan.fournier@polymtl.ca>
#  Company     : GRM, Polytechnique Montreal
#  Description : Floorplan script for CVVEC Lane
##########################################################################

#########################
#  PREPARATORY CLEANUP #
########################

unplaceallblocks
deleteFiller -prefix ENDCAP
deleteFiller -prefix WELLTAP
deletePlaceBlockage -all
deleteRouteBlk -all
deleteHaloFromBlock -allBlock

##########################
#  SRAM MACRO INSTANCES  #
##########################

# VRF
set vrf_rams  [get_object_name [get_cells -hierarchical *R1P]]
set vrf_width [dbGet [dbGetInstByName [lindex $vrf_rams 0]].box_urx]
set vrf_height [dbGet [dbGetInstByName [lindex $vrf_rams 0]].box_ury]
set HALO_SRAM 0.64

set lane_margin 5.04
set lane_height [expr 4*$vrf_height + 5*$HALO_SRAM+ 2*$lane_margin]
set lane_width  [expr 16*$vrf_width + 2*$lane_margin]

floorPlan -coreMarginsBy io -d $lane_width $lane_height $lane_margin $lane_margin $lane_margin $lane_margin -noSnapToGrid

set fp_box [dbFPlanCoreBox [dbHeadFPlan]]
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

############
#  GUIDES  #
############

# Vertical guides for data RAMs.
set vguide_ram_height $vrf_height
set voffset $HALO_SRAM
set vspace [expr $HALO_SRAM]
set vguide_stride [expr $vguide_ram_height + $vspace]
set vguides {}
for {set i 0} {$i < 4} {incr i} {
    lappend vguides [expr $fp_y0 + $i * $vguide_stride + $voffset]
}

#########
#  VRF  #
#########

set i 0
foreach vrf_inst $vrf_rams {
    set x [expr $i % 2]
    set y [expr $i / 2]
    placeInstance $vrf_inst [list [expr $fp_x0 + $x*($vrf_width + $HALO_SRAM) + $HALO_SRAM] [lindex $vguides $y]] R0 -fixed   
    addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $vrf_inst
    #createPlaceBlockage -type soft -inst $vrf_inst -outerRingBySide $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM
    #addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $vrf_inst
    
    incr i
}

##########
#  PINS  #
##########

set port_pins [get_object_name [get_ports]]
editPin -pin $port_pins -edge 2 -layer C1 -spreadType SIDE -offsetStart [expr 0.01*$lane_height + $lane_margin] -offsetEnd [expr 0.51*$lane_height] -spacing 0.32
