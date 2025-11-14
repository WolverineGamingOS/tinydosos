; kernel.asm - simple shell, loaded at 0x0000:0x0500
[org 0x0500]
bits 16

start_kernel:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    sti

main_loop:
    call print_prompt
    call read_line    ; input in buffer at input_buf, length in cx
    cmp cx, 0
    je main_loop
    call handle_cmd
    jmp main_loop

; ---------- simple prompt ----------
print_prompt:
    mov si, prompt
    call print_str
    ret

prompt db "A:\>",0

; ---------- read_line (reads chars, echoes; returns cx=len) ----------
read_line:
    mov di, input_buf
    xor cx, cx
.read_char:
    mov ah, 0x00
    int 0x16        ; BIOS keyboard: get char (blocking)
    cmp al, 0x0D    ; CR ?
    je .done
    cmp al, 0x08    ; backspace
    je .backsp
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10        ; echo
    jmp .read_char
.backsp:
    cmp cx, 0
    je .read_char
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .read_char
.done:
    mov byte [di], 0
    ret

input_buf times 128 db 0

; ---------- handle_cmd ----------
handle_cmd:
    mov si, input_buf
    call strcmp_help
    cmp al, 1
    je cmd_help
    mov si, input_buf
    call strcmp_cls
    cmp al, 1
    je cmd_cls
    mov si, input_buf
    call strcmp_reboot
    cmp al, 1
    je cmd_reboot
    mov si, input_buf
    call strcmp_echo
    cmp al, 1
    je cmd_echo

    ; unknown
    mov si, unknown_cmd
    call print_str
    ret

cmd_help:
    mov si, help_text
    call print_str
    ret

cmd_cls:
    ; BIOS scroll up AH=06 to clear screen
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

cmd_reboot:
    ; BIOS warm boot via int 0x19
    cli
    int 0x19
    hlt
    ret

cmd_echo:
    ; echo the rest after "echo "
    mov si, input_buf
    add si, 5    ; skip 'echo '
    call print_str
    ret

; ---------- helpers ----------
print_str:
    pusha
.next:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    popa
    ret

; simple string compare helpers (returns AL=1 if match)
; compares whole buffer to fixed string
strcmp_help:
    push si
    mov di, help_cmd
    call strcmp_common
    pop si
    ret

strcmp_cls:
    push si
    mov di, cls_cmd
    call strcmp_common
    pop si
    ret

strcmp_reboot:
    push si
    mov di, reboot_cmd
    call strcmp_common
    pop si
    ret

strcmp_echo:
    push si
    mov di, echo_cmd
    call strcmp_prefix ; echo should check prefix "echo "
    pop si
    ret

; compare exact (null-terminated)
strcmp_common:
    ; SI=user, DI=literal
.cmploop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    cmp al, 0
    je .yes
    inc si
    inc di
    jmp .cmploop
.yes:
    mov al, 1
    ret
.no:
    mov al, 0
    ret

; check prefix (literal must match start of buffer)
strcmp_prefix:
    ; DI=literal, SI=user
.cmploop2:
    mov al, [di]
    cmp al, 0
    je .yes
    mov bl, [si]
    cmp al, bl
    jne .no
    inc di
    inc si
    jmp .cmploop2
.yes:
    mov al, 1
    ret
.no:
    mov al, 0
    ret

; data
help_cmd db "help",0
cls_cmd  db "cls",0
reboot_cmd db "reboot",0
echo_cmd db "echo ",0

help_text db "Commands:",0x0D,0x0A
db "  help    - show this text",0x0D,0x0A
db "  cls     - clear screen",0x0D,0x0A
db "  echo x  - print x",0x0D,0x0A
db "  reboot  - reboot",0x0D,0x0A,0

unknown_cmd db "Unknown command",0x0D,0x0A,0

times 512-($-$$) db 0
