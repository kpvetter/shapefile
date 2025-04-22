#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# coloring.tcl -- Using hard-coded neighboring data, insuring adjacent shapes have different colors
# by Keith Vetter 2025-04-20
#
# English counties
# https://geoportal.statistics.gov.uk/datasets/3aeb4ae1c88848e9b4f57749e68d185d_0/explore?location=52.611195%2C-2.491568%2C6.25
# https://statistics.ukdataservice.ac.uk/dataset/2011-census-geography-boundaries-counties
# https://simplemaps.com/gis/country/gb#all
package require cksum

namespace eval ::Coloring {
    variable BORDERS
    variable COLORS [list lightyellow cyan orange green pink sienna1 yellow red blue springgreen]
}

proc ::Coloring::CreateColoringScheme {nameList {nonce ""}} {
    # Returns dictionary with keys being entries from the nameList and values being a color
    variable BORDERS
    variable COLORS

    set coloringScheme [dict create]
    foreach name $nameList {
        set color ""
        if { [info exists BORDERS($name)]} {
            set exclude [lmap n $BORDERS($name) {
                if {! [dict exists $coloringScheme $n]} continue
                dict get $coloringScheme $n
            }]
            set available [lmap c $COLORS { if {$c in $exclude} continue; set c }]
            set color [::Coloring::RandomColor $available "$name $nonce"]
        }
        if {$color eq ""} {
            set color [::Coloring::RandomColor $COLORS "$name $nonce"]
        }
        dict set coloringScheme $name $color
    }
    return $coloringScheme
}
proc ::Coloring::RandomColor {colors nonce} {
    # Pick a pseudo-random color from a list of colors
    if {$colors eq {}} { return "" }
    set clrIndex [expr {[::crc::cksum $nonce] % [llength $colors]}]
    set color [lindex $colors $clrIndex]
    return $color
}

################################################################
# Data about which state/country abuts other states/countries
#
# NB. Georgia is weird in that it's both a state and country

