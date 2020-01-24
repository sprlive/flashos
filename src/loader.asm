%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

jmp protect_mode2

gdt:
;0描述符
	dd	0x00000000
	dd	0x00000000
;1描述符(4GB代码段描述符)
	dd	0x0000ffff
	dd	DESC_CODE_HIGH4
;2描述符(4GB数据段描述符)
	dd	0x0000ffff
	dd	DESC_DATA_HIGH4
;3描述符(28Kb的视频段描述符)
	dd	0x8000_0007
	dd	DESC_VIDEO_HIGH4
	
;一共4个8字节，就是+0x023
total_mem_bytes dd 0

lgdt_value:
	dw $-gdt-1	;高16位表示表的最后一个字节的偏移（表的大小-1） 
	dd gdt		;低32位表示起始位置（GDT的物理地址）

ards_buf times 244 db 0
ards_nr dw 0
		
idt:
	;在此安装中断/陷阱/任务门描述符

SELECTOR_CODE	equ	(0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA	equ	(0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO	equ	(0x0003<<3) + TI_GDT + RPL0

;一共 4*8+2+4+244+2=284 ，共 +0x300
protect_mode:
;计算内存容量
	xor ebx,ebx
	mov edx,0x534d4150
	mov di,ards_buf
.e820_mem_get_loop:
	mov eax,0x0000e820
	mov ecx,20
	int 0x15
	add di,cx
	inc word [ards_nr]
	cmp ebx,0
	jnz .e820_mem_get_loop
	mov cx,[ards_buf]
	xor edx,edx
.find_max_mem_area:
	mov eax,[ebx]
	add eax,[ebx+8]
	add ebx,20
	cmp edx,eax
	jge .next_ards
	mov edx,eax
.next_ards:
	loop .find_max_mem_area
	jmp .mem_get_ok
.mem_get_ok:
	mov [total_mem_bytes],edx

protect_mode2:
;进入32位
	lgdt [lgdt_value]
	in al,0x92
	or al,0000_0010b
	out 0x92,al
	cli
	mov eax,cr0
	or eax,1
	mov cr0,eax
	
	jmp dword SELECTOR_CODE:main
	
[bits 32]
;正式进入32位
main:
mov ax,SELECTOR_DATA
mov ds,ax
mov es,ax
mov ss,ax
mov esp,LOADER_STACK_TOP
mov ax,SELECTOR_VIDEO
mov gs,ax

mov byte [gs:0xa0],'3'
mov byte [gs:0xa2],'2'
mov byte [gs:0xa4],'m'
mov byte [gs:0xa6],'o'
mov byte [gs:0xa8],'d'

;加载kernel
mov eax,KERNEL_START_SECTOR		;kernel.bin所在的扇区号 0x9
mov ebx,KERNEL_BIN_BASE_ADDR	;写入的内存地址 0x70000
mov ecx,200						;读入的扇区数
call rd_disk_m_32

mov byte [gs:0x140],'l'
mov byte [gs:0x142],'o'
mov byte [gs:0x144],'a'
mov byte [gs:0x146],'d'
mov byte [gs:0x14a],'k'
mov byte [gs:0x14c],'e'
mov byte [gs:0x14e],'r'
mov byte [gs:0x150],'n'
mov byte [gs:0x152],'e'
mov byte [gs:0x154],'l'

;创建页表并初始化（页目录和页表）
call setup_page

sgdt [lgdt_value]
mov ebx,[lgdt_value+2]
or dword [ebx+0x18+4],0xc0000000
add dword [lgdt_value+2],0xc0000000
add esp,0xc0000000

mov eax,PAGE_DIR_TABLE_POS
mov cr3,eax

mov eax,cr0
or eax,0x80000000
mov cr0,eax

lgdt [lgdt_value]

mov byte [gs:0x1e0],'p'
mov byte [gs:0x1e2],'a'
mov byte [gs:0x1e4],'g'
mov byte [gs:0x1e6],'e'
mov byte [gs:0x1ea],'o'
mov byte [gs:0x1ec],'n'

;进入内核
call kernel_init

mov byte [gs:0x280],'i'
mov byte [gs:0x282],'n'
mov byte [gs:0x284],'i'
mov byte [gs:0x286],'t'
mov byte [gs:0x28a],'k'
mov byte [gs:0x28c],'e'
mov byte [gs:0x28e],'r'
mov byte [gs:0x290],'n'
mov byte [gs:0x292],'e'
mov byte [gs:0x294],'l'

mov esp,0xc009f000
jmp KERNEL_ENTRY_POINT

jmp		$

setup_page:
;先把页目录占用的空间逐字清零
	mov ecx,4096
	mov esi,0
.clear_page_dir:
	mov byte [PAGE_DIR_TABLE_POS+esi],0
	inc esi
	loop .clear_page_dir
	
;开始创建页目录项（PDE）
.create_pde:
	mov eax,PAGE_DIR_TABLE_POS
	add eax,0x1000; 此时eax为第一个页表的位置及属性
	mov ebx,eax
	or eax,111b
	mov [PAGE_DIR_TABLE_POS],eax
	mov [PAGE_DIR_TABLE_POS+0xc00],eax
	sub eax,0x1000
	mov [PAGE_DIR_TABLE_POS+4*1023],eax

;开始创建页表项（PTE）
	mov ecx,256
	mov esi,0
	mov edx,111b
.create_pte:
	mov [ebx+esi*4],edx
	add edx,4096
	inc esi
	loop .create_pte
	
;创建内核其他页表的页目录项（PDE）
	mov eax,PAGE_DIR_TABLE_POS
	add eax,0x2000
	or eax,111b
	mov ebx,PAGE_DIR_TABLE_POS
	mov ecx,254
	mov esi,769
.create_kernel_pde:
	mov [ebx+esi*4],eax
	inc esi
	add eax,0x1000
	loop .create_kernel_pde
	ret
	
	
; 保护模式的硬盘读取函数
rd_disk_m_32:

    mov esi, eax
    mov di, cx

    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi
    ; 保存LBA地址
    mov dx, 0x1f3
    out dx, al

    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al

    shr eax, cl
    mov dx, 0x1f5
    out dx, al

    shr eax, cl
    and al, 0x0f
    or al, 0xe0
    mov dx, 0x1f6
    out dx, al

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

.not_ready:
    nop
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .not_ready

    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax
    mov dx, 0x1f0

.go_on_read:
    in ax, dx
    mov [ds:ebx], ax
    add ebx, 2
    loop .go_on_read
    ret
	
; 将kernel.bin中的segment拷贝到编译的地址
kernel_init:
	xor eax,eax
	xor ebx,ebx	;记录程序头表地址（内核地址+程序头表偏移地址）
	xor ecx,ecx	;记录程序头中的数量
	xor edx,edx	;记录程序头表中每个条目的字节大小
	
	mov dx,[KERNEL_BIN_BASE_ADDR+42]	;偏移文件42字节处是e_phentsize
	mov ebx,[KERNEL_BIN_BASE_ADDR+28]	;偏移文件28字节处是e_phoff
	add ebx,KERNEL_BIN_BASE_ADDR
	mov cx,[KERNEL_BIN_BASE_ADDR+44]	;偏移文件44字节处是e_phnum
	
.each_segment:
	cmp byte [ebx+0],0	;p_type=0,说明此头未使用
	je .PTNULL
	
	push dword [ebx+16]	;p_filesz压入栈(mem_cpy第三个参数)
	mov eax,[ebx+4]
	add eax,KERNEL_BIN_BASE_ADDR
	push eax			;p_offset+内核地址=段地址(mem_cpy第二个参数)
	push dword [ebx+8]	;p_vaddr(mem_cpy第一个参数)
	call mem_cpy
	add esp,12
.PTNULL:
	add ebx,edx	;ebx指向下一个程序头
	loop .each_segment
	ret
	
;主子拷贝函数（dst,src,size）
mem_cpy:
	cld
	push ebp
	mov ebp,esp
	push ecx
	
	mov edi,[ebp+8]		;dst
	mov esi,[ebp+12]	;src
	mov ecx,[ebp+16]	;size
	rep movsb
	
	pop ecx
	pop ebp
	ret
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	