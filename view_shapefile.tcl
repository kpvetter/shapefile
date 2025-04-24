#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# view_shapefile.tcl -- <description>
# by Keith Vetter 2025-02-13
# https://www.census.gov/geographies/mapping-files/2021/geo/carto-boundary-file.html
#
# TODO:
#
# ColorScheme logic for BASE_SCHEME needs to be revised vis-a-vis filtering
# Pick DB Column same wm geom as splash???
# move wrapping longitude
# help/about page???
# option to mask overflow shapes???
# url links to good shape files outside of Github????
# some shape files want 2 column keys, e.g. cs_2021_us_county_20m wants county & state names
# tooltips
# fractional meridians for shapes under 1 degree in size???
# Make Splash open file widget the default???
# UK counties is messed up -- wrong data???
#
# DONE meridian lines
# DONE progress bar or busy mouse
# DONE Check PolyLine
# DONE allow range specification
# DONE dig out database names
# DONE limit how many shapes listed
# DONE polyline are lines not polygons
# DONE remove STATES and turn RSTATES into list
# DONE title label
# DONE show how many shapes
# DONE tooltips
# DONE implement keep selected
# NOPE handle zip files
# DONE all on/off in ranges panel
# DONE center image
# DONE do points shapes???
# DONE better error diplay when opening bad file
# DONE bounding box frame
# DONE handle multipoint type shapes
# DONE Splash screen
# DONE Idle screen
# DONE Swapped checkedlistbox columns
# DONE moved index field to end column in the CheckedListBox
#
# DONE removed Range section
# DONE remove Idle screen
# DONE remove Show Meridians/Frame buttons
# DONE keep color scheme until bbox gets recomputed
# DONE open shape files directly from Splash screen
# DONE changed background outside bbox to gray90
# SKIP icon for Pick DB column dialog
# DONE added extracting first shapefile from a zip file
# DONE BETA filter names: avoid some, need others
# DONE BETA add special Europe, Asia, etc. button if viewing those areas
#
# DONE Clear Selected now leaves all drawn shapes checked in the CheckedListBox
# DONE clearing tooltips on erase (shouldn't happen but was getting spurious tooltips)
# DONE Organized checked, index, ids conversions to each other
# DONE Added four US Census Bureau regions
# DONE Added 4 hemispheres
# DONE Removed beta filtering
# DONE Renamed Beta Regions
# DONE keyboard navigation in shape list
# NOPE Splash -- don't duplicate github downloads with local ones
# DONE coloring scheme insuring neighbors have different colors
# DONE use trace add execution add exit enter AtExit
# DONE right click on region clears all then adds
# DONE redid coloring to dynamically determine bordering shapes
# DONE pretty file name with files inside a zip
# DONE random base coloring
# DONE quadrants for shapefiles without any region info

package require Tk
package require fileutil
package require tooltip
package require vfs::zip
package require http
package require tls
http::register https 443 [list ::tls::socket -tls1 1]
package require uri

source [file join [file dirname $argv0] src/shapefile.tcl]
source [file join [file dirname $argv0] src/checkedlistbox.tcl]
source [file join [file dirname $argv0] src/coloring.tcl]
source [file join [file dirname $argv0] src/dbf_lite.tsh]
source [file join [file dirname $argv0] src/filters.tcl]
source [file join [file dirname $argv0] src/regions.tcl]

set S(width) 1024
set S(height) 655
set S(margin) 20
set S(bbox,last) ""
set S(bbox,cnt) 0
set S(indexList,all) {}
set S(indexList,last) {}
set S(colors) [list lightyellow cyan orange green pink sienna1 yellow red blue springgreen]
set S(fname) "<no file loaded>"
set S(fname,pretty) "Welcome to Shapefile Viewer"
set S(fname,pretty2) ""
set S(max,shapes) 1000
set S(NULL_VALUE) {-1 <none>}
set S(title_font) [concat [font actual TkDefaultFont] -size 48 -weight bold]
set S(big_bold_font) [concat [font actual TkDefaultFont] -size 18 -weight bold]
set S(bold_font) [concat [font actual TkDefaultFont] -weight bold]
set S(x_font) [concat [font actual TkDefaultFont] -overstrike 1]
set S(messages) ""
set S(frame,onoff) 1
set S(frame,bbox) ""
set S(meridians,onoff) 1
set S(meridians,bbox) ""
set S(iconfile) myicon.png
set S(icon,usa) usa_icon.png
set S(canvas,bg) gray90
set S(tempdir) ""
set S(dbData) {}

set S(beta) False
if {$::tcl_platform(user) eq "kvetter"} { set S(beta) True }


