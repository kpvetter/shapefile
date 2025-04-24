#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# regions.tcl -- Contains GIS data about various regions of the USA or the world
#

namespace eval ::Regions {
    variable frame ""  ;# Set in ControlWindow when panel is being laid out
    variable BLOCS

    unset -nocomplain BLOCS
}
proc ::Regions::InstallBlocs {} {
    variable frame

    set grid_max_columns 3
    destroy {*}[winfo child $frame]
    grid forget $frame
    ::tooltip::clear $frame._*

    set which [::Regions::WhichBlocs]
    if {$which eq ""} return

    grid $frame -row 3 -sticky news

    set row -1
    set col -1
    foreach bloc $which {
        set col [expr {($col + 1) % $grid_max_columns}]
        incr row [expr {$col == 0}]
        set w $frame.$row,$col

        lassign [split [string map {"_" " "} $bloc] ","] _ name tooltip
        ::ttk::button $w -text $name -command [list ::Regions::ToggleBlocOn $bloc]
        bind $w <2> [list ::Regions::ToggleBlocOn $bloc True]
        bind $w <3> [list ::Regions::ToggleBlocOn $bloc True]
        if {$tooltip ne ""} {
            set tooltip [string map {@ "\n"} $tooltip]
            ::tooltip::tooltip $w $tooltip
        }

        grid $w -row $row -column $col -sticky ew
    }
    grid columnconfigure $frame all -weight 1 -uniform a
}
proc ::Regions::ToggleBlocOn {bloc {clear False}} {
    variable BLOCS
    global S

    if {$bloc in {x,North_Half x,East_Half x,South_Half x,West_Half}} {
        set indexList [::Regions::Quadrants $bloc]
    } else {
        set nameList $BLOCS($bloc)

        # Convert names into indexes in the Shapefile
        set indexList [NameListToIndexList $nameList]
    }

    # Convert indexes into CheckedListBox item ids
    set idList [IndexListToIdList $indexList]

    # Turn on CheckedListBox ids
    if {$idList ne {}} {
        if {$clear} {
            ToggleAll "alloff"
        }
        ::CheckedListBox::ToggleSome $S(tree) 1 $idList
    }
}


proc ::Regions::WhichBlocs {} {
    variable BLOCS
    global S

    set masterNameList [lmap x $S(dbData) { lindex $x 1 }]

    set result {}
    foreach bloc [lsort -dictionary [array names BLOCS]] {
        if {[::Regions::Contains $bloc $BLOCS($bloc) $masterNameList]} {
            lappend result $bloc
        }
    }
    if {$result eq {}} {
        set result {x,North_Half x,East_Half x,South_Half x,West_Half}
    }
    return $result
}
proc ::Regions::Contains {who subList masterList} {
    # NB. names such as Georgia and Puerto Rico can be in multiple domains
    set found 0
    set missing 0
    foreach item $subList {
        if {$item in $masterList} {
            incr found
        } else {
            incr missing
        }
    }
    if {$found > $missing} { return True }
    return False
}

proc ::Regions::Quadrants {which} {
    global S

    array set SIDES {x,West_Half {3 +} x,South_Half {2 +} x,East_Half {1 -} x,North_Half {4 -}}

    set bboxes {}
    foreach idx $S(indexList,all) {
        set meta [$S(shape) ReadOneMeta $idx]
        lappend bboxes [list $idx {*}[dict get $meta box]]
    }

    set half [expr {$S(recordCount) / 2}]
    lassign $SIDES($which) index direction
    set dir [expr {$direction eq "-" ? "-decreasing" : "-increasing"}]
    set items [lrange [lsort -real $dir -index $index $bboxes] 0 $half]
    set itemList [lsort -integer [lmap x $items { lindex $x 0 }]]

    return $itemList
}

################################################################
################################################################
#
# Hard code regions
# * USA -- based on US Census Bureau
# * World -- continents and hemispheres
# * California -- https://census.ca.gov/regions/
#

# Four US Census Bureau regions
set ::Regions::BLOCS(aa,Midwest_US,US_Census_Region:_Midwest) {
    "Illinois" "Indiana" "Iowa" "Kansas" "Michigan" "Minnesota" "Missouri"
    "Nebraska" "North Dakota" "Ohio" "South Dakota" "Wisconsin"}
