##########################################################################
#  File        : fp.tcl
#  Authors     : Yoan Fournier  <yoan.fournier@polymtl.ca>
#  Company     : GRM, Polytechnique Montreal
#  Description : Floorplan script for tile
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

set cvvec       [get_object_name [get_cells -hierarchical g_ariane_core*]]

set L2Data      [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *l2*data*"]]
set L2Tag       [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *l2*tag*"]]
set L2State     [get_object_name [get_cells -hierarchical *R2P -filter "@full_name =~ *l2*state*"]]
set L2Dir       [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *l2*dir*"]]

set L15Data      [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *l15*data*"]]
set L15Tag       [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *l15*tag*"]]
set L15HMT       [get_object_name [get_cells -hierarchical *R1P -filter "@full_name =~ *l15*hmt*"]]

set HALO_SRAM 1.44
set HALO_LANE 5.76

# Widths
set cvvecHeight [dbGet [dbGetInstByName [lindex $cvvec 0] ].box_ury]
set cvvecWidth  [dbGet [dbGetInstByName [lindex $cvvec 0] ].box_urx]

set L2DataWidth     [dbGet [dbGetInstByName [lindex $L2Data 0] ].box_urx]
set L2DataHeight    [dbGet [dbGetInstByName [lindex $L2Data 0] ].box_ury]
set L2TagWidth      [dbGet [dbGetInstByName [lindex $L2Tag 0]  ].box_urx]
set L2TagHeight     [dbGet [dbGetInstByName [lindex $L2Tag 0]  ].box_ury]
set L2StateWidth    [dbGet [dbGetInstByName [lindex $L2State 0]].box_urx]
set L2StateHeight   [dbGet [dbGetInstByName [lindex $L2State 0]].box_ury]
set L2DirWidth      [dbGet [dbGetInstByName [lindex $L2Dir 0]  ].box_urx]
set L2DirHeight     [dbGet [dbGetInstByName [lindex $L2Dir 0]  ].box_ury]

set L15DataWidth    [dbGet [dbGetInstByName [lindex $L15Data 0]].box_urx]
set L15DataHeight   [dbGet [dbGetInstByName [lindex $L15Data 0]].box_ury]
set L15TagWidth     [dbGet [dbGetInstByName [lindex $L15Tag 0] ].box_urx]
set L15TagHeight    [dbGet [dbGetInstByName [lindex $L15Tag 0] ].box_ury]
set L15HMTWidth     [dbGet [dbGetInstByName [lindex $L15HMT 0] ].box_urx]
set L15HMTHeight    [dbGet [dbGetInstByName [lindex $L15HMT 0] ].box_ury]

set tileMargin 5.76
set tileWidth  [expr 1350]
set tileHeight [expr 1250]

floorPlan -coreMarginsBy io -d $tileWidth $tileHeight $tileMargin $tileMargin $tileMargin $tileMargin -noSnapToGrid

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
#  CVVEC  #
###########
placeInstance -fixed $cvvec [list [expr $fp_x0] [expr $fp_y0]] MY

addHaloToBlock 0 0 $HALO_LANE $HALO_LANE $cvvec

########
#  L2  #
########

# Place L2 data
set i 0
set L2DataXOff [expr $tileMargin]
set L2DataYOff [expr $tileMargin]
foreach macro $L2Data {
    set x [expr $i % 2]
    set y [expr $i / 2]
    placeInstance -fixed $macro [list [expr $tileWidth - ($x + 1)*$L2DataWidth - $x*$HALO_SRAM - $L2DataXOff] [expr $y*($L2DataHeight) + $L2DataYOff]] MY
    addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $macro
    incr i
}

# Place L2 state
set i 0
set L2StateXOff [expr $cvvecWidth + $HALO_LANE + $tileMargin]
set L2StateYOff [expr $L2DataHeight*3 + $tileMargin]
foreach macro $L2State {
    set x [expr $i % 2]
    set y [expr $i / 2]
    placeInstance -fixed $macro [list [expr $L2StateXOff] [expr $y*($L2StateHeight) + $L2StateYOff]]
    addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $macro
    incr i
}

# Place L2 dir
set i 0
set L2DirXOff [expr $tileMargin]
set L2DirYOff [expr $L2DataHeight*4 + $tileMargin + $HALO_SRAM]
foreach macro $L2Dir {
    set x [expr $i % 2]
    set y [expr $i / 2]
    placeInstance -fixed $macro [list [expr $tileWidth - ($x + 1)*$L2DirWidth - $L2DirXOff] [expr $y*($L2DirHeight) + $L2DirYOff]] MY
    addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $macro
    incr i
}

# Place L2 tag
set i 0
set L2TagXOff [expr $cvvecWidth + $HALO_LANE + $tileMargin]
set L2TagYOff [expr $L2DataHeight*2 + $tileMargin]
foreach macro $L2Tag {
    set x [expr $i % 2]
    set y [expr $i / 2]
    placeInstance -fixed $macro [list [expr $L2TagXOff] [expr $y*($L2TagHeight) + $L2TagYOff]]
    addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $macro
    incr i
}

########
# L1.5 #
########

# Place L15 data
set L15DataXOff  [expr $tileMargin]
set L15DataYOff  [expr $L2DataHeight*4 + $L2DirHeight + $tileMargin + 2*$HALO_SRAM]
placeInstance -fixed $L15Data [list [expr $tileWidth - $L15DataWidth - $L15DataXOff] [expr $L15DataYOff]] MY
addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $L15Data

# Place L15 tag
set L15TagXOff  [expr $cvvecWidth + $HALO_LANE + $tileMargin]
set L15TagYOff  [expr 5*$L2DataHeight]
placeInstance -fixed $L15Tag [list [expr $L15TagXOff] [expr $L15TagYOff]]
addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $L15Tag

# Place L15 hmt
set L15HMTXOff  [expr $tileMargin]
set L15HMTYOff  [expr $L2DataHeight*4  + $L2DirHeight + $L15DataHeight + $tileMargin + 3*$HALO_SRAM]
placeInstance -fixed $L15HMT [list [expr $tileWidth - $L15HMTWidth - $L15HMTXOff] [expr $L15HMTYOff]] MY
addHaloToBlock $HALO_SRAM $HALO_SRAM $HALO_SRAM $HALO_SRAM $L15HMT

##########
#  PINS  #
##########
setPinAssignMode -restrict_boundary_macro_distance 0
setPinAssignMode -block_boundary_macro_distance 0
deletePinGroup -pinGroup *
deletePinGuide -all

set north_port_pins [get_object_name [get_ports *N*]]
set south_port_pins [lreverse [get_object_name [get_ports *S*]]]
set west_port_pins  [get_object_name [get_ports *W*]]
set east_port_pins  [lreverse [get_object_name [get_ports *E*]]]
set other_pins      [get_object_name [get_ports -regexp {^[^SNEW]*$}]]

# North ports
set dyn0_dataIn_N_pins   [lsearch -all -inline $north_port_pins dyn0_dataIn_N*]
set dyn0_validIn_N_pins  [lsearch -all -inline $north_port_pins dyn0_validIn_N]
set dyn0_dNo_yummy_pins  [lsearch -all -inline $north_port_pins dyn0_dNo_yummy]
set dyn0_dNo_pins        [lsearch -all -inline -regexp $north_port_pins {dyn0_dNo\[\d+}]
set dyn0_dNo_valid_pins  [lsearch -all -inline $north_port_pins dyn0_dNo_valid]
set dyn0_yummyOut_N_pins [lsearch -all -inline $north_port_pins dyn0_yummyOut_N]
set dyn0_N               [concat {*}[list $dyn0_dataIn_N_pins $dyn0_validIn_N_pins $dyn0_dNo_yummy_pins $dyn0_dNo_pins $dyn0_dNo_valid_pins $dyn0_yummyOut_N_pins]]

set dyn1_dataIn_N_pins   [lsearch -all -inline $north_port_pins dyn1_dataIn_N*]
set dyn1_validIn_N_pins  [lsearch -all -inline $north_port_pins dyn1_validIn_N]
set dyn1_dNo_yummy_pins  [lsearch -all -inline $north_port_pins dyn1_dNo_yummy]
set dyn1_dNo_pins        [lsearch -all -inline -regexp $north_port_pins {dyn1_dNo\[\d+}]
set dyn1_dNo_valid_pins  [lsearch -all -inline $north_port_pins dyn1_dNo_valid]
set dyn1_yummyOut_N_pins [lsearch -all -inline $north_port_pins dyn1_yummyOut_N]
set dyn1_N               [concat {*}[list $dyn1_dataIn_N_pins $dyn1_validIn_N_pins $dyn1_dNo_yummy_pins $dyn1_dNo_pins $dyn1_dNo_valid_pins $dyn1_yummyOut_N_pins]]

set dyn2_dataIn_N_pins   [lsearch -all -inline $north_port_pins dyn2_dataIn_N*]
set dyn2_validIn_N_pins  [lsearch -all -inline $north_port_pins dyn2_validIn_N]
set dyn2_dNo_yummy_pins  [lsearch -all -inline $north_port_pins dyn2_dNo_yummy]
set dyn2_dNo_pins        [lsearch -all -inline -regexp $north_port_pins {dyn2_dNo\[\d+}]
set dyn2_dNo_valid_pins  [lsearch -all -inline $north_port_pins dyn2_dNo_valid]
set dyn2_yummyOut_N_pins [lsearch -all -inline $north_port_pins dyn2_yummyOut_N]
set dyn2_N               [concat {*}[list $dyn2_dataIn_N_pins $dyn2_validIn_N_pins $dyn2_dNo_yummy_pins $dyn2_dNo_pins $dyn2_dNo_valid_pins $dyn2_yummyOut_N_pins]]

set ordered_north_port_pins [concat {*}[list $dyn0_N $dyn1_N $dyn2_N]]

# South ports 
set dyn0_dataIn_S_pins   [lreverse [lsearch -all -inline $south_port_pins dyn0_dataIn_S*]]
set dyn0_validIn_S_pins  [lsearch -all -inline $south_port_pins dyn0_validIn_S]
set dyn0_dSo_yummy_pins  [lsearch -all -inline $south_port_pins dyn0_dSo_yummy]
set dyn0_dSo_pins        [lreverse [lsearch -all -inline -regexp $south_port_pins {dyn0_dSo\[\d+}]]
set dyn0_dSo_valid_pins  [lsearch -all -inline $south_port_pins dyn0_dSo_valid]
set dyn0_yummyOut_S_pins [lsearch -all -inline $south_port_pins dyn0_yummyOut_S]
set dyn0_S               [concat {*}[list $dyn0_dSo_pins $dyn0_dSo_valid_pins $dyn0_yummyOut_S_pins $dyn0_dataIn_S_pins $dyn0_validIn_S_pins $dyn0_dSo_yummy_pins]]

set dyn1_dataIn_S_pins   [lreverse [lsearch -all -inline $south_port_pins dyn1_dataIn_S*]]
set dyn1_validIn_S_pins  [lsearch -all -inline $south_port_pins dyn1_validIn_S]
set dyn1_dSo_yummy_pins  [lsearch -all -inline $south_port_pins dyn1_dSo_yummy]
set dyn1_dSo_pins        [lreverse [lsearch -all -inline -regexp $south_port_pins {dyn1_dSo\[\d+}]]
set dyn1_dSo_valid_pins  [lsearch -all -inline $south_port_pins dyn1_dSo_valid]
set dyn1_yummyOut_S_pins [lsearch -all -inline $south_port_pins dyn1_yummyOut_S]
set dyn1_S               [concat {*}[list $dyn1_dSo_pins $dyn1_dSo_valid_pins $dyn1_yummyOut_S_pins $dyn1_dataIn_S_pins $dyn1_validIn_S_pins $dyn1_dSo_yummy_pins]]

set dyn2_dataIn_S_pins   [lreverse [lsearch -all -inline $south_port_pins dyn2_dataIn_S*]]
set dyn2_validIn_S_pins  [lsearch -all -inline $south_port_pins dyn2_validIn_S]
set dyn2_dSo_yummy_pins  [lsearch -all -inline $south_port_pins dyn2_dSo_yummy]
set dyn2_dSo_pins        [lreverse [lsearch -all -inline -regexp $south_port_pins {dyn2_dSo\[\d+}]]
set dyn2_dSo_valid_pins  [lsearch -all -inline $south_port_pins dyn2_dSo_valid]
set dyn2_yummyOut_S_pins [lsearch -all -inline $south_port_pins dyn2_yummyOut_S]
set dyn2_S               [concat {*}[list $dyn2_dSo_pins $dyn2_dSo_valid_pins $dyn2_yummyOut_S_pins $dyn2_dataIn_S_pins $dyn2_validIn_S_pins $dyn2_dSo_yummy_pins]]

set ordered_south_port_pins [concat {*}[list $dyn0_S $dyn1_S $dyn2_S]]

# West ports
set dyn0_dataIn_W_pins   [lsearch -all -inline $west_port_pins dyn0_dataIn_W*]
set dyn0_validIn_W_pins  [lsearch -all -inline $west_port_pins dyn0_validIn_W]
set dyn0_dWo_yummy_pins  [lsearch -all -inline $west_port_pins dyn0_dWo_yummy]
set dyn0_dWo_pins        [lsearch -all -inline -regexp $west_port_pins {dyn0_dWo\[\d+}]
set dyn0_dWo_valid_pins  [lsearch -all -inline $west_port_pins dyn0_dWo_valid]
set dyn0_yummyOut_W_pins [lsearch -all -inline $west_port_pins dyn0_yummyOut_W]
set dyn0_W               [concat {*}[list $dyn0_dataIn_W_pins $dyn0_validIn_W_pins $dyn0_dWo_yummy_pins $dyn0_dWo_pins $dyn0_dWo_valid_pins $dyn0_yummyOut_W_pins]]

set dyn1_dataIn_W_pins   [lsearch -all -inline $west_port_pins dyn1_dataIn_W*]
set dyn1_validIn_W_pins  [lsearch -all -inline $west_port_pins dyn1_validIn_W]
set dyn1_dWo_yummy_pins  [lsearch -all -inline $west_port_pins dyn1_dWo_yummy]
set dyn1_dWo_pins        [lsearch -all -inline -regexp $west_port_pins {dyn1_dWo\[\d+}]
set dyn1_dWo_valid_pins  [lsearch -all -inline $west_port_pins dyn1_dWo_valid]
set dyn1_yummyOut_W_pins [lsearch -all -inline $west_port_pins dyn1_yummyOut_W]
set dyn1_W               [concat {*}[list $dyn1_dataIn_W_pins $dyn1_validIn_W_pins $dyn1_dWo_yummy_pins $dyn1_dWo_pins $dyn1_dWo_valid_pins $dyn1_yummyOut_W_pins]]

set dyn2_dataIn_W_pins   [lsearch -all -inline $west_port_pins dyn2_dataIn_W*]
set dyn2_validIn_W_pins  [lsearch -all -inline $west_port_pins dyn2_validIn_W]
set dyn2_dWo_yummy_pins  [lsearch -all -inline $west_port_pins dyn2_dWo_yummy]
set dyn2_dWo_pins        [lsearch -all -inline -regexp $west_port_pins {dyn2_dWo\[\d+}]
set dyn2_dWo_valid_pins  [lsearch -all -inline $west_port_pins dyn2_dWo_valid]
set dyn2_yummyOut_W_pins [lsearch -all -inline $west_port_pins dyn2_yummyOut_W]
set dyn2_W               [concat {*}[list $dyn2_dataIn_W_pins $dyn2_validIn_W_pins $dyn2_dWo_yummy_pins $dyn2_dWo_pins $dyn2_dWo_valid_pins $dyn2_yummyOut_W_pins]]

set ordered_west_port_pins [concat {*}[list $dyn0_W $dyn1_W $dyn2_W]]

# East ports
set dyn0_dataIn_E_pins   [lreverse [lsearch -all -inline $east_port_pins dyn0_dataIn_E*]]
set dyn0_validIn_E_pins  [lsearch -all -inline $east_port_pins dyn0_validIn_E]
set dyn0_dEo_yummy_pins  [lsearch -all -inline $east_port_pins dyn0_dEo_yummy]
set dyn0_dEo_pins        [lreverse [lsearch -all -inline -regexp $east_port_pins {dyn0_dEo\[\d+}]]
set dyn0_dEo_valid_pins  [lsearch -all -inline $east_port_pins dyn0_dEo_valid]
set dyn0_yummyOut_E_pins [lsearch -all -inline $east_port_pins dyn0_yummyOut_E]
set dyn0_E               [concat {*}[list $dyn0_dEo_pins $dyn0_dEo_valid_pins $dyn0_yummyOut_E_pins $dyn0_dataIn_E_pins $dyn0_validIn_E_pins $dyn0_dEo_yummy_pins]]

set dyn1_dataIn_E_pins   [lreverse [lsearch -all -inline $east_port_pins dyn1_dataIn_E*]]
set dyn1_validIn_E_pins  [lsearch -all -inline $east_port_pins dyn1_validIn_E]
set dyn1_dEo_yummy_pins  [lsearch -all -inline $east_port_pins dyn1_dEo_yummy]
set dyn1_dEo_pins        [lreverse [lsearch -all -inline -regexp $east_port_pins {dyn1_dEo\[\d+}]]
set dyn1_dEo_valid_pins  [lsearch -all -inline $east_port_pins dyn1_dEo_valid]
set dyn1_yummyOut_E_pins [lsearch -all -inline $east_port_pins dyn1_yummyOut_E]
set dyn1_E               [concat {*}[list $dyn1_dEo_pins $dyn1_dEo_valid_pins $dyn1_yummyOut_E_pins $dyn1_dataIn_E_pins $dyn1_validIn_E_pins $dyn1_dEo_yummy_pins]]

set dyn2_dataIn_E_pins   [lreverse [lsearch -all -inline $east_port_pins dyn2_dataIn_E*]]
set dyn2_validIn_E_pins  [lsearch -all -inline $east_port_pins dyn2_validIn_E]
set dyn2_dEo_yummy_pins  [lsearch -all -inline $east_port_pins dyn2_dEo_yummy]
set dyn2_dEo_pins        [lreverse [lsearch -all -inline -regexp $east_port_pins {dyn2_dEo\[\d+}]]
set dyn2_dEo_valid_pins  [lsearch -all -inline $east_port_pins dyn2_dEo_valid]
set dyn2_yummyOut_E_pins [lsearch -all -inline $east_port_pins dyn2_yummyOut_E]
set dyn2_E               [concat {*}[list $dyn2_dEo_pins $dyn2_dEo_valid_pins $dyn2_yummyOut_E_pins $dyn2_dataIn_E_pins $dyn2_validIn_E_pins $dyn2_dEo_yummy_pins]]

set ordered_east_port_pins [concat {*}[list $dyn0_E $dyn1_E $dyn2_E]]

createPinGroup northPins -pin $ordered_north_port_pins
createPinGroup southPins -pin $ordered_south_port_pins
createPinGroup westPins  -pin $ordered_west_port_pins
createPinGroup eastPins  -pin $ordered_east_port_pins

addPinToPinGroup -pinGroup northPins -pin $other_pins

createPinGuide -edge 0 -pinGroup westPins  -layer C4 -offset_start [expr $cvvecHeight + 8*$tileMargin]
createPinGuide -edge 1 -pinGroup northPins -layer C3 -offset_start [expr $cvvecWidth  + 8*$tileMargin]
createPinGuide -edge 2 -pinGroup eastPins  -layer C4 -offset_start [expr $cvvecHeight + 8*$tileMargin]
createPinGuide -edge 3 -pinGroup southPins -layer C3 -offset_start [expr $cvvecWidth  + 8*$tileMargin]

assignIoPins