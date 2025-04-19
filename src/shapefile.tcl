#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# shapefile.tsh -- Parses an ESRI Shapefile
# by Keith Vetter 2025-02-07
#
# Usage:
#   set shape [::Shapefile::Go my_shapefile.shp]
#   $shape SetLogger BASIC | NONE | func
#   puts [$shape Header]
#   puts "Record Count: [$shape RecordCount]"
#
#   for {set idx 1} {$idx <= [$shape RecordCount]} {incr idx} {
#      lassign [$shape ReadOneRecord $idx] recordNumber type record
#      puts "RecordNumber: $recordNumber Type: $type"
#   }
#   $shape Done
#
#
# File spec:
# https://www.esri.com/content/dam/esrisites/sitecore-archive/Files/Pdfs/library/whitepapers/pdfs/shapefile.pdf
#

package provide shapefile 0.1

catch {namespace delete ::Shapefile}

namespace eval ::Shapefile {
    variable THIS
    variable INDICES
    variable META
    variable PRETTY

    array unset THIS *
    array unset INDICES *
    array unset META *

    array set PRETTY {0 Null
        1 Point 3 PolyLine 5 Polygon 8 MultiPoint
        11 PointZ 13 PolyLineZ 15 PolygonZ 18 MultiPointZ
        21 PointM 23 PolyLineM 25 PolygonM 28 MultiPointM
        31 MultiPatch}

    set THIS(start) [clock seconds]
}

proc ::Shapefile::Go {fname} {
    variable THIS

    set shape [::Shapefile::_NewId]

    set THIS($shape,logger) NONE
    set THIS($shape,fname) $fname
    set THIS($shape,count) 0
    set THIS($shape,quickPass) False
    set shx "[file rootname $fname].shx"
    set THIS($shape,shx) [expr {[file exists $shx] ? $shx : ""}]

    set THIS($shape,fin) [open $fname rb]
    set THIS($shape,header) [::Shapefile::_ReadHeader $shape]

    if {[dict get $THIS($shape,header) status] ne "OK"} {
        set emsg "error reading shape file '$fname'"
        ::Shapefile::_Logger $shape $emsg
        ::Shapefile::Done $shape
        return -code 1 $emsg
    }

    # Add the bounding box to the header data
    # WARNING: shape files may have incorrect bounding box values in header
    dict set THIS($shape,header) box {}
    foreach vname {xmin ymin xmax ymax} {
        set value [dict get $::Shapefile::THIS($shape,header) $vname]
        dict lappend THIS($shape,header) box $value
    }
    set type [dict get $THIS($shape,header) shapeType]
    dict append THIS($shape,header) pretty $::Shapefile::PRETTY($type)

    ::Shapefile::_NewObject $shape
    return $shape
}
proc ::Shapefile::Done {shape} {
    variable THIS
    variable INDICES
    variable META

    if {! [info exists THIS($shape,fin)]} return

    ::Shapefile::_Logger $shape "closing $THIS($shape,fname)"

    if {$THIS($shape,fin) ne "CLOSED"} {
        close $THIS($shape,fin)
    }
    array unset THIS $shape,*
    array unset INDICES $shape,*
    array unset META $shape,*
    catch {rename $shape {}}
}
proc ::Shapefile::SetLogger {shape logger} {
    set ::Shapefile::THIS($shape,logger) $logger
}
proc ::Shapefile::Header {shape} {
    # Returns shapefile's header with a few added values
    return $::Shapefile::THIS($shape,header)
}
proc ::Shapefile::RecordCount {shape} {
    variable THIS

    if {$THIS($shape,quickPass)} {
        return $THIS($shape,count)
    }
    if {$THIS($shape,shx) ne ""} {
        set shxSize [file size $THIS($shape,shx)]
        set THIS($shape,count) [expr {($shxSize - 100) / 8}]
        return $THIS($shape,count)
    }
    ::Shapefile::_QuickPass $shape
    return $THIS($shape,count)
}
proc ::Shapefile::ReadOneMeta {shape requestedRecord} {
    # Returns type, bounding box, numPoints, etc for each record
    variable META
    ::Shapefile::_QuickPass $shape
    return $META($shape,$requestedRecord)
}

