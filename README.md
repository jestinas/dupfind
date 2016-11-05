# Dupfind

Shell script to find duplicate files in one or multiple directory subtrees.

## How it works

The tool uses multiple filters on the input file list:

* First the files are grouped by their file length.
* Then the files are grouped by their SHA1/MD5 checksum.
* After that, only same files that equal in their bytes are let thru.
* In the end, a shell command to delete the superfluous files is print out.

Dupfind will *not* delete a file itself. It will output instead an executable shell script to
delete the duplicates yourself. It's your responsibility to check what is going to be
deleted.

You can select a selection and a removal strategy. These topics will be covered in
the next subsections.

### Selection strategy

The selection strategy defines which file to *keep* when you have duplicates.

The built-in strategies will return the following results:
* FIRST: Keep the first file that was seen by "find".
* SHORTESTPATH: Keep the file with the shortest file path when counting the characters.
* LONGESTPATH: Similar to SHORTESTPATH, but keeps the file with the longest path.

### Removal strategy

The removal strategy defines the line to be printed when a file is found to be
a duplicate and to be removed.
* RM: Output a "rm -f" command.
* LN: Output a "ln -f" command for creating a hard link. Only works with Unix filesystems.
* LNS: Output a "ln -sf" command for creating a symbolic link. Only works on Unix filesystems.

## Command line options

The command line options are as follows:

    $ ./dupfind.sh -h
    dupfind.sh (C) 2007-2016 S.Fuhrmann <s_fuhrm@gmx.de>
    
    	-h...This command line help
    	-v...Verbose progress output
    	-d...Debug the script (only for development)
    	-r...Removal strategy: One of RM (default), LNS, LN or NOP
    	-s...Selection strategy: One of FIRST, SHORTESTPATH, LONGESTPATH
    	-U...Unsafe comparison, but faster operation (only md5sum message digest comparison)

The other arguments passed to the command line are treated as directories to scan.

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

