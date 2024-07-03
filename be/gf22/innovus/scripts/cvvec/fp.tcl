##########################################################################
#  File        : fp.tcl
#  Authors     : Yoan Fournier  <yoan.fournier@polymtl.ca>
#  Company     : GRM, Polytechnique Montreal
#  Description : Floorplan script for CVVEC
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

##########################
#  SRAM MACRO INSTANCES  #
##########################

# Lanes
set Lanes      [get_object_name [get_cells -hierarchical *lane]]

# Caches
set ICacheTag  [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *icache*tag*"]]
set ICacheData [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *icache*data*"]]
set DCacheTag  [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *dcache*tag*"]]
set DCacheData [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *dcache*data*"]]

set HALO_SRAM 1.44
set HALO_LANE 5.76

# Widths
set LaneWidth        [dbGet [dbGetInstByName [lindex $Lanes 0]     ].box_urx]
set LaneHeight       [dbGet [dbGetInstByName [lindex $Lanes 0]     ].box_ury]
set ICacheDataWidth  [dbGet [dbGetInstByName [lindex $ICacheData 0]].box_urx]
set ICacheDataHeight [dbGet [dbGetInstByName [lindex $ICacheData 0]].box_ury]
set ICacheTagWidth   [dbGet [dbGetInstByName [lindex $ICacheTag 0] ].box_urx]
set ICacheTagHeight  [dbGet [dbGetInstByName [lindex $ICacheTag 0] ].box_ury]
set DCacheDataWidth  [dbGet [dbGetInstByName [lindex $DCacheData 0]].box_urx]
set DCacheDataHeight [dbGet [dbGetInstByName [lindex $DCacheData 0]].box_ury]
set DCacheTagWidth   [dbGet [dbGetInstByName [lindex $DCacheTag 0] ].box_urx]
set DCacheTagHeight  [dbGet [dbGetInstByName [lindex $DCacheTag 0] ].box_ury]

set cvvecMargin 5.76
set cvvecWidth  [expr 2.35*$LaneWidth]
set cvvecHeight [expr 2*$LaneHeight + 2*$DCacheDataHeight + 2.5*$HALO_SRAM + 1*$HALO_LANE + 2*$cvvecMargin]

floorPlan -coreMarginsBy io -d $cvvecWidth $cvvecHeight $cvvecMargin $cvvecMargin $cvvecMargin $cvvecMargin -noSnapToGrid

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

###########
#  LANES  #
###########
placeInstance [lindex $Lanes 0] [list [expr $fp_x0] [expr 0*$LaneHeight + $cvvecMargin + 0*$HALO_LANE]] R0 -fixed
placeInstance [lindex $Lanes 1] [list [expr $fp_x0] [expr 1*$LaneHeight + $cvvecMargin + 0.125*$HALO_LANE]] R0 -fixed
placeInstance [lindex $Lanes 2] [list [expr $fp_x1 - $LaneWidth] [expr 0*$LaneHeight + $cvvecMargin + 0*$HALO_LANE]] MY -fixed
placeInstance [lindex $Lanes 3] [list [expr $fp_x1 - $LaneWidth] [expr 1*$LaneHeight + $cvvecMargin + 0.125*$HALO_LANE]] MY -fixed

addHaloToBlock 0            0                       $HALO_LANE  [expr 0.125*$HALO_LANE] [lindex $Lanes 0]
addHaloToBlock 0            [expr 0.125*$HALO_LANE] $HALO_LANE  $HALO_LANE              [lindex $Lanes 1]
addHaloToBlock $HALO_LANE   0                       0           [expr 0.125*$HALO_LANE] [lindex $Lanes 2]
addHaloToBlock $HALO_LANE   [expr 0.125*$HALO_LANE] 0           $HALO_LANE              [lindex $Lanes 3]

########
#  I$  #
########

# Place the ways
set ICacheXOffset [expr $fp_x0 + $HALO_SRAM] 
set ICacheYOffset [expr $fp_y0 + 2*$LaneHeight + 1.5*$HALO_SRAM + 1*$HALO_LANE]
for {set way 0} {$way < [expr [llength $ICacheData]/2]} {incr way} {
    placeInstance [lindex $ICacheData [expr 2*$way]] [list [expr $ICacheXOffset + $way*($ICacheDataWidth + $HALO_SRAM)] [expr $ICacheYOffset]] R0 -fixed
    placeInstance [lindex $ICacheData [expr 2*$way+1]] [list [expr $ICacheXOffset + $way*($ICacheDataWidth + $HALO_SRAM)] [expr $ICacheYOffset + $ICacheDataHeight + $HALO_SRAM]] R0 -fixed
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $ICacheData [expr 2*$way]]
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $ICacheData [expr 2*$way+1]]
}

for {set way 0} {$way < [expr [llength $ICacheTag]/2]} {incr way} {
    placeInstance [lindex $ICacheTag [expr 2*$way]] [list [expr $ICacheXOffset + ([llength $ICacheData]/2)*$ICacheDataWidth + $way*($ICacheTagWidth + $HALO_SRAM) + 4*$HALO_SRAM] [expr $ICacheYOffset]] R0 -fixed
    placeInstance [lindex $ICacheTag [expr 2*$way+1]] [list [expr $ICacheXOffset + ([llength $ICacheData]/2)*$ICacheDataWidth + $way*($ICacheTagWidth + $HALO_SRAM) + 4*$HALO_SRAM] [expr $ICacheYOffset + $ICacheDataHeight + $HALO_SRAM]] R0 -fixed
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $ICacheTag [expr 2*$way]]
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $ICacheTag [expr 2*$way+1]]
}

