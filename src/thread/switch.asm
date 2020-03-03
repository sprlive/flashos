[bits 32]
section .text
global switch_to
switch_to:
	;栈中此处时返回地址
	push esi
	push edi
	push ebx
	push ebp
	mov eax,[esp+20] ;得到栈中的参数cur
	mov [eax],esp	;保存栈顶指针esp，task_struct的self_kstack字段
	
	mov eax,[esp+24] ;得到栈中的参数next
	mov esp,[eax]
	pop ebp
	pop ebx
	pop edi
	pop esi
	ret
