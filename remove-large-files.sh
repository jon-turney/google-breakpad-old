#!/bin/sh
#
# svn r1403 contains a 185MB libchromeshell.so.sym, which  is larger than github permits
# this is the script used to remove that from the git repo
#

git filter-branch -f --tree-filter 'rm -f src/processor/testdata/symbols/microdump/libchromeshell.so/76304586D0CD2C8FF899C602BF1756A20/libchromeshell.so.sym' -- --all
