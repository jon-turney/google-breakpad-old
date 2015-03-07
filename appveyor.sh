#!/bin/sh
set -e

srcdir=`dirname "$0"`
test -z "$srcdir" && srcdir=.
ORIGDIR=`pwd`
cd "$srcdir"

echo fetching externals...
./fetch-externals
patch -N -d src/testing/gtest -p1 <0001-Fix-building-gtest-for-Windows-with-Werror-unused-va.patch || true

echo autoreconf running...
autoreconf -fvi

if [ -z $HOST ] ; then
    HOST=$(autotools/config.guess)
    AR="ar"
else
    AR=${HOST}-ar
fi

echo configure running...
cd "$ORIGDIR"
"$srcdir"/configure --prefix=/usr --enable-silent-rules --host=${HOST}

echo make running...
make

echo make install running...
make install DESTDIR=./staging
# Makefile made by gyp doesn't have an install target, so make up for that deficiency
${AR} -M <<EOF
CREATE ./staging/usr/lib/libbreakpad_client.a
ADDLIB $srcdir/src/out/Debug/obj.target/client/windows/crash_generation/libcrash_generation_client.a
ADDLIB $srcdir/src/out/Debug/obj.target/client/windows/crash_generation/libcrash_generation_server.a
ADDLIB $srcdir/src/out/Debug/obj.target/client/windows/handler/libexception_handler.a
ADDLIB $srcdir/src/out/Debug/obj.target/client/windows/libcommon.a
ADDLIB $srcdir/src/out/Debug/obj.target/client/windows/sender/libcrash_report_sender.a
SAVE
END
EOF
cp -a ./breakpad-client.pc ./staging/usr/lib/pkgconfig/
cp -a $srcdir/src/out/Debug/crash_generation_app.exe ./staging/usr/bin/

# takes too long to run for appveyor
if [ ! $APPVEYOR ] ; then
  echo make check running...
  export PATH=/usr/${HOST}/sys-root/mingw/bin/:$PATH
  make check
fi
