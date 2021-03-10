bits 64
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .rodata

BOARD_HEIGHT equ 30
BOARD_WIDTH equ 45
NEWLINE db 0xd, 0xa, 0
BOARD_ICON_EMPTY db ". ", 0
BOARD_ICON_FOOD db "* ", 0
BOARD_ICON_HEAD db "O ", 0
FMT_INT db "%d", 0xd, 0xa, 0
FMT_SHORT db "%hd", 0xd, 0xa, 0
FMT_UINT db "%u", 0xd, 0xa, 0
FMT_CHAR db "%c", 0xd, 0xa, 0
FMT_STRING db "%s", 0xd, 0xa, 0
FMT_SCORE db "Score: %d", 0xd, 0xa, 0
SEQ_CLEAR db 0x1b, 0x5b, "2J", 0
SEQ_POS db 0x1b, 0x5b, "%d;%dH", 0
SEQ_BLUE db 0x1b, 0x5b, "34m", 0
SEQ_RESET db 0x1b, 0x5b, "0m", 0
SEQ_HIDE_CURSOR db 0x1b, 0x5b, "?25l", 0
SEQ_SHOW_CURSOR db 0x1b, 0x5b, "?25h", 0
SEQ_USE_ALT_BUFFER db 0x1b, 0x5b, "?1049h", 0
SEQ_USE_MAIN_BUFFER db 0x1b, 0x5b, "?1049l", 0
STD_INPUT_HANDLE dq -10
INPUT_UP db "w"
INPUT_DOWN db "s"
INPUT_LEFT db "a"
INPUT_RIGHT db "d"
INPUT_QUIT db "q"
VKEY_W equ 0x57
VKEY_A equ 0x41
VKEY_S equ 0x53
VKEY_D equ 0x44
VKEY_Q equ 0x51
DIR_UP equ 1
DIR_DOWN equ 2
DIR_LEFT equ 3
DIR_RIGHT equ 4
KEY_DOWN_VALUE equ 0b1000000000000000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .data
g_std_handle dq 0
g_head_x dq 10
g_head_y dq 10
g_food_x dq 10
g_food_y dq 5
g_dir dq 4 ; right
g_score dq 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .text

global main

; HANDLE WINAPI GetStdHandle(
;   _In_ DWORD nStdHandle
; );
extern GetStdHandle

; BOOL WINAPI FlushConsoleInputBuffer(
;   _In_ HANDLE hConsoleInput
; );
extern FlushConsoleInputBuffer

; VOID WINAPI ExitProcess(
;   _In_ UINT uExitCode
; );
extern ExitProcess

; void Sleep(
;   DWORD dwMilliseconds
; );
extern Sleep

; SHORT GetAsyncKeyState(
;   int vKey
; );
extern GetAsyncKeyState

; _Post_equals_last_error_ DWORD GetLastError();
extern GetLastError

extern _CRT_INIT
extern printf


setup_input:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  ; Use alternate buffer
  mov rcx, SEQ_USE_ALT_BUFFER
  call printf

  ; Get the standard input handle
  mov rcx, [STD_INPUT_HANDLE] ; nStdHandle
  call GetStdHandle
  mov [g_std_handle], rax

  ; Hide the cursor
  mov rcx, SEQ_HIDE_CURSOR
  call printf

  mov rsp, rbp
  pop rbp
  ret


reset_input:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  ; Flush buffer so we don't get a bunch of characters printed
  ; This is apparently bad/deprecated, but do we care? No!
  mov rcx, [g_std_handle]
  call FlushConsoleInputBuffer

  ; Switch back to main buffer
  mov rcx, SEQ_USE_MAIN_BUFFER
  call printf

  mov rsp, rbp
  pop rbp
  ret


