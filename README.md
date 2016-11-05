# Dupfind

Shell script to find duplicate files in one or multiple directory subtrees.

## How it works

The tool uses multiple filters on the input file list:

* First the files are grouped by their file length.
* Then the files are grouped by their SHA1/MD5 checksum.
* After that, only same files are let thru.
* In the end, a shell command to delete the superfluous files is print out.

Dupfind will not delete a file itself. It will give you an executable shell script to
delete the duplicates yourself. It's your responsibility to check what is going to be
deleted.

## Command line options

    $ ./dupfind.sh -h
    dupfind.sh (C) 2007-2016 S.Fuhrmann <s_fuhrm@gmx.de>
    
    	-h...This command line help
    	-v...Verbose progress output
    	-d...Debug the script (only for development)
    	-r...Removal strategy: One of RM (default), LNS, LN or NOP
    	-s...Selection strategy: One of FIRST, SHORTESTPATH, LONGESTPATH
    	-U...Unsafe comparison, but faster operation (only md5sum message digest comparison)

## Requirements

Requires the following Linux binaries that are normally installed in every installation:
* bash
* awk
* cmp
* find
* sort
* md5sum (or sha1sum)

The script could work with Cygwin, but it's not tested.

## License

The software is under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

