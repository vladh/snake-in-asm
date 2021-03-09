#include <windows.h>
#include <stdio.h>

int main() {
  while (TRUE) {
    if (GetAsyncKeyState(0x57) & 0x01) {
      printf("yes\n");
    } else {
      /* printf("no\n"); */
    }
  }

  return 0;
}
