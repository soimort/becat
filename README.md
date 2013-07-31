# becat

__becat(1)__ is a command-line utility to split, concatenate and compare binary files.

## Dependencies

* [Tcl](http://www.tcl.tk/) (>= 8.5)
* [GNU Coreutils](http://www.gnu.org/software/coreutils/)

## Usage

### Split files into pieces

    $ becat split [<options>] <file>...

Available options:

```
-b, --bytes, --blocksize <size>  Bytes per block
-o, --output <filename>          Output filename
-q, --quiet                      Quiet mode
    --dec, --decimal             Show dec representation of number
    --no-dec, --no-decimal       Don't show dec representation of number
    --hex, --hexadecimal         Show hex representation of number
    --no-hex, --no-hexadecimal   Don't show hex representation of number
    --oct, --octal               Show oct representation of number
    --no-oct, --no-octal         Don't show oct representation of number
```

### Read / concatenate files

    $ becat join [<options>] <file>...

Available options:

```
-o, --output <filename>          Output filename
-s, --start <start>              Range start
-l, --length <length>            Range length
-r, --range <start>-<end>        Range
-q, --quiet                      Quiet mode
    --dec, --decimal             Show dec representation of number
    --no-dec, --no-decimal       Don't show dec representation of number
    --hex, --hexadecimal         Show hex representation of number
    --no-hex, --no-hexadecimal   Don't show hex representation of number
    --oct, --octal               Show oct representation of number
    --no-oct, --no-octal         Don't show oct representation of number
```

### List checksums of files

    $ becat hash [<options>] <file>...

Available options:

```
-c, --color, --color-scheme <n>  Color scheme (0, 1, 2)
    --no-color                   No-color mode (same as --color-scheme 0)
    --filename, --show-filename  Show filename
    --no-filename                Don't show filename
    --group, --show-group        Show group
    --no-group                   Don't show group
    --size, --show-size          Show size
    --no-size                    Don't show size
    --bsd, --bsd-checksum        Use BSD checksum (16-bits CRC)
    --sysv, --sysv-checksum      Use SysV checksum (16-bits CRC)
    --crc, --cksum, --checksum   Use GNU checksum (32-bits CRC)
    --md5, --md5sum              Use MD5 checksum
    --sha1, --sha1sum            Use SHA-1 checksum
    --sha224, --sha224sum        Use SHA-224 checksum
    --sha256, --sha256sum        Use SHA-256 checksum
    --sha384, --sha384sum        Use SHA-384 checksum
    --sha512, --sha512sum        Use SHA-512 checksum
```

### Compare files

    $ becat compare [<options>] <file>...

Available options:

```
-b, --bytes, --blocksize <size>  Bytes per block
-c, --color, --color-scheme <n>  Color scheme (0, 1, 2)
    --no-color                   No-color mode (same as --color-scheme 0)
    --dec, --decimal             Show dec representation of number
    --no-dec, --no-decimal       Don't show dec representation of number
    --hex, --hexadecimal         Show hex representation of number
    --no-hex, --no-hexadecimal   Don't show hex representation of number
    --oct, --octal               Show oct representation of number
    --no-oct, --no-octal         Don't show oct representation of number
    --bsd, --bsd-checksum        Use BSD checksum (16-bits CRC)
    --sysv, --sysv-checksum      Use SysV checksum (16-bits CRC)
    --crc, --cksum, --checksum   Use GNU checksum (32-bits CRC)
    --md5, --md5sum              Use MD5 checksum
    --sha1, --sha1sum            Use SHA-1 checksum
    --sha224, --sha224sum        Use SHA-224 checksum
    --sha256, --sha256sum        Use SHA-256 checksum
    --sha384, --sha384sum        Use SHA-384 checksum
    --sha512, --sha512sum        Use SHA-512 checksum
```