proc DoDisplay {} {
    global S

    LoadIcons

    wm title . "Shapefile Viewer"
    wm iconphoto . ::img::logo
    wm iconname . "View Shape"
    wm protocol . exit

    ::ttk::frame .top
    label .top.title -textvariable S(fname,pretty) -anchor c -font $S(title_font) -bg $S(canvas,bg)
    label .top.icon_left -image ::img::logo_icon -padx .2i -bg $S(canvas,bg)
    label .top.icon_right -image ::img::logo_icon_flip -padx .2i -bg $S(canvas,bg)
    canvas .c -width $S(width) -height $S(height) -bg $S(canvas,bg) -highlightthickness 0
    ::ttk::frame .bottom -borderwidth 2 -relief ridge
    ::ttk::label .bottom.messages -textvariable S(messages) -anchor c

    ::ttk::frame .ctrl
    ControlWindow .ctrl

    grid .top -sticky news -row 0 -column 0
    grid columnconfigure .top 1 -weight 1
    grid .top.icon_left -row 0 -column 0 -sticky w
    grid .top.title -row 0 -column 1 -sticky news
    grid .top.icon_right -row 0 -column 2 -sticky e

    grid .c -sticky news -row 1 -column 0
    grid .bottom -sticky news -row 2 -column 0
    grid .bottom.messages -row 0 -column 0 -sticky news
    grid .ctrl -sticky ns -row 0 -column 1 -rowspan 3
    grid rowconfigure . 1 -weight 1
    grid columnconfigure . 0 -weight 1
    grid columnconfigure .bottom 0 -weight 1

    focus $S(tree)
    wm withdraw . ; update ; wm deiconify .
    after idle DrawBBox
}

