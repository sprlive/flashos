#include "print.h"
#include "init.h"
#include "thread.h"

void k_thread_a(void*);
void k_thread_b(void*);

int main(void){
	put_str("I am kernel\n");
	init_all();
	//void* addr = get_kernel_pages(3);
	//put_str("\n get_kernel_pages start vaddr is ");
	//put_int((uint32_t)addr);
	//put_str("\n");
	//asm volatile("sti");
	
	thread_start("k_thread_a", 31, k_thread_a, "argA ");
	thread_start("k_thread_b", 8, k_thread_b, "argB ");
	
	intr_enable();
	
	while(1) {
		put_str("Main ");
	}
	return 0;
}

void k_thread_a(void* arg) {
	char* para = arg;
	while(1) {
		put_str(para);
	}
}

void k_thread_b(void* arg) {
	char* para = arg;
	while(1) {
		put_str(para);
	}
}
