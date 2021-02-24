@echo off

if not defined DevEnvDir (
  call vcvarsall x64
)

echo Compiling...

nasm -f win64 -gcv8 -l obj/hello.lst -o obj/hello.obj src/hello.asm

echo Linking...

link obj/hello.obj ^
/subsystem:console ^
/entry:main ^
/out:bin/hello.exe ^
/defaultlib:ucrt.lib ^
/defaultlib:msvcrt.lib ^
/defaultlib:legacy_stdio_definitions.lib ^
/defaultlib:Kernel32.lib ^
/defaultlib:Shell32.lib ^
/nologo ^
/incremental:no ^
/opt:noref ^
/debug ^
/pdb:"obj\hello.pdb"
