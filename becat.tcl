#!/usr/bin/env tclsh

set script_name becat
set version 0.0.1
set usage {
    {becat}             "becat <command> [<args>]

See 'becat help <command>' for more information on a specific command."
    {becat split}       "becat split [<options>] <file>...
Split files into pieces."
    {becat join}        "becat join [<options>] <file>...
Read / concatenate files."
    {becat hash}        "becat hash [<options>] <file>...
List checksums of files."
    {becat compare}     "becat compare [<options>] <file>...
Compare files."
    {becat help}        "becat help
Print help."
    {becat version}     "becat version
Print version."
}
set argsusage {
    "-b, --bytes, --blocksize <size> "
    "Bytes per block"
    
    "-c, --color, --color-scheme <n> "
    "Color scheme (0, 1, 2)"
    "    --no-color                  "
    "No-color mode (same as --color-scheme 0)"
    
    "-o, --output <filename>         "
    "Output filename"
    
    "-s, --start <start>             "
    "Range start"
    "-l, --length <length>           "
    "Range length"
    "-r, --range <start>-<end>       "
    "Range"
    
    "-q, --quiet                     "
    "Quiet mode"
    
    "    --filename, --show-filename "
    "Show filename"
    "    --no-filename               "
    "Don't show filename"
    "    --group, --show-group       "
    "Show group"
    "    --no-group                  "
    "Don't show group"
    "    --size, --show-size         "
    "Show size"
    "    --no-size                   "
    "Don't show size"
    
    "    --dec, --decimal            "
    "Show dec representation of number"
    "    --no-dec, --no-decimal      "
    "Don't show dec representation of number"
    "    --hex, --hexadecimal        "
    "Show hex representation of number"
    "    --no-hex, --no-hexadecimal  "
    "Don't show hex representation of number"
    "    --oct, --octal              "
    "Show oct representation of number"
    "    --no-oct, --no-octal        "
    "Don't show oct representation of number"
    
    "    --bsd, --bsd-checksum       "
    "Use BSD checksum (16-bits CRC)"
    "    --sysv, --sysv-checksum     "
    "Use SysV checksum (16-bits CRC)"
    "    --crc, --cksum, --checksum  "
    "Use GNU checksum (32-bits CRC)"
    "    --md5, --md5sum             "
    "Use MD5 checksum"
    "    --sha1, --sha1sum           "
    "Use SHA-1 checksum"
    "    --sha224, --sha224sum       "
    "Use SHA-224 checksum"
    "    --sha256, --sha256sum       "
    "Use SHA-256 checksum"
    "    --sha384, --sha384sum       "
    "Use SHA-384 checksum"
    "    --sha512, --sha512sum       "
    "Use SHA-512 checksum"
}

# Optional args
set optargs {
    blocksize           0x100000
    color_scheme        1
    hashfunc            md5
    quiet               0
    
    range_start         0
    range_length        0
    
    show_filename       1
    show_group          1
    show_size           1
    
    show_dec            1
    show_hex            0
    show_oct            0
    
}

# ANSI escape code for colors
set color_table {
    black               "\033\[30m%s\033\[0m"
    red                 "\033\[31m%s\033\[0m"
    green               "\033\[32m%s\033\[0m"
    yellow              "\033\[33m%s\033\[0m"
    blue                "\033\[34m%s\033\[0m"
    magenta             "\033\[35m%s\033\[0m"
    cyan                "\033\[36m%s\033\[0m"
    light_gray          "\033\[37m%s\033\[0m"
    dark_gray           "\033\[90m%s\033\[0m"
    light_red           "\033\[91m%s\033\[0m"
    light_green         "\033\[92m%s\033\[0m"
    light_yellow        "\033\[93m%s\033\[0m"
    light_blue          "\033\[94m%s\033\[0m"
    light_magenta       "\033\[95m%s\033\[0m"
    light_cyan          "\033\[96m%s\033\[0m"
    white               "\033\[97m%s\033\[0m"
}

# Common Unicode characters
set unicode_table {
    full_block          "\u2588"
    light_shade         "\u2591"
    medium_shade        "\u2592"
    dark_shade          "\u2593"
}

