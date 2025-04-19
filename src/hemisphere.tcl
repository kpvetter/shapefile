#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# hemisphere.tcl -- <description>
# by Keith Vetter 2025-04-18
#

catch {wm withdraw .}

set shapefile [file join [file dirname $argv0] shapefile.tcl]
source $shapefile

set HEMISPHERES(west) {}
set HEMISPHERES(east) {}
set HEMISPHERES(north) {}
set HEMISPHERES(south) {}

set fname ../world_boundaries/World_Countries_shp.shp

proc FixSize {text value} {
    set result [format " %s %7.2f" $text $value]
    return $result
}


set shape [::Shapefile::Go $fname]
set recordCount [$shape RecordCount]
for {set idx 1} {$idx <= $recordCount} {incr idx} {
    lassign [$shape ReadOneRecord $idx] recordNumber type record
    set bbox [dict get $record box]
    lassign $bbox X(left) X(bottom) X(right) X(top)
    set msg [format "%3d :" $idx]
    foreach side {left bottom right top} {
        set result [FixSize $side $X($side)]
        append msg $result
    }
    puts $msg

}
$shape Done
