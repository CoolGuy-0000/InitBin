FORMAT PE64 GUI 4.0 DLL

ENTRY code_start

section 'code' code readable writeable executable

code_start = $

call GetCurrentAddress

DB 0Fh, 1Fh, 84h, 00h
_param01 = $-code_start
DD code_size

mov rbp, rax

call GetKernelModuleHandle
mov QWORD PTR rbp+KERNEL32, rax

lea rdx, [rbp+_str.NUM_BUF01]
mov rcx, rbp
call UInt64ToString

lea rdx, [rbp+_str.SetEnvironmentVariableA]
mov rcx, QWORD PTR rbp+KERNEL32
call FindFuncByName
mov QWORD PTR rbp+SetEnvironmentVariableA, rax

sub rsp, 18h
mov rdx, rdi

lea rdx, [rbp+_str.NUM_BUF01]
lea rcx, QWORD PTR rbp+_str.CG_VAR_BaseRBP
call QWORD PTR rbp+SetEnvironmentVariableA

lea rdx, [rbp+_str.LoadLibraryA]
mov rcx, QWORD PTR rbp+KERNEL32
call FindFuncByName

lea rcx, [rbp+_str.BridgePath]
call rax

add rsp, 18h

L_self_loop: jmp L_self_loop

GetCurrentAddress:
mov rax, [rsp]
sub rax, 5
ret

GetKernelModuleHandle:
mov rax, [gs:60h]
mov rax, [rax+18h] ;LDR
mov rax, [rax+20h] ;InMemoryOrderModuleList
mov rax, [rax] 
mov rax, [rax]
mov rax, [rax+20h]
ret

FindFuncByName:
        push    rbp
        mov     rbp, rsp
        push    rbx
        push    rsi
        push    rdi
        push    r12
        push    r14
        push    r15
        sub     rsp, 32                 

        mov     rbx, rcx                
        mov     rsi, rdx                

        mov     eax, DWORD PTR rbx+3Ch
        lea     r8,  [rbx+rax]

        mov     eax, DWORD PTR r8+136     
        test    eax, eax
        jz      ffbn_not_found
        lea     r14, [rbx+rax]             

        mov     eax, DWORD PTR r14+24    
        test    eax, eax
        jz      ffbn_not_found
        mov     r10d, eax                   

        mov     eax, DWORD PTR r14+32   
        lea     r15, [rbx+rax]            

        mov     eax, DWORD PTR r14+36    
        lea     rdi, [rbx+rax]            

        xor     r12d, r12d        

ffbn_search_loop:
        cmp     r12d, r10d
        jae     ffbn_not_found

        mov     eax, DWORD PTR r15 + r12*4
        lea     rdx, [rbx+rax]         
        mov     rcx, rsi               

        call    strcmp
        test    eax, eax
        jz      ffbn_found             

        inc     r12d
        jmp     ffbn_search_loop

ffbn_found:
        
        movzx   eax, WORD PTR rdi + r12*2 

       
        mov     edx, DWORD PTR r14+28      ; AddressOfFunctions RVA
        lea     rdx, [rbx+rdx]               ; rdx = AddressOfFunctions (VA)
        mov     eax, DWORD PTR rdx + rax*4 ; eax = Function RVA
        test    eax, eax
        jz      ffbn_not_found              

        lea     rax, [rbx+rax]
        jmp     ffbn_exit

ffbn_not_found:
        xor     rax, rax                   

ffbn_exit:
        add     rsp, 32
        pop     r15
        pop     r14
        pop     r12
        pop     rdi
        pop     rsi
        pop     rbx
        pop     rbp
        ret

strcmp:
strcmp_loop:
        mov     al,  BYTE PTR rcx
        mov     r8b, BYTE PTR rdx         
        cmp     al, r8b
        jne     strcmp_not_equal

        test    al, al                      
        jz      strcmp_equal

        inc     rcx
        inc     rdx
        jmp     strcmp_loop

strcmp_equal:
        xor     eax, eax                    
        ret

strcmp_not_equal:
        mov     eax, 1                      
        ret

UInt64ToString:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push rcx

    mov r8, rcx
    mov r9, rdx
    lea rdi, [rdx+15]
    mov byte ptr rdi+1, 0
    mov rax, 16
    mov rcx, 16

convert_loop:
    mov r10d, 0Fh
    and r10d, r8d

    cmp r10d, 9
    jle num_0_9
    add r10d, 'A' - 10
    jmp store_char

num_0_9:
    add r10d, '0'

store_char:
    mov [rdi], r10b
    dec rdi
    shr r8, 4
    dec rcx
    jnz convert_loop

    mov rax, 16

    pop rcx
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret
;-------------------------------------


KERNEL32 = $-code_start
	DQ 0

LoadLibraryA = $-code_start
	DQ 0

SetEnvironmentVariableA = $-code_start
	DQ 0

_str:
	.LoadLibraryA = $-code_start
	DB "LoadLibraryA",0

	.SetEnvironmentVariableA = $-code_start
	DB "SetEnvironmentVariableA",0

	.CG_VAR_BaseRBP = $-code_start
	DB "CG_VAR_BaseRBP",0

	.BridgePath = $-code_start
	DB ".\\bridge.dll",0
    
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0

	.NUM_BUF01 = $-code_start
	times 32 DB 0

	DD 0CCCCCCCCh
	DD 0CCCCCCCCh

code_size = $-code_start
