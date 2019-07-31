; Command Line Assembly Tool to get the dot product 

; Assembly and Linking Instructions (for self reference)
; $ nasm -f elf64 *.asm && ld *.o -o * && ./* 
; debug flags = (-g -Fdwarf)

;Macro Defintions
BUFLEN equ 1000
;Exit Macro
%macro exit 1
    mov rax, 60 ;sys_exit() id > ras
    mov rdi, %1  ;move the value of the first argument into rdi
    syscall
%endmacro

;Print Null Terminated String
%macro print_str 1
    mov rdi, %1  ;Move string pointer into rdi
    call _RDIstrlen
    mov rdx, rax ;Take result of strlen and put in rdx register

    mov rax, 1   ;id of sys_write
    mov rdi, 1   ;id of std_out
    mov rsi, %1  ;pointer to string
    syscall
%endmacro

;Gets a string buffer from stdin and stores it in rax
;input is the string buffer reserved and its length
%macro get_input 2

    mov rax, 0 ;sys_read
    mov rdi, 0 ;std_in
    mov rsi, %1 ;mov buffer address into rsi
    mov rdx, %2 ;size of buffer
    syscall

%endmacro

;Gets index of first occurance of token in string
;Input: first input should be buffer address, second should be token
;Puts output in rax, 
%macro index_token 2
    mov rdi, %1
    mov dl, %2
    call _token_index
%endmacro


;==========================================================================================
;Section Declarations
;==========================================================================================

;Constant Data, that is initialized in memory, cannot be changed in size, but can be changed
section .data 
    entry_text db "Please enter the x and y components of Vector a seperated by a space: ",0      ;10 is New Line, 0 is null-char
;Constant data that is initialized to zero
;Reserving the bytes needed for our input
section .bss  
    buf resb BUFLEN

;Contains the text and label to Execution entry point
section .text 
    global _start

;==========================================================================================
;Subroutine Definitions
;==========================================================================================

;=====================================
;== Printing and String Subroutines ==
;=====================================

;Strlen expects the string's address to be in rdi register, it will use rcx as a temporary counter, and place the value in rax
_RDIstrlen:
    push rcx     ;Put rcx's value onto the stack, so the data isnt lost
    xor rcx, rcx ;Set counter to zero

    _next:       ;Label for what to do when moving between bytes
        cmp [rdi], byte 0  ;Compare the current byte with zero
        jz _null           ;If zero flag is set (they are the same value) jump to _null

        inc rdi ;Increment the string pointer
        inc rcx ;Increment the counter

        jmp _next


    _null:      ;Label for when null is hit
        mov rax, rcx
        pop rcx
        ret

;Returns the index of any given token in a contigous array of bytes
;Input buffer address in rdi, token should be stored in dl
;Output is in rax
_token_index:
    
    xor rax, rax ;Setting rax to zero, rax will hold the index
    xor rcx, rcx
    xor cl, cl
    _loop:

        cmp [rdi], byte 0     ;Compare with zero
        jz _token_not_found   ;If zero flag then we have reached end of string

        mov cl, [rdi]         ;Move the lowest byte of the value at the address [rdi] into cl (lowest byte of rcx)
        cmp cl,  dl           ;Compare byte with token byte
        jz _token_found       ;If zero flag then token is found

        inc rdi               ;Increment string pointer
        inc rax               ;Increment counter

        jmp _loop

    _token_not_found:
        mov rax, -1 ;Return -1 if not found
        ret

    _token_found:
        ret


;Float and Vector sub_routines
;expects a.x in XMM1, a.y in XMM2, b.x in XMM3, and b.y in XMM4
;output in xmm0 (destructive)
_dot:
    
    mulps xmm1, xmm3 ;mult a.x with b.x
    mulps xmm2, xmm4 ;mult a.y and b.y

    movaps xmm0, xmm1
    addps xmm0, xmm2 ;sum two results

    ret
    
    
;===========================        
;== Execution Entry Point ==
;===========================

_start:
    
    print_str entry_text
    get_input buf, 1000
    print_str buf
    index_token buf, byte 32 ;Index the space character

    exit 0
