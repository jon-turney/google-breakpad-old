# Breakpad for Cygwin/MinGW

google-breakpad with support added for PE/COFF executables with DWARF debugging
information, as used by Cygwin/MinGW

## Compiling

See README

Will produce dump\_syms, minidump\_dump, minidump\_stackwalk, libbreakpad.a

and for MinGW libcrash\_generation_client.a, libcrash\_generation_server.a, crash\_generation_app.exe

Note that since git-svn ignores svn externals, this repository is missing the
gyp and gtest dependencies.

## Using

See http://code.google.com/p/google-breakpad/wiki/GettingStartedWithBreakpad

### Producing and installing symbols

   dump\_syms crash\_generation\_app.exe >crash\_generation\_app.sym
   SYMBOLPATH= /symbols/`head -1 crash\_generation\_app.sym | cut -f5 -d' '`/`head -1 crash\_generation\_app.sym | cut -f4 -d' '`/
   mdir -p $(SYMBOLPATH)
   mv crash\_generation\_app.sym $(SYMBOLPATH)

### Generating a minidump file

A small test application demonstrating out-of-process dumping called
crash\_generation\_app.exe is built.

- Create C:\Dumps\
- Run it once, selecting "Server->Start" from the menu
- Run it again, selecting "Client->Deref zero"
- Client should crash, and a .dmp is written to C:\Dumps\

# Processing the minidump to produce a stack trace

minidump\_stackwalk blah.dmp /symbols

## Issues

### lack of build-id

Executables produced by Cygwin/MinGW gcc do not contain a build-id.

On Windows, this build-id takes the form of a CodeView record.

This build-id is captured for all modules in the process by MiniDumpWriteDump(),
and is used by the breakpad minidump processing tools to find the matching
symbol file.

See http://debuginfo.com/articles/debuginfomatch.html

Possible solutions:

* Implement 'ld --build-id' for PE/COFF executables (See https://sourceware.org/ml/binutils/2014-01/msg00296.html)
* Write a tool to add build-id to existing PE/COFF executables.  This turns out to be quite tricky...
