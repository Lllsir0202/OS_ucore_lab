
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	00e60613          	addi	a2,a2,14 # 80204020 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	1c5000ef          	jal	ra,802009e6 <memset>

    cons_init();  // init the console
    80200026:	150000ef          	jal	ra,80200176 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	9ce58593          	addi	a1,a1,-1586 # 802009f8 <etext>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	9e650513          	addi	a0,a0,-1562 # 80200a18 <etext+0x20>
    8020003a:	036000ef          	jal	ra,80200070 <cprintf>

    print_kerninfo();
    8020003e:	068000ef          	jal	ra,802000a6 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	144000ef          	jal	ra,80200186 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0ee000ef          	jal	ra,80200134 <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	136000ef          	jal	ra,80200180 <intr_enable>
    
    __asm__ ("ebreak"::);
    8020004e:	9002                	ebreak
    __asm__ ("mret"::);
    80200050:	30200073          	mret

    while (1)
    80200054:	a001                	j	80200054 <kern_init+0x4a>

0000000080200056 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200056:	1141                	addi	sp,sp,-16
    80200058:	e022                	sd	s0,0(sp)
    8020005a:	e406                	sd	ra,8(sp)
    8020005c:	842e                	mv	s0,a1
    cons_putc(c);
    8020005e:	11a000ef          	jal	ra,80200178 <cons_putc>
    (*cnt)++;
    80200062:	401c                	lw	a5,0(s0)
}
    80200064:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200066:	2785                	addiw	a5,a5,1
    80200068:	c01c                	sw	a5,0(s0)
}
    8020006a:	6402                	ld	s0,0(sp)
    8020006c:	0141                	addi	sp,sp,16
    8020006e:	8082                	ret

0000000080200070 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200070:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    80200072:	02810313          	addi	t1,sp,40 # 80204028 <end+0x8>
int cprintf(const char *fmt, ...) {
    80200076:	8e2a                	mv	t3,a0
    80200078:	f42e                	sd	a1,40(sp)
    8020007a:	f832                	sd	a2,48(sp)
    8020007c:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020007e:	00000517          	auipc	a0,0x0
    80200082:	fd850513          	addi	a0,a0,-40 # 80200056 <cputch>
    80200086:	004c                	addi	a1,sp,4
    80200088:	869a                	mv	a3,t1
    8020008a:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    8020008c:	ec06                	sd	ra,24(sp)
    8020008e:	e0ba                	sd	a4,64(sp)
    80200090:	e4be                	sd	a5,72(sp)
    80200092:	e8c2                	sd	a6,80(sp)
    80200094:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200096:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200098:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020009a:	560000ef          	jal	ra,802005fa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    8020009e:	60e2                	ld	ra,24(sp)
    802000a0:	4512                	lw	a0,4(sp)
    802000a2:	6125                	addi	sp,sp,96
    802000a4:	8082                	ret

00000000802000a6 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a6:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a8:	00001517          	auipc	a0,0x1
    802000ac:	97850513          	addi	a0,a0,-1672 # 80200a20 <etext+0x28>
void print_kerninfo(void) {
    802000b0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000b2:	fbfff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b6:	00000597          	auipc	a1,0x0
    802000ba:	f5458593          	addi	a1,a1,-172 # 8020000a <kern_init>
    802000be:	00001517          	auipc	a0,0x1
    802000c2:	98250513          	addi	a0,a0,-1662 # 80200a40 <etext+0x48>
    802000c6:	fabff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000ca:	00001597          	auipc	a1,0x1
    802000ce:	92e58593          	addi	a1,a1,-1746 # 802009f8 <etext>
    802000d2:	00001517          	auipc	a0,0x1
    802000d6:	98e50513          	addi	a0,a0,-1650 # 80200a60 <etext+0x68>
    802000da:	f97ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000de:	00004597          	auipc	a1,0x4
    802000e2:	f3258593          	addi	a1,a1,-206 # 80204010 <ticks>
    802000e6:	00001517          	auipc	a0,0x1
    802000ea:	99a50513          	addi	a0,a0,-1638 # 80200a80 <etext+0x88>
    802000ee:	f83ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000f2:	00004597          	auipc	a1,0x4
    802000f6:	f2e58593          	addi	a1,a1,-210 # 80204020 <end>
    802000fa:	00001517          	auipc	a0,0x1
    802000fe:	9a650513          	addi	a0,a0,-1626 # 80200aa0 <etext+0xa8>
    80200102:	f6fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200106:	00004597          	auipc	a1,0x4
    8020010a:	31958593          	addi	a1,a1,793 # 8020441f <end+0x3ff>
    8020010e:	00000797          	auipc	a5,0x0
    80200112:	efc78793          	addi	a5,a5,-260 # 8020000a <kern_init>
    80200116:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	43f7d593          	srai	a1,a5,0x3f
}
    8020011e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200120:	3ff5f593          	andi	a1,a1,1023
    80200124:	95be                	add	a1,a1,a5
    80200126:	85a9                	srai	a1,a1,0xa
    80200128:	00001517          	auipc	a0,0x1
    8020012c:	99850513          	addi	a0,a0,-1640 # 80200ac0 <etext+0xc8>
}
    80200130:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200132:	bf3d                	j	80200070 <cprintf>

0000000080200134 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    80200134:	1141                	addi	sp,sp,-16
    80200136:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200138:	02000793          	li	a5,32
    8020013c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200140:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200144:	67e1                	lui	a5,0x18
    80200146:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    8020014a:	953e                	add	a0,a0,a5
    8020014c:	04b000ef          	jal	ra,80200996 <sbi_set_timer>
}
    80200150:	60a2                	ld	ra,8(sp)
    ticks = 0;
    80200152:	00004797          	auipc	a5,0x4
    80200156:	ea07bf23          	sd	zero,-322(a5) # 80204010 <ticks>
    cprintf("++ setup timer interrupts\n");
    8020015a:	00001517          	auipc	a0,0x1
    8020015e:	99650513          	addi	a0,a0,-1642 # 80200af0 <etext+0xf8>
}
    80200162:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    80200164:	b731                	j	80200070 <cprintf>

0000000080200166 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200166:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020016a:	67e1                	lui	a5,0x18
    8020016c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200170:	953e                	add	a0,a0,a5
    80200172:	0250006f          	j	80200996 <sbi_set_timer>

0000000080200176 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200176:	8082                	ret