# Units of multiples of bytes
# KB -> Kilobyte        K (KiB) -> Kibibyte
# MB -> Megabyte        M (MiB) -> Mebibyte
# GB -> Gigabyte        G (GiB) -> Gibibyte
set unit_table {
    KB  1000
    K   1024
    MB  1000*1000
    M   1024*1024
    GB  1000*1000*1000
    G   1024*1024*1024
}

# GNU Coreutils commands to calculate checksums
set hashcmd {
    bsd                 {sum -r}
    sysv                {sum -s}
    crc                 {cksum}
    md5                 {md5sum}
    sha1                {sha1sum}
    sha224              {sha224sum}
    sha256              {sha256sum}
    sha384              {sha384sum}
    sha512              {sha512sum}
}

# Print a usage message
proc print_usage {msg} {
    puts stdout "Usage: $msg"
}

# Print an error message and exit
proc err {msg} {
    puts stderr "Error: $msg"
    exit
}

# Parse integer
proc get_num {value} {
    global unit_table
    
    set suffix [string toupper [string range $value end-1 end]]
    switch -regexp -- $suffix {
        "[[:xdigit:]][^[:xdigit:]]" {
            set unit [string index $suffix 1]
            if {[dict exists $unit_table $unit]} {
                set value "[string range $value 0 end-1] * [dict get $unit_table $unit]"
            } else {
                err "Unknown unit: $unit"
            }
        }
        "[^[:xdigit:]]B" {
            set unit "[string index $suffix 0]B"
            if {[dict exists $unit_table $unit]} {
                set value "[string range $value 0 end-2] * [dict get $unit_table $unit]"
            } else {
                err "Unknown unit: $unit"
            }
        }
        default {}
    }
    if {[expr $value] < 0x80000000} {
        expr $value
    } else {
        err "Integer out of range (0 - 0x7FFFFFFF)"
    }
}

# Colorize text
proc colorize {color content} {
    # Optional args available
    global optargs
    set color_scheme [dict get $optargs color_scheme]
    
    global color_table
    
    switch -- $color_scheme {
        1 {
            # Color scheme 1 - for dark background
            switch -- $color {
                eq { format [dict get $color_table light_yellow] $content }
                ne { format [dict get $color_table light_red] $content }
            }
        }
        2 {
            # Color scheme 2 - for light background
            switch -- $color {
                eq { format [dict get $color_table blue] $content }
                ne { format [dict get $color_table red] $content }
            }
        }
        0 -
        default { return $content }
    }
}

# Return the checksum of data or file
proc hash {hashfunc data {filename {}}} {
    global hashcmd
    
    if {$filename == {}} {
        # Return the checksum of data (if no filename given)
        set tmpfile [exec mktemp]
        set f1 [open $tmpfile w+]
        set f2 [open "| [dict get $hashcmd $hashfunc] >@$f1" w]
        chan configure $f2 -translation binary
        puts -nonewline $f2 $data
        catch { close $f2 }
        chan seek $f1 0
        set ret [read -nonewline $f1]
        catch { close $f1 }
        file delete $tmpfile
        lindex $ret 0
    } else {
        # Return the checksum of file
        exec {*}[dict get $hashcmd $hashfunc] -- $filename | cut "-d " "-f1"
    }
}

# Return the number of digits of an integer (decimal digits by default)
proc nod {n {base 10}} { expr 1 + int(log($n) / log($base)) }

################
# Sub-commands #
################

# Print help
proc help {{target 0}} {
    global script_name
    global usage
    global argsusage
    
    if {[dict exists $usage [concat $script_name $target]]} {
        print_usage [dict get $usage [concat $script_name $target]]
        puts {}
        dict for {key value} $argsusage {
            puts [format "%s %s" $key $value]
        }
    } else {
        print_usage [dict get $usage $script_name]
        puts {}
        dict for {key value} $usage {
            regexp -- {\n([^\n]*)} $value _ temp
            puts [format "%s\t%s" $key $temp]
        }
    }
}

