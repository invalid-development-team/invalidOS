; setup
; by zebra
use16
org 0500h
jmp start

    include 'lib/ata.s'

.code:
start:
use16

xor ax,ax
push ax
pop es
mov al,90h
mov bl,4h
mul bl
mov bx,ax
mov si,0700h
mov [es:bx],si
add bx,2
push cs
pop ax
mov [es:bx], ax

push cs
pop ds
mov si,paket_sysint
mov ah,42h
int 13h

; Open gate A20
in al, 92h
or al, 2
out 92h, al

; Disable maskable interrupts
cli

; Disable non-maskable interrupts
in al, 70h
or al, 80h
out 70h, al

lgdt [gdtr]

; Switch to protected mode
mov eax, cr0
or al, 1
mov cr0, eax

jmp far dword 0000000000001000b:pm_entry

use32

; Protected mode entry point
pm_entry:
    mov ax, 0000000000010000b
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, 0x3
    mov ecx, 0x8
    mov edi, 0x0900
    call ata_lba_read
    call 0x0900

    mov edi, 0xB8000
    mov esi, message

    cld
    .loop:
        lodsb
        test al, al
        jz .exit
        stosb
        mov al, 7
        stosb
        jmp .loop
    cli

    cld
    .exit:
        jmp $
        hlt

message db 'Error, host is down!', 0

align 8

; push cs
; pop ds
; mov si,paket_kernel
; mov ah,42h
; int 13h
; jmp 0000:8000h

; jmp $

times(512-($-0500h)) db 0

.data:

gdt:
NULL_SEG_DESCRIPTOR db 8 dup(0)

CODE_SEG_DESCRIPTOR:
    dw 0xFFFF          
    db 0x00, 0x00, 0x00
    db 10011010b       
    db 11001111b       
    db 0x00            

DATA_SEG_DESCRIPTOR:
    dw 0xFFFF          
    db 0x00, 0x00, 0x00
    db 10010010b       
    db 11001111b       
    db 0x00            

gdt_size equ $ - gdt

gdtr:
    dw gdt_size - 1
    dd gdt 

paket_kernel:
    dw 16;const paksize
    dw 8;num sectors
    dw 8000h;offset
    dw 0;segment
    dq 5;start sector

paket_sysint:
    dw 16;const paksize
    dw 2;num sectors
    dw 900h;offset
    dw 0;segment
    dq 3;start sector

times(512-($-0700h)) db 0