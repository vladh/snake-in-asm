bits 64
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .data

list dq 1, 2, 3, 4, 5
list_len dq 5
fmt_list_item db "%d ", 0
fmt_list_end db ".", 0xd, 0xa, 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .text

global main

extern ExitProcess
extern _CRT_INIT
extern printf

main:
  push    rbp
  mov     rbp, rsp
  sub     rsp, 32

  push rbx

  call    _CRT_INIT

  xor     rbx, rbx

.start_loop:

  cmp     rbx, [list_len]
  je      .end_loop

  mov     rcx, fmt_list_item
  mov     rdx, rbx
  call    printf

  inc     rbx

  jmp     .start_loop

.end_loop:

  mov     rcx, fmt_list_end
  call    printf

  pop rbx

  xor     rax, rax
  call    ExitProcess
