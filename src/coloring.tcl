#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# coloring.tcl -- Creates a coloring scheme where no adjacent shapes have the same color
# by Keith Vetter 2025-04-20
#
# First we determine adjacent shapes by seeing if their bounding boxes overlap. This
# can lead to false positives, especially for Russia whose bounding boxes overlaps
# with many countries it doesn't touch.
#
# Next we go through each shape and pick a color that none of the neighbors have.
# This is guaranteed to work, but if we order the shape list by most numbers of
# neighbors first, it works pretty well.
#
# The result is a simple list which each shape's base color index at its spot in the list.
# The actual color is that base color index plus a nonce to pick a color from $COLORS.

namespace eval ::Coloring {
    variable COLORS [list lightyellow cyan orange green pink sienna1 yellow red blue springgreen]
    variable BASE_SCHEME ;# An array holding our coloring scheme
}
proc ::Coloring::NewBaseColorScheme {shape indexList} {
    # Using computed adjacency data, get a proper map coloring
    variable BASE_SCHEME
    variable COLORS

    unset -nocomplain BASE_SCHEME
    unset -nocomplain borders
    set all_colors [range [llength $COLORS]]
    set colorCount [dict create]
    foreach colorIdx $all_colors { dict set colorCount $colorIdx 0 }

    ::Coloring::_ComputeOverlaps $shape $indexList borders
    foreach idx $indexList { set BASE_SCHEME($idx) "X" }

    ;# Reorder index list to have shapes with the most neighbors come first
    set keyedIndexList [lmap x $indexList { list $x [llength $borders($x)]}]
    set keyedIndexList [lsort -integer -index 1 -decreasing $keyedIndexList]

    foreach item $keyedIndexList {
        lassign $item idx _

        set exclude [lmap x $borders($idx) { set BASE_SCHEME($x) }]
        set available [lmap x $all_colors { if {$x in $exclude} continue ; set x }]

        if {$available eq ""} {
            set available $all_colors

            set who [lindex [IndexListToNameList [list $idx]] 0]
            puts stderr "$idx '$who' has too many neighbors"
        }
        set colorIdx [lpick $available]
        set colorIdx [::Coloring::_LeastUsedColor $colorCount $available]

        dict incr colorCount $colorIdx
        set BASE_SCHEME($idx) $colorIdx
    }
}
proc ::Coloring::GetColor {idx nonce} {
    variable COLORS
    variable BASE_SCHEME

    set colorIdx [expr {($nonce + $BASE_SCHEME($idx)) % [llength $COLORS]}]
    set color [lindex $COLORS $colorIdx]
    return $color
}

proc ::Coloring::_ComputeOverlaps {shape indexList &result} {
    # Determine which shapes are possibly adjacent by if their bounding boxes overlap
    upvar 1 ${&result} result

    array unset result
    unset -nocomplain MEM

    foreach idx1 $indexList {
        ::Throbber::Step

        set bbox1 [$shape BoundingBox $idx1]
        set result($idx1) {}

        foreach idx2 $indexList {
            if {$idx1 == $idx2} continue
            set bbox2 [$shape BoundingBox $idx2]
            if {[info exists MEM($bbox1,$bbox2)]} {
                set overlap $MEM($bbox1,$bbox2)
            } else {
                set overlap [::Coloring::_OverlapBBox $bbox1 $bbox2]
                set MEM($bbox2,$bbox1) $overlap
            }
            if {$overlap} {
                lappend result($idx1) $idx2
            }
        }
    }
    return
}
proc ::Coloring::_OverlapBBox {bbox1 bbox2} {
    # Returns True if two bounding boxes overlap
    lassign $bbox1 left1 bottom1 right1 top1
    lassign $bbox2 left2 bottom2 right2 top2

    if {$right2 < $left1} { return False }
    if {$left2 > $right1} { return False }
    if {$top2 < $bottom1} { return False }
    if {$bottom2 > $top1} { return False }
    return True
}
proc ::Coloring::_LeastUsedColor {colorCount available} {
    # Given dictionary of color usage, pick the least used one

    set rest [lassign $available first]
    set minValue [dict get $colorCount $first]
    set minWho [list $first]

    foreach colorIdx $rest {
        set value [dict get $colorCount $colorIdx]
        if {$value < $minValue} {
            set minValue $value
            set minWho [list $colorIdx]
        } elseif {$value == $minValue} {
            lappend minWho $colorIdx
        }
    }
    set who [lpick $minWho]
    return $who
}
