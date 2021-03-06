LIB = -I lib/kernel/ -I lib/ -I kernel/ -I thread/ -I device/ -I userprog/
GCCPARAM = -c -fno-builtin
TARGET = ../bochs/hd60M.img
OSTARGET = target/os.raw

mbr.bin: mbr.asm
	nasm -I include/ -o out/mbr.bin mbr.asm -l out/mbr.lst
	
loader.bin: loader.asm
	nasm -I include/ -o out/loader.bin loader.asm -l out/loader.lst
	
kernel.bin: kernel/main.c
	nasm -f elf -o out/print.o lib/kernel/print.asm -l out/print.lst
	nasm -f elf -o out/kernel.o kernel/kernel.asm -l out/kernel.lst
	nasm -f elf -o out/switch.o thread/switch.asm -l out/switch.lst
	gcc $(LIB) $(GCCPARAM) -o out/main.o	kernel/main.c
	gcc $(LIB) $(GCCPARAM) -o out/string.o	lib/string.c
	gcc $(LIB) $(GCCPARAM) -o out/list.o	lib/kernel/list.c
	gcc $(LIB) $(GCCPARAM) -o out/interrupt.o	kernel/interrupt.c
	gcc $(LIB) $(GCCPARAM) -o out/init.o	kernel/init.c
	gcc $(LIB) $(GCCPARAM) -o out/bitmap.o	kernel/bitmap.c
	gcc $(LIB) $(GCCPARAM) -o out/memory.o	kernel/memory.c
	gcc $(LIB) $(GCCPARAM) -o out/debug.o	kernel/debug.c
	gcc $(LIB) $(GCCPARAM) -o out/thread.o	thread/thread.c
	gcc $(LIB) $(GCCPARAM) -o out/sync.o	thread/sync.c
	gcc $(LIB) $(GCCPARAM) -o out/timer.o	device/timer.c
	gcc $(LIB) $(GCCPARAM) -o out/console.o	device/console.c
	gcc $(LIB) $(GCCPARAM) -o out/keyboard.o	device/keyboard.c
	gcc $(LIB) $(GCCPARAM) -o out/ioqueue.o	device/ioqueue.c
	gcc $(LIB) $(GCCPARAM) -o out/tss.o	userprog/tss.c
	gcc $(LIB) $(GCCPARAM) -o out/process.o	userprog/process.c
	ld -Ttext 0xc0001500 -e main -o \
		out/kernel.bin \
		out/main.o \
		out/init.o \
		out/interrupt.o \
		out/print.o \
		out/kernel.o \
		out/switch.o \
		out/memory.o \
		out/debug.o \
		out/bitmap.o \
		out/string.o \
		out/list.o \
		out/thread.o \
		out/timer.o \
		out/sync.o \
		out/console.o \
		out/ioqueue.o \
		out/tss.o \
		out/process.o \
		out/keyboard.o
	
os.raw: mbr.bin loader.bin kernel.bin
	../bochs/bin/bximage -hd -mode="flat" -size=60 -q target/os.raw
	dd if=out/mbr.bin of=${OSTARGET} bs=512 count=1 conv=notrunc
	dd if=out/loader.bin of=${OSTARGET} bs=512 count=4 seek=2 conv=notrunc
	dd if=out/kernel.bin of=${OSTARGET} bs=512 count=200 seek=9 conv=notrunc
	
run:
	make install
	make only-qemu-run
	
brun:
	make install
	make only-bochs-run
	
bdrun:
	make install
	make only-bochsdbg-run
	
only-qemu-run:
	qemu-system-i386 -m 512 target/os.raw
	
only-bochs-run:
	../bochs/bin/bochs -f ../bochs/bochsrc.disk -q
	
only-bochsdbg-run:
	../bochs/bin/bochs -f ../bochs/bochsrc.disk -q
	
only-run-s:
	qemu-system-i386 -s -S -m 512 target/os.raw --nographic
	
install:
	make clean
	make -r os.raw
	
clean:
	del /q target
	del /q out
	del os.raw
	del os.raw.lock
	del bochs.out