proc ::Shapefile::ReadOneRecord {shape requestedRecord} {
    variable THIS
    variable INDICES

    ::Shapefile::_Logger $shape "ReadOneRecord $requestedRecord"
    ::Shapefile::_QuickPass $shape
    if {! [info exists INDICES($shape,start,$requestedRecord)]} {
        error "cannot locate record $requestedRecord"
    }

    set fin $THIS($shape,fin)
    seek $fin $INDICES($shape,start,$requestedRecord) start
    lassign [::Shapefile::_ReadRecordHeader $shape] EOF recordNumber contentLength type
    if {$EOF eq "EOF"} break

    set THIS($shape,nextRecordStart) [expr {[tell $fin] + 2 * $contentLength}]

    set shapeHandler ::Shapefile::_ShapeType${type}
    lassign [$shapeHandler $shape False] type record

    return [list $recordNumber $type $record]
}
proc ::Shapefile::ReadOneRecordRaw {shape requestedRecord} {
    variable THIS
    variable INDICES

    ::Shapefile::_QuickPass $shape
    if {$requestedRecord eq "header"} {
        set low 0
        set high 100
    } else {
        set low $INDICES($shape,start,$requestedRecord)
        set high $INDICES($shape,end,$requestedRecord)
    }

    set fin $THIS($shape,fin)
    seek $fin $low start
    set bytes [read $fin [expr {$high - $low}]] ; list
    return $bytes
}

proc ::Shapefile::BoundingBox {shape idList} {
    # Given a list of record numbers, computes the bounding box of the union
    # NB. ::Shapefile::_QuickPass caches each record metadata
    variable META

    ::Shapefile::_QuickPass $shape

    # if {$idList eq "all"} {
    #     set idList {}
    #     for {set idx 1} {$idx <= [$shape RecordCount]} {incr idx} {
    #         lappend idList $idx
    #     }
    # }

    ::Shapefile::_Logger $shape "BoundingBox for $idList"
    set idList2 [lassign $idList firstId]

    if {! [info exists META($shape,$firstId)]} {
        error "cannot locate bounding box for $firstId"
    }

    lassign [dict get $META($shape,$firstId) box] left bottom right top
    foreach idx $idList2 {
        lassign [dict get $META($shape,$idx) box] left1 bottom1 right1 top1
        set left [expr {min($left, $left1)}]
        set bottom [expr {min($bottom, $bottom1)}]
        set right [expr {max($right, $right1)}]
        set top [expr {max($top, $top1)}]
    }

    return [list $left $bottom $right $top]
}
################################################################
#
# Private methods
#
proc ::Shapefile::_Logger {shape msg} {
    variable THIS
    if {$THIS($shape,logger) eq "NONE"} return
    if {$THIS($shape,logger) eq "BASIC"} {
        set when [clock format [clock seconds] -format "%H:%M:%S"]
        puts stderr "LOG: $when $msg"
        return
    }
    $THIS($shape,logger) $msg
}
proc ::Shapefile::_NewId {} {
    # Get a unique new id for our object

    set existing [info commands [namespace current]::_obj*]
    for {set cnt [llength $existing]} {1} {incr cnt} {
        set shape "[namespace current]::_obj$cnt"
        if {$shape ni $existing} break
    }
    return $shape
}

proc ::Shapefile::_NewObject {shape} {
    # Return a namespace ensemble object with the appropriate command map
    set commandMap {}
    foreach fullCmd [info commands ::Shapefile::*] {
        # Copy all exported commands into our object but with a THIS first parameter
        set cmd [namespace tail $fullCmd]
        if {[string index $cmd 0] eq "_"} continue
        if {$cmd eq "Go"} continue
        lappend commandMap $cmd [list $cmd $shape]
    }
    ::namespace ensemble create -command $shape -map $commandMap
    return $shape
}

