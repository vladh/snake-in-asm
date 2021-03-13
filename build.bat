@echo off

if not defined DevEnvDir (
  call vcvarsall x64
)

echo Compiling...

nasm -f win64 -gcv8 -l obj/snake.lst -o obj/snake.obj src/snake.asm

echo Linking...

link obj/snake.obj ^
/subsystem:console ^
/entry:main ^
/out:bin/snake.exe ^
/defaultlib:ucrt.lib ^
/defaultlib:msvcrt.lib ^
/defaultlib:legacy_stdio_definitions.lib ^
/defaultlib:Kernel32.lib ^
/defaultlib:Shell32.lib ^
/defaultlib:User32.lib ^
/nologo ^
/incremental:no ^
/opt:noref ^
/debug ^
/pdb:"bin\snake.pdb"