set ::Regions::BLOCS(aa,Northeast_US,US_Census_Region:_Northeast) {
    "Connecticut" "Maine" "Massachusetts" "New Hampshire" "New Jersey"
    "New York" "Pennsylvania" "Rhode Island" "Vermont"}
set ::Regions::BLOCS(aa,West_US,US_Census_Region:_West) {
    "Alaska" "Arizona" "California" "Colorado" "Hawaii" "Idaho" "Montana"
    "Nevada" "New Mexico" "Oregon" "Utah" "Washington" "Wyoming"}
set ::Regions::BLOCS(aa,South_US,US_Census_Region:_South) {
    "Alabama" "Arkansas" "Delaware" "Florida" "Georgia" "Kentucky"
    "Louisiana" "Maryland" "Mississippi" "North Carolina" "Oklahoma"
    "South Carolina" "Tennessee" "Texas" "Virginia" "West Virginia"
    "District of Columbia"}

# https://www2.census.gov/geo/pdfs/maps-data/maps/reference/us_regdiv.pdf
# https://en.wikipedia.org/wiki/List_of_regions_of_the_United_States
# set ::Regions::BLOCS(bb,New_England,US_Census_Division:_New_England) {
#     "Connecticut" "Maine" "Massachusetts" "New Hampshire" "Rhode Island" "Vermont"}
# set ::Regions::BLOCS(bb,Middle_Atlantic,US_Census_Division:_Middle_Atlantic) {
#     "New Jersey" "New York" "Pennsylvania"}
# set ::Regions::BLOCS(bb,East_North_Central,US_Census_Division:_East_North_Central) {
#     "Indiana" "Illinois" "Michigan" "Ohio" "Wisconsin"}
# set ::Regions::BLOCS(bb,West_North_Central,US_Census_Division:_West_North_Central) {
#     "Iowa" "Kansas" "Minnesota" "Missouri" "Nebraska" "North Dakota" "South Dakota"}
# set ::Regions::BLOCS(bb,South_Atlantic,US_Census_Division:_South_Atlantic) {
#     "Delaware" "District of Columbia" "Florida" "Georgia" "Maryland" "North Carolina"
#     "South Carolina" "Virginia" "West Virginia"}
# set ::Regions::BLOCS(bb,East_South_Central,US_Census_Division:_East_South_Central) {
#     "Alabama" "Kentucky" "Mississippi" "Tennessee"}
# set ::Regions::BLOCS(bb,West_South_Central,US_Census_Division:_West_South_Central) {
#     "Arkansas" "Louisiana" "Oklahoma" "Texas"}
# set ::Regions::BLOCS(bb,Mountain,US_Census_Division:_Mountain) {
#     "Arizona" "Colorado" "Idaho" "New Mexico" "Montana" "Utah" "Nevada" "Wyoming"}
# set ::Regions::BLOCS(bb,Pacific,US_Census_Division:_Pacific) {
#     "Alaska" "California" "Hawaii" "Oregon" "Washington"}

set ::Regions::BLOCS(cc,Continental_US,US_without_Alaska_and_Hawaii) {
    "Alabama" "Arizona" "Arkansas" "California" "Colorado"
    "Connecticut" "Delaware" "District of Columbia" "Florida"
    "Georgia" "Idaho" "Illinois" "Indiana" "Iowa" "Kansas" "Kentucky"
    "Louisiana" "Maine" "Maryland" "Massachusetts" "Michigan"
    "Minnesota" "Mississippi" "Missouri" "Montana" "Nebraska" "Nevada"
    "New Hampshire" "New Jersey" "New Mexico" "New York" "North Carolina"
    "North Dakota" "Oklahoma" "Ohio" "Oregon" "Pennsylvania"
    "Rhode Island" "South Carolina" "South Dakota" "Tennessee" "Texas"
    "Utah" "Vermont" "Virginia" "Washington" "West Virginia"
    "Wisconsin" "Wyoming"}

