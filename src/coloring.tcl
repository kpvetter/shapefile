#!/bin/sh
# Restart with tcl: -*- mode: tcl; tab-width: 8; -*- \
exec tclsh $0 ${1+"$@"}

##+##########################################################################
#
# coloring.tcl -- Gives a coloring scheme for a list of names that avoids touching colors
# by Keith Vetter 2025-04-20
#
package require cksum

namespace eval ::Coloring {
    variable BORDERS
    variable COLORS [list lightyellow cyan orange green pink sienna1 yellow red blue springgreen]
    # FIX
    #   Congo
    #   Palestine Territory

    #   Vatican City
    #   Laos
    #   Côte d'Ivoire
    # NB. Georgia is both a state and a country so we combine the two
    array set BORDERS {
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
        "Congo" {"Angola", "Cameroon" "Central African Republic" "Congo DRC" "Gabon" }
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

        "Georgia" {"Armenia" "Azerbaijan" "Russian Federation" "Turkiye"
            "North Carolina" "South Carolina" "Tennessee" "Alabama" "Florida"}
    }
}
proc ::Coloring::CreateColoringScheme {nameList {nonce ""}} {
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
    if {$colors eq {}} { return "" }
    set clrIndex [expr {[::crc::cksum $nonce] % [llength $colors]}]
    set color [lindex $colors $clrIndex]
    return $color
}

