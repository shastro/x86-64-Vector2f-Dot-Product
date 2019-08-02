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

;Print a single byte in its ascii form
%macro print_char 1
    mov al, %1
    call _ALDigit_to_ascii
    call _RAXprint_char
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


;Calls div, quotient will be in RAX, remainder in RDX
;Destroys content in both RAX and RDX
%macro u_div 2
    
    xor rax, rax
    xor rdx, rdx

    push r9
    xor r9, r9

    mov rax, %1
    mov rcx, %2 ; 

    div r9

    pop r9

%endmacro

;Function prologue should be called at the start of every subroutine, handles the creation of a stack frame
;Pushes all callee reserved Registers
;Combined with func_epilogue the stack should be in the same state it was in when the subroutine was started eg rsp rbp should be unchanged
%macro push_callees 0
    ;Pushing callee-saved registers onto the stack, these are registers that the callee cannot allow changes to be made to
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
%endmacro

;Epilogue for use at the end of a Function
%macro pop_callees 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
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
    push_callees ;Push all callee-saved
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
        pop_callees
        ret

;Returns the index of any given token in a contigous array of bytes
;Input buffer address in rdi, token should be stored in dl
;Output is in rax
_token_index:
    push_callees
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
        pop_callees
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

 ;Prints a single character stored in the lowest byte of rax (al)
_RAXprint_char:
    
    push rsi  ;Preserve rsi
    push rcx  ;Preserve rcx
    push rax  ;Push char onto stack
    
    
    xor rsi, rsi

    mov rax, 1   ;id of sys_write
    mov rdi, 1   ;id of std_out
    mov rsi, rsp ;Move the value at the head of the stack into rsi
    mov rdx, 1   ;Length of buffer

    syscall

    
    pop rax
    pop rcx
    pop rsi

    ret

;Converts a digit in al to its ascii value stored in al
;Modifies lowest byte of rax
;Must be a single byte
_ALDigit_to_ascii:

    add al, byte 48
    ret

_R8print_number:
    ;Convert a number in R8 to its ascii counterpart, store in rax
    ;This will involve aquiring each digit, and converting each into its ascii byte value
    ;I'll store each ascii digit on the stack, then I'll pop them all off for Printing
    ;Rcx will be a counter of the number of stack items

    ;Create stack frame
    ;push rbx

    push rcx
    xor rcx, rcx  ;Set counter to zero

    ;Initialize Registers
    xor rax, rax
    xor rdx, rdx
    mov rax, r8 
    
    _divloop:

        cmp rax, 0 ;Have finished processing digits onto stack
        jz _printloop

        mov rdi, 10
        div rdi      ;Divides rax by 10, stores quotient in rax, stores remainder in rdx


        push rdx      ;Pushes the last digit onto the stack
        xor rdx,rdx

        inc rcx ;Increment the counter



        jmp _divloop




    ;Once the number is converte

    _printloop:
        cmp rcx, 0
        jz _end
        xor r8, r8 ;We will use r8 as a temp register for Printing
        pop r8     ;Pop current digit of the stack into r8
        print_char r8b ;Print the current char
        dec rcx

        jmp _printloop


    _end:

    pop rcx
    ;pop rsp ;Pop rbx's value into rsp
    ret




;===========================        
;== Execution Entry Point ==
;===========================

_start:
    
    ; print_str entry_text
    ; get_input buf, 1000
    ; index_token buf, byte 32 ;Index the space character

    ; u_div 100, 25
    ; u_div 99, 1
    ; u_div 3, 2
    ; u_div 20, 10

    mov r8, 125
    call _R8print_number

    ; mov rax, 12
    ; mov rdx, 0
    ; mov rdi,10
    ; div rdi
    exit 0