# https://www.countries-ofthe-world.com/
set ::Regions::BLOCS(aa,Europe) {
    "Albania" "Andorra" "Armenia" "Austria" "Azerbaijan" "Belarus"
    "Belgium" "Bosnia and Herzegovina" "Bulgaria" "Croatia" "Cyprus"
    "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Georgia" "Germany"
    "Greece" "Hungary" "Iceland" "Ireland" "Italy" "Kazakhstan"
    "Latvia" "Liechtenstein" "Lithuania" "Luxembourg" "Malta" "Moldova"
    "Monaco" "Montenegro" "Netherlands" "North Macedonia" "Norway"
    "Poland" "Portugal" "Romania" "Russian Federation" "San Marino" "Serbia"
    "Slovakia" "Slovenia" "Spain" "Sweden" "Switzerland" "Turkiye"
    "Ukraine" "United Kingdom" "Vatican City"
    "Gibraltar" "Faroe Islands" "Guernsey" "Isle of Man" "Azores" "Jersey"
    "Svalbard"}
set ::Regions::BLOCS(aa,Continental_Europe) {
    "Albania" "Andorra" "Austria" "Azores" "Belarus" "Belgium"
    "Bosnia and Herzegovina" "Bulgaria" "Croatia" "Czech Republic"
    "Denmark" "Estonia" "Faroe Islands" "Finland" "France" "Germany"
    "Gibraltar" "Greece" "Guernsey" "Hungary" "Iceland" "Ireland"
    "Isle of Man" "Italy" "Jersey" "Latvia" "Liechtenstein" "Lithuania"
    "Luxembourg" "Malta" "Moldova" "Monaco" "Montenegro" "Netherlands"
    "North Macedonia" "Norway" "Poland" "Portugal" "Romania" "San Marino"
    "Serbia" "Slovakia" "Slovenia" "Spain" "Svalbard" "Sweden"
    "Switzerland" "Ukraine" "United Kingdom" "Vatican City"}
set ::Regions::BLOCS(aa,Asia) {
    "Afghanistan" "Armenia" "Azerbaijan" "Bahrain" "Bangladesh"
    "Bhutan" "Brunei Darussalam" "Cambodia" "China" "Cyprus" "Georgia" "India"
    "Indonesia" "Iran" "Iraq" "Israel" "Japan" "Jordan" "Kazakhstan"
    "Kuwait" "Kyrgyzstan" "Laos" "Lebanon" "Malaysia" "Maldives"
    "Mongolia" "Myanmar" "Nepal" "North Korea" "Oman" "Pakistan"
    "Philippines" "Qatar" "Russian Federation" "Saudi Arabia"
    "Singapore" "South Korea" "Sri Lanka" "Syria"
    "Tajikistan" "Thailand" "Timor-Leste" "Turkiye" "Turkmenistan"
    "United Arab Emirates" "Uzbekistan" "Vietnam" "Yemen"
    "Palestinian Territory"}
set ::Regions::BLOCS(aa,Africa) {
    "Algeria" "Angola" "Benin" "Botswana" "Burkina Faso" "Burundi"
    "Cabo Verde" "Cameroon" "Central African Republic" "Chad"
    "Comoros" "Congo" "Congo DRC" "Côte d'Ivoire" "Djibouti" "Egypt"
    "Equatorial Guinea" "Eritrea" "Eswatini" "Ethiopia" "Gabon"
    "Gambia" "Ghana" "Guinea" "Guinea-Bissau" "Kenya" "Lesotho"
    "Liberia" "Libya" "Madagascar" "Malawi" "Mali" "Mauritania"
    "Mauritius" "Morocco" "Mozambique" "Namibia" "Niger" "Nigeria"
    "Rwanda" "Sao Tome and Principe" "Senegal" "Seychelles"
    "Sierra Leone" "Somalia" "South Africa" "South Sudan" "Sudan"
    "Tanzania" "Togo" "Tunisia" "Uganda" "Zambia" "Zimbabwe"}
set ::Regions::BLOCS(aa,North_America) {
    "Anguilla" "Antigua and Barbuda" "Aruba" "Bahamas" "Barbados"
    "Belize" "Bermuda" "Bonaire" "British Virgin Islands" "Canada"
    "Cayman Islands" "Costa Rica" "Cuba" "Curacao" "Dominica"
    "Dominican Republic" "El Salvador" "Greenland" "Grenada"
    "Guadeloupe" "Guatemala" "Haiti" "Honduras" "Jamaica" "Martinique"
    "Mexico" "Montserrat" "Nicaragua" "Panama" "Puerto Rico" "Saba"
    "Saint Barthelemy" "Saint Eustatius" "Saint Kitts and Nevis"
    "Saint Lucia" "Saint Martin" "Saint Pierre and Miquelon"
    "Saint Vincent and the Grenadines" "Sint Maarten"
    "Trinidad and Tobago" "Turks and Caicos Islands"
    "US Virgin Islands" "United States"}