proc ControlWindow {w} {
    global S

    ::ttk::frame $w.top -borderwidth 5 -relief ridge
    ::ttk::frame $w.items -borderwidth 5 -relief ridge
    ::ttk::frame $w.all -borderwidth 5 -relief ridge
    ::ttk::frame $w.beta -borderwidth 5 -relief ridge
    ::ttk::frame $w.buttons -borderwidth 5 -relief ridge
    set ::Regions::frame $w.beta

    grid $w.top -row 0 -sticky ew
    grid $w.items -row 1 -sticky news
    grid $w.all -row 2 -sticky news
    # grid $w.beta -row 3 -sticky news
    grid $w.buttons -row 4 -sticky news
    grid rowconfigure $w 1 -weight 1

    # File buttons
    ::ttk::button $w.top.file -text "Open Shape File" -command GetNewFile
    bind $w.top.file <2> Splash
    bind $w.top.file <3> Splash
    ::ttk::label $w.top.fname -textvariable S(fname,pretty2) -width 30 -anchor c
    pack $w.top.file -side left
    pack $w.top.fname -side left -fill x

    # CheckedListBox
    set ww $w.items
    destroy {*}[winfo child $ww]
    set headers {"Shape Name" "Index"}
    set hSizes {"Shape 12345" "1234"}
    set S(tree) [::CheckedListBox::Create $ww $headers $hSizes]
    $S(tree) column #2 -width 45 -stretch 0

    # All on and off buttons
    set ww $w.all
    ::ttk::button $ww.on -text "All on" -command {ToggleAll "allon"}
    ::ttk::button $ww.off -text "All off" -command {ToggleAll "alloff"}
    grid x $ww.on x $ww.off x -row 0
    grid columnconfig $ww {0 2 4} -weight 1

    # Drawing buttons
    set ww $w.buttons
    ::ttk::button $ww.draw1 -text "Clear & Draw" -command {DoSelectedShapes clear}
    ::ttk::button $ww.draw2 -text "Redraw All" -command {DoSelectedShapes all}
    ::ttk::button $ww.draw3 -text "Draw New" -command {DoSelectedShapes only_new}
    ::ttk::button $ww.clear1 -text "Clear All" -command {EraseShapes erase}
    ::ttk::button $ww.clear2 -text "Clear Selected" -command {EraseShapes selected}
    ::ttk::button $ww.clear3 -text "Keep Selected" -command KeepSelected
    grid x $ww.draw1 x $ww.clear1 x -row 1 -sticky ew
    grid x $ww.draw2 x $ww.clear2 x -row 2 -sticky ew
    grid x $ww.draw3 x $ww.clear3 x -row 3 -sticky ew
    grid columnconfig $ww {0 2 4} -weight 1
}
proc GetNewFile {} {
    global S

    destroy .splash
    update

    set types {
        {{Shape Files} {.shp}}
        {{Zip Files} {.zip}}}
    set initialDir [file dirname $S(fname)]
    if {$initialDir eq $S(tempdir)} { set initialDir "."}

    set fname [tk_getOpenFile -title "Open SHAPE file" -parent .ctrl -filetypes $types \
                   -initialdir $initialDir]
    if {$fname eq ""} return
    InstallZipFile $fname
}
proc InstallZipFile {zipName} {
    if {[file extension $zipName] eq ".zip"} {
        set fname [::Zip::Open $zipName]
        if {$fname ne ""} {
            InstallNewFile $fname $zipName
        } else {
            MyError "No Shapefiles found in $zipName"
        }
    } else {
        InstallNewFile $zipName $zipName
    }
}
proc InstallNewFile {fname trueName} {
    global S

    ::tooltip::tooltip clear
    .c delete all

    ::CheckedListBox::Clear $S(tree)
    set S(bbox,last) ""
    catch {$S(shape) Done}
    DrawBBox

    set n [catch {set S(shape) [::Shapefile::Go $fname]} emsg]
    if {$n} {
        MyError $emsg
        return
    }
    set S(fname) $fname
    set S(fname,pretty) [file rootname [file tail $trueName]]
    set S(fname,pretty2) $S(fname,pretty)
    set header [$S(shape) Header]
    set type [dict get $header shapeType]
    if {$type ni {5 15 25 3 13 23 1 11 21 8 18 28}} {
        MyError "Cannot view shapes of type [dict get $header pretty]"
        $S(shape) Done
        set S(fname) "<no file loaded>"
        set S(fname,pretty) ""
        set S(fname,pretty2) ""
        return
    }

    set recordCount [$S(shape) RecordCount]
    append S(fname,pretty2) " -- [Comma $recordCount] Shapes"

    set dbData [ExtractAllDBaseInfo $fname]
    if {$dbData eq {}} {
        set dbData [lmap v [range 1 [expr {min($recordCount+1, $S(max,shapes)+1)}]] { list $v "" }]
    }
    set recordCount [llength $dbData] ;# May have been filtered
    if {$recordCount > $S(max,shapes)} {
        set emsg "Too many shapes [Comma $recordCount]\n"
        append emsg "Only showing first [Comma $S(max,shapes)] shapes"
        tk_messageBox -icon warning -message $emsg -type ok -parent .
        set recordCount $S(max,shapes)
        set dbData [lrange $dbData 0 $recordCount]
    }

    set S(dbData) $dbData
    set S(indexList,all) [lmap x $S(dbData) { lindex $x 0 } ]
    set S(recordCount) $recordCount
    set checkboxData {}
    foreach datum $S(dbData) {
        lassign $datum row value

        set meta [$S(shape) ReadOneMeta $row]
        set numPoints 1
        if {[dict exists $meta numPoints]} {
            set numPoints [dict get $meta numPoints]
        }
        if {$value eq ""} {
            set value "[dict get $meta pretty] with [Plural $numPoints point]"
        } else {
            append value " ([Plural $numPoints point])"
        }
        lappend checkboxData [list $value $row]
    }

    ::CheckedListBox::Clear $S(tree)
    ::CheckedListBox::AddManyItems $S(tree) $checkboxData
    ::Regions::InstallBlocs
    update
    bind $S(tree) <KeyPress> {::CheckedListBox::_KeyPress %W %A}

    ::Coloring::NewBaseColorScheme $S(shape) $S(recordCount)
}
proc ExtractAllDBaseInfo {fname} {
    # Returns list of {row# value} from *.dbf for selected column

    set dbfname "[file rootname $fname].dbf"
    if {! [file exists $dbfname]} { return {} }
    set nRows [::DBF::Go $dbfname]
    set rawColData [::DBF::Columns]
    set colData [lmap v $rawColData {
        expr {[lindex $v 3] ne "C" || [lindex $v 2] < 6 ? [continue] : $v}
    }]

    lassign [PickDBaseColumn $colData] column name
    if {$column == -1} { return {} }
    set nameData [::DBF::ReadRecordColumns [list $column] 1 -1] ; list
    ;# set nameData [PrettyNames $nameData] -- data is only one column, don't need this
    set nameData [::Filters::FilterDBaseInfo $nameData]
    return $nameData
}
proc PrettyNames {nameData} {
    # Name data from dBaseIII may contain multiple columns, if so join into one name
    set result {}
    foreach datum $nameData {
        set names [lassign $datum row]
        set prettyName [join $names "."]
        lappend result [list $row $prettyName]
    }
    return $result
}