# Split a file into pieces
proc split_main {target} {
    # Optional args available
    global optargs
    set blocksize [dict get $optargs blocksize]
    set quiet [dict get $optargs quiet]
    set show_dec [dict get $optargs show_dec]
    set show_oct [dict get $optargs show_oct]
    set show_hex [dict get $optargs show_hex]
    if {[dict exists $optargs output]} {
        set output [dict get $optargs output]
    } else {
        set output $target
    }
    
    set ifsize [file size $target]
    set sn(dec) [nod [expr $ifsize - 1]]
    set sn(hex) [nod [expr $ifsize - 1] 16]
    set sn(oct) [nod [expr $ifsize - 1] 8]
    set pn [nod [expr ceil(double($ifsize) / $blocksize) - 1]]
    
    if {!$quiet} { puts "Spliting file: $target" }
    set ifid [open $target r]
    chan configure $ifid -translation binary
    
    for { set p 0 } {![chan eof $ifid]} { incr p } {
        set ofname ${output}_[format "%0${pn}d" $p]
        set b_start [expr $p * $blocksize]
        set b_end [expr min(($p + 1) * $blocksize - 1, $ifsize - 1)]
        set line ""
        if {$show_dec} {
            set line $line[format "%${sn(dec)}d-%${sn(dec)}d" $b_start $b_end]|
        }
        if {$show_hex} {
            set line $line[format "%${sn(hex)}X-%${sn(hex)}X" $b_start $b_end]|
        }
        if {$show_oct} {
            set line $line[format "%${sn(oct)}o-%${sn(oct)}o" $b_start $b_end]|
        }
        set line "$line => $ofname"
        
        set ofid [open $ofname w]
        chan configure $ofid -translation binary
        chan copy $ifid $ofid -size $blocksize
        catch { close $ofid }
        
        if {!$quiet} { puts $line }
    }
    
    catch { close $ifid }
}

# Read / concatenate files
proc join_main {targets} {
    # Optional args available
    global optargs
    set quiet [dict get $optargs quiet]
    set range_start [dict get $optargs range_start]
    set range_length [dict get $optargs range_length]
    set show_dec [dict get $optargs show_dec]
    set show_oct [dict get $optargs show_oct]
    set show_hex [dict get $optargs show_hex]
    if {[dict exists $optargs output]} {
        set output [dict get $optargs output]
    } else {
        set output {}
    }
    
    set totalsize 0
    foreach target $targets {
        set totalsize [expr $totalsize + [file size $target]]
    }
    set sn(dec) [nod [expr $totalsize - 1]]
    set sn(hex) [nod [expr $totalsize - 1] 16]
    set sn(oct) [nod [expr $totalsize - 1] 8]
    
    if {$output == {}} {
        chan configure stdout -translation binary
    } else {
        if {!$quiet} { puts "Concatenating file: $output" }
        file delete $output
        set ofid [open $output a]
        chan configure $ofid -translation binary
    }
    
    set b_end -1
    foreach target $targets {
        if {$range_length} {
            set ifsize [expr min($range_length, [file size $target] - $range_start)]
        } else {
            set ifsize [file size $target]
        }
        set b_start [expr $b_end + 1]
        set b_end [expr $b_start + $ifsize - 1]
        set line ""
        if {$show_dec} {
            set line $line[format "%${sn(dec)}d-%${sn(dec)}d" $b_start $b_end]|
        }
        if {$show_hex} {
            set line $line[format "%${sn(hex)}X-%${sn(hex)}X" $b_start $b_end]|
        }
        if {$show_oct} {
            set line $line[format "%${sn(oct)}o-%${sn(oct)}o" $b_start $b_end]|
        }
        set line "$line <= $target"
        
        set ifid [open $target r]
        chan configure $ifid -translation binary
        chan seek $ifid $range_start
        if {$output != {}} {
            if {$range_length} {
                chan copy $ifid $ofid -size $range_length
            } else {
                chan copy $ifid $ofid
            }
        } else {
            if {$range_length} {
                puts -nonewline [read $ifid $range_length]
            } else {
                puts -nonewline [read $ifid]
            }
        }
        catch { close $ifid }
        
        if {$output != {} && !$quiet} { puts $line }
    }
    
    if {$output == {}} {
        chan configure stdout -translation binary
    } else {
        catch { close $ofid }
    }
}