set ::Regions::BLOCS(aa,South_America) {
    "Argentina" "Bolivia" "Brazil" "Chile" "Colombia" "Ecuador"
    "Falkland Islands" "French Guiana" "Guyana" "Paraguay" "Peru"
    "South Georgia and South Sandwich Islands" "Suriname" "Uruguay" "Venezuela"}
set ::Regions::BLOCS(aa,Oceania) {
    "American Samoa" "Australia" "Cook Islands" "Fiji"
    "French Polynesia" "Guam" "Kiribati" "Marshall Islands"
    "Micronesia" "Nauru" "New Caledonia" "New Zealand" "Niue"
    "Norfolk Island" "Northern Mariana Islands" "Palau"
    "Papua New Guinea" "Pitcairn" "Samoa" "Solomon Islands"
    "Tokelau" "Tonga" "Tuvalu" "Vanuatu" "Wallis and Futuna"}
set ::Regions::BLOCS(bb,Miscellany) {
    "Antarctica" "Bouvet Island" "British Indian Ocean Territory"
    "Canarias" "Christmas Island" "Cocos Islands" "French Southern Territories"
    "Glorioso Islands" "Heard Island and McDonald Islands" "Juan De Nova Island"
    "Madeira" "Mayotte" "Réunion" "Saint Helena" "United States Minor Outlying Islands"}
set ::Regions::BLOCS(cc,Western_Hemisphere,All_countries_in_or_partially_in@the_western_hemisphere) {
    "Algeria" "American Samoa" "Anguilla" "Antarctica" "Antigua and Barbuda" "Argentina"
    "Aruba" "Azores" "Bahamas" "Barbados" "Belize" "Bermuda" "Bolivia" "Bonaire" "Brazil"
    "British Virgin Islands" "Burkina Faso" "Cabo Verde" "Canada" "Canarias" "Cayman Islands"
    "Chile" "Colombia" "Cook Islands" "Costa Rica" "Côte d'Ivoire" "Cuba" "Curacao" "Dominica"
    "Dominican Republic" "Ecuador" "El Salvador" "Falkland Islands" "Faroe Islands" "Fiji"
    "France" "French Guiana" "French Polynesia" "Gambia" "Ghana" "Gibraltar" "Greenland"
    "Grenada" "Guadeloupe" "Guatemala" "Guernsey" "Guinea" "Guinea-Bissau" "Guyana" "Haiti"
    "Honduras" "Iceland" "Ireland" "Isle of Man" "Jamaica" "Jersey" "Kiribati" "Liberia"
    "Madeira" "Mali" "Martinique" "Mauritania" "Mexico" "Montserrat" "Morocco" "New Zealand"
    "Nicaragua" "Niue" "Panama" "Paraguay" "Peru" "Pitcairn" "Portugal" "Puerto Rico"
    "Russian Federation" "Saba" "Saint Barthelemy" "Saint Eustatius" "Saint Helena"
    "Saint Kitts and Nevis" "Saint Lucia" "Saint Martin" "Saint Pierre and Miquelon"
    "Saint Vincent and the Grenadines" "Samoa" "Senegal" "Sierra Leone" "Sint Maarten"
    "South Georgia and South Sandwich Islands" "Spain" "Suriname" "Svalbard" "Togo"
    "Tokelau" "Tonga" "Trinidad and Tobago" "Turks and Caicos Islands" "United Kingdom"
    "United States" "United States Minor Outlying Islands" "Uruguay" "US Virgin Islands"
    "Venezuela" "Wallis and Futuna"}
