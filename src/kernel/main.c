#include "print.h"
#include "init.h"
#include "thread.h"
#include "interrupt.h"

#include "ioqueue.h"
#include "keyboard.h"
#include "process.h"

void k_thread_a(void*);
void k_thread_b(void*);
void u_prog_a(void);
void u_prog_b(void);
int test_var_a = 0, test_var_b = 0;

int main(void){
	put_str("I am kernel\n");
	init_all();
	
	thread_start("threadA", 31, k_thread_a, "AOUT_");
	thread_start("threadB", 31, k_thread_b, "BOUT_");
	//thread_start("userProcessA", 31, u_prog_a, "AOUT_");
	//thread_start("userProcessB", 31, u_prog_b, "BOUT_");
	//process_execute(u_prog_a, "userProcessA");
	//process_execute(u_prog_b, "userProcessB");
	
	intr_enable();
	
	while(1) {
		//console_put_str("Main ");
	}
	return 0;
}

void k_thread_a(void* arg) {
	char* para = arg;
	while(1) {
		console_put_str("threadA:");
		console_put_int(test_var_a);
	}
}

void k_thread_b(void* arg) {
	char* para = arg;
	while(1) {
		console_put_str("threadB:");
		console_put_int(test_var_b);
	}
}

void u_prog_a(void) {
	while(1) {
		//test_var_a++;
		console_put_str("userProcessA:");
		console_put_int(test_var_a);
	}
}

void u_prog_b(void) {
	while(1) {
		//test_var_b++;
		console_put_str("userProcessB:");
		console_put_int(test_var_b);
	}
}