0000000080200178 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200178:	0ff57513          	zext.b	a0,a0
    8020017c:	0010006f          	j	8020097c <sbi_console_putchar>

0000000080200180 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    80200180:	100167f3          	csrrsi	a5,sstatus,2
    80200184:	8082                	ret

0000000080200186 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200186:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    8020018a:	00000797          	auipc	a5,0x0
    8020018e:	34e78793          	addi	a5,a5,846 # 802004d8 <__alltraps>
    80200192:	10579073          	csrw	stvec,a5
}
    80200196:	8082                	ret

0000000080200198 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200198:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    8020019a:	1141                	addi	sp,sp,-16
    8020019c:	e022                	sd	s0,0(sp)
    8020019e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a0:	00001517          	auipc	a0,0x1
    802001a4:	97050513          	addi	a0,a0,-1680 # 80200b10 <etext+0x118>
void print_regs(struct pushregs *gpr) {
    802001a8:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001aa:	ec7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001ae:	640c                	ld	a1,8(s0)
    802001b0:	00001517          	auipc	a0,0x1
    802001b4:	97850513          	addi	a0,a0,-1672 # 80200b28 <etext+0x130>
    802001b8:	eb9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001bc:	680c                	ld	a1,16(s0)
    802001be:	00001517          	auipc	a0,0x1
    802001c2:	98250513          	addi	a0,a0,-1662 # 80200b40 <etext+0x148>
    802001c6:	eabff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001ca:	6c0c                	ld	a1,24(s0)
    802001cc:	00001517          	auipc	a0,0x1
    802001d0:	98c50513          	addi	a0,a0,-1652 # 80200b58 <etext+0x160>
    802001d4:	e9dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001d8:	700c                	ld	a1,32(s0)
    802001da:	00001517          	auipc	a0,0x1
    802001de:	99650513          	addi	a0,a0,-1642 # 80200b70 <etext+0x178>
    802001e2:	e8fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e6:	740c                	ld	a1,40(s0)
    802001e8:	00001517          	auipc	a0,0x1
    802001ec:	9a050513          	addi	a0,a0,-1632 # 80200b88 <etext+0x190>
    802001f0:	e81ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001f4:	780c                	ld	a1,48(s0)
    802001f6:	00001517          	auipc	a0,0x1
    802001fa:	9aa50513          	addi	a0,a0,-1622 # 80200ba0 <etext+0x1a8>
    802001fe:	e73ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200202:	7c0c                	ld	a1,56(s0)
    80200204:	00001517          	auipc	a0,0x1
    80200208:	9b450513          	addi	a0,a0,-1612 # 80200bb8 <etext+0x1c0>
    8020020c:	e65ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    80200210:	602c                	ld	a1,64(s0)
    80200212:	00001517          	auipc	a0,0x1
    80200216:	9be50513          	addi	a0,a0,-1602 # 80200bd0 <etext+0x1d8>
    8020021a:	e57ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    8020021e:	642c                	ld	a1,72(s0)
    80200220:	00001517          	auipc	a0,0x1
    80200224:	9c850513          	addi	a0,a0,-1592 # 80200be8 <etext+0x1f0>
    80200228:	e49ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    8020022c:	682c                	ld	a1,80(s0)
    8020022e:	00001517          	auipc	a0,0x1
    80200232:	9d250513          	addi	a0,a0,-1582 # 80200c00 <etext+0x208>
    80200236:	e3bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    8020023a:	6c2c                	ld	a1,88(s0)
    8020023c:	00001517          	auipc	a0,0x1
    80200240:	9dc50513          	addi	a0,a0,-1572 # 80200c18 <etext+0x220>
    80200244:	e2dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200248:	702c                	ld	a1,96(s0)
    8020024a:	00001517          	auipc	a0,0x1
    8020024e:	9e650513          	addi	a0,a0,-1562 # 80200c30 <etext+0x238>
    80200252:	e1fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200256:	742c                	ld	a1,104(s0)
    80200258:	00001517          	auipc	a0,0x1
    8020025c:	9f050513          	addi	a0,a0,-1552 # 80200c48 <etext+0x250>
    80200260:	e11ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    80200264:	782c                	ld	a1,112(s0)
    80200266:	00001517          	auipc	a0,0x1
    8020026a:	9fa50513          	addi	a0,a0,-1542 # 80200c60 <etext+0x268>
    8020026e:	e03ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200272:	7c2c                	ld	a1,120(s0)
    80200274:	00001517          	auipc	a0,0x1
    80200278:	a0450513          	addi	a0,a0,-1532 # 80200c78 <etext+0x280>
    8020027c:	df5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    80200280:	604c                	ld	a1,128(s0)
    80200282:	00001517          	auipc	a0,0x1
    80200286:	a0e50513          	addi	a0,a0,-1522 # 80200c90 <etext+0x298>
    8020028a:	de7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    8020028e:	644c                	ld	a1,136(s0)
    80200290:	00001517          	auipc	a0,0x1
    80200294:	a1850513          	addi	a0,a0,-1512 # 80200ca8 <etext+0x2b0>
    80200298:	dd9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    8020029c:	684c                	ld	a1,144(s0)
    8020029e:	00001517          	auipc	a0,0x1
    802002a2:	a2250513          	addi	a0,a0,-1502 # 80200cc0 <etext+0x2c8>
    802002a6:	dcbff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002aa:	6c4c                	ld	a1,152(s0)
    802002ac:	00001517          	auipc	a0,0x1
    802002b0:	a2c50513          	addi	a0,a0,-1492 # 80200cd8 <etext+0x2e0>
    802002b4:	dbdff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002b8:	704c                	ld	a1,160(s0)
    802002ba:	00001517          	auipc	a0,0x1
    802002be:	a3650513          	addi	a0,a0,-1482 # 80200cf0 <etext+0x2f8>
    802002c2:	dafff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c6:	744c                	ld	a1,168(s0)
    802002c8:	00001517          	auipc	a0,0x1
    802002cc:	a4050513          	addi	a0,a0,-1472 # 80200d08 <etext+0x310>
    802002d0:	da1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002d4:	784c                	ld	a1,176(s0)
    802002d6:	00001517          	auipc	a0,0x1
    802002da:	a4a50513          	addi	a0,a0,-1462 # 80200d20 <etext+0x328>
    802002de:	d93ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e2:	7c4c                	ld	a1,184(s0)
    802002e4:	00001517          	auipc	a0,0x1
    802002e8:	a5450513          	addi	a0,a0,-1452 # 80200d38 <etext+0x340>
    802002ec:	d85ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002f0:	606c                	ld	a1,192(s0)
    802002f2:	00001517          	auipc	a0,0x1
    802002f6:	a5e50513          	addi	a0,a0,-1442 # 80200d50 <etext+0x358>
    802002fa:	d77ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002fe:	646c                	ld	a1,200(s0)
    80200300:	00001517          	auipc	a0,0x1
    80200304:	a6850513          	addi	a0,a0,-1432 # 80200d68 <etext+0x370>
    80200308:	d69ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    8020030c:	686c                	ld	a1,208(s0)
    8020030e:	00001517          	auipc	a0,0x1
    80200312:	a7250513          	addi	a0,a0,-1422 # 80200d80 <etext+0x388>
    80200316:	d5bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    8020031a:	6c6c                	ld	a1,216(s0)
    8020031c:	00001517          	auipc	a0,0x1
    80200320:	a7c50513          	addi	a0,a0,-1412 # 80200d98 <etext+0x3a0>
    80200324:	d4dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200328:	706c                	ld	a1,224(s0)
    8020032a:	00001517          	auipc	a0,0x1
    8020032e:	a8650513          	addi	a0,a0,-1402 # 80200db0 <etext+0x3b8>
    80200332:	d3fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200336:	746c                	ld	a1,232(s0)
    80200338:	00001517          	auipc	a0,0x1
    8020033c:	a9050513          	addi	a0,a0,-1392 # 80200dc8 <etext+0x3d0>
    80200340:	d31ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    80200344:	786c                	ld	a1,240(s0)
    80200346:	00001517          	auipc	a0,0x1
    8020034a:	a9a50513          	addi	a0,a0,-1382 # 80200de0 <etext+0x3e8>
    8020034e:	d23ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200352:	7c6c                	ld	a1,248(s0)
}
    80200354:	6402                	ld	s0,0(sp)
    80200356:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200358:	00001517          	auipc	a0,0x1
    8020035c:	aa050513          	addi	a0,a0,-1376 # 80200df8 <etext+0x400>
}
    80200360:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200362:	b339                	j	80200070 <cprintf>