set ::Regions::BLOCS(cc,Eastern_Hemisphere,All_countries_in_or_partially_in@the_eastern_hemisphere) {
    "Afghanistan" "Albania" "Algeria" "Andorra" "Angola" "Antarctica" "Armenia" "Australia"
    "Austria" "Azerbaijan" "Bahrain" "Bangladesh" "Belarus" "Belgium" "Benin" "Bhutan"
    "Bosnia and Herzegovina" "Botswana" "Bouvet Island" "British Indian Ocean Territory"
    "Brunei Darussalam" "Bulgaria" "Burkina Faso" "Burundi" "Cambodia" "Cameroon"
    "Central African Republic" "Chad" "China" "Christmas Island" "Cocos Islands" "Comoros"
    "Congo" "Congo DRC" "Croatia" "Cyprus" "Czech Republic" "Denmark" "Djibouti" "Egypt"
    "Equatorial Guinea" "Eritrea" "Estonia" "Eswatini" "Ethiopia" "Fiji" "Finland" "France"
    "French Southern Territories" "Gabon" "Georgia" "Germany" "Ghana" "Glorioso Islands"
    "Greece" "Guam" "Heard Island and McDonald Islands" "Hungary" "India" "Indonesia" "Iran"
    "Iraq" "Israel" "Italy" "Japan" "Jordan" "Juan De Nova Island" "Kazakhstan" "Kenya"
    "Kiribati" "Kuwait" "Kyrgyzstan" "Laos" "Latvia" "Lebanon" "Lesotho" "Libya"
    "Liechtenstein" "Lithuania" "Luxembourg" "Madagascar" "Malawi" "Malaysia" "Maldives"
    "Mali" "Malta" "Marshall Islands" "Mauritius" "Mayotte" "Micronesia" "Moldova" "Monaco"
    "Mongolia" "Montenegro" "Mozambique" "Myanmar" "Namibia" "Nauru" "Nepal" "Netherlands"
    "New Caledonia" "New Zealand" "Niger" "Nigeria" "Norfolk Island" "North Korea"
    "North Macedonia" "Northern Mariana Islands" "Norway" "Oman" "Pakistan" "Palau"
    "Palestinian Territory" "Papua New Guinea" "Philippines" "Poland" "Qatar" "Réunion"
    "Romania" "Russian Federation" "Rwanda" "San Marino" "Sao Tome and Principe"
    "Saudi Arabia" "Serbia" "Seychelles" "Singapore" "Slovakia" "Slovenia" "Solomon Islands"
    "Somalia" "South Africa" "South Korea" "South Sudan" "Spain" "Sri Lanka" "Sudan"
    "Svalbard" "Sweden" "Switzerland" "Syria" "Tajikistan" "Tanzania" "Thailand"
    "Timor-Leste" "Togo" "Tunisia" "Turkiye" "Turkmenistan" "Tuvalu" "Uganda" "Ukraine"
    "United Arab Emirates" "United Kingdom" "United States"
    "United States Minor Outlying Islands" "Uzbekistan" "Vanuatu" "Vatican City" "Vietnam"
    "Yemen" "Zambia" "Zimbabwe"}
