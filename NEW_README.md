# DungeonRush in Zig!

This is a near exact **Zig port** of the original DungeonRush `C-based` rogue-like game running on SDL2.

## Port Goals
* To re-create a moderately complex game fully in Zig to get better at Zig.
* To make this port faithful to the original, while being more idiomatic.
* To identify and fix any *possible* undefined behaviors that the Zig compiler catches.
* To fully eradicate all original C-based files and C build scripts.
* To port in phases!
  * Phase 1: port the C code almost as-is to minimize bugs introduced
      * Still using `c.malloc`/`c.free` in many cases
      * A few cases are using callbacks using the `callconv(.C)` for `c.qsort`
      * Still using multi-pointers or a few `[*c]` style pointers
  * Phase 2: Ziggify
      * Use proper Zig `allocators` instead of `c.malloc`/`c.free`
      * Move away from `c_int` or C specific types
      * Favor slices over multi-pointers, remove any pointer arithmetic.
      * Use more of Zig's stdlib for logging, fileio, etc.
      * Utilize `defer`/`errdefer` for effective cleanup
  * Phase 3: Code Clean-up/Refactor
      * Remove duplicate code
      * Make code more idiomatic for Zig
      * Make the code more maintainable
      * Use less globals
      * Fix namespace issues
      * Remove redundant naming like some enumerations have their container name still.
      * Use some Zig based collections like the `generic` LinkList
      * Introduce unit-tests

## Contributions
Want to hack on this project with me? I will welcome all contributions that improve the code while keeping it faithful to the original DungeonRush project. I'd like the game to look and run identical. I'd like help with the phases outlined above. 

However, code will be rejected that needlessly complicates the game or does not run identical to the original C project.

If people want to change the overall look and feel or game logic, please fork DungeonRush and change it however you like!

## Callouts
* Zig doesn't have `do/while` so they've all been replaced with `while` with a break on a `negated` condition.
* Before anyone complains about the port looking like ugly Zig code, this is why I'm taking a multi-phase approach.
* The original C-based code has no testing whatsoever, neither does the Zig currently.
* All original development was done on Apple MacOS Silcon, contributions are welcome for other OSes.
* The game has some multi-player networking code, I don't care about it at the moment so it's not ported.