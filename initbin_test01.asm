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
        ; 프로롤그 (비휘발 레지스터 보존 + 16바이트 정렬)
        push    rbp
        mov     rbp, rsp
        push    rbx
        push    rsi
        push    rdi
        push    r12
        push    r14
        push    r15
        sub     rsp, 32                 ; shadow/local (정렬 유지)

        mov     rbx, rcx                ; rbx = 모듈 베이스
        mov     rsi, rdx                ; rsi = 찾을 함수 이름 포인터

        ; ---------------------------
        ; NT 헤더 찾기: nt = base + e_lfanew
        ; ---------------------------
        mov     eax, DWORD PTR rbx+3Ch    ; e_lfanew
        lea     r8,  [rbx+rax]              ; r8 = NT headers

        ; ---------------------------
        ; Export Directory 가져오기
        ; OptionalHeader.DataDirectory[0] (EXPORT) 의 RVA는
        ; NT + 24(파일헤더 뒤) + 112(OptHdr64에서 DataDir 시작) = +136
        ; ---------------------------
        mov     eax, DWORD PTR r8+136     ; Export Directory RVA
        test    eax, eax
        jz      ffbn_not_found
        lea     r14, [rbx+rax]              ; r14 = Export Directory (VA)

        ; 자주 쓰는 필드/테이블 주소
        mov     eax, DWORD PTR r14+24     ; NumberOfNames
        test    eax, eax
        jz      ffbn_not_found
        mov     r10d, eax                    ; r10d = NumberOfNames

        mov     eax, DWORD PTR r14+32     ; AddressOfNames RVA
        lea     r15, [rbx+rax]               ; r15 = AddressOfNames (VA)

        mov     eax, DWORD PTR r14+36     ; AddressOfNameOrdinals RVA
        lea     rdi, [rbx+rax]               ; rdi = AddressOfNameOrdinals (VA)

        ; 루프 인덱스 i = 0 .. NumberOfNames-1
        xor     r12d, r12d                   ; r12d = i

ffbn_search_loop:
        cmp     r12d, r10d
        jae     ffbn_not_found

        ; namePtr = base + ((DWORD*)AddressOfNames)[i]
        mov     eax, DWORD PTR r15 + r12*4
        lea     rdx, [rbx+rax]               ; rdx = 현재 이름 포인터
        mov     rcx, rsi                     ; rcx = 찾을 이름 포인터

        ; strcmp(targetName, namePtr)
        call    strcmp
        test    eax, eax
        jz      ffbn_found                   ; 같다면 성공

        inc     r12d
        jmp     ffbn_search_loop

ffbn_found:
        ; ordinal = ((WORD*)AddressOfNameOrdinals)[i]
        movzx   eax, WORD PTR rdi + r12*2  ; eax = ordinal (index)

        ; funcVA = base + ((DWORD*)AddressOfFunctions)[ordinal]
        mov     edx, DWORD PTR r14+28      ; AddressOfFunctions RVA
        lea     rdx, [rbx+rdx]               ; rdx = AddressOfFunctions (VA)
        mov     eax, DWORD PTR rdx + rax*4 ; eax = Function RVA
        test    eax, eax
        jz      ffbn_not_found               ; (희귀) 0이면 실패 취급

        lea     rax, [rbx+rax]               ; rax = 실제 함수 주소
        jmp     ffbn_exit

ffbn_not_found:
        xor     rax, rax                     ; 실패 시 0

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

; ------------------------------------------------------------
; int strcmp(const char* s1 /*RCX*/, const char* s2 /*RDX*/)
;   - 같으면 0, 다르면 1 반환 (간단 비교)
; ------------------------------------------------------------
strcmp:
strcmp_loop:
        mov     al,  BYTE PTR rcx
        mov     r8b, BYTE PTR rdx         ; r8b 사용: 비보존 RBX 건드리지 않기 위함
        cmp     al, r8b
        jne     strcmp_not_equal

        test    al, al                      ; NUL?
        jz      strcmp_equal

        inc     rcx
        inc     rdx
        jmp     strcmp_loop

strcmp_equal:
        xor     eax, eax                    ; 0 (같음)
        ret

strcmp_not_equal:
        mov     eax, 1                      ; 1 (다름)
        ret

;-------------------------------------

_str:
	.LoadLibraryA = $-code_start
	DB "LoadLibraryA",0

	.BridgePath = $-code_start
	DB ".\\bridge64.dll",0

code_size = $-code_start