set ::Regions::BLOCS(cc,Northern_Hemisphere,All_countries_in_or_partially_in@the_northern_hemisphere) {
    "Afghanistan" "Albania" "Algeria" "Andorra" "Anguilla" "Antigua and Barbuda" "Armenia"
    "Aruba" "Austria" "Azerbaijan" "Azores" "Bahamas" "Bahrain" "Bangladesh" "Barbados"
    "Belarus" "Belgium" "Belize" "Benin" "Bermuda" "Bhutan" "Bonaire" "Bosnia and Herzegovina"
    "Brazil" "British Virgin Islands" "Brunei Darussalam" "Bulgaria" "Burkina Faso"
    "Cabo Verde" "Cambodia" "Cameroon" "Canada" "Canarias" "Cayman Islands"
    "Central African Republic" "Chad" "China" "Colombia" "Congo" "Congo DRC" "Costa Rica"
    "Côte d'Ivoire" "Croatia" "Cuba" "Curacao" "Cyprus" "Czech Republic" "Denmark" "Djibouti"
    "Dominica" "Dominican Republic" "Ecuador" "Egypt" "El Salvador" "Equatorial Guinea"
    "Eritrea" "Estonia" "Ethiopia" "Faroe Islands" "Finland" "France" "French Guiana"
    "Gabon" "Gambia" "Georgia" "Germany" "Ghana" "Gibraltar" "Greece" "Greenland" "Grenada"
    "Guadeloupe" "Guam" "Guatemala" "Guernsey" "Guinea" "Guinea-Bissau" "Guyana" "Haiti"
    "Honduras" "Hungary" "Iceland" "India" "Indonesia" "Iran" "Iraq" "Ireland" "Isle of Man"
    "Israel" "Italy" "Jamaica" "Japan" "Jersey" "Jordan" "Kazakhstan" "Kenya" "Kiribati"
    "Kuwait" "Kyrgyzstan" "Laos" "Latvia" "Lebanon" "Liberia" "Libya" "Liechtenstein"
    "Lithuania" "Luxembourg" "Madeira" "Malaysia" "Maldives" "Mali" "Malta" "Marshall Islands"
    "Martinique" "Mauritania" "Mexico" "Micronesia" "Moldova" "Monaco" "Mongolia" "Montenegro"
    "Montserrat" "Morocco" "Myanmar" "Nepal" "Netherlands" "Nicaragua" "Niger" "Nigeria"
    "North Korea" "North Macedonia" "Northern Mariana Islands" "Norway" "Oman" "Pakistan"
    "Palau" "Palestinian Territory" "Panama" "Philippines" "Poland" "Portugal" "Puerto Rico"
    "Qatar" "Romania" "Russian Federation" "Saba" "Saint Barthelemy" "Saint Eustatius"
    "Saint Kitts and Nevis" "Saint Lucia" "Saint Martin" "Saint Pierre and Miquelon"
    "Saint Vincent and the Grenadines" "San Marino" "Sao Tome and Principe" "Saudi Arabia"
    "Senegal" "Serbia" "Sierra Leone" "Singapore" "Sint Maarten" "Slovakia" "Slovenia"
    "Somalia" "South Korea" "South Sudan" "Spain" "Sri Lanka" "Sudan" "Suriname" "Svalbard"
    "Sweden" "Switzerland" "Syria" "Tajikistan" "Thailand" "Togo" "Trinidad and Tobago"
    "Tunisia" "Turkiye" "Turkmenistan" "Turks and Caicos Islands" "Uganda" "Ukraine"
    "United Arab Emirates" "United Kingdom" "United States"
    "United States Minor Outlying Islands" "US Virgin Islands" "Uzbekistan" "Vatican City"
    "Venezuela" "Vietnam" "Yemen"}
set ::Regions::BLOCS(cc,Southern_Hemisphere,All_countries_in_or_partially_in@the_southern_hemisphere) {
    "American Samoa" "Angola" "Antarctica" "Argentina" "Australia" "Bolivia" "Botswana"
    "Bouvet Island" "Brazil" "British Indian Ocean Territory" "Burundi" "Chile"
    "Christmas Island" "Cocos Islands" "Colombia" "Comoros" "Congo" "Congo DRC"
    "Cook Islands" "Ecuador" "Eswatini" "Falkland Islands" "Fiji" "French Polynesia"
    "French Southern Territories" "Gabon" "Glorioso Islands"
    "Heard Island and McDonald Islands" "Indonesia" "Juan De Nova Island" "Kenya"
    "Lesotho" "Madagascar" "Malawi" "Maldives" "Mauritius" "Mayotte" "Mozambique"
    "Namibia" "Nauru" "New Caledonia" "New Zealand" "Niue" "Norfolk Island" "Papua New Guinea"
    "Paraguay" "Peru" "Pitcairn" "Réunion" "Rwanda" "Saint Helena" "Samoa" "Seychelles"
    "Solomon Islands" "Somalia" "South Africa" "South Georgia and South Sandwich Islands"
    "Tanzania" "Timor-Leste" "Tokelau" "Tonga" "Tuvalu" "Uganda"
    "United States Minor Outlying Islands" "Uruguay" "Vanuatu" "Wallis and Futuna" "Zambia"
    "Zimbabwe"}

# California county regions
# https://census.ca.gov/regions/
set ::Regions::BLOCS(a0,Superior_California) {
    "Butte" "Colusa" "El Dorado" "Glenn" "Lassen" "Modoc" "Nevada" "Placer" "Plumas"
    "Sacramento" "Shasta" "Sierra" "Siskiyou" "Sutter" "Tehama" "Yolo" "Yuba"}
set ::Regions::BLOCS(a1,North_Coast) {"Del Norte" "Humboldt" "Lake" "Mendocino" "Napa" "Sonoma" "Trinity"}
set ::Regions::BLOCS(a2,Bay_Area) {
    "Alameda" "Contra Costa" "Marin" "San Francisco" "San Mateo" "Santa Clara" "Solano"}
