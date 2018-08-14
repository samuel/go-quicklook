#!/bin/bash

set -e

if [[ -e "build" ]]; then
    rm -r build
fi
mkdir build
clang -O3 -Wall -DNDEBUG -Winvalid-pch -m64 -msse4.2 -c -o main.o q/main.c
go build -buildmode c-archive
clang -bundle -lobjc -framework Foundation -framework AppKit -framework QuickLook -o RetroLook retrolook.a main.o
cp -r RetroLook.qlgenerator build/
cp RetroLook build/RetroLook.qlgenerator/Contents/MacOS/
cp -r build/RetroLook.qlgenerator ~/Library/QuickLook/
rm main.o retrolook.a retrolook.h