proc ::Shapefile::_ReadHeader {shape} {
    # Reads Shapefile's header data into a dictionary
    variable THIS

    ::Shapefile::_Logger $shape "reading header"
    set fin $THIS($shape,fin)

    seek $fin 0 start
    set input [read $fin 100] ; list
    set n [binary scan $input IIIIIIIiiqqqqqqqq fileCode _ _ _ _ _  fileLength version \
               shapeType xmin ymin xmax ymax zmin zmax mmin mmax]
    if {$n != 17 || $fileCode != 9994} {
        ::Shapefile::_Logger $shape "ERROR: not a shapefile"
        set header [dict create status "ERROR: not a shapefile"]
    } else {
        set shapeHandler ::Shapefile::_ShapeType${shapeType}
        if {[info commands $shapeHandler] eq {}} {
            ::Shapefile::_Logger $shape "ERROR: cannot handle shape type $shapeType"
            set header [dict create status "ERROR: cannot handle shape type $shapeType"]
        } else {
            set header [dict create status OK fileCode $fileCode fileLength $fileLength \
                            version $version shapeType $shapeType xmin $xmin ymin $ymin \
                            xmax $xmax ymax $ymax zmin $zmin zmax $zmax mmin $mmin mmax $mmax]
        }
    }
    return $header
}
proc ::Shapefile::_QuickPass {shape} {
    # Extract indices and possibly the bounding box of each node
    variable THIS
    variable INDICES
    variable META

    if {$THIS($shape,quickPass)} return

    set start [clock seconds]
    set THIS($shape,count) 0

    ::Shapefile::_Logger $shape "doing _QuickPass"
    set fin $THIS($shape,fin)
    if {$fin eq "CLOSED"} return

    set nextRecordStart 100
    while {1} {
        set thisRecordStart $nextRecordStart
        seek $fin $thisRecordStart start

        lassign [::Shapefile::_ReadRecordHeader $shape] EOF recordNumber contentLength type
        if {$EOF eq "EOF"} break
        set nextRecordStart [expr {[tell $fin] + 2 * $contentLength}]

        set THIS($shape,count) $recordNumber
        set THIS($shape,nextRecordStart) $nextRecordStart
        set INDICES($shape,start,$recordNumber) $thisRecordStart
        set INDICES($shape,end,$recordNumber) $THIS($shape,nextRecordStart)

        set shapeHandler ::Shapefile::_ShapeType${type}
        lassign [$shapeHandler $shape True] type record
        set META($shape,$recordNumber) $record
    }
    ::Shapefile::_Logger $shape "done with _QuickPass [expr {[clock seconds] - $start}] seconds"
    set THIS($shape,quickPass) True

}
proc ::Shapefile::_ReadRecordHeader {shape} {
    # Reads next record header plus the next integer which is the record type
    # Also checks for EOF
    variable THIS

    set fin $THIS($shape,fin)
    set format IIi
    binary scan [::Shapefile::_FormattedRead $shape $format] $format recordNumber contentLength type
    if {[eof $fin]} { return [list EOF _ _ _] }
    seek $fin -4 current
    return [list "" $recordNumber $contentLength $type]
}

proc ::Shapefile::_FormattedRead {shape format} {
    # Reads the correct amount of bytes for a given binary scan format string
    variable THIS

    set fin $THIS($shape,fin)

    set readLength [::Shapefile::_ScanFormatReadLength $format]
    set input [read $fin $readLength] ; list
    return $input
}

proc ::Shapefile::_ScanFormatReadLength {format} {
    # Determines how many bytes need to be read for a given binary scan format string

    array set SIZES {i 4 I 4 f 4 d 8 r 4 R 4 q 8 Q 8}
    set readLength 0
    foreach {_ item count} [regexp -all -inline {(.)(\d*)} $format] {
        if {$count eq {}} { set count 1 }
        incr readLength [expr {$SIZES($item) * $count}]
    }
    return $readLength
}

############
#
# Handlers for various shape types
#
#

interp alias {} ::Shapefile::_ShapeType3 {} ::Shapefile::_ShapeTypePoly
interp alias {} ::Shapefile::_ShapeType5 {} ::Shapefile::_ShapeTypePoly
interp alias {} ::Shapefile::_ShapeType13 {} ::Shapefile::_ShapeTypePoly
interp alias {} ::Shapefile::_ShapeType15 {} ::Shapefile::_ShapeTypePoly
interp alias {} ::Shapefile::_ShapeType23 {} ::Shapefile::_ShapeTypePoly
interp alias {} ::Shapefile::_ShapeType25 {} ::Shapefile::_ShapeTypePoly

interp alias {} ::Shapefile::_ShapeType1 {} ::Shapefile::_ShapeTypePoint
interp alias {} ::Shapefile::_ShapeType11 {} ::Shapefile::_ShapeTypePoint
interp alias {} ::Shapefile::_ShapeType21 {} ::Shapefile::_ShapeTypePoint

interp alias {} ::Shapefile::_ShapeType8 {} ::Shapefile::_ShapeTypeMultiPoint
interp alias {} ::Shapefile::_ShapeType18 {} ::Shapefile::_ShapeTypeMultiPoint
interp alias {} ::Shapefile::_ShapeType28 {} ::Shapefile::_ShapeTypeMultiPoint