0000000080200364 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    80200364:	1141                	addi	sp,sp,-16
    80200366:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200368:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    8020036a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    8020036c:	00001517          	auipc	a0,0x1
    80200370:	aa450513          	addi	a0,a0,-1372 # 80200e10 <etext+0x418>
void print_trapframe(struct trapframe *tf) {
    80200374:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200376:	cfbff0ef          	jal	ra,80200070 <cprintf>
    print_regs(&tf->gpr);
    8020037a:	8522                	mv	a0,s0
    8020037c:	e1dff0ef          	jal	ra,80200198 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    80200380:	10043583          	ld	a1,256(s0)
    80200384:	00001517          	auipc	a0,0x1
    80200388:	aa450513          	addi	a0,a0,-1372 # 80200e28 <etext+0x430>
    8020038c:	ce5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    80200390:	10843583          	ld	a1,264(s0)
    80200394:	00001517          	auipc	a0,0x1
    80200398:	aac50513          	addi	a0,a0,-1364 # 80200e40 <etext+0x448>
    8020039c:	cd5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    802003a0:	11043583          	ld	a1,272(s0)
    802003a4:	00001517          	auipc	a0,0x1
    802003a8:	ab450513          	addi	a0,a0,-1356 # 80200e58 <etext+0x460>
    802003ac:	cc5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b0:	11843583          	ld	a1,280(s0)
}
    802003b4:	6402                	ld	s0,0(sp)
    802003b6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b8:	00001517          	auipc	a0,0x1
    802003bc:	ab850513          	addi	a0,a0,-1352 # 80200e70 <etext+0x478>
}
    802003c0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c2:	b17d                	j	80200070 <cprintf>

00000000802003c4 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003c4:	11853783          	ld	a5,280(a0)
    802003c8:	472d                	li	a4,11
    802003ca:	0786                	slli	a5,a5,0x1
    802003cc:	8385                	srli	a5,a5,0x1
    802003ce:	06f76f63          	bltu	a4,a5,8020044c <interrupt_handler+0x88>
    802003d2:	00001717          	auipc	a4,0x1
    802003d6:	b6670713          	addi	a4,a4,-1178 # 80200f38 <etext+0x540>
    802003da:	078a                	slli	a5,a5,0x2
    802003dc:	97ba                	add	a5,a5,a4
    802003de:	439c                	lw	a5,0(a5)
    802003e0:	97ba                	add	a5,a5,a4
    802003e2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003e4:	00001517          	auipc	a0,0x1
    802003e8:	b0450513          	addi	a0,a0,-1276 # 80200ee8 <etext+0x4f0>
    802003ec:	b151                	j	80200070 <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003ee:	00001517          	auipc	a0,0x1
    802003f2:	ada50513          	addi	a0,a0,-1318 # 80200ec8 <etext+0x4d0>
    802003f6:	b9ad                	j	80200070 <cprintf>
            cprintf("User software interrupt\n");
    802003f8:	00001517          	auipc	a0,0x1
    802003fc:	a9050513          	addi	a0,a0,-1392 # 80200e88 <etext+0x490>
    80200400:	b985                	j	80200070 <cprintf>
            cprintf("Supervisor software interrupt\n");
    80200402:	00001517          	auipc	a0,0x1
    80200406:	aa650513          	addi	a0,a0,-1370 # 80200ea8 <etext+0x4b0>
    8020040a:	b19d                	j	80200070 <cprintf>