proc PickDBaseColumn {colData} {
    global S

    destroy .columns
    toplevel .columns
    wm title .columns "Pick Shape Name"
    wm transient .columns .

    ::ttk::frame .columns.f
    grid .columns.f -sticky news

    set f .columns.f.title
    set TITLE $f
    set w $f.title
    ::ttk::frame $f -padding .2i -relief ridge -borderwidth 4
    ::ttk::label $w -text "Pick DB column for shape names" -font $S(big_bold_font) -anchor c
    grid $f -row 0 -column 0 -sticky ew -pady {0 .1i}
    grid $w -sticky news

    # Column middle section
    set f .columns.f.columns
    set COLUMNS $f
    ::ttk::frame $f
    grid $f -row 1 -column 0 -sticky ew -pady {0 .1i}
    grid columnconfigure $f all -weight 1

    set row 0
    set col 1
    set w $f.column_0
    ::ttk::radiobutton $w -text "<none>" -variable S(pick,column) -value $S(NULL_VALUE)
    set S(pick,column) [$w cget -value]
    grid $w -sticky ew -row $row -column $col

    set firstChoices [list "name"]
    set secondChoices [list "country" "county" "countyname"]

    foreach datum $colData {
        lassign $datum idx name len
        set w $f.column_$idx
        set label "$name ($len)"

        # Pick default value
        set lname [string tolower $name]
        if {$lname in $firstChoices} {
            set S(pick,column) [list $idx $name]
        }
        if {$S(pick,column) eq $S(NULL_VALUE) && $lname in $secondChoices} {
            set S(pick,column) [list $idx $name]
        }
        ::ttk::radiobutton $w -text $label -variable S(pick,column) -value [list $idx $name]

        incr col 2
        if {$col == 5} {
            set col 1
            incr row
        }
        grid $w -sticky ew -row $row -column $col
    }
    grid columnconfigure $f {0 2 4} -weight 1

    # Buttons at the bottom
    set f .columns.f.buttons
    set BUTTONS $f
    ::ttk::frame $f
    ::ttk::button $f.cancel -text Cancel \
        -command {set ::S(pick,column) $S(NULL_VALUE) ; destroy .columns}
    ::ttk::button $f.ok -text Ok -command {destroy .columns}

    grid $f -row 2 -column 0 -sticky ew -pady {.1i .2i}
    grid $f.cancel $f.ok
    grid columnconfigure $f all -weight 1

    # Locate window nicely in main window
    update idletasks

    scan [wm geometry .] "%dx%d+%d+%d" width height x0 y0
    set x1 [expr {$x0 + [winfo reqwidth .] / 2 \
                      - [winfo reqwidth .columns] / 2}]
    set y1 [expr {$y0 + 100}]
    wm geom .columns +$x1+$y1

    # Wait for user to make a choice
    grab set .columns
    tkwait window .columns
    grab release .columns

    return $S(pick,column)
}


proc Comma {num} {
    while {[regsub {^([-+]?[0-9]+)([0-9][0-9][0-9])} $num {\1,\2} num]} {}
    return $num
}

proc ComputeTransform {bbox pts} {
    # Scale list of {lon lat} points to fit into bounding box
    global S

    set result {}
    lassign $bbox left bottom right top

    set cwidth [winfo width .c]
    set cheight [winfo height .c]
    set bwidth [expr {$right - $left}]
    set bheight [expr {$top - $bottom}]

    if {$bwidth == 0 || $bheight == 0} {
        set x [expr {$cwidth / 2}]
        set y [expr {$cheight / 2}]
        foreach pt $pts { lappend result $x $y }
        return $result
    }

    # Compute scale to fit into bbox
    set scale_x [expr {($cwidth - 2 * $S(margin)) / $bwidth}]
    set scale_y [expr {($cheight - 2 * $S(margin)) / $bheight}]
    set scale_xy [expr {min($scale_x, $scale_y)}]

    # Compute padding to center bbox in the canvas
    set x [expr {($right - $left) * $scale_xy}]
    set unused [expr {$cwidth - $x}]
    set padx [expr {$unused / 2 - $S(margin)}]
    set y [expr {($top - $bottom) * $scale_xy}]
    set unused [expr {$cheight - $y}]
    set pady [expr {$unused / 2 - $S(margin)}]

    foreach {lon lat} $pts {
        set cx [expr {$padx + $S(margin) + ($lon - $left) * $scale_xy}]
        set cy [expr {$pady + $S(margin) - ($lat - $top) * $scale_xy}]
        lappend result $cx $cy
    }

    set result [lmap v $result { expr {int($v)}}]
    return $result
}


proc GetPointsForPart {requestedPart record} {
    # The points array is divided into parts indexed by [dict get $record parts]
    # return then nth (base 1) part

    if {$requestedPart <= 0} {
        error "requestedPart too small, must be at least 1"
    }

    set parts [dict get $record parts]
    set numParts [dict get $record numParts]
    if {$requestedPart > $numParts} {
        if {$numParts == 1} {
            error "requestPart ($requestedPart) too big, shape only has one part"
        } else {
            error "requestPart ($requestedPart) too big, shape only has $numParts parts"
        }
    }

    lassign [lrange [concat _ $parts end] $requestedPart end] lo hi
    set lo [expr {2 * $lo}]
    if {$hi ne "end"} {
        set hi [expr {2 * $hi - 1}]
    }
    set pts [lrange [dict get $record points] $lo $hi]
    return $pts
}
proc range {args} {
    # Extension of python's range command, except:
    # * accepts numbers of form a, a+b or a-b
    # * high argument can be a list and will equal the length of the list

    if {[llength $args] == 1} {
        lassign [concat 0 $args 1] low high step
    } elseif {[llength $args] == 2} {
        lassign [concat $args 1] low high step
    } elseif {[llength $args] == 3} {
        lassign $args low high step
    } else {
        error "Wrong number of arguments to range: '$args'"
    }

    # accepts numbers of form a, a+b, a-b, a+-b, a--b
    if {[regexp {^-?\d+[+-]-?\d+$} $low]} { set low [expr $low] }
    if {[regexp {^-?\d+[+-]-?\d+$} $high]} { set high [expr $high] }
    if {[regexp {^-?\d+[+-]-?\d+$} $step]} { set step [expr $step] }

    set result {}
    if {$low > $high && $step < 0} {
        for {set idx $low} {$idx > $high} {incr idx $step} {
            lappend result $idx
        }
    } else {
        for {set idx $low} {$idx < $high} {incr idx $step} {
            lappend result $idx
        }
    }
    return $result
}

