#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# zipopen.tcl -- Handles opening a zip file and extracting files to a temp directory
# by Keith Vetter 2025-04-21
#

package require fileutil
package require vfs::zip

namespace eval ::Zip {
    variable Z
    set Z(tempdir) ""
    # Code to open a zip file using Tcl's VSF file system and extracting the
    # the shape and dbaseIII files into a temporary directory

}
proc ::Zip::Open {zipName extension {otherExtensions {}}} {
    # Opens up the zipName and extracts the first $EXTENSION file
    # into a temp directory.
    variable Z

    ::Zip::Cleanup $zipName
    if {$Z(tempdir) eq ""} {
        set Z(tempdir) [::fileutil::maketempdir -prefix zip_kpv_]
    }

    try {
        set mountPoint /__zip
        set zipVFS [::vfs::zip::Mount [file normalize $zipName] $mountPoint]
        set foundFiles [::Zip::FindAll $mountPoint $extension]
        if {[llength $foundFiles] == 0} { return "" }

        set first [lindex $foundFiles 0]
        foreach ext [concat [list $extension] $otherExtensions] {
            set fname [file rootname $first].[string trimleft $ext "."]
            if {[file exists $fname]} {
                catch {file copy -force -- $fname $Z(tempdir)}
            }
        }

        set n [catch {
            file copy -force -- $shpFile $Z(tempdir)
            file copy -force -- $dbfFile $Z(tempdir)
            file copy -force -- $shxFile $Z(tempdir)
        } emsg]

    } finally {
        ::vfs::zip::Unmount $zipVFS $mountPoint
    }
    set result [file join $Z(tempdir) [file tail $first]]
    if {[file exist $result]} { return $result }
    return ""
}

proc ::Zip::FindAll {cwd extension} {
    # Recursively search a directory (in this case inside a zip file) for all files with $extension

    set foundFiles {}
    set extension [string trimleft $extension "."]
    foreach zfile [lsort -dictionary [glob -nocomplain $cwd/*.$extension]] {
        lappend foundFiles $zfile
    }

    # Now recurse into subdirectories
    foreach zfile [lsort -dictionary [glob -nocomplain $cwd/*]] {
        if {[file isdirectory $zfile]} {
            set more [::Zip::FindAll $zfile $extension]
            lappend foundFiles {*}$more
        }
    }
    return $foundFiles
}
proc ::Zip::Cleanup {{except {}}} {
    variable Z
    if {$Z(tempdir) ne ""} {
        foreach fname [glob -nocomplain [file join $Z(tempdir) "*"]] {
            if {$fname ne $except} {
                catch {file delete -force -- $fname}
            }
        }
    }
}
proc ::Zip::Done {args} {
    variable Z
    if {$Z(tempdir) ne ""} {
        catch {file delete -force -- $Z(tempdir)}
    }
}

if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    set zipName ~/misc/tcl/shapefile/UK_Counties.zip
    set extension .dbf
    if {$tcl_interactive} return
    set dbfFile [::Zip::Open $zipName $extension]
}
