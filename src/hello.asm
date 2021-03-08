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

segment .data
g_std_handle dd 0

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

; void Sleep(
;   DWORD dwMilliseconds
; );
extern Sleep

; BOOL WINAPI GetNumberOfConsoleInputEvents(
;   _In_  HANDLE  hConsoleInput,
;   _Out_ LPDWORD lpcNumberOfEvents
; );
extern GetNumberOfConsoleInputEvents

extern _CRT_INIT
extern printf


setup_input:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  ; Get the standard input handle
  mov rcx, [STD_INPUT_HANDLE] ; nStdHandle
  call GetStdHandle
  mov [g_std_handle], rax

  ; Disable all input modes
  ; This means the typed character won't be printed, and we also will not
  ; wait for an <Enter> after it.
  mov rcx, [g_std_handle] ; hConsoleHandle
  mov rdx, 0 ; dwMode
  call SetConsoleMode

  mov rsp, rbp
  pop rbp
  ret


read_char:
; rbp +
.char equ 16
.nBytesRead equ 24
.nEvents equ 32
; rsp +
.scratch equ 32
  push rbp
  mov rbp, rsp
  sub rsp, 64

  ; Get the number of input events
  mov rcx, [g_std_handle]
  lea rdx, [rbp + .nEvents]
  call GetNumberOfConsoleInputEvents

  cmp byte [rbp + .nEvents], 0
  je .done_reading

  ; Read the character
  mov rcx, [g_std_handle] ; hFile
  lea rdx, [rbp + .char] ; lpBuffer
  mov r8, 1 ; nNumberOfBytesToRead
  lea r9, [rbp + .nBytesRead] ; lpNumberOfBytesRead
  mov qword [rsp + .scratch], 0 ; lpOverlapped
  call ReadFile

  .done_reading:

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
.dir_x equ 64
.dir_y equ 52
  push rbp
  mov rbp, rsp
  sub rsp, 128

  call _CRT_INIT

  ; Clear board and setup input
  call clear_board
  call setup_input

  ; Init data
  mov byte [rsp + .head_x], 10
  mov byte [rsp + .head_y], 3
  mov byte [rsp + .food_x], 10
  mov byte [rsp + .food_x], 5
  mov byte [rsp + .dir_x], 1
  mov byte [rsp + .dir_y], 0

  .loop:
    ; Reset position to 0, 0
    mov rdx, 0
    mov r8, 0
    mov rcx, SEQ_POS
    call printf

    ; Print board
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

    ; Move snake
    xor rcx, rcx
    add rcx, [rsp + .dir_x]
    add rcx, [rsp + .head_x]
    mov [rsp + .head_x], rcx
    xor rcx, rcx
    add rcx, [rsp + .dir_y]
    add rcx, [rsp + .head_y]
    mov [rsp + .head_y], rcx

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
    ; dec byte [rsp + .head_y]
    jmp .end_input

    .action_down:
    ; inc byte [rsp + .head_y]
    jmp .end_input

    .action_left:
    ; dec byte [rsp + .head_x]
    jmp .end_input

    .action_right:
    ; inc byte [rsp + .head_x]
    jmp .end_input

    .action_quit:
    jmp .end_loop

    .end_input:

    mov rcx, 50
    call Sleep
    jmp .loop
  .end_loop:

  call clear_board

  xor rax, rax
  mov rsp, rbp
  pop rbp
  call ExitProcess