proc TooltipClear {args} {
    foreach tag $args {
        foreach id [.c find withtag $tag] {
            ::tooltip::tooltip clear .c,$id
        }
    }

}
proc DoOneShape {shape idx bbox color} {
    global S

    set name [lindex $S(dbData) $idx-1 1]

    lassign [$shape ReadOneRecord $idx] recordNumber type record
    set type [dict get [$shape Header] shapeType]
    set isPolygon [expr {($type % 10) == 5}]
    set isPoint [expr {($type % 10) == 1}]
    set isMultiPoint [expr {($type % 10) == 8}]
    set name [lindex $S(dbData) $idx-1 1]
    if {$name eq ""} {set name "Shape #$idx"}

    TooltipClear shape_$idx
    .c delete shape_$idx

    if {$isPoint || $isMultiPoint} {
        if {$isPoint} {
            set pts [list [dict get $record pointX] [dict get $record pointY]]
        } else {
            set pts [dict get $record points]
        }
        foreach {lon lat} $pts {
            lassign [ComputeTransform $bbox [list $lon $lat]] x y
            set x0 [expr {$x - 5}]
            set y0 [expr {$y - 5}]
            set x1 [expr {$x + 5}]
            set y1 [expr {$y + 5}]
            set xy [list $x $y0 $x1 $y $x $y1 $x0 $y]
            .c create poly $xy -tag [list shape shape_$idx] -fill $color -outline black
            ::tooltip::tooltip .c -items shape_$idx $name
        }
    } else {
        set numPoints [dict get $record numPoints]
        set numParts [dict get $record numParts]
        for {set part 1} {$part <= $numParts} {incr part} {
            set pts [GetPointsForPart $part $record]
            set xy [ComputeTransform $bbox $pts]
            if {$isPolygon} {
                .c create poly $xy -tag [list shape shape_$idx] -width 2 -fill $color -outline black
            } else {
                .c create line $xy -tag [list shape shape_$idx] -width 2 -fill $color
            }
        }
        ::tooltip::tooltip .c -items shape_$idx $name
    }
    .c raise bbox
}
proc Plural {cnt single {many ""}} {
    if {$cnt == 1} { return "1 $single" }
    if {$many eq ""} { set many "${single}s" }
    return "[Comma $cnt] $many"
}
proc EraseShapes {how} {
    global S

    if {$how eq "erase"} {
        TooltipClear shape
        .c delete shape
        ToggleAll "alloff"
        set S(indexList,last) {}
        return
    }

    # Clear selected shapes
    set indexList [CheckedToIndexList]

    foreach idx $indexList {
        set tag "shape_$idx"
        TooltipClear $tag
        .c delete $tag
    }

    # Mark on those states still drawn
    set indexList [CanvasToIndexList]
    set idList [IndexListToIdList $indexList]
    ToggleAll "alloff"
    ::CheckedListBox::ToggleSome $S(tree) 1 $idList
    set S(indexList,last) [CheckedToIndexList]
}
proc KeepSelected {} {
    set ::S(indexList,last) [CheckedToIndexList]
    set keepTagList [lmap v $::S(indexList,last) { return -level 0 "shape_$v" }]

    foreach id [.c find withtag shape] {
        set keep False

        set tags [.c itemcget $id -tag]
        foreach tag $tags {
            if {$tag in $keepTagList} {
                set keep True
                break
            }
        }
        if {! $keep} {
            TooltipClear $id
            .c delete $id
        }
    }
}
#################################################################
#
# indexList : Shape's indices
# idList    : Tree's items
# nameList  : Shape's named items
#
# checked items  -> idList    : ::CheckedListBox::GetChecked
# checked items  -> indexList : CheckedToIndexList
# nameList       -> indexList : NameListToIndexList
# indexList      -> idList    : IndexListToIdList
# indexList      -> nameList  : IndexListToNameList
# canvas item    -> indexList : CanvasToIndexList

