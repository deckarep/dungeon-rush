// NOTE: This file exists purely for bridge from Zig.
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "res.h"
#include "game.h"
#include "ui.h"
#include "prng.h"

#ifdef DBG
#include <assert.h>
#endif

// cmain is the bridge for zig to build.
#pragma clang diagnostic ignored "-Wunused-parameter"
extern int cmain(char** args, int argc) {
  
  //R.C. Unused.
  //printf("argc %d\n", argc);
  //printf("args %p\n", *args);
  
  prngSrand(time(NULL));
  // Start up SDL and create window
  if (!init()) {
    printf("Failed to initialize!\n");
  } else {
    // Load media
    if (!loadMedia()) {
      printf("Failed to load media!\n");
    } else {
      mainUi();
    }
  }
  cleanup();

  return 0;
}

extern int add(int a, int b){
    return a + b;
}