clear_screen:
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

  ; Reset position to 0, 0
  mov rdx, 0
  mov r8, 0
  mov rcx, SEQ_POS
  call printf

  mov [rbp + .r12_storage], r12
  mov [rbp + .r13_storage], r13

  xor r12, r12
  .height_loop:
    cmp r12, BOARD_HEIGHT
    je .end_height_loop

    xor r13, r13
    .width_loop:
      cmp r13, BOARD_WIDTH
      je .end_width_loop

      .maybe_print_head:
      cmp r13, [g_head_x]
      jne .maybe_print_food
      cmp r12, [g_head_y]
      jne .maybe_print_food
      mov rcx, BOARD_ICON_HEAD
      call printf
      jmp .end_print

      .maybe_print_food:
      cmp r13, [g_food_x]
      jne .print_empty
      cmp r12, [g_food_y]
      jne .print_empty
      mov rcx, BOARD_ICON_FOOD
      call printf
      jmp .end_print

      .print_empty:
      mov rcx, BOARD_ICON_EMPTY
      call printf
      jmp .end_print

      .end_print:

      inc r13
      jmp .width_loop
    .end_width_loop:

    mov rcx, NEWLINE
    call printf

    inc r12
    jmp .height_loop
  .end_height_loop:

  ; Print score
  mov rdx, 0
  mov r8, (BOARD_WIDTH * 2) + 2
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_SCORE
  mov rdx, [g_score]
  call printf

  mov r12, [rbp + .r12_storage]
  mov r13, [rbp + .r13_storage]
  mov rsp, rbp
  pop rbp
  ret


reposition_fruit:
  rdtsc
  xor edx, edx
  mov ecx, BOARD_WIDTH
  div ecx
  mov [g_food_x], edx

  rdtsc
  xor edx, edx
  mov ecx, BOARD_HEIGHT
  div ecx
  mov [g_food_y], edx

  ret


reposition_head:
  rdtsc
  xor edx, edx
  mov ecx, BOARD_WIDTH
  div ecx
  mov [g_head_x], edx

  rdtsc
  xor edx, edx
  mov ecx, BOARD_HEIGHT
  div ecx
  mov [g_head_y], edx

  ret


update_game_data:
  ; Move snake
  cmp byte [g_dir], DIR_UP
  jne .check_down
  sub byte [g_head_y], 1

  .check_down:
  cmp byte [g_dir], DIR_DOWN
  jne .check_left
  add byte [g_head_y], 1

  .check_left:
  cmp byte [g_dir], DIR_LEFT
  jne .check_right
  sub byte [g_head_x], 1

  .check_right:
  cmp byte [g_dir], DIR_RIGHT
  jne .end_checks
  add byte [g_head_x], 1

  .end_checks:

  ; Check if we ate fruit
  mov rcx, [g_head_x]
  cmp rcx, [g_food_x]
  jne .end_eat
  mov rcx, [g_head_y]
  cmp rcx, [g_food_y]
  jne .end_eat
  call reposition_fruit
  inc qword [g_score]
  jmp .end_eat

  .end_eat:

  ret


main:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  call _CRT_INIT

  call clear_screen
  call setup_input
  call reposition_fruit
  ; call reposition_head

  .loop:
    ; Print board
    call print_board
    call update_game_data

    ; Check keys pressed
    mov rcx, VKEY_W
    call GetAsyncKeyState
    and rax, KEY_DOWN_VALUE
    cmp rax, 0
    jne .action_up

    mov rcx, VKEY_S
    call GetAsyncKeyState
    and rax, KEY_DOWN_VALUE
    cmp rax, 0
    jne .action_down

    mov rcx, VKEY_A
    call GetAsyncKeyState
    and rax, KEY_DOWN_VALUE
    cmp rax, 0
    jne .action_left

    mov rcx, VKEY_D
    call GetAsyncKeyState
    and rax, KEY_DOWN_VALUE
    cmp rax, 0
    jne .action_right

    mov rcx, VKEY_Q
    call GetAsyncKeyState
    and rax, KEY_DOWN_VALUE
    cmp rax, 0
    jne .action_quit

    jmp .end_input

    .action_up:
    mov byte [g_dir], 1
    jmp .end_input

    .action_down:
    mov byte [g_dir], 2
    jmp .end_input

    .action_left:
    mov byte [g_dir], 3
    jmp .end_input

    .action_right:
    mov byte [g_dir], 4
    jmp .end_input

    .action_quit:
    jmp .end_loop

    .end_input:

    mov rcx, 50
    call Sleep
    jmp .loop
  .end_loop:

  ; call clear_screen
  call reset_input

  .end:

  xor rax, rax
  mov rsp, rbp
  pop rbp
  call ExitProcess