proc CheckedToIndexList {} {
    global S
    set tags [::CheckedListBox::GetChecked $S(tree)]
    set indexList [lmap v $tags { lindex [$S(tree) item $v -values] 1}]
    return $indexList
}
proc NameListToIndexList {nameList} {
    global S

    set indexList {}
    foreach dbRow $S(dbData) {
        lassign $dbRow index name
        if {$name in $nameList} {
            lappend indexList $index
        }
    }
    return $indexList
}
proc IndexListToIdList {indexList} {
    global S
    set idList {}
    foreach id [$S(tree) children {}] {
        set index [lindex [$S(tree) item $id -values] 1]
        if {$index in $indexList} {
            lappend idList $id
        }
    }
    return $idList
}
proc IndexListToNameList {indexList} {
    global S
    set nameList {}

    foreach dbRow $S(dbData) {
        lassign $dbRow index name
        if {$index in $indexList} {
            lappend nameList [expr {$name ne "" ? $name : "Shape $index"}]
        }
    }
    set nameList [lsort -dictionary $nameList]
    return $nameList
}
proc CanvasToIndexList {} {
    global S

    set indexList {}
    foreach id [.c find withtag shape] {
        lassign [.c itemcget $id -tag] _ tag
        lassign [split $tag "_"] _ index
        if {$index ne ""} {
            lappend indexList $index
        }
    }
    return $indexList
}

proc DoSelectedShapes {how} {
    global S

    set start [clock seconds]
    if {$how eq "clear"} {
        TooltipClear shape meridians
        .c delete shape meridians
    }

    set indexList [CheckedToIndexList]
    if {$how eq "only_new"} {
        set indexList [lmap v $indexList { if {$v in $S(indexList,last)} continue ; set v }]
        lappend S(indexList,last) {*}$indexList
    } else {
        set S(indexList,last) $indexList
    }
    if {$indexList eq {}} return

    set nameList [IndexListToNameList $indexList]
    set total [llength $indexList]

    set numShapes [llength [.c find withtag shape]]
    if {$how eq "clear" || $numShapes == 0} {
        set S(bbox,last) [$S(shape) BoundingBox $indexList]
        incr S(bbox,cnt)
    }
    DrawBBox
    DrawMeridians

    . config -cursor watch
    .c config -cursor watch
    update

    set cnt 0
    foreach idx $indexList name $nameList {
        incr cnt
        set color [::Coloring::GetColor $idx $S(bbox,cnt)]
        Progress "Drawing #$cnt of $total"
        DoOneShape $S(shape) $idx $S(bbox,last) $color
        if {$cnt % 10 == 0} update
    }
    update
    . config -cursor {}
    .c config -cursor {}
    set duration [expr {[clock seconds] - $start}]
    Progress "Drew [Plural $total shape] in [Plural $duration second]"
    update
}
proc DrawBBox {} {
    global S
    if {! $S(frame,onoff)} {
        .c delete bbox mask
        return
    }
    if {[.c find withtag bbox] ne {} && $S(frame,bbox) eq $S(bbox,last)} return

    .c delete bbox mask
    if {$S(bbox,last) eq ""} {
        set xy [list $S(margin) $S(margin) \
                    [expr {[winfo width .c] - $S(margin)}] \
                    [expr {[winfo height .c] - $S(margin)}]]
    } else {
        set xy [ComputeTransform $S(bbox,last) $S(bbox,last)]
        set S(frame,bbox) $S(bbox,last)
    }
    set margin 5
    lassign $xy x0 y0 x1 y1
    set x0 [expr {$x0 - $margin}]
    set x1 [expr {$x1 + $margin}]
    set y0 [expr {$y0 + $margin}]
    set y1 [expr {$y1 - $margin}]
    set xy2 [list $x0 $y0 $x1 $y0 $x1 $y1 $x0 $y1 $x0 $y0]

    .c create line $xy2 -tag bbox -fill black -width 10
    .c create line $xy2 -tag bbox -fill white -width 2
    .c raise bbox
    .c create rect $x0 $y1 $x1 $y0 -tag mask -fill white -outline white
    .c lower mask
}

proc ToggleAll {onoff} {
    global S

    CheckedListBox::ToggleAll $S(tree) [expr {$onoff eq "allon"}]
}
proc DrawMeridians {} {
    global S

    if {$S(bbox,last) eq {} || ! $S(meridians,onoff)} {
        TooltipClear meridians
        .c delete meridians
        return
    }
    if {[.c find withtag meridians] ne {} && $S(meridians,bbox) eq $S(bbox,last)} return

    lassign $S(bbox,last) left bottom right top
    set lats [expr {$top - $bottom}]
    set lons [expr {$right - $left}]
    set dlat [expr {$lats < 20 ? 1 : 10}]
    set dlon [expr {$lons < 20 ? 1 : 10}]
    set delta [expr {max($dlat, $dlon)}]

    _DrawMeridians $S(bbox,last) $delta $delta
    set S(meridians,bbox) $S(bbox,last)
}
proc _DrawMeridians {bbox dlat dlon} {
    lassign $bbox left bottom right top

    TooltipClear meridians
    .c delete meridians
    set north [range $dlat 90+$dlat $dlat]
    set south [range -$dlat -90-$dlat -$dlat]
    set all [concat [lreverse $south] 0 $north]
    foreach lat $all {
        if {$lat < $bottom} continue
        if {$lat > $top} break

        set pts [list $left $lat $right $lat]
        set xy [ComputeTransform $bbox $pts]
        .c create line $xy -tag [list meridians lat_$lat] -dash "."
        ::tooltip::tooltip .c -items lat_$lat "latitude $lat\xb0"
    }

    set east [range $dlon 180+$dlon $dlon]
    set west [range -$dlon -180-$dlon -$dlon]
    set all [concat [lreverse $west] 0 $east]
    foreach lon $all {
        if {$lon < $left} continue
        if {$lon > $right} break
        set pts [list $lon $top $lon $bottom]
        set xy [ComputeTransform $bbox $pts]
        .c create line $xy -tag [list meridians lon_$lon] -dash "."
        ::tooltip::tooltip .c -items lon_$lon "longitude $lon\xb0"
    }
    .c itemconfig lat_0 -width 2 -dash "-"
    .c itemconfig lon_0 -width 2 -dash "-"
    .c itemconfig lon_180 -width 2 -dash "-"
    .c lower meridians
    .c lower mask
}