########
#  D$  #
########

# Place the ways
set DCacheXOffset [expr $fp_x1]
set DCacheYOffset [expr $fp_y0 + 2*$LaneHeight + 1.5*$HALO_SRAM + 1*$HALO_LANE]
for {set way 0} {$way < [expr [llength $DCacheData] / 2]} {incr way} {
    placeInstance [lindex $DCacheData [expr 2*$way]] [list [expr $DCacheXOffset - ($way+1)*($DCacheDataWidth + $HALO_SRAM)] [expr $DCacheYOffset]] MY -fixed
    placeInstance [lindex $DCacheData [expr 2*$way+1]] [list [expr $DCacheXOffset - ($way+1)*($DCacheDataWidth + $HALO_SRAM)] [expr $DCacheYOffset + $DCacheDataHeight + $HALO_SRAM]] MY -fixed
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $DCacheData [expr 2*$way]]
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $DCacheData [expr 2*$way+1]]
}

for {set way 0} {$way < [expr [llength $DCacheTag]/2]} {incr way} {
    placeInstance [lindex $DCacheTag [expr 2*$way]] [list [expr $DCacheXOffset - ([llength $DCacheData]/2)*$DCacheDataWidth - ($way+1)*($DCacheDataWidth + $HALO_SRAM) - 2*$HALO_SRAM] [expr $DCacheYOffset]] MY -fixed
    placeInstance [lindex $DCacheTag [expr 2*$way+1]] [list [expr $DCacheXOffset - ([llength $DCacheData]/2)*$DCacheDataWidth - ($way+1)*($DCacheDataWidth + $HALO_SRAM) - 2*$HALO_SRAM] [expr $DCacheYOffset + $DCacheDataHeight + $HALO_SRAM]] MY -fixed
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $DCacheTag [expr 2*$way]]
    addHaloToBlock  $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM [lindex $DCacheTag [expr 2*$way+1]]
}

##########
#  PINS  #
##########

set port_pins [get_object_name [get_ports]]
editPin -pin $port_pins -edge 1 -layer C4 -spreadType SIDE -spacing 0.32 -offsetStart [expr 4*$ICacheDataWidth + 5*$HALO_SRAM + $cvvecMargin] -offsetEnd [expr 2*$DCacheDataWidth + 3*$HALO_SRAM + $cvvecMargin]
