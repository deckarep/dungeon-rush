# Compiles zig.
clear && zig build && mv zig-out/bin/dungeonrush-zig .
./fmt.sh