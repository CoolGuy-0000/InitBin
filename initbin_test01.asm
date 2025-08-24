FORMAT PE64 GUI 4.0 DLL

ENTRY code_start

section 'code' code readable writeable executable

DD code_size

code_start = $

call GetCurrentAddress
mov rbp, rax

call GetKernelModuleHandle

lea rdx, [rbp+_str.LoadLibraryA]
mov rcx, rax
call FindFuncByName

sub rsp, 18h
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

        ; strcmp(targetName, namePtr)
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

        lea     rax, [rbx+rax]               ; rax = 실제 함수 주소
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

;-------------------------------------

_str:
	.LoadLibraryA = $-code_start
	DB "LoadLibraryA",0

	.BridgePath = $-code_start
	DB ".\\bridge64.dll",0

code_size = $-code_start