set ::Regions::BLOCS(a3,North_San_Joaquin_Valley) {
    "Alpine" "Amador" "Calaveras" "Madera" "Mariposa" "Merced" "Mono" "San Joaquin"
    "Stanislaus" "Tuolumne"}
set ::Regions::BLOCS(a4,South_San_Joaquin_Valley) {"Fresno" "Inyo" "Kern" "Kings" "Tulare"}
set ::Regions::BLOCS(a5,Central_Coast) {
    "Monterey" "San Benito" "San Luis Obispo" "Santa Barbara" "Santa Cruz" "Ventura"}
set ::Regions::BLOCS(a6,Inland_Empire) {"Riverside" "San Bernardino"}
set ::Regions::BLOCS(a7,Los_Angeles) {"Los Angeles"}
set ::Regions::BLOCS(a8,Orange) {"Orange"}
set ::Regions::BLOCS(a9,San_Diego) {"Imperial" "San Diego"}


# UK Counties
# https://alphabeticalordering.com/united-kingdom/
# https://gis.stackexchange.com/questions/267775/uk-regional-shape-map-with-scotland-wales-and-northern-ireland
# https://borders.ukdataservice.ac.uk/easy_download.html
#
# PASSWORD: https://www.igismap.com/download-united-kingdom-administrative-boundary-shapefiles-countries-regions-counties-unitary-authorities-wards/
# PASSWORD: https://story.mapog.com/app/gisdata/united%20kingdom/United%20Kingdom%20Country%20Boundary

set ::Regions::BLOCS(uk0,England) {
    "Bedfordshire" "Berkshire" "Bristol" "Buckinghamshire" "Cambridgeshire" "Cheshire" "Cornwall" "Cumbria" "Derbyshire" "Devon" "Dorset" "Durham" "East Riding of Yorkshire" "East Sussex" "Essex" "Gloucestershire" "Greater London" "Greater Manchester" "Hampshire" "Herefordshire" "Hertfordshire" "Isle of Wight" "Kent" "Lancashire" "Leicestershire" "Lincolnshire" "Merseyside" "Middlesex" "Norfolk" "North Yorkshire" "Northamptonshire" "Northumberland" "Nottinghamshire" "Oxfordshire" "Rutland" "Shropshire" "Somerset" "South Yorkshire" "Staffordshire" "Suffolk" "Surrey" "Tyne and Wear" "Warwickshire" "West Midlands" "West Sussex" "West Yorkshire" "Wiltshire" "Worcestershire"}
set ::Regions::BLOCS(uk0,Northern_Ireland) {
    "Antrim" "Armagh" "Down" "Fermanagh" "Londonderry" "Tyrone"}
set ::Regions::BLOCS(uk0,Scotland) {
    "Aberdeen City" "Aberdeenshire" "Angus" "Argyll and Bute" "Clackmannanshire" "Dumfries and Galloway" "Dundee" "East Ayrshire" "East Dunbartonshire" "East Lothian" "East Renfrewshire" "Edinburgh" "Falkirk" "Fife" "Glasgow" "Highland" "Inverclyde" "Midlothian" "Moray" "North Ayrshire" "North Lanarkshire" "Orkney" "Perth and Kinross" "Renfrewshire" "Scottish Borders" "Shetland Isles" "South Ayrshire" "South Lanarkshire" "Stirlingshire" "West Dunbartonshire" "West Lothian" "Western Isles"}
