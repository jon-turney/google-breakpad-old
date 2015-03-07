# Breakpad for Cygwin/MinGW

[![Build status](https://ci.appveyor.com/api/projects/status/7ipva2m4gq5lr4k0/branch/pecoff-dwarf-on-svn-rev-1434?svg=true)](https://ci.appveyor.com/project/jon-turney/google-breakpad)

google-breakpad with support added for PE/COFF executables with DWARF debugging
information, as used by Cygwin/MinGW

## Compiling

### Preparation

Run the fetch-externals script to fetch submodules in the DEPS file (e.g the gyp and gtest dependencies).
(The upsteam repository is meant to be checked out using Chromium's depot_tools, which does that)

```
./fetch-externals
```

Run autoreconf to generate ./configure

````
autoreconf -fvi
````

### Compiling

See README

````
./configure && make
````

will produce dump\_syms, minidump\_dump, minidump\_stackwalk, libbreakpad.a
and for MinGW libcrash\_generation_client.a, libcrash\_generation_server.a, crash\_generation_app.exe

## Using

See http://code.google.com/p/google-breakpad/wiki/GettingStartedWithBreakpad

### Producing and installing symbols

````
dump_syms crash_generation_app.exe >crash_generation_app.sym
FILE=`head -1 crash_generation_app.sym | cut -f5 -d' '`
BUILDID=`head -1 crash_generation_app.sym | cut -f4 -d' '`
SYMBOLPATH=/symbols/${FILE}/${BUILDID}/
mdir -p ${SYMBOLPATH}
mv crash_generation_app.sym ${SYMBOLPATH}
````

### Generating a minidump file

A small test application demonstrating out-of-process dumping called
crash\_generation\_app.exe is built.

- Run it once, selecting "Server->Start" from the menu
- Run it again, selecting "Client->Deref zero"
- Client should crash, and a .dmp is written to C:\Dumps\

### Processing the minidump to produce a stack trace

````
minidump_stackwalk blah.dmp /symbols/
````

## Issues

### Lack of build-id

On Windows, the build-id takes the form of a CodeView record.
This build-id is captured for all modules in the process by MiniDumpWriteDump(),
and is used by the breakpad minidump processing tools to find the matching
symbol file.

See http://debuginfo.com/articles/debuginfomatch.html

I have implemented 'ld --build-id' for PE/COFF executables (See
https://sourceware.org/ml/binutils/2014-01/msg00296.html), but you must use a
sufficently recent version of binutils (2.25 or later) and build with
'-Wl,--build-id' (or a gcc configured with '--enable-linker-build-id', which
turns that flag on by default) to enable that.

A tool could be written to add a build-id to existing PE/COFF executables, but in
practice this turns out to be quite tricky...

### Symbols from a PDB or the Microsoft Symbol Server

<a href="http://hg.mozilla.org/users/tmielczarek_mozilla.com/fetch-win32-symbols">
symsrv_convert</a> and dump_syms for PDB cannot be currently built with MinGW,
because they require the MS DIA (Debug Interface Access) SDK (which is only in
paid editions of Visual Studio) and the DIA SDK uses ATL.

An alternate PDB parser is available at https://github.com/luser/dump_syms, but
that also needs some work before it can be built with MinGW.