proc Splash {} {
    global S

    destroy .splash
    ::ttk::frame .splash -padding {.2i .2i} -relief ridge -borderwidth 5
    ::ttk::label .splash.logo -image ::img::logo_small -padding {0 0 .2i 0}
    ::ttk::label .splash.title -text "Shapefile Viewer" -font $S(title_font)
    set text "View the contents of an ESRI Shapefile"
    ::ttk::label .splash.text -text $text -justify c -font $S(big_bold_font)
    ::ttk::label .splash.credit -text "By Keith Vetter\nMarch 2025" -justify c -font $S(bold_font)

    ::ttk::frame .splash.web
    ::ttk::frame .splash.buttons

    grid .splash.logo .splash.title
    grid ^ .splash.text -sticky n
    grid .splash.credit -columnspan 2
    grid .splash.web -columnspan 2 -pady .25i
    grid .splash.buttons -columnspan 2

    set localFiles [lsort -dictionary [glob -nocomplain *.shp *.zip]]

    # Buttons for web downloads
    set col -1
    foreach item [::Github::Known] {
        lassign $item key txt url icon
        incr col
        set w .splash.web.$col

        # If the file is local, use that instead of the web version
        set tail [file tail $url]
        if {$tail in $localFiles} {
            set cmd [list SplashGo $tail]
            set tooltip "Open local copy of\n$txt"
        } else {
            set cmd [list ::Github::Open $key]
            set tooltip "Download from the web\n$txt"
        }
        ::ttk::button $w -text $txt -command $cmd -image $icon -compound top
        grid $w -sticky ns -row 0 -column $col -padx .1i
        ::tooltip::tooltip $w $tooltip
    }

    # Buttons for local .shp and .zip files
    set id -1
    foreach shp [lrange $localFiles 0 10] {
        incr id
        set w .splash.buttons.$id
        ::ttk::button $w -text $shp -command [list SplashGo $shp]
        grid $w -sticky ew
    }
    grid config $w -pady {0 .2i}

    # Close button
    ::ttk::button .splash.buttons.close -text "Open Shape File Dialog" -command GetNewFile
    grid .splash.buttons.close -pady {.25i 0} -sticky ew

    place .splash -in .c -relx .5 -rely .4 -anchor c
    # after 30000 {destroy .splash}
    bind .splash.logo <2> {destroy .splash}
    bind .splash.logo <3> {destroy .splash}
}
proc SplashGo {fname} {
    destroy .splash
    InstallZipFile $fname
}
proc CleanUp {} {
    # Tasks to be done before exiting
    catch {file delete -force -- $::S(tempdir)}
    destroy .
    exit
}
namespace eval ::Zip {
    # Code to open a zip file using Tcl's VSF file system and extracting the
    # the shape and dbaseIII files into a temporary directory

}
proc ::Zip::Open {zipName} {
    # Opens up the zipName and extracts the first XXX.shp file (also XXX.shx and XXX.dbf)
    # into a temp directory.
    global S

    ::Zip::Cleanup $zipName
    if {$S(tempdir) eq ""} {
        set S(tempdir) [::fileutil::maketempdir -prefix view_shapefile_kpv_]
    }

    set shapeFile ""
    try {
        set mountPoint /__zip
        set zipVFS [::vfs::zip::Mount [file normalize $zipName] $mountPoint]
        set shpData [::Zip::FindAllShapeFiles $mountPoint]
        if {[llength $shpData] == 0} { return "" }

        lassign [lindex $shpData 0] shpFile shxFile dbfFile
        set shapeFile [file join $S(tempdir) [file tail $shpFile]]

        set n [catch {
            file copy -force -- $shpFile $S(tempdir)
            file copy -force -- $dbfFile $S(tempdir)
            file copy -force -- $shxFile $S(tempdir)
        } emsg]

    } finally {
        ::vfs::zip::Unmount $zipVFS $mountPoint
    }
    if {[file exist $shapeFile]} { return $shapeFile }
    return ""
}