# World countries
# https://github.com/geodatasource/country-borders
array set ::Coloring::BORDERS {
    "Afghanistan" {"China" "Iran" "Pakistan" "Tajikistan" "Turkmenistan" "Uzbekistan" }
    "Albania" {"Greece" "Montenegro" "North Macedonia" "Serbia" }
    "Algeria" {"Libya" "Mali" "Mauritania" "Morocco" "Niger" "Tunisia" "Western Sahara" }
    "Andorra" {"France" "Spain" }
    "Angola" {"Congo" "Congo DRC" "Namibia" "Zambia" }
    "Argentina" {"Bolivia" "Brazil" "Chile" "Paraguay" "Uruguay" }
    "Armenia" {"Azerbaijan" "Georgia" "Iran" "Turkiye" }
    "Austria" {"Czech Republic" "Germany" "Hungary" "Italy" "Liechtenstein" "Slovakia" "Slovenia" "Switzerland" }
    "Azerbaijan" {"Armenia" "Georgia" "Iran" "Russian Federation" "Turkiye" }
    "Bangladesh" {"India" "Myanmar" }
    "Belarus" {"Latvia" "Lithuania" "Poland" "Russian Federation" "Ukraine" }
    "Belgium" {"France" "Germany" "Luxembourg" "Netherlands" }
    "Belize" {"Guatemala" "Mexico" }
    "Benin" {"Burkina Faso" "Niger" "Nigeria" "Togo" }
    "Bhutan" {"China" "India" }
    "Bolivia" {"Argentina" "Brazil" "Chile" "Paraguay" "Peru" }
    "Bosnia and Herzegovina" {"Croatia" "Montenegro" "Serbia" }
    "Botswana" {"Namibia" "South Africa" "Zambia" "Zimbabwe" }
    "Brazil" {"Argentina" "Bolivia" "Colombia" "French Guiana" "Guyana" "Paraguay" "Peru" "Suriname" "Uruguay" "Venezuela" }
    "Brunei Darussalam" {"Malaysia" }
    "Bulgaria" {"Greece" "North Macedonia" "Romania" "Serbia" "Turkiye" }
    "Burkina Faso" {"Benin" "Côte d'Ivoire" "Ghana" "Mali" "Niger" "Togo" }
    "Burundi" {"Congo DRC" "Rwanda" "Tanzania" }
    "Cambodia" {"Laos" "Thailand" "Vietnam" }
    "Cameroon" {"Central African Republic" "Chad" "Congo" "Equatorial Guinea" "Gabon" "Nigeria" }
    "Canada" {"United States" }
    "Central African Republic" {"Cameroon" "Chad" "Congo" "Congo DRC" "South Sudan" "Sudan" }
    "Chad" {"Cameroon" "Central African Republic" "Libya" "Niger" "Nigeria" "Sudan" }
    "Chile" {"Argentina" "Bolivia" "Peru" }
    "China" {"Afghanistan" "Bhutan" "Hong Kong" "India" "Kazakhstan" "North Korea" "Kyrgyzstan" "Laos" "Macao" "Mongolia" "Myanmar" "Nepal" "Pakistan" "Russian Federation" "Tajikistan" "Vietnam" }
    "Colombia" {"Brazil" "Ecuador" "Panama" "Peru" "Venezuela" }
    "Congo" {"Angola" "Cameroon" "Central African Republic" "Congo DRC" "Gabon" }
    "Congo DRC" {"Angola" "Burundi" "Central African Republic" "Congo" "Rwanda" "South Sudan" "Tanzania" "Uganda" "Zambia"}
    "Costa Rica" {"Nicaragua" "Panama" }
    "Côte d'Ivoire" {"Burkina Faso" "Ghana" "Guinea" "Liberia" "Mali" }
    "Croatia" {"Bosnia and Herzegovina" "Hungary" "Montenegro" "Serbia" "Slovenia" }
    "Czech Republic" {"Austria" "Germany" "Poland" "Slovakia" }
    "Denmark" {"Germany" }
    "Djibouti" {"Eritrea" "Ethiopia" "Somalia" }
    "Dominican Republic" {"Haiti" }
    "Ecuador" {"Colombia" "Peru" }
    "Egypt" {"Israel" "Libya" "Palestinian Territory" "Sudan" }
    "El Salvador" {"Guatemala" "Honduras" }
    "Equatorial Guinea" {"Cameroon" "Gabon" }
    "Eritrea" {"Djibouti" "Ethiopia" "Sudan" }
    "Estonia" {"Latvia" "Russian Federation" }
    "Eswatini" {"Mozambique" "South Africa" }
    "Ethiopia" {"Djibouti" "Eritrea" "Kenya" "Somalia" "South Sudan" "Sudan" }
    "Finland" {"Norway" "Russian Federation" "Sweden" }
    "France" {"Andorra" "Belgium" "Germany" "Italy" "Luxembourg" "Monaco" "Spain" "Switzerland" }
    "French Guiana" {"Brazil" "Suriname" }
    "Gabon" {"Cameroon" "Congo" "Equatorial Guinea" }
    "Gambia" {"Senegal" }
    "Georgia" {"Armenia" "Azerbaijan" "Russian Federation" "Turkiye" }
    "Germany" {"Austria" "Belgium" "Czech Republic" "Denmark" "France" "Luxembourg" "Netherlands" "Poland" "Switzerland" }
    "Ghana" {"Burkina Faso" "Côte d'Ivoire" "Togo" }
    "Gibraltar" {"Spain" }
    "Greece" {"Albania" "Bulgaria" "North Macedonia" "Turkiye" }
    "Guatemala" {"Belize" "El Salvador" "Honduras" "Mexico" }
    "Guinea" {"Côte d'Ivoire" "Guinea-Bissau" "Liberia" "Mali" "Senegal" "Sierra Leone" }
    "Guinea-Bissau" {"Guinea" "Senegal" }
    "Guyana" {"Brazil" "Suriname" "Venezuela" }
    "Haiti" {"Dominican Republic" }
    "Holy See" {"Italy" }
    "Honduras" {"El Salvador" "Guatemala" "Nicaragua" }
    "Hong Kong" {"China" }
    "Hungary" {"Austria" "Croatia" "Romania" "Serbia" "Slovakia" "Slovenia" "Ukraine" }
    "India" {"Bangladesh" "Bhutan" "China" "Myanmar" "Nepal" "Pakistan" }
    "Indonesia" {"Malaysia" "Papua New Guinea" "Timor-Leste" }
    "Iran" {"Afghanistan" "Armenia" "Azerbaijan" "Iraq" "Pakistan" "Turkiye" "Turkmenistan" }
    "Iraq" {"Iran" "Jordan" "Kuwait" "Saudi Arabia" "Syria" "Turkiye" }
    "Ireland" {"United Kingdom" }
    "Israel" {"Egypt" "Jordan" "Lebanon" "Palestinian Territory" "Syria" }
    "Italy" {"Austria" "France" "Holy See" "San Marino" "Slovenia" "Switzerland" "Vatican City"}
    "Jordan" {"Iraq" "Israel" "Palestinian Territory" "Saudi Arabia" "Syria" }
    "Kazakhstan" {"China" "Kyrgyzstan" "Russian Federation" "Turkmenistan" "Uzbekistan" }
    "Kenya" {"Ethiopia" "Somalia" "South Sudan" "Tanzania" "Uganda" }
    "North Korea" {"China" "South Korea" "Russian Federation" }
    "South Korea" {"North Korea" }
    "Kuwait" {"Iraq" "Saudi Arabia" }
    "Kyrgyzstan" {"China" "Kazakhstan" "Tajikistan" "Uzbekistan" }
    "Laos" {"Cambodia" "China" "Myanmar" "Thailand" "Vietnam" }
    "Latvia" {"Belarus" "Estonia" "Lithuania" "Russian Federation" }
    "Lebanon" {"Israel" "Syria" }
    "Lesotho" {"South Africa" }
    "Liberia" {"Côte d'Ivoire" "Guinea" "Sierra Leone" }
    "Libya" {"Algeria" "Chad" "Egypt" "Niger" "Sudan" "Tunisia" }
    "Liechtenstein" {"Austria" "Switzerland" }
    "Lithuania" {"Belarus" "Latvia" "Poland" "Russian Federation" }
    "Luxembourg" {"Belgium" "France" "Germany" }
    "Macao" {"China" }
    "Malawi" {"Mozambique" "Tanzania" "Zambia" }
    "Malaysia" {"Brunei Darussalam" "Indonesia" "Singapore" "Thailand" }
    "Mali" {"Algeria" "Burkina Faso" "Côte d'Ivoire" "Guinea" "Mauritania" "Niger" "Senegal" }
    "Mauritania" {"Algeria" "Mali" "Senegal" "Western Sahara" }
    "Mexico" {"Belize" "Guatemala" "United States" }
    "Moldova" {"Romania" "Ukraine" }
    "Monaco" {"France" }
    "Mongolia" {"China" "Russian Federation" }
    "Montenegro" {"Albania" "Bosnia and Herzegovina" "Croatia" "Serbia" }
    "Morocco" {"Algeria" "Spain" "Western Sahara" }
    "Mozambique" {"Eswatini" "Malawi" "South Africa" "Tanzania" "Zambia" "Zimbabwe" }
    "Myanmar" {"Bangladesh" "China" "India" "Laos" "Thailand" }
    "Namibia" {"Angola" "Botswana" "South Africa" "Zambia" }
    "Nepal" {"China" "India" }
    "Netherlands" {"Belgium" "Germany" }
    "Nicaragua" {"Costa Rica" "Honduras" }
    "Niger" {"Algeria" "Benin" "Burkina Faso" "Chad" "Libya" "Mali" "Nigeria" }
    "Nigeria" {"Benin" "Cameroon" "Chad" "Niger" }
    "North Macedonia" {"Albania" "Bulgaria" "Greece" "Serbia" }
    "Norway" {"Finland" "Russian Federation" "Sweden" }
    "Oman" {"Saudi Arabia" "United Arab Emirates" "Yemen" }
    "Pakistan" {"Afghanistan" "China" "India" "Iran" }
    "Palestinian Territory" {"Egypt" "Israel" "Jordan"}
    "Panama" {"Colombia" "Costa Rica" }
    "Papua New Guinea" {"Indonesia" }
    "Paraguay" {"Argentina" "Bolivia" "Brazil" }
    "Peru" {"Bolivia" "Brazil" "Chile" "Colombia" "Ecuador" }
    "Poland" {"Belarus" "Czech Republic" "Germany" "Lithuania" "Russian Federation" "Slovakia" "Ukraine" }
    "Portugal" {"Spain" }
    "Qatar" {"Saudi Arabia" }
    "Romania" {"Bulgaria" "Hungary" "Moldova" "Serbia" "Ukraine" }
    "Russian Federation" {"Azerbaijan" "Belarus" "China" "Estonia" "Finland" "Georgia" "Kazakhstan" "Korea" "Latvia" "Lithuania" "Mongolia" "Norway" "Poland" "Ukraine" }
    "Rwanda" {"Burundi" "Congo DRC" "Tanzania" "Uganda" }
    "Saint Martin" {"Sint Maarten" }
    "San Marino" {"Italy" }
    "Saudi Arabia" {"Iraq" "Jordan" "Kuwait" "Oman" "Qatar" "United Arab Emirates" "Yemen" }
    "Senegal" {"Gambia" "Guinea" "Guinea-Bissau" "Mali" "Mauritania" }
    "Serbia" {"Albania" "Bosnia and Herzegovina" "Bulgaria" "Croatia" "Hungary" "Montenegro" "North Macedonia" "Romania" }
    "Sierra Leone" {"Guinea" "Liberia" }
    "Singapore" {"Malaysia"}
    "Sint Maarten" {"Saint Martin" }
    "Slovakia" {"Austria" "Czech Republic" "Hungary" "Poland" "Ukraine" }
    "Slovenia" {"Austria" "Croatia" "Hungary" "Italy" }
    "Somalia" {"Djibouti" "Ethiopia" "Kenya" }
    "South Africa" {"Botswana" "Eswatini" "Lesotho" "Mozambique" "Namibia" "Zimbabwe" }
    "South Sudan" {"Central African Republic" "Congo DRC" "Ethiopia" "Kenya" "Sudan" "Uganda" }
    "Spain" {"Andorra" "France" "Gibraltar" "Morocco" "Portugal" }
    "Sudan" {"Central African Republic" "Chad" "Egypt" "Eritrea" "Ethiopia" "Libya" "South Sudan" }
    "Suriname" {"Brazil" "French Guiana" "Guyana" }
    "Sweden" {"Finland" "Norway" }
    "Switzerland" {"Austria" "France" "Germany" "Italy" "Liechtenstein" }
    "Syria" {"Iraq" "Israel" "Jordan" "Lebanon" "Turkiye" }
    "Tajikistan" {"Afghanistan" "China" "Kyrgyzstan" "Uzbekistan" }
    "Tanzania" {"Burundi" "Congo DRC" "Kenya" "Malawi" "Mozambique" "Rwanda" "Uganda" "Zambia" }
    "Thailand" {"Cambodia" "Laos" "Malaysia" "Myanmar" }
    "Timor-Leste" {"Indonesia" }
    "Togo" {"Benin" "Burkina Faso" "Ghana" }
    "Tunisia" {"Algeria" "Libya" }
    "Turkiye" {"Armenia" "Azerbaijan" "Bulgaria" "Georgia" "Greece" "Iran" "Iraq" "Syria" }
    "Turkmenistan" {"Afghanistan" "Iran" "Kazakhstan" "Uzbekistan" }
    "Uganda" {"Congo DRC" "Kenya" "Rwanda" "South Sudan" "Tanzania" }
    "Ukraine" {"Belarus" "Hungary" "Moldova" "Poland" "Romania" "Russian Federation" "Slovakia" }
    "United Arab Emirates" {"Oman" "Saudi Arabia" }
    "United Kingdom" {"Ireland" }
    "United States" {"Canada" "Mexico" }
    "Uruguay" {"Argentina" "Brazil" }
    "Uzbekistan" {"Afghanistan" "Kazakhstan" "Kyrgyzstan" "Tajikistan" "Turkmenistan" }
    "Vatican City" {"Italy"}
    "Venezuela" {"Brazil" "Colombia" "Guyana" }
    "Vietnam" {"Cambodia" "China" "Laos" }
    "Western Sahara" {"Algeria" "Mauritania" "Morocco" }
    "Yemen" {"Oman" "Saudi Arabia" }
    "Zambia" {"Angola" "Botswana" "Congo DRC" "Malawi" "Mozambique" "Namibia" "Tanzania" "Zimbabwe" }
    "Zimbabwe" {"Botswana" "Mozambique" "South Africa" "Zambia" }
}
# USA States
array set ::Coloring::BORDERS {
    "Alabama" {"Florida" "Georgia" "Mississippi" "Tennessee" }
    "Alaska" {}
    "Arizona" {"California" "Colorado" "Nevada" "New Mexico" "Utah" }
    "Arkansas" {"Louisiana" "Mississippi" "Missouri" "Oklahoma" "Tennessee" "Texas" }
    "California" {"Arizona" "Nevada" "Oregon" }
    "Colorado" {"Arizona" "Kansas" "Nebraska" "New Mexico" "Oklahoma" "Utah" "Wyoming" }
    "Connecticut" {"Massachusetts" "New York" "Rhode Island" }
    "Delaware" {"Maryland" "New Jersey" "Pennsylvania" }
    "District of Columbia" {"Maryland" "Virginia" }
    "Florida" {"Alabama" "Georgia" }
    "Georgia" {"Alabama" "Florida" "North Carolina" "South Carolina" "Tennessee" }
    "Hawaii" {}
    "Idaho" {"Montana" "Nevada" "Oregon" "Utah" "Washington" "Wyoming" }
    "Illinois" {"Indiana" "Iowa" "Kentucky" "Missouri" "Wisconsin" }
    "Indiana" {"Illinois" "Kentucky" "Michigan" "Ohio" }
    "Iowa" {"Illinois" "Minnesota" "Missouri" "Nebraska" "South Dakota" "Wisconsin" }
    "Kansas" {"Colorado" "Missouri" "Nebraska" "Oklahoma" }
    "Kentucky" {"Illinois" "Indiana" "Missouri" "Ohio" "Tennessee" "Virginia" "West Virginia" }
    "Louisiana" {"Arkansas" "Mississippi" "Texas" }
    "Maine" {"New Hampshire" }
    "Maryland" {"Delaware" "Pennsylvania" "Virginia" "West Virginia" }
    "Massachusetts" {"Connecticut" "New Hampshire" "New York" "Rhode Island" "Vermont" }
    "Michigan" {"Illinois" "Indiana" "Ohio" "Wisconsin" }
    "Minnesota" {"Iowa" "North Dakota" "South Dakota" "Wisconsin" }
    "Mississippi" {"Alabama" "Arkansas" "Louisiana" "Tennessee" }
    "Missouri" {"Arkansas" "Illinois" "Iowa" "Kansas" "Kentucky" "Nebraska" "Oklahoma" "Tennessee" }
    "Montana" {"Idaho" "North Dakota" "South Dakota" "Wyoming" }
    "Nebraska" {"Colorado" "Iowa" "Kansas" "Missouri" "South Dakota" "Wyoming" }
    "Nevada" {"Arizona" "California" "Idaho" "Oregon" "Utah" }
    "New Hampshire" {"Maine" "Massachusetts" "Vermont" }
    "New Jersey" {"Delaware" "New York" "Pennsylvania" }
    "New Mexico" {"Arizona" "Colorado" "Oklahoma" "Texas" "Utah" }
    "New York" {"Connecticut" "Massachusetts" "New Jersey" "Pennsylvania" "Vermont" }
    "North Carolina" {"Georgia" "South Carolina" "Tennessee" "Virginia" }
    "North Dakota" {"Minnesota" "Montana" "South Dakota" }
    "Ohio" {"Indiana" "Kentucky" "Michigan" "Pennsylvania" "West Virginia" }
    "Oklahoma" {"Arkansas" "Colorado" "Kansas" "Missouri" "New Mexico" "Texas" }
    "Oregon" {"California" "Idaho" "Nevada" "Washington" }
    "Pennsylvania" {"Delaware" "Maryland" "New Jersey" "New York" "Ohio" "West Virginia" }
    "Rhode Island" {"Connecticut" "Massachusetts" }
    "South Carolina" {"Georgia" "North Carolina" }
    "South Dakota" {"Iowa" "Minnesota" "Montana" "Nebraska" "North Dakota" "Wyoming" }
    "Tennessee" {"Alabama" "Arkansas" "Georgia" "Kentucky" "Mississippi" "Missouri" "North Carolina" "Virginia" }
    "Texas" {"Arkansas" "Louisiana" "New Mexico" "Oklahoma" }
    "Utah" {"Arizona" "Colorado" "Idaho" "Nevada" "New Mexico" "Wyoming" }
    "Vermont" {"Massachusetts" "New Hampshire" "New York" }
    "Virginia" {"Kentucky" "Maryland" "North Carolina" "Tennessee" "West Virginia" }
    "Washington" {"Idaho" "Oregon" }
    "West Virginia" {"Kentucky" "Maryland" "Ohio" "Pennsylvania" "Virginia" }
    "Wisconsin" {"Illinois" "Iowa" "Michigan" "Minnesota" }
    "Wyoming" {"Colorado" "Idaho" "Montana" "Nebraska" "South Dakota" "Utah" }
}
# California counties
array set ::Coloring::BORDERS {
    "Alameda" {"Contra Costa" "San Francisco" "San Joaquin" "San Mateo" "Santa Clara" "Stanislaus"}
    "Alpine" {"Amador" "Calaveras" "El Dorado" "Mono" "Tuolumne"}
    "Amador" {"Alpine" "Calaveras" "El Dorado" "Sacramento" "San Joaquin"}
    "Butte" {"Colusa" "Glenn" "Plumas" "Sutter" "Tehama" "Yuba"}
    "Calaveras" {"Alpine" "Amador" "San Joaquin" "Stanislaus" "Tuolumne"}
    "Colusa" {"Butte" "Glenn" "Lake" "Sutter" "Yolo"}
    "Contra Costa" {"Alameda" "Marin" "Sacramento" "San Francisco" "San Joaquin" "Solano" "Sonoma"}
    "Del Norte" {"Humboldt" "Siskiyou"}
    "El Dorado" {"Alpine" "Amador" "Placer" "Sacramento"}
    "Fresno" {"Inyo" "Kings" "Madera" "Merced" "Mono" "Monterey" "San Benito" "Tulare"}
    "Glenn" {"Butte" "Colusa" "Lake" "Mendocino" "Tehama"}
    "Humboldt" {"Del Norte" "Mendocino" "Siskiyou" "Trinity"}
    "Imperial" {"Riverside" g"San Diego"}
    "Inyo" {"Fresno" "Kern" "Mono" "San Bernardino" "Tulare"}
    "Kern" {"Inyo" "Kings" "Los Angeles" "San Bernardino" "San Luis Obispo" "Santa Barbara" "Tulare" "Ventura"}
    "Kings" {"Fresno" "Kern" "Monterey" "San Luis Obispo" "Tulare"}
    "Lake" {"Colusa" "Glenn" "Mendocino" "Napa" "Sonoma" "Yolo"}
    "Lassen" {"Modoc" "Plumas" "Shasta" "Sierra"}
    "Los Angeles" {"Kern" "Orange" "San Bernardino" "Ventura"}
    "Madera" {"Fresno" "Mariposa" "Merced" "Mono" "Tuolumne"}
    "Marin" {"Contra Costa" "San Francisco" "Solano" "Sonoma"}
    "Mariposa" {"Madera" "Merced" "Stanislaus" "Tuolumne"}
    "Mendocino" {"Glenn" "Humboldt" "Lake" "Sonoma" "Tehama" "Trinity"}
    "Merced" {"Fresno" "Madera" "Mariposa" "San Benito" "Santa Clara" "Stanislaus"}
    "Modoc" {"Lassen" "Shasta" "Siskiyou"}
    "Mono" {"Alpine" "Fresno" "Inyo" "Madera" "Tuolumne"}
    "Monterey" {"Fresno" "Kings" "San Benito" "San Luis Obispo" "Santa Cruz"}
    "Napa" {"Lake" "Solano" "Sonoma" "Yolo"}
    "Nevada" {"Placer" "Sierra" "Yuba"}
    "Orange" {"Los Angeles" "Riverside" "San Bernardino" "San Diego"}
    "Placer" {"El Dorado" "Nevada" "Sacramento" "Sutter" "Yuba"}
    "Plumas" {"Butte" "Lassen" "Shasta" "Sierra" "Tehama" "Yuba"}
    "Riverside" {"Imperial" "Orange" "San Bernardino" "San Diego"}
    "Sacramento" {"Amador" "Contra Costa" "El Dorado" "Placer" "San Joaquin" "Solano" "Sutter" "Yolo"}
    "San Benito" {"Fresno" "Merced" "Monterey" "Santa Clara" "Santa Cruz"}
    "San Bernardino" {"Inyo" "Kern" "Los Angeles" "Orange" "Riverside"}
    "San Diego" {"Imperial" "Orange" "Riverside"}
    "San Francisco" {"Alameda" "Contra Costa" "Marin" "San Mateo"}
    "San Joaquin" {"Alameda" "Amador" "Calaveras" "Contra Costa" "Sacramento" "Stanislaus"}
    "San Luis Obispo" {"Kern" "Kings" "Monterey" "Santa Barbara"}
    "San Mateo" {"Alameda" "San Francisco" "Santa Clara" "Santa Cruz"}
    "Santa Barbara" {"Kern" "San Luis Obispo" "Ventura"}
    "Santa Clara" {"Alameda" "Merced" "San Benito" "San Mateo" "Santa Cruz" "Stanislaus" "Monterey" "San Benito" "San Mateo" "Santa Clara"}
    "Shasta" {"Lassen" "Modoc" "Plumas" "Siskiyou" "Tehama" "Trinity"}
    "Sierra" {"Lassen" "Nevada" "Plumas" "Yuba"}
    "Siskiyou" {"Del Norte" "Humboldt" "Modoc" "Shasta" "Trinity"}
    "Solano" {"Contra Costa" "Marin" "Napa" "Sacramento" "Sonoma" "Yolo"}
    "Sonoma" {"Contra Costa" "Lake" "Marin" "Mendocino" "Napa" "Solano"}
    "Stanislaus" {"Alameda" "Calaveras" "Mariposa" "Merced" "San Joaquin" "Santa Clara" "Tuolumne"}
    "Sutter" {"Butte" "Colusa" "Placer" "Sacramento" "Yolo" "Yuba"}
    "Tehama" {"Butte" "Glenn" "Mendocino" "Plumas" "Shasta" "Trinity"}
    "Trinity" {"Humboldt" "Mendocino" "Shasta" "Siskiyou" "Tehama"}
    "Tulare" {"Fresno" "Inyo" "Kern" "Kings"}
    "Tuolumne" {"Alpine" "Calaveras" "Madera" "Mariposa" "Mono" "Stanislaus"}
    "Ventura" {"Kern" "Los Angeles" "Santa Barbara"}
    "Yolo" {"Colusa" "Lake" "Napa" "Sacramento" "Solano" "Sutter"}
    "Yuba" {"Butte" "Nevada" "Placer" "Plumas" "Sierra" "Sutter"}
}
# Michigan Counties
# https://data-ecgis.opendata.arcgis.com/datasets/444c7933651845438204be5a6f163547/about
array set ::Coloring::BORDERS {
    "Alcona" {"Alpena" "Iosco" "Ogemaw" "Oscoda" }
    "Alger" {"Delta" "Keweenaw" "Luce" "Marquette" "Schoolcraft" }
    "Allegan" {"Barry" "Kalamazoo" "Kent" "Ottawa" "Van Buren" }
    "Alpena" {"Alcona" "Montmorency" "Oscoda" "Presque Isle" }
    "Antrim" {"Charlevoix" "Crawford" "Grand Traverse" "Kalkaska" "Leelanau" "Otsego" }
    "Arenac" {"Bay" "Gladwin" "Huron" "Iosco" "Ogemaw" }
    "Baraga" {"Houghton" "Iron" "Marquette" }
    "Barry" {"Allegan" "Calhoun" "Eaton" "Ionia" "Kalamazoo" "Kent" }
    "Bay" {"Arenac" "Gladwin" "Huron" "Midland" "Saginaw" "Tuscola" }
    "Benzie" {"Grand Traverse" "Leelanau" "Manistee" "Wexford" }
    "Berrien" {"Cass" "Van Buren" }
    "Branch" {"Calhoun" "Hillsdale" "Kalamazoo" "St. Joseph" }
    "Calhoun" {"Barry" "Branch" "Eaton" "Hillsdale" "Jackson" "Kalamazoo" "St. Joseph" }
    "Cass" {"Berrien" "Kalamazoo" "St. Joseph" "Van Buren" }
    "Charlevoix" {"Antrim" "Cheboygan" "Emmet" "Leelanau" "Mackinac" "Otsego" "Schoolcraft" }
    "Cheboygan" {"Charlevoix" "Emmet" "Mackinac" "Montmorency" "Otsego" "Presque Isle" }
    "Chippewa" {"Luce" "Mackinac" "Presque Isle" }
    "Clare" {"Gladwin" "Isabella" "Mecosta" "Midland" "Missaukee" "Osceola" "Roscommon" }
    "Clinton" {"Eaton" "Gratiot" "Ingham" "Ionia" "Montcalm" "Shiawassee" }
    "Crawford" {"Antrim" "Kalkaska" "Missaukee" "Montmorency" "Ogemaw" "Oscoda" "Otsego" "Roscommon" }
    "Delta" {"Alger" "Leelanau" "Marquette" "Menominee" "Schoolcraft" }
    "Dickinson" {"Iron" "Marquette" "Menominee" }
    "Eaton" {"Barry" "Calhoun" "Clinton" "Ingham" "Ionia" "Jackson" }
    "Emmet" {"Charlevoix" "Cheboygan" "Mackinac" }
    "Genesee" {"Lapeer" "Livingston" "Oakland" "Saginaw" "Shiawassee" "Tuscola" }
    "Gladwin" {"Arenac" "Bay" "Clare" "Isabella" "Midland" "Ogemaw" "Roscommon" }
    "Gogebic" {"Iron" "Ontonagon" }
    "Grand Traverse" {"Antrim" "Benzie" "Kalkaska" "Leelanau" "Manistee" "Missaukee" "Wexford" }
    "Gratiot" {"Clinton" "Ionia" "Isabella" "Midland" "Montcalm" "Saginaw" "Shiawassee" }
    "Hillsdale" {"Branch" "Calhoun" "Jackson" "Lenawee" }
    "Houghton" {"Baraga" "Iron" "Keweenaw" "Marquette" "Ontonagon" }
    "Huron" {"Arenac" "Bay" "Iosco" "Sanilac" "Tuscola" }
    "Ingham" {"Clinton" "Eaton" "Jackson" "Livingston" "Shiawassee" }
    "Ionia" {"Barry" "Clinton" "Eaton" "Gratiot" "Kent" "Montcalm" }
    "Iosco" {"Alcona" "Arenac" "Huron" "Ogemaw" "Oscoda" }
    "Iron" {"Baraga" "Dickinson" "Gogebic" "Houghton" "Marquette" "Ontonagon" }
    "Isabella" {"Clare" "Gladwin" "Gratiot" "Mecosta" "Midland" "Montcalm" "Osceola" }
    "Jackson" {"Calhoun" "Eaton" "Hillsdale" "Ingham" "Lenawee" "Livingston" "Washtenaw" }
    "Kalamazoo" {"Allegan" "Barry" "Branch" "Calhoun" "Cass" "St. Joseph" "Van Buren" }
    "Kalkaska" {"Antrim" "Crawford" "Grand Traverse" "Missaukee" "Otsego" "Roscommon" "Wexford" }
    "Kent" {"Allegan" "Barry" "Ionia" "Montcalm" "Muskegon" "Newaygo" "Ottawa" }
    "Keweenaw" {"Alger" "Houghton" "Marquette" "Ontonagon" }
    "Lake" {"Manistee" "Mason" "Mecosta" "Newaygo" "Oceana" "Osceola" "Wexford" }
    "Lapeer" {"Genesee" "Macomb" "Oakland" "St. Clair" "Sanilac" "Tuscola" }
    "Leelanau" {"Antrim" "Benzie" "Charlevoix" "Delta" "Grand Traverse" "Schoolcraft" }
    "Lenawee" {"Hillsdale" "Jackson" "Monroe" "Washtenaw" }
    "Livingston" {"Genesee" "Ingham" "Jackson" "Oakland" "Shiawassee" "Washtenaw" }
    "Luce" {"Alger" "Chippewa" "Mackinac" "Schoolcraft" }
    "Mackinac" {"Charlevoix" "Cheboygan" "Chippewa" "Emmet" "Luce" "Presque Isle" "Schoolcraft" }
    "Macomb" {"Lapeer" "Oakland" "St. Clair" "Wayne" }
    "Manistee" {"Benzie" "Grand Traverse" "Lake" "Mason" "Wexford" }
    "Marquette" {"Alger" "Baraga" "Delta" "Dickinson" "Houghton" "Iron" "Keweenaw" "Menominee" }
    "Mason" {"Lake" "Manistee" "Newaygo" "Oceana" }
    "Mecosta" {"Clare" "Isabella" "Lake" "Montcalm" "Newaygo" "Osceola" }
    "Menominee" {"Delta" "Dickinson" "Marquette" }
    "Midland" {"Bay" "Clare" "Gladwin" "Gratiot" "Isabella" "Saginaw" }
    "Missaukee" {"Clare" "Crawford" "Grand Traverse" "Kalkaska" "Osceola" "Roscommon" "Wexford" }
    "Monroe" {"Lenawee" "Washtenaw" "Wayne" }
    "Montcalm" {"Clinton" "Gratiot" "Ionia" "Isabella" "Kent" "Mecosta" "Newaygo" }
    "Montmorency" {"Alpena" "Cheboygan" "Crawford" "Oscoda" "Otsego" "Presque Isle" }
    "Muskegon" {"Kent" "Newaygo" "Oceana" "Ottawa" }
    "Newaygo" {"Kent" "Lake" "Mason" "Mecosta" "Montcalm" "Muskegon" "Oceana" "Osceola" }
    "Oakland" {"Genesee" "Lapeer" "Livingston" "Macomb" "Washtenaw" "Wayne" }
    "Oceana" {"Lake" "Mason" "Muskegon" "Newaygo" }
    "Ogemaw" {"Alcona" "Arenac" "Crawford" "Gladwin" "Iosco" "Oscoda" "Roscommon" }
    "Ontonagon" {"Gogebic" "Houghton" "Iron" "Keweenaw" }
    "Osceola" {"Clare" "Isabella" "Lake" "Mecosta" "Missaukee" "Newaygo" "Wexford" }
    "Oscoda" {"Alcona" "Alpena" "Crawford" "Iosco" "Montmorency" "Ogemaw" "Otsego" "Roscommon" }
    "Otsego" {"Antrim" "Charlevoix" "Cheboygan" "Crawford" "Kalkaska" "Montmorency" "Oscoda" }
    "Ottawa" {"Allegan" "Kent" "Muskegon" }
    "Presque Isle" {"Alpena" "Cheboygan" "Chippewa" "Mackinac" "Montmorency" }
    "Roscommon" {"Clare" "Crawford" "Gladwin" "Kalkaska" "Missaukee" "Ogemaw" "Oscoda" }
    "Saginaw" {"Bay" "Genesee" "Gratiot" "Midland" "Shiawassee" "Tuscola" }
    "St. Clair" {"Lapeer" "Macomb" "Sanilac" }
    "St. Joseph" {"Branch" "Calhoun" "Cass" "Kalamazoo" "Van Buren" }
    "Sanilac" {"Huron" "Lapeer" "St. Clair" "Tuscola" }
    "Schoolcraft" {"Alger" "Charlevoix" "Delta" "Leelanau" "Luce" "Mackinac" }
    "Shiawassee" {"Clinton" "Genesee" "Gratiot" "Ingham" "Livingston" "Saginaw" }
    "Tuscola" {"Bay" "Genesee" "Huron" "Lapeer" "Saginaw" "Sanilac" }
    "Van Buren" {"Allegan" "Berrien" "Cass" "Kalamazoo" "St. Joseph" }
    "Washtenaw" {"Jackson" "Lenawee" "Livingston" "Monroe" "Oakland" "Wayne" }
    "Wayne" {"Macomb" "Monroe" "Oakland" "Washtenaw" }
    "Wexford" {"Benzie" "Grand Traverse" "Kalkaska" "Lake" "Manistee" "Missaukee" "Osceola" }
}
# Rhode Island counties
array set ::Coloring::BORDERS {
    "Bristol" {"Kent" "Newport" "Providence" }
    "Kent" {"Bristol" "Newport" "Providence" "Washington" }
    "Newport" {"Bristol" "Kent" "Washington" }
    "Providence" {"Bristol" "Kent" }
    "Washington" {"Kent" "Newport" }
}
array set ::Coloring::BORDERS {
    "Georgia" {"Armenia" "Azerbaijan" "Russian Federation" "Turkiye"
        "North Carolina" "South Carolina" "Tennessee" "Alabama" "Florida"}
}