proc ::Shapefile::_ShapeType0 {shape QUICK} {
    variable THIS

    set fin $THIS($shape,fin)

    set format i
    binary scan [::Shapefile::_FormattedRead $shape $format] $format type ; list
    set record [dict create status OK type $type pretty $::Shapefile::PRETTY($type)]
    return [list $type $record]
}
proc ::Shapefile::_ShapeTypePoint {shape QUICK} {
    # Extracts the data for Shape Type 1 : Point, 11 : PointZ, 21 : PointM
    variable THIS

    set fin $THIS($shape,fin)

    set format iqq
    binary scan [::Shapefile::_FormattedRead $shape $format] $format type pointX pointY
    set box [list $pointX $pointY $pointX $pointY] ;# Create a bounding box for consistency
    set record [dict create status OK type $type pretty $::Shapefile::PRETTY($type) \
                    pointX $pointX pointY $pointY box $box]

    if {$type == 11} {
        set format qq
        binary scan [::Shapefile::_FormattedRead $shape $format] $format pointZ measureM
        ::Shapefile::AppendDict record pointZ $pointZ measureM $measureM
    } elseif {$type == 21} {
        set format q
        binary scan [::Shapefile::_FormattedRead $shape $format] $format measureM
        ::Shapefile::AppendDict record measureM $measureM
    }
    return [list $type $record]
}
proc ::Shapefile::_ShapeTypePoly {shape QUICK} {
    # Extracts the data for Shape Type 3 : PolyLine, 5 : Polygon, 13 PolyLineZ, 23 PolyLineM
    variable THIS

    set fin $THIS($shape,fin)

    set format iq4ii
    binary scan [::Shapefile::_FormattedRead $shape $format] $format type box numParts numPoints
    set record [dict create status OK type $type pretty $::Shapefile::PRETTY($type) \
                    box $box numParts $numParts numPoints $numPoints]

    if {! $QUICK} {
        set format "i$numParts"
        binary scan [::Shapefile::_FormattedRead $shape $format] $format parts

        set format "q[expr {2 * $numPoints}]"
        binary scan [::Shapefile::_FormattedRead $shape $format] $format points
        ::Shapefile::AppendDict record parts $parts points $points

        if {$type in {13 15}} {
            set format "qqq${numPoints}"
            binary scan [::Shapefile::_FormattedRead $shape $format] $format minZ maxZ arrayZ
            ::Shapefile::AppendDict header minZ $minZ maxZ $maxZ arrayZ $arrayZ
        }

        if {$type in {13 15 23 25}} {
            lassign {0 0 {}} minM maxM arrayM
            if {[tell $fin] < $THIS($shape,nextRecordStart)} {
                set format "qqq${numPoints}"
                binary scan [::Shapefile::_FormattedRead $shape $format] $format minM maxM arrayM
            }
            ::Shapefile::AppendDict header minM $minM maxM $maxM arrayM $arrayM
        }
    }
    return [list $type $record]
}
proc ::Shapefile::_ShapeTypeMultiPoint {shape QUICK} {
    # Extracts the data for Shape Type 8 MultiPoint, 18 MultiPointZ, 28 MultiPointM
    variable THIS

    set fin $THIS($shape,fin)

    set format iq4i
    binary scan [::Shapefile::_FormattedRead $shape $format] $format type box numPoints
    set format "q[expr {2 * $numPoints}]"
    binary scan [::Shapefile::_FormattedRead $shape $format] $format points
    set record [dict create status OK type $type pretty $::Shapefile::PRETTY($type) \
                    box $box numPoints $numPoints points $points] ; list
    if {! $QUICK} {
        if {$type in {18}} {
            set format "qqq${numPoints}"
            binary scan [::Shapefile::_FormattedRead $shape $format] $format minZ maxZ arrayZ
            ::Shapefile::AppendDict header minZ $minZ maxZ $maxZ arrayZ $arrayZ
        }

        if {$type in {18 28}} {
            lassign {0 0 {}} minM maxM arrayM
            if {[tell $fin] < $THIS($shape,nextRecordStart)} {
                set format "qqq${numPoints}"
                binary scan [::Shapefile::_FormattedRead $shape $format] $format minM maxM arrayM
            }
            ::Shapefile::AppendDict header minM $minM maxM $maxM arrayM $arrayM
        }
    }
    return [list $type $record]
}

