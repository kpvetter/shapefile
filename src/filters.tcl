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
    set FILTERS(need) [list]
}
proc ::Filters::SetFilters {avoids needs} {
    variable FILTERS
    set FILTERS(avoid) $avoids
    set FILTERS(need) $needs
}
proc ::Filters::FilterDBaseInfo {dbData} {
    # Checks the first name in each nameDatum to see if it
    # should be avoided or required.
    # dbData is [list {idx1 name} {idx2 name} ...]

    variable FILTERS

    set FILTERS(dropped) {}
    set FILTERS(keptout) {}
    if {$FILTERS(need) eq "" && $FILTERS(avoid) eq ""} { return $dbData }

    set reAvoid [join [lmap x $FILTERS(avoid) { expr {$x eq "" ? "^$" : $x }}] "|"]
    set reNeed [join [lmap x $FILTERS(need) { expr {$x eq "" ? "^$" : $x }}] "|"]

    set result {}
    foreach v $dbData {
        set name [lindex $v 1]
        if {[regexp -nocase $reAvoid $name]} {
            lappend FILTERS(dropped) $name
            continue
        }
        if {$FILTERS(need) ne ""} {
            if {! [regexp -nocase $reNeed $name]} {
                lappend FILTERS(keptout) $name
                continue
            }
        }
        lappend result $v
    }
    return $result
}
