#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# filters.tcl -- Filter shape names avoiding some and requiring others
# by Keith Vetter 2025-04-24
#
namespace eval ::Filters {
    variable FILTERS

    unset -nocomplain FILTERS
    set FILTERS(avoid) [list "UNK" ""]
    set FILTERS(need) [list "MISSISSIPPI RIVER" "MISSOURI RIVER"]
}
proc ::Filters::SetFilters {avoids needs} {
    variable FILTERS
    set FILTERS(avoid) $avoids
    set FILTERS(needs) $needs
}
proc ::Filters::FilterDBaseInfo {nameData} {
    # Checks the first name in each nameDatum to see if it
    # should be avoided or required.
    # nameData is [list {idx1 name} {idx2 name} ...]

    variable FILTERS

    set FILTERS(dropped) {}
    set FILTERS(keptout) {}
    if {$FILTERS(need) eq "" && $FILTERS(avoid) eq ""} { return $nameData }

    set result {}
    foreach v $nameData {
        # set idx [lindex $v 0]
        # if {$idx == 11700} { puts hi ; break}
        set name [lindex $v 1]
        if {$name in $FILTERS(avoid)} {
            lappend FILTERS(dropped) $name
            continue
        }
        if {$FILTERS(need) ne ""} {
            if {$name ni $FILTERS(need)} {
                lappend FILTERS(keptout) $name
                continue
            }
        }
        lappend result $v
    }
    return $result
}