# List checksums of files
proc hash_main {targets} {
    # Optional args available
    global optargs
    set hashfunc [dict get $optargs hashfunc]
    set color_scheme [dict get $optargs color_scheme]
    set show_filename [dict get $optargs show_filename]
    set show_group [dict get $optargs show_group]
    set show_size [dict get $optargs show_size]
    
    set results {}
    set hashes {}
    set gids {}
    set gid 0
    set i 0
    foreach target $targets {
        set result [hash $hashfunc {} $target]
        if {$show_size} { set result [concat $result [file size $target]] }
        if {$show_filename} { set result [concat $result $target] }
        set hashkey [lindex $result 0]
        if {![dict exists $hashes $hashkey]} {
            incr gid
            dict set hashes $hashkey $i
            dict set gids $hashkey $gid
            if {$show_group} {
                set result [concat $result \[$gid\]]
            }
        } else {
            dict set hashes $hashkey [concat [dict get $hashes $hashkey] $i]
            if {$show_group} {
                set result [concat $result \[[dict get $gids $hashkey]\]]
            }
            if {[llength [dict get $hashes $hashkey]] == 2} {
                set first [lindex [dict get $hashes $hashkey] 0]
                lset results $first [colorize eq [lindex $results $first]]
            }
            set result [colorize eq $result]
        }
        lappend results $result
        incr i
    }
    
    foreach result $results { puts $result }
}

# Compare files
proc compare_main {targets} {
    # Optional args available
    global optargs
    set blocksize [dict get $optargs blocksize]
    set color_scheme [dict get $optargs color_scheme]
    set hashfunc [dict get $optargs hashfunc]
    set show_dec [dict get $optargs show_dec]
    set show_oct [dict get $optargs show_oct]
    set show_hex [dict get $optargs show_hex]
    
    global unicode_table
    
    set maxsize 0
    set tn 0
    foreach target $targets {
        if {[file size $target] > $maxsize} {
            set maxsize [file size $target]
        }
        set tn [expr max($tn, [string length [file tail $target]])]
        set fid($target) [open $target r]
        chan configure $fid($target) -translation binary
    }
    set sn(dec) [nod [expr $maxsize - 1]]
    set sn(hex) [nod [expr $maxsize - 1] 16]
    set sn(oct) [nod [expr $maxsize - 1] 8]
    
    set line ""
    if {$show_dec} {
        set line $line[string repeat " " [expr $sn(dec) * 2 + 2]]
    }
    if {$show_hex} {
        set line $line[string repeat " " [expr $sn(hex) * 2 + 2]]
    }
    if {$show_oct} {
        set line $line[string repeat " " [expr $sn(oct) * 2 + 2]]
    }
    foreach target $targets {
        set line $line[format " %${tn}s" [file tail $target]]
    }
    puts $line
    
    set n [expr int(ceil(double($maxsize) / $blocksize))]
    for { set p 0 } {$p < $n} { incr p } {
        set b_start [expr $p * $blocksize]
        set b_end [expr min(($p + 1) * $blocksize - 1, $maxsize - 1)]
        set line ""
        if {$show_dec} {
            set line $line[format "%${sn(dec)}d-%${sn(dec)}d" $b_start $b_end]|
        }
        if {$show_hex} {
            set line $line[format "%${sn(hex)}x-%${sn(hex)}x" $b_start $b_end]|
        }
        if {$show_oct} {
            set line $line[format "%${sn(oct)}o-%${sn(oct)}o" $b_start $b_end]|
        }
        
        set results {}
        set hashes {}
        set i 0
        foreach target $targets {
            if {![chan eof $fid($target)]} {
                set hashkey [hash $hashfunc [read $fid($target) $blocksize]]
                if {![dict exists $hashes $hashkey]} {
                    dict set hashes $hashkey $i
                } else {
                    dict set hashes $hashkey [concat [dict get $hashes $hashkey] $i]
                }
                lappend results [dict get $unicode_table full_block]
            } else {
                lappend results " "
            }
            incr i
        }
        
        if {[dict size $hashes] > 1} {
            if {[dict size $hashes] == 2} {
                set t0 [lindex [dict values $hashes] 0]
                set t1 [lindex [dict values $hashes] 1]
                if {[llength $t0] == 1 && [llength $t1] > 1} {
                    set t [lindex $t0 0]
                    lset results $t [if {$color_scheme} {
                        colorize ne [lindex $results $t]
                    } else {
                        dict get $unicode_table light_shade
                    }]
                    foreach t $t1 {
                        lset results $t [if {$color_scheme} {
                            colorize eq [lindex $results $t]
                        } else {
                            dict get $unicode_table dark_shade
                        }]
                    }
                } elseif {[llength $t0] > 1 && [llength $t1] == 1} {
                    set t [lindex $t1 0]
                    lset results $t [if {$color_scheme} {
                        colorize ne [lindex $results $t]
                    } else {
                        dict get $unicode_table light_shade
                    }]
                    foreach t $t0 {
                        lset results $t [if {$color_scheme} {
                            colorize eq [lindex $results $t]
                        } else {
                            dict get $unicode_table dark_shade
                        }]
                    }
                } else {
                    for { set t 0 } {$t < [llength $results]} { incr t } {
                        lset results $t [if {$color_scheme} {
                            colorize ne [lindex $results $t]
                        } else {
                            dict get $unicode_table light_shade
                        }]
                    }
                }
            } else {
                for { set t 0 } {$t < [llength $results]} { incr t } {
                    lset results $t [if {$color_scheme} {
                        colorize ne [lindex $results $t]
                    } else {
                        dict get $unicode_table light_shade
                    }]
                }
            }
        }
        
        foreach result $results {
            set line $line[string repeat " " $tn]$result
        }
        puts $line
    }
    
    foreach target $targets { catch { close $fid($target) } }
}

