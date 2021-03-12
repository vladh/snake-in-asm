bits 64
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment .rodata

BOARD_HEIGHT equ 30
BOARD_WIDTH equ 45
NEWLINE db 0xd, 0xa, 0
BOARD_ICON_EMPTY db ". ", 0
BOARD_ICON_FRUIT db "* ", 0
BOARD_ICON_HEAD db "O ", 0
BOARD_ICON_TAIL db "x ", 0
FMT_INT db "%d", 0xd, 0xa, 0
FMT_SHORT db "%hd", 0xd, 0xa, 0
FMT_UINT db "%u", 0xd, 0xa, 0
FMT_CHAR db "%c", 0xd, 0xa, 0
FMT_STRING db "%s", 0xd, 0xa, 0
FMT_SCORE db "Score: %d", 0
FMT_SPEED db "Speed: %d%%", 0
FMT_LENGTH db "Length: %d", 0
FMT_CONTROLS_MOVEMENT db "WASD to move", 0
FMT_CONTROLS_QUIT db "Q to quit", 0
FMT_GAME db "GAME", 0
FMT_OVER db "OVER", 0
FMT_END_SCORE db "Your score was: %d", 0
FMT_RATING_1 db "Sucks to suck!", 0
FMT_RATING_2 db "A Snake god.", 0
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
g_fruit_x dq 10
g_fruit_y dq 5
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

; BOOL WINAPI SetConsoleMode(
;   _In_ HANDLE hConsoleHandle,
;   _In_ DWORD  dwMode
; );
extern SetConsoleMode

; BOOL WINAPI ReadConsole(
;   _In_     HANDLE  hConsoleInput,
;   _Out_    LPVOID  lpBuffer,
;   _In_     DWORD   nNumberOfCharsToRead,
;   _Out_    LPDWORD lpNumberOfCharsRead,
;   _In_opt_ LPVOID  pInputControl
; );
extern ReadConsoleA

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

  ; Disable echoing input and other such things, so that we don't print stuff
  ; out when we're reading characters.
  mov rcx, [g_std_handle]
  mov rdx, 0
  call SetConsoleMode

  ; Hide the cursor
  mov rcx, SEQ_HIDE_CURSOR
  call printf

  mov rsp, rbp
  pop rbp
  ret


flush_input_buffer:
  push rbp
  mov rbp, rsp
  sub rsp, 32

  ; Flush buffer so we don't get a bunch of characters printed
  ; This is apparently bad/deprecated, but do we care? No!
  mov rcx, [g_std_handle]
  call FlushConsoleInputBuffer

  mov rsp, rbp
  pop rbp
  ret


reset_input:
  push rbp
  mov rbp, rsp
  sub rsp, 32

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

  mov rdx, 1
  mov r8, 1
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

  ; Reset position to 1, 1
  mov rdx, 1
  mov r8, 1
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
      jne .maybe_print_fruit
      cmp r12, [g_head_y]
      jne .maybe_print_fruit
      mov rcx, BOARD_ICON_HEAD
      call printf
      jmp .end_print

      .maybe_print_fruit:
      cmp r13, [g_fruit_x]
      jne .maybe_print_tail
      cmp r12, [g_fruit_y]
      jne .maybe_print_tail
      mov rcx, BOARD_ICON_FRUIT
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
        cmp r12, [rax]
        jne .no_tail_match
        mov rcx, BOARD_ICON_TAIL
        call printf
        jmp .end_print
        .no_tail_match:
        inc r14
        jmp .loop_tail

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
  mov rdx, 1
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

  ; Print length
  mov rdx, 3
  mov r8, (BOARD_WIDTH * 2) + 2
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_LENGTH
  mov rdx, [g_snake_length]
  call printf

  ; Print controls
  mov rdx, 4
  mov r8, (BOARD_WIDTH * 2) + 2
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_CONTROLS_MOVEMENT
  mov rdx, [g_snake_length]
  call printf

  mov rdx, 5
  mov r8, (BOARD_WIDTH * 2) + 2
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_CONTROLS_QUIT
  mov rdx, [g_snake_length]
  call printf

  ; Clean up
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
  mov [g_fruit_x], edx

  rdtsc
  xor edx, edx
  mov ecx, BOARD_HEIGHT
  div ecx
  mov [g_fruit_y], edx

  ret


