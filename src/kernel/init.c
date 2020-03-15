#include "init.h"
#include "print.h"
#include "interrupt.h"
#include "memory.h"
#include "../device/timer.h"
#include "../device/console.h"

// 负责初始化所有模块
void init_all() {
	put_str("init_all\n");
	idt_init();	// 初始化中断
	timer_init();	// 初始化 PIT
	mem_init();	// 初始化内存管理
	thread_init(); // 初始化线程相关结构
	console_init(); // 控制台初始化
	keyboard_init(); // 键盘初始化
}
