; -----------------------------------------------------------------------------
; boot.asm - A minimal 16-bit Real Mode bootloader
;
; Goal:
; 1. Setup stack & data segments
; 2. Enable A20 line
; 3. Load Stage 2 from disk
; 4. Switch to 32-bit Protected Mode
; 5. Jump to C code
; -----------------------------------------------------------------------------

[org 0x7c00]        ; BIOS loads us at this address
[bits 16]           ; Start in 16-bit Real Mode

start:
    ; -------------------------------------------------------------------------
    ; 1. Setup Stack & Data Segments
    ; -------------------------------------------------------------------------
    cli             ; Disable interrupts
    mov ax, 0       ; Set data segments to 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00  ; Stack grows down from here
    sti             ; Enable interrupts

    ; Save boot drive number (passed by BIOS in DL)
    mov [BOOT_DRIVE], dl

    ; Print "Hello from Stage 1!"
    mov bp, MSG_STAGE1
    call print_string

    ; -------------------------------------------------------------------------
    ; 2. Enable A20 line
    ; -------------------------------------------------------------------------
    mov bp, MSG_A20
    call print_string

    call check_a20
    cmp ax, 1
    je .a20_done

    ; BIOS enable A20
    mov ax, 0x2401
    int 0x15

    call check_a20
    cmp ax, 1
    je .a20_done

    ; If still failed, print error and halt
    mov bp, MSG_A20_ERR
    call print_string

.a20_done:
    ; -------------------------------------------------------------------------
    ; 3. Load Stage 2 from Disk
    ; -------------------------------------------------------------------------
    mov bp, MSG_LOAD
    call print_string

    mov bx, 0x1000  ; Load to address 0x1000 (ES:BX = 0x0000:0x1000)
%ifndef STAGE2_SECTORS
    %define STAGE2_SECTORS 1
%endif
    mov dh, STAGE2_SECTORS       ; Load STAGE2_SECTORS sectors (calculated by Makefile)
    mov dl, [BOOT_DRIVE]
    call disk_load

    ; -------------------------------------------------------------------------
    ; 4. Switch to Protected Mode
    ; -------------------------------------------------------------------------
    call get_cursor_position
    cli             ; Disable interrupts for the switch
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1     ; Set PE (Protection Enable) bit
    mov cr0, eax

    jmp CODE_SEG:init_pm ; Far jump to flush pipeline

; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------
BOOT_DRIVE:  db 0
MSG_STAGE1:  db 'Hello from Stage 1!', 13, 10, 0
MSG_A20:     db 'Enabling A20...', 13, 10, 0
MSG_A20_ERR: db 'A20 Gate Error!', 13, 10, 0
MSG_LOAD:    db 'Loading Stage 2...', 13, 10, 0
MSG_ERR:     db 'Disk Read Error!', 13, 10, 0

; Get current cursor position -> DH, DL
get_cursor_position:
    mov ah, 0x03    ; Function: Get Cursor Position
    mov bh, 0x00    ; Page 0
    int 0x10
    ret

; -----------------------------------------------------------------------------
; Function: print_string
; Input: BP = pointer to null-terminated string
; Uses BIOS INT 0x10, AX=0x1301 (Write String, Update Cursor)
; -----------------------------------------------------------------------------
print_string:
    pusha

    ; Calculate length of string at BP -> CX
    mov di, bp      ; DI points to string start
    xor cx, cx      ; CX = 0
.strlen_loop:
    cmp byte [di], 0
    je .strlen_done
    inc di
    inc cx
    jmp .strlen_loop
.strlen_done:
    ; Now CX = length, but, the following interrupt call would overwrite, so
    ; let's save it onto the stack
    push cx
    call get_cursor_position

    ; Print String
    mov ax, 0x1301  ; Function: Write String (AH=13h), Update Cursor (AL=01h)
    mov bx, 0x0007  ; Page 0 (BH), Attribute Light Gray on Black (BL)
    ; CX needs to contain the number of character to print
    pop cx
    ; BP is already set to string
    ; DH, DL are set by cursor query
    int 0x10

    popa
    ret

; -----------------------------------------------------------------------------
; Function: check_a20
; Returns: AX = 1 if enabled, AX = 0 if disabled
; -----------------------------------------------------------------------------
check_a20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax
    mov es, ax
    mov di, 0x7dfe ; 0x0000:0x7dfe (Boot signature)

    mov ax, 0xffff
    mov ds, ax
    mov si, 0x7e0e ; 0xffff:0x7e0e = 0x107dfe

    mov al, [es:di]
    push ax

    mov al, [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xff

    cmp byte [es:di], 0xff

    pop ax
    mov [ds:si], al

    pop ax
    mov [es:di], al

    mov ax, 0
    je .done

    mov ax, 1

.done:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

; -----------------------------------------------------------------------------
; Function: disk_load
; Input: DH = number of sectors to read, DL = drive, ES:BX = buffer
; -----------------------------------------------------------------------------
disk_load:
    push dx         ; Store DX so we can check number of sectors read later
    mov ah, 0x02    ; BIOS read sector function
    mov al, dh      ; Read DH sectors
    mov ch, 0x00    ; Cylinder 0
    mov dh, 0x00    ; Head 0
    mov cl, 0x02    ; Start reading from 2nd sector (sector 1 is bootloader)
    int 0x13

    jc .disk_error  ; Jump if carry flag set (error)

    pop dx          ; Restore DX
    cmp dh, al      ; Compare sectors read (AL) with expected (DH)
    jne .disk_error
    ret

.disk_error:
    mov bp, MSG_ERR
    call print_string
    jmp $

; -----------------------------------------------------------------------------
; Global Descriptor Table (GDT)
; -----------------------------------------------------------------------------
gdt_start:

gdt_null:           ; Mandatory null descriptor
    dd 0x0
    dd 0x0

; Alternative way to exress the following more compactly:
; dq 0x00CF9A000000FFFF
gdt_code:           ; Code segment descriptor
    dw 0xffff       ; Limit (bits 0-15)
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10011010b    ; Present, Ring 0, Code, Exec/Read
    db 11001111b    ; Granularity 4KB, 32-bit, Limit (bits 16-19)
    db 0x0          ; Base (bits 24-31)

; Alternative way to exress the following more compactly:
; dq 0x00CF92000000FFFF
gdt_data:           ; Data segment descriptor
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b    ; Present, Ring 0, Data, Read/Write
    db 11001111b
    db 0x0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                ; Address of GDT

; Constants for GDT segment offsets
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; -----------------------------------------------------------------------------
; 32-bit Protected Mode
; -----------------------------------------------------------------------------
[bits 32]

init_pm:
    ; -------------------------------------------------------------------------
    ; 5. Jump to C Code
    ; -------------------------------------------------------------------------
    mov ax, DATA_SEG        ; Update segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000        ; Update stack position
    mov esp, ebp

    push dword edx          ; Pass cursor position
    call 0x1000             ; Call our C stage2 loaded at 0x1000
    jmp $

; -----------------------------------------------------------------------------
; Boot Sector Padding
; -----------------------------------------------------------------------------
times 510-($-$$) db 0   ; Fill rest of sector with 0
dw 0xaa55               ; Boot signature
