# DungeonRush in Zig!

![](screenshot.gif)

This is a near exact **Zig port** of the [original DungeonRush `C-based`](https://github.com/rapiz1/DungeonRush) rogue-like game running on SDL2 originally developed by @rapiz1.

## Port Goals
* To re-create a moderately complex game, fully in Zig and to get better at the language.
* To make this port faithful to the original, while being more idiomatic.
* To identify and fix any *possible* undefined behaviors or bugs that the Zig compiler catches or
  that myself or other contributors catch.
* To ensure the game is as fast and responsive as the original project.
* To fully eradicate all original C-based files and C-based build scripts.
* To port in phases:
  1. Phase 1: port the C code almost as-is to minimize bugs introduced
      * Still using `c.malloc`/`c.free` in many cases, most cases don't check for null (alloc failure)
      * A few cases are using callbacks using the `callconv(.C)` for `c.qsort`
      * Still using multi-pointers or a few `[*c]` style pointers
  2. Phase 2: Ziggify
      * Use proper Zig `allocators` instead of `c.malloc`/`c.free`
      * Move away from `c_int` or C specific types
      * Favor slices over multi-pointers, remove any pointer arithmetic.
      * Use more of Zig's stdlib for logging, file-io, etc.
      * Utilize `defer`/`errdefer` for effective cleanup
      * Migrate to a Zig-based SDL wrapper, for a nicer SDL experience.
      * Ensure all errors are accounted for, utilize `try`
      * Use build.zig.zon
      * Setup Github to build the project regularly
  3. Phase 3: Code Clean-up/Refactor
      * Remove duplicate code
      * Make code even more idiomatic for Zig
      * Make the code more maintainable
      * Use less globals
      * Fix namespace issues
      * Remove redundant naming like some enumerations have their container name as the prefix
      * Use some Zig based collections like the `generic` LinkList over the original C ADT style.
      * Bonus: Introduce unit-tests
      * Get building for other OSes (w/ community contributions)

## A twist on classic Snake
* DungeonRush is a pretty fun project/game.
  * It's a twist on Snake
  * It uses cellular automata to generate random dungeon levels
  * It has weapons, buffs, enemies, bosses and loot drops
  * It features classic pixel art and animations
  * Don't forget 8-bit style music and sound-fx

## Source
  * zrc/ - Ziglang port (by @deckarep)
  * src/ - C-based version (original by @rapiz1)

## Installing and Running
  * Built and tested against [Zig 0.13.0](https://ziglang.org/documentation/0.13.0/) release
  * Ensure SDL2 is installed for your OS/Platform
  * From the root folder: `zig build run`

## Contributions
Want to hack on this project with me? I will welcome all contributions that improve the code while keeping it faithful to the original DungeonRush project. I'd like the game to look and run identical. I'd like help with the phases outlined above. There's plenty of low-hanging fruit that is relevant to beginners and experienced a-like.

However, code will be rejected that needlessly complicates the game or does not run identical to the original C project.

If people want to change the overall look and feel or game logic, please fork DungeonRush and change it however you like!

## Callouts
* Zig doesn't have `do/while` so they've all been replaced with `while` with a break on a `negated` condition.
* Before anyone complains about the port looking like ugly Zig code written like C, this is why I'm taking a multi-phase approach. If you've ever done migrations, changing too many things at once introduces bugs, especially when tests don't exist.
* All original development was done on Apple MacOS Silcon, contributions are welcome for other OSes.
* The game has some multi-player networking code, I don't care about it at the moment so it's not done.