################################################################
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {

    set countries {"Afghanistan" "Albania" "Algeria" "American Samoa"
        "Andorra" "Angola" "Anguilla" "Antarctica" "Antigua and Barbuda"
        "Argentina" "Armenia" "Aruba" "Australia" "Austria" "Azerbaijan"
        "Azores" "Bahamas" "Bahrain" "Bangladesh" "Barbados" "Belarus"
        "Belgium" "Belize" "Benin" "Bermuda" "Bhutan" "Bolivia" "Bonaire"
        "Bosnia and Herzegovina" "Botswana" "Bouvet Island" "Brazil"
        "British Indian Ocean Territory" "British Virgin Islands"
        "Brunei Darussalam" "Bulgaria" "Burkina Faso" "Burundi" "Cabo Verde"
        "Cambodia" "Cameroon" "Canada" "Canarias" "Cayman Islands"
        "Central African Republic" "Chad" "Chile" "China"
        "Christmas Island" "Cocos Islands" "Colombia" "Comoros" "Congo" "Congo DRC"
        "Cook Islands" "Costa Rica" "Croatia" "Cuba" "Curacao" "Cyprus"
        "Czech Republic" "Côte d'Ivoire" "Denmark" "Djibouti" "Dominica"
        "Dominican Republic" "Ecuador" "Egypt" "El Salvador"
        "Equatorial Guinea" "Eritrea" "Estonia" "Eswatini" "Ethiopia"
        "Falkland Islands" "Faroe Islands" "Fiji" "Finland" "France" "French Guiana"
        "French Polynesia" "French Southern Territories" "Gabon" "Gambia"
        "Georgia" "Germany" "Ghana" "Gibraltar" "Glorioso Islands"
        "Greece" "Greenland" "Grenada" "Guadeloupe" "Guam" "Guatemala"
        "Guernsey" "Guinea" "Guinea-Bissau" "Guyana" "Haiti"
        "Heard Island and McDonald Islands" "Honduras" "Hungary" "Iceland" "India"
        "Indonesia" "Iran" "Iraq" "Ireland" "Isle of Man" "Israel" "Italy"
        "Jamaica" "Japan" "Jersey" "Jordan" "Juan De Nova Island"
        "Kazakhstan" "Kenya" "Kiribati" "Kuwait" "Kyrgyzstan" "Laos"
        "Latvia" "Lebanon" "Lesotho" "Liberia" "Libya" "Liechtenstein"
        "Lithuania" "Luxembourg" "Madagascar" "Madeira" "Malawi"
        "Malaysia" "Maldives" "Mali" "Malta" "Marshall Islands"
        "Martinique" "Mauritania" "Mauritius" "Mayotte" "Mexico"
        "Micronesia" "Moldova" "Monaco" "Mongolia" "Montenegro"
        "Montserrat" "Morocco" "Mozambique" "Myanmar" "Namibia" "Nauru"
        "Nepal" "Netherlands" "New Caledonia" "New Zealand" "Nicaragua"
        "Niger" "Nigeria" "Niue" "Norfolk Island" "North Korea"
        "North Macedonia" "Northern Mariana Islands" "Norway" "Oman" "Pakistan"
        "Palau" "Palestinian Territory" "Panama" "Papua New Guinea"
        "Paraguay" "Peru" "Philippines" "Pitcairn" "Poland" "Portugal"
        "Puerto Rico" "Qatar" "Romania" "Russian Federation" "Rwanda"
        "Réunion" "Saba" "Saint Barthelemy" "Saint Eustatius"
        "Saint Helena" "Saint Kitts and Nevis" "Saint Lucia" "Saint Martin"
        "Saint Pierre and Miquelon" "Saint Vincent and the Grenadines"
        "Samoa" "San Marino" "Sao Tome and Principe" "Saudi Arabia"
        "Senegal" "Serbia" "Seychelles" "Sierra Leone" "Singapore"
        "Sint Maarten" "Slovakia" "Slovenia" "Solomon Islands" "Somalia"
        "South Africa" "South Georgia and South Sandwich Islands" "South Korea"
        "South Sudan" "Spain" "Sri Lanka" "Sudan" "Suriname" "Svalbard"
        "Sweden" "Switzerland" "Syria" "Tajikistan" "Tanzania" "Thailand"
        "Timor-Leste" "Togo" "Tokelau" "Tonga" "Trinidad and Tobago"
        "Tunisia" "Turkiye" "Turkmenistan" "Turks and Caicos Islands"
        "Tuvalu" "Uganda" "Ukraine" "United Arab Emirates"
        "United Kingdom" "United States" "United States Minor Outlying Islands"
        "Uruguay" "US Virgin Islands" "Uzbekistan" "Vanuatu"
        "Vatican City" "Venezuela" "Vietnam" "Wallis and Futuna" "Yemen" "Zambia"
        "Zimbabwe"}

    set islands {
        "Australia" "Antarctica"
        "Antigua and Barbuda" "Bahamas" "Bahrain" "Barbados" "Brunei"
        "Cape Verde" "Comoros" "Cuba" "Cyprus" "Dominica"
        "Dominican Republic" "East Timor" "Fiji" "Grenada" "Haiti" "Iceland"
        "Indonesia" "Ireland" "Jamaica" "Japan" "Kiribati" "Madagascar"
        "Maldives" "Malta" "Marshall Islands" "Mauritius" "Micronesia"
        "Nauru" "New Zealand" "Palau" "Papua New Guinea" "Philippines"
        "Saint Kitts and Nevis" "Saint Lucia"
        "Saint Vincent and the Grenadines" "Samoa" "São Tomé and Príncipe" "Seychelles"
        "Singapore" "Solomon Islands" "Sri Lanka" "Tonga"
        "Trinidad and Tobago" "Tuvalu" "United Kingdom" "Vanuatu" "Northern Cyprus"
        "Taiwan" "Cook Islands" "Niue" "Bermuda" "Bouvet Island" "British Indian Ocean Territory"
        "American Samoa" "Andaman and Nicobar Islands" "Anguilla" "Aruba"
        "Bermuda" "Bouvet Island" "British Indian Ocean Territory"
        "British Virgin Islands" "Caribbean Netherlands" "Cayman Islands"
        "Christmas Island" "Cocos (Keeling) Islands" "Curaçao" "Easter Island"
        "Falkland Islands" "Faroe Islands" "French Polynesia"
        "French Southern and Antarctic Lands" "Galápagos Islands" "Greenland" "Guadeloupe" "Guam"
        "Guernsey" "Heard and McDonald Islands" "Hong Kong" "Isle of Man"
        "Jan Mayen" "Jersey" "Juan Fernández Islands" "Lakshadweep" "Macau"
        "Martinique" "Mayotte" "Montserrat" "New Caledonia" "Norfolk Island"
        "Northern Mariana Islands"
        "Pitcairn, Henderson, Ducie, and Oeno Islands" "Puerto Rico" "Réunion" "Saint Barthélemy"
        "Saint Helena, Ascension, and Tristan da Cunha" "Saint Martin"
        "Saint Pierre and Miquelon" "Sint Maarten"
        "South Georgia and the South Sandwich Islands"
        "Sovereign Base Areas of Akrotiri and Dhekelia" "Svalbard" "Tokelau"
        "Turks and Caicos Islands"
        "United States Minor Outlying Islands" "U.S. Virgin Islands" "Wallis and Futuna"
        "Azores" "Bonaire" "Cabo Verde" "Canarias" "Cocos Islands" "Curacao"
        "French Southern Territories" "Glorioso Islands"
        "Heard Island and McDonald Islands" "Juan De Nova Island" "Madeira"
        "Pitcairn" "Saba" "Saint Barthelemy" "Saint Eustatius"
        "Saint Helena" "Sao Tome and Principe"
        "South Georgia and South Sandwich Islands" "US Virgin Islands"
    }


    "proc" FindMissing {} {

        set missing {}
        foreach c $::countries {
            if {$c in $::islands} continue
            if {! [info exists ::Coloring::BORDERS($c)]} {
                puts "missing $c"
                lappend missing $c
            }
        }
    }
    FindMissing
}