set ::Regions::BLOCS(uk0,Wales) {
    "Anglesey" "Blaenau Gwent" "Bridgend" "Caerphilly" "Cardiff" "Carmarthenshire"
    "Ceredigion" "Conwy" "Denbighshire" "Flintshire" "Glamorgan" "Gwynedd" "Merthyr Tydfil"
    "Monmouthshire" "Neath Port Talbot" "Newport" "Newport City" "Pembrokeshire" "Powys"
    "Rhondda Cynon Taff" "Swansea" "Torfaen" "Wrexham"
}
set ::Regions::BLOCS(uk0,United_Kingdom) {
    "Aberdeen City" "Aberdeenshire" "Anglesey" "Angus"
    "Argyll and Bute" "Bedfordshire" "Berkshire" "Blaenau Gwent" "Bridgend"
    "Bristol" "Buckinghamshire" "Caerphilly" "Cambridgeshire"
    "Cardiff" "Carmarthenshire" "Ceredigion" "Cheshire"
    "Clackmannanshire" "Conwy" "Cornwall" "Antrim"
    "Armagh" "Down" "Fermanagh" "Londonderry"
    "Tyrone" "Cumbria" "Denbighshire" "Derbyshire" "Devon"
    "Dorset" "Dumfries and Galloway" "Dundee" "Durham" "East Ayrshire"
    "East Dunbartonshire" "East Lothian" "East Renfrewshire"
    "East Riding of Yorkshire" "East Sussex" "Edinburgh" "Essex" "Falkirk"
    "Fife" "Flintshire" "Glamorgan" "Glasgow" "Gloucestershire"
    "Greater London" "Greater Manchester" "Gwynedd" "Hampshire"
    "Herefordshire" "Hertfordshire" "Highland" "Inverclyde"
    "Isle of Wight" "Kent" "Lancashire" "Leicestershire" "Lincolnshire"
    "Merseyside" "Merthyr Tydfil" "Middlesex" "Midlothian"
    "Monmouthshire" "Moray" "Neath Port Talbot" "Newport"
    "Newport City" "Norfolk" "North Ayrshire" "North Lanarkshire"
    "North Yorkshire" "Northamptonshire" "Northumberland" "Nottinghamshire"
    "Orkney" "Oxfordshire" "Pembrokeshire" "Perth and Kinross" "Powys"
    "Renfrewshire" "Rhondda Cynon Taff" "Rutland" "Scottish Borders"
    "Shetland Isles" "Shropshire" "Somerset" "South Ayrshire"
    "South Lanarkshire" "South Yorkshire" "Staffordshire" "Stirlingshire"
    "Suffolk" "Surrey" "Swansea" "Torfaen" "Tyne and Wear"
    "Warwickshire" "West Dunbartonshire" "West Lothian"
    "West Midlands" "West Sussex" "West Yorkshire" "Western Isles"
    "Wiltshire" "Worcestershire" "Wrexham"}

set SHAPE_ENGLISH_COUNTIES {
    "Aberdeenshire" "Anglesey" "Angus" "Antrim" "Argyllshire" "Armagh"
    "Ayrshire" "Banffshire" "Bedfordshire" "Berkshire" "Berwickshire"
    "Brecknockshire" "Buckinghamshire" "Buteshire" "Caernarfonshire"
    "Caithness" "Cambridgeshire" "Cardiganshire" "Carmarthenshire"
    "Cheshire" "Clackmannanshire" "Cornwall" "Cromartyshire"
    "Cumberland" "Denbighshire" "Derbyshire" "Devon" "Dorset" "Down"
    "Dumfriesshire" "Dunbartonshire" "Durham" "East Lothian" "Essex"
    "Fermanagh" "Fife" "Flintshire" "Glamorgan" "Gloucestershire"
    "Hampshire" "Herefordshire" "Hertfordshire" "Huntingdonshire"
    "Inverness-shire" "Kent" "Kincardineshire" "Kinross-shire"
    "Kirkcudbrightshire" "Lanarkshire" "Lancashire" "Leicestershire"
    "Lincolnshire" "Londonderry" "Merionethshire" "Middlesex"
    "Midlothian" "Monmouthshire" "Montgomeryshire" "Morayshire"
    "Nairnshire" "Norfolk" "Northamptonshire" "Northumberland"
    "Nottinghamshire" "Orkney" "Oxfordshire" "Peeblesshire"
    "Pembrokeshire" "Perthshire" "Radnorshire" "Renfrewshire"
    "Ross-shire" "Roxburghshire" "Rutland" "Selkirkshire" "Shetland"
    "Shropshire" "Somerset" "Staffordshire" "Stirlingshire" "Suffolk"
    "Surrey" "Sussex" "Sutherland" "Tyrone" "Warwickshire"
    "West Lothian" "Westmorland" "Wigtownshire" "Wiltshire" "Worcestershire"
    "Yorkshire" }


proc 3Set {list1 list2} {
    set only1 {}
    set only2 {}
    set both {}
    foreach item1 $list1 {
        if {$item1 in $list2} {
            lappend both $item1
        } else {
            lappend only1 $item1
        }
    }
    foreach item2 $list2 {
        if {$item2 ni $list1} {
            lappend only2 $item2
        }
    }
    return [list $only1 $only2 $both]
}