void interrupt_handler(struct trapframe *tf) {
    8020040c:	1141                	addi	sp,sp,-16
    8020040e:	e022                	sd	s0,0(sp)
    80200410:	e406                	sd	ra,8(sp)
            */
            //设置下一次中断为1000000次时钟中断后，即大约1s输出一次100ticks
            clock_set_next_event();

            //计数器加一
            ticks++;
    80200412:	00004417          	auipc	s0,0x4
    80200416:	bfe40413          	addi	s0,s0,-1026 # 80204010 <ticks>
            clock_set_next_event();
    8020041a:	d4dff0ef          	jal	ra,80200166 <clock_set_next_event>
            ticks++;
    8020041e:	601c                	ld	a5,0(s0)

            //调用print
            if(ticks % TICK_NUM == 0){
    80200420:	06400713          	li	a4,100
            ticks++;
    80200424:	0785                	addi	a5,a5,1
    80200426:	e01c                	sd	a5,0(s0)
            if(ticks % TICK_NUM == 0){
    80200428:	601c                	ld	a5,0(s0)
    8020042a:	02e7f7b3          	remu	a5,a5,a4
    8020042e:	c385                	beqz	a5,8020044e <interrupt_handler+0x8a>
                print_ticks();
            }

            if(ticks == 1000){
    80200430:	6018                	ld	a4,0(s0)
    80200432:	3e800793          	li	a5,1000
    80200436:	02f70563          	beq	a4,a5,80200460 <interrupt_handler+0x9c>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    8020043a:	60a2                	ld	ra,8(sp)
    8020043c:	6402                	ld	s0,0(sp)
    8020043e:	0141                	addi	sp,sp,16
    80200440:	8082                	ret
            cprintf("Supervisor external interrupt\n");
    80200442:	00001517          	auipc	a0,0x1
    80200446:	ad650513          	addi	a0,a0,-1322 # 80200f18 <etext+0x520>
    8020044a:	b11d                	j	80200070 <cprintf>
            print_trapframe(tf);
    8020044c:	bf21                	j	80200364 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    8020044e:	06400593          	li	a1,100
    80200452:	00001517          	auipc	a0,0x1
    80200456:	ab650513          	addi	a0,a0,-1354 # 80200f08 <etext+0x510>
    8020045a:	c17ff0ef          	jal	ra,80200070 <cprintf>
}
    8020045e:	bfc9                	j	80200430 <interrupt_handler+0x6c>
}
    80200460:	6402                	ld	s0,0(sp)
    80200462:	60a2                	ld	ra,8(sp)
    80200464:	0141                	addi	sp,sp,16
                sbi_shutdown();
    80200466:	a3a9                	j	802009b0 <sbi_shutdown>

0000000080200468 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    80200468:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
    8020046c:	1141                	addi	sp,sp,-16
    8020046e:	e022                	sd	s0,0(sp)
    80200470:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
    80200472:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
    80200474:	842a                	mv	s0,a0
    switch (tf->cause) {
    80200476:	04e78663          	beq	a5,a4,802004c2 <exception_handler+0x5a>
    8020047a:	02f76c63          	bltu	a4,a5,802004b2 <exception_handler+0x4a>
    8020047e:	4709                	li	a4,2
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            //输出指令异常类型
            cprintf("Instruction Exception: Illegal instruction\n");
    80200480:	00001517          	auipc	a0,0x1
    80200484:	ae850513          	addi	a0,a0,-1304 # 80200f68 <etext+0x570>
    switch (tf->cause) {
    80200488:	02e79163          	bne	a5,a4,802004aa <exception_handler+0x42>
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            //输出指令异常类型
            cprintf("Instruction Exception: breakpoint\n");
    8020048c:	be5ff0ef          	jal	ra,80200070 <cprintf>
            
            //输出异常指令地址
            cprintf("at 0x%08x \n",tf->epc);
    80200490:	10843583          	ld	a1,264(s0)
    80200494:	00001517          	auipc	a0,0x1
    80200498:	b0450513          	addi	a0,a0,-1276 # 80200f98 <etext+0x5a0>
    8020049c:	bd5ff0ef          	jal	ra,80200070 <cprintf>

            //更新tf->epc
            tf->epc = tf->epc + 2;
    802004a0:	10843783          	ld	a5,264(s0)
    802004a4:	0789                	addi	a5,a5,2
    802004a6:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    802004aa:	60a2                	ld	ra,8(sp)
    802004ac:	6402                	ld	s0,0(sp)
    802004ae:	0141                	addi	sp,sp,16
    802004b0:	8082                	ret
    switch (tf->cause) {
    802004b2:	17f1                	addi	a5,a5,-4
    802004b4:	471d                	li	a4,7
    802004b6:	fef77ae3          	bgeu	a4,a5,802004aa <exception_handler+0x42>
}
    802004ba:	6402                	ld	s0,0(sp)
    802004bc:	60a2                	ld	ra,8(sp)
    802004be:	0141                	addi	sp,sp,16
            print_trapframe(tf);
    802004c0:	b555                	j	80200364 <print_trapframe>
            cprintf("Instruction Exception: breakpoint\n");
    802004c2:	00001517          	auipc	a0,0x1
    802004c6:	ae650513          	addi	a0,a0,-1306 # 80200fa8 <etext+0x5b0>
    802004ca:	b7c9                	j	8020048c <exception_handler+0x24>

00000000802004cc <trap>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    802004cc:	11853783          	ld	a5,280(a0)
    802004d0:	0007c363          	bltz	a5,802004d6 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    802004d4:	bf51                	j	80200468 <exception_handler>
        interrupt_handler(tf);
    802004d6:	b5fd                	j	802003c4 <interrupt_handler>

00000000802004d8 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    802004d8:	14011073          	csrw	sscratch,sp
    802004dc:	712d                	addi	sp,sp,-288
    802004de:	e002                	sd	zero,0(sp)
    802004e0:	e406                	sd	ra,8(sp)
    802004e2:	ec0e                	sd	gp,24(sp)
    802004e4:	f012                	sd	tp,32(sp)
    802004e6:	f416                	sd	t0,40(sp)
    802004e8:	f81a                	sd	t1,48(sp)
    802004ea:	fc1e                	sd	t2,56(sp)
    802004ec:	e0a2                	sd	s0,64(sp)
    802004ee:	e4a6                	sd	s1,72(sp)
    802004f0:	e8aa                	sd	a0,80(sp)
    802004f2:	ecae                	sd	a1,88(sp)
    802004f4:	f0b2                	sd	a2,96(sp)
    802004f6:	f4b6                	sd	a3,104(sp)
    802004f8:	f8ba                	sd	a4,112(sp)
    802004fa:	fcbe                	sd	a5,120(sp)
    802004fc:	e142                	sd	a6,128(sp)
    802004fe:	e546                	sd	a7,136(sp)
    80200500:	e94a                	sd	s2,144(sp)
    80200502:	ed4e                	sd	s3,152(sp)
    80200504:	f152                	sd	s4,160(sp)
    80200506:	f556                	sd	s5,168(sp)
    80200508:	f95a                	sd	s6,176(sp)
    8020050a:	fd5e                	sd	s7,184(sp)
    8020050c:	e1e2                	sd	s8,192(sp)
    8020050e:	e5e6                	sd	s9,200(sp)
    80200510:	e9ea                	sd	s10,208(sp)
    80200512:	edee                	sd	s11,216(sp)
    80200514:	f1f2                	sd	t3,224(sp)
    80200516:	f5f6                	sd	t4,232(sp)
    80200518:	f9fa                	sd	t5,240(sp)
    8020051a:	fdfe                	sd	t6,248(sp)
    8020051c:	14001473          	csrrw	s0,sscratch,zero
    80200520:	100024f3          	csrr	s1,sstatus
    80200524:	14102973          	csrr	s2,sepc
    80200528:	143029f3          	csrr	s3,stval
    8020052c:	14202a73          	csrr	s4,scause
    80200530:	e822                	sd	s0,16(sp)
    80200532:	e226                	sd	s1,256(sp)
    80200534:	e64a                	sd	s2,264(sp)
    80200536:	ea4e                	sd	s3,272(sp)
    80200538:	ee52                	sd	s4,280(sp)

    move  a0, sp
    8020053a:	850a                	mv	a0,sp
    jal trap
    8020053c:	f91ff0ef          	jal	ra,802004cc <trap>

0000000080200540 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    80200540:	6492                	ld	s1,256(sp)
    80200542:	6932                	ld	s2,264(sp)
    80200544:	10049073          	csrw	sstatus,s1
    80200548:	14191073          	csrw	sepc,s2
    8020054c:	60a2                	ld	ra,8(sp)
    8020054e:	61e2                	ld	gp,24(sp)
    80200550:	7202                	ld	tp,32(sp)
    80200552:	72a2                	ld	t0,40(sp)
    80200554:	7342                	ld	t1,48(sp)
    80200556:	73e2                	ld	t2,56(sp)
    80200558:	6406                	ld	s0,64(sp)
    8020055a:	64a6                	ld	s1,72(sp)
    8020055c:	6546                	ld	a0,80(sp)
    8020055e:	65e6                	ld	a1,88(sp)
    80200560:	7606                	ld	a2,96(sp)
    80200562:	76a6                	ld	a3,104(sp)
    80200564:	7746                	ld	a4,112(sp)
    80200566:	77e6                	ld	a5,120(sp)
    80200568:	680a                	ld	a6,128(sp)
    8020056a:	68aa                	ld	a7,136(sp)
    8020056c:	694a                	ld	s2,144(sp)
    8020056e:	69ea                	ld	s3,152(sp)
    80200570:	7a0a                	ld	s4,160(sp)
    80200572:	7aaa                	ld	s5,168(sp)
    80200574:	7b4a                	ld	s6,176(sp)
    80200576:	7bea                	ld	s7,184(sp)
    80200578:	6c0e                	ld	s8,192(sp)
    8020057a:	6cae                	ld	s9,200(sp)
    8020057c:	6d4e                	ld	s10,208(sp)
    8020057e:	6dee                	ld	s11,216(sp)
    80200580:	7e0e                	ld	t3,224(sp)
    80200582:	7eae                	ld	t4,232(sp)
    80200584:	7f4e                	ld	t5,240(sp)
    80200586:	7fee                	ld	t6,248(sp)
    80200588:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    8020058a:	10200073          	sret

000000008020058e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    8020058e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200592:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200594:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200598:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    8020059a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    8020059e:	f022                	sd	s0,32(sp)
    802005a0:	ec26                	sd	s1,24(sp)
    802005a2:	e84a                	sd	s2,16(sp)
    802005a4:	f406                	sd	ra,40(sp)
    802005a6:	e44e                	sd	s3,8(sp)
    802005a8:	84aa                	mv	s1,a0
    802005aa:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    802005ac:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    802005b0:	2a01                	sext.w	s4,s4
    if (num >= base) {
    802005b2:	03067e63          	bgeu	a2,a6,802005ee <printnum+0x60>
    802005b6:	89be                	mv	s3,a5
        while (-- width > 0)
    802005b8:	00805763          	blez	s0,802005c6 <printnum+0x38>
    802005bc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    802005be:	85ca                	mv	a1,s2
    802005c0:	854e                	mv	a0,s3
    802005c2:	9482                	jalr	s1
        while (-- width > 0)
    802005c4:	fc65                	bnez	s0,802005bc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    802005c6:	1a02                	slli	s4,s4,0x20
    802005c8:	00001797          	auipc	a5,0x1
    802005cc:	a0878793          	addi	a5,a5,-1528 # 80200fd0 <etext+0x5d8>
    802005d0:	020a5a13          	srli	s4,s4,0x20
    802005d4:	9a3e                	add	s4,s4,a5
}
    802005d6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    802005d8:	000a4503          	lbu	a0,0(s4)
}
    802005dc:	70a2                	ld	ra,40(sp)
    802005de:	69a2                	ld	s3,8(sp)
    802005e0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    802005e2:	85ca                	mv	a1,s2
    802005e4:	87a6                	mv	a5,s1
}
    802005e6:	6942                	ld	s2,16(sp)
    802005e8:	64e2                	ld	s1,24(sp)
    802005ea:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    802005ec:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    802005ee:	03065633          	divu	a2,a2,a6
    802005f2:	8722                	mv	a4,s0
    802005f4:	f9bff0ef          	jal	ra,8020058e <printnum>
    802005f8:	b7f9                	j	802005c6 <printnum+0x38>

00000000802005fa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    802005fa:	7119                	addi	sp,sp,-128
    802005fc:	f4a6                	sd	s1,104(sp)
    802005fe:	f0ca                	sd	s2,96(sp)
    80200600:	ecce                	sd	s3,88(sp)
    80200602:	e8d2                	sd	s4,80(sp)
    80200604:	e4d6                	sd	s5,72(sp)
    80200606:	e0da                	sd	s6,64(sp)
    80200608:	fc5e                	sd	s7,56(sp)
    8020060a:	f06a                	sd	s10,32(sp)
    8020060c:	fc86                	sd	ra,120(sp)
    8020060e:	f8a2                	sd	s0,112(sp)
    80200610:	f862                	sd	s8,48(sp)
    80200612:	f466                	sd	s9,40(sp)
    80200614:	ec6e                	sd	s11,24(sp)
    80200616:	892a                	mv	s2,a0
    80200618:	84ae                	mv	s1,a1
    8020061a:	8d32                	mv	s10,a2
    8020061c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020061e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200622:	5b7d                	li	s6,-1
    80200624:	00001a97          	auipc	s5,0x1
    80200628:	9e0a8a93          	addi	s5,s5,-1568 # 80201004 <etext+0x60c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020062c:	00001b97          	auipc	s7,0x1
    80200630:	bb4b8b93          	addi	s7,s7,-1100 # 802011e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200634:	000d4503          	lbu	a0,0(s10)
    80200638:	001d0413          	addi	s0,s10,1
    8020063c:	01350a63          	beq	a0,s3,80200650 <vprintfmt+0x56>
            if (ch == '\0') {
    80200640:	c121                	beqz	a0,80200680 <vprintfmt+0x86>
            putch(ch, putdat);
    80200642:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200644:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    80200646:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200648:	fff44503          	lbu	a0,-1(s0)
    8020064c:	ff351ae3          	bne	a0,s3,80200640 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    80200650:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200654:	02000793          	li	a5,32
        lflag = altflag = 0;
    80200658:	4c81                	li	s9,0
    8020065a:	4881                	li	a7,0
        width = precision = -1;
    8020065c:	5c7d                	li	s8,-1
    8020065e:	5dfd                	li	s11,-1
    80200660:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    80200664:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200666:	fdd6059b          	addiw	a1,a2,-35
    8020066a:	0ff5f593          	zext.b	a1,a1
    8020066e:	00140d13          	addi	s10,s0,1
    80200672:	04b56263          	bltu	a0,a1,802006b6 <vprintfmt+0xbc>
    80200676:	058a                	slli	a1,a1,0x2
    80200678:	95d6                	add	a1,a1,s5
    8020067a:	4194                	lw	a3,0(a1)
    8020067c:	96d6                	add	a3,a3,s5
    8020067e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200680:	70e6                	ld	ra,120(sp)
    80200682:	7446                	ld	s0,112(sp)
    80200684:	74a6                	ld	s1,104(sp)
    80200686:	7906                	ld	s2,96(sp)
    80200688:	69e6                	ld	s3,88(sp)
    8020068a:	6a46                	ld	s4,80(sp)
    8020068c:	6aa6                	ld	s5,72(sp)
    8020068e:	6b06                	ld	s6,64(sp)
    80200690:	7be2                	ld	s7,56(sp)
    80200692:	7c42                	ld	s8,48(sp)
    80200694:	7ca2                	ld	s9,40(sp)
    80200696:	7d02                	ld	s10,32(sp)
    80200698:	6de2                	ld	s11,24(sp)
    8020069a:	6109                	addi	sp,sp,128
    8020069c:	8082                	ret
            padc = '0';
    8020069e:	87b2                	mv	a5,a2
            goto reswitch;
    802006a0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802006a4:	846a                	mv	s0,s10
    802006a6:	00140d13          	addi	s10,s0,1
    802006aa:	fdd6059b          	addiw	a1,a2,-35
    802006ae:	0ff5f593          	zext.b	a1,a1
    802006b2:	fcb572e3          	bgeu	a0,a1,80200676 <vprintfmt+0x7c>
            putch('%', putdat);
    802006b6:	85a6                	mv	a1,s1
    802006b8:	02500513          	li	a0,37
    802006bc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802006be:	fff44783          	lbu	a5,-1(s0)
    802006c2:	8d22                	mv	s10,s0
    802006c4:	f73788e3          	beq	a5,s3,80200634 <vprintfmt+0x3a>
    802006c8:	ffed4783          	lbu	a5,-2(s10)
    802006cc:	1d7d                	addi	s10,s10,-1
    802006ce:	ff379de3          	bne	a5,s3,802006c8 <vprintfmt+0xce>
    802006d2:	b78d                	j	80200634 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    802006d4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    802006d8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802006dc:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    802006de:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    802006e2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    802006e6:	02d86463          	bltu	a6,a3,8020070e <vprintfmt+0x114>
                ch = *fmt;
    802006ea:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    802006ee:	002c169b          	slliw	a3,s8,0x2
    802006f2:	0186873b          	addw	a4,a3,s8
    802006f6:	0017171b          	slliw	a4,a4,0x1
    802006fa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    802006fc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    80200700:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200702:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    80200706:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    8020070a:	fed870e3          	bgeu	a6,a3,802006ea <vprintfmt+0xf0>
            if (width < 0)
    8020070e:	f40ddce3          	bgez	s11,80200666 <vprintfmt+0x6c>
                width = precision, precision = -1;
    80200712:	8de2                	mv	s11,s8
    80200714:	5c7d                	li	s8,-1
    80200716:	bf81                	j	80200666 <vprintfmt+0x6c>
            if (width < 0)
    80200718:	fffdc693          	not	a3,s11
    8020071c:	96fd                	srai	a3,a3,0x3f
    8020071e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    80200722:	00144603          	lbu	a2,1(s0)
    80200726:	2d81                	sext.w	s11,s11
    80200728:	846a                	mv	s0,s10
            goto reswitch;
    8020072a:	bf35                	j	80200666 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    8020072c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    80200730:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200734:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200736:	846a                	mv	s0,s10
            goto process_precision;
    80200738:	bfd9                	j	8020070e <vprintfmt+0x114>
    if (lflag >= 2) {
    8020073a:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020073c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200740:	01174463          	blt	a4,a7,80200748 <vprintfmt+0x14e>
    else if (lflag) {
    80200744:	1a088e63          	beqz	a7,80200900 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    80200748:	000a3603          	ld	a2,0(s4)
    8020074c:	46c1                	li	a3,16
    8020074e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    80200750:	2781                	sext.w	a5,a5
    80200752:	876e                	mv	a4,s11
    80200754:	85a6                	mv	a1,s1
    80200756:	854a                	mv	a0,s2
    80200758:	e37ff0ef          	jal	ra,8020058e <printnum>
            break;
    8020075c:	bde1                	j	80200634 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    8020075e:	000a2503          	lw	a0,0(s4)
    80200762:	85a6                	mv	a1,s1
    80200764:	0a21                	addi	s4,s4,8
    80200766:	9902                	jalr	s2
            break;
    80200768:	b5f1                	j	80200634 <vprintfmt+0x3a>
    if (lflag >= 2) {
    8020076a:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020076c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200770:	01174463          	blt	a4,a7,80200778 <vprintfmt+0x17e>
    else if (lflag) {
    80200774:	18088163          	beqz	a7,802008f6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    80200778:	000a3603          	ld	a2,0(s4)
    8020077c:	46a9                	li	a3,10
    8020077e:	8a2e                	mv	s4,a1
    80200780:	bfc1                	j	80200750 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    80200782:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    80200786:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200788:	846a                	mv	s0,s10
            goto reswitch;
    8020078a:	bdf1                	j	80200666 <vprintfmt+0x6c>
            putch(ch, putdat);
    8020078c:	85a6                	mv	a1,s1
    8020078e:	02500513          	li	a0,37
    80200792:	9902                	jalr	s2
            break;
    80200794:	b545                	j	80200634 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    80200796:	00144603          	lbu	a2,1(s0)
            lflag ++;
    8020079a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    8020079c:	846a                	mv	s0,s10
            goto reswitch;
    8020079e:	b5e1                	j	80200666 <vprintfmt+0x6c>
    if (lflag >= 2) {
    802007a0:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802007a2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802007a6:	01174463          	blt	a4,a7,802007ae <vprintfmt+0x1b4>
    else if (lflag) {
    802007aa:	14088163          	beqz	a7,802008ec <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    802007ae:	000a3603          	ld	a2,0(s4)
    802007b2:	46a1                	li	a3,8
    802007b4:	8a2e                	mv	s4,a1
    802007b6:	bf69                	j	80200750 <vprintfmt+0x156>
            putch('0', putdat);
    802007b8:	03000513          	li	a0,48
    802007bc:	85a6                	mv	a1,s1
    802007be:	e03e                	sd	a5,0(sp)
    802007c0:	9902                	jalr	s2
            putch('x', putdat);
    802007c2:	85a6                	mv	a1,s1
    802007c4:	07800513          	li	a0,120
    802007c8:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802007ca:	0a21                	addi	s4,s4,8
            goto number;
    802007cc:	6782                	ld	a5,0(sp)
    802007ce:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    802007d0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    802007d4:	bfb5                	j	80200750 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    802007d6:	000a3403          	ld	s0,0(s4)
    802007da:	008a0713          	addi	a4,s4,8
    802007de:	e03a                	sd	a4,0(sp)
    802007e0:	14040263          	beqz	s0,80200924 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    802007e4:	0fb05763          	blez	s11,802008d2 <vprintfmt+0x2d8>
    802007e8:	02d00693          	li	a3,45
    802007ec:	0cd79163          	bne	a5,a3,802008ae <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007f0:	00044783          	lbu	a5,0(s0)
    802007f4:	0007851b          	sext.w	a0,a5
    802007f8:	cf85                	beqz	a5,80200830 <vprintfmt+0x236>
    802007fa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    802007fe:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200802:	000c4563          	bltz	s8,8020080c <vprintfmt+0x212>
    80200806:	3c7d                	addiw	s8,s8,-1
    80200808:	036c0263          	beq	s8,s6,8020082c <vprintfmt+0x232>
                    putch('?', putdat);
    8020080c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020080e:	0e0c8e63          	beqz	s9,8020090a <vprintfmt+0x310>
    80200812:	3781                	addiw	a5,a5,-32
    80200814:	0ef47b63          	bgeu	s0,a5,8020090a <vprintfmt+0x310>
                    putch('?', putdat);
    80200818:	03f00513          	li	a0,63
    8020081c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020081e:	000a4783          	lbu	a5,0(s4)
    80200822:	3dfd                	addiw	s11,s11,-1
    80200824:	0a05                	addi	s4,s4,1
    80200826:	0007851b          	sext.w	a0,a5
    8020082a:	ffe1                	bnez	a5,80200802 <vprintfmt+0x208>
            for (; width > 0; width --) {
    8020082c:	01b05963          	blez	s11,8020083e <vprintfmt+0x244>
    80200830:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200832:	85a6                	mv	a1,s1
    80200834:	02000513          	li	a0,32
    80200838:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020083a:	fe0d9be3          	bnez	s11,80200830 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020083e:	6a02                	ld	s4,0(sp)
    80200840:	bbd5                	j	80200634 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200842:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200844:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    80200848:	01174463          	blt	a4,a7,80200850 <vprintfmt+0x256>
    else if (lflag) {
    8020084c:	08088d63          	beqz	a7,802008e6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    80200850:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    80200854:	0a044d63          	bltz	s0,8020090e <vprintfmt+0x314>
            num = getint(&ap, lflag);
    80200858:	8622                	mv	a2,s0
    8020085a:	8a66                	mv	s4,s9
    8020085c:	46a9                	li	a3,10
    8020085e:	bdcd                	j	80200750 <vprintfmt+0x156>
            err = va_arg(ap, int);
    80200860:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200864:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200866:	0a21                	addi	s4,s4,8
            if (err < 0) {
    80200868:	41f7d69b          	sraiw	a3,a5,0x1f
    8020086c:	8fb5                	xor	a5,a5,a3
    8020086e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200872:	02d74163          	blt	a4,a3,80200894 <vprintfmt+0x29a>
    80200876:	00369793          	slli	a5,a3,0x3
    8020087a:	97de                	add	a5,a5,s7
    8020087c:	639c                	ld	a5,0(a5)
    8020087e:	cb99                	beqz	a5,80200894 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    80200880:	86be                	mv	a3,a5
    80200882:	00000617          	auipc	a2,0x0
    80200886:	77e60613          	addi	a2,a2,1918 # 80201000 <etext+0x608>
    8020088a:	85a6                	mv	a1,s1
    8020088c:	854a                	mv	a0,s2
    8020088e:	0ce000ef          	jal	ra,8020095c <printfmt>
    80200892:	b34d                	j	80200634 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    80200894:	00000617          	auipc	a2,0x0
    80200898:	75c60613          	addi	a2,a2,1884 # 80200ff0 <etext+0x5f8>
    8020089c:	85a6                	mv	a1,s1
    8020089e:	854a                	mv	a0,s2
    802008a0:	0bc000ef          	jal	ra,8020095c <printfmt>
    802008a4:	bb41                	j	80200634 <vprintfmt+0x3a>
                p = "(null)";
    802008a6:	00000417          	auipc	s0,0x0
    802008aa:	74240413          	addi	s0,s0,1858 # 80200fe8 <etext+0x5f0>
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008ae:	85e2                	mv	a1,s8
    802008b0:	8522                	mv	a0,s0
    802008b2:	e43e                	sd	a5,8(sp)
    802008b4:	116000ef          	jal	ra,802009ca <strnlen>
    802008b8:	40ad8dbb          	subw	s11,s11,a0
    802008bc:	01b05b63          	blez	s11,802008d2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
    802008c0:	67a2                	ld	a5,8(sp)
    802008c2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008c6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    802008c8:	85a6                	mv	a1,s1
    802008ca:	8552                	mv	a0,s4
    802008cc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008ce:	fe0d9ce3          	bnez	s11,802008c6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802008d2:	00044783          	lbu	a5,0(s0)
    802008d6:	00140a13          	addi	s4,s0,1
    802008da:	0007851b          	sext.w	a0,a5
    802008de:	d3a5                	beqz	a5,8020083e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    802008e0:	05e00413          	li	s0,94
    802008e4:	bf39                	j	80200802 <vprintfmt+0x208>
        return va_arg(*ap, int);
    802008e6:	000a2403          	lw	s0,0(s4)
    802008ea:	b7ad                	j	80200854 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    802008ec:	000a6603          	lwu	a2,0(s4)
    802008f0:	46a1                	li	a3,8
    802008f2:	8a2e                	mv	s4,a1
    802008f4:	bdb1                	j	80200750 <vprintfmt+0x156>
    802008f6:	000a6603          	lwu	a2,0(s4)
    802008fa:	46a9                	li	a3,10
    802008fc:	8a2e                	mv	s4,a1
    802008fe:	bd89                	j	80200750 <vprintfmt+0x156>
    80200900:	000a6603          	lwu	a2,0(s4)
    80200904:	46c1                	li	a3,16
    80200906:	8a2e                	mv	s4,a1
    80200908:	b5a1                	j	80200750 <vprintfmt+0x156>
                    putch(ch, putdat);
    8020090a:	9902                	jalr	s2
    8020090c:	bf09                	j	8020081e <vprintfmt+0x224>
                putch('-', putdat);
    8020090e:	85a6                	mv	a1,s1
    80200910:	02d00513          	li	a0,45
    80200914:	e03e                	sd	a5,0(sp)
    80200916:	9902                	jalr	s2
                num = -(long long)num;
    80200918:	6782                	ld	a5,0(sp)
    8020091a:	8a66                	mv	s4,s9
    8020091c:	40800633          	neg	a2,s0
    80200920:	46a9                	li	a3,10
    80200922:	b53d                	j	80200750 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    80200924:	03b05163          	blez	s11,80200946 <vprintfmt+0x34c>
    80200928:	02d00693          	li	a3,45
    8020092c:	f6d79de3          	bne	a5,a3,802008a6 <vprintfmt+0x2ac>
                p = "(null)";
    80200930:	00000417          	auipc	s0,0x0
    80200934:	6b840413          	addi	s0,s0,1720 # 80200fe8 <etext+0x5f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200938:	02800793          	li	a5,40
    8020093c:	02800513          	li	a0,40
    80200940:	00140a13          	addi	s4,s0,1
    80200944:	bd6d                	j	802007fe <vprintfmt+0x204>
    80200946:	00000a17          	auipc	s4,0x0
    8020094a:	6a3a0a13          	addi	s4,s4,1699 # 80200fe9 <etext+0x5f1>
    8020094e:	02800513          	li	a0,40
    80200952:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    80200956:	05e00413          	li	s0,94
    8020095a:	b565                	j	80200802 <vprintfmt+0x208>

000000008020095c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020095c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    8020095e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200962:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200964:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200966:	ec06                	sd	ra,24(sp)
    80200968:	f83a                	sd	a4,48(sp)
    8020096a:	fc3e                	sd	a5,56(sp)
    8020096c:	e0c2                	sd	a6,64(sp)
    8020096e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    80200970:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200972:	c89ff0ef          	jal	ra,802005fa <vprintfmt>
}
    80200976:	60e2                	ld	ra,24(sp)
    80200978:	6161                	addi	sp,sp,80
    8020097a:	8082                	ret

000000008020097c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    8020097c:	4781                	li	a5,0
    8020097e:	00003717          	auipc	a4,0x3
    80200982:	68273703          	ld	a4,1666(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    80200986:	88ba                	mv	a7,a4
    80200988:	852a                	mv	a0,a0
    8020098a:	85be                	mv	a1,a5
    8020098c:	863e                	mv	a2,a5
    8020098e:	00000073          	ecall
    80200992:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    80200994:	8082                	ret

0000000080200996 <sbi_set_timer>:
    __asm__ volatile (
    80200996:	4781                	li	a5,0
    80200998:	00003717          	auipc	a4,0x3
    8020099c:	68073703          	ld	a4,1664(a4) # 80204018 <SBI_SET_TIMER>
    802009a0:	88ba                	mv	a7,a4
    802009a2:	852a                	mv	a0,a0
    802009a4:	85be                	mv	a1,a5
    802009a6:	863e                	mv	a2,a5
    802009a8:	00000073          	ecall
    802009ac:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    802009ae:	8082                	ret

00000000802009b0 <sbi_shutdown>:
    __asm__ volatile (
    802009b0:	4781                	li	a5,0
    802009b2:	00003717          	auipc	a4,0x3
    802009b6:	65673703          	ld	a4,1622(a4) # 80204008 <SBI_SHUTDOWN>
    802009ba:	88ba                	mv	a7,a4
    802009bc:	853e                	mv	a0,a5
    802009be:	85be                	mv	a1,a5
    802009c0:	863e                	mv	a2,a5
    802009c2:	00000073          	ecall
    802009c6:	87aa                	mv	a5,a0


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    802009c8:	8082                	ret

00000000802009ca <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    802009ca:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    802009cc:	e589                	bnez	a1,802009d6 <strnlen+0xc>
    802009ce:	a811                	j	802009e2 <strnlen+0x18>
        cnt ++;
    802009d0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802009d2:	00f58863          	beq	a1,a5,802009e2 <strnlen+0x18>
    802009d6:	00f50733          	add	a4,a0,a5
    802009da:	00074703          	lbu	a4,0(a4)
    802009de:	fb6d                	bnez	a4,802009d0 <strnlen+0x6>
    802009e0:	85be                	mv	a1,a5
    }
    return cnt;
}
    802009e2:	852e                	mv	a0,a1
    802009e4:	8082                	ret

00000000802009e6 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    802009e6:	ca01                	beqz	a2,802009f6 <memset+0x10>
    802009e8:	962a                	add	a2,a2,a0
    char *p = s;
    802009ea:	87aa                	mv	a5,a0
        *p ++ = c;
    802009ec:	0785                	addi	a5,a5,1
    802009ee:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    802009f2:	fec79de3          	bne	a5,a2,802009ec <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    802009f6:	8082                	ret
