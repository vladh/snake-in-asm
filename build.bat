nasm -f win64 -o obj/hello_world.obj src/hello_world.asm

link obj/hello_world.obj ^
/subsystem:console ^
/entry:main ^
/out:bin/hello_world_basic.exe ^
kernel32.lib legacy_stdio_definitions.lib msvcrt.lib