update_game_data: ; (tail_addr)
  mov r8, rcx

  ; Update snake tail
  cmp qword [g_snake_length], 0
  je .end_tail_update

  ; We want to move the tail position from index r9 - 1 to index r9
  ; The index, r9, is in [0, g_snake_length - 1]
  ; If r9 == 0, we copy from the head to the first tail position
  mov r9, [g_snake_length]
  sub r9, 1

  ; Calculate tail memory address
  mov eax, r9d
  xor edx, edx
  mov ecx, 16
  mul ecx
  add rax, r8 ; rax = ([g_snake_length] * 16) + tail_addr

  .loop_tail:
    cmp r9, 0
    jne .update_tail_segment
    ; Update first tail segment (to replace old head)
    mov rcx, [g_head_x]
    mov [rax], rcx
    mov rcx, [g_head_y]
    mov [rax + 8], rcx
    jmp .end_tail_update

    .update_tail_segment:
    ; Update tail segment
    ; Move segment n to segment n + 1

    ; But first, has this tail piece collided with the head?
    mov rcx, [g_head_x]
    cmp rcx, [rax]
    jne .can_update_tail_segment
    mov rcx, [g_head_y]
    cmp rcx, [rax + 8]
    jne .can_update_tail_segment
    ; Oops, they collided!
    jmp .finish_with_game_over

    ; Ok, we're good, we can move the segment now
    .can_update_tail_segment:
    mov rcx, [rax - 16]
    mov [rax], rcx
    mov rcx, [rax - 16 + 8]
    mov [rax + 8], rcx

    dec r9
    sub rax, 16
    jmp .loop_tail
  .end_tail_update:

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
  xor rax, rax
  jmp .finish_update

  .finish_with_game_over:
  mov rax, 1

  .finish_update:

  ret


check_if_we_ate_and_update_length:
  ; Check if we ate fruit
  mov rdx, [g_head_x]
  cmp rdx, [g_fruit_x]
  jne .end_eat
  mov rdx, [g_head_y]
  cmp rdx, [g_fruit_y]
  jne .end_eat

  inc qword [g_snake_length]
  call reposition_fruit
  inc qword [g_score]
  cmp qword [g_speed], BASE_WAIT_TIME - MIN_WAIT_TIME - SPEED_INCREMENT
  jg .end_wait_change
  add qword [g_speed], SPEED_INCREMENT
  .end_wait_change:

  .end_eat:

  ret


process_inputs:
  push rbp
  mov rbp, rsp
  sub rsp, 32

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
  mov rax, 1
  jmp .return_input

  .end_input:
  xor rax, rax

  .return_input:
  mov rsp, rbp
  pop rbp
  ret


print_game_over:
; rbp +
.scratch1 equ 16
.scratch2 equ 24
; rsp +
.pInputControl equ 32
  push rbp
  mov rbp, rsp
  sub rsp, 64

  ; Print game over stuff
  ; NOTE: When we move to BOARD_WIDTH below, keep in mind that our characters
  ; are 2-wide, so BOARD_WIDTH will be half the effective width.
  mov rdx, (BOARD_HEIGHT / 2)
  mov r8, BOARD_WIDTH - (BOARD_WIDTH / 4)
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_GAME
  call printf

  mov rdx, (BOARD_HEIGHT / 2) + 1
  mov r8, BOARD_WIDTH - (BOARD_WIDTH / 4)
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_OVER
  call printf

  mov rdx, (BOARD_HEIGHT / 2) + 2
  mov r8, BOARD_WIDTH - (BOARD_WIDTH / 4)
  mov rcx, SEQ_POS
  call printf

  mov rcx, FMT_END_SCORE
  mov rdx, [g_score]
  call printf

  mov rdx, (BOARD_HEIGHT / 2) + 3
  mov r8, BOARD_WIDTH - (BOARD_WIDTH / 4)
  mov rcx, SEQ_POS
  call printf

  cmp qword [g_score], 10
  jge .print_rating_2
  mov rcx, FMT_RATING_1
  call printf
  jmp .end_print_rating

  .print_rating_2:
  mov rcx, FMT_RATING_2
  call printf
  jmp .end_print_rating

  .end_print_rating:

  ; Wait for the user to press something
  mov rcx, [g_std_handle] ; hConsoleInput
  lea rdx, [rbp + .scratch1] ; lpBuffer
  mov r8, 1 ; nNumberOfChartsToRead
  lea r9, [rbp + .scratch2] ; lpNumberOfCharsToRead
  mov byte [rsp + .pInputControl], 0 ; pInputControl
  call ReadConsoleA

  mov rsp, rbp
  pop rbp
  ret


main:
  push rbp
  mov rbp, rsp
  sub rsp, 32 + 512

  call _CRT_INIT

  call clear_screen
  call setup_input
  call reposition_fruit

  .loop:
    mov rcx, rsp
    add rcx, 32
    call update_game_data

    cmp rax, 1
    je .game_over

    mov rcx, rsp
    add rcx, 32
    call print_board

    call check_if_we_ate_and_update_length

    call process_inputs
    cmp rax, 1
    je .end_loop

    mov rcx, BASE_WAIT_TIME
    sub rcx, [g_speed]
    call Sleep
    jmp .loop
  .end_loop:
  jmp .cleanup

  .game_over:
  call flush_input_buffer
  call print_game_over
  call reset_input
  jmp .end

  .cleanup:
  call flush_input_buffer
  call reset_input
  jmp .end

  .end:

  xor rax, rax
  mov rsp, rbp
  pop rbp
  call ExitProcess
