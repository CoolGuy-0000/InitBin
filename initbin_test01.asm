FORMAT PE64 GUI 4.0 DLL

ENTRY code_start

section 'code' code readable writeable executable
code_start = $

call GetCurrentAddress
mov rbp, rax

mov [rbp+_PREV_STACK01], rsp
and rsp, 0FFFFFFFFFFFFFFF0h

mov [rbp+_BP], rbp

call GetKernelModuleHandle
mov [rbp+_KERNEL], rax

push 2CEh
push rax
call FindFuncByOrdinal
mov [rbp+GetProcAddress], rax
mov rsi, rax

lea rdi, [rbp+__func_init__]

L_func_init:
mov rdx, [rdi]
add rdx, rbp
mov rcx, [rbp+_KERNEL]
call rsi
mov [rdi], rax
lea rdi, [rdi+8]
cmp QWORD PTR rdi, 0
jnz L_func_init

sub rsp, 8
push 0
push 0
lea r9, [rbp+_BP]
lea r8, [rbp+_ThreadRoutine]
mov rdx, 1000h
mov rcx, 0
call QWORD PTR rbp+CreateThread
add rsp, 8

lea rcx, [rbp+_str.my_module_name]
call QWORD PTR rbp+GetModuleHandleA
mov [rbp+my_module], rax

mov rcx, [rax+6] ;entry origin
add rcx, rax

mov rsp, [rbp+_PREV_STACK01]
jmp rcx

_ThreadRoutine = $-code_start
mov rbp, [rcx]

mov [rbp+_PREV_STACK02], rsp
and rsp, 0FFFFFFFFFFFFFFF0h

lea rcx, [rbp+_str.USER32]
call QWORD PTR rbp+GetModuleHandleA
mov [rbp+_USER32], rax

mov rsi, [rbp+GetProcAddress]
lea rdi, [rbp+__func_init_user__]

L_func_init_user:
mov rdx, [rdi]
add rdx, rbp
mov rcx, [rbp+_USER32]
call rsi
mov [rdi], rax
lea rdi, [rdi+8]
cmp QWORD PTR rdi, 0
jnz L_func_init_user

mov r9, 0
lea r8, [rbp+_str.msg_success]
lea rdx, [rbp+_str.msg_success]
mov rcx, 0
call QWORD PTR rbp+MessageBoxA

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


;HMODULE module, WORD Ordinal
FindFuncByOrdinal:

push rbp
mov rbp, rsp
push rcx

xor rcx, rcx

mov rax, [rbp+16]
movzx rcx, BYTE PTR rax+3Ch ;fanew
add rcx, rax

xor rax, rax
mov eax, DWORD PTR rcx+136
add rax, [rbp+16]

xor rcx, rcx
mov ecx, DWORD PTR rax+28
add rcx, [rbp+16]

xor rax, rax
mov eax, DWORD PTR rbp+24
dec eax
mov eax, DWORD PTR rcx+rax*4

add rax, [rbp+16]

pop rcx
pop rbp
ret 16


;-------------------------------------


GetProcAddress = $-code_start
DQ 0 

_KERNEL = $-code_start
DQ 0

_BP = $-code_start
DQ 0

_PREV_STACK01 = $-code_start
DQ 0

_PREV_STACK02 = $-code_start
DQ 0

my_module = $-code_start
DQ 0

_USER32 = $-code_start
DQ 0

__func_init__ = $-code_start

GetModuleHandleA = $-code_start
DQ _str.GetModuleHandleA

CreateThread = $-code_start
DQ _str.CreateThread

DQ 0


__func_init_user__ = $-code_start

MessageBoxA = $-code_start
DQ _str.MessageBoxA 

DQ 0


_str:
	.GetModuleHandleA = $-code_start
	DB "GetModuleHandleA",0
	
	.CreateThread = $-code_start
	DB "CreateThread",0
	
	.MessageBoxA = $-code_start
	DB "MessageBoxA",0
	
	.my_module_name = $-code_start
	DB "Test64Program.exe",0


	.USER32 = $-code_start
	DB "USER32.DLL",0

	.msg_success = $-code_start
	DB "Success!",0
	
code_size = $-code_start