################
# Main program #
################

# Print usage if no command specified
if {$argc == 0} { help; exit }

# Parse the command
set cmd [lindex $argv 0]
set argv [lrange $argv 1 end]

# Parse command-line options
if {[string equal [info script] $argv0]} {
    while {[llength $argv] > 0} {
        set flag [lindex $argv 0]
        switch -regexp -- $flag {
            "^(--no-color)$" {
                # No-color mode
                set argv [lrange $argv 1 end]
                dict set optargs color_scheme 0
            }
            "^(-q|--quiet)$" {
                # Quiet mode
                set argv [lrange $argv 1 end]
                dict set optargs quiet 1
            }
            "^(--filename|--show-filename)$" {
                # Show filename
                set argv [lrange $argv 1 end]
                dict set optargs show_filename 1
            }
            "^(--no-filename)$" {
                # Don't show filename
                set argv [lrange $argv 1 end]
                dict set optargs show_filename 0
            }
            "^(--group|--show-group)$" {
                # Show group
                set argv [lrange $argv 1 end]
                dict set optargs show_group 1
            }
            "^(--no-group)$" {
                # Don't show group
                set argv [lrange $argv 1 end]
                dict set optargs show_group 0
            }
            "^(--size|--show-size)$" {
                # Show size
                set argv [lrange $argv 1 end]
                dict set optargs show_size 1
            }
            "^(--no-size)$" {
                # Don't show size
                set argv [lrange $argv 1 end]
                dict set optargs show_size 0
            }
            "^(--dec|--decimal)$" {
                # Show decimal representation of number
                set argv [lrange $argv 1 end]
                dict set optargs show_dec 1
            }
            "^(--no-dec|--no-decimal)$" {
                # Don't show decimal representation of number
                set argv [lrange $argv 1 end]
                dict set optargs show_dec 0
            }
            "^(--hex|--hexadecimal)$" {
                # Show hexadecimal representation of number
                set argv [lrange $argv 1 end]
                dict set optargs show_hex 1
            }
            "^(--no-hex|--no-hexadecimal)$" {
                # Don't show hexadecimal representation of number
                set argv [lrange $argv 1 end]
                dict set optargs show_hex 0
            }
            "^(--oct|--octal)$" {
                # Show octal representation of number
                set argv [lrange $argv 1 end]
                dict set optargs show_oct 1
            }
            "^(--no-oct|--no-octal)$" {
                # Don't show octal representation of number
                set argv [lrange $argv 1 end]
                dict set optargs show_oct 0
            }
            
            "^(--bsd|--bsd-checksum)$" {
                # Use BSD checksum (16-bits CRC)
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "bsd"
            }
            "^(--sysv|--sysv-checksum)$" {
                # Use SysV checksum (16-bits CRC)
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "sysv"
            }
            "^(--crc|--cksum|--checksum|--gnu-checksum|--posix-checksum)$" {
                # Use GNU checksum (32-bits CRC)
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "crc"
            }
            "^(--md5|--md5sum)$" {
                # Use MD5 checksum
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "md5"
            }
            "^(--sha1|--sha1sum)$" {
                # Use SHA-1 checksum
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "sha1"
            }
            "^(--sha224|--sha224sum)$" {
                # Use SHA-224 checksum
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "sha224"
            }
            "^(--sha256|--sha256sum)$" {
                # Use SHA-256 checksum
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "sha256"
            }
            "^(--sha384|--sha384sum)$" {
                # Use SHA-384 checksum
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "sha384"
            }
            "^(--sha512|--sha512sum)$" {
                # Use SHA-512 checksum
                set argv [lrange $argv 1 end]
                dict set optargs hashfunc "sha512"
            }
            
            "^(-b|--bytes|--blocksize)$" {
                # Bytes per block
                set value [lindex $argv 1]
                set argv [lrange $argv 2 end]
                dict set optargs blocksize [get_num $value]
            }
            "^(-b.+)$" {
                regexp -- {-b(.+)} $flag _ value
                set argv [lrange $argv 1 end]
                dict set optargs blocksize [get_num $value]
            }
            
            "^(-c|--color|--color-scheme)$" {
                # Color scheme
                set value [lindex $argv 1]
                set argv [lrange $argv 2 end]
                dict set optargs color_scheme [get_num $value]
            }
            "^(-c.+)$" {
                regexp -- {-c(.+)} $flag _ value
                set argv [lrange $argv 1 end]
                dict set optargs color_scheme [get_num $value]
            }
            
            "^(-o|--output)$" {
                # Output filename
                set value [lindex $argv 1]
                set argv [lrange $argv 2 end]
                dict set optargs output $value
            }
            "^(-o.+)$" {
                regexp -- {-o(.+)} $flag _ value
                set argv [lrange $argv 1 end]
                dict set optargs output $value
            }
            
            "^(-s|--start)$" {
                # Range start
                set value [lindex $argv 1]
                set argv [lrange $argv 2 end]
                dict set optargs range_start [get_num $value]
            }
            "^(-s.+)$" {
                regexp -- {-s(.+)} $flag _ value
                set argv [lrange $argv 1 end]
                dict set optargs range_start [get_num $value]
            }
            
            "^(-l|--length)$" {
                # Range length
                set value [lindex $argv 1]
                set argv [lrange $argv 2 end]
                dict set optargs range_length [get_num $value]
            }
            "^(-l.+)$" {
                regexp -- {-l(.+)} $flag _ value
                set argv [lrange $argv 1 end]
                dict set optargs range_length [get_num $value]
            }
            
            "^(-r|--range)$" {
                # Range
                regexp -- {(.*)-(.*)} [lindex $argv 1] _ s e
                set argv [lrange $argv 2 end]
                if {$s != "" && $e != ""} {
                    set s [get_num $s]
                    set e [get_num $e]
                    dict set optargs range_start $s
                    dict set optargs range_length [expr $e - $s + 1]
                } elseif {$s != "" && $e == ""} {
                    set s [get_num $s]
                    dict set optargs range_start $s
                } elseif {$s == "" && $e != ""} {
                    set e [get_num $e]
                    dict set optargs range_length [expr $e + 1]
                }
            }
            "^(-r.*-.*)$" {
                regexp -- {-r(.*)-(.*)} $flag _ s e
                set argv [lrange $argv 1 end]
                if {$s != "" && $e != ""} {
                    set s [get_num $s]
                    set e [get_num $e]
                    dict set optargs range_start $s
                    dict set optargs range_length [expr $e - $s + 1]
                } elseif {$s != "" && $e == ""} {
                    set s [get_num $s]
                    dict set optargs range_start $s
                } elseif {$s == "" && $e != ""} {
                    set e [get_num $e]
                    dict set optargs range_length [expr $e + 1]
                }
            }
            
            default { break }
        }
    }
}

set targets $argv
switch -- $cmd {
    "split" {
        # Split files into pieces
        foreach target $targets {
            split_main $target
        }
    }
    
    "r" -
    "read" -
    "join" {
        # Read / concatenate files
        join_main $targets
    }
    
    "ls" -
    "list" -
    "hash" {
        # List checksums of files
        hash_main $targets
    }
    
    "cmp" -
    "compare" {
        # Compare files
        compare_main $targets
    }
    
    "-h" -
    "--help" -
    "help" {
        # Print help
        if {$targets == {}} {
            help
        } else {
            foreach target $targets {
                help $target
            }
        }
    }
    
    "-V" -
    "--version" -
    "version" {
        # Print version
        puts "$script_name $version"
    }
}

exit
