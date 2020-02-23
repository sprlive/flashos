#include "print.h"
#include "init.h"
void main(void){
	put_str("I am kernel\n");
	init_all();
	void* addr = get_kernel_pages(3);
	put_str("\n get_kernel_pages start vaddr is ");
	put_int((uint32_t)addr);
	put_str("\n");
	//asm volatile("sti");
	while(1);
}
