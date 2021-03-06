bits 64
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .rodata

BOARD_HEIGHT dq 15
BOARD_WIDTH dq 30
NEWLINE db 0xd, 0xa, 0
BOARD_ICON_EMPTY db ".", 0
BOARD_ICON_FOOD db "*", 0
BOARD_ICON_HEAD db "O", 0
FMT_NUMBER db "%d", 0xd, 0xa, 0
FMT_CHAR db "%c", 0xd, 0xa, 0
FMT_STRING db "%s", 0xd, 0xa, 0
SEQ_CLEAR db 0x1b, 0x5b, "2J", 0
SEQ_POS db 0x1b, 0x5b, "%d;%dH", 0
SEQ_BLUE db 0x1b, 0x5b, "34m", 0
SEQ_RESET db 0x1b, 0x5b, "0m", 0
STD_INPUT_HANDLE dq -10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .text

global main

; HANDLE WINAPI GetStdHandle(
;   _In_ DWORD nStdHandle
; );
extern GetStdHandle

; BOOL WINAPI ReadFile(
;   _In_        HANDLE       hFile,
;   _Out_       LPVOID       lpBuffer,
;   _In_        DWORD        nNumberOfBytesToRead,
;   _Out_opt_   LPDWORD      lpNumberOfBytesRead,
;   _Inout_opt_ LPOVERLAPPED lpOverlapped
; );
extern ReadFile

; VOID WINAPI ExitProcess(
;   _In_ UINT uExitCode
; );
extern ExitProcess

extern _CRT_INIT
extern printf


read_char:
.char equ 16
.nBytesRead equ 24
  push rbp
  mov rbp, rsp
  sub rsp, 64

  mov rcx, [STD_INPUT_HANDLE]
  call GetStdHandle

  mov rcx, rax ; hFile
  lea rdx, [rbp + .char] ; lpBuffer
  mov r8, 1 ; nNumberOfBytesToRead
  lea r9, [rbp + .nBytesRead] ; lpNumberOfBytesRead
  mov qword [rsp + 32], 0 ; lpOverlapped
  call ReadFile

  mov rcx, FMT_CHAR
  mov rdx, [rbp + 16]
  call printf

  mov rsp, rbp
  pop rbp
  ret


clear_board:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  mov rdx, 0
  mov r8, 0
  mov rcx, SEQ_POS
  call printf

  mov rcx, SEQ_CLEAR
  call printf

  mov rsp, rbp
  pop rbp
  ret



print_char: ; (x, y, char)
.char equ 16
  push rbp
  mov rbp, rsp
  sub rsp, 32

  mov [rbp + .char], r8

  mov rdx, rcx
  mov r8, rdx
  mov rcx, SEQ_POS
  call printf

  mov rcx, [rbp + .char]
  call printf

  mov rsp, rbp
  pop rbp
  ret



print_board:
.r12_storage equ 16
.r13_storage equ 24
  push rbp
  mov rbp, rsp
  sub rsp, 32

  mov [rsp + .r12_storage], r12
  mov [rsp + .r13_storage], r13

  xor r12, r12
  .height_loop:
    cmp r12, [BOARD_HEIGHT]
    je .end_height_loop

    xor r13, r13
    .width_loop:
      cmp r13, [BOARD_WIDTH]
      je .end_width_loop

      mov rcx, BOARD_ICON_EMPTY
      call printf

      inc r13
      jmp .width_loop
    .end_width_loop:

    mov rcx, NEWLINE
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
.head_x equ 32
.head_y equ 40
.food_x equ 48
.food_y equ 56
  push rbp
  mov rbp, rsp
  sub rsp, 64

  mov byte [rsp + .head_x], 3
  mov byte [rsp + .head_y], 3
  mov byte [rsp + .food_x], 10
  mov byte [rsp + .food_x], 10

  call _CRT_INIT
  call clear_board
  call print_board

  mov rcx, [rsp + .food_x] ; x
  mov rdx, [rsp + .food_y] ; y
  mov r8, BOARD_ICON_FOOD ; char
  call print_char

  mov rcx, [rsp + .head_x] ; x
  mov rdx, [rsp + .head_y] ; y
  mov r8, BOARD_ICON_HEAD ; char
  call print_char

  mov rdx, 0
  mov r8, 0
  mov rcx, SEQ_POS
  call printf

  call read_char

  mov rsp, rbp
  pop rbp
  xor rax, rax
  call ExitProcess
