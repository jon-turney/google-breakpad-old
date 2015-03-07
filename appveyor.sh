#!/bin/sh
set -e
echo fetching svn externals
./fetch-svn-externals
echo autoreconf running...
autoreconf -fvi
HOST=${HOST:-$(autotools/config.guess)}
echo configure running...
./configure --prefix=/usr --enable-silent-rules --host=${HOST}
echo make running...
make
echo make install running...
make install DESTDIR=./staging
# Makefile made by gyp doesn't have an install target, so make up for that deficiency
${HOST}-ar -M <<EOF
CREATE ./staging/usr/lib/libbreakpad_client.a
ADDLIB ./src/out/Debug/obj.target/client/windows/crash_generation/libcrash_generation_client.a
ADDLIB ./src/out/Debug/obj.target/client/windows/crash_generation/libcrash_generation_server.a
ADDLIB ./src/out/Debug/obj.target/client/windows/handler/libexception_handler.a
ADDLIB ./src/out/Debug/obj.target/client/windows/libcommon.a
ADDLIB ./src/out/Debug/obj.target/client/windows/sender/libcrash_report_sender.a
SAVE
END
EOF
cp -a ./breakpad-client.pc ./staging/usr/lib/pkgconfig/
cp -a ./src/out/Debug/crash_generation_app.exe ./staging/usr/bin/
