#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# throbber.tcl -- Animates a text spinner
# by Keith Vetter 2025-04-26
#
namespace eval ::Throbber {
    variable T
    set T(dots) { ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ }
    set T(delay,ms) 80
    set T(varName) ""
    set T(index) -1
    set T(last) 0
}

proc ::Throbber::Start {varName} {
    variable T
    set T(varName) $varName
    set T(index) -1
    set T(last) 0
    ::Throbber::Step
}
proc ::Throbber::Step {} {
    # Gets called repeatedly but only update throbber after
    # $T(delay,ms) have elapsed since the last update
    variable T

    set now [clock milliseconds]
    if {$now - $T(last) < $T(delay,ms)} return
    set T(last) $now

    set T(index) [expr {($T(index) + 1) % [llength $T(dots)]}]
    upvar \#0 $T(varName) var
    set var [lindex $T(dots) $T(index)]
    update
}
