#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

package require Tk

namespace eval ::Throbber {
    variable T
    set T(dots) { ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ }
    set T(delay) 80
    set T(varName) ""
    set T(index) 0
    set T(aid) ""
}

proc ::Throbber::Start {varName} {
    variable T
    set T(varName) $varName
    set T(index) -1

    ::Throbber::Step
}
proc ::Throbber::Step {} {
    variable T

    set T(index) [expr {($T(index) + 1) % [llength $T(dots)]}]
    upvar 1 $T(varName) var
    set var [lindex $T(dots) $T(index)]
    update

    set T(aid) [after $T(delay) ::Throbber::Step]
}
proc ::Throbber::Stop {} {
    variable T
    after cancel $T(aid)
}
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    set S(title_font) [concat [font actual TkDefaultFont] -size 48 -weight bold]
    set S(text) ""

    "proc" Go {} {
        global S
        toplevel .top
        wm geom .top +100+100
        ::ttk::label .top.l1 -text "Testing throbber" -font $S(title_font)
        ::ttk::label .top.l2 -textvar S(text) -font $S(title_font)

        ::ttk::button .top.b1 -text "Start" -command [list ::Throbber::Start S(text)]
        ::ttk::button .top.b2 -text "Stop" -command [list ::Throbber::Stop]

        grid .top.l1 -
        grid .top.l2 -
        grid .top.b1 .top.b2
        tkwait window .top
    }
    Go
}
