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
FMT_INT db "%d", 0xd, 0xa, 0
FMT_UINT db "%u", 0xd, 0xa, 0
FMT_CHAR db "%c", 0xd, 0xa, 0
FMT_STRING db "%s", 0xd, 0xa, 0
SEQ_CLEAR db 0x1b, 0x5b, "2J", 0
SEQ_POS db 0x1b, 0x5b, "%d;%dH", 0
SEQ_BLUE db 0x1b, 0x5b, "34m", 0
SEQ_RESET db 0x1b, 0x5b, "0m", 0
STD_INPUT_HANDLE dq -10
INPUT_UP db "w"
INPUT_DOWN db "s"
INPUT_LEFT db "a"
INPUT_RIGHT db "d"
INPUT_QUIT db "q"

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

; BOOL WINAPI SetConsoleMode(
;   _In_ HANDLE hConsoleHandle,
;   _In_ DWORD  dwMode
; );
extern SetConsoleMode

extern _CRT_INIT
extern printf


read_char:
.char equ 16
.nBytesRead equ 24
.handle equ 32
.scratch equ 40
  push rbp
  mov rbp, rsp
  sub rsp, 32

  ; Get the standard input handle
  mov rcx, [STD_INPUT_HANDLE] ; nStdHandle
  call GetStdHandle
  mov [rbp + .handle], rax

  ; Disable all input modes
  ; This means the typed character won't be printed, and we also will not
  ; wait for an <Enter> after it.
  mov rcx, rax ; hConsoleHandle
  mov rdx, 0 ; dwMode
  call SetConsoleMode

  ; Read the character
  mov rcx, [rbp + .handle] ; hFile
  lea rdx, [rbp + .char] ; lpBuffer
  mov r8, 1 ; nNumberOfBytesToRead
  lea r9, [rbp + .nBytesRead] ; lpNumberOfBytesRead
  mov qword [rbp + .scratch], 0 ; lpOverlapped
  call ReadFile

  mov rax, [rbp + .char]
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

  mov r8, rcx
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

  call _CRT_INIT

  ; Init positions
  mov byte [rsp + .head_x], 10
  mov byte [rsp + .head_y], 3
  mov byte [rsp + .food_x], 10
  mov byte [rsp + .food_x], 5

  .loop:
    ; Clear and print board
    call clear_board
    call print_board

    ; Print food
    mov rcx, [rsp + .food_x] ; x
    mov rdx, [rsp + .food_y] ; y
    mov r8, BOARD_ICON_FOOD ; char
    call print_char

    ; Print head
    mov rcx, [rsp + .head_x] ; x
    mov rdx, [rsp + .head_y] ; y
    mov r8, BOARD_ICON_HEAD ; char
    call print_char

    ; Reset position to 0, 0
    mov rdx, 0
    mov r8, 0
    mov rcx, SEQ_POS
    call printf

    ; Read character
    call read_char

    ; Do something with character
    cmp al, [INPUT_UP]
    je .action_up
    cmp al, [INPUT_DOWN]
    je .action_down
    cmp al, [INPUT_LEFT]
    je .action_left
    cmp al, [INPUT_RIGHT]
    je .action_right
    cmp al, [INPUT_QUIT]
    je .action_quit
    jmp .end_input

    .action_up:
    dec byte [rsp + .head_y]
    jmp .end_input

    .action_down:
    inc byte [rsp + .head_y]
    jmp .end_input

    .action_left:
    dec byte [rsp + .head_x]
    jmp .end_input

    .action_right:
    inc byte [rsp + .head_x]
    jmp .end_input

    .action_quit:
    jmp .end_loop

    .end_input:
    jmp .loop
  .end_loop:

  call clear_board

  xor rax, rax
  mov rsp, rbp
  pop rbp
  call ExitProcess
