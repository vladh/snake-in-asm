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
BOARD_ICON_TAIL db "x ", 0
FMT_INT db "%d", 0xd, 0xa, 0
FMT_SHORT db "%hd", 0xd, 0xa, 0
FMT_UINT db "%u", 0xd, 0xa, 0
FMT_CHAR db "%c", 0xd, 0xa, 0
FMT_STRING db "%s", 0xd, 0xa, 0
FMT_SCORE db "Score: %d", 0xd, 0xa, 0
FMT_SPEED db "Speed: %d%%", 0xd, 0xa, 0
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
BASE_WAIT_TIME equ 50
MIN_WAIT_TIME equ 5
SPEED_INCREMENT equ 1
SNAKE_MAX_LENGTH equ 32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .data
g_std_handle dq 0
g_head_x dq 10
g_head_y dq 10
g_food_x dq 10
g_food_y dq 5
g_dir dq 4 ; right
g_score dq 0
g_speed dq 0
g_snake_length dq 0

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



print_board: ; (tail_addr)
; rbp +
.r12_storage equ 16
.r13_storage equ 24
.r14_storage equ 32
; rsp +
.tail_addr equ 32
  push rbp
  mov rbp, rsp
  sub rsp, 32 + 64

  mov [rbp + .r12_storage], r12
  mov [rbp + .r13_storage], r13
  mov [rbp + .r14_storage], r14
  mov [rsp + .tail_addr], rcx

  ; Reset position to 0, 0
  mov rdx, 0
  mov r8, 0
  mov rcx, SEQ_POS
  call printf

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
      jne .maybe_print_tail
      cmp r12, [g_food_y]
      jne .maybe_print_tail
      mov rcx, BOARD_ICON_FOOD
      call printf
      jmp .end_print

      .maybe_print_tail:
      mov r14, 0
      .loop_tail:
        cmp r14, [g_snake_length]
        je .end_tail_loop

        mov rax, r14
        xor edx, edx
        mov ecx, 16
        mul ecx ; [r14 (index)] * 16
        add rax, [rsp + .tail_addr]
        cmp r13, [rax]
        jne .no_tail_match
        add rax, 8
        cmp r14, [rax]
        jne .no_tail_match
        mov rcx, BOARD_ICON_TAIL
        call printf
        .no_tail_match:
        inc r14

      .end_tail_loop:

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

  ; Print speed
  mov rdx, 2
  mov r8, (BOARD_WIDTH * 2) + 2
  mov rcx, SEQ_POS
  call printf

  ; Get speed percentage out of the max speed
  mov eax, [g_speed]
  mov ecx, 100
  mul ecx

  xor edx, edx
  mov ecx, BASE_WAIT_TIME - MIN_WAIT_TIME
  div ecx

  mov rcx, FMT_SPEED
  mov edx, eax
  call printf

  mov r12, [rbp + .r12_storage]
  mov r13, [rbp + .r13_storage]
  mov r13, [rbp + .r14_storage]
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


update_game_data: ; (tail_addr)
  mov r8, rcx

  ; Move snake
  cmp byte [g_dir], DIR_UP
  jne .check_down
  cmp byte [g_head_y], 0
  jne .move_up
  mov byte [g_head_y], BOARD_HEIGHT - 1
  jmp .end_checks
  .move_up:
  sub byte [g_head_y], 1
  jmp .end_checks

  .check_down:
  cmp byte [g_dir], DIR_DOWN
  jne .check_left
  cmp byte [g_head_y], BOARD_HEIGHT - 1
  jne .move_down
  mov byte [g_head_y], 0
  jmp .end_checks
  .move_down:
  add byte [g_head_y], 1
  jmp .end_checks

  .check_left:
  cmp byte [g_dir], DIR_LEFT
  jne .check_right
  cmp byte [g_head_x], 0
  jne .move_left
  mov byte [g_head_x], BOARD_WIDTH - 1
  jmp .end_checks
  .move_left:
  sub byte [g_head_x], 1
  jmp .end_checks

  .check_right:
  cmp byte [g_dir], DIR_RIGHT
  jne .end_checks
  cmp byte [g_head_x], BOARD_WIDTH - 1
  jne .move_right
  mov byte [g_head_x], 0
  jmp .end_checks
  .move_right:
  add byte [g_head_x], 1
  jmp .end_checks

  .end_checks:

  ; Check if we ate fruit
  mov rdx, [g_head_x]
  cmp rdx, [g_food_x]
  jne .end_eat
  mov rdx, [g_head_y]
  cmp rdx, [g_food_y]
  jne .end_eat

  mov eax, [g_snake_length]
  xor edx, edx
  mov ecx, 16
  mul ecx ; [g_snake_length] * 16
  add rax, r8
  mov rcx, [g_head_x]
  mov [rax], rcx
  mov rcx, [g_head_y]
  mov [rax + 8], rcx
  inc qword [g_snake_length]

  call reposition_fruit
  inc qword [g_score]
  cmp qword [g_speed], BASE_WAIT_TIME - MIN_WAIT_TIME - SPEED_INCREMENT
  jg .end_wait_change
  add qword [g_speed], SPEED_INCREMENT
  .end_wait_change:

  jmp .end_eat

  .end_eat:

  ret


main:
  push rbp
  mov rbp, rsp
  sub rsp, 32 + 512

  call _CRT_INIT

  call clear_screen
  call setup_input
  call reposition_fruit
  ; call reposition_head

  .loop:
    mov rcx, rsp
    add rcx, 32
    call print_board

    mov rcx, rsp
    add rcx, 32
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

    mov rcx, BASE_WAIT_TIME
    sub rcx, [g_speed]
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
