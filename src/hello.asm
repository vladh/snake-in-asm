bits 64
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .data

board_height dq 15
board_width dq 30
newline db 0xd, 0xa, 0
board_icon_empty db ".", 0
board_icon_test db "!", 0
board_icon_head db "O", 0
fmt_number db "%d", 0xd, 0xa, 0
fmt_string db "%s", 0xd, 0xa, 0
seq_clear db 0x1b, 0x5b, "2J", 0
seq_pos db 0x1b, 0x5b, "%d;%dH", 0
seq_blue db 0x1b, 0x5b, "34m", 0
seq_reset db 0x1b, 0x5b, "0m", 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .text

global main

extern ExitProcess
extern _CRT_INIT
extern printf


clear_board:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  mov rcx, seq_clear
  call printf

  mov rsp, rbp
  pop rbp
  ret



print_char: ; (x, y, char)
.char equ 32
  push rbp
  mov rbp, rsp
  sub rsp, 64

  mov [rsp + .char], r8

  mov rdx, rcx
  mov r8, rdx
  mov rcx, seq_pos
  call printf

  mov rcx, [rsp + .char]
  call printf

  mov rsp, rbp
  pop rbp
  ret



print_board:
.r12_storage equ 32
.r13_storage equ 40
  push rbp
  mov rbp, rsp
  sub rsp, 32

  mov rcx, fmt_number
  mov rdx, [rbp + 16]
  call printf

  mov [rsp + .r12_storage], r12
  mov [rsp + .r13_storage], r13

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

  mov r12, [rsp + .r12_storage]
  mov r13, [rsp + .r13_storage]
  mov rsp, rbp
  pop rbp
  ret


main:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  call _CRT_INIT

  call clear_board

  mov rcx, 10
  mov rdx, 10
  mov r8, board_icon_test
  call print_char

  mov rcx, 2
  mov rdx, 2
  mov r8, board_icon_head
  call print_char

  ; push 5
  ; call print_board
  ; add rsp, 8 ; pop

  xor rax, rax
  mov rsp, rbp
  pop rbp
  call ExitProcess
