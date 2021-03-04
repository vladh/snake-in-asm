bits 64
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .data

board_height dq 15
board_width dq 30
board_icon_empty db ".", 0
newline db 0xd, 0xa, 0
number_format db "%d", 0xd, 0xa, 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .text

global main

extern ExitProcess
extern _CRT_INIT
extern printf

print_board:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  mov rcx, number_format
  mov rdx, [rbp + 16]
  call printf

  push r12
  push r13

  xor r12, r12
  .height_loop:
    cmp r12, [board_height]
    je .end_height_loop

    xor r13, r13
    .width_loop:
      cmp r13, [board_width]
      je .end_width_loop

      mov rcx, board_icon_empty
      call printf

      inc r13
      jmp .width_loop
    .end_width_loop:

    mov rcx, newline
    call printf

    inc r12
    jmp .height_loop
  .end_height_loop:

  pop r13
  pop r12
  xor rax, rax
  mov rsp, rbp
  pop rbp
  ret

main:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  call _CRT_INIT

  push 5
  call print_board
  add rsp, 8 ; pop

  xor rax, rax
  mov rsp, rbp
  pop rbp
  call ExitProcess
