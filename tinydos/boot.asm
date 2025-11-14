; boot.asm - 512 byte boot sector
[org 0x7c00]
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; show message
    mov si, boot_msg
    call print_string

    ; load kernel (1 sector) to 0x0000:0x0500 (physical 0x0500)
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x0500

    mov ah, 0x02    ; BIOS: read sectors
    mov al, 1       ; read 1 sector
    mov ch, 0       ; cylinder
    mov cl, 2       ; sector (1 = boot sector, so kernel at sector 2)
    mov dh, 0       ; head
    mov dl, [boot_drive] ; drive (BIOS gives boot drive in DL)
    int 0x13
    jc disk_error

    ; jump to kernel entry at 0x0000:0x0500
    jmp 0x0000:0x0500

disk_error:
    mov si, disk_msg
    call print_string
    hlt
    jmp $

; --- print_string (SI -> NUL-terminated) ---
print_string:
    pusha
.next_char:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp .next_char
.done:
    popa
    ret

boot_msg db "TinyDOS booting...", 0x0D,0x0A, 0
disk_msg db "Disk read error.", 0x0D,0x0A, 0

; store DL (BIOS drive) on stack location for later
boot_drive: db 0

times 510-($-$$) db 0
dw 0xAA55
