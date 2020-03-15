[bits 32]
%define ERROR_CODE nop
%define ZERO push 0

extern idt_table

section .data
global intr_entry_table
intr_entry_table:

%macro VECTOR 2
	section .text
	intr%1entry:
		%2
		push ds
		push es
		push fs
		push gs
		pushad
		
		;如果是从片上进入到中断，除了往从片上发送EOI外，还要往主片上发送EOI
		mov al,0x20
		out 0xa0,al
		out 0x20,al
		
		push %1
		call [idt_table + %1*4]
		jmp intr_exit
		
	section .data
		dd intr%1entry
%endmacro

section .text
global intr_exit
intr_exit:
	add esp,4
	popad
	pop gs
	pop fs
	pop es
	pop ds
	add esp,4
	iretd

VECTOR 0X00,ZERO
VECTOR 0X01,ZERO
VECTOR 0X02,ZERO
VECTOR 0X03,ZERO
VECTOR 0X04,ZERO
VECTOR 0X05,ZERO
VECTOR 0X06,ZERO
VECTOR 0X07,ZERO
VECTOR 0X08,ZERO
VECTOR 0X09,ZERO
VECTOR 0X0a,ZERO
VECTOR 0X0b,ZERO
VECTOR 0X0c,ZERO
VECTOR 0X0d,ZERO
VECTOR 0X0e,ZERO
VECTOR 0X0f,ZERO
VECTOR 0X10,ZERO
VECTOR 0X11,ZERO
VECTOR 0X12,ZERO
VECTOR 0X13,ZERO
VECTOR 0X14,ZERO
VECTOR 0X15,ZERO
VECTOR 0X16,ZERO
VECTOR 0X17,ZERO
VECTOR 0X18,ZERO
VECTOR 0X19,ZERO
VECTOR 0X1a,ZERO
VECTOR 0X1b,ZERO
VECTOR 0X1c,ZERO
VECTOR 0X1d,ZERO
VECTOR 0X1e,ERROR_CODE
VECTOR 0X1f,ZERO

VECTOR 0x20,ZERO ;时钟中断对应的入口
VECTOR 0x21,ZERO ;键盘中断对应的入口
VECTOR 0x22,ZERO ;级联用的
VECTOR 0x23,ZERO ;串口2 对应的入口
VECTOR 0x24,ZERO ;串口1 对应的入口
VECTOR 0x25,ZERO ;并口2 对应的入口
VECTOR 0x26,ZERO ;软盘对应的入口
VECTOR 0x27,ZERO ;并口1 对应的入口
VECTOR 0x28,ZERO ;实时时钟对应的入口
VECTOR 0x29,ZERO ;重定向
VECTOR 0x2a,ZERO ;保留
VECTOR 0x2b,ZERO ;保留
VECTOR 0x2c,ZERO ;ps/2 鼠标
VECTOR 0x2d,ZERO ;fpu 浮点单元异常
VECTOR 0x2e,ZERO ;硬盘
VECTOR 0x2f,ZERO ;保留

