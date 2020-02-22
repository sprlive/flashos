mbr.bin: mbr.asm
	nasm -I include/ -o out/mbr.bin mbr.asm -l out/mbr.lst
	
loader.bin: loader.asm
	nasm -I include/ -o out/loader.bin loader.asm -l out/loader.lst
	
kernel.bin: kernel/main.c
	gcc -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o out/main.o kernel/main.c
	nasm -f elf -o out/print.o lib/kernel/print.asm -l out/print.lst
	nasm -f elf -o out/kernel.o kernel/kernel.asm -l out/kernel.lst
	gcc -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o out/string.o lib/string.c
	gcc -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o out/interrupt.o kernel/interrupt.c
	gcc -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o out/init.o kernel/init.c
	gcc -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o out/bitmap.o kernel/bitmap.c
	gcc -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o out/memory.o kernel/memory.c
	ld -Ttext 0xc0001500 -e main -o out/kernel.bin out/main.o out/init.o out/interrupt.o out/print.o out/kernel.o out/memory.o out/bitmap.o out/string.o
	
os.raw: mbr.bin loader.bin kernel.bin
	../bochs/bin/bximage -hd -mode="flat" -size=60 -q target/os.raw
	dd if=out/mbr.bin of=target/os.raw bs=512 count=1
	dd if=out/loader.bin of=target/os.raw bs=512 count=4 seek=2
	dd if=out/kernel.bin of=target/os.raw bs=512 count=200 seek=9
	
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
	rm -rf target/*
	rm -rf out/*
	rm -rf os.raw
	rm -rf os.raw.lock
	rm -rf bochs.out