proc ::Zip::FindAllShapeFiles {cwd} {
    # Recursively search a directory (in this case inside a zip file) for all shapefiles
    # Result will be a list of tuples: {fname.shp fname.shx fname.dbf}

    set shpData {}
    foreach zfile [lsort -dictionary [glob -nocomplain $cwd/*]] {
        if {[file isdirectory $zfile]} {
            set more [::Zip::FindAllShapeFiles $zfile]
            lappend shpData {*}$more
        } elseif {[file extension $zfile] eq ".shp"} {
            set datum [list $zfile]
            foreach ext {.shx .dbf} {
                set extra "[file rootname $zfile]$ext"
                lappend datum [expr {[file exists $extra] ? $extra : ""}]
            }
            lappend shpData $datum
        }
    }
    return $shpData
}
proc ::Zip::Cleanup {except} {
    global S
    if {$S(tempdir) ne ""} {
        foreach fname [glob -nocomplain [file join $S(tempdir) "*"]] {
            if {$fname ne $except} {
                catch {file delete -force -- $fname}
            }
        }
    }
}

proc Progress {msg} {
    set ::S(messages) $msg
    update
}
proc MyError {emsg} {
    tk_messageBox -icon error -type ok -message $emsg -parent .
}
proc AtExit {args} {
    global S
    if {$S(tempdir) ne ""} {
        catch {file delete -force -- $S(tempdir)}
    }
}

namespace eval ::Github {
    # Holds info about Shapefiles we have stored in Github or possibly elsewhere on the web
    variable URL
    set baseUrl https://raw.githubusercontent.com/kpvetter/shapefile/refs/heads/main/sampleData
    # URL(x) [list title url icon]
    set URL(worldShapes.zip) [list "World Countries" $baseUrl/worldShapes.zip ::img::world_icon]
    set URL(cb_2021_us_state_20m.zip) [list "United States" $baseUrl/cb_2021_us_state_20m.zip ::img::usa_icon]
}

proc ::Github::Known {} {
    variable URL
    set all [lmap {key value} [array get URL] { linsert $value 0 $key }]
    return [lsort -dictionary -index 0 $all]
}

proc ::Github::Open {who} {
    variable URL

    if {! [info exists URL($who)]} {
        MyError "$who not in URL list"
        return
    }
    destroy .splash
    set url [lindex $URL($who) 1]
    set zdata [::Github::_DownloadZip $url] ; list
    set zipName [::Github::_SaveZip $who $zdata]
    InstallZipFile $zipName
}

proc ::Github::_DownloadZip {github_url} {
    # Downloads a given URL

    set token [::Github::_geturl_followRedirects $github_url]

    set code [::http::ncode $token]
    set data [::http::data $token] ; list
    ::http::cleanup $token

    if {$code != 200} {
        puts stderr "ERROR: wrong http code ($code) downloading $github_url"
        exit 1
    }
    return $data
}

proc ::Github::_SaveZip {who zdata} {
    global S

    if {$S(tempdir) eq ""} {
        set S(tempdir) [::fileutil::maketempdir -prefix view_shapefile_kpv_]
    }
    set zipName [file join $S(tempdir) $who]

    set fout [open $zipName wb]
    puts -nonewline $fout $zdata
    close $fout

    return $zipName
}

proc ::Github::_geturl_followRedirects {url args} {
    # Calls http::geturl while following redirects

    array set URI [::uri::split $url] ;# Need host info from here
    set maxTries 10
    while {[incr maxTries -1] >= 0} {
        set token [http::geturl $url {*}$args]
        if {![string match {30[1237]} [::http::ncode $token]]} {return $token}
        array set meta [set ${token}(meta)]
        if {![info exist meta(Location)]} {
            return $token
        }
        http::reset $token

        array set uri [::uri::split $meta(Location)]
        unset meta
        if {$uri(host) == ""} { set uri(host) $URI(host) }
        # problem w/ relative versus absolute paths
        set url [eval ::uri::join [array get uri]]
    }
}
proc LoadIcons {} {
    global S

    image create photo ::img::logo -file $S(iconfile)
    image create photo ::img::logo_small
    ::img::logo_small copy ::img::logo -subsample 2 2
    image create photo ::img::logo_icon
    ::img::logo_icon copy ::img::logo -subsample 4 4
    image create photo ::img::logo_icon_flip
    ::img::logo_icon_flip copy ::img::logo -subsample -4 4

    image create photo ::img::usa_icon -file $S(icon,usa)
    image create photo ::img::world_icon
    ::img::world_icon copy ::img::logo_icon
}


################################################################
################################################################

foreach tinfo [trace info execution exit] {
    trace remove execution exit {*}$tinfo
}
trace add execution exit enter AtExit
trace add execution xx enter AtExit

DoDisplay
Splash

return