proc ::Shapefile::_ShapeType31 {shape QUICK} {
    # Extracts the data for Shape Type 31 : MultiPatch
    variable THIS

    set fin $THIS($shape,fin)

    set format iq4ii
    binary scan [::Shapefile::_FormattedRead $shape $format] $format type box numParts numPoints
    set record [dict create status OK type $type pretty $::Shapefile::PRETTY($type) \
                    box $box numParts $numParts numPoints $numPoints]

    if {! $QUICK} {
        set format "i${numParts}i${numParts}"
        binary scan [::Shapefile::_FormattedRead $shape $format] $format parts partTypes

        set format "q[expr {2 * $numPoints}]"
        binary scan [::Shapefile::_FormattedRead $shape $format] $format points

        set format "qqq${numPoints}"
        binary scan [::Shapefile::_FormattedRead $shape $format] $format minZ maxZ arrayZ

        lassign {0 0 {}} minM maxM arrayM
        if {[tell $fin] < $THIS($shape,nextRecordStart)} {
            set format "qqq${numPoints}"
            binary scan [::Shapefile::_FormattedRead $shape $format] $format minM maxM arrayM
        }
        ::Shapefile::AppendDict record parts $parts points $points minZ $minZ maxZ $maxZ arrayZ $arrayZ \
            minM $minM maxM $maxM arrayM $arrayM]
    }
    return [list $type $record]
}
proc ::Shapefile::AppendDict {dictName args} {
    upvar 1 $dictName myDict
    foreach {key value} $args {
        dict append myDict $key $value
    }
}

################################################################
################################################################

namespace eval ::Shapefile::Copy {
    # Undocumented code to extract shapes from one shapefile into another
    # Works for all shapes without M or Z values (header isn't updated correctly)
}
proc ::Shapefile::Copy::Copy {shape oname idList} {
    set fout [open $oname wb]

    set bytes [::Shapefile::Copy::_NewHeader $shape $idList] ; list
    puts -nonewline $fout $bytes

    set newId 0
    foreach idx $idList {
        incr newId
        set bytes [$shape ReadOneRecordRaw $idx] ; list
        set rawNewId [binary format I $newId] ; list
        set bytes [string replace $bytes 0 3 $rawNewId] ; list
        puts -nonewline $fout $bytes
    }
    close $fout
}
proc ::Shapefile::Copy::_NewHeader {shape idList} {
    set bytes [$shape ReadOneRecordRaw "header"] ; list

    # Insert new size
    set newSize [::Shapefile::Copy::_NewSize $shape $idList]
    set rawNewSize [binary format I $newSize] ; list
    set bytes [string replace $bytes 24 27 $rawNewSize] ; list

    # Insert new bbox
    lassign [$shape BoundingBox $idList] xmin ymin xmax ymax
    set rawNewBbox [binary format qqqq $xmin $ymin $xmax $ymax] ; list
    set bytes [string replace $bytes 36 67 $rawNewBbox] ; list

    # TBD: new Zmin, Zmax, Mmin, Mmax

    return $bytes
}
proc ::Shapefile::Copy::_NewSize {shape idList} {
    # Computes how big new shape file will be (in 2 bytes words)

    set totalSize 100
    foreach idx $idList {
        set low $::Shapefile::INDICES($shape,start,$idx)
        set high $::Shapefile::INDICES($shape,end,$idx)
        set recordSize [expr {$high - $low}]
        incr totalSize $recordSize
    }
    set totalSize [expr {$totalSize / 2}]
    return $totalSize
}

################################################################
################################################################

# Quick sample usage
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    if {$argv ne {}} {
        set fname [lindex $argv 0]
    } else {
        set fname tl_2024_us_state.shp
        if {! [file exists $fname]} {
            set fname [lindex [glob -nocomplain *.shp] 0]
        }
    }
    if {! [file exists $fname]} {
        puts "Bad input file '$fname'"
        return
    }
    puts "\n$fname\n[string repeat = [string length $fname]]"
    set shape [::Shapefile::Go $fname]
    $shape SetLogger NONE
    set header [$shape Header]
    set recordCount [$shape RecordCount]

    for {set idx 1} {$idx <= min(10, $recordCount)} {incr idx} {
        lassign [$shape ReadOneRecord $idx] recordNumber type record
        set line [format "%3d type: %2d status: %s  " $recordNumber $type [dict get $record status]]
        puts $line
    }

    $shape Done
}
return
