
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	92013103          	ld	sp,-1760(sp) # 80008920 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	93070713          	addi	a4,a4,-1744 # 80008980 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	5de78793          	addi	a5,a5,1502 # 80006640 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb3f7>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	ec078793          	addi	a5,a5,-320 # 80000f6c <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	710080e7          	jalr	1808(ra) # 8000283a <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	93650513          	addi	a0,a0,-1738 # 80010ac0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b38080e7          	jalr	-1224(ra) # 80000cca <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	92648493          	addi	s1,s1,-1754 # 80010ac0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9b690913          	addi	s2,s2,-1610 # 80010b58 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9a2080e7          	jalr	-1630(ra) # 80001b62 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4bc080e7          	jalr	1212(ra) # 80002684 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1ee080e7          	jalr	494(ra) # 800023c4 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	5d2080e7          	jalr	1490(ra) # 800027e4 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	89a50513          	addi	a0,a0,-1894 # 80010ac0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b50080e7          	jalr	-1200(ra) # 80000d7e <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	88450513          	addi	a0,a0,-1916 # 80010ac0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b3a080e7          	jalr	-1222(ra) # 80000d7e <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8ef72323          	sw	a5,-1818(a4) # 80010b58 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7f450513          	addi	a0,a0,2036 # 80010ac0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	9f6080e7          	jalr	-1546(ra) # 80000cca <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	59e080e7          	jalr	1438(ra) # 80002890 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7c650513          	addi	a0,a0,1990 # 80010ac0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a7c080e7          	jalr	-1412(ra) # 80000d7e <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7a270713          	addi	a4,a4,1954 # 80010ac0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	77878793          	addi	a5,a5,1912 # 80010ac0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7e27a783          	lw	a5,2018(a5) # 80010b58 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	73670713          	addi	a4,a4,1846 # 80010ac0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	72648493          	addi	s1,s1,1830 # 80010ac0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6ea70713          	addi	a4,a4,1770 # 80010ac0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72a23          	sw	a5,1908(a4) # 80010b60 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6ae78793          	addi	a5,a5,1710 # 80010ac0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	72c7a323          	sw	a2,1830(a5) # 80010b5c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	71a50513          	addi	a0,a0,1818 # 80010b58 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fee080e7          	jalr	-18(ra) # 80002434 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	66050513          	addi	a0,a0,1632 # 80010ac0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	7d2080e7          	jalr	2002(ra) # 80000c3a <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	df878793          	addi	a5,a5,-520 # 80242270 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6207aa23          	sw	zero,1588(a5) # 80010b80 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b8a50513          	addi	a0,a0,-1142 # 800080f8 <digits+0xb8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3cf72023          	sw	a5,960(a4) # 80008940 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5c4dad83          	lw	s11,1476(s11) # 80010b80 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	56e50513          	addi	a0,a0,1390 # 80010b68 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	6c8080e7          	jalr	1736(ra) # 80000cca <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	41050513          	addi	a0,a0,1040 # 80010b68 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	61e080e7          	jalr	1566(ra) # 80000d7e <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3f448493          	addi	s1,s1,1012 # 80010b68 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	4b4080e7          	jalr	1204(ra) # 80000c3a <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3b450513          	addi	a0,a0,948 # 80010b88 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	45e080e7          	jalr	1118(ra) # 80000c3a <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	486080e7          	jalr	1158(ra) # 80000c7e <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1407a783          	lw	a5,320(a5) # 80008940 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	4f8080e7          	jalr	1272(ra) # 80000d1e <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1107b783          	ld	a5,272(a5) # 80008948 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	11073703          	ld	a4,272(a4) # 80008950 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	326a0a13          	addi	s4,s4,806 # 80010b88 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0de48493          	addi	s1,s1,222 # 80008948 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0de98993          	addi	s3,s3,222 # 80008950 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	ba0080e7          	jalr	-1120(ra) # 80002434 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2b850513          	addi	a0,a0,696 # 80010b88 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	3f2080e7          	jalr	1010(ra) # 80000cca <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0607a783          	lw	a5,96(a5) # 80008940 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	06673703          	ld	a4,102(a4) # 80008950 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0567b783          	ld	a5,86(a5) # 80008948 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	28a98993          	addi	s3,s3,650 # 80010b88 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	04248493          	addi	s1,s1,66 # 80008948 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	04290913          	addi	s2,s2,66 # 80008950 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	aa6080e7          	jalr	-1370(ra) # 800023c4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	25448493          	addi	s1,s1,596 # 80010b88 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	00e7b423          	sd	a4,8(a5) # 80008950 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	424080e7          	jalr	1060(ra) # 80000d7e <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1ce48493          	addi	s1,s1,462 # 80010b88 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	306080e7          	jalr	774(ra) # 80000cca <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	3a8080e7          	jalr	936(ra) # 80000d7e <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb1                	bnez	a5,80000a4c <kfree+0x64>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00243797          	auipc	a5,0x243
    80000a00:	a0c78793          	addi	a5,a5,-1524 # 80243408 <end>
    80000a04:	04f56463          	bltu	a0,a5,80000a4c <kfree+0x64>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57063          	bgeu	a0,a5,80000a4c <kfree+0x64>
    panic("kfree");


  //acquire(&stPageRefs.lock);
  if(stPageRefs.ref_arr[(uint64)pa >> PGSHIFT] == 0)
    80000a10:	00c55793          	srli	a5,a0,0xc
    80000a14:	00478693          	addi	a3,a5,4
    80000a18:	068a                	slli	a3,a3,0x2
    80000a1a:	00010717          	auipc	a4,0x10
    80000a1e:	1c670713          	addi	a4,a4,454 # 80010be0 <stPageRefs>
    80000a22:	9736                	add	a4,a4,a3
    80000a24:	4718                	lw	a4,8(a4)
    80000a26:	cb1d                	beqz	a4,80000a5c <kfree+0x74>
  {
    //release(&stPageRefs.lock);
    panic("kfree: ref count is 0 oh no");
  }

  stPageRefs.ref_arr[(uint64)pa >> PGSHIFT]--;
    80000a28:	377d                	addiw	a4,a4,-1
    80000a2a:	0007061b          	sext.w	a2,a4
    80000a2e:	0791                	addi	a5,a5,4
    80000a30:	078a                	slli	a5,a5,0x2
    80000a32:	00010697          	auipc	a3,0x10
    80000a36:	1ae68693          	addi	a3,a3,430 # 80010be0 <stPageRefs>
    80000a3a:	97b6                	add	a5,a5,a3
    80000a3c:	c798                	sw	a4,8(a5)

  if(stPageRefs.ref_arr[(uint64)pa >> PGSHIFT] != 0)
    80000a3e:	c61d                	beqz	a2,80000a6c <kfree+0x84>
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
    //release(&stPageRefs.lock);
  }
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6902                	ld	s2,0(sp)
    80000a48:	6105                	addi	sp,sp,32
    80000a4a:	8082                	ret
    panic("kfree");
    80000a4c:	00007517          	auipc	a0,0x7
    80000a50:	61450513          	addi	a0,a0,1556 # 80008060 <digits+0x20>
    80000a54:	00000097          	auipc	ra,0x0
    80000a58:	aec080e7          	jalr	-1300(ra) # 80000540 <panic>
    panic("kfree: ref count is 0 oh no");
    80000a5c:	00007517          	auipc	a0,0x7
    80000a60:	60c50513          	addi	a0,a0,1548 # 80008068 <digits+0x28>
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	adc080e7          	jalr	-1316(ra) # 80000540 <panic>
    memset(pa, 1, PGSIZE);
    80000a6c:	6605                	lui	a2,0x1
    80000a6e:	4585                	li	a1,1
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	356080e7          	jalr	854(ra) # 80000dc6 <memset>
    acquire(&kmem.lock);
    80000a78:	00010917          	auipc	s2,0x10
    80000a7c:	14890913          	addi	s2,s2,328 # 80010bc0 <kmem>
    80000a80:	854a                	mv	a0,s2
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	248080e7          	jalr	584(ra) # 80000cca <acquire>
    r->next = kmem.freelist;
    80000a8a:	01893783          	ld	a5,24(s2)
    80000a8e:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a90:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000a94:	854a                	mv	a0,s2
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	2e8080e7          	jalr	744(ra) # 80000d7e <release>
    80000a9e:	b74d                	j	80000a40 <kfree+0x58>

0000000080000aa0 <freerange>:
{
    80000aa0:	7139                	addi	sp,sp,-64
    80000aa2:	fc06                	sd	ra,56(sp)
    80000aa4:	f822                	sd	s0,48(sp)
    80000aa6:	f426                	sd	s1,40(sp)
    80000aa8:	f04a                	sd	s2,32(sp)
    80000aaa:	ec4e                	sd	s3,24(sp)
    80000aac:	e852                	sd	s4,16(sp)
    80000aae:	e456                	sd	s5,8(sp)
    80000ab0:	e05a                	sd	s6,0(sp)
    80000ab2:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ab4:	6785                	lui	a5,0x1
    80000ab6:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000aba:	953a                	add	a0,a0,a4
    80000abc:	777d                	lui	a4,0xfffff
    80000abe:	00e574b3          	and	s1,a0,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac2:	97a6                	add	a5,a5,s1
    80000ac4:	02f5eb63          	bltu	a1,a5,80000afa <freerange+0x5a>
    80000ac8:	892e                	mv	s2,a1
    stPageRefs.ref_arr[(uint64)p >> PGSHIFT] = 1;
    80000aca:	00010b17          	auipc	s6,0x10
    80000ace:	116b0b13          	addi	s6,s6,278 # 80010be0 <stPageRefs>
    80000ad2:	4a85                	li	s5,1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad4:	6a05                	lui	s4,0x1
    80000ad6:	6989                	lui	s3,0x2
    stPageRefs.ref_arr[(uint64)p >> PGSHIFT] = 1;
    80000ad8:	00c4d793          	srli	a5,s1,0xc
    80000adc:	0791                	addi	a5,a5,4
    80000ade:	078a                	slli	a5,a5,0x2
    80000ae0:	97da                	add	a5,a5,s6
    80000ae2:	0157a423          	sw	s5,8(a5)
    kfree(p);
    80000ae6:	8526                	mv	a0,s1
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	f00080e7          	jalr	-256(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af0:	87a6                	mv	a5,s1
    80000af2:	94d2                	add	s1,s1,s4
    80000af4:	97ce                	add	a5,a5,s3
    80000af6:	fef971e3          	bgeu	s2,a5,80000ad8 <freerange+0x38>
}
    80000afa:	70e2                	ld	ra,56(sp)
    80000afc:	7442                	ld	s0,48(sp)
    80000afe:	74a2                	ld	s1,40(sp)
    80000b00:	7902                	ld	s2,32(sp)
    80000b02:	69e2                	ld	s3,24(sp)
    80000b04:	6a42                	ld	s4,16(sp)
    80000b06:	6aa2                	ld	s5,8(sp)
    80000b08:	6b02                	ld	s6,0(sp)
    80000b0a:	6121                	addi	sp,sp,64
    80000b0c:	8082                	ret

0000000080000b0e <kinit>:
{
    80000b0e:	1141                	addi	sp,sp,-16
    80000b10:	e406                	sd	ra,8(sp)
    80000b12:	e022                	sd	s0,0(sp)
    80000b14:	0800                	addi	s0,sp,16
  initlock(&stPageRefs.lock, "page_refs"); 
    80000b16:	00007597          	auipc	a1,0x7
    80000b1a:	57258593          	addi	a1,a1,1394 # 80008088 <digits+0x48>
    80000b1e:	00010517          	auipc	a0,0x10
    80000b22:	0c250513          	addi	a0,a0,194 # 80010be0 <stPageRefs>
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	114080e7          	jalr	276(ra) # 80000c3a <initlock>
  initlock(&kmem.lock, "kmem");
    80000b2e:	00007597          	auipc	a1,0x7
    80000b32:	56a58593          	addi	a1,a1,1386 # 80008098 <digits+0x58>
    80000b36:	00010517          	auipc	a0,0x10
    80000b3a:	08a50513          	addi	a0,a0,138 # 80010bc0 <kmem>
    80000b3e:	00000097          	auipc	ra,0x0
    80000b42:	0fc080e7          	jalr	252(ra) # 80000c3a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b46:	45c5                	li	a1,17
    80000b48:	05ee                	slli	a1,a1,0x1b
    80000b4a:	00243517          	auipc	a0,0x243
    80000b4e:	8be50513          	addi	a0,a0,-1858 # 80243408 <end>
    80000b52:	00000097          	auipc	ra,0x0
    80000b56:	f4e080e7          	jalr	-178(ra) # 80000aa0 <freerange>
}
    80000b5a:	60a2                	ld	ra,8(sp)
    80000b5c:	6402                	ld	s0,0(sp)
    80000b5e:	0141                	addi	sp,sp,16
    80000b60:	8082                	ret

0000000080000b62 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b62:	1101                	addi	sp,sp,-32
    80000b64:	ec06                	sd	ra,24(sp)
    80000b66:	e822                	sd	s0,16(sp)
    80000b68:	e426                	sd	s1,8(sp)
    80000b6a:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b6c:	00010497          	auipc	s1,0x10
    80000b70:	05448493          	addi	s1,s1,84 # 80010bc0 <kmem>
    80000b74:	8526                	mv	a0,s1
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	154080e7          	jalr	340(ra) # 80000cca <acquire>
  r = kmem.freelist;
    80000b7e:	6c84                	ld	s1,24(s1)

  if(r)
    80000b80:	c0b9                	beqz	s1,80000bc6 <kalloc+0x64>
  {
    //increment references
    //acquire(&stPageRefs.lock);
    stPageRefs.ref_arr[(uint64)r >> PGSHIFT] = 1;
    80000b82:	00c4d793          	srli	a5,s1,0xc
    80000b86:	0791                	addi	a5,a5,4
    80000b88:	078a                	slli	a5,a5,0x2
    80000b8a:	00010717          	auipc	a4,0x10
    80000b8e:	05670713          	addi	a4,a4,86 # 80010be0 <stPageRefs>
    80000b92:	97ba                	add	a5,a5,a4
    80000b94:	4705                	li	a4,1
    80000b96:	c798                	sw	a4,8(a5)
    //release(&stPageRefs.lock);

    kmem.freelist = r->next;  
    80000b98:	609c                	ld	a5,0(s1)
    80000b9a:	00010517          	auipc	a0,0x10
    80000b9e:	02650513          	addi	a0,a0,38 # 80010bc0 <kmem>
    80000ba2:	ed1c                	sd	a5,24(a0)

  }
  release(&kmem.lock);
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	1da080e7          	jalr	474(ra) # 80000d7e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bac:	6605                	lui	a2,0x1
    80000bae:	4595                	li	a1,5
    80000bb0:	8526                	mv	a0,s1
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	214080e7          	jalr	532(ra) # 80000dc6 <memset>
  return (void*)r;
}
    80000bba:	8526                	mv	a0,s1
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  release(&kmem.lock);
    80000bc6:	00010517          	auipc	a0,0x10
    80000bca:	ffa50513          	addi	a0,a0,-6 # 80010bc0 <kmem>
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1b0080e7          	jalr	432(ra) # 80000d7e <release>
  if(r)
    80000bd6:	b7d5                	j	80000bba <kalloc+0x58>

0000000080000bd8 <increase_ref>:

void
increase_ref(void *pa)
{
    80000bd8:	1141                	addi	sp,sp,-16
    80000bda:	e422                	sd	s0,8(sp)
    80000bdc:	0800                	addi	s0,sp,16
  //acquire(&stPageRefs.lock);

  stPageRefs.ref_arr[(uint64)pa >> PGSHIFT]++;
    80000bde:	8131                	srli	a0,a0,0xc
    80000be0:	0511                	addi	a0,a0,4
    80000be2:	050a                	slli	a0,a0,0x2
    80000be4:	00010797          	auipc	a5,0x10
    80000be8:	ffc78793          	addi	a5,a5,-4 # 80010be0 <stPageRefs>
    80000bec:	97aa                	add	a5,a5,a0
    80000bee:	4798                	lw	a4,8(a5)
    80000bf0:	2705                	addiw	a4,a4,1
    80000bf2:	c798                	sw	a4,8(a5)
  
  //release(&stPageRefs.lock);
}
    80000bf4:	6422                	ld	s0,8(sp)
    80000bf6:	0141                	addi	sp,sp,16
    80000bf8:	8082                	ret

0000000080000bfa <decrease_ref>:

void
decrease_ref(void *pa)
{
    80000bfa:	1141                	addi	sp,sp,-16
    80000bfc:	e422                	sd	s0,8(sp)
    80000bfe:	0800                	addi	s0,sp,16
  //acquire(&stPageRefs.lock);

  stPageRefs.ref_arr[(uint64)pa >> PGSHIFT]--;
    80000c00:	8131                	srli	a0,a0,0xc
    80000c02:	0511                	addi	a0,a0,4
    80000c04:	050a                	slli	a0,a0,0x2
    80000c06:	00010797          	auipc	a5,0x10
    80000c0a:	fda78793          	addi	a5,a5,-38 # 80010be0 <stPageRefs>
    80000c0e:	97aa                	add	a5,a5,a0
    80000c10:	4798                	lw	a4,8(a5)
    80000c12:	377d                	addiw	a4,a4,-1
    80000c14:	c798                	sw	a4,8(a5)
  
  //release(&stPageRefs.lock);
}
    80000c16:	6422                	ld	s0,8(sp)
    80000c18:	0141                	addi	sp,sp,16
    80000c1a:	8082                	ret

0000000080000c1c <get_refcount>:

int
get_refcount(void *pa)
{
    80000c1c:	1141                	addi	sp,sp,-16
    80000c1e:	e422                	sd	s0,8(sp)
    80000c20:	0800                	addi	s0,sp,16
  //acquire(&stPageRefs.lock);
  int ret = stPageRefs.ref_arr[(uint64)pa >> PGSHIFT];
    80000c22:	8131                	srli	a0,a0,0xc
    80000c24:	0511                	addi	a0,a0,4
    80000c26:	050a                	slli	a0,a0,0x2
    80000c28:	00010797          	auipc	a5,0x10
    80000c2c:	fb878793          	addi	a5,a5,-72 # 80010be0 <stPageRefs>
    80000c30:	97aa                	add	a5,a5,a0
  //release(&stPageRefs.lock);

  return ret;
    80000c32:	4788                	lw	a0,8(a5)
    80000c34:	6422                	ld	s0,8(sp)
    80000c36:	0141                	addi	sp,sp,16
    80000c38:	8082                	ret

0000000080000c3a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c3a:	1141                	addi	sp,sp,-16
    80000c3c:	e422                	sd	s0,8(sp)
    80000c3e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c40:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c42:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c46:	00053823          	sd	zero,16(a0)
}
    80000c4a:	6422                	ld	s0,8(sp)
    80000c4c:	0141                	addi	sp,sp,16
    80000c4e:	8082                	ret

0000000080000c50 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c50:	411c                	lw	a5,0(a0)
    80000c52:	e399                	bnez	a5,80000c58 <holding+0x8>
    80000c54:	4501                	li	a0,0
  return r;
}
    80000c56:	8082                	ret
{
    80000c58:	1101                	addi	sp,sp,-32
    80000c5a:	ec06                	sd	ra,24(sp)
    80000c5c:	e822                	sd	s0,16(sp)
    80000c5e:	e426                	sd	s1,8(sp)
    80000c60:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c62:	6904                	ld	s1,16(a0)
    80000c64:	00001097          	auipc	ra,0x1
    80000c68:	ee2080e7          	jalr	-286(ra) # 80001b46 <mycpu>
    80000c6c:	40a48533          	sub	a0,s1,a0
    80000c70:	00153513          	seqz	a0,a0
}
    80000c74:	60e2                	ld	ra,24(sp)
    80000c76:	6442                	ld	s0,16(sp)
    80000c78:	64a2                	ld	s1,8(sp)
    80000c7a:	6105                	addi	sp,sp,32
    80000c7c:	8082                	ret

0000000080000c7e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c7e:	1101                	addi	sp,sp,-32
    80000c80:	ec06                	sd	ra,24(sp)
    80000c82:	e822                	sd	s0,16(sp)
    80000c84:	e426                	sd	s1,8(sp)
    80000c86:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c88:	100024f3          	csrr	s1,sstatus
    80000c8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c92:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c96:	00001097          	auipc	ra,0x1
    80000c9a:	eb0080e7          	jalr	-336(ra) # 80001b46 <mycpu>
    80000c9e:	5d3c                	lw	a5,120(a0)
    80000ca0:	cf89                	beqz	a5,80000cba <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ca2:	00001097          	auipc	ra,0x1
    80000ca6:	ea4080e7          	jalr	-348(ra) # 80001b46 <mycpu>
    80000caa:	5d3c                	lw	a5,120(a0)
    80000cac:	2785                	addiw	a5,a5,1
    80000cae:	dd3c                	sw	a5,120(a0)
}
    80000cb0:	60e2                	ld	ra,24(sp)
    80000cb2:	6442                	ld	s0,16(sp)
    80000cb4:	64a2                	ld	s1,8(sp)
    80000cb6:	6105                	addi	sp,sp,32
    80000cb8:	8082                	ret
    mycpu()->intena = old;
    80000cba:	00001097          	auipc	ra,0x1
    80000cbe:	e8c080e7          	jalr	-372(ra) # 80001b46 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8085                	srli	s1,s1,0x1
    80000cc4:	8885                	andi	s1,s1,1
    80000cc6:	dd64                	sw	s1,124(a0)
    80000cc8:	bfe9                	j	80000ca2 <push_off+0x24>

0000000080000cca <acquire>:
{
    80000cca:	1101                	addi	sp,sp,-32
    80000ccc:	ec06                	sd	ra,24(sp)
    80000cce:	e822                	sd	s0,16(sp)
    80000cd0:	e426                	sd	s1,8(sp)
    80000cd2:	1000                	addi	s0,sp,32
    80000cd4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cd6:	00000097          	auipc	ra,0x0
    80000cda:	fa8080e7          	jalr	-88(ra) # 80000c7e <push_off>
  if(holding(lk))
    80000cde:	8526                	mv	a0,s1
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	f70080e7          	jalr	-144(ra) # 80000c50 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ce8:	4705                	li	a4,1
  if(holding(lk))
    80000cea:	e115                	bnez	a0,80000d0e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cec:	87ba                	mv	a5,a4
    80000cee:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cf2:	2781                	sext.w	a5,a5
    80000cf4:	ffe5                	bnez	a5,80000cec <acquire+0x22>
  __sync_synchronize();
    80000cf6:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	e4c080e7          	jalr	-436(ra) # 80001b46 <mycpu>
    80000d02:	e888                	sd	a0,16(s1)
}
    80000d04:	60e2                	ld	ra,24(sp)
    80000d06:	6442                	ld	s0,16(sp)
    80000d08:	64a2                	ld	s1,8(sp)
    80000d0a:	6105                	addi	sp,sp,32
    80000d0c:	8082                	ret
    panic("acquire");
    80000d0e:	00007517          	auipc	a0,0x7
    80000d12:	39250513          	addi	a0,a0,914 # 800080a0 <digits+0x60>
    80000d16:	00000097          	auipc	ra,0x0
    80000d1a:	82a080e7          	jalr	-2006(ra) # 80000540 <panic>

0000000080000d1e <pop_off>:

void
pop_off(void)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e406                	sd	ra,8(sp)
    80000d22:	e022                	sd	s0,0(sp)
    80000d24:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d26:	00001097          	auipc	ra,0x1
    80000d2a:	e20080e7          	jalr	-480(ra) # 80001b46 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d2e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d32:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d34:	e78d                	bnez	a5,80000d5e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d36:	5d3c                	lw	a5,120(a0)
    80000d38:	02f05b63          	blez	a5,80000d6e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d3c:	37fd                	addiw	a5,a5,-1
    80000d3e:	0007871b          	sext.w	a4,a5
    80000d42:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d44:	eb09                	bnez	a4,80000d56 <pop_off+0x38>
    80000d46:	5d7c                	lw	a5,124(a0)
    80000d48:	c799                	beqz	a5,80000d56 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d4a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d4e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d52:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d56:	60a2                	ld	ra,8(sp)
    80000d58:	6402                	ld	s0,0(sp)
    80000d5a:	0141                	addi	sp,sp,16
    80000d5c:	8082                	ret
    panic("pop_off - interruptible");
    80000d5e:	00007517          	auipc	a0,0x7
    80000d62:	34a50513          	addi	a0,a0,842 # 800080a8 <digits+0x68>
    80000d66:	fffff097          	auipc	ra,0xfffff
    80000d6a:	7da080e7          	jalr	2010(ra) # 80000540 <panic>
    panic("pop_off");
    80000d6e:	00007517          	auipc	a0,0x7
    80000d72:	35250513          	addi	a0,a0,850 # 800080c0 <digits+0x80>
    80000d76:	fffff097          	auipc	ra,0xfffff
    80000d7a:	7ca080e7          	jalr	1994(ra) # 80000540 <panic>

0000000080000d7e <release>:
{
    80000d7e:	1101                	addi	sp,sp,-32
    80000d80:	ec06                	sd	ra,24(sp)
    80000d82:	e822                	sd	s0,16(sp)
    80000d84:	e426                	sd	s1,8(sp)
    80000d86:	1000                	addi	s0,sp,32
    80000d88:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d8a:	00000097          	auipc	ra,0x0
    80000d8e:	ec6080e7          	jalr	-314(ra) # 80000c50 <holding>
    80000d92:	c115                	beqz	a0,80000db6 <release+0x38>
  lk->cpu = 0;
    80000d94:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d98:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d9c:	0f50000f          	fence	iorw,ow
    80000da0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000da4:	00000097          	auipc	ra,0x0
    80000da8:	f7a080e7          	jalr	-134(ra) # 80000d1e <pop_off>
}
    80000dac:	60e2                	ld	ra,24(sp)
    80000dae:	6442                	ld	s0,16(sp)
    80000db0:	64a2                	ld	s1,8(sp)
    80000db2:	6105                	addi	sp,sp,32
    80000db4:	8082                	ret
    panic("release");
    80000db6:	00007517          	auipc	a0,0x7
    80000dba:	31250513          	addi	a0,a0,786 # 800080c8 <digits+0x88>
    80000dbe:	fffff097          	auipc	ra,0xfffff
    80000dc2:	782080e7          	jalr	1922(ra) # 80000540 <panic>

0000000080000dc6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dc6:	1141                	addi	sp,sp,-16
    80000dc8:	e422                	sd	s0,8(sp)
    80000dca:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dcc:	ca19                	beqz	a2,80000de2 <memset+0x1c>
    80000dce:	87aa                	mv	a5,a0
    80000dd0:	1602                	slli	a2,a2,0x20
    80000dd2:	9201                	srli	a2,a2,0x20
    80000dd4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000dd8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ddc:	0785                	addi	a5,a5,1
    80000dde:	fee79de3          	bne	a5,a4,80000dd8 <memset+0x12>
  }
  return dst;
}
    80000de2:	6422                	ld	s0,8(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dee:	ca05                	beqz	a2,80000e1e <memcmp+0x36>
    80000df0:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000df4:	1682                	slli	a3,a3,0x20
    80000df6:	9281                	srli	a3,a3,0x20
    80000df8:	0685                	addi	a3,a3,1
    80000dfa:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dfc:	00054783          	lbu	a5,0(a0)
    80000e00:	0005c703          	lbu	a4,0(a1)
    80000e04:	00e79863          	bne	a5,a4,80000e14 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e08:	0505                	addi	a0,a0,1
    80000e0a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e0c:	fed518e3          	bne	a0,a3,80000dfc <memcmp+0x14>
  }

  return 0;
    80000e10:	4501                	li	a0,0
    80000e12:	a019                	j	80000e18 <memcmp+0x30>
      return *s1 - *s2;
    80000e14:	40e7853b          	subw	a0,a5,a4
}
    80000e18:	6422                	ld	s0,8(sp)
    80000e1a:	0141                	addi	sp,sp,16
    80000e1c:	8082                	ret
  return 0;
    80000e1e:	4501                	li	a0,0
    80000e20:	bfe5                	j	80000e18 <memcmp+0x30>

0000000080000e22 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e22:	1141                	addi	sp,sp,-16
    80000e24:	e422                	sd	s0,8(sp)
    80000e26:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e28:	c205                	beqz	a2,80000e48 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e2a:	02a5e263          	bltu	a1,a0,80000e4e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e2e:	1602                	slli	a2,a2,0x20
    80000e30:	9201                	srli	a2,a2,0x20
    80000e32:	00c587b3          	add	a5,a1,a2
{
    80000e36:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e38:	0585                	addi	a1,a1,1
    80000e3a:	0705                	addi	a4,a4,1
    80000e3c:	fff5c683          	lbu	a3,-1(a1)
    80000e40:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e44:	fef59ae3          	bne	a1,a5,80000e38 <memmove+0x16>

  return dst;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret
  if(s < d && s + n > d){
    80000e4e:	02061693          	slli	a3,a2,0x20
    80000e52:	9281                	srli	a3,a3,0x20
    80000e54:	00d58733          	add	a4,a1,a3
    80000e58:	fce57be3          	bgeu	a0,a4,80000e2e <memmove+0xc>
    d += n;
    80000e5c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e5e:	fff6079b          	addiw	a5,a2,-1
    80000e62:	1782                	slli	a5,a5,0x20
    80000e64:	9381                	srli	a5,a5,0x20
    80000e66:	fff7c793          	not	a5,a5
    80000e6a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e6c:	177d                	addi	a4,a4,-1
    80000e6e:	16fd                	addi	a3,a3,-1
    80000e70:	00074603          	lbu	a2,0(a4)
    80000e74:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e78:	fee79ae3          	bne	a5,a4,80000e6c <memmove+0x4a>
    80000e7c:	b7f1                	j	80000e48 <memmove+0x26>

0000000080000e7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e406                	sd	ra,8(sp)
    80000e82:	e022                	sd	s0,0(sp)
    80000e84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e86:	00000097          	auipc	ra,0x0
    80000e8a:	f9c080e7          	jalr	-100(ra) # 80000e22 <memmove>
}
    80000e8e:	60a2                	ld	ra,8(sp)
    80000e90:	6402                	ld	s0,0(sp)
    80000e92:	0141                	addi	sp,sp,16
    80000e94:	8082                	ret

0000000080000e96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e96:	1141                	addi	sp,sp,-16
    80000e98:	e422                	sd	s0,8(sp)
    80000e9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e9c:	ce11                	beqz	a2,80000eb8 <strncmp+0x22>
    80000e9e:	00054783          	lbu	a5,0(a0)
    80000ea2:	cf89                	beqz	a5,80000ebc <strncmp+0x26>
    80000ea4:	0005c703          	lbu	a4,0(a1)
    80000ea8:	00f71a63          	bne	a4,a5,80000ebc <strncmp+0x26>
    n--, p++, q++;
    80000eac:	367d                	addiw	a2,a2,-1
    80000eae:	0505                	addi	a0,a0,1
    80000eb0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000eb2:	f675                	bnez	a2,80000e9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000eb4:	4501                	li	a0,0
    80000eb6:	a809                	j	80000ec8 <strncmp+0x32>
    80000eb8:	4501                	li	a0,0
    80000eba:	a039                	j	80000ec8 <strncmp+0x32>
  if(n == 0)
    80000ebc:	ca09                	beqz	a2,80000ece <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ebe:	00054503          	lbu	a0,0(a0)
    80000ec2:	0005c783          	lbu	a5,0(a1)
    80000ec6:	9d1d                	subw	a0,a0,a5
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret
    return 0;
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <strncmp+0x32>

0000000080000ed2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e422                	sd	s0,8(sp)
    80000ed6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ed8:	872a                	mv	a4,a0
    80000eda:	8832                	mv	a6,a2
    80000edc:	367d                	addiw	a2,a2,-1
    80000ede:	01005963          	blez	a6,80000ef0 <strncpy+0x1e>
    80000ee2:	0705                	addi	a4,a4,1
    80000ee4:	0005c783          	lbu	a5,0(a1)
    80000ee8:	fef70fa3          	sb	a5,-1(a4)
    80000eec:	0585                	addi	a1,a1,1
    80000eee:	f7f5                	bnez	a5,80000eda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ef0:	86ba                	mv	a3,a4
    80000ef2:	00c05c63          	blez	a2,80000f0a <strncpy+0x38>
    *s++ = 0;
    80000ef6:	0685                	addi	a3,a3,1
    80000ef8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000efc:	40d707bb          	subw	a5,a4,a3
    80000f00:	37fd                	addiw	a5,a5,-1
    80000f02:	010787bb          	addw	a5,a5,a6
    80000f06:	fef048e3          	bgtz	a5,80000ef6 <strncpy+0x24>
  return os;
}
    80000f0a:	6422                	ld	s0,8(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret

0000000080000f10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e422                	sd	s0,8(sp)
    80000f14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f16:	02c05363          	blez	a2,80000f3c <safestrcpy+0x2c>
    80000f1a:	fff6069b          	addiw	a3,a2,-1
    80000f1e:	1682                	slli	a3,a3,0x20
    80000f20:	9281                	srli	a3,a3,0x20
    80000f22:	96ae                	add	a3,a3,a1
    80000f24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f26:	00d58963          	beq	a1,a3,80000f38 <safestrcpy+0x28>
    80000f2a:	0585                	addi	a1,a1,1
    80000f2c:	0785                	addi	a5,a5,1
    80000f2e:	fff5c703          	lbu	a4,-1(a1)
    80000f32:	fee78fa3          	sb	a4,-1(a5)
    80000f36:	fb65                	bnez	a4,80000f26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f3c:	6422                	ld	s0,8(sp)
    80000f3e:	0141                	addi	sp,sp,16
    80000f40:	8082                	ret

0000000080000f42 <strlen>:

int
strlen(const char *s)
{
    80000f42:	1141                	addi	sp,sp,-16
    80000f44:	e422                	sd	s0,8(sp)
    80000f46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f48:	00054783          	lbu	a5,0(a0)
    80000f4c:	cf91                	beqz	a5,80000f68 <strlen+0x26>
    80000f4e:	0505                	addi	a0,a0,1
    80000f50:	87aa                	mv	a5,a0
    80000f52:	4685                	li	a3,1
    80000f54:	9e89                	subw	a3,a3,a0
    80000f56:	00f6853b          	addw	a0,a3,a5
    80000f5a:	0785                	addi	a5,a5,1
    80000f5c:	fff7c703          	lbu	a4,-1(a5)
    80000f60:	fb7d                	bnez	a4,80000f56 <strlen+0x14>
    ;
  return n;
}
    80000f62:	6422                	ld	s0,8(sp)
    80000f64:	0141                	addi	sp,sp,16
    80000f66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f68:	4501                	li	a0,0
    80000f6a:	bfe5                	j	80000f62 <strlen+0x20>

0000000080000f6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f6c:	1141                	addi	sp,sp,-16
    80000f6e:	e406                	sd	ra,8(sp)
    80000f70:	e022                	sd	s0,0(sp)
    80000f72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	bc2080e7          	jalr	-1086(ra) # 80001b36 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f7c:	00008717          	auipc	a4,0x8
    80000f80:	9dc70713          	addi	a4,a4,-1572 # 80008958 <started>
  if(cpuid() == 0){
    80000f84:	c139                	beqz	a0,80000fca <main+0x5e>
    while(started == 0)
    80000f86:	431c                	lw	a5,0(a4)
    80000f88:	2781                	sext.w	a5,a5
    80000f8a:	dff5                	beqz	a5,80000f86 <main+0x1a>
      ;
    __sync_synchronize();
    80000f8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f90:	00001097          	auipc	ra,0x1
    80000f94:	ba6080e7          	jalr	-1114(ra) # 80001b36 <cpuid>
    80000f98:	85aa                	mv	a1,a0
    80000f9a:	00007517          	auipc	a0,0x7
    80000f9e:	14e50513          	addi	a0,a0,334 # 800080e8 <digits+0xa8>
    80000fa2:	fffff097          	auipc	ra,0xfffff
    80000fa6:	5e8080e7          	jalr	1512(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000faa:	00000097          	auipc	ra,0x0
    80000fae:	0d8080e7          	jalr	216(ra) # 80001082 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fb2:	00002097          	auipc	ra,0x2
    80000fb6:	da0080e7          	jalr	-608(ra) # 80002d52 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fba:	00005097          	auipc	ra,0x5
    80000fbe:	6c6080e7          	jalr	1734(ra) # 80006680 <plicinithart>
  }

  scheduler();        
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	11a080e7          	jalr	282(ra) # 800020dc <scheduler>
    consoleinit();
    80000fca:	fffff097          	auipc	ra,0xfffff
    80000fce:	486080e7          	jalr	1158(ra) # 80000450 <consoleinit>
    printfinit();
    80000fd2:	fffff097          	auipc	ra,0xfffff
    80000fd6:	798080e7          	jalr	1944(ra) # 8000076a <printfinit>
    printf("\n");
    80000fda:	00007517          	auipc	a0,0x7
    80000fde:	11e50513          	addi	a0,a0,286 # 800080f8 <digits+0xb8>
    80000fe2:	fffff097          	auipc	ra,0xfffff
    80000fe6:	5a8080e7          	jalr	1448(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000fea:	00007517          	auipc	a0,0x7
    80000fee:	0e650513          	addi	a0,a0,230 # 800080d0 <digits+0x90>
    80000ff2:	fffff097          	auipc	ra,0xfffff
    80000ff6:	598080e7          	jalr	1432(ra) # 8000058a <printf>
    printf("\n");
    80000ffa:	00007517          	auipc	a0,0x7
    80000ffe:	0fe50513          	addi	a0,a0,254 # 800080f8 <digits+0xb8>
    80001002:	fffff097          	auipc	ra,0xfffff
    80001006:	588080e7          	jalr	1416(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	b04080e7          	jalr	-1276(ra) # 80000b0e <kinit>
    kvminit();       // create kernel page table
    80001012:	00000097          	auipc	ra,0x0
    80001016:	326080e7          	jalr	806(ra) # 80001338 <kvminit>
    kvminithart();   // turn on paging
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	068080e7          	jalr	104(ra) # 80001082 <kvminithart>
    procinit();      // process table
    80001022:	00001097          	auipc	ra,0x1
    80001026:	a60080e7          	jalr	-1440(ra) # 80001a82 <procinit>
    trapinit();      // trap vectors
    8000102a:	00002097          	auipc	ra,0x2
    8000102e:	d00080e7          	jalr	-768(ra) # 80002d2a <trapinit>
    trapinithart();  // install kernel trap vector
    80001032:	00002097          	auipc	ra,0x2
    80001036:	d20080e7          	jalr	-736(ra) # 80002d52 <trapinithart>
    plicinit();      // set up interrupt controller
    8000103a:	00005097          	auipc	ra,0x5
    8000103e:	630080e7          	jalr	1584(ra) # 8000666a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001042:	00005097          	auipc	ra,0x5
    80001046:	63e080e7          	jalr	1598(ra) # 80006680 <plicinithart>
    binit();         // buffer cache
    8000104a:	00002097          	auipc	ra,0x2
    8000104e:	766080e7          	jalr	1894(ra) # 800037b0 <binit>
    iinit();         // inode table
    80001052:	00003097          	auipc	ra,0x3
    80001056:	e06080e7          	jalr	-506(ra) # 80003e58 <iinit>
    fileinit();      // file table
    8000105a:	00004097          	auipc	ra,0x4
    8000105e:	dac080e7          	jalr	-596(ra) # 80004e06 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001062:	00005097          	auipc	ra,0x5
    80001066:	726080e7          	jalr	1830(ra) # 80006788 <virtio_disk_init>
    userinit();      // first user process
    8000106a:	00001097          	auipc	ra,0x1
    8000106e:	e54080e7          	jalr	-428(ra) # 80001ebe <userinit>
    __sync_synchronize();
    80001072:	0ff0000f          	fence
    started = 1;
    80001076:	4785                	li	a5,1
    80001078:	00008717          	auipc	a4,0x8
    8000107c:	8ef72023          	sw	a5,-1824(a4) # 80008958 <started>
    80001080:	b789                	j	80000fc2 <main+0x56>

0000000080001082 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e422                	sd	s0,8(sp)
    80001086:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001088:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000108c:	00008797          	auipc	a5,0x8
    80001090:	8d47b783          	ld	a5,-1836(a5) # 80008960 <kernel_pagetable>
    80001094:	83b1                	srli	a5,a5,0xc
    80001096:	577d                	li	a4,-1
    80001098:	177e                	slli	a4,a4,0x3f
    8000109a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000109c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010a0:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010a4:	6422                	ld	s0,8(sp)
    800010a6:	0141                	addi	sp,sp,16
    800010a8:	8082                	ret

00000000800010aa <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010aa:	7139                	addi	sp,sp,-64
    800010ac:	fc06                	sd	ra,56(sp)
    800010ae:	f822                	sd	s0,48(sp)
    800010b0:	f426                	sd	s1,40(sp)
    800010b2:	f04a                	sd	s2,32(sp)
    800010b4:	ec4e                	sd	s3,24(sp)
    800010b6:	e852                	sd	s4,16(sp)
    800010b8:	e456                	sd	s5,8(sp)
    800010ba:	e05a                	sd	s6,0(sp)
    800010bc:	0080                	addi	s0,sp,64
    800010be:	84aa                	mv	s1,a0
    800010c0:	89ae                	mv	s3,a1
    800010c2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010c4:	57fd                	li	a5,-1
    800010c6:	83e9                	srli	a5,a5,0x1a
    800010c8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010ca:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010cc:	04b7f263          	bgeu	a5,a1,80001110 <walk+0x66>
    panic("walk");
    800010d0:	00007517          	auipc	a0,0x7
    800010d4:	03050513          	addi	a0,a0,48 # 80008100 <digits+0xc0>
    800010d8:	fffff097          	auipc	ra,0xfffff
    800010dc:	468080e7          	jalr	1128(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010e0:	060a8663          	beqz	s5,8000114c <walk+0xa2>
    800010e4:	00000097          	auipc	ra,0x0
    800010e8:	a7e080e7          	jalr	-1410(ra) # 80000b62 <kalloc>
    800010ec:	84aa                	mv	s1,a0
    800010ee:	c529                	beqz	a0,80001138 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010f0:	6605                	lui	a2,0x1
    800010f2:	4581                	li	a1,0
    800010f4:	00000097          	auipc	ra,0x0
    800010f8:	cd2080e7          	jalr	-814(ra) # 80000dc6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010fc:	00c4d793          	srli	a5,s1,0xc
    80001100:	07aa                	slli	a5,a5,0xa
    80001102:	0017e793          	ori	a5,a5,1
    80001106:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000110a:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    8000110c:	036a0063          	beq	s4,s6,8000112c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001110:	0149d933          	srl	s2,s3,s4
    80001114:	1ff97913          	andi	s2,s2,511
    80001118:	090e                	slli	s2,s2,0x3
    8000111a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000111c:	00093483          	ld	s1,0(s2)
    80001120:	0014f793          	andi	a5,s1,1
    80001124:	dfd5                	beqz	a5,800010e0 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001126:	80a9                	srli	s1,s1,0xa
    80001128:	04b2                	slli	s1,s1,0xc
    8000112a:	b7c5                	j	8000110a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000112c:	00c9d513          	srli	a0,s3,0xc
    80001130:	1ff57513          	andi	a0,a0,511
    80001134:	050e                	slli	a0,a0,0x3
    80001136:	9526                	add	a0,a0,s1
}
    80001138:	70e2                	ld	ra,56(sp)
    8000113a:	7442                	ld	s0,48(sp)
    8000113c:	74a2                	ld	s1,40(sp)
    8000113e:	7902                	ld	s2,32(sp)
    80001140:	69e2                	ld	s3,24(sp)
    80001142:	6a42                	ld	s4,16(sp)
    80001144:	6aa2                	ld	s5,8(sp)
    80001146:	6b02                	ld	s6,0(sp)
    80001148:	6121                	addi	sp,sp,64
    8000114a:	8082                	ret
        return 0;
    8000114c:	4501                	li	a0,0
    8000114e:	b7ed                	j	80001138 <walk+0x8e>

0000000080001150 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001150:	57fd                	li	a5,-1
    80001152:	83e9                	srli	a5,a5,0x1a
    80001154:	00b7f463          	bgeu	a5,a1,8000115c <walkaddr+0xc>
    return 0;
    80001158:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000115a:	8082                	ret
{
    8000115c:	1141                	addi	sp,sp,-16
    8000115e:	e406                	sd	ra,8(sp)
    80001160:	e022                	sd	s0,0(sp)
    80001162:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001164:	4601                	li	a2,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f44080e7          	jalr	-188(ra) # 800010aa <walk>
  if(pte == 0)
    8000116e:	c105                	beqz	a0,8000118e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001170:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001172:	0117f693          	andi	a3,a5,17
    80001176:	4745                	li	a4,17
    return 0;
    80001178:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000117a:	00e68663          	beq	a3,a4,80001186 <walkaddr+0x36>
}
    8000117e:	60a2                	ld	ra,8(sp)
    80001180:	6402                	ld	s0,0(sp)
    80001182:	0141                	addi	sp,sp,16
    80001184:	8082                	ret
  pa = PTE2PA(*pte);
    80001186:	83a9                	srli	a5,a5,0xa
    80001188:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000118c:	bfcd                	j	8000117e <walkaddr+0x2e>
    return 0;
    8000118e:	4501                	li	a0,0
    80001190:	b7fd                	j	8000117e <walkaddr+0x2e>

0000000080001192 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001192:	715d                	addi	sp,sp,-80
    80001194:	e486                	sd	ra,72(sp)
    80001196:	e0a2                	sd	s0,64(sp)
    80001198:	fc26                	sd	s1,56(sp)
    8000119a:	f84a                	sd	s2,48(sp)
    8000119c:	f44e                	sd	s3,40(sp)
    8000119e:	f052                	sd	s4,32(sp)
    800011a0:	ec56                	sd	s5,24(sp)
    800011a2:	e85a                	sd	s6,16(sp)
    800011a4:	e45e                	sd	s7,8(sp)
    800011a6:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011a8:	c639                	beqz	a2,800011f6 <mappages+0x64>
    800011aa:	8aaa                	mv	s5,a0
    800011ac:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011ae:	777d                	lui	a4,0xfffff
    800011b0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011b4:	fff58993          	addi	s3,a1,-1
    800011b8:	99b2                	add	s3,s3,a2
    800011ba:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011be:	893e                	mv	s2,a5
    800011c0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011c4:	6b85                	lui	s7,0x1
    800011c6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ca:	4605                	li	a2,1
    800011cc:	85ca                	mv	a1,s2
    800011ce:	8556                	mv	a0,s5
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	eda080e7          	jalr	-294(ra) # 800010aa <walk>
    800011d8:	cd1d                	beqz	a0,80001216 <mappages+0x84>
    if(*pte & PTE_V)
    800011da:	611c                	ld	a5,0(a0)
    800011dc:	8b85                	andi	a5,a5,1
    800011de:	e785                	bnez	a5,80001206 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011e0:	80b1                	srli	s1,s1,0xc
    800011e2:	04aa                	slli	s1,s1,0xa
    800011e4:	0164e4b3          	or	s1,s1,s6
    800011e8:	0014e493          	ori	s1,s1,1
    800011ec:	e104                	sd	s1,0(a0)
    if(a == last)
    800011ee:	05390063          	beq	s2,s3,8000122e <mappages+0x9c>
    a += PGSIZE;
    800011f2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011f4:	bfc9                	j	800011c6 <mappages+0x34>
    panic("mappages: size");
    800011f6:	00007517          	auipc	a0,0x7
    800011fa:	f1250513          	addi	a0,a0,-238 # 80008108 <digits+0xc8>
    800011fe:	fffff097          	auipc	ra,0xfffff
    80001202:	342080e7          	jalr	834(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001206:	00007517          	auipc	a0,0x7
    8000120a:	f1250513          	addi	a0,a0,-238 # 80008118 <digits+0xd8>
    8000120e:	fffff097          	auipc	ra,0xfffff
    80001212:	332080e7          	jalr	818(ra) # 80000540 <panic>
      return -1;
    80001216:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001218:	60a6                	ld	ra,72(sp)
    8000121a:	6406                	ld	s0,64(sp)
    8000121c:	74e2                	ld	s1,56(sp)
    8000121e:	7942                	ld	s2,48(sp)
    80001220:	79a2                	ld	s3,40(sp)
    80001222:	7a02                	ld	s4,32(sp)
    80001224:	6ae2                	ld	s5,24(sp)
    80001226:	6b42                	ld	s6,16(sp)
    80001228:	6ba2                	ld	s7,8(sp)
    8000122a:	6161                	addi	sp,sp,80
    8000122c:	8082                	ret
  return 0;
    8000122e:	4501                	li	a0,0
    80001230:	b7e5                	j	80001218 <mappages+0x86>

0000000080001232 <kvmmap>:
{
    80001232:	1141                	addi	sp,sp,-16
    80001234:	e406                	sd	ra,8(sp)
    80001236:	e022                	sd	s0,0(sp)
    80001238:	0800                	addi	s0,sp,16
    8000123a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000123c:	86b2                	mv	a3,a2
    8000123e:	863e                	mv	a2,a5
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f52080e7          	jalr	-174(ra) # 80001192 <mappages>
    80001248:	e509                	bnez	a0,80001252 <kvmmap+0x20>
}
    8000124a:	60a2                	ld	ra,8(sp)
    8000124c:	6402                	ld	s0,0(sp)
    8000124e:	0141                	addi	sp,sp,16
    80001250:	8082                	ret
    panic("kvmmap");
    80001252:	00007517          	auipc	a0,0x7
    80001256:	ed650513          	addi	a0,a0,-298 # 80008128 <digits+0xe8>
    8000125a:	fffff097          	auipc	ra,0xfffff
    8000125e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>

0000000080001262 <kvmmake>:
{
    80001262:	1101                	addi	sp,sp,-32
    80001264:	ec06                	sd	ra,24(sp)
    80001266:	e822                	sd	s0,16(sp)
    80001268:	e426                	sd	s1,8(sp)
    8000126a:	e04a                	sd	s2,0(sp)
    8000126c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	8f4080e7          	jalr	-1804(ra) # 80000b62 <kalloc>
    80001276:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001278:	6605                	lui	a2,0x1
    8000127a:	4581                	li	a1,0
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	b4a080e7          	jalr	-1206(ra) # 80000dc6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001284:	4719                	li	a4,6
    80001286:	6685                	lui	a3,0x1
    80001288:	10000637          	lui	a2,0x10000
    8000128c:	100005b7          	lui	a1,0x10000
    80001290:	8526                	mv	a0,s1
    80001292:	00000097          	auipc	ra,0x0
    80001296:	fa0080e7          	jalr	-96(ra) # 80001232 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000129a:	4719                	li	a4,6
    8000129c:	6685                	lui	a3,0x1
    8000129e:	10001637          	lui	a2,0x10001
    800012a2:	100015b7          	lui	a1,0x10001
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f8a080e7          	jalr	-118(ra) # 80001232 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4719                	li	a4,6
    800012b2:	004006b7          	lui	a3,0x400
    800012b6:	0c000637          	lui	a2,0xc000
    800012ba:	0c0005b7          	lui	a1,0xc000
    800012be:	8526                	mv	a0,s1
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	f72080e7          	jalr	-142(ra) # 80001232 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c8:	00007917          	auipc	s2,0x7
    800012cc:	d3890913          	addi	s2,s2,-712 # 80008000 <etext>
    800012d0:	4729                	li	a4,10
    800012d2:	80007697          	auipc	a3,0x80007
    800012d6:	d2e68693          	addi	a3,a3,-722 # 8000 <_entry-0x7fff8000>
    800012da:	4605                	li	a2,1
    800012dc:	067e                	slli	a2,a2,0x1f
    800012de:	85b2                	mv	a1,a2
    800012e0:	8526                	mv	a0,s1
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	f50080e7          	jalr	-176(ra) # 80001232 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ea:	4719                	li	a4,6
    800012ec:	46c5                	li	a3,17
    800012ee:	06ee                	slli	a3,a3,0x1b
    800012f0:	412686b3          	sub	a3,a3,s2
    800012f4:	864a                	mv	a2,s2
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f38080e7          	jalr	-200(ra) # 80001232 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001302:	4729                	li	a4,10
    80001304:	6685                	lui	a3,0x1
    80001306:	00006617          	auipc	a2,0x6
    8000130a:	cfa60613          	addi	a2,a2,-774 # 80007000 <_trampoline>
    8000130e:	040005b7          	lui	a1,0x4000
    80001312:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001314:	05b2                	slli	a1,a1,0xc
    80001316:	8526                	mv	a0,s1
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	f1a080e7          	jalr	-230(ra) # 80001232 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001320:	8526                	mv	a0,s1
    80001322:	00000097          	auipc	ra,0x0
    80001326:	6ca080e7          	jalr	1738(ra) # 800019ec <proc_mapstacks>
}
    8000132a:	8526                	mv	a0,s1
    8000132c:	60e2                	ld	ra,24(sp)
    8000132e:	6442                	ld	s0,16(sp)
    80001330:	64a2                	ld	s1,8(sp)
    80001332:	6902                	ld	s2,0(sp)
    80001334:	6105                	addi	sp,sp,32
    80001336:	8082                	ret

0000000080001338 <kvminit>:
{
    80001338:	1141                	addi	sp,sp,-16
    8000133a:	e406                	sd	ra,8(sp)
    8000133c:	e022                	sd	s0,0(sp)
    8000133e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001340:	00000097          	auipc	ra,0x0
    80001344:	f22080e7          	jalr	-222(ra) # 80001262 <kvmmake>
    80001348:	00007797          	auipc	a5,0x7
    8000134c:	60a7bc23          	sd	a0,1560(a5) # 80008960 <kernel_pagetable>
}
    80001350:	60a2                	ld	ra,8(sp)
    80001352:	6402                	ld	s0,0(sp)
    80001354:	0141                	addi	sp,sp,16
    80001356:	8082                	ret

0000000080001358 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001358:	715d                	addi	sp,sp,-80
    8000135a:	e486                	sd	ra,72(sp)
    8000135c:	e0a2                	sd	s0,64(sp)
    8000135e:	fc26                	sd	s1,56(sp)
    80001360:	f84a                	sd	s2,48(sp)
    80001362:	f44e                	sd	s3,40(sp)
    80001364:	f052                	sd	s4,32(sp)
    80001366:	ec56                	sd	s5,24(sp)
    80001368:	e85a                	sd	s6,16(sp)
    8000136a:	e45e                	sd	s7,8(sp)
    8000136c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000136e:	03459793          	slli	a5,a1,0x34
    80001372:	e795                	bnez	a5,8000139e <uvmunmap+0x46>
    80001374:	8a2a                	mv	s4,a0
    80001376:	892e                	mv	s2,a1
    80001378:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137a:	0632                	slli	a2,a2,0xc
    8000137c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001380:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001382:	6b05                	lui	s6,0x1
    80001384:	0735e263          	bltu	a1,s3,800013e8 <uvmunmap+0x90>
    //   }
    //   //do nothing if refcount == 1
    // }
    *pte = 0;
  }
}
    80001388:	60a6                	ld	ra,72(sp)
    8000138a:	6406                	ld	s0,64(sp)
    8000138c:	74e2                	ld	s1,56(sp)
    8000138e:	7942                	ld	s2,48(sp)
    80001390:	79a2                	ld	s3,40(sp)
    80001392:	7a02                	ld	s4,32(sp)
    80001394:	6ae2                	ld	s5,24(sp)
    80001396:	6b42                	ld	s6,16(sp)
    80001398:	6ba2                	ld	s7,8(sp)
    8000139a:	6161                	addi	sp,sp,80
    8000139c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	d9250513          	addi	a0,a0,-622 # 80008130 <digits+0xf0>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	19a080e7          	jalr	410(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d9a50513          	addi	a0,a0,-614 # 80008148 <digits+0x108>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	18a080e7          	jalr	394(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800013be:	00007517          	auipc	a0,0x7
    800013c2:	d9a50513          	addi	a0,a0,-614 # 80008158 <digits+0x118>
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	17a080e7          	jalr	378(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800013ce:	00007517          	auipc	a0,0x7
    800013d2:	da250513          	addi	a0,a0,-606 # 80008170 <digits+0x130>
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	16a080e7          	jalr	362(ra) # 80000540 <panic>
    *pte = 0;
    800013de:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e2:	995a                	add	s2,s2,s6
    800013e4:	fb3972e3          	bgeu	s2,s3,80001388 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013e8:	4601                	li	a2,0
    800013ea:	85ca                	mv	a1,s2
    800013ec:	8552                	mv	a0,s4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	cbc080e7          	jalr	-836(ra) # 800010aa <walk>
    800013f6:	84aa                	mv	s1,a0
    800013f8:	d95d                	beqz	a0,800013ae <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013fa:	6108                	ld	a0,0(a0)
    800013fc:	00157793          	andi	a5,a0,1
    80001400:	dfdd                	beqz	a5,800013be <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001402:	3ff57793          	andi	a5,a0,1023
    80001406:	fd7784e3          	beq	a5,s7,800013ce <uvmunmap+0x76>
    if(do_free){
    8000140a:	fc0a8ae3          	beqz	s5,800013de <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000140e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001410:	0532                	slli	a0,a0,0xc
    80001412:	fffff097          	auipc	ra,0xfffff
    80001416:	5d6080e7          	jalr	1494(ra) # 800009e8 <kfree>
    8000141a:	b7d1                	j	800013de <uvmunmap+0x86>

000000008000141c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000141c:	1101                	addi	sp,sp,-32
    8000141e:	ec06                	sd	ra,24(sp)
    80001420:	e822                	sd	s0,16(sp)
    80001422:	e426                	sd	s1,8(sp)
    80001424:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001426:	fffff097          	auipc	ra,0xfffff
    8000142a:	73c080e7          	jalr	1852(ra) # 80000b62 <kalloc>
    8000142e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001430:	c519                	beqz	a0,8000143e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001432:	6605                	lui	a2,0x1
    80001434:	4581                	li	a1,0
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	990080e7          	jalr	-1648(ra) # 80000dc6 <memset>
  return pagetable;
}
    8000143e:	8526                	mv	a0,s1
    80001440:	60e2                	ld	ra,24(sp)
    80001442:	6442                	ld	s0,16(sp)
    80001444:	64a2                	ld	s1,8(sp)
    80001446:	6105                	addi	sp,sp,32
    80001448:	8082                	ret

000000008000144a <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000144a:	7179                	addi	sp,sp,-48
    8000144c:	f406                	sd	ra,40(sp)
    8000144e:	f022                	sd	s0,32(sp)
    80001450:	ec26                	sd	s1,24(sp)
    80001452:	e84a                	sd	s2,16(sp)
    80001454:	e44e                	sd	s3,8(sp)
    80001456:	e052                	sd	s4,0(sp)
    80001458:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000145a:	6785                	lui	a5,0x1
    8000145c:	04f67863          	bgeu	a2,a5,800014ac <uvmfirst+0x62>
    80001460:	8a2a                	mv	s4,a0
    80001462:	89ae                	mv	s3,a1
    80001464:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001466:	fffff097          	auipc	ra,0xfffff
    8000146a:	6fc080e7          	jalr	1788(ra) # 80000b62 <kalloc>
    8000146e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001470:	6605                	lui	a2,0x1
    80001472:	4581                	li	a1,0
    80001474:	00000097          	auipc	ra,0x0
    80001478:	952080e7          	jalr	-1710(ra) # 80000dc6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000147c:	4779                	li	a4,30
    8000147e:	86ca                	mv	a3,s2
    80001480:	6605                	lui	a2,0x1
    80001482:	4581                	li	a1,0
    80001484:	8552                	mv	a0,s4
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	d0c080e7          	jalr	-756(ra) # 80001192 <mappages>
  memmove(mem, src, sz);
    8000148e:	8626                	mv	a2,s1
    80001490:	85ce                	mv	a1,s3
    80001492:	854a                	mv	a0,s2
    80001494:	00000097          	auipc	ra,0x0
    80001498:	98e080e7          	jalr	-1650(ra) # 80000e22 <memmove>
}
    8000149c:	70a2                	ld	ra,40(sp)
    8000149e:	7402                	ld	s0,32(sp)
    800014a0:	64e2                	ld	s1,24(sp)
    800014a2:	6942                	ld	s2,16(sp)
    800014a4:	69a2                	ld	s3,8(sp)
    800014a6:	6a02                	ld	s4,0(sp)
    800014a8:	6145                	addi	sp,sp,48
    800014aa:	8082                	ret
    panic("uvmfirst: more than a page");
    800014ac:	00007517          	auipc	a0,0x7
    800014b0:	cdc50513          	addi	a0,a0,-804 # 80008188 <digits+0x148>
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	08c080e7          	jalr	140(ra) # 80000540 <panic>

00000000800014bc <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014bc:	1101                	addi	sp,sp,-32
    800014be:	ec06                	sd	ra,24(sp)
    800014c0:	e822                	sd	s0,16(sp)
    800014c2:	e426                	sd	s1,8(sp)
    800014c4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014c6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014c8:	00b67d63          	bgeu	a2,a1,800014e2 <uvmdealloc+0x26>
    800014cc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014ce:	6785                	lui	a5,0x1
    800014d0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014d2:	00f60733          	add	a4,a2,a5
    800014d6:	76fd                	lui	a3,0xfffff
    800014d8:	8f75                	and	a4,a4,a3
    800014da:	97ae                	add	a5,a5,a1
    800014dc:	8ff5                	and	a5,a5,a3
    800014de:	00f76863          	bltu	a4,a5,800014ee <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014e2:	8526                	mv	a0,s1
    800014e4:	60e2                	ld	ra,24(sp)
    800014e6:	6442                	ld	s0,16(sp)
    800014e8:	64a2                	ld	s1,8(sp)
    800014ea:	6105                	addi	sp,sp,32
    800014ec:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ee:	8f99                	sub	a5,a5,a4
    800014f0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014f2:	4685                	li	a3,1
    800014f4:	0007861b          	sext.w	a2,a5
    800014f8:	85ba                	mv	a1,a4
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	e5e080e7          	jalr	-418(ra) # 80001358 <uvmunmap>
    80001502:	b7c5                	j	800014e2 <uvmdealloc+0x26>

0000000080001504 <uvmalloc>:
  if(newsz < oldsz)
    80001504:	0ab66563          	bltu	a2,a1,800015ae <uvmalloc+0xaa>
{
    80001508:	7139                	addi	sp,sp,-64
    8000150a:	fc06                	sd	ra,56(sp)
    8000150c:	f822                	sd	s0,48(sp)
    8000150e:	f426                	sd	s1,40(sp)
    80001510:	f04a                	sd	s2,32(sp)
    80001512:	ec4e                	sd	s3,24(sp)
    80001514:	e852                	sd	s4,16(sp)
    80001516:	e456                	sd	s5,8(sp)
    80001518:	e05a                	sd	s6,0(sp)
    8000151a:	0080                	addi	s0,sp,64
    8000151c:	8aaa                	mv	s5,a0
    8000151e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001520:	6785                	lui	a5,0x1
    80001522:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001524:	95be                	add	a1,a1,a5
    80001526:	77fd                	lui	a5,0xfffff
    80001528:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152c:	08c9f363          	bgeu	s3,a2,800015b2 <uvmalloc+0xae>
    80001530:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001532:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001536:	fffff097          	auipc	ra,0xfffff
    8000153a:	62c080e7          	jalr	1580(ra) # 80000b62 <kalloc>
    8000153e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001540:	c51d                	beqz	a0,8000156e <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001542:	6605                	lui	a2,0x1
    80001544:	4581                	li	a1,0
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	880080e7          	jalr	-1920(ra) # 80000dc6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000154e:	875a                	mv	a4,s6
    80001550:	86a6                	mv	a3,s1
    80001552:	6605                	lui	a2,0x1
    80001554:	85ca                	mv	a1,s2
    80001556:	8556                	mv	a0,s5
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	c3a080e7          	jalr	-966(ra) # 80001192 <mappages>
    80001560:	e90d                	bnez	a0,80001592 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001562:	6785                	lui	a5,0x1
    80001564:	993e                	add	s2,s2,a5
    80001566:	fd4968e3          	bltu	s2,s4,80001536 <uvmalloc+0x32>
  return newsz;
    8000156a:	8552                	mv	a0,s4
    8000156c:	a809                	j	8000157e <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000156e:	864e                	mv	a2,s3
    80001570:	85ca                	mv	a1,s2
    80001572:	8556                	mv	a0,s5
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f48080e7          	jalr	-184(ra) # 800014bc <uvmdealloc>
      return 0;
    8000157c:	4501                	li	a0,0
}
    8000157e:	70e2                	ld	ra,56(sp)
    80001580:	7442                	ld	s0,48(sp)
    80001582:	74a2                	ld	s1,40(sp)
    80001584:	7902                	ld	s2,32(sp)
    80001586:	69e2                	ld	s3,24(sp)
    80001588:	6a42                	ld	s4,16(sp)
    8000158a:	6aa2                	ld	s5,8(sp)
    8000158c:	6b02                	ld	s6,0(sp)
    8000158e:	6121                	addi	sp,sp,64
    80001590:	8082                	ret
      kfree(mem);
    80001592:	8526                	mv	a0,s1
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	454080e7          	jalr	1108(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000159c:	864e                	mv	a2,s3
    8000159e:	85ca                	mv	a1,s2
    800015a0:	8556                	mv	a0,s5
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	f1a080e7          	jalr	-230(ra) # 800014bc <uvmdealloc>
      return 0;
    800015aa:	4501                	li	a0,0
    800015ac:	bfc9                	j	8000157e <uvmalloc+0x7a>
    return oldsz;
    800015ae:	852e                	mv	a0,a1
}
    800015b0:	8082                	ret
  return newsz;
    800015b2:	8532                	mv	a0,a2
    800015b4:	b7e9                	j	8000157e <uvmalloc+0x7a>

00000000800015b6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015b6:	7179                	addi	sp,sp,-48
    800015b8:	f406                	sd	ra,40(sp)
    800015ba:	f022                	sd	s0,32(sp)
    800015bc:	ec26                	sd	s1,24(sp)
    800015be:	e84a                	sd	s2,16(sp)
    800015c0:	e44e                	sd	s3,8(sp)
    800015c2:	e052                	sd	s4,0(sp)
    800015c4:	1800                	addi	s0,sp,48
    800015c6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015c8:	84aa                	mv	s1,a0
    800015ca:	6905                	lui	s2,0x1
    800015cc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ce:	4985                	li	s3,1
    800015d0:	a829                	j	800015ea <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015d2:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015d4:	00c79513          	slli	a0,a5,0xc
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	fde080e7          	jalr	-34(ra) # 800015b6 <freewalk>
      pagetable[i] = 0;
    800015e0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015e4:	04a1                	addi	s1,s1,8
    800015e6:	03248163          	beq	s1,s2,80001608 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015ea:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ec:	00f7f713          	andi	a4,a5,15
    800015f0:	ff3701e3          	beq	a4,s3,800015d2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015f4:	8b85                	andi	a5,a5,1
    800015f6:	d7fd                	beqz	a5,800015e4 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f40080e7          	jalr	-192(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001608:	8552                	mv	a0,s4
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3de080e7          	jalr	990(ra) # 800009e8 <kfree>
}
    80001612:	70a2                	ld	ra,40(sp)
    80001614:	7402                	ld	s0,32(sp)
    80001616:	64e2                	ld	s1,24(sp)
    80001618:	6942                	ld	s2,16(sp)
    8000161a:	69a2                	ld	s3,8(sp)
    8000161c:	6a02                	ld	s4,0(sp)
    8000161e:	6145                	addi	sp,sp,48
    80001620:	8082                	ret

0000000080001622 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001622:	1101                	addi	sp,sp,-32
    80001624:	ec06                	sd	ra,24(sp)
    80001626:	e822                	sd	s0,16(sp)
    80001628:	e426                	sd	s1,8(sp)
    8000162a:	1000                	addi	s0,sp,32
    8000162c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000162e:	e999                	bnez	a1,80001644 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001630:	8526                	mv	a0,s1
    80001632:	00000097          	auipc	ra,0x0
    80001636:	f84080e7          	jalr	-124(ra) # 800015b6 <freewalk>
}
    8000163a:	60e2                	ld	ra,24(sp)
    8000163c:	6442                	ld	s0,16(sp)
    8000163e:	64a2                	ld	s1,8(sp)
    80001640:	6105                	addi	sp,sp,32
    80001642:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001644:	6785                	lui	a5,0x1
    80001646:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001648:	95be                	add	a1,a1,a5
    8000164a:	4685                	li	a3,1
    8000164c:	00c5d613          	srli	a2,a1,0xc
    80001650:	4581                	li	a1,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	d06080e7          	jalr	-762(ra) # 80001358 <uvmunmap>
    8000165a:	bfd9                	j	80001630 <uvmfree+0xe>

000000008000165c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //removed the mem char here

  for(i = 0; i < sz; i += PGSIZE){
    8000165c:	c669                	beqz	a2,80001726 <uvmcopy+0xca>
{
    8000165e:	7139                	addi	sp,sp,-64
    80001660:	fc06                	sd	ra,56(sp)
    80001662:	f822                	sd	s0,48(sp)
    80001664:	f426                	sd	s1,40(sp)
    80001666:	f04a                	sd	s2,32(sp)
    80001668:	ec4e                	sd	s3,24(sp)
    8000166a:	e852                	sd	s4,16(sp)
    8000166c:	e456                	sd	s5,8(sp)
    8000166e:	e05a                	sd	s6,0(sp)
    80001670:	0080                	addi	s0,sp,64
    80001672:	8b2a                	mv	s6,a0
    80001674:	8aae                	mv	s5,a1
    80001676:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001678:	4981                	li	s3,0
    8000167a:	a091                	j	800016be <uvmcopy+0x62>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    8000167c:	00007517          	auipc	a0,0x7
    80001680:	b3c50513          	addi	a0,a0,-1220 # 800081b8 <digits+0x178>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	ebc080e7          	jalr	-324(ra) # 80000540 <panic>
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    8000168c:	00007517          	auipc	a0,0x7
    80001690:	b4c50513          	addi	a0,a0,-1204 # 800081d8 <digits+0x198>
    80001694:	fffff097          	auipc	ra,0xfffff
    80001698:	eac080e7          	jalr	-340(ra) # 80000540 <panic>
      *pte &= ~PTE_W;//remove write
      *pte |= PTE_COW;//set cow 
    }
    

    flags = PTE_FLAGS(*pte);
    8000169c:	00093703          	ld	a4,0(s2) # 1000 <_entry-0x7ffff000>
    //map to same physical address
    if(mappages(new, i, PGSIZE, pa, flags) != 0)
    800016a0:	3ff77713          	andi	a4,a4,1023
    800016a4:	86a6                	mv	a3,s1
    800016a6:	6605                	lui	a2,0x1
    800016a8:	85ce                	mv	a1,s3
    800016aa:	8556                	mv	a0,s5
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	ae6080e7          	jalr	-1306(ra) # 80001192 <mappages>
    800016b4:	e529                	bnez	a0,800016fe <uvmcopy+0xa2>
  for(i = 0; i < sz; i += PGSIZE){
    800016b6:	6785                	lui	a5,0x1
    800016b8:	99be                	add	s3,s3,a5
    800016ba:	0549fc63          	bgeu	s3,s4,80001712 <uvmcopy+0xb6>
    if((pte = walk(old, i, 0)) == 0)
    800016be:	4601                	li	a2,0
    800016c0:	85ce                	mv	a1,s3
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9e6080e7          	jalr	-1562(ra) # 800010aa <walk>
    800016cc:	892a                	mv	s2,a0
    800016ce:	d55d                	beqz	a0,8000167c <uvmcopy+0x20>
    if((*pte & PTE_V) == 0)
    800016d0:	6114                	ld	a3,0(a0)
    800016d2:	0016f793          	andi	a5,a3,1
    800016d6:	dbdd                	beqz	a5,8000168c <uvmcopy+0x30>
    pa = PTE2PA(*pte);
    800016d8:	82a9                	srli	a3,a3,0xa
    800016da:	00c69493          	slli	s1,a3,0xc
    increase_ref((void*)pa);
    800016de:	8526                	mv	a0,s1
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	4f8080e7          	jalr	1272(ra) # 80000bd8 <increase_ref>
    if ((*pte & PTE_W))
    800016e8:	00093783          	ld	a5,0(s2)
    800016ec:	0047f713          	andi	a4,a5,4
    800016f0:	d755                	beqz	a4,8000169c <uvmcopy+0x40>
      *pte &= ~PTE_W;//remove write
    800016f2:	9bed                	andi	a5,a5,-5
      *pte |= PTE_COW;//set cow 
    800016f4:	2007e793          	ori	a5,a5,512
    800016f8:	00f93023          	sd	a5,0(s2)
    800016fc:	b745                	j	8000169c <uvmcopy+0x40>
    // }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016fe:	4685                	li	a3,1
    80001700:	00c9d613          	srli	a2,s3,0xc
    80001704:	4581                	li	a1,0
    80001706:	8556                	mv	a0,s5
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	c50080e7          	jalr	-944(ra) # 80001358 <uvmunmap>
  return -1;
    80001710:	557d                	li	a0,-1
}
    80001712:	70e2                	ld	ra,56(sp)
    80001714:	7442                	ld	s0,48(sp)
    80001716:	74a2                	ld	s1,40(sp)
    80001718:	7902                	ld	s2,32(sp)
    8000171a:	69e2                	ld	s3,24(sp)
    8000171c:	6a42                	ld	s4,16(sp)
    8000171e:	6aa2                	ld	s5,8(sp)
    80001720:	6b02                	ld	s6,0(sp)
    80001722:	6121                	addi	sp,sp,64
    80001724:	8082                	ret
  return 0;
    80001726:	4501                	li	a0,0
}
    80001728:	8082                	ret

000000008000172a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000172a:	1141                	addi	sp,sp,-16
    8000172c:	e406                	sd	ra,8(sp)
    8000172e:	e022                	sd	s0,0(sp)
    80001730:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001732:	4601                	li	a2,0
    80001734:	00000097          	auipc	ra,0x0
    80001738:	976080e7          	jalr	-1674(ra) # 800010aa <walk>
  if(pte == 0)
    8000173c:	c901                	beqz	a0,8000174c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000173e:	611c                	ld	a5,0(a0)
    80001740:	9bbd                	andi	a5,a5,-17
    80001742:	e11c                	sd	a5,0(a0)
}
    80001744:	60a2                	ld	ra,8(sp)
    80001746:	6402                	ld	s0,0(sp)
    80001748:	0141                	addi	sp,sp,16
    8000174a:	8082                	ret
    panic("uvmclear");
    8000174c:	00007517          	auipc	a0,0x7
    80001750:	aac50513          	addi	a0,a0,-1364 # 800081f8 <digits+0x1b8>
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	dec080e7          	jalr	-532(ra) # 80000540 <panic>

000000008000175c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000175c:	10068f63          	beqz	a3,8000187a <copyout+0x11e>
{
    80001760:	7159                	addi	sp,sp,-112
    80001762:	f486                	sd	ra,104(sp)
    80001764:	f0a2                	sd	s0,96(sp)
    80001766:	eca6                	sd	s1,88(sp)
    80001768:	e8ca                	sd	s2,80(sp)
    8000176a:	e4ce                	sd	s3,72(sp)
    8000176c:	e0d2                	sd	s4,64(sp)
    8000176e:	fc56                	sd	s5,56(sp)
    80001770:	f85a                	sd	s6,48(sp)
    80001772:	f45e                	sd	s7,40(sp)
    80001774:	f062                	sd	s8,32(sp)
    80001776:	ec66                	sd	s9,24(sp)
    80001778:	e86a                	sd	s10,16(sp)
    8000177a:	e46e                	sd	s11,8(sp)
    8000177c:	1880                	addi	s0,sp,112
    8000177e:	8baa                	mv	s7,a0
    80001780:	8aae                	mv	s5,a1
    80001782:	8b32                	mv	s6,a2
    80001784:	8a36                	mv	s4,a3
   va0 = PGROUNDDOWN(dstva);
    80001786:	74fd                	lui	s1,0xfffff
    80001788:	8ced                	and	s1,s1,a1
    
    // error handling for the virtual address
    if (va0>=MAXVA){
    8000178a:	57fd                	li	a5,-1
    8000178c:	83e9                	srli	a5,a5,0x1a
    8000178e:	0e97e863          	bltu	a5,s1,8000187e <copyout+0x122>
    }
    
    pte_t *pte = walk(pagetable, va0, 0);

    // error check the flags
    if (pte==0||(*pte&PTE_U)==0||(*pte&PTE_V)==0){
    80001792:	4cc5                	li	s9,17
    }

    if(*pte & PTE_COW)
    {
      uint64 pa = PTE2PA(*pte);
      if(get_refcount((void*)pa) == 1) //if theres only one process refering to process, directly edit(no need to kalloc afresh)
    80001794:	4d85                	li	s11,1
    if (va0>=MAXVA){
    80001796:	57fd                	li	a5,-1
    80001798:	01a7dd13          	srli	s10,a5,0x1a
    8000179c:	a861                	j	80001834 <copyout+0xd8>
      uint64 pa = PTE2PA(*pte);
    8000179e:	00a9d993          	srli	s3,s3,0xa
    800017a2:	09b2                	slli	s3,s3,0xc
      if(get_refcount((void*)pa) == 1) //if theres only one process refering to process, directly edit(no need to kalloc afresh)
    800017a4:	854e                	mv	a0,s3
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	476080e7          	jalr	1142(ra) # 80000c1c <get_refcount>
    800017ae:	01b51b63          	bne	a0,s11,800017c4 <copyout+0x68>
      {
        *pte |= PTE_W;
        *pte &= ~PTE_COW;
    800017b2:	00093783          	ld	a5,0(s2)
    800017b6:	dff7f793          	andi	a5,a5,-513
    800017ba:	0047e793          	ori	a5,a5,4
    800017be:	00f93023          	sd	a5,0(s2)
    800017c2:	a859                	j	80001858 <copyout+0xfc>
      }
      else  //make new page
      {
        void * newpagepa = kalloc();
    800017c4:	fffff097          	auipc	ra,0xfffff
    800017c8:	39e080e7          	jalr	926(ra) # 80000b62 <kalloc>
    800017cc:	8c2a                	mv	s8,a0
        if(newpagepa == 0)
    800017ce:	c915                	beqz	a0,80001802 <copyout+0xa6>
        {
          exit(-1);
        }
        else
        {
          memmove(newpagepa, (void*)pa, PGSIZE);
    800017d0:	6605                	lui	a2,0x1
    800017d2:	85ce                	mv	a1,s3
    800017d4:	fffff097          	auipc	ra,0xfffff
    800017d8:	64e080e7          	jalr	1614(ra) # 80000e22 <memmove>
          uint flags = PTE_FLAGS(*pte);
          uint64 newpagepte = PA2PTE(newpagepa) | flags | PTE_V;
    800017dc:	00cc5c13          	srli	s8,s8,0xc
    800017e0:	0c2a                	slli	s8,s8,0xa
          uint flags = PTE_FLAGS(*pte);
    800017e2:	00093783          	ld	a5,0(s2)
          uint64 newpagepte = PA2PTE(newpagepa) | flags | PTE_V;
    800017e6:	1ff7f793          	andi	a5,a5,511
          *pte = newpagepte;
          *pte |= PTE_W; //allow writes for new page
          *pte &= ~PTE_COW; //unset cow 
    800017ea:	0187e7b3          	or	a5,a5,s8
    800017ee:	0057e793          	ori	a5,a5,5
    800017f2:	00f93023          	sd	a5,0(s2)

          kfree((void*)pa); //decrease ref count of old page and free
    800017f6:	854e                	mv	a0,s3
    800017f8:	fffff097          	auipc	ra,0xfffff
    800017fc:	1f0080e7          	jalr	496(ra) # 800009e8 <kfree>
    80001800:	a8a1                	j	80001858 <copyout+0xfc>
          exit(-1);
    80001802:	557d                	li	a0,-1
    80001804:	00001097          	auipc	ra,0x1
    80001808:	d00080e7          	jalr	-768(ra) # 80002504 <exit>
    8000180c:	a0b1                	j	80001858 <copyout+0xfc>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000180e:	409a84b3          	sub	s1,s5,s1
    80001812:	0009861b          	sext.w	a2,s3
    80001816:	85da                	mv	a1,s6
    80001818:	9526                	add	a0,a0,s1
    8000181a:	fffff097          	auipc	ra,0xfffff
    8000181e:	608080e7          	jalr	1544(ra) # 80000e22 <memmove>

    len -= n;
    80001822:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001826:	9b4e                	add	s6,s6,s3
  while(len > 0){
    80001828:	040a0763          	beqz	s4,80001876 <copyout+0x11a>
    if (va0>=MAXVA){
    8000182c:	052d6b63          	bltu	s10,s2,80001882 <copyout+0x126>
   va0 = PGROUNDDOWN(dstva);
    80001830:	84ca                	mv	s1,s2
    dstva = va0 + PGSIZE;
    80001832:	8aca                	mv	s5,s2
    pte_t *pte = walk(pagetable, va0, 0);
    80001834:	4601                	li	a2,0
    80001836:	85a6                	mv	a1,s1
    80001838:	855e                	mv	a0,s7
    8000183a:	00000097          	auipc	ra,0x0
    8000183e:	870080e7          	jalr	-1936(ra) # 800010aa <walk>
    80001842:	892a                	mv	s2,a0
    if (pte==0||(*pte&PTE_U)==0||(*pte&PTE_V)==0){
    80001844:	c129                	beqz	a0,80001886 <copyout+0x12a>
    80001846:	00053983          	ld	s3,0(a0)
    8000184a:	0119f793          	andi	a5,s3,17
    8000184e:	05979c63          	bne	a5,s9,800018a6 <copyout+0x14a>
    if(*pte & PTE_COW)
    80001852:	2009f793          	andi	a5,s3,512
    80001856:	f7a1                	bnez	a5,8000179e <copyout+0x42>
    pa0 = walkaddr(pagetable, va0);
    80001858:	85a6                	mv	a1,s1
    8000185a:	855e                	mv	a0,s7
    8000185c:	00000097          	auipc	ra,0x0
    80001860:	8f4080e7          	jalr	-1804(ra) # 80001150 <walkaddr>
    if(pa0 == 0)
    80001864:	c139                	beqz	a0,800018aa <copyout+0x14e>
    n = PGSIZE - (dstva - va0);
    80001866:	6905                	lui	s2,0x1
    80001868:	9926                	add	s2,s2,s1
    8000186a:	415909b3          	sub	s3,s2,s5
    8000186e:	fb3a70e3          	bgeu	s4,s3,8000180e <copyout+0xb2>
    80001872:	89d2                	mv	s3,s4
    80001874:	bf69                	j	8000180e <copyout+0xb2>
  }
  return 0;
    80001876:	4501                	li	a0,0
    80001878:	a801                	j	80001888 <copyout+0x12c>
    8000187a:	4501                	li	a0,0
}
    8000187c:	8082                	ret
      return -1;
    8000187e:	557d                	li	a0,-1
    80001880:	a021                	j	80001888 <copyout+0x12c>
    80001882:	557d                	li	a0,-1
    80001884:	a011                	j	80001888 <copyout+0x12c>
      return -1;
    80001886:	557d                	li	a0,-1
}
    80001888:	70a6                	ld	ra,104(sp)
    8000188a:	7406                	ld	s0,96(sp)
    8000188c:	64e6                	ld	s1,88(sp)
    8000188e:	6946                	ld	s2,80(sp)
    80001890:	69a6                	ld	s3,72(sp)
    80001892:	6a06                	ld	s4,64(sp)
    80001894:	7ae2                	ld	s5,56(sp)
    80001896:	7b42                	ld	s6,48(sp)
    80001898:	7ba2                	ld	s7,40(sp)
    8000189a:	7c02                	ld	s8,32(sp)
    8000189c:	6ce2                	ld	s9,24(sp)
    8000189e:	6d42                	ld	s10,16(sp)
    800018a0:	6da2                	ld	s11,8(sp)
    800018a2:	6165                	addi	sp,sp,112
    800018a4:	8082                	ret
      return -1;
    800018a6:	557d                	li	a0,-1
    800018a8:	b7c5                	j	80001888 <copyout+0x12c>
      return -1;
    800018aa:	557d                	li	a0,-1
    800018ac:	bff1                	j	80001888 <copyout+0x12c>

00000000800018ae <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018ae:	caa5                	beqz	a3,8000191e <copyin+0x70>
{
    800018b0:	715d                	addi	sp,sp,-80
    800018b2:	e486                	sd	ra,72(sp)
    800018b4:	e0a2                	sd	s0,64(sp)
    800018b6:	fc26                	sd	s1,56(sp)
    800018b8:	f84a                	sd	s2,48(sp)
    800018ba:	f44e                	sd	s3,40(sp)
    800018bc:	f052                	sd	s4,32(sp)
    800018be:	ec56                	sd	s5,24(sp)
    800018c0:	e85a                	sd	s6,16(sp)
    800018c2:	e45e                	sd	s7,8(sp)
    800018c4:	e062                	sd	s8,0(sp)
    800018c6:	0880                	addi	s0,sp,80
    800018c8:	8b2a                	mv	s6,a0
    800018ca:	8a2e                	mv	s4,a1
    800018cc:	8c32                	mv	s8,a2
    800018ce:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018d0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018d2:	6a85                	lui	s5,0x1
    800018d4:	a01d                	j	800018fa <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018d6:	018505b3          	add	a1,a0,s8
    800018da:	0004861b          	sext.w	a2,s1
    800018de:	412585b3          	sub	a1,a1,s2
    800018e2:	8552                	mv	a0,s4
    800018e4:	fffff097          	auipc	ra,0xfffff
    800018e8:	53e080e7          	jalr	1342(ra) # 80000e22 <memmove>

    len -= n;
    800018ec:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018f0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018f2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018f6:	02098263          	beqz	s3,8000191a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800018fa:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018fe:	85ca                	mv	a1,s2
    80001900:	855a                	mv	a0,s6
    80001902:	00000097          	auipc	ra,0x0
    80001906:	84e080e7          	jalr	-1970(ra) # 80001150 <walkaddr>
    if(pa0 == 0)
    8000190a:	cd01                	beqz	a0,80001922 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000190c:	418904b3          	sub	s1,s2,s8
    80001910:	94d6                	add	s1,s1,s5
    80001912:	fc99f2e3          	bgeu	s3,s1,800018d6 <copyin+0x28>
    80001916:	84ce                	mv	s1,s3
    80001918:	bf7d                	j	800018d6 <copyin+0x28>
  }
  return 0;
    8000191a:	4501                	li	a0,0
    8000191c:	a021                	j	80001924 <copyin+0x76>
    8000191e:	4501                	li	a0,0
}
    80001920:	8082                	ret
      return -1;
    80001922:	557d                	li	a0,-1
}
    80001924:	60a6                	ld	ra,72(sp)
    80001926:	6406                	ld	s0,64(sp)
    80001928:	74e2                	ld	s1,56(sp)
    8000192a:	7942                	ld	s2,48(sp)
    8000192c:	79a2                	ld	s3,40(sp)
    8000192e:	7a02                	ld	s4,32(sp)
    80001930:	6ae2                	ld	s5,24(sp)
    80001932:	6b42                	ld	s6,16(sp)
    80001934:	6ba2                	ld	s7,8(sp)
    80001936:	6c02                	ld	s8,0(sp)
    80001938:	6161                	addi	sp,sp,80
    8000193a:	8082                	ret

000000008000193c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000193c:	c2dd                	beqz	a3,800019e2 <copyinstr+0xa6>
{
    8000193e:	715d                	addi	sp,sp,-80
    80001940:	e486                	sd	ra,72(sp)
    80001942:	e0a2                	sd	s0,64(sp)
    80001944:	fc26                	sd	s1,56(sp)
    80001946:	f84a                	sd	s2,48(sp)
    80001948:	f44e                	sd	s3,40(sp)
    8000194a:	f052                	sd	s4,32(sp)
    8000194c:	ec56                	sd	s5,24(sp)
    8000194e:	e85a                	sd	s6,16(sp)
    80001950:	e45e                	sd	s7,8(sp)
    80001952:	0880                	addi	s0,sp,80
    80001954:	8a2a                	mv	s4,a0
    80001956:	8b2e                	mv	s6,a1
    80001958:	8bb2                	mv	s7,a2
    8000195a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000195c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000195e:	6985                	lui	s3,0x1
    80001960:	a02d                	j	8000198a <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001962:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001966:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001968:	37fd                	addiw	a5,a5,-1
    8000196a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000196e:	60a6                	ld	ra,72(sp)
    80001970:	6406                	ld	s0,64(sp)
    80001972:	74e2                	ld	s1,56(sp)
    80001974:	7942                	ld	s2,48(sp)
    80001976:	79a2                	ld	s3,40(sp)
    80001978:	7a02                	ld	s4,32(sp)
    8000197a:	6ae2                	ld	s5,24(sp)
    8000197c:	6b42                	ld	s6,16(sp)
    8000197e:	6ba2                	ld	s7,8(sp)
    80001980:	6161                	addi	sp,sp,80
    80001982:	8082                	ret
    srcva = va0 + PGSIZE;
    80001984:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001988:	c8a9                	beqz	s1,800019da <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000198a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000198e:	85ca                	mv	a1,s2
    80001990:	8552                	mv	a0,s4
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	7be080e7          	jalr	1982(ra) # 80001150 <walkaddr>
    if(pa0 == 0)
    8000199a:	c131                	beqz	a0,800019de <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000199c:	417906b3          	sub	a3,s2,s7
    800019a0:	96ce                	add	a3,a3,s3
    800019a2:	00d4f363          	bgeu	s1,a3,800019a8 <copyinstr+0x6c>
    800019a6:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019a8:	955e                	add	a0,a0,s7
    800019aa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019ae:	daf9                	beqz	a3,80001984 <copyinstr+0x48>
    800019b0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019b2:	41650633          	sub	a2,a0,s6
    800019b6:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdbbbf7>
    800019ba:	95da                	add	a1,a1,s6
    while(n > 0){
    800019bc:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800019be:	00f60733          	add	a4,a2,a5
    800019c2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbbbf8>
    800019c6:	df51                	beqz	a4,80001962 <copyinstr+0x26>
        *dst = *p;
    800019c8:	00e78023          	sb	a4,0(a5)
      --max;
    800019cc:	40f584b3          	sub	s1,a1,a5
      dst++;
    800019d0:	0785                	addi	a5,a5,1
    while(n > 0){
    800019d2:	fed796e3          	bne	a5,a3,800019be <copyinstr+0x82>
      dst++;
    800019d6:	8b3e                	mv	s6,a5
    800019d8:	b775                	j	80001984 <copyinstr+0x48>
    800019da:	4781                	li	a5,0
    800019dc:	b771                	j	80001968 <copyinstr+0x2c>
      return -1;
    800019de:	557d                	li	a0,-1
    800019e0:	b779                	j	8000196e <copyinstr+0x32>
  int got_null = 0;
    800019e2:	4781                	li	a5,0
  if(got_null){
    800019e4:	37fd                	addiw	a5,a5,-1
    800019e6:	0007851b          	sext.w	a0,a5
}
    800019ea:	8082                	ret

00000000800019ec <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800019ec:	7139                	addi	sp,sp,-64
    800019ee:	fc06                	sd	ra,56(sp)
    800019f0:	f822                	sd	s0,48(sp)
    800019f2:	f426                	sd	s1,40(sp)
    800019f4:	f04a                	sd	s2,32(sp)
    800019f6:	ec4e                	sd	s3,24(sp)
    800019f8:	e852                	sd	s4,16(sp)
    800019fa:	e456                	sd	s5,8(sp)
    800019fc:	e05a                	sd	s6,0(sp)
    800019fe:	0080                	addi	s0,sp,64
    80001a00:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a02:	0022f497          	auipc	s1,0x22f
    80001a06:	62648493          	addi	s1,s1,1574 # 80231028 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a0a:	8b26                	mv	s6,s1
    80001a0c:	00006a97          	auipc	s5,0x6
    80001a10:	5f4a8a93          	addi	s5,s5,1524 # 80008000 <etext>
    80001a14:	04000937          	lui	s2,0x4000
    80001a18:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a1a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a1c:	00236a17          	auipc	s4,0x236
    80001a20:	60ca0a13          	addi	s4,s4,1548 # 80238028 <tickslock>
    char *pa = kalloc();
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	13e080e7          	jalr	318(ra) # 80000b62 <kalloc>
    80001a2c:	862a                	mv	a2,a0
    if (pa == 0)
    80001a2e:	c131                	beqz	a0,80001a72 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a30:	416485b3          	sub	a1,s1,s6
    80001a34:	8599                	srai	a1,a1,0x6
    80001a36:	000ab783          	ld	a5,0(s5)
    80001a3a:	02f585b3          	mul	a1,a1,a5
    80001a3e:	2585                	addiw	a1,a1,1
    80001a40:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a44:	4719                	li	a4,6
    80001a46:	6685                	lui	a3,0x1
    80001a48:	40b905b3          	sub	a1,s2,a1
    80001a4c:	854e                	mv	a0,s3
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	7e4080e7          	jalr	2020(ra) # 80001232 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a56:	1c048493          	addi	s1,s1,448
    80001a5a:	fd4495e3          	bne	s1,s4,80001a24 <proc_mapstacks+0x38>
  }
}
    80001a5e:	70e2                	ld	ra,56(sp)
    80001a60:	7442                	ld	s0,48(sp)
    80001a62:	74a2                	ld	s1,40(sp)
    80001a64:	7902                	ld	s2,32(sp)
    80001a66:	69e2                	ld	s3,24(sp)
    80001a68:	6a42                	ld	s4,16(sp)
    80001a6a:	6aa2                	ld	s5,8(sp)
    80001a6c:	6b02                	ld	s6,0(sp)
    80001a6e:	6121                	addi	sp,sp,64
    80001a70:	8082                	ret
      panic("kalloc");
    80001a72:	00006517          	auipc	a0,0x6
    80001a76:	79650513          	addi	a0,a0,1942 # 80008208 <digits+0x1c8>
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	ac6080e7          	jalr	-1338(ra) # 80000540 <panic>

0000000080001a82 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a82:	7139                	addi	sp,sp,-64
    80001a84:	fc06                	sd	ra,56(sp)
    80001a86:	f822                	sd	s0,48(sp)
    80001a88:	f426                	sd	s1,40(sp)
    80001a8a:	f04a                	sd	s2,32(sp)
    80001a8c:	ec4e                	sd	s3,24(sp)
    80001a8e:	e852                	sd	s4,16(sp)
    80001a90:	e456                	sd	s5,8(sp)
    80001a92:	e05a                	sd	s6,0(sp)
    80001a94:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a96:	00006597          	auipc	a1,0x6
    80001a9a:	77a58593          	addi	a1,a1,1914 # 80008210 <digits+0x1d0>
    80001a9e:	0022f517          	auipc	a0,0x22f
    80001aa2:	15a50513          	addi	a0,a0,346 # 80230bf8 <pid_lock>
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	194080e7          	jalr	404(ra) # 80000c3a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001aae:	00006597          	auipc	a1,0x6
    80001ab2:	76a58593          	addi	a1,a1,1898 # 80008218 <digits+0x1d8>
    80001ab6:	0022f517          	auipc	a0,0x22f
    80001aba:	15a50513          	addi	a0,a0,346 # 80230c10 <wait_lock>
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	17c080e7          	jalr	380(ra) # 80000c3a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ac6:	0022f497          	auipc	s1,0x22f
    80001aca:	56248493          	addi	s1,s1,1378 # 80231028 <proc>
  {
    initlock(&p->lock, "proc");
    80001ace:	00006b17          	auipc	s6,0x6
    80001ad2:	75ab0b13          	addi	s6,s6,1882 # 80008228 <digits+0x1e8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001ad6:	8aa6                	mv	s5,s1
    80001ad8:	00006a17          	auipc	s4,0x6
    80001adc:	528a0a13          	addi	s4,s4,1320 # 80008000 <etext>
    80001ae0:	04000937          	lui	s2,0x4000
    80001ae4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ae6:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ae8:	00236997          	auipc	s3,0x236
    80001aec:	54098993          	addi	s3,s3,1344 # 80238028 <tickslock>
    initlock(&p->lock, "proc");
    80001af0:	85da                	mv	a1,s6
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	146080e7          	jalr	326(ra) # 80000c3a <initlock>
    p->state = UNUSED;
    80001afc:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b00:	415487b3          	sub	a5,s1,s5
    80001b04:	8799                	srai	a5,a5,0x6
    80001b06:	000a3703          	ld	a4,0(s4)
    80001b0a:	02e787b3          	mul	a5,a5,a4
    80001b0e:	2785                	addiw	a5,a5,1
    80001b10:	00d7979b          	slliw	a5,a5,0xd
    80001b14:	40f907b3          	sub	a5,s2,a5
    80001b18:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b1a:	1c048493          	addi	s1,s1,448
    80001b1e:	fd3499e3          	bne	s1,s3,80001af0 <procinit+0x6e>
  }
}
    80001b22:	70e2                	ld	ra,56(sp)
    80001b24:	7442                	ld	s0,48(sp)
    80001b26:	74a2                	ld	s1,40(sp)
    80001b28:	7902                	ld	s2,32(sp)
    80001b2a:	69e2                	ld	s3,24(sp)
    80001b2c:	6a42                	ld	s4,16(sp)
    80001b2e:	6aa2                	ld	s5,8(sp)
    80001b30:	6b02                	ld	s6,0(sp)
    80001b32:	6121                	addi	sp,sp,64
    80001b34:	8082                	ret

0000000080001b36 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b36:	1141                	addi	sp,sp,-16
    80001b38:	e422                	sd	s0,8(sp)
    80001b3a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b3c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b3e:	2501                	sext.w	a0,a0
    80001b40:	6422                	ld	s0,8(sp)
    80001b42:	0141                	addi	sp,sp,16
    80001b44:	8082                	ret

0000000080001b46 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b46:	1141                	addi	sp,sp,-16
    80001b48:	e422                	sd	s0,8(sp)
    80001b4a:	0800                	addi	s0,sp,16
    80001b4c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b4e:	2781                	sext.w	a5,a5
    80001b50:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b52:	0022f517          	auipc	a0,0x22f
    80001b56:	0d650513          	addi	a0,a0,214 # 80230c28 <cpus>
    80001b5a:	953e                	add	a0,a0,a5
    80001b5c:	6422                	ld	s0,8(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret

0000000080001b62 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
  push_off();
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	112080e7          	jalr	274(ra) # 80000c7e <push_off>
    80001b74:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b76:	2781                	sext.w	a5,a5
    80001b78:	079e                	slli	a5,a5,0x7
    80001b7a:	0022f717          	auipc	a4,0x22f
    80001b7e:	07e70713          	addi	a4,a4,126 # 80230bf8 <pid_lock>
    80001b82:	97ba                	add	a5,a5,a4
    80001b84:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	198080e7          	jalr	408(ra) # 80000d1e <pop_off>
  return p;
}
    80001b8e:	8526                	mv	a0,s1
    80001b90:	60e2                	ld	ra,24(sp)
    80001b92:	6442                	ld	s0,16(sp)
    80001b94:	64a2                	ld	s1,8(sp)
    80001b96:	6105                	addi	sp,sp,32
    80001b98:	8082                	ret

0000000080001b9a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e406                	sd	ra,8(sp)
    80001b9e:	e022                	sd	s0,0(sp)
    80001ba0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	fc0080e7          	jalr	-64(ra) # 80001b62 <myproc>
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	1d4080e7          	jalr	468(ra) # 80000d7e <release>

  if (first)
    80001bb2:	00007797          	auipc	a5,0x7
    80001bb6:	d1e7a783          	lw	a5,-738(a5) # 800088d0 <first.1>
    80001bba:	eb89                	bnez	a5,80001bcc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bbc:	00001097          	auipc	ra,0x1
    80001bc0:	1ae080e7          	jalr	430(ra) # 80002d6a <usertrapret>
}
    80001bc4:	60a2                	ld	ra,8(sp)
    80001bc6:	6402                	ld	s0,0(sp)
    80001bc8:	0141                	addi	sp,sp,16
    80001bca:	8082                	ret
    first = 0;
    80001bcc:	00007797          	auipc	a5,0x7
    80001bd0:	d007a223          	sw	zero,-764(a5) # 800088d0 <first.1>
    fsinit(ROOTDEV);
    80001bd4:	4505                	li	a0,1
    80001bd6:	00002097          	auipc	ra,0x2
    80001bda:	202080e7          	jalr	514(ra) # 80003dd8 <fsinit>
    80001bde:	bff9                	j	80001bbc <forkret+0x22>

0000000080001be0 <allocpid>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	e04a                	sd	s2,0(sp)
    80001bea:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bec:	0022f917          	auipc	s2,0x22f
    80001bf0:	00c90913          	addi	s2,s2,12 # 80230bf8 <pid_lock>
    80001bf4:	854a                	mv	a0,s2
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	0d4080e7          	jalr	212(ra) # 80000cca <acquire>
  pid = nextpid;
    80001bfe:	00007797          	auipc	a5,0x7
    80001c02:	cd678793          	addi	a5,a5,-810 # 800088d4 <nextpid>
    80001c06:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c08:	0014871b          	addiw	a4,s1,1
    80001c0c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c0e:	854a                	mv	a0,s2
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	16e080e7          	jalr	366(ra) # 80000d7e <release>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret

0000000080001c26 <proc_pagetable>:
{
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	e04a                	sd	s2,0(sp)
    80001c30:	1000                	addi	s0,sp,32
    80001c32:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	7e8080e7          	jalr	2024(ra) # 8000141c <uvmcreate>
    80001c3c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c3e:	c121                	beqz	a0,80001c7e <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c40:	4729                	li	a4,10
    80001c42:	00005697          	auipc	a3,0x5
    80001c46:	3be68693          	addi	a3,a3,958 # 80007000 <_trampoline>
    80001c4a:	6605                	lui	a2,0x1
    80001c4c:	040005b7          	lui	a1,0x4000
    80001c50:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c52:	05b2                	slli	a1,a1,0xc
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	53e080e7          	jalr	1342(ra) # 80001192 <mappages>
    80001c5c:	02054863          	bltz	a0,80001c8c <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c60:	4719                	li	a4,6
    80001c62:	05893683          	ld	a3,88(s2)
    80001c66:	6605                	lui	a2,0x1
    80001c68:	020005b7          	lui	a1,0x2000
    80001c6c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c6e:	05b6                	slli	a1,a1,0xd
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	520080e7          	jalr	1312(ra) # 80001192 <mappages>
    80001c7a:	02054163          	bltz	a0,80001c9c <proc_pagetable+0x76>
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c8c:	4581                	li	a1,0
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	992080e7          	jalr	-1646(ra) # 80001622 <uvmfree>
    return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	b7d5                	j	80001c7e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c9c:	4681                	li	a3,0
    80001c9e:	4605                	li	a2,1
    80001ca0:	040005b7          	lui	a1,0x4000
    80001ca4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca6:	05b2                	slli	a1,a1,0xc
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	6ae080e7          	jalr	1710(ra) # 80001358 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cb2:	4581                	li	a1,0
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	96c080e7          	jalr	-1684(ra) # 80001622 <uvmfree>
    return 0;
    80001cbe:	4481                	li	s1,0
    80001cc0:	bf7d                	j	80001c7e <proc_pagetable+0x58>

0000000080001cc2 <proc_freepagetable>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	e04a                	sd	s2,0(sp)
    80001ccc:	1000                	addi	s0,sp,32
    80001cce:	84aa                	mv	s1,a0
    80001cd0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cd2:	4681                	li	a3,0
    80001cd4:	4605                	li	a2,1
    80001cd6:	040005b7          	lui	a1,0x4000
    80001cda:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cdc:	05b2                	slli	a1,a1,0xc
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	67a080e7          	jalr	1658(ra) # 80001358 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ce6:	4681                	li	a3,0
    80001ce8:	4605                	li	a2,1
    80001cea:	020005b7          	lui	a1,0x2000
    80001cee:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cf0:	05b6                	slli	a1,a1,0xd
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	664080e7          	jalr	1636(ra) # 80001358 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cfc:	85ca                	mv	a1,s2
    80001cfe:	8526                	mv	a0,s1
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	922080e7          	jalr	-1758(ra) # 80001622 <uvmfree>
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <freeproc>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	1000                	addi	s0,sp,32
    80001d1e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d20:	6d28                	ld	a0,88(a0)
    80001d22:	c509                	beqz	a0,80001d2c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	cc4080e7          	jalr	-828(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001d2c:	0404bc23          	sd	zero,88(s1)
  if (p->alarmtrpfrm)
    80001d30:	1884b503          	ld	a0,392(s1)
    80001d34:	c509                	beqz	a0,80001d3e <freeproc+0x2a>
    kfree(p->alarmtrpfrm);
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	cb2080e7          	jalr	-846(ra) # 800009e8 <kfree>
  p->alarmtrpfrm = 0;
    80001d3e:	1804b423          	sd	zero,392(s1)
  if (p->pagetable)
    80001d42:	68a8                	ld	a0,80(s1)
    80001d44:	c511                	beqz	a0,80001d50 <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80001d46:	64ac                	ld	a1,72(s1)
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	f7a080e7          	jalr	-134(ra) # 80001cc2 <proc_freepagetable>
  p->pagetable = 0;
    80001d50:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d54:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d58:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d5c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d60:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d64:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d68:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d6c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d70:	0004ac23          	sw	zero,24(s1)
}
    80001d74:	60e2                	ld	ra,24(sp)
    80001d76:	6442                	ld	s0,16(sp)
    80001d78:	64a2                	ld	s1,8(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret

0000000080001d7e <allocproc>:
{
    80001d7e:	1101                	addi	sp,sp,-32
    80001d80:	ec06                	sd	ra,24(sp)
    80001d82:	e822                	sd	s0,16(sp)
    80001d84:	e426                	sd	s1,8(sp)
    80001d86:	e04a                	sd	s2,0(sp)
    80001d88:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d8a:	0022f497          	auipc	s1,0x22f
    80001d8e:	29e48493          	addi	s1,s1,670 # 80231028 <proc>
    80001d92:	00236917          	auipc	s2,0x236
    80001d96:	29690913          	addi	s2,s2,662 # 80238028 <tickslock>
    acquire(&p->lock);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	f2e080e7          	jalr	-210(ra) # 80000cca <acquire>
    if (p->state == UNUSED)
    80001da4:	4c9c                	lw	a5,24(s1)
    80001da6:	cf81                	beqz	a5,80001dbe <allocproc+0x40>
      release(&p->lock);
    80001da8:	8526                	mv	a0,s1
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	fd4080e7          	jalr	-44(ra) # 80000d7e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001db2:	1c048493          	addi	s1,s1,448
    80001db6:	ff2492e3          	bne	s1,s2,80001d9a <allocproc+0x1c>
  return 0;
    80001dba:	4481                	li	s1,0
    80001dbc:	a075                	j	80001e68 <allocproc+0xea>
  p->pid = allocpid();
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	e22080e7          	jalr	-478(ra) # 80001be0 <allocpid>
    80001dc6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dc8:	4785                	li	a5,1
    80001dca:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	d96080e7          	jalr	-618(ra) # 80000b62 <kalloc>
    80001dd4:	892a                	mv	s2,a0
    80001dd6:	eca8                	sd	a0,88(s1)
    80001dd8:	cd59                	beqz	a0,80001e76 <allocproc+0xf8>
  p->pagetable = proc_pagetable(p);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	e4a080e7          	jalr	-438(ra) # 80001c26 <proc_pagetable>
    80001de4:	892a                	mv	s2,a0
    80001de6:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001de8:	c15d                	beqz	a0,80001e8e <allocproc+0x110>
  memset(&p->context, 0, sizeof(p->context));
    80001dea:	07000613          	li	a2,112
    80001dee:	4581                	li	a1,0
    80001df0:	06048513          	addi	a0,s1,96
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	fd2080e7          	jalr	-46(ra) # 80000dc6 <memset>
  p->context.ra = (uint64)forkret;
    80001dfc:	00000797          	auipc	a5,0x0
    80001e00:	d9e78793          	addi	a5,a5,-610 # 80001b9a <forkret>
    80001e04:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e06:	60bc                	ld	a5,64(s1)
    80001e08:	6705                	lui	a4,0x1
    80001e0a:	97ba                	add	a5,a5,a4
    80001e0c:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e0e:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e12:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e16:	00007797          	auipc	a5,0x7
    80001e1a:	b5a7a783          	lw	a5,-1190(a5) # 80008970 <ticks>
    80001e1e:	16f4a623          	sw	a5,364(s1)
  p->alarm_flag = 0;
    80001e22:	1804a823          	sw	zero,400(s1)
  if ((p->alarmtrpfrm = (struct trapframe *)kalloc()) == 0)
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	d3c080e7          	jalr	-708(ra) # 80000b62 <kalloc>
    80001e2e:	892a                	mv	s2,a0
    80001e30:	18a4b423          	sd	a0,392(s1)
    80001e34:	c92d                	beqz	a0,80001ea6 <allocproc+0x128>
  p->currticks = 0;
    80001e36:	1804a223          	sw	zero,388(s1)
  p->ticks = 0;
    80001e3a:	1804a023          	sw	zero,384(s1)
  p->waittime = 0;
    80001e3e:	1804aa23          	sw	zero,404(s1)
  p->inserttime = 0;
    80001e42:	1804ac23          	sw	zero,408(s1)
  p->priority = 0;
    80001e46:	1804ae23          	sw	zero,412(s1)
  p->statp = 50;
    80001e4a:	03200793          	li	a5,50
    80001e4e:	1af4a023          	sw	a5,416(s1)
  p->runtime = 0;
    80001e52:	1a04a423          	sw	zero,424(s1)
  p->wtime = 0;
    80001e56:	1a04a623          	sw	zero,428(s1)
  p->stime = 0;
    80001e5a:	1a04a823          	sw	zero,432(s1)
  p->rbi = 25;
    80001e5e:	47e5                	li	a5,25
    80001e60:	1af4aa23          	sw	a5,436(s1)
  p->sched_count = 0;
    80001e64:	1a04ac23          	sw	zero,440(s1)
}
    80001e68:	8526                	mv	a0,s1
    80001e6a:	60e2                	ld	ra,24(sp)
    80001e6c:	6442                	ld	s0,16(sp)
    80001e6e:	64a2                	ld	s1,8(sp)
    80001e70:	6902                	ld	s2,0(sp)
    80001e72:	6105                	addi	sp,sp,32
    80001e74:	8082                	ret
    freeproc(p);
    80001e76:	8526                	mv	a0,s1
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	e9c080e7          	jalr	-356(ra) # 80001d14 <freeproc>
    release(&p->lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	efc080e7          	jalr	-260(ra) # 80000d7e <release>
    return 0;
    80001e8a:	84ca                	mv	s1,s2
    80001e8c:	bff1                	j	80001e68 <allocproc+0xea>
    freeproc(p);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	00000097          	auipc	ra,0x0
    80001e94:	e84080e7          	jalr	-380(ra) # 80001d14 <freeproc>
    release(&p->lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	ee4080e7          	jalr	-284(ra) # 80000d7e <release>
    return 0;
    80001ea2:	84ca                	mv	s1,s2
    80001ea4:	b7d1                	j	80001e68 <allocproc+0xea>
    freeproc(p);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	e6c080e7          	jalr	-404(ra) # 80001d14 <freeproc>
    release(&p->lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	ecc080e7          	jalr	-308(ra) # 80000d7e <release>
    return 0;
    80001eba:	84ca                	mv	s1,s2
    80001ebc:	b775                	j	80001e68 <allocproc+0xea>

0000000080001ebe <userinit>:
{
    80001ebe:	1101                	addi	sp,sp,-32
    80001ec0:	ec06                	sd	ra,24(sp)
    80001ec2:	e822                	sd	s0,16(sp)
    80001ec4:	e426                	sd	s1,8(sp)
    80001ec6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	eb6080e7          	jalr	-330(ra) # 80001d7e <allocproc>
    80001ed0:	84aa                	mv	s1,a0
  initproc = p;
    80001ed2:	00007797          	auipc	a5,0x7
    80001ed6:	a8a7bb23          	sd	a0,-1386(a5) # 80008968 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eda:	03400613          	li	a2,52
    80001ede:	00007597          	auipc	a1,0x7
    80001ee2:	a0258593          	addi	a1,a1,-1534 # 800088e0 <initcode>
    80001ee6:	6928                	ld	a0,80(a0)
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	562080e7          	jalr	1378(ra) # 8000144a <uvmfirst>
  p->sz = PGSIZE;
    80001ef0:	6785                	lui	a5,0x1
    80001ef2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ef4:	6cb8                	ld	a4,88(s1)
    80001ef6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001efa:	6cb8                	ld	a4,88(s1)
    80001efc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001efe:	4641                	li	a2,16
    80001f00:	00006597          	auipc	a1,0x6
    80001f04:	33058593          	addi	a1,a1,816 # 80008230 <digits+0x1f0>
    80001f08:	15848513          	addi	a0,s1,344
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	004080e7          	jalr	4(ra) # 80000f10 <safestrcpy>
  p->cwd = namei("/");
    80001f14:	00006517          	auipc	a0,0x6
    80001f18:	32c50513          	addi	a0,a0,812 # 80008240 <digits+0x200>
    80001f1c:	00003097          	auipc	ra,0x3
    80001f20:	8e6080e7          	jalr	-1818(ra) # 80004802 <namei>
    80001f24:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f28:	478d                	li	a5,3
    80001f2a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	e50080e7          	jalr	-432(ra) # 80000d7e <release>
}
    80001f36:	60e2                	ld	ra,24(sp)
    80001f38:	6442                	ld	s0,16(sp)
    80001f3a:	64a2                	ld	s1,8(sp)
    80001f3c:	6105                	addi	sp,sp,32
    80001f3e:	8082                	ret

0000000080001f40 <growproc>:
{
    80001f40:	1101                	addi	sp,sp,-32
    80001f42:	ec06                	sd	ra,24(sp)
    80001f44:	e822                	sd	s0,16(sp)
    80001f46:	e426                	sd	s1,8(sp)
    80001f48:	e04a                	sd	s2,0(sp)
    80001f4a:	1000                	addi	s0,sp,32
    80001f4c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	c14080e7          	jalr	-1004(ra) # 80001b62 <myproc>
    80001f56:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f58:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f5a:	01204c63          	bgtz	s2,80001f72 <growproc+0x32>
  else if (n < 0)
    80001f5e:	02094663          	bltz	s2,80001f8a <growproc+0x4a>
  p->sz = sz;
    80001f62:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f64:	4501                	li	a0,0
}
    80001f66:	60e2                	ld	ra,24(sp)
    80001f68:	6442                	ld	s0,16(sp)
    80001f6a:	64a2                	ld	s1,8(sp)
    80001f6c:	6902                	ld	s2,0(sp)
    80001f6e:	6105                	addi	sp,sp,32
    80001f70:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f72:	4691                	li	a3,4
    80001f74:	00b90633          	add	a2,s2,a1
    80001f78:	6928                	ld	a0,80(a0)
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	58a080e7          	jalr	1418(ra) # 80001504 <uvmalloc>
    80001f82:	85aa                	mv	a1,a0
    80001f84:	fd79                	bnez	a0,80001f62 <growproc+0x22>
      return -1;
    80001f86:	557d                	li	a0,-1
    80001f88:	bff9                	j	80001f66 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f8a:	00b90633          	add	a2,s2,a1
    80001f8e:	6928                	ld	a0,80(a0)
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	52c080e7          	jalr	1324(ra) # 800014bc <uvmdealloc>
    80001f98:	85aa                	mv	a1,a0
    80001f9a:	b7e1                	j	80001f62 <growproc+0x22>

0000000080001f9c <fork>:
{
    80001f9c:	7139                	addi	sp,sp,-64
    80001f9e:	fc06                	sd	ra,56(sp)
    80001fa0:	f822                	sd	s0,48(sp)
    80001fa2:	f426                	sd	s1,40(sp)
    80001fa4:	f04a                	sd	s2,32(sp)
    80001fa6:	ec4e                	sd	s3,24(sp)
    80001fa8:	e852                	sd	s4,16(sp)
    80001faa:	e456                	sd	s5,8(sp)
    80001fac:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	bb4080e7          	jalr	-1100(ra) # 80001b62 <myproc>
    80001fb6:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	dc6080e7          	jalr	-570(ra) # 80001d7e <allocproc>
    80001fc0:	10050c63          	beqz	a0,800020d8 <fork+0x13c>
    80001fc4:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fc6:	048ab603          	ld	a2,72(s5)
    80001fca:	692c                	ld	a1,80(a0)
    80001fcc:	050ab503          	ld	a0,80(s5)
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	68c080e7          	jalr	1676(ra) # 8000165c <uvmcopy>
    80001fd8:	04054863          	bltz	a0,80002028 <fork+0x8c>
  np->sz = p->sz;
    80001fdc:	048ab783          	ld	a5,72(s5)
    80001fe0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001fe4:	058ab683          	ld	a3,88(s5)
    80001fe8:	87b6                	mv	a5,a3
    80001fea:	058a3703          	ld	a4,88(s4)
    80001fee:	12068693          	addi	a3,a3,288
    80001ff2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ff6:	6788                	ld	a0,8(a5)
    80001ff8:	6b8c                	ld	a1,16(a5)
    80001ffa:	6f90                	ld	a2,24(a5)
    80001ffc:	01073023          	sd	a6,0(a4)
    80002000:	e708                	sd	a0,8(a4)
    80002002:	eb0c                	sd	a1,16(a4)
    80002004:	ef10                	sd	a2,24(a4)
    80002006:	02078793          	addi	a5,a5,32
    8000200a:	02070713          	addi	a4,a4,32
    8000200e:	fed792e3          	bne	a5,a3,80001ff2 <fork+0x56>
  np->trapframe->a0 = 0;
    80002012:	058a3783          	ld	a5,88(s4)
    80002016:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    8000201a:	0d0a8493          	addi	s1,s5,208
    8000201e:	0d0a0913          	addi	s2,s4,208
    80002022:	150a8993          	addi	s3,s5,336
    80002026:	a00d                	j	80002048 <fork+0xac>
    freeproc(np);
    80002028:	8552                	mv	a0,s4
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	cea080e7          	jalr	-790(ra) # 80001d14 <freeproc>
    release(&np->lock);
    80002032:	8552                	mv	a0,s4
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	d4a080e7          	jalr	-694(ra) # 80000d7e <release>
    return -1;
    8000203c:	597d                	li	s2,-1
    8000203e:	a059                	j	800020c4 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80002040:	04a1                	addi	s1,s1,8
    80002042:	0921                	addi	s2,s2,8
    80002044:	01348b63          	beq	s1,s3,8000205a <fork+0xbe>
    if (p->ofile[i])
    80002048:	6088                	ld	a0,0(s1)
    8000204a:	d97d                	beqz	a0,80002040 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000204c:	00003097          	auipc	ra,0x3
    80002050:	e4c080e7          	jalr	-436(ra) # 80004e98 <filedup>
    80002054:	00a93023          	sd	a0,0(s2)
    80002058:	b7e5                	j	80002040 <fork+0xa4>
  np->cwd = idup(p->cwd);
    8000205a:	150ab503          	ld	a0,336(s5)
    8000205e:	00002097          	auipc	ra,0x2
    80002062:	fba080e7          	jalr	-70(ra) # 80004018 <idup>
    80002066:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000206a:	4641                	li	a2,16
    8000206c:	158a8593          	addi	a1,s5,344
    80002070:	158a0513          	addi	a0,s4,344
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	e9c080e7          	jalr	-356(ra) # 80000f10 <safestrcpy>
  pid = np->pid;
    8000207c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002080:	8552                	mv	a0,s4
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	cfc080e7          	jalr	-772(ra) # 80000d7e <release>
  acquire(&wait_lock);
    8000208a:	0022f497          	auipc	s1,0x22f
    8000208e:	b8648493          	addi	s1,s1,-1146 # 80230c10 <wait_lock>
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	c36080e7          	jalr	-970(ra) # 80000cca <acquire>
  np->parent = p;
    8000209c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	cdc080e7          	jalr	-804(ra) # 80000d7e <release>
  acquire(&np->lock);
    800020aa:	8552                	mv	a0,s4
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	c1e080e7          	jalr	-994(ra) # 80000cca <acquire>
  np->state = RUNNABLE;
    800020b4:	478d                	li	a5,3
    800020b6:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020ba:	8552                	mv	a0,s4
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	cc2080e7          	jalr	-830(ra) # 80000d7e <release>
}
    800020c4:	854a                	mv	a0,s2
    800020c6:	70e2                	ld	ra,56(sp)
    800020c8:	7442                	ld	s0,48(sp)
    800020ca:	74a2                	ld	s1,40(sp)
    800020cc:	7902                	ld	s2,32(sp)
    800020ce:	69e2                	ld	s3,24(sp)
    800020d0:	6a42                	ld	s4,16(sp)
    800020d2:	6aa2                	ld	s5,8(sp)
    800020d4:	6121                	addi	sp,sp,64
    800020d6:	8082                	ret
    return -1;
    800020d8:	597d                	li	s2,-1
    800020da:	b7ed                	j	800020c4 <fork+0x128>

00000000800020dc <scheduler>:
{
    800020dc:	7159                	addi	sp,sp,-112
    800020de:	f486                	sd	ra,104(sp)
    800020e0:	f0a2                	sd	s0,96(sp)
    800020e2:	eca6                	sd	s1,88(sp)
    800020e4:	e8ca                	sd	s2,80(sp)
    800020e6:	e4ce                	sd	s3,72(sp)
    800020e8:	e0d2                	sd	s4,64(sp)
    800020ea:	fc56                	sd	s5,56(sp)
    800020ec:	f85a                	sd	s6,48(sp)
    800020ee:	f45e                	sd	s7,40(sp)
    800020f0:	f062                	sd	s8,32(sp)
    800020f2:	ec66                	sd	s9,24(sp)
    800020f4:	e86a                	sd	s10,16(sp)
    800020f6:	e46e                	sd	s11,8(sp)
    800020f8:	1880                	addi	s0,sp,112
    800020fa:	8792                	mv	a5,tp
  int id = r_tp();
    800020fc:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020fe:	00779d93          	slli	s11,a5,0x7
    80002102:	0022f717          	auipc	a4,0x22f
    80002106:	af670713          	addi	a4,a4,-1290 # 80230bf8 <pid_lock>
    8000210a:	976e                	add	a4,a4,s11
    8000210c:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &minproc->context);
    80002110:	0022f717          	auipc	a4,0x22f
    80002114:	b2070713          	addi	a4,a4,-1248 # 80230c30 <cpus+0x8>
    80002118:	9dba                	add	s11,s11,a4
      if (p->state == RUNNABLE)
    8000211a:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000211c:	00236a17          	auipc	s4,0x236
    80002120:	f0ca0a13          	addi	s4,s4,-244 # 80238028 <tickslock>
        num = (3*minproc->runtime - minproc->stime - minproc->wtime)*50;
    80002124:	03200c13          	li	s8,50
      c->proc = minproc;
    80002128:	079e                	slli	a5,a5,0x7
    8000212a:	0022fd17          	auipc	s10,0x22f
    8000212e:	aced0d13          	addi	s10,s10,-1330 # 80230bf8 <pid_lock>
    80002132:	9d3e                	add	s10,s10,a5
    80002134:	aa1d                	j	8000226a <scheduler+0x18e>
        minctime = minproc->ctime;
    80002136:	16c4ab83          	lw	s7,364(s1)
        num = (3*minproc->runtime - minproc->stime - minproc->wtime)*50;
    8000213a:	1a84a783          	lw	a5,424(s1)
    8000213e:	1b04a683          	lw	a3,432(s1)
    80002142:	1ac4a703          	lw	a4,428(s1)
    80002146:	00179a9b          	slliw	s5,a5,0x1
    8000214a:	00fa8abb          	addw	s5,s5,a5
    8000214e:	40da8abb          	subw	s5,s5,a3
    80002152:	40ea8abb          	subw	s5,s5,a4
    80002156:	038a8abb          	mulw	s5,s5,s8
        den = minproc->runtime + minproc->stime + minproc->wtime + 1;
    8000215a:	9fb5                	addw	a5,a5,a3
    8000215c:	2785                	addiw	a5,a5,1
    8000215e:	9fb9                	addw	a5,a5,a4
        rbi = num/den;
    80002160:	02fadabb          	divuw	s5,s5,a5
        minproc->rbi = max(rbi, 0);
    80002164:	1b54aa23          	sw	s5,436(s1)
        mindp = min(minproc->rbi + minproc->statp, 100);
    80002168:	1a04a783          	lw	a5,416(s1)
    8000216c:	00fa8abb          	addw	s5,s5,a5
    80002170:	000a871b          	sext.w	a4,s5
    80002174:	06400793          	li	a5,100
    80002178:	00e7f463          	bgeu	a5,a4,80002180 <scheduler+0xa4>
    8000217c:	06400a93          	li	s5,100
    80002180:	2a81                	sext.w	s5,s5
        release(&p->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	bfa080e7          	jalr	-1030(ra) # 80000d7e <release>
    struct proc* minproc = &proc[0];
    8000218c:	0022f917          	auipc	s2,0x22f
    80002190:	e9c90913          	addi	s2,s2,-356 # 80231028 <proc>
        dp = min(p->rbi + p->statp, 100);
    80002194:	06400b13          	li	s6,100
    80002198:	06400c93          	li	s9,100
    8000219c:	a831                	j	800021b8 <scheduler+0xdc>
          minctime = p->ctime;
    8000219e:	16c92b83          	lw	s7,364(s2)
          mindp = dp;
    800021a2:	8abe                	mv	s5,a5
          minctime = p->ctime;
    800021a4:	84ca                	mv	s1,s2
      release(&p->lock);
    800021a6:	854a                	mv	a0,s2
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	bd6080e7          	jalr	-1066(ra) # 80000d7e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800021b0:	1c090913          	addi	s2,s2,448
    800021b4:	07490963          	beq	s2,s4,80002226 <scheduler+0x14a>
      acquire(&p->lock);
    800021b8:	854a                	mv	a0,s2
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	b10080e7          	jalr	-1264(ra) # 80000cca <acquire>
      if (p->state == RUNNABLE)
    800021c2:	01892783          	lw	a5,24(s2)
    800021c6:	ff3790e3          	bne	a5,s3,800021a6 <scheduler+0xca>
        num = ((3*p->runtime) - p->stime - p->wtime)*50;
    800021ca:	1a892703          	lw	a4,424(s2)
    800021ce:	1b092603          	lw	a2,432(s2)
    800021d2:	1ac92683          	lw	a3,428(s2)
    800021d6:	0017179b          	slliw	a5,a4,0x1
    800021da:	9fb9                	addw	a5,a5,a4
    800021dc:	9f91                	subw	a5,a5,a2
    800021de:	9f95                	subw	a5,a5,a3
    800021e0:	038787bb          	mulw	a5,a5,s8
        den = p->runtime + p->stime + p->wtime + 1;
    800021e4:	9f31                	addw	a4,a4,a2
    800021e6:	2705                	addiw	a4,a4,1
    800021e8:	9f35                	addw	a4,a4,a3
        rbi = num/den;
    800021ea:	02e7d7bb          	divuw	a5,a5,a4
        p->rbi = max(rbi, 0);
    800021ee:	1af92a23          	sw	a5,436(s2)
        dp = min(p->rbi + p->statp, 100);
    800021f2:	1a092703          	lw	a4,416(s2)
    800021f6:	9fb9                	addw	a5,a5,a4
    800021f8:	0007871b          	sext.w	a4,a5
    800021fc:	00eb7363          	bgeu	s6,a4,80002202 <scheduler+0x126>
    80002200:	87e6                	mv	a5,s9
    80002202:	2781                	sext.w	a5,a5
        if(dp < mindp || ((dp == mindp) && (p->sched_count < minproc->sched_count)) || (dp == mindp && (p->sched_count == minproc->sched_count) && p->ctime < minctime))
    80002204:	f957ede3          	bltu	a5,s5,8000219e <scheduler+0xc2>
    80002208:	f9579fe3          	bne	a5,s5,800021a6 <scheduler+0xca>
    8000220c:	1b892683          	lw	a3,440(s2)
    80002210:	1b84a703          	lw	a4,440(s1)
    80002214:	f8e6e5e3          	bltu	a3,a4,8000219e <scheduler+0xc2>
    80002218:	f8e697e3          	bne	a3,a4,800021a6 <scheduler+0xca>
    8000221c:	16c92703          	lw	a4,364(s2)
    80002220:	f97773e3          	bgeu	a4,s7,800021a6 <scheduler+0xca>
    80002224:	bfad                	j	8000219e <scheduler+0xc2>
    acquire(&minproc->lock);
    80002226:	8926                	mv	s2,s1
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	aa0080e7          	jalr	-1376(ra) # 80000cca <acquire>
    if (minproc->state == RUNNABLE)
    80002232:	4c9c                	lw	a5,24(s1)
    80002234:	03379663          	bne	a5,s3,80002260 <scheduler+0x184>
      minproc->state = RUNNING;
    80002238:	4791                	li	a5,4
    8000223a:	cc9c                	sw	a5,24(s1)
      c->proc = minproc;
    8000223c:	029d3823          	sd	s1,48(s10)
      minproc->sched_count++;
    80002240:	1b84a783          	lw	a5,440(s1)
    80002244:	2785                	addiw	a5,a5,1
    80002246:	1af4ac23          	sw	a5,440(s1)
      minproc->runtime = 0;
    8000224a:	1a04a423          	sw	zero,424(s1)
      swtch(&c->context, &minproc->context);
    8000224e:	06048593          	addi	a1,s1,96
    80002252:	856e                	mv	a0,s11
    80002254:	00001097          	auipc	ra,0x1
    80002258:	a6c080e7          	jalr	-1428(ra) # 80002cc0 <swtch>
      c->proc = 0;
    8000225c:	020d3823          	sd	zero,48(s10)
    release(&minproc->lock);
    80002260:	854a                	mv	a0,s2
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	b1c080e7          	jalr	-1252(ra) # 80000d7e <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000226a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000226e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002272:	10079073          	csrw	sstatus,a5
    uint minctime = minproc->ctime;
    80002276:	0022f497          	auipc	s1,0x22f
    8000227a:	db248493          	addi	s1,s1,-590 # 80231028 <proc>
    8000227e:	16c4ab83          	lw	s7,364(s1)
      acquire(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a46080e7          	jalr	-1466(ra) # 80000cca <acquire>
      if (p->state == RUNNABLE)
    8000228c:	4c9c                	lw	a5,24(s1)
    8000228e:	eb3784e3          	beq	a5,s3,80002136 <scheduler+0x5a>
      release(&p->lock);
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	aea080e7          	jalr	-1302(ra) # 80000d7e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000229c:	1c048493          	addi	s1,s1,448
    800022a0:	ff4491e3          	bne	s1,s4,80002282 <scheduler+0x1a6>
    uint mindp = 200; //doesnt matter im reinitializing later
    800022a4:	0c800a93          	li	s5,200
    struct proc* minproc = &proc[0];
    800022a8:	0022f497          	auipc	s1,0x22f
    800022ac:	d8048493          	addi	s1,s1,-640 # 80231028 <proc>
    800022b0:	bdf1                	j	8000218c <scheduler+0xb0>

00000000800022b2 <sched>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022c0:	00000097          	auipc	ra,0x0
    800022c4:	8a2080e7          	jalr	-1886(ra) # 80001b62 <myproc>
    800022c8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	986080e7          	jalr	-1658(ra) # 80000c50 <holding>
    800022d2:	c93d                	beqz	a0,80002348 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022d6:	2781                	sext.w	a5,a5
    800022d8:	079e                	slli	a5,a5,0x7
    800022da:	0022f717          	auipc	a4,0x22f
    800022de:	91e70713          	addi	a4,a4,-1762 # 80230bf8 <pid_lock>
    800022e2:	97ba                	add	a5,a5,a4
    800022e4:	0a87a703          	lw	a4,168(a5)
    800022e8:	4785                	li	a5,1
    800022ea:	06f71763          	bne	a4,a5,80002358 <sched+0xa6>
  if (p->state == RUNNING)
    800022ee:	4c98                	lw	a4,24(s1)
    800022f0:	4791                	li	a5,4
    800022f2:	06f70b63          	beq	a4,a5,80002368 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022fa:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022fc:	efb5                	bnez	a5,80002378 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022fe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002300:	0022f917          	auipc	s2,0x22f
    80002304:	8f890913          	addi	s2,s2,-1800 # 80230bf8 <pid_lock>
    80002308:	2781                	sext.w	a5,a5
    8000230a:	079e                	slli	a5,a5,0x7
    8000230c:	97ca                	add	a5,a5,s2
    8000230e:	0ac7a983          	lw	s3,172(a5)
    80002312:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002314:	2781                	sext.w	a5,a5
    80002316:	079e                	slli	a5,a5,0x7
    80002318:	0022f597          	auipc	a1,0x22f
    8000231c:	91858593          	addi	a1,a1,-1768 # 80230c30 <cpus+0x8>
    80002320:	95be                	add	a1,a1,a5
    80002322:	06048513          	addi	a0,s1,96
    80002326:	00001097          	auipc	ra,0x1
    8000232a:	99a080e7          	jalr	-1638(ra) # 80002cc0 <swtch>
    8000232e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002330:	2781                	sext.w	a5,a5
    80002332:	079e                	slli	a5,a5,0x7
    80002334:	993e                	add	s2,s2,a5
    80002336:	0b392623          	sw	s3,172(s2)
}
    8000233a:	70a2                	ld	ra,40(sp)
    8000233c:	7402                	ld	s0,32(sp)
    8000233e:	64e2                	ld	s1,24(sp)
    80002340:	6942                	ld	s2,16(sp)
    80002342:	69a2                	ld	s3,8(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret
    panic("sched p->lock");
    80002348:	00006517          	auipc	a0,0x6
    8000234c:	f0050513          	addi	a0,a0,-256 # 80008248 <digits+0x208>
    80002350:	ffffe097          	auipc	ra,0xffffe
    80002354:	1f0080e7          	jalr	496(ra) # 80000540 <panic>
    panic("sched locks");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	f0050513          	addi	a0,a0,-256 # 80008258 <digits+0x218>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1e0080e7          	jalr	480(ra) # 80000540 <panic>
    panic("sched running");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	f0050513          	addi	a0,a0,-256 # 80008268 <digits+0x228>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1d0080e7          	jalr	464(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	f0050513          	addi	a0,a0,-256 # 80008278 <digits+0x238>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1c0080e7          	jalr	448(ra) # 80000540 <panic>

0000000080002388 <yield>:
{
    80002388:	1101                	addi	sp,sp,-32
    8000238a:	ec06                	sd	ra,24(sp)
    8000238c:	e822                	sd	s0,16(sp)
    8000238e:	e426                	sd	s1,8(sp)
    80002390:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	7d0080e7          	jalr	2000(ra) # 80001b62 <myproc>
    8000239a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	92e080e7          	jalr	-1746(ra) # 80000cca <acquire>
  p->state = RUNNABLE;
    800023a4:	478d                	li	a5,3
    800023a6:	cc9c                	sw	a5,24(s1)
  sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	f0a080e7          	jalr	-246(ra) # 800022b2 <sched>
  release(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	9cc080e7          	jalr	-1588(ra) # 80000d7e <release>
}
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6105                	addi	sp,sp,32
    800023c2:	8082                	ret

00000000800023c4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023c4:	7179                	addi	sp,sp,-48
    800023c6:	f406                	sd	ra,40(sp)
    800023c8:	f022                	sd	s0,32(sp)
    800023ca:	ec26                	sd	s1,24(sp)
    800023cc:	e84a                	sd	s2,16(sp)
    800023ce:	e44e                	sd	s3,8(sp)
    800023d0:	1800                	addi	s0,sp,48
    800023d2:	89aa                	mv	s3,a0
    800023d4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	78c080e7          	jalr	1932(ra) # 80001b62 <myproc>
    800023de:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8ea080e7          	jalr	-1814(ra) # 80000cca <acquire>
  release(lk);
    800023e8:	854a                	mv	a0,s2
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	994080e7          	jalr	-1644(ra) # 80000d7e <release>

  // Go to sleep.
  p->chan = chan;
    800023f2:	0334b023          	sd	s3,32(s1)
  p->sleeptick = ticks;
    800023f6:	00006797          	auipc	a5,0x6
    800023fa:	57a7a783          	lw	a5,1402(a5) # 80008970 <ticks>
    800023fe:	1af4a223          	sw	a5,420(s1)
  p->state = SLEEPING;
    80002402:	4789                	li	a5,2
    80002404:	cc9c                	sw	a5,24(s1)

  sched();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	eac080e7          	jalr	-340(ra) # 800022b2 <sched>

  // Tidy up.
  p->chan = 0;
    8000240e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	96a080e7          	jalr	-1686(ra) # 80000d7e <release>
  acquire(lk);
    8000241c:	854a                	mv	a0,s2
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	8ac080e7          	jalr	-1876(ra) # 80000cca <acquire>
}
    80002426:	70a2                	ld	ra,40(sp)
    80002428:	7402                	ld	s0,32(sp)
    8000242a:	64e2                	ld	s1,24(sp)
    8000242c:	6942                	ld	s2,16(sp)
    8000242e:	69a2                	ld	s3,8(sp)
    80002430:	6145                	addi	sp,sp,48
    80002432:	8082                	ret

0000000080002434 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002434:	7139                	addi	sp,sp,-64
    80002436:	fc06                	sd	ra,56(sp)
    80002438:	f822                	sd	s0,48(sp)
    8000243a:	f426                	sd	s1,40(sp)
    8000243c:	f04a                	sd	s2,32(sp)
    8000243e:	ec4e                	sd	s3,24(sp)
    80002440:	e852                	sd	s4,16(sp)
    80002442:	e456                	sd	s5,8(sp)
    80002444:	0080                	addi	s0,sp,64
    80002446:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002448:	0022f497          	auipc	s1,0x22f
    8000244c:	be048493          	addi	s1,s1,-1056 # 80231028 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002450:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002452:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002454:	00236917          	auipc	s2,0x236
    80002458:	bd490913          	addi	s2,s2,-1068 # 80238028 <tickslock>
    8000245c:	a811                	j	80002470 <wakeup+0x3c>
      }
      release(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	91e080e7          	jalr	-1762(ra) # 80000d7e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002468:	1c048493          	addi	s1,s1,448
    8000246c:	03248663          	beq	s1,s2,80002498 <wakeup+0x64>
    if (p != myproc())
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	6f2080e7          	jalr	1778(ra) # 80001b62 <myproc>
    80002478:	fea488e3          	beq	s1,a0,80002468 <wakeup+0x34>
      acquire(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	84c080e7          	jalr	-1972(ra) # 80000cca <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002486:	4c9c                	lw	a5,24(s1)
    80002488:	fd379be3          	bne	a5,s3,8000245e <wakeup+0x2a>
    8000248c:	709c                	ld	a5,32(s1)
    8000248e:	fd4798e3          	bne	a5,s4,8000245e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002492:	0154ac23          	sw	s5,24(s1)
    80002496:	b7e1                	j	8000245e <wakeup+0x2a>
    }
  }
}
    80002498:	70e2                	ld	ra,56(sp)
    8000249a:	7442                	ld	s0,48(sp)
    8000249c:	74a2                	ld	s1,40(sp)
    8000249e:	7902                	ld	s2,32(sp)
    800024a0:	69e2                	ld	s3,24(sp)
    800024a2:	6a42                	ld	s4,16(sp)
    800024a4:	6aa2                	ld	s5,8(sp)
    800024a6:	6121                	addi	sp,sp,64
    800024a8:	8082                	ret

00000000800024aa <reparent>:
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024bc:	0022f497          	auipc	s1,0x22f
    800024c0:	b6c48493          	addi	s1,s1,-1172 # 80231028 <proc>
      pp->parent = initproc;
    800024c4:	00006a17          	auipc	s4,0x6
    800024c8:	4a4a0a13          	addi	s4,s4,1188 # 80008968 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024cc:	00236997          	auipc	s3,0x236
    800024d0:	b5c98993          	addi	s3,s3,-1188 # 80238028 <tickslock>
    800024d4:	a029                	j	800024de <reparent+0x34>
    800024d6:	1c048493          	addi	s1,s1,448
    800024da:	01348d63          	beq	s1,s3,800024f4 <reparent+0x4a>
    if (pp->parent == p)
    800024de:	7c9c                	ld	a5,56(s1)
    800024e0:	ff279be3          	bne	a5,s2,800024d6 <reparent+0x2c>
      pp->parent = initproc;
    800024e4:	000a3503          	ld	a0,0(s4)
    800024e8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	f4a080e7          	jalr	-182(ra) # 80002434 <wakeup>
    800024f2:	b7d5                	j	800024d6 <reparent+0x2c>
}
    800024f4:	70a2                	ld	ra,40(sp)
    800024f6:	7402                	ld	s0,32(sp)
    800024f8:	64e2                	ld	s1,24(sp)
    800024fa:	6942                	ld	s2,16(sp)
    800024fc:	69a2                	ld	s3,8(sp)
    800024fe:	6a02                	ld	s4,0(sp)
    80002500:	6145                	addi	sp,sp,48
    80002502:	8082                	ret

0000000080002504 <exit>:
{
    80002504:	7179                	addi	sp,sp,-48
    80002506:	f406                	sd	ra,40(sp)
    80002508:	f022                	sd	s0,32(sp)
    8000250a:	ec26                	sd	s1,24(sp)
    8000250c:	e84a                	sd	s2,16(sp)
    8000250e:	e44e                	sd	s3,8(sp)
    80002510:	e052                	sd	s4,0(sp)
    80002512:	1800                	addi	s0,sp,48
    80002514:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	64c080e7          	jalr	1612(ra) # 80001b62 <myproc>
    8000251e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002520:	00006797          	auipc	a5,0x6
    80002524:	4487b783          	ld	a5,1096(a5) # 80008968 <initproc>
    80002528:	0d050493          	addi	s1,a0,208
    8000252c:	15050913          	addi	s2,a0,336
    80002530:	02a79363          	bne	a5,a0,80002556 <exit+0x52>
    panic("init exiting");
    80002534:	00006517          	auipc	a0,0x6
    80002538:	d5c50513          	addi	a0,a0,-676 # 80008290 <digits+0x250>
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	004080e7          	jalr	4(ra) # 80000540 <panic>
      fileclose(f);
    80002544:	00003097          	auipc	ra,0x3
    80002548:	9a6080e7          	jalr	-1626(ra) # 80004eea <fileclose>
      p->ofile[fd] = 0;
    8000254c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002550:	04a1                	addi	s1,s1,8
    80002552:	01248563          	beq	s1,s2,8000255c <exit+0x58>
    if (p->ofile[fd])
    80002556:	6088                	ld	a0,0(s1)
    80002558:	f575                	bnez	a0,80002544 <exit+0x40>
    8000255a:	bfdd                	j	80002550 <exit+0x4c>
  begin_op();
    8000255c:	00002097          	auipc	ra,0x2
    80002560:	4c6080e7          	jalr	1222(ra) # 80004a22 <begin_op>
  iput(p->cwd);
    80002564:	1509b503          	ld	a0,336(s3)
    80002568:	00002097          	auipc	ra,0x2
    8000256c:	ca8080e7          	jalr	-856(ra) # 80004210 <iput>
  end_op();
    80002570:	00002097          	auipc	ra,0x2
    80002574:	530080e7          	jalr	1328(ra) # 80004aa0 <end_op>
  p->cwd = 0;
    80002578:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000257c:	0022e497          	auipc	s1,0x22e
    80002580:	69448493          	addi	s1,s1,1684 # 80230c10 <wait_lock>
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	744080e7          	jalr	1860(ra) # 80000cca <acquire>
  reparent(p);
    8000258e:	854e                	mv	a0,s3
    80002590:	00000097          	auipc	ra,0x0
    80002594:	f1a080e7          	jalr	-230(ra) # 800024aa <reparent>
  wakeup(p->parent);
    80002598:	0389b503          	ld	a0,56(s3)
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	e98080e7          	jalr	-360(ra) # 80002434 <wakeup>
  acquire(&p->lock);
    800025a4:	854e                	mv	a0,s3
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	724080e7          	jalr	1828(ra) # 80000cca <acquire>
  p->xstate = status;
    800025ae:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025b2:	4795                	li	a5,5
    800025b4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800025b8:	00006797          	auipc	a5,0x6
    800025bc:	3b87a783          	lw	a5,952(a5) # 80008970 <ticks>
    800025c0:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	7b8080e7          	jalr	1976(ra) # 80000d7e <release>
  sched();
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	ce4080e7          	jalr	-796(ra) # 800022b2 <sched>
  panic("zombie exit");
    800025d6:	00006517          	auipc	a0,0x6
    800025da:	cca50513          	addi	a0,a0,-822 # 800082a0 <digits+0x260>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	f62080e7          	jalr	-158(ra) # 80000540 <panic>

00000000800025e6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025e6:	7179                	addi	sp,sp,-48
    800025e8:	f406                	sd	ra,40(sp)
    800025ea:	f022                	sd	s0,32(sp)
    800025ec:	ec26                	sd	s1,24(sp)
    800025ee:	e84a                	sd	s2,16(sp)
    800025f0:	e44e                	sd	s3,8(sp)
    800025f2:	1800                	addi	s0,sp,48
    800025f4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025f6:	0022f497          	auipc	s1,0x22f
    800025fa:	a3248493          	addi	s1,s1,-1486 # 80231028 <proc>
    800025fe:	00236997          	auipc	s3,0x236
    80002602:	a2a98993          	addi	s3,s3,-1494 # 80238028 <tickslock>
  {
    acquire(&p->lock);
    80002606:	8526                	mv	a0,s1
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	6c2080e7          	jalr	1730(ra) # 80000cca <acquire>
    if (p->pid == pid)
    80002610:	589c                	lw	a5,48(s1)
    80002612:	01278d63          	beq	a5,s2,8000262c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	766080e7          	jalr	1894(ra) # 80000d7e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002620:	1c048493          	addi	s1,s1,448
    80002624:	ff3491e3          	bne	s1,s3,80002606 <kill+0x20>
  }
  return -1;
    80002628:	557d                	li	a0,-1
    8000262a:	a829                	j	80002644 <kill+0x5e>
      p->killed = 1;
    8000262c:	4785                	li	a5,1
    8000262e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002630:	4c98                	lw	a4,24(s1)
    80002632:	4789                	li	a5,2
    80002634:	00f70f63          	beq	a4,a5,80002652 <kill+0x6c>
      release(&p->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	744080e7          	jalr	1860(ra) # 80000d7e <release>
      return 0;
    80002642:	4501                	li	a0,0
}
    80002644:	70a2                	ld	ra,40(sp)
    80002646:	7402                	ld	s0,32(sp)
    80002648:	64e2                	ld	s1,24(sp)
    8000264a:	6942                	ld	s2,16(sp)
    8000264c:	69a2                	ld	s3,8(sp)
    8000264e:	6145                	addi	sp,sp,48
    80002650:	8082                	ret
        p->state = RUNNABLE;
    80002652:	478d                	li	a5,3
    80002654:	cc9c                	sw	a5,24(s1)
    80002656:	b7cd                	j	80002638 <kill+0x52>

0000000080002658 <setkilled>:

void setkilled(struct proc *p)
{
    80002658:	1101                	addi	sp,sp,-32
    8000265a:	ec06                	sd	ra,24(sp)
    8000265c:	e822                	sd	s0,16(sp)
    8000265e:	e426                	sd	s1,8(sp)
    80002660:	1000                	addi	s0,sp,32
    80002662:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	666080e7          	jalr	1638(ra) # 80000cca <acquire>
  p->killed = 1;
    8000266c:	4785                	li	a5,1
    8000266e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	70c080e7          	jalr	1804(ra) # 80000d7e <release>
}
    8000267a:	60e2                	ld	ra,24(sp)
    8000267c:	6442                	ld	s0,16(sp)
    8000267e:	64a2                	ld	s1,8(sp)
    80002680:	6105                	addi	sp,sp,32
    80002682:	8082                	ret

0000000080002684 <killed>:

int killed(struct proc *p)
{
    80002684:	1101                	addi	sp,sp,-32
    80002686:	ec06                	sd	ra,24(sp)
    80002688:	e822                	sd	s0,16(sp)
    8000268a:	e426                	sd	s1,8(sp)
    8000268c:	e04a                	sd	s2,0(sp)
    8000268e:	1000                	addi	s0,sp,32
    80002690:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	638080e7          	jalr	1592(ra) # 80000cca <acquire>
  k = p->killed;
    8000269a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000269e:	8526                	mv	a0,s1
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	6de080e7          	jalr	1758(ra) # 80000d7e <release>
  return k;
}
    800026a8:	854a                	mv	a0,s2
    800026aa:	60e2                	ld	ra,24(sp)
    800026ac:	6442                	ld	s0,16(sp)
    800026ae:	64a2                	ld	s1,8(sp)
    800026b0:	6902                	ld	s2,0(sp)
    800026b2:	6105                	addi	sp,sp,32
    800026b4:	8082                	ret

00000000800026b6 <wait>:
{
    800026b6:	715d                	addi	sp,sp,-80
    800026b8:	e486                	sd	ra,72(sp)
    800026ba:	e0a2                	sd	s0,64(sp)
    800026bc:	fc26                	sd	s1,56(sp)
    800026be:	f84a                	sd	s2,48(sp)
    800026c0:	f44e                	sd	s3,40(sp)
    800026c2:	f052                	sd	s4,32(sp)
    800026c4:	ec56                	sd	s5,24(sp)
    800026c6:	e85a                	sd	s6,16(sp)
    800026c8:	e45e                	sd	s7,8(sp)
    800026ca:	e062                	sd	s8,0(sp)
    800026cc:	0880                	addi	s0,sp,80
    800026ce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	492080e7          	jalr	1170(ra) # 80001b62 <myproc>
    800026d8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026da:	0022e517          	auipc	a0,0x22e
    800026de:	53650513          	addi	a0,a0,1334 # 80230c10 <wait_lock>
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5e8080e7          	jalr	1512(ra) # 80000cca <acquire>
    havekids = 0;
    800026ea:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026ec:	4a15                	li	s4,5
        havekids = 1;
    800026ee:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f0:	00236997          	auipc	s3,0x236
    800026f4:	93898993          	addi	s3,s3,-1736 # 80238028 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026f8:	0022ec17          	auipc	s8,0x22e
    800026fc:	518c0c13          	addi	s8,s8,1304 # 80230c10 <wait_lock>
    havekids = 0;
    80002700:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002702:	0022f497          	auipc	s1,0x22f
    80002706:	92648493          	addi	s1,s1,-1754 # 80231028 <proc>
    8000270a:	a0bd                	j	80002778 <wait+0xc2>
          pid = pp->pid;
    8000270c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002710:	000b0e63          	beqz	s6,8000272c <wait+0x76>
    80002714:	4691                	li	a3,4
    80002716:	02c48613          	addi	a2,s1,44
    8000271a:	85da                	mv	a1,s6
    8000271c:	05093503          	ld	a0,80(s2)
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	03c080e7          	jalr	60(ra) # 8000175c <copyout>
    80002728:	02054563          	bltz	a0,80002752 <wait+0x9c>
          freeproc(pp);
    8000272c:	8526                	mv	a0,s1
    8000272e:	fffff097          	auipc	ra,0xfffff
    80002732:	5e6080e7          	jalr	1510(ra) # 80001d14 <freeproc>
          release(&pp->lock);
    80002736:	8526                	mv	a0,s1
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	646080e7          	jalr	1606(ra) # 80000d7e <release>
          release(&wait_lock);
    80002740:	0022e517          	auipc	a0,0x22e
    80002744:	4d050513          	addi	a0,a0,1232 # 80230c10 <wait_lock>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	636080e7          	jalr	1590(ra) # 80000d7e <release>
          return pid;
    80002750:	a0b5                	j	800027bc <wait+0x106>
            release(&pp->lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	62a080e7          	jalr	1578(ra) # 80000d7e <release>
            release(&wait_lock);
    8000275c:	0022e517          	auipc	a0,0x22e
    80002760:	4b450513          	addi	a0,a0,1204 # 80230c10 <wait_lock>
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	61a080e7          	jalr	1562(ra) # 80000d7e <release>
            return -1;
    8000276c:	59fd                	li	s3,-1
    8000276e:	a0b9                	j	800027bc <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002770:	1c048493          	addi	s1,s1,448
    80002774:	03348463          	beq	s1,s3,8000279c <wait+0xe6>
      if (pp->parent == p)
    80002778:	7c9c                	ld	a5,56(s1)
    8000277a:	ff279be3          	bne	a5,s2,80002770 <wait+0xba>
        acquire(&pp->lock);
    8000277e:	8526                	mv	a0,s1
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	54a080e7          	jalr	1354(ra) # 80000cca <acquire>
        if (pp->state == ZOMBIE)
    80002788:	4c9c                	lw	a5,24(s1)
    8000278a:	f94781e3          	beq	a5,s4,8000270c <wait+0x56>
        release(&pp->lock);
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	5ee080e7          	jalr	1518(ra) # 80000d7e <release>
        havekids = 1;
    80002798:	8756                	mv	a4,s5
    8000279a:	bfd9                	j	80002770 <wait+0xba>
    if (!havekids || killed(p))
    8000279c:	c719                	beqz	a4,800027aa <wait+0xf4>
    8000279e:	854a                	mv	a0,s2
    800027a0:	00000097          	auipc	ra,0x0
    800027a4:	ee4080e7          	jalr	-284(ra) # 80002684 <killed>
    800027a8:	c51d                	beqz	a0,800027d6 <wait+0x120>
      release(&wait_lock);
    800027aa:	0022e517          	auipc	a0,0x22e
    800027ae:	46650513          	addi	a0,a0,1126 # 80230c10 <wait_lock>
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	5cc080e7          	jalr	1484(ra) # 80000d7e <release>
      return -1;
    800027ba:	59fd                	li	s3,-1
}
    800027bc:	854e                	mv	a0,s3
    800027be:	60a6                	ld	ra,72(sp)
    800027c0:	6406                	ld	s0,64(sp)
    800027c2:	74e2                	ld	s1,56(sp)
    800027c4:	7942                	ld	s2,48(sp)
    800027c6:	79a2                	ld	s3,40(sp)
    800027c8:	7a02                	ld	s4,32(sp)
    800027ca:	6ae2                	ld	s5,24(sp)
    800027cc:	6b42                	ld	s6,16(sp)
    800027ce:	6ba2                	ld	s7,8(sp)
    800027d0:	6c02                	ld	s8,0(sp)
    800027d2:	6161                	addi	sp,sp,80
    800027d4:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027d6:	85e2                	mv	a1,s8
    800027d8:	854a                	mv	a0,s2
    800027da:	00000097          	auipc	ra,0x0
    800027de:	bea080e7          	jalr	-1046(ra) # 800023c4 <sleep>
    havekids = 0;
    800027e2:	bf39                	j	80002700 <wait+0x4a>

00000000800027e4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027e4:	7179                	addi	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	e052                	sd	s4,0(sp)
    800027f2:	1800                	addi	s0,sp,48
    800027f4:	84aa                	mv	s1,a0
    800027f6:	892e                	mv	s2,a1
    800027f8:	89b2                	mv	s3,a2
    800027fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	366080e7          	jalr	870(ra) # 80001b62 <myproc>
  if (user_dst)
    80002804:	c08d                	beqz	s1,80002826 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002806:	86d2                	mv	a3,s4
    80002808:	864e                	mv	a2,s3
    8000280a:	85ca                	mv	a1,s2
    8000280c:	6928                	ld	a0,80(a0)
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	f4e080e7          	jalr	-178(ra) # 8000175c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002816:	70a2                	ld	ra,40(sp)
    80002818:	7402                	ld	s0,32(sp)
    8000281a:	64e2                	ld	s1,24(sp)
    8000281c:	6942                	ld	s2,16(sp)
    8000281e:	69a2                	ld	s3,8(sp)
    80002820:	6a02                	ld	s4,0(sp)
    80002822:	6145                	addi	sp,sp,48
    80002824:	8082                	ret
    memmove((char *)dst, src, len);
    80002826:	000a061b          	sext.w	a2,s4
    8000282a:	85ce                	mv	a1,s3
    8000282c:	854a                	mv	a0,s2
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	5f4080e7          	jalr	1524(ra) # 80000e22 <memmove>
    return 0;
    80002836:	8526                	mv	a0,s1
    80002838:	bff9                	j	80002816 <either_copyout+0x32>

000000008000283a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000283a:	7179                	addi	sp,sp,-48
    8000283c:	f406                	sd	ra,40(sp)
    8000283e:	f022                	sd	s0,32(sp)
    80002840:	ec26                	sd	s1,24(sp)
    80002842:	e84a                	sd	s2,16(sp)
    80002844:	e44e                	sd	s3,8(sp)
    80002846:	e052                	sd	s4,0(sp)
    80002848:	1800                	addi	s0,sp,48
    8000284a:	892a                	mv	s2,a0
    8000284c:	84ae                	mv	s1,a1
    8000284e:	89b2                	mv	s3,a2
    80002850:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	310080e7          	jalr	784(ra) # 80001b62 <myproc>
  if (user_src)
    8000285a:	c08d                	beqz	s1,8000287c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000285c:	86d2                	mv	a3,s4
    8000285e:	864e                	mv	a2,s3
    80002860:	85ca                	mv	a1,s2
    80002862:	6928                	ld	a0,80(a0)
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	04a080e7          	jalr	74(ra) # 800018ae <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000286c:	70a2                	ld	ra,40(sp)
    8000286e:	7402                	ld	s0,32(sp)
    80002870:	64e2                	ld	s1,24(sp)
    80002872:	6942                	ld	s2,16(sp)
    80002874:	69a2                	ld	s3,8(sp)
    80002876:	6a02                	ld	s4,0(sp)
    80002878:	6145                	addi	sp,sp,48
    8000287a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000287c:	000a061b          	sext.w	a2,s4
    80002880:	85ce                	mv	a1,s3
    80002882:	854a                	mv	a0,s2
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	59e080e7          	jalr	1438(ra) # 80000e22 <memmove>
    return 0;
    8000288c:	8526                	mv	a0,s1
    8000288e:	bff9                	j	8000286c <either_copyin+0x32>

0000000080002890 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002890:	715d                	addi	sp,sp,-80
    80002892:	e486                	sd	ra,72(sp)
    80002894:	e0a2                	sd	s0,64(sp)
    80002896:	fc26                	sd	s1,56(sp)
    80002898:	f84a                	sd	s2,48(sp)
    8000289a:	f44e                	sd	s3,40(sp)
    8000289c:	f052                	sd	s4,32(sp)
    8000289e:	ec56                	sd	s5,24(sp)
    800028a0:	e85a                	sd	s6,16(sp)
    800028a2:	e45e                	sd	s7,8(sp)
    800028a4:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	85250513          	addi	a0,a0,-1966 # 800080f8 <digits+0xb8>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	cdc080e7          	jalr	-804(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028b6:	0022f497          	auipc	s1,0x22f
    800028ba:	8ca48493          	addi	s1,s1,-1846 # 80231180 <proc+0x158>
    800028be:	00236917          	auipc	s2,0x236
    800028c2:	8c290913          	addi	s2,s2,-1854 # 80238180 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028c8:	00006997          	auipc	s3,0x6
    800028cc:	9e898993          	addi	s3,s3,-1560 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800028d0:	00006a97          	auipc	s5,0x6
    800028d4:	9e8a8a93          	addi	s5,s5,-1560 # 800082b8 <digits+0x278>
    printf("\n");
    800028d8:	00006a17          	auipc	s4,0x6
    800028dc:	820a0a13          	addi	s4,s4,-2016 # 800080f8 <digits+0xb8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e0:	00006b97          	auipc	s7,0x6
    800028e4:	a48b8b93          	addi	s7,s7,-1464 # 80008328 <states.0>
    800028e8:	a00d                	j	8000290a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028ea:	ed86a583          	lw	a1,-296(a3)
    800028ee:	8556                	mv	a0,s5
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c9a080e7          	jalr	-870(ra) # 8000058a <printf>
    printf("\n");
    800028f8:	8552                	mv	a0,s4
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c90080e7          	jalr	-880(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002902:	1c048493          	addi	s1,s1,448
    80002906:	03248263          	beq	s1,s2,8000292a <procdump+0x9a>
    if (p->state == UNUSED)
    8000290a:	86a6                	mv	a3,s1
    8000290c:	ec04a783          	lw	a5,-320(s1)
    80002910:	dbed                	beqz	a5,80002902 <procdump+0x72>
      state = "???";
    80002912:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002914:	fcfb6be3          	bltu	s6,a5,800028ea <procdump+0x5a>
    80002918:	02079713          	slli	a4,a5,0x20
    8000291c:	01d75793          	srli	a5,a4,0x1d
    80002920:	97de                	add	a5,a5,s7
    80002922:	6390                	ld	a2,0(a5)
    80002924:	f279                	bnez	a2,800028ea <procdump+0x5a>
      state = "???";
    80002926:	864e                	mv	a2,s3
    80002928:	b7c9                	j	800028ea <procdump+0x5a>
  }
}
    8000292a:	60a6                	ld	ra,72(sp)
    8000292c:	6406                	ld	s0,64(sp)
    8000292e:	74e2                	ld	s1,56(sp)
    80002930:	7942                	ld	s2,48(sp)
    80002932:	79a2                	ld	s3,40(sp)
    80002934:	7a02                	ld	s4,32(sp)
    80002936:	6ae2                	ld	s5,24(sp)
    80002938:	6b42                	ld	s6,16(sp)
    8000293a:	6ba2                	ld	s7,8(sp)
    8000293c:	6161                	addi	sp,sp,80
    8000293e:	8082                	ret

0000000080002940 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002940:	711d                	addi	sp,sp,-96
    80002942:	ec86                	sd	ra,88(sp)
    80002944:	e8a2                	sd	s0,80(sp)
    80002946:	e4a6                	sd	s1,72(sp)
    80002948:	e0ca                	sd	s2,64(sp)
    8000294a:	fc4e                	sd	s3,56(sp)
    8000294c:	f852                	sd	s4,48(sp)
    8000294e:	f456                	sd	s5,40(sp)
    80002950:	f05a                	sd	s6,32(sp)
    80002952:	ec5e                	sd	s7,24(sp)
    80002954:	e862                	sd	s8,16(sp)
    80002956:	e466                	sd	s9,8(sp)
    80002958:	e06a                	sd	s10,0(sp)
    8000295a:	1080                	addi	s0,sp,96
    8000295c:	8b2a                	mv	s6,a0
    8000295e:	8bae                	mv	s7,a1
    80002960:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	200080e7          	jalr	512(ra) # 80001b62 <myproc>
    8000296a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000296c:	0022e517          	auipc	a0,0x22e
    80002970:	2a450513          	addi	a0,a0,676 # 80230c10 <wait_lock>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	356080e7          	jalr	854(ra) # 80000cca <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000297c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000297e:	4a15                	li	s4,5
        havekids = 1;
    80002980:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002982:	00235997          	auipc	s3,0x235
    80002986:	6a698993          	addi	s3,s3,1702 # 80238028 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000298a:	0022ed17          	auipc	s10,0x22e
    8000298e:	286d0d13          	addi	s10,s10,646 # 80230c10 <wait_lock>
    havekids = 0;
    80002992:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002994:	0022e497          	auipc	s1,0x22e
    80002998:	69448493          	addi	s1,s1,1684 # 80231028 <proc>
    8000299c:	a059                	j	80002a22 <waitx+0xe2>
          pid = np->pid;
    8000299e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800029a2:	1684a783          	lw	a5,360(s1)
    800029a6:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800029aa:	16c4a703          	lw	a4,364(s1)
    800029ae:	9f3d                	addw	a4,a4,a5
    800029b0:	1704a783          	lw	a5,368(s1)
    800029b4:	9f99                	subw	a5,a5,a4
    800029b6:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029ba:	000b0e63          	beqz	s6,800029d6 <waitx+0x96>
    800029be:	4691                	li	a3,4
    800029c0:	02c48613          	addi	a2,s1,44
    800029c4:	85da                	mv	a1,s6
    800029c6:	05093503          	ld	a0,80(s2)
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	d92080e7          	jalr	-622(ra) # 8000175c <copyout>
    800029d2:	02054563          	bltz	a0,800029fc <waitx+0xbc>
          freeproc(np);
    800029d6:	8526                	mv	a0,s1
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	33c080e7          	jalr	828(ra) # 80001d14 <freeproc>
          release(&np->lock);
    800029e0:	8526                	mv	a0,s1
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	39c080e7          	jalr	924(ra) # 80000d7e <release>
          release(&wait_lock);
    800029ea:	0022e517          	auipc	a0,0x22e
    800029ee:	22650513          	addi	a0,a0,550 # 80230c10 <wait_lock>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	38c080e7          	jalr	908(ra) # 80000d7e <release>
          return pid;
    800029fa:	a09d                	j	80002a60 <waitx+0x120>
            release(&np->lock);
    800029fc:	8526                	mv	a0,s1
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	380080e7          	jalr	896(ra) # 80000d7e <release>
            release(&wait_lock);
    80002a06:	0022e517          	auipc	a0,0x22e
    80002a0a:	20a50513          	addi	a0,a0,522 # 80230c10 <wait_lock>
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	370080e7          	jalr	880(ra) # 80000d7e <release>
            return -1;
    80002a16:	59fd                	li	s3,-1
    80002a18:	a0a1                	j	80002a60 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a1a:	1c048493          	addi	s1,s1,448
    80002a1e:	03348463          	beq	s1,s3,80002a46 <waitx+0x106>
      if (np->parent == p)
    80002a22:	7c9c                	ld	a5,56(s1)
    80002a24:	ff279be3          	bne	a5,s2,80002a1a <waitx+0xda>
        acquire(&np->lock);
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	2a0080e7          	jalr	672(ra) # 80000cca <acquire>
        if (np->state == ZOMBIE)
    80002a32:	4c9c                	lw	a5,24(s1)
    80002a34:	f74785e3          	beq	a5,s4,8000299e <waitx+0x5e>
        release(&np->lock);
    80002a38:	8526                	mv	a0,s1
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	344080e7          	jalr	836(ra) # 80000d7e <release>
        havekids = 1;
    80002a42:	8756                	mv	a4,s5
    80002a44:	bfd9                	j	80002a1a <waitx+0xda>
    if (!havekids || p->killed)
    80002a46:	c701                	beqz	a4,80002a4e <waitx+0x10e>
    80002a48:	02892783          	lw	a5,40(s2)
    80002a4c:	cb8d                	beqz	a5,80002a7e <waitx+0x13e>
      release(&wait_lock);
    80002a4e:	0022e517          	auipc	a0,0x22e
    80002a52:	1c250513          	addi	a0,a0,450 # 80230c10 <wait_lock>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	328080e7          	jalr	808(ra) # 80000d7e <release>
      return -1;
    80002a5e:	59fd                	li	s3,-1
  }
}
    80002a60:	854e                	mv	a0,s3
    80002a62:	60e6                	ld	ra,88(sp)
    80002a64:	6446                	ld	s0,80(sp)
    80002a66:	64a6                	ld	s1,72(sp)
    80002a68:	6906                	ld	s2,64(sp)
    80002a6a:	79e2                	ld	s3,56(sp)
    80002a6c:	7a42                	ld	s4,48(sp)
    80002a6e:	7aa2                	ld	s5,40(sp)
    80002a70:	7b02                	ld	s6,32(sp)
    80002a72:	6be2                	ld	s7,24(sp)
    80002a74:	6c42                	ld	s8,16(sp)
    80002a76:	6ca2                	ld	s9,8(sp)
    80002a78:	6d02                	ld	s10,0(sp)
    80002a7a:	6125                	addi	sp,sp,96
    80002a7c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a7e:	85ea                	mv	a1,s10
    80002a80:	854a                	mv	a0,s2
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	942080e7          	jalr	-1726(ra) # 800023c4 <sleep>
    havekids = 0;
    80002a8a:	b721                	j	80002992 <waitx+0x52>

0000000080002a8c <update_time>:

void update_time()
{
    80002a8c:	7139                	addi	sp,sp,-64
    80002a8e:	fc06                	sd	ra,56(sp)
    80002a90:	f822                	sd	s0,48(sp)
    80002a92:	f426                	sd	s1,40(sp)
    80002a94:	f04a                	sd	s2,32(sp)
    80002a96:	ec4e                	sd	s3,24(sp)
    80002a98:	e852                	sd	s4,16(sp)
    80002a9a:	e456                	sd	s5,8(sp)
    80002a9c:	0080                	addi	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a9e:	0022e497          	auipc	s1,0x22e
    80002aa2:	58a48493          	addi	s1,s1,1418 # 80231028 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002aa6:	4991                	li	s3,4
    {
      p->rtime++;
      p->runtime++;
    }
    else if(p->state == SLEEPING)
    80002aa8:	4a09                	li	s4,2
    {
      p->stime++;
    }
    else if(p->state == RUNNABLE)
    80002aaa:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002aac:	00235917          	auipc	s2,0x235
    80002ab0:	57c90913          	addi	s2,s2,1404 # 80238028 <tickslock>
    80002ab4:	a025                	j	80002adc <update_time+0x50>
      p->rtime++;
    80002ab6:	1684a783          	lw	a5,360(s1)
    80002aba:	2785                	addiw	a5,a5,1
    80002abc:	16f4a423          	sw	a5,360(s1)
      p->runtime++;
    80002ac0:	1a84a783          	lw	a5,424(s1)
    80002ac4:	2785                	addiw	a5,a5,1
    80002ac6:	1af4a423          	sw	a5,424(s1)
    {
      p->wtime++;
    }
    release(&p->lock);
    80002aca:	8526                	mv	a0,s1
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	2b2080e7          	jalr	690(ra) # 80000d7e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ad4:	1c048493          	addi	s1,s1,448
    80002ad8:	03248a63          	beq	s1,s2,80002b0c <update_time+0x80>
    acquire(&p->lock);
    80002adc:	8526                	mv	a0,s1
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	1ec080e7          	jalr	492(ra) # 80000cca <acquire>
    if (p->state == RUNNING)
    80002ae6:	4c9c                	lw	a5,24(s1)
    80002ae8:	fd3787e3          	beq	a5,s3,80002ab6 <update_time+0x2a>
    else if(p->state == SLEEPING)
    80002aec:	01478a63          	beq	a5,s4,80002b00 <update_time+0x74>
    else if(p->state == RUNNABLE)
    80002af0:	fd579de3          	bne	a5,s5,80002aca <update_time+0x3e>
      p->wtime++;
    80002af4:	1ac4a783          	lw	a5,428(s1)
    80002af8:	2785                	addiw	a5,a5,1
    80002afa:	1af4a623          	sw	a5,428(s1)
    80002afe:	b7f1                	j	80002aca <update_time+0x3e>
      p->stime++;
    80002b00:	1b04a783          	lw	a5,432(s1)
    80002b04:	2785                	addiw	a5,a5,1
    80002b06:	1af4a823          	sw	a5,432(s1)
    80002b0a:	b7c1                	j	80002aca <update_time+0x3e>
  }
}
    80002b0c:	70e2                	ld	ra,56(sp)
    80002b0e:	7442                	ld	s0,48(sp)
    80002b10:	74a2                	ld	s1,40(sp)
    80002b12:	7902                	ld	s2,32(sp)
    80002b14:	69e2                	ld	s3,24(sp)
    80002b16:	6a42                	ld	s4,16(sp)
    80002b18:	6aa2                	ld	s5,8(sp)
    80002b1a:	6121                	addi	sp,sp,64
    80002b1c:	8082                	ret

0000000080002b1e <InitQueue>:

Queue InitQueue()
{
    80002b1e:	7179                	addi	sp,sp,-48
    80002b20:	f422                	sd	s0,40(sp)
    80002b22:	1800                	addi	s0,sp,48
    80002b24:	04000793          	li	a5,64
  que.front = -1;
  que.rear = -1;
  que.size = NPROC;
  struct proc* arr[NPROC];
  que.arr = arr;
  for(int i = 0; i < NPROC; i++)
    80002b28:	37fd                	addiw	a5,a5,-1
    80002b2a:	fffd                	bnez	a5,80002b28 <InitQueue+0xa>
  }

  Queue q = &que;

  return q;
}
    80002b2c:	fd840513          	addi	a0,s0,-40
    80002b30:	7422                	ld	s0,40(sp)
    80002b32:	6145                	addi	sp,sp,48
    80002b34:	8082                	ret

0000000080002b36 <IsEmpty>:

int IsEmpty(Queue q)
{
    80002b36:	1141                	addi	sp,sp,-16
    80002b38:	e422                	sd	s0,8(sp)
    80002b3a:	0800                	addi	s0,sp,16
  return q->front == -1;
    80002b3c:	4108                	lw	a0,0(a0)
    80002b3e:	0505                	addi	a0,a0,1
}
    80002b40:	00153513          	seqz	a0,a0
    80002b44:	6422                	ld	s0,8(sp)
    80002b46:	0141                	addi	sp,sp,16
    80002b48:	8082                	ret

0000000080002b4a <IsFull>:

int IsFull(Queue q)
{
    80002b4a:	1141                	addi	sp,sp,-16
    80002b4c:	e422                	sd	s0,8(sp)
    80002b4e:	0800                	addi	s0,sp,16
  return (q->rear + 1) % q->size == q->front;
    80002b50:	415c                	lw	a5,4(a0)
    80002b52:	2785                	addiw	a5,a5,1
    80002b54:	4518                	lw	a4,8(a0)
    80002b56:	02e7e7bb          	remw	a5,a5,a4
    80002b5a:	4118                	lw	a4,0(a0)
    80002b5c:	40e78533          	sub	a0,a5,a4
}
    80002b60:	00153513          	seqz	a0,a0
    80002b64:	6422                	ld	s0,8(sp)
    80002b66:	0141                	addi	sp,sp,16
    80002b68:	8082                	ret

0000000080002b6a <Enqueue>:


void Enqueue(Queue q, struct proc* pro) 
{
    80002b6a:	1101                	addi	sp,sp,-32
    80002b6c:	ec06                	sd	ra,24(sp)
    80002b6e:	e822                	sd	s0,16(sp)
    80002b70:	e426                	sd	s1,8(sp)
    80002b72:	e04a                	sd	s2,0(sp)
    80002b74:	1000                	addi	s0,sp,32
    80002b76:	84aa                	mv	s1,a0
    80002b78:	892e                	mv	s2,a1
  if (IsFull(q) || ((q->front == 0) && (q->rear == q->size-1)))
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	fd0080e7          	jalr	-48(ra) # 80002b4a <IsFull>
    80002b82:	ed01                	bnez	a0,80002b9a <Enqueue+0x30>
    80002b84:	409c                	lw	a5,0(s1)
    80002b86:	e39d                	bnez	a5,80002bac <Enqueue+0x42>
    80002b88:	449c                	lw	a5,8(s1)
    80002b8a:	40d8                	lw	a4,4(s1)
    80002b8c:	37fd                	addiw	a5,a5,-1
    80002b8e:	00f70663          	beq	a4,a5,80002b9a <Enqueue+0x30>
  if (IsEmpty(q))
  {
    q->front = 0;
    q->rear = 0;
  }
  else if(q->rear == q->size-1 && q->front != 0)
    80002b92:	40dc                	lw	a5,4(s1)
  {
    q->rear = 0;
  }
  else
  {
    q->rear++;
    80002b94:	0017851b          	addiw	a0,a5,1
    80002b98:	a839                	j	80002bb6 <Enqueue+0x4c>
    printf("Process queue is full\n");
    80002b9a:	00005517          	auipc	a0,0x5
    80002b9e:	72e50513          	addi	a0,a0,1838 # 800082c8 <digits+0x288>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	9e8080e7          	jalr	-1560(ra) # 8000058a <printf>
    return;
    80002baa:	a821                	j	80002bc2 <Enqueue+0x58>
  if (IsEmpty(q))
    80002bac:	577d                	li	a4,-1
    80002bae:	02e79063          	bne	a5,a4,80002bce <Enqueue+0x64>
    q->front = 0;
    80002bb2:	0004a023          	sw	zero,0(s1)
    q->rear = 0;
    80002bb6:	c0c8                	sw	a0,4(s1)
  }
  q->arr[q->rear] = pro;
    80002bb8:	689c                	ld	a5,16(s1)
    80002bba:	050e                	slli	a0,a0,0x3
    80002bbc:	97aa                	add	a5,a5,a0
    80002bbe:	0127b023          	sd	s2,0(a5)
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6902                	ld	s2,0(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret
  else if(q->rear == q->size-1 && q->front != 0)
    80002bce:	40dc                	lw	a5,4(s1)
    80002bd0:	4498                	lw	a4,8(s1)
    80002bd2:	377d                	addiw	a4,a4,-1
    80002bd4:	fef701e3          	beq	a4,a5,80002bb6 <Enqueue+0x4c>
    80002bd8:	bf75                	j	80002b94 <Enqueue+0x2a>

0000000080002bda <Dequeue>:
  return q->front == -1;
    80002bda:	4118                	lw	a4,0(a0)

struct proc* Dequeue(Queue q)
{
  struct proc * ret;

  if (IsEmpty(q))
    80002bdc:	56fd                	li	a3,-1
    80002bde:	02d70163          	beq	a4,a3,80002c00 <Dequeue+0x26>
    80002be2:	87aa                	mv	a5,a0
  {
    printf("Process queue is empty\n");
    return 0;
  }
  if (q->front == q->rear)
    80002be4:	4154                	lw	a3,4(a0)
    80002be6:	02e68e63          	beq	a3,a4,80002c22 <Dequeue+0x48>
    q->rear = -1;
      
  }
  else
  {
    ret = q->arr[q->front];
    80002bea:	6914                	ld	a3,16(a0)
    80002bec:	00371613          	slli	a2,a4,0x3
    80002bf0:	96b2                	add	a3,a3,a2
    80002bf2:	6288                	ld	a0,0(a3)
    q->front = (q->front + 1) % q->size;
    80002bf4:	2705                	addiw	a4,a4,1
    80002bf6:	4794                	lw	a3,8(a5)
    80002bf8:	02d7673b          	remw	a4,a4,a3
    80002bfc:	c398                	sw	a4,0(a5)
  }
  return ret;
}
    80002bfe:	8082                	ret
{
    80002c00:	1141                	addi	sp,sp,-16
    80002c02:	e406                	sd	ra,8(sp)
    80002c04:	e022                	sd	s0,0(sp)
    80002c06:	0800                	addi	s0,sp,16
    printf("Process queue is empty\n");
    80002c08:	00005517          	auipc	a0,0x5
    80002c0c:	6d850513          	addi	a0,a0,1752 # 800082e0 <digits+0x2a0>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	97a080e7          	jalr	-1670(ra) # 8000058a <printf>
    return 0;
    80002c18:	4501                	li	a0,0
}
    80002c1a:	60a2                	ld	ra,8(sp)
    80002c1c:	6402                	ld	s0,0(sp)
    80002c1e:	0141                	addi	sp,sp,16
    80002c20:	8082                	ret
    ret = q->arr[q->front];
    80002c22:	6914                	ld	a3,16(a0)
    80002c24:	070e                	slli	a4,a4,0x3
    80002c26:	9736                	add	a4,a4,a3
    80002c28:	6308                	ld	a0,0(a4)
    q->front = -1;
    80002c2a:	577d                	li	a4,-1
    80002c2c:	c398                	sw	a4,0(a5)
    q->rear = -1;
    80002c2e:	c3d8                	sw	a4,4(a5)
    80002c30:	8082                	ret

0000000080002c32 <DeqyuElement>:

struct proc* DeqyuElement(Queue q, struct proc* pro)
{
    80002c32:	7179                	addi	sp,sp,-48
    80002c34:	f406                	sd	ra,40(sp)
    80002c36:	f022                	sd	s0,32(sp)
    80002c38:	ec26                	sd	s1,24(sp)
    80002c3a:	e84a                	sd	s2,16(sp)
    80002c3c:	e44e                	sd	s3,8(sp)
    80002c3e:	1800                	addi	s0,sp,48
    80002c40:	84aa                	mv	s1,a0
  struct proc * ret;
  struct proc* deq;
  
  int oldfront = q->front;
    80002c42:	00052983          	lw	s3,0(a0)

  int curindex = 0;
  while(q->arr[curindex] != pro)
    80002c46:	691c                	ld	a5,16(a0)
    80002c48:	6398                	ld	a4,0(a5)
    80002c4a:	06e58963          	beq	a1,a4,80002cbc <DeqyuElement+0x8a>
    80002c4e:	07a1                	addi	a5,a5,8
  int curindex = 0;
    80002c50:	4901                	li	s2,0
  {
    curindex++;
    80002c52:	2905                	addiw	s2,s2,1
  while(q->arr[curindex] != pro)
    80002c54:	07a1                	addi	a5,a5,8
    80002c56:	ff87b703          	ld	a4,-8(a5)
    80002c5a:	feb71ce3          	bne	a4,a1,80002c52 <DeqyuElement+0x20>
  }

  while(q->front != curindex)
    80002c5e:	03298063          	beq	s3,s2,80002c7e <DeqyuElement+0x4c>
  //while(q->front != curindex)
  {
    deq = Dequeue(q);
    80002c62:	8526                	mv	a0,s1
    80002c64:	00000097          	auipc	ra,0x0
    80002c68:	f76080e7          	jalr	-138(ra) # 80002bda <Dequeue>
    80002c6c:	85aa                	mv	a1,a0
    Enqueue(q, deq);
    80002c6e:	8526                	mv	a0,s1
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	efa080e7          	jalr	-262(ra) # 80002b6a <Enqueue>
  while(q->front != curindex)
    80002c78:	409c                	lw	a5,0(s1)
    80002c7a:	ff2794e3          	bne	a5,s2,80002c62 <DeqyuElement+0x30>
  }
  ret = Dequeue(q);
    80002c7e:	8526                	mv	a0,s1
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	f5a080e7          	jalr	-166(ra) # 80002bda <Dequeue>
    80002c88:	892a                	mv	s2,a0
  //while(!IsEmpty(q) && q->front != oldfront)
  while(q->front != oldfront)
    80002c8a:	409c                	lw	a5,0(s1)
    80002c8c:	03378063          	beq	a5,s3,80002cac <DeqyuElement+0x7a>
  {
    deq = Dequeue(q);
    80002c90:	8526                	mv	a0,s1
    80002c92:	00000097          	auipc	ra,0x0
    80002c96:	f48080e7          	jalr	-184(ra) # 80002bda <Dequeue>
    80002c9a:	85aa                	mv	a1,a0
    Enqueue(q, deq);
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	ecc080e7          	jalr	-308(ra) # 80002b6a <Enqueue>
  while(q->front != oldfront)
    80002ca6:	409c                	lw	a5,0(s1)
    80002ca8:	ff3794e3          	bne	a5,s3,80002c90 <DeqyuElement+0x5e>
  }
  return ret;
    80002cac:	854a                	mv	a0,s2
    80002cae:	70a2                	ld	ra,40(sp)
    80002cb0:	7402                	ld	s0,32(sp)
    80002cb2:	64e2                	ld	s1,24(sp)
    80002cb4:	6942                	ld	s2,16(sp)
    80002cb6:	69a2                	ld	s3,8(sp)
    80002cb8:	6145                	addi	sp,sp,48
    80002cba:	8082                	ret
  int curindex = 0;
    80002cbc:	4901                	li	s2,0
    80002cbe:	b745                	j	80002c5e <DeqyuElement+0x2c>

0000000080002cc0 <swtch>:
    80002cc0:	00153023          	sd	ra,0(a0)
    80002cc4:	00253423          	sd	sp,8(a0)
    80002cc8:	e900                	sd	s0,16(a0)
    80002cca:	ed04                	sd	s1,24(a0)
    80002ccc:	03253023          	sd	s2,32(a0)
    80002cd0:	03353423          	sd	s3,40(a0)
    80002cd4:	03453823          	sd	s4,48(a0)
    80002cd8:	03553c23          	sd	s5,56(a0)
    80002cdc:	05653023          	sd	s6,64(a0)
    80002ce0:	05753423          	sd	s7,72(a0)
    80002ce4:	05853823          	sd	s8,80(a0)
    80002ce8:	05953c23          	sd	s9,88(a0)
    80002cec:	07a53023          	sd	s10,96(a0)
    80002cf0:	07b53423          	sd	s11,104(a0)
    80002cf4:	0005b083          	ld	ra,0(a1)
    80002cf8:	0085b103          	ld	sp,8(a1)
    80002cfc:	6980                	ld	s0,16(a1)
    80002cfe:	6d84                	ld	s1,24(a1)
    80002d00:	0205b903          	ld	s2,32(a1)
    80002d04:	0285b983          	ld	s3,40(a1)
    80002d08:	0305ba03          	ld	s4,48(a1)
    80002d0c:	0385ba83          	ld	s5,56(a1)
    80002d10:	0405bb03          	ld	s6,64(a1)
    80002d14:	0485bb83          	ld	s7,72(a1)
    80002d18:	0505bc03          	ld	s8,80(a1)
    80002d1c:	0585bc83          	ld	s9,88(a1)
    80002d20:	0605bd03          	ld	s10,96(a1)
    80002d24:	0685bd83          	ld	s11,104(a1)
    80002d28:	8082                	ret

0000000080002d2a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002d2a:	1141                	addi	sp,sp,-16
    80002d2c:	e406                	sd	ra,8(sp)
    80002d2e:	e022                	sd	s0,0(sp)
    80002d30:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d32:	00005597          	auipc	a1,0x5
    80002d36:	62658593          	addi	a1,a1,1574 # 80008358 <states.0+0x30>
    80002d3a:	00235517          	auipc	a0,0x235
    80002d3e:	2ee50513          	addi	a0,a0,750 # 80238028 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	ef8080e7          	jalr	-264(ra) # 80000c3a <initlock>
}
    80002d4a:	60a2                	ld	ra,8(sp)
    80002d4c:	6402                	ld	s0,0(sp)
    80002d4e:	0141                	addi	sp,sp,16
    80002d50:	8082                	ret

0000000080002d52 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002d52:	1141                	addi	sp,sp,-16
    80002d54:	e422                	sd	s0,8(sp)
    80002d56:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d58:	00004797          	auipc	a5,0x4
    80002d5c:	85878793          	addi	a5,a5,-1960 # 800065b0 <kernelvec>
    80002d60:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d64:	6422                	ld	s0,8(sp)
    80002d66:	0141                	addi	sp,sp,16
    80002d68:	8082                	ret

0000000080002d6a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002d6a:	1141                	addi	sp,sp,-16
    80002d6c:	e406                	sd	ra,8(sp)
    80002d6e:	e022                	sd	s0,0(sp)
    80002d70:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	df0080e7          	jalr	-528(ra) # 80001b62 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d7e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d80:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d84:	00004697          	auipc	a3,0x4
    80002d88:	27c68693          	addi	a3,a3,636 # 80007000 <_trampoline>
    80002d8c:	00004717          	auipc	a4,0x4
    80002d90:	27470713          	addi	a4,a4,628 # 80007000 <_trampoline>
    80002d94:	8f15                	sub	a4,a4,a3
    80002d96:	040007b7          	lui	a5,0x4000
    80002d9a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002d9c:	07b2                	slli	a5,a5,0xc
    80002d9e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002da0:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002da4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002da6:	18002673          	csrr	a2,satp
    80002daa:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002dac:	6d30                	ld	a2,88(a0)
    80002dae:	6138                	ld	a4,64(a0)
    80002db0:	6585                	lui	a1,0x1
    80002db2:	972e                	add	a4,a4,a1
    80002db4:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002db6:	6d38                	ld	a4,88(a0)
    80002db8:	00000617          	auipc	a2,0x0
    80002dbc:	13e60613          	addi	a2,a2,318 # 80002ef6 <usertrap>
    80002dc0:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002dc2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002dc4:	8612                	mv	a2,tp
    80002dc6:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc8:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002dcc:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002dd0:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dd4:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002dd8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dda:	6f18                	ld	a4,24(a4)
    80002ddc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002de0:	6928                	ld	a0,80(a0)
    80002de2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002de4:	00004717          	auipc	a4,0x4
    80002de8:	2b870713          	addi	a4,a4,696 # 8000709c <userret>
    80002dec:	8f15                	sub	a4,a4,a3
    80002dee:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002df0:	577d                	li	a4,-1
    80002df2:	177e                	slli	a4,a4,0x3f
    80002df4:	8d59                	or	a0,a0,a4
    80002df6:	9782                	jalr	a5
}
    80002df8:	60a2                	ld	ra,8(sp)
    80002dfa:	6402                	ld	s0,0(sp)
    80002dfc:	0141                	addi	sp,sp,16
    80002dfe:	8082                	ret

0000000080002e00 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	e426                	sd	s1,8(sp)
    80002e08:	e04a                	sd	s2,0(sp)
    80002e0a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e0c:	00235917          	auipc	s2,0x235
    80002e10:	21c90913          	addi	s2,s2,540 # 80238028 <tickslock>
    80002e14:	854a                	mv	a0,s2
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	eb4080e7          	jalr	-332(ra) # 80000cca <acquire>
  ticks++;
    80002e1e:	00006497          	auipc	s1,0x6
    80002e22:	b5248493          	addi	s1,s1,-1198 # 80008970 <ticks>
    80002e26:	409c                	lw	a5,0(s1)
    80002e28:	2785                	addiw	a5,a5,1
    80002e2a:	c09c                	sw	a5,0(s1)
  update_time();
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	c60080e7          	jalr	-928(ra) # 80002a8c <update_time>
  //   {
  //     p->wtime++;
  //   }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002e34:	8526                	mv	a0,s1
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	5fe080e7          	jalr	1534(ra) # 80002434 <wakeup>
  release(&tickslock);
    80002e3e:	854a                	mv	a0,s2
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	f3e080e7          	jalr	-194(ra) # 80000d7e <release>
}
    80002e48:	60e2                	ld	ra,24(sp)
    80002e4a:	6442                	ld	s0,16(sp)
    80002e4c:	64a2                	ld	s1,8(sp)
    80002e4e:	6902                	ld	s2,0(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	e426                	sd	s1,8(sp)
    80002e5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e5e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002e62:	00074d63          	bltz	a4,80002e7c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002e66:	57fd                	li	a5,-1
    80002e68:	17fe                	slli	a5,a5,0x3f
    80002e6a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002e6c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002e6e:	06f70363          	beq	a4,a5,80002ed4 <devintr+0x80>
  }
}
    80002e72:	60e2                	ld	ra,24(sp)
    80002e74:	6442                	ld	s0,16(sp)
    80002e76:	64a2                	ld	s1,8(sp)
    80002e78:	6105                	addi	sp,sp,32
    80002e7a:	8082                	ret
      (scause & 0xff) == 9)
    80002e7c:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002e80:	46a5                	li	a3,9
    80002e82:	fed792e3          	bne	a5,a3,80002e66 <devintr+0x12>
    int irq = plic_claim();
    80002e86:	00004097          	auipc	ra,0x4
    80002e8a:	832080e7          	jalr	-1998(ra) # 800066b8 <plic_claim>
    80002e8e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002e90:	47a9                	li	a5,10
    80002e92:	02f50763          	beq	a0,a5,80002ec0 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002e96:	4785                	li	a5,1
    80002e98:	02f50963          	beq	a0,a5,80002eca <devintr+0x76>
    return 1;
    80002e9c:	4505                	li	a0,1
    else if (irq)
    80002e9e:	d8f1                	beqz	s1,80002e72 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ea0:	85a6                	mv	a1,s1
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	4be50513          	addi	a0,a0,1214 # 80008360 <states.0+0x38>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	6e0080e7          	jalr	1760(ra) # 8000058a <printf>
      plic_complete(irq);
    80002eb2:	8526                	mv	a0,s1
    80002eb4:	00004097          	auipc	ra,0x4
    80002eb8:	828080e7          	jalr	-2008(ra) # 800066dc <plic_complete>
    return 1;
    80002ebc:	4505                	li	a0,1
    80002ebe:	bf55                	j	80002e72 <devintr+0x1e>
      uartintr();
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	ad8080e7          	jalr	-1320(ra) # 80000998 <uartintr>
    80002ec8:	b7ed                	j	80002eb2 <devintr+0x5e>
      virtio_disk_intr();
    80002eca:	00004097          	auipc	ra,0x4
    80002ece:	cda080e7          	jalr	-806(ra) # 80006ba4 <virtio_disk_intr>
    80002ed2:	b7c5                	j	80002eb2 <devintr+0x5e>
    if (cpuid() == 0)
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	c62080e7          	jalr	-926(ra) # 80001b36 <cpuid>
    80002edc:	c901                	beqz	a0,80002eec <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ede:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ee2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ee4:	14479073          	csrw	sip,a5
    return 2;
    80002ee8:	4509                	li	a0,2
    80002eea:	b761                	j	80002e72 <devintr+0x1e>
      clockintr();
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	f14080e7          	jalr	-236(ra) # 80002e00 <clockintr>
    80002ef4:	b7ed                	j	80002ede <devintr+0x8a>

0000000080002ef6 <usertrap>:
{
    80002ef6:	7179                	addi	sp,sp,-48
    80002ef8:	f406                	sd	ra,40(sp)
    80002efa:	f022                	sd	s0,32(sp)
    80002efc:	ec26                	sd	s1,24(sp)
    80002efe:	e84a                	sd	s2,16(sp)
    80002f00:	e44e                	sd	s3,8(sp)
    80002f02:	e052                	sd	s4,0(sp)
    80002f04:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f06:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002f0a:	1007f793          	andi	a5,a5,256
    80002f0e:	ebd1                	bnez	a5,80002fa2 <usertrap+0xac>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f10:	00003797          	auipc	a5,0x3
    80002f14:	6a078793          	addi	a5,a5,1696 # 800065b0 <kernelvec>
    80002f18:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	c46080e7          	jalr	-954(ra) # 80001b62 <myproc>
    80002f24:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f26:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f28:	14102773          	csrr	a4,sepc
    80002f2c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f2e:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002f32:	47a1                	li	a5,8
    80002f34:	06f70f63          	beq	a4,a5,80002fb2 <usertrap+0xbc>
    80002f38:	14202773          	csrr	a4,scause
  else if(r_scause() == 15)
    80002f3c:	47bd                	li	a5,15
    80002f3e:	14f71063          	bne	a4,a5,8000307e <usertrap+0x188>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f42:	14302973          	csrr	s2,stval
    if((va >= MAXVA) || (va < p->trapframe->sp && va >= (p->trapframe->sp - PGSIZE)) || ((pte = (walk(p->pagetable, va, 0))) == 0) || ((*pte & PTE_V) == 0))
    80002f46:	57fd                	li	a5,-1
    80002f48:	83e9                	srli	a5,a5,0x1a
    80002f4a:	0327e663          	bltu	a5,s2,80002f76 <usertrap+0x80>
    80002f4e:	6d3c                	ld	a5,88(a0)
    80002f50:	7b9c                	ld	a5,48(a5)
    80002f52:	00f97663          	bgeu	s2,a5,80002f5e <usertrap+0x68>
    80002f56:	777d                	lui	a4,0xfffff
    80002f58:	97ba                	add	a5,a5,a4
    80002f5a:	00f97e63          	bgeu	s2,a5,80002f76 <usertrap+0x80>
    80002f5e:	4601                	li	a2,0
    80002f60:	85ca                	mv	a1,s2
    80002f62:	68a8                	ld	a0,80(s1)
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	146080e7          	jalr	326(ra) # 800010aa <walk>
    80002f6c:	c509                	beqz	a0,80002f76 <usertrap+0x80>
    80002f6e:	611c                	ld	a5,0(a0)
    80002f70:	0017f713          	andi	a4,a5,1
    80002f74:	eb35                	bnez	a4,80002fe8 <usertrap+0xf2>
      p->killed = 1;
    80002f76:	4785                	li	a5,1
    80002f78:	d49c                	sw	a5,40(s1)
  int which_dev = 0;
    80002f7a:	4901                	li	s2,0
  if (killed(p))
    80002f7c:	8526                	mv	a0,s1
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	706080e7          	jalr	1798(ra) # 80002684 <killed>
    80002f86:	1e051663          	bnez	a0,80003172 <usertrap+0x27c>
  usertrapret();
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	de0080e7          	jalr	-544(ra) # 80002d6a <usertrapret>
}
    80002f92:	70a2                	ld	ra,40(sp)
    80002f94:	7402                	ld	s0,32(sp)
    80002f96:	64e2                	ld	s1,24(sp)
    80002f98:	6942                	ld	s2,16(sp)
    80002f9a:	69a2                	ld	s3,8(sp)
    80002f9c:	6a02                	ld	s4,0(sp)
    80002f9e:	6145                	addi	sp,sp,48
    80002fa0:	8082                	ret
    panic("usertrap: not from user mode");
    80002fa2:	00005517          	auipc	a0,0x5
    80002fa6:	3de50513          	addi	a0,a0,990 # 80008380 <states.0+0x58>
    80002faa:	ffffd097          	auipc	ra,0xffffd
    80002fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    if (killed(p))
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	6d2080e7          	jalr	1746(ra) # 80002684 <killed>
    80002fba:	e10d                	bnez	a0,80002fdc <usertrap+0xe6>
    p->trapframe->epc += 4;
    80002fbc:	6cb8                	ld	a4,88(s1)
    80002fbe:	6f1c                	ld	a5,24(a4)
    80002fc0:	0791                	addi	a5,a5,4
    80002fc2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fc4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fc8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fcc:	10079073          	csrw	sstatus,a5
    syscall();
    80002fd0:	00000097          	auipc	ra,0x0
    80002fd4:	424080e7          	jalr	1060(ra) # 800033f4 <syscall>
  int which_dev = 0;
    80002fd8:	4901                	li	s2,0
    80002fda:	b74d                	j	80002f7c <usertrap+0x86>
      exit(-1);
    80002fdc:	557d                	li	a0,-1
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	526080e7          	jalr	1318(ra) # 80002504 <exit>
    80002fe6:	bfd9                	j	80002fbc <usertrap+0xc6>
    else if((*pte & PTE_COW))
    80002fe8:	2007f793          	andi	a5,a5,512
    80002fec:	e789                	bnez	a5,80002ff6 <usertrap+0x100>
      p->killed = 1;
    80002fee:	4785                	li	a5,1
    80002ff0:	d49c                	sw	a5,40(s1)
  int which_dev = 0;
    80002ff2:	4901                	li	s2,0
    80002ff4:	b761                	j	80002f7c <usertrap+0x86>
      pte = walk(p->pagetable, va, 0);
    80002ff6:	4601                	li	a2,0
    80002ff8:	75fd                	lui	a1,0xfffff
    80002ffa:	00b975b3          	and	a1,s2,a1
    80002ffe:	68a8                	ld	a0,80(s1)
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	0aa080e7          	jalr	170(ra) # 800010aa <walk>
    80003008:	89aa                	mv	s3,a0
      uint64 pa = PTE2PA(*pte);
    8000300a:	00053903          	ld	s2,0(a0)
    8000300e:	00a95913          	srli	s2,s2,0xa
    80003012:	0932                	slli	s2,s2,0xc
      if(get_refcount((void*)pa) == 1)
    80003014:	854a                	mv	a0,s2
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	c06080e7          	jalr	-1018(ra) # 80000c1c <get_refcount>
    8000301e:	4785                	li	a5,1
    80003020:	00f51c63          	bne	a0,a5,80003038 <usertrap+0x142>
        *pte &= ~PTE_COW;
    80003024:	0009b783          	ld	a5,0(s3)
    80003028:	dff7f793          	andi	a5,a5,-513
    8000302c:	0047e793          	ori	a5,a5,4
    80003030:	00f9b023          	sd	a5,0(s3)
  int which_dev = 0;
    80003034:	4901                	li	s2,0
    80003036:	b799                	j	80002f7c <usertrap+0x86>
        void* newpagepa = kalloc();
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	b2a080e7          	jalr	-1238(ra) # 80000b62 <kalloc>
    80003040:	8a2a                	mv	s4,a0
        if(newpagepa == 0)
    80003042:	c915                	beqz	a0,80003076 <usertrap+0x180>
          memmove(newpagepa, (void*)pa, PGSIZE);
    80003044:	6605                	lui	a2,0x1
    80003046:	85ca                	mv	a1,s2
    80003048:	ffffe097          	auipc	ra,0xffffe
    8000304c:	dda080e7          	jalr	-550(ra) # 80000e22 <memmove>
          uint64 newpagepte = PA2PTE(newpagepa) | flags | PTE_V;
    80003050:	00ca5793          	srli	a5,s4,0xc
    80003054:	07aa                	slli	a5,a5,0xa
          uint flags = PTE_FLAGS(*pte);
    80003056:	0009b703          	ld	a4,0(s3)
          uint64 newpagepte = PA2PTE(newpagepa) | flags | PTE_V;
    8000305a:	1ff77713          	andi	a4,a4,511
          *pte &= ~PTE_COW; //unset cow 
    8000305e:	8fd9                	or	a5,a5,a4
    80003060:	0057e793          	ori	a5,a5,5
    80003064:	00f9b023          	sd	a5,0(s3)
          kfree((void*)pa); //decrease ref count of old page and free
    80003068:	854a                	mv	a0,s2
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	97e080e7          	jalr	-1666(ra) # 800009e8 <kfree>
  int which_dev = 0;
    80003072:	4901                	li	s2,0
    80003074:	b721                	j	80002f7c <usertrap+0x86>
          p->killed = 1;
    80003076:	4785                	li	a5,1
    80003078:	d49c                	sw	a5,40(s1)
  int which_dev = 0;
    8000307a:	4901                	li	s2,0
    8000307c:	b701                	j	80002f7c <usertrap+0x86>
  else if ((which_dev = devintr()) != 0)
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	dd6080e7          	jalr	-554(ra) # 80002e54 <devintr>
    80003086:	892a                	mv	s2,a0
    80003088:	c945                	beqz	a0,80003138 <usertrap+0x242>
    if((which_dev = devintr()) == 2)
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	dca080e7          	jalr	-566(ra) # 80002e54 <devintr>
    80003092:	892a                	mv	s2,a0
    80003094:	4789                	li	a5,2
    80003096:	eef513e3          	bne	a0,a5,80002f7c <usertrap+0x86>
      if(p->alarm_flag == 0 && p->ticks != 0)
    8000309a:	1904a783          	lw	a5,400(s1)
    8000309e:	ebb1                	bnez	a5,800030f2 <usertrap+0x1fc>
    800030a0:	1804a783          	lw	a5,384(s1)
    800030a4:	c7b9                	beqz	a5,800030f2 <usertrap+0x1fc>
        p->currticks++;
    800030a6:	1844a703          	lw	a4,388(s1)
    800030aa:	2705                	addiw	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fdbbbf9>
    800030ac:	0007069b          	sext.w	a3,a4
    800030b0:	18e4a223          	sw	a4,388(s1)
        if(p->currticks >= p->ticks)
    800030b4:	02f6cf63          	blt	a3,a5,800030f2 <usertrap+0x1fc>
          *p->alarmtrpfrm = *p->trapframe;
    800030b8:	6cb4                	ld	a3,88(s1)
    800030ba:	87b6                	mv	a5,a3
    800030bc:	1884b703          	ld	a4,392(s1)
    800030c0:	12068693          	addi	a3,a3,288
    800030c4:	0007b803          	ld	a6,0(a5)
    800030c8:	6788                	ld	a0,8(a5)
    800030ca:	6b8c                	ld	a1,16(a5)
    800030cc:	6f90                	ld	a2,24(a5)
    800030ce:	01073023          	sd	a6,0(a4)
    800030d2:	e708                	sd	a0,8(a4)
    800030d4:	eb0c                	sd	a1,16(a4)
    800030d6:	ef10                	sd	a2,24(a4)
    800030d8:	02078793          	addi	a5,a5,32
    800030dc:	02070713          	addi	a4,a4,32
    800030e0:	fed792e3          	bne	a5,a3,800030c4 <usertrap+0x1ce>
          p->alarm_flag = 1;
    800030e4:	4785                	li	a5,1
    800030e6:	18f4a823          	sw	a5,400(s1)
          p->trapframe->epc = p->handlerfn;
    800030ea:	6cbc                	ld	a5,88(s1)
    800030ec:	1784b703          	ld	a4,376(s1)
    800030f0:	ef98                	sd	a4,24(a5)
{
    800030f2:	0022e497          	auipc	s1,0x22e
    800030f6:	f3648493          	addi	s1,s1,-202 # 80231028 <proc>
        if (p->state == RUNNABLE)
    800030fa:	4a0d                	li	s4,3
          p->waittime = 0;
    800030fc:	4981                	li	s3,0
      for (p = proc; p < &proc[NPROC]; p++)
    800030fe:	00235917          	auipc	s2,0x235
    80003102:	f2a90913          	addi	s2,s2,-214 # 80238028 <tickslock>
    80003106:	a821                	j	8000311e <usertrap+0x228>
    80003108:	18f4aa23          	sw	a5,404(s1)
        release(&p->lock);
    8000310c:	8526                	mv	a0,s1
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	c70080e7          	jalr	-912(ra) # 80000d7e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80003116:	1c048493          	addi	s1,s1,448
    8000311a:	07248963          	beq	s1,s2,8000318c <usertrap+0x296>
        acquire(&p->lock);
    8000311e:	8526                	mv	a0,s1
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	baa080e7          	jalr	-1110(ra) # 80000cca <acquire>
        if (p->state == RUNNABLE)
    80003128:	4c98                	lw	a4,24(s1)
          p->waittime = 0;
    8000312a:	87ce                	mv	a5,s3
        if (p->state == RUNNABLE)
    8000312c:	fd471ee3          	bne	a4,s4,80003108 <usertrap+0x212>
          p->waittime++;
    80003130:	1944a783          	lw	a5,404(s1)
    80003134:	2785                	addiw	a5,a5,1
    80003136:	bfc9                	j	80003108 <usertrap+0x212>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003138:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000313c:	5890                	lw	a2,48(s1)
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	26250513          	addi	a0,a0,610 # 800083a0 <states.0+0x78>
    80003146:	ffffd097          	auipc	ra,0xffffd
    8000314a:	444080e7          	jalr	1092(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000314e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003152:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003156:	00005517          	auipc	a0,0x5
    8000315a:	27a50513          	addi	a0,a0,634 # 800083d0 <states.0+0xa8>
    8000315e:	ffffd097          	auipc	ra,0xffffd
    80003162:	42c080e7          	jalr	1068(ra) # 8000058a <printf>
    setkilled(p);
    80003166:	8526                	mv	a0,s1
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	4f0080e7          	jalr	1264(ra) # 80002658 <setkilled>
    80003170:	b531                	j	80002f7c <usertrap+0x86>
    exit(-1);
    80003172:	557d                	li	a0,-1
    80003174:	fffff097          	auipc	ra,0xfffff
    80003178:	390080e7          	jalr	912(ra) # 80002504 <exit>
  if (which_dev == 2)
    8000317c:	4789                	li	a5,2
    8000317e:	e0f916e3          	bne	s2,a5,80002f8a <usertrap+0x94>
    yield();
    80003182:	fffff097          	auipc	ra,0xfffff
    80003186:	206080e7          	jalr	518(ra) # 80002388 <yield>
    8000318a:	b501                	j	80002f8a <usertrap+0x94>
  if (killed(p))
    8000318c:	00235517          	auipc	a0,0x235
    80003190:	e9c50513          	addi	a0,a0,-356 # 80238028 <tickslock>
    80003194:	fffff097          	auipc	ra,0xfffff
    80003198:	4f0080e7          	jalr	1264(ra) # 80002684 <killed>
    8000319c:	d17d                	beqz	a0,80003182 <usertrap+0x28c>
    exit(-1);
    8000319e:	557d                	li	a0,-1
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	364080e7          	jalr	868(ra) # 80002504 <exit>
  if (which_dev == 2)
    800031a8:	bfe9                	j	80003182 <usertrap+0x28c>

00000000800031aa <kerneltrap>:
{
    800031aa:	7179                	addi	sp,sp,-48
    800031ac:	f406                	sd	ra,40(sp)
    800031ae:	f022                	sd	s0,32(sp)
    800031b0:	ec26                	sd	s1,24(sp)
    800031b2:	e84a                	sd	s2,16(sp)
    800031b4:	e44e                	sd	s3,8(sp)
    800031b6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031b8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031bc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031c0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800031c4:	1004f793          	andi	a5,s1,256
    800031c8:	cb85                	beqz	a5,800031f8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031ca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031ce:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800031d0:	ef85                	bnez	a5,80003208 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	c82080e7          	jalr	-894(ra) # 80002e54 <devintr>
    800031da:	cd1d                	beqz	a0,80003218 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031dc:	4789                	li	a5,2
    800031de:	06f50a63          	beq	a0,a5,80003252 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031e2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031e6:	10049073          	csrw	sstatus,s1
}
    800031ea:	70a2                	ld	ra,40(sp)
    800031ec:	7402                	ld	s0,32(sp)
    800031ee:	64e2                	ld	s1,24(sp)
    800031f0:	6942                	ld	s2,16(sp)
    800031f2:	69a2                	ld	s3,8(sp)
    800031f4:	6145                	addi	sp,sp,48
    800031f6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	1f850513          	addi	a0,a0,504 # 800083f0 <states.0+0xc8>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	340080e7          	jalr	832(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	21050513          	addi	a0,a0,528 # 80008418 <states.0+0xf0>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	330080e7          	jalr	816(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003218:	85ce                	mv	a1,s3
    8000321a:	00005517          	auipc	a0,0x5
    8000321e:	21e50513          	addi	a0,a0,542 # 80008438 <states.0+0x110>
    80003222:	ffffd097          	auipc	ra,0xffffd
    80003226:	368080e7          	jalr	872(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000322a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000322e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003232:	00005517          	auipc	a0,0x5
    80003236:	21650513          	addi	a0,a0,534 # 80008448 <states.0+0x120>
    8000323a:	ffffd097          	auipc	ra,0xffffd
    8000323e:	350080e7          	jalr	848(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003242:	00005517          	auipc	a0,0x5
    80003246:	21e50513          	addi	a0,a0,542 # 80008460 <states.0+0x138>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003252:	fffff097          	auipc	ra,0xfffff
    80003256:	910080e7          	jalr	-1776(ra) # 80001b62 <myproc>
    8000325a:	d541                	beqz	a0,800031e2 <kerneltrap+0x38>
    8000325c:	fffff097          	auipc	ra,0xfffff
    80003260:	906080e7          	jalr	-1786(ra) # 80001b62 <myproc>
    80003264:	4d18                	lw	a4,24(a0)
    80003266:	4791                	li	a5,4
    80003268:	f6f71de3          	bne	a4,a5,800031e2 <kerneltrap+0x38>
    yield();
    8000326c:	fffff097          	auipc	ra,0xfffff
    80003270:	11c080e7          	jalr	284(ra) # 80002388 <yield>
    80003274:	b7bd                	j	800031e2 <kerneltrap+0x38>

0000000080003276 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003276:	1101                	addi	sp,sp,-32
    80003278:	ec06                	sd	ra,24(sp)
    8000327a:	e822                	sd	s0,16(sp)
    8000327c:	e426                	sd	s1,8(sp)
    8000327e:	1000                	addi	s0,sp,32
    80003280:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003282:	fffff097          	auipc	ra,0xfffff
    80003286:	8e0080e7          	jalr	-1824(ra) # 80001b62 <myproc>
  switch (n) {
    8000328a:	4795                	li	a5,5
    8000328c:	0497e163          	bltu	a5,s1,800032ce <argraw+0x58>
    80003290:	048a                	slli	s1,s1,0x2
    80003292:	00005717          	auipc	a4,0x5
    80003296:	20670713          	addi	a4,a4,518 # 80008498 <states.0+0x170>
    8000329a:	94ba                	add	s1,s1,a4
    8000329c:	409c                	lw	a5,0(s1)
    8000329e:	97ba                	add	a5,a5,a4
    800032a0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032a2:	6d3c                	ld	a5,88(a0)
    800032a4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032a6:	60e2                	ld	ra,24(sp)
    800032a8:	6442                	ld	s0,16(sp)
    800032aa:	64a2                	ld	s1,8(sp)
    800032ac:	6105                	addi	sp,sp,32
    800032ae:	8082                	ret
    return p->trapframe->a1;
    800032b0:	6d3c                	ld	a5,88(a0)
    800032b2:	7fa8                	ld	a0,120(a5)
    800032b4:	bfcd                	j	800032a6 <argraw+0x30>
    return p->trapframe->a2;
    800032b6:	6d3c                	ld	a5,88(a0)
    800032b8:	63c8                	ld	a0,128(a5)
    800032ba:	b7f5                	j	800032a6 <argraw+0x30>
    return p->trapframe->a3;
    800032bc:	6d3c                	ld	a5,88(a0)
    800032be:	67c8                	ld	a0,136(a5)
    800032c0:	b7dd                	j	800032a6 <argraw+0x30>
    return p->trapframe->a4;
    800032c2:	6d3c                	ld	a5,88(a0)
    800032c4:	6bc8                	ld	a0,144(a5)
    800032c6:	b7c5                	j	800032a6 <argraw+0x30>
    return p->trapframe->a5;
    800032c8:	6d3c                	ld	a5,88(a0)
    800032ca:	6fc8                	ld	a0,152(a5)
    800032cc:	bfe9                	j	800032a6 <argraw+0x30>
  panic("argraw");
    800032ce:	00005517          	auipc	a0,0x5
    800032d2:	1a250513          	addi	a0,a0,418 # 80008470 <states.0+0x148>
    800032d6:	ffffd097          	auipc	ra,0xffffd
    800032da:	26a080e7          	jalr	618(ra) # 80000540 <panic>

00000000800032de <fetchaddr>:
{
    800032de:	1101                	addi	sp,sp,-32
    800032e0:	ec06                	sd	ra,24(sp)
    800032e2:	e822                	sd	s0,16(sp)
    800032e4:	e426                	sd	s1,8(sp)
    800032e6:	e04a                	sd	s2,0(sp)
    800032e8:	1000                	addi	s0,sp,32
    800032ea:	84aa                	mv	s1,a0
    800032ec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	874080e7          	jalr	-1932(ra) # 80001b62 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800032f6:	653c                	ld	a5,72(a0)
    800032f8:	02f4f863          	bgeu	s1,a5,80003328 <fetchaddr+0x4a>
    800032fc:	00848713          	addi	a4,s1,8
    80003300:	02e7e663          	bltu	a5,a4,8000332c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003304:	46a1                	li	a3,8
    80003306:	8626                	mv	a2,s1
    80003308:	85ca                	mv	a1,s2
    8000330a:	6928                	ld	a0,80(a0)
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	5a2080e7          	jalr	1442(ra) # 800018ae <copyin>
    80003314:	00a03533          	snez	a0,a0
    80003318:	40a00533          	neg	a0,a0
}
    8000331c:	60e2                	ld	ra,24(sp)
    8000331e:	6442                	ld	s0,16(sp)
    80003320:	64a2                	ld	s1,8(sp)
    80003322:	6902                	ld	s2,0(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret
    return -1;
    80003328:	557d                	li	a0,-1
    8000332a:	bfcd                	j	8000331c <fetchaddr+0x3e>
    8000332c:	557d                	li	a0,-1
    8000332e:	b7fd                	j	8000331c <fetchaddr+0x3e>

0000000080003330 <fetchstr>:
{
    80003330:	7179                	addi	sp,sp,-48
    80003332:	f406                	sd	ra,40(sp)
    80003334:	f022                	sd	s0,32(sp)
    80003336:	ec26                	sd	s1,24(sp)
    80003338:	e84a                	sd	s2,16(sp)
    8000333a:	e44e                	sd	s3,8(sp)
    8000333c:	1800                	addi	s0,sp,48
    8000333e:	892a                	mv	s2,a0
    80003340:	84ae                	mv	s1,a1
    80003342:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	81e080e7          	jalr	-2018(ra) # 80001b62 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000334c:	86ce                	mv	a3,s3
    8000334e:	864a                	mv	a2,s2
    80003350:	85a6                	mv	a1,s1
    80003352:	6928                	ld	a0,80(a0)
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	5e8080e7          	jalr	1512(ra) # 8000193c <copyinstr>
    8000335c:	00054e63          	bltz	a0,80003378 <fetchstr+0x48>
  return strlen(buf);
    80003360:	8526                	mv	a0,s1
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	be0080e7          	jalr	-1056(ra) # 80000f42 <strlen>
}
    8000336a:	70a2                	ld	ra,40(sp)
    8000336c:	7402                	ld	s0,32(sp)
    8000336e:	64e2                	ld	s1,24(sp)
    80003370:	6942                	ld	s2,16(sp)
    80003372:	69a2                	ld	s3,8(sp)
    80003374:	6145                	addi	sp,sp,48
    80003376:	8082                	ret
    return -1;
    80003378:	557d                	li	a0,-1
    8000337a:	bfc5                	j	8000336a <fetchstr+0x3a>

000000008000337c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	1000                	addi	s0,sp,32
    80003386:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	eee080e7          	jalr	-274(ra) # 80003276 <argraw>
    80003390:	c088                	sw	a0,0(s1)
}
    80003392:	60e2                	ld	ra,24(sp)
    80003394:	6442                	ld	s0,16(sp)
    80003396:	64a2                	ld	s1,8(sp)
    80003398:	6105                	addi	sp,sp,32
    8000339a:	8082                	ret

000000008000339c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000339c:	1101                	addi	sp,sp,-32
    8000339e:	ec06                	sd	ra,24(sp)
    800033a0:	e822                	sd	s0,16(sp)
    800033a2:	e426                	sd	s1,8(sp)
    800033a4:	1000                	addi	s0,sp,32
    800033a6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	ece080e7          	jalr	-306(ra) # 80003276 <argraw>
    800033b0:	e088                	sd	a0,0(s1)
}
    800033b2:	60e2                	ld	ra,24(sp)
    800033b4:	6442                	ld	s0,16(sp)
    800033b6:	64a2                	ld	s1,8(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret

00000000800033bc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033bc:	7179                	addi	sp,sp,-48
    800033be:	f406                	sd	ra,40(sp)
    800033c0:	f022                	sd	s0,32(sp)
    800033c2:	ec26                	sd	s1,24(sp)
    800033c4:	e84a                	sd	s2,16(sp)
    800033c6:	1800                	addi	s0,sp,48
    800033c8:	84ae                	mv	s1,a1
    800033ca:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800033cc:	fd840593          	addi	a1,s0,-40
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	fcc080e7          	jalr	-52(ra) # 8000339c <argaddr>
  return fetchstr(addr, buf, max);
    800033d8:	864a                	mv	a2,s2
    800033da:	85a6                	mv	a1,s1
    800033dc:	fd843503          	ld	a0,-40(s0)
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	f50080e7          	jalr	-176(ra) # 80003330 <fetchstr>
}
    800033e8:	70a2                	ld	ra,40(sp)
    800033ea:	7402                	ld	s0,32(sp)
    800033ec:	64e2                	ld	s1,24(sp)
    800033ee:	6942                	ld	s2,16(sp)
    800033f0:	6145                	addi	sp,sp,48
    800033f2:	8082                	ret

00000000800033f4 <syscall>:
[SYS_setpriority] sys_setpriority
};

void
syscall(void)
{
    800033f4:	1101                	addi	sp,sp,-32
    800033f6:	ec06                	sd	ra,24(sp)
    800033f8:	e822                	sd	s0,16(sp)
    800033fa:	e426                	sd	s1,8(sp)
    800033fc:	e04a                	sd	s2,0(sp)
    800033fe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	762080e7          	jalr	1890(ra) # 80001b62 <myproc>
    80003408:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000340a:	05853903          	ld	s2,88(a0)
    8000340e:	0a893783          	ld	a5,168(s2)
    80003412:	0007869b          	sext.w	a3,a5
  //num = * (int *) 0;

  if (num==SYS_read){
    80003416:	4715                	li	a4,5
    80003418:	02e68763          	beq	a3,a4,80003446 <syscall+0x52>
    readcount++;
  }

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000341c:	37fd                	addiw	a5,a5,-1
    8000341e:	4765                	li	a4,25
    80003420:	04f76663          	bltu	a4,a5,8000346c <syscall+0x78>
    80003424:	00369713          	slli	a4,a3,0x3
    80003428:	00005797          	auipc	a5,0x5
    8000342c:	08878793          	addi	a5,a5,136 # 800084b0 <syscalls>
    80003430:	97ba                	add	a5,a5,a4
    80003432:	6398                	ld	a4,0(a5)
    80003434:	cf05                	beqz	a4,8000346c <syscall+0x78>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    if(num != 25)
    80003436:	47e5                	li	a5,25
    80003438:	02f69663          	bne	a3,a5,80003464 <syscall+0x70>
    {
      p->trapframe->a0 = syscalls[num]();
    }
    else
    {
      syscalls[num]();
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	322080e7          	jalr	802(ra) # 8000375e <sys_sigreturn>
    80003444:	a091                	j	80003488 <syscall+0x94>
    readcount++;
    80003446:	00005617          	auipc	a2,0x5
    8000344a:	52e60613          	addi	a2,a2,1326 # 80008974 <readcount>
    8000344e:	4218                	lw	a4,0(a2)
    80003450:	2705                	addiw	a4,a4,1
    80003452:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003454:	37fd                	addiw	a5,a5,-1
    80003456:	4665                	li	a2,25
    80003458:	00002717          	auipc	a4,0x2
    8000345c:	74870713          	addi	a4,a4,1864 # 80005ba0 <sys_read>
    80003460:	00f66663          	bltu	a2,a5,8000346c <syscall+0x78>
      p->trapframe->a0 = syscalls[num]();
    80003464:	9702                	jalr	a4
    80003466:	06a93823          	sd	a0,112(s2)
    8000346a:	a839                	j	80003488 <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    8000346c:	15848613          	addi	a2,s1,344
    80003470:	588c                	lw	a1,48(s1)
    80003472:	00005517          	auipc	a0,0x5
    80003476:	00650513          	addi	a0,a0,6 # 80008478 <states.0+0x150>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	110080e7          	jalr	272(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003482:	6cbc                	ld	a5,88(s1)
    80003484:	577d                	li	a4,-1
    80003486:	fbb8                	sd	a4,112(a5)
  }
}
    80003488:	60e2                	ld	ra,24(sp)
    8000348a:	6442                	ld	s0,16(sp)
    8000348c:	64a2                	ld	s1,8(sp)
    8000348e:	6902                	ld	s2,0(sp)
    80003490:	6105                	addi	sp,sp,32
    80003492:	8082                	ret

0000000080003494 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003494:	1101                	addi	sp,sp,-32
    80003496:	ec06                	sd	ra,24(sp)
    80003498:	e822                	sd	s0,16(sp)
    8000349a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000349c:	fec40593          	addi	a1,s0,-20
    800034a0:	4501                	li	a0,0
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	eda080e7          	jalr	-294(ra) # 8000337c <argint>
  exit(n);
    800034aa:	fec42503          	lw	a0,-20(s0)
    800034ae:	fffff097          	auipc	ra,0xfffff
    800034b2:	056080e7          	jalr	86(ra) # 80002504 <exit>
  return 0; // not reached
}
    800034b6:	4501                	li	a0,0
    800034b8:	60e2                	ld	ra,24(sp)
    800034ba:	6442                	ld	s0,16(sp)
    800034bc:	6105                	addi	sp,sp,32
    800034be:	8082                	ret

00000000800034c0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800034c0:	1141                	addi	sp,sp,-16
    800034c2:	e406                	sd	ra,8(sp)
    800034c4:	e022                	sd	s0,0(sp)
    800034c6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034c8:	ffffe097          	auipc	ra,0xffffe
    800034cc:	69a080e7          	jalr	1690(ra) # 80001b62 <myproc>
}
    800034d0:	5908                	lw	a0,48(a0)
    800034d2:	60a2                	ld	ra,8(sp)
    800034d4:	6402                	ld	s0,0(sp)
    800034d6:	0141                	addi	sp,sp,16
    800034d8:	8082                	ret

00000000800034da <sys_fork>:

uint64
sys_fork(void)
{
    800034da:	1141                	addi	sp,sp,-16
    800034dc:	e406                	sd	ra,8(sp)
    800034de:	e022                	sd	s0,0(sp)
    800034e0:	0800                	addi	s0,sp,16
  return fork();
    800034e2:	fffff097          	auipc	ra,0xfffff
    800034e6:	aba080e7          	jalr	-1350(ra) # 80001f9c <fork>
}
    800034ea:	60a2                	ld	ra,8(sp)
    800034ec:	6402                	ld	s0,0(sp)
    800034ee:	0141                	addi	sp,sp,16
    800034f0:	8082                	ret

00000000800034f2 <sys_wait>:

uint64
sys_wait(void)
{
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800034fa:	fe840593          	addi	a1,s0,-24
    800034fe:	4501                	li	a0,0
    80003500:	00000097          	auipc	ra,0x0
    80003504:	e9c080e7          	jalr	-356(ra) # 8000339c <argaddr>
  return wait(p);
    80003508:	fe843503          	ld	a0,-24(s0)
    8000350c:	fffff097          	auipc	ra,0xfffff
    80003510:	1aa080e7          	jalr	426(ra) # 800026b6 <wait>
}
    80003514:	60e2                	ld	ra,24(sp)
    80003516:	6442                	ld	s0,16(sp)
    80003518:	6105                	addi	sp,sp,32
    8000351a:	8082                	ret

000000008000351c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000351c:	7179                	addi	sp,sp,-48
    8000351e:	f406                	sd	ra,40(sp)
    80003520:	f022                	sd	s0,32(sp)
    80003522:	ec26                	sd	s1,24(sp)
    80003524:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003526:	fdc40593          	addi	a1,s0,-36
    8000352a:	4501                	li	a0,0
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	e50080e7          	jalr	-432(ra) # 8000337c <argint>
  addr = myproc()->sz;
    80003534:	ffffe097          	auipc	ra,0xffffe
    80003538:	62e080e7          	jalr	1582(ra) # 80001b62 <myproc>
    8000353c:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000353e:	fdc42503          	lw	a0,-36(s0)
    80003542:	fffff097          	auipc	ra,0xfffff
    80003546:	9fe080e7          	jalr	-1538(ra) # 80001f40 <growproc>
    8000354a:	00054863          	bltz	a0,8000355a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000354e:	8526                	mv	a0,s1
    80003550:	70a2                	ld	ra,40(sp)
    80003552:	7402                	ld	s0,32(sp)
    80003554:	64e2                	ld	s1,24(sp)
    80003556:	6145                	addi	sp,sp,48
    80003558:	8082                	ret
    return -1;
    8000355a:	54fd                	li	s1,-1
    8000355c:	bfcd                	j	8000354e <sys_sbrk+0x32>

000000008000355e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000355e:	7139                	addi	sp,sp,-64
    80003560:	fc06                	sd	ra,56(sp)
    80003562:	f822                	sd	s0,48(sp)
    80003564:	f426                	sd	s1,40(sp)
    80003566:	f04a                	sd	s2,32(sp)
    80003568:	ec4e                	sd	s3,24(sp)
    8000356a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000356c:	fcc40593          	addi	a1,s0,-52
    80003570:	4501                	li	a0,0
    80003572:	00000097          	auipc	ra,0x0
    80003576:	e0a080e7          	jalr	-502(ra) # 8000337c <argint>
  acquire(&tickslock);
    8000357a:	00235517          	auipc	a0,0x235
    8000357e:	aae50513          	addi	a0,a0,-1362 # 80238028 <tickslock>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	748080e7          	jalr	1864(ra) # 80000cca <acquire>
  ticks0 = ticks;
    8000358a:	00005917          	auipc	s2,0x5
    8000358e:	3e692903          	lw	s2,998(s2) # 80008970 <ticks>
  while (ticks - ticks0 < n)
    80003592:	fcc42783          	lw	a5,-52(s0)
    80003596:	cf9d                	beqz	a5,800035d4 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003598:	00235997          	auipc	s3,0x235
    8000359c:	a9098993          	addi	s3,s3,-1392 # 80238028 <tickslock>
    800035a0:	00005497          	auipc	s1,0x5
    800035a4:	3d048493          	addi	s1,s1,976 # 80008970 <ticks>
    if (killed(myproc()))
    800035a8:	ffffe097          	auipc	ra,0xffffe
    800035ac:	5ba080e7          	jalr	1466(ra) # 80001b62 <myproc>
    800035b0:	fffff097          	auipc	ra,0xfffff
    800035b4:	0d4080e7          	jalr	212(ra) # 80002684 <killed>
    800035b8:	ed15                	bnez	a0,800035f4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800035ba:	85ce                	mv	a1,s3
    800035bc:	8526                	mv	a0,s1
    800035be:	fffff097          	auipc	ra,0xfffff
    800035c2:	e06080e7          	jalr	-506(ra) # 800023c4 <sleep>
  while (ticks - ticks0 < n)
    800035c6:	409c                	lw	a5,0(s1)
    800035c8:	412787bb          	subw	a5,a5,s2
    800035cc:	fcc42703          	lw	a4,-52(s0)
    800035d0:	fce7ece3          	bltu	a5,a4,800035a8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800035d4:	00235517          	auipc	a0,0x235
    800035d8:	a5450513          	addi	a0,a0,-1452 # 80238028 <tickslock>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	7a2080e7          	jalr	1954(ra) # 80000d7e <release>
  return 0;
    800035e4:	4501                	li	a0,0
}
    800035e6:	70e2                	ld	ra,56(sp)
    800035e8:	7442                	ld	s0,48(sp)
    800035ea:	74a2                	ld	s1,40(sp)
    800035ec:	7902                	ld	s2,32(sp)
    800035ee:	69e2                	ld	s3,24(sp)
    800035f0:	6121                	addi	sp,sp,64
    800035f2:	8082                	ret
      release(&tickslock);
    800035f4:	00235517          	auipc	a0,0x235
    800035f8:	a3450513          	addi	a0,a0,-1484 # 80238028 <tickslock>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	782080e7          	jalr	1922(ra) # 80000d7e <release>
      return -1;
    80003604:	557d                	li	a0,-1
    80003606:	b7c5                	j	800035e6 <sys_sleep+0x88>

0000000080003608 <sys_kill>:

uint64
sys_kill(void)
{
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003610:	fec40593          	addi	a1,s0,-20
    80003614:	4501                	li	a0,0
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	d66080e7          	jalr	-666(ra) # 8000337c <argint>
  return kill(pid);
    8000361e:	fec42503          	lw	a0,-20(s0)
    80003622:	fffff097          	auipc	ra,0xfffff
    80003626:	fc4080e7          	jalr	-60(ra) # 800025e6 <kill>
}
    8000362a:	60e2                	ld	ra,24(sp)
    8000362c:	6442                	ld	s0,16(sp)
    8000362e:	6105                	addi	sp,sp,32
    80003630:	8082                	ret

0000000080003632 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	e426                	sd	s1,8(sp)
    8000363a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000363c:	00235517          	auipc	a0,0x235
    80003640:	9ec50513          	addi	a0,a0,-1556 # 80238028 <tickslock>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	686080e7          	jalr	1670(ra) # 80000cca <acquire>
  xticks = ticks;
    8000364c:	00005497          	auipc	s1,0x5
    80003650:	3244a483          	lw	s1,804(s1) # 80008970 <ticks>
  release(&tickslock);
    80003654:	00235517          	auipc	a0,0x235
    80003658:	9d450513          	addi	a0,a0,-1580 # 80238028 <tickslock>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	722080e7          	jalr	1826(ra) # 80000d7e <release>
  return xticks;
}
    80003664:	02049513          	slli	a0,s1,0x20
    80003668:	9101                	srli	a0,a0,0x20
    8000366a:	60e2                	ld	ra,24(sp)
    8000366c:	6442                	ld	s0,16(sp)
    8000366e:	64a2                	ld	s1,8(sp)
    80003670:	6105                	addi	sp,sp,32
    80003672:	8082                	ret

0000000080003674 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003674:	7139                	addi	sp,sp,-64
    80003676:	fc06                	sd	ra,56(sp)
    80003678:	f822                	sd	s0,48(sp)
    8000367a:	f426                	sd	s1,40(sp)
    8000367c:	f04a                	sd	s2,32(sp)
    8000367e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003680:	fd840593          	addi	a1,s0,-40
    80003684:	4501                	li	a0,0
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	d16080e7          	jalr	-746(ra) # 8000339c <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000368e:	fd040593          	addi	a1,s0,-48
    80003692:	4505                	li	a0,1
    80003694:	00000097          	auipc	ra,0x0
    80003698:	d08080e7          	jalr	-760(ra) # 8000339c <argaddr>
  argaddr(2, &addr2);
    8000369c:	fc840593          	addi	a1,s0,-56
    800036a0:	4509                	li	a0,2
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	cfa080e7          	jalr	-774(ra) # 8000339c <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800036aa:	fc040613          	addi	a2,s0,-64
    800036ae:	fc440593          	addi	a1,s0,-60
    800036b2:	fd843503          	ld	a0,-40(s0)
    800036b6:	fffff097          	auipc	ra,0xfffff
    800036ba:	28a080e7          	jalr	650(ra) # 80002940 <waitx>
    800036be:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800036c0:	ffffe097          	auipc	ra,0xffffe
    800036c4:	4a2080e7          	jalr	1186(ra) # 80001b62 <myproc>
    800036c8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036ca:	4691                	li	a3,4
    800036cc:	fc440613          	addi	a2,s0,-60
    800036d0:	fd043583          	ld	a1,-48(s0)
    800036d4:	6928                	ld	a0,80(a0)
    800036d6:	ffffe097          	auipc	ra,0xffffe
    800036da:	086080e7          	jalr	134(ra) # 8000175c <copyout>
    return -1;
    800036de:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036e0:	00054f63          	bltz	a0,800036fe <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800036e4:	4691                	li	a3,4
    800036e6:	fc040613          	addi	a2,s0,-64
    800036ea:	fc843583          	ld	a1,-56(s0)
    800036ee:	68a8                	ld	a0,80(s1)
    800036f0:	ffffe097          	auipc	ra,0xffffe
    800036f4:	06c080e7          	jalr	108(ra) # 8000175c <copyout>
    800036f8:	00054a63          	bltz	a0,8000370c <sys_waitx+0x98>
    return -1;
  return ret;
    800036fc:	87ca                	mv	a5,s2
}
    800036fe:	853e                	mv	a0,a5
    80003700:	70e2                	ld	ra,56(sp)
    80003702:	7442                	ld	s0,48(sp)
    80003704:	74a2                	ld	s1,40(sp)
    80003706:	7902                	ld	s2,32(sp)
    80003708:	6121                	addi	sp,sp,64
    8000370a:	8082                	ret
    return -1;
    8000370c:	57fd                	li	a5,-1
    8000370e:	bfc5                	j	800036fe <sys_waitx+0x8a>

0000000080003710 <sys_sigalarm>:

//alarm amd return
uint64
sys_sigalarm(void)
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	1000                	addi	s0,sp,32
  uint64 handleraddr;
  int ticks;

  argint(0, &ticks);
    80003718:	fe440593          	addi	a1,s0,-28
    8000371c:	4501                	li	a0,0
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	c5e080e7          	jalr	-930(ra) # 8000337c <argint>
  argaddr(1, &handleraddr);
    80003726:	fe840593          	addi	a1,s0,-24
    8000372a:	4505                	li	a0,1
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	c70080e7          	jalr	-912(ra) # 8000339c <argaddr>

  myproc()->ticks = ticks;
    80003734:	ffffe097          	auipc	ra,0xffffe
    80003738:	42e080e7          	jalr	1070(ra) # 80001b62 <myproc>
    8000373c:	fe442783          	lw	a5,-28(s0)
    80003740:	18f52023          	sw	a5,384(a0)
  myproc()->handlerfn = handleraddr;
    80003744:	ffffe097          	auipc	ra,0xffffe
    80003748:	41e080e7          	jalr	1054(ra) # 80001b62 <myproc>
    8000374c:	fe843783          	ld	a5,-24(s0)
    80003750:	16f53c23          	sd	a5,376(a0)

  return 0;
}
    80003754:	4501                	li	a0,0
    80003756:	60e2                	ld	ra,24(sp)
    80003758:	6442                	ld	s0,16(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret

000000008000375e <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    8000375e:	1141                	addi	sp,sp,-16
    80003760:	e406                	sd	ra,8(sp)
    80003762:	e022                	sd	s0,0(sp)
    80003764:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003766:	ffffe097          	auipc	ra,0xffffe
    8000376a:	3fc080e7          	jalr	1020(ra) # 80001b62 <myproc>
  
  *p->trapframe= *p->alarmtrpfrm;
    8000376e:	18853683          	ld	a3,392(a0)
    80003772:	87b6                	mv	a5,a3
    80003774:	6d38                	ld	a4,88(a0)
    80003776:	12068693          	addi	a3,a3,288
    8000377a:	0007b883          	ld	a7,0(a5)
    8000377e:	0087b803          	ld	a6,8(a5)
    80003782:	6b8c                	ld	a1,16(a5)
    80003784:	6f90                	ld	a2,24(a5)
    80003786:	01173023          	sd	a7,0(a4)
    8000378a:	01073423          	sd	a6,8(a4)
    8000378e:	eb0c                	sd	a1,16(a4)
    80003790:	ef10                	sd	a2,24(a4)
    80003792:	02078793          	addi	a5,a5,32
    80003796:	02070713          	addi	a4,a4,32
    8000379a:	fed790e3          	bne	a5,a3,8000377a <sys_sigreturn+0x1c>

  p->alarm_flag = 0;
    8000379e:	18052823          	sw	zero,400(a0)
  p->currticks = 0;
    800037a2:	18052223          	sw	zero,388(a0)

  return 0;
}
    800037a6:	4501                	li	a0,0
    800037a8:	60a2                	ld	ra,8(sp)
    800037aa:	6402                	ld	s0,0(sp)
    800037ac:	0141                	addi	sp,sp,16
    800037ae:	8082                	ret

00000000800037b0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037b0:	7179                	addi	sp,sp,-48
    800037b2:	f406                	sd	ra,40(sp)
    800037b4:	f022                	sd	s0,32(sp)
    800037b6:	ec26                	sd	s1,24(sp)
    800037b8:	e84a                	sd	s2,16(sp)
    800037ba:	e44e                	sd	s3,8(sp)
    800037bc:	e052                	sd	s4,0(sp)
    800037be:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037c0:	00005597          	auipc	a1,0x5
    800037c4:	dc858593          	addi	a1,a1,-568 # 80008588 <syscalls+0xd8>
    800037c8:	00235517          	auipc	a0,0x235
    800037cc:	87850513          	addi	a0,a0,-1928 # 80238040 <bcache>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	46a080e7          	jalr	1130(ra) # 80000c3a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800037d8:	0023d797          	auipc	a5,0x23d
    800037dc:	86878793          	addi	a5,a5,-1944 # 80240040 <bcache+0x8000>
    800037e0:	0023d717          	auipc	a4,0x23d
    800037e4:	ac870713          	addi	a4,a4,-1336 # 802402a8 <bcache+0x8268>
    800037e8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800037ec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037f0:	00235497          	auipc	s1,0x235
    800037f4:	86848493          	addi	s1,s1,-1944 # 80238058 <bcache+0x18>
    b->next = bcache.head.next;
    800037f8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800037fa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800037fc:	00005a17          	auipc	s4,0x5
    80003800:	d94a0a13          	addi	s4,s4,-620 # 80008590 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003804:	2b893783          	ld	a5,696(s2)
    80003808:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000380a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000380e:	85d2                	mv	a1,s4
    80003810:	01048513          	addi	a0,s1,16
    80003814:	00001097          	auipc	ra,0x1
    80003818:	4c8080e7          	jalr	1224(ra) # 80004cdc <initsleeplock>
    bcache.head.next->prev = b;
    8000381c:	2b893783          	ld	a5,696(s2)
    80003820:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003822:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003826:	45848493          	addi	s1,s1,1112
    8000382a:	fd349de3          	bne	s1,s3,80003804 <binit+0x54>
  }
}
    8000382e:	70a2                	ld	ra,40(sp)
    80003830:	7402                	ld	s0,32(sp)
    80003832:	64e2                	ld	s1,24(sp)
    80003834:	6942                	ld	s2,16(sp)
    80003836:	69a2                	ld	s3,8(sp)
    80003838:	6a02                	ld	s4,0(sp)
    8000383a:	6145                	addi	sp,sp,48
    8000383c:	8082                	ret

000000008000383e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000383e:	7179                	addi	sp,sp,-48
    80003840:	f406                	sd	ra,40(sp)
    80003842:	f022                	sd	s0,32(sp)
    80003844:	ec26                	sd	s1,24(sp)
    80003846:	e84a                	sd	s2,16(sp)
    80003848:	e44e                	sd	s3,8(sp)
    8000384a:	1800                	addi	s0,sp,48
    8000384c:	892a                	mv	s2,a0
    8000384e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003850:	00234517          	auipc	a0,0x234
    80003854:	7f050513          	addi	a0,a0,2032 # 80238040 <bcache>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	472080e7          	jalr	1138(ra) # 80000cca <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003860:	0023d497          	auipc	s1,0x23d
    80003864:	a984b483          	ld	s1,-1384(s1) # 802402f8 <bcache+0x82b8>
    80003868:	0023d797          	auipc	a5,0x23d
    8000386c:	a4078793          	addi	a5,a5,-1472 # 802402a8 <bcache+0x8268>
    80003870:	02f48f63          	beq	s1,a5,800038ae <bread+0x70>
    80003874:	873e                	mv	a4,a5
    80003876:	a021                	j	8000387e <bread+0x40>
    80003878:	68a4                	ld	s1,80(s1)
    8000387a:	02e48a63          	beq	s1,a4,800038ae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000387e:	449c                	lw	a5,8(s1)
    80003880:	ff279ce3          	bne	a5,s2,80003878 <bread+0x3a>
    80003884:	44dc                	lw	a5,12(s1)
    80003886:	ff3799e3          	bne	a5,s3,80003878 <bread+0x3a>
      b->refcnt++;
    8000388a:	40bc                	lw	a5,64(s1)
    8000388c:	2785                	addiw	a5,a5,1
    8000388e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003890:	00234517          	auipc	a0,0x234
    80003894:	7b050513          	addi	a0,a0,1968 # 80238040 <bcache>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	4e6080e7          	jalr	1254(ra) # 80000d7e <release>
      acquiresleep(&b->lock);
    800038a0:	01048513          	addi	a0,s1,16
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	472080e7          	jalr	1138(ra) # 80004d16 <acquiresleep>
      return b;
    800038ac:	a8b9                	j	8000390a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038ae:	0023d497          	auipc	s1,0x23d
    800038b2:	a424b483          	ld	s1,-1470(s1) # 802402f0 <bcache+0x82b0>
    800038b6:	0023d797          	auipc	a5,0x23d
    800038ba:	9f278793          	addi	a5,a5,-1550 # 802402a8 <bcache+0x8268>
    800038be:	00f48863          	beq	s1,a5,800038ce <bread+0x90>
    800038c2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038c4:	40bc                	lw	a5,64(s1)
    800038c6:	cf81                	beqz	a5,800038de <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038c8:	64a4                	ld	s1,72(s1)
    800038ca:	fee49de3          	bne	s1,a4,800038c4 <bread+0x86>
  panic("bget: no buffers");
    800038ce:	00005517          	auipc	a0,0x5
    800038d2:	cca50513          	addi	a0,a0,-822 # 80008598 <syscalls+0xe8>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c6a080e7          	jalr	-918(ra) # 80000540 <panic>
      b->dev = dev;
    800038de:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800038e2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800038e6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800038ea:	4785                	li	a5,1
    800038ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038ee:	00234517          	auipc	a0,0x234
    800038f2:	75250513          	addi	a0,a0,1874 # 80238040 <bcache>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	488080e7          	jalr	1160(ra) # 80000d7e <release>
      acquiresleep(&b->lock);
    800038fe:	01048513          	addi	a0,s1,16
    80003902:	00001097          	auipc	ra,0x1
    80003906:	414080e7          	jalr	1044(ra) # 80004d16 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000390a:	409c                	lw	a5,0(s1)
    8000390c:	cb89                	beqz	a5,8000391e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000390e:	8526                	mv	a0,s1
    80003910:	70a2                	ld	ra,40(sp)
    80003912:	7402                	ld	s0,32(sp)
    80003914:	64e2                	ld	s1,24(sp)
    80003916:	6942                	ld	s2,16(sp)
    80003918:	69a2                	ld	s3,8(sp)
    8000391a:	6145                	addi	sp,sp,48
    8000391c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000391e:	4581                	li	a1,0
    80003920:	8526                	mv	a0,s1
    80003922:	00003097          	auipc	ra,0x3
    80003926:	050080e7          	jalr	80(ra) # 80006972 <virtio_disk_rw>
    b->valid = 1;
    8000392a:	4785                	li	a5,1
    8000392c:	c09c                	sw	a5,0(s1)
  return b;
    8000392e:	b7c5                	j	8000390e <bread+0xd0>

0000000080003930 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003930:	1101                	addi	sp,sp,-32
    80003932:	ec06                	sd	ra,24(sp)
    80003934:	e822                	sd	s0,16(sp)
    80003936:	e426                	sd	s1,8(sp)
    80003938:	1000                	addi	s0,sp,32
    8000393a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000393c:	0541                	addi	a0,a0,16
    8000393e:	00001097          	auipc	ra,0x1
    80003942:	472080e7          	jalr	1138(ra) # 80004db0 <holdingsleep>
    80003946:	cd01                	beqz	a0,8000395e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003948:	4585                	li	a1,1
    8000394a:	8526                	mv	a0,s1
    8000394c:	00003097          	auipc	ra,0x3
    80003950:	026080e7          	jalr	38(ra) # 80006972 <virtio_disk_rw>
}
    80003954:	60e2                	ld	ra,24(sp)
    80003956:	6442                	ld	s0,16(sp)
    80003958:	64a2                	ld	s1,8(sp)
    8000395a:	6105                	addi	sp,sp,32
    8000395c:	8082                	ret
    panic("bwrite");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	c5250513          	addi	a0,a0,-942 # 800085b0 <syscalls+0x100>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	bda080e7          	jalr	-1062(ra) # 80000540 <panic>

000000008000396e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000396e:	1101                	addi	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	e426                	sd	s1,8(sp)
    80003976:	e04a                	sd	s2,0(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000397c:	01050913          	addi	s2,a0,16
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	42e080e7          	jalr	1070(ra) # 80004db0 <holdingsleep>
    8000398a:	c92d                	beqz	a0,800039fc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	3de080e7          	jalr	990(ra) # 80004d6c <releasesleep>

  acquire(&bcache.lock);
    80003996:	00234517          	auipc	a0,0x234
    8000399a:	6aa50513          	addi	a0,a0,1706 # 80238040 <bcache>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	32c080e7          	jalr	812(ra) # 80000cca <acquire>
  b->refcnt--;
    800039a6:	40bc                	lw	a5,64(s1)
    800039a8:	37fd                	addiw	a5,a5,-1
    800039aa:	0007871b          	sext.w	a4,a5
    800039ae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039b0:	eb05                	bnez	a4,800039e0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039b2:	68bc                	ld	a5,80(s1)
    800039b4:	64b8                	ld	a4,72(s1)
    800039b6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039b8:	64bc                	ld	a5,72(s1)
    800039ba:	68b8                	ld	a4,80(s1)
    800039bc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039be:	0023c797          	auipc	a5,0x23c
    800039c2:	68278793          	addi	a5,a5,1666 # 80240040 <bcache+0x8000>
    800039c6:	2b87b703          	ld	a4,696(a5)
    800039ca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039cc:	0023d717          	auipc	a4,0x23d
    800039d0:	8dc70713          	addi	a4,a4,-1828 # 802402a8 <bcache+0x8268>
    800039d4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800039d6:	2b87b703          	ld	a4,696(a5)
    800039da:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800039dc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800039e0:	00234517          	auipc	a0,0x234
    800039e4:	66050513          	addi	a0,a0,1632 # 80238040 <bcache>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	396080e7          	jalr	918(ra) # 80000d7e <release>
}
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6902                	ld	s2,0(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret
    panic("brelse");
    800039fc:	00005517          	auipc	a0,0x5
    80003a00:	bbc50513          	addi	a0,a0,-1092 # 800085b8 <syscalls+0x108>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	b3c080e7          	jalr	-1220(ra) # 80000540 <panic>

0000000080003a0c <bpin>:

void
bpin(struct buf *b) {
    80003a0c:	1101                	addi	sp,sp,-32
    80003a0e:	ec06                	sd	ra,24(sp)
    80003a10:	e822                	sd	s0,16(sp)
    80003a12:	e426                	sd	s1,8(sp)
    80003a14:	1000                	addi	s0,sp,32
    80003a16:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a18:	00234517          	auipc	a0,0x234
    80003a1c:	62850513          	addi	a0,a0,1576 # 80238040 <bcache>
    80003a20:	ffffd097          	auipc	ra,0xffffd
    80003a24:	2aa080e7          	jalr	682(ra) # 80000cca <acquire>
  b->refcnt++;
    80003a28:	40bc                	lw	a5,64(s1)
    80003a2a:	2785                	addiw	a5,a5,1
    80003a2c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a2e:	00234517          	auipc	a0,0x234
    80003a32:	61250513          	addi	a0,a0,1554 # 80238040 <bcache>
    80003a36:	ffffd097          	auipc	ra,0xffffd
    80003a3a:	348080e7          	jalr	840(ra) # 80000d7e <release>
}
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	64a2                	ld	s1,8(sp)
    80003a44:	6105                	addi	sp,sp,32
    80003a46:	8082                	ret

0000000080003a48 <bunpin>:

void
bunpin(struct buf *b) {
    80003a48:	1101                	addi	sp,sp,-32
    80003a4a:	ec06                	sd	ra,24(sp)
    80003a4c:	e822                	sd	s0,16(sp)
    80003a4e:	e426                	sd	s1,8(sp)
    80003a50:	1000                	addi	s0,sp,32
    80003a52:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a54:	00234517          	auipc	a0,0x234
    80003a58:	5ec50513          	addi	a0,a0,1516 # 80238040 <bcache>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	26e080e7          	jalr	622(ra) # 80000cca <acquire>
  b->refcnt--;
    80003a64:	40bc                	lw	a5,64(s1)
    80003a66:	37fd                	addiw	a5,a5,-1
    80003a68:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a6a:	00234517          	auipc	a0,0x234
    80003a6e:	5d650513          	addi	a0,a0,1494 # 80238040 <bcache>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	30c080e7          	jalr	780(ra) # 80000d7e <release>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret

0000000080003a84 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a84:	1101                	addi	sp,sp,-32
    80003a86:	ec06                	sd	ra,24(sp)
    80003a88:	e822                	sd	s0,16(sp)
    80003a8a:	e426                	sd	s1,8(sp)
    80003a8c:	e04a                	sd	s2,0(sp)
    80003a8e:	1000                	addi	s0,sp,32
    80003a90:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a92:	00d5d59b          	srliw	a1,a1,0xd
    80003a96:	0023d797          	auipc	a5,0x23d
    80003a9a:	c867a783          	lw	a5,-890(a5) # 8024071c <sb+0x1c>
    80003a9e:	9dbd                	addw	a1,a1,a5
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	d9e080e7          	jalr	-610(ra) # 8000383e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003aa8:	0074f713          	andi	a4,s1,7
    80003aac:	4785                	li	a5,1
    80003aae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003ab2:	14ce                	slli	s1,s1,0x33
    80003ab4:	90d9                	srli	s1,s1,0x36
    80003ab6:	00950733          	add	a4,a0,s1
    80003aba:	05874703          	lbu	a4,88(a4)
    80003abe:	00e7f6b3          	and	a3,a5,a4
    80003ac2:	c69d                	beqz	a3,80003af0 <bfree+0x6c>
    80003ac4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003ac6:	94aa                	add	s1,s1,a0
    80003ac8:	fff7c793          	not	a5,a5
    80003acc:	8f7d                	and	a4,a4,a5
    80003ace:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	126080e7          	jalr	294(ra) # 80004bf8 <log_write>
  brelse(bp);
    80003ada:	854a                	mv	a0,s2
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	e92080e7          	jalr	-366(ra) # 8000396e <brelse>
}
    80003ae4:	60e2                	ld	ra,24(sp)
    80003ae6:	6442                	ld	s0,16(sp)
    80003ae8:	64a2                	ld	s1,8(sp)
    80003aea:	6902                	ld	s2,0(sp)
    80003aec:	6105                	addi	sp,sp,32
    80003aee:	8082                	ret
    panic("freeing free block");
    80003af0:	00005517          	auipc	a0,0x5
    80003af4:	ad050513          	addi	a0,a0,-1328 # 800085c0 <syscalls+0x110>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	a48080e7          	jalr	-1464(ra) # 80000540 <panic>

0000000080003b00 <balloc>:
{
    80003b00:	711d                	addi	sp,sp,-96
    80003b02:	ec86                	sd	ra,88(sp)
    80003b04:	e8a2                	sd	s0,80(sp)
    80003b06:	e4a6                	sd	s1,72(sp)
    80003b08:	e0ca                	sd	s2,64(sp)
    80003b0a:	fc4e                	sd	s3,56(sp)
    80003b0c:	f852                	sd	s4,48(sp)
    80003b0e:	f456                	sd	s5,40(sp)
    80003b10:	f05a                	sd	s6,32(sp)
    80003b12:	ec5e                	sd	s7,24(sp)
    80003b14:	e862                	sd	s8,16(sp)
    80003b16:	e466                	sd	s9,8(sp)
    80003b18:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b1a:	0023d797          	auipc	a5,0x23d
    80003b1e:	bea7a783          	lw	a5,-1046(a5) # 80240704 <sb+0x4>
    80003b22:	cff5                	beqz	a5,80003c1e <balloc+0x11e>
    80003b24:	8baa                	mv	s7,a0
    80003b26:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b28:	0023db17          	auipc	s6,0x23d
    80003b2c:	bd8b0b13          	addi	s6,s6,-1064 # 80240700 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b30:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b32:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b34:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b36:	6c89                	lui	s9,0x2
    80003b38:	a061                	j	80003bc0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b3a:	97ca                	add	a5,a5,s2
    80003b3c:	8e55                	or	a2,a2,a3
    80003b3e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	0b4080e7          	jalr	180(ra) # 80004bf8 <log_write>
        brelse(bp);
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	e20080e7          	jalr	-480(ra) # 8000396e <brelse>
  bp = bread(dev, bno);
    80003b56:	85a6                	mv	a1,s1
    80003b58:	855e                	mv	a0,s7
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	ce4080e7          	jalr	-796(ra) # 8000383e <bread>
    80003b62:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b64:	40000613          	li	a2,1024
    80003b68:	4581                	li	a1,0
    80003b6a:	05850513          	addi	a0,a0,88
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	258080e7          	jalr	600(ra) # 80000dc6 <memset>
  log_write(bp);
    80003b76:	854a                	mv	a0,s2
    80003b78:	00001097          	auipc	ra,0x1
    80003b7c:	080080e7          	jalr	128(ra) # 80004bf8 <log_write>
  brelse(bp);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	dec080e7          	jalr	-532(ra) # 8000396e <brelse>
}
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	60e6                	ld	ra,88(sp)
    80003b8e:	6446                	ld	s0,80(sp)
    80003b90:	64a6                	ld	s1,72(sp)
    80003b92:	6906                	ld	s2,64(sp)
    80003b94:	79e2                	ld	s3,56(sp)
    80003b96:	7a42                	ld	s4,48(sp)
    80003b98:	7aa2                	ld	s5,40(sp)
    80003b9a:	7b02                	ld	s6,32(sp)
    80003b9c:	6be2                	ld	s7,24(sp)
    80003b9e:	6c42                	ld	s8,16(sp)
    80003ba0:	6ca2                	ld	s9,8(sp)
    80003ba2:	6125                	addi	sp,sp,96
    80003ba4:	8082                	ret
    brelse(bp);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	dc6080e7          	jalr	-570(ra) # 8000396e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003bb0:	015c87bb          	addw	a5,s9,s5
    80003bb4:	00078a9b          	sext.w	s5,a5
    80003bb8:	004b2703          	lw	a4,4(s6)
    80003bbc:	06eaf163          	bgeu	s5,a4,80003c1e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003bc0:	41fad79b          	sraiw	a5,s5,0x1f
    80003bc4:	0137d79b          	srliw	a5,a5,0x13
    80003bc8:	015787bb          	addw	a5,a5,s5
    80003bcc:	40d7d79b          	sraiw	a5,a5,0xd
    80003bd0:	01cb2583          	lw	a1,28(s6)
    80003bd4:	9dbd                	addw	a1,a1,a5
    80003bd6:	855e                	mv	a0,s7
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	c66080e7          	jalr	-922(ra) # 8000383e <bread>
    80003be0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003be2:	004b2503          	lw	a0,4(s6)
    80003be6:	000a849b          	sext.w	s1,s5
    80003bea:	8762                	mv	a4,s8
    80003bec:	faa4fde3          	bgeu	s1,a0,80003ba6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003bf0:	00777693          	andi	a3,a4,7
    80003bf4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003bf8:	41f7579b          	sraiw	a5,a4,0x1f
    80003bfc:	01d7d79b          	srliw	a5,a5,0x1d
    80003c00:	9fb9                	addw	a5,a5,a4
    80003c02:	4037d79b          	sraiw	a5,a5,0x3
    80003c06:	00f90633          	add	a2,s2,a5
    80003c0a:	05864603          	lbu	a2,88(a2)
    80003c0e:	00c6f5b3          	and	a1,a3,a2
    80003c12:	d585                	beqz	a1,80003b3a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c14:	2705                	addiw	a4,a4,1
    80003c16:	2485                	addiw	s1,s1,1
    80003c18:	fd471ae3          	bne	a4,s4,80003bec <balloc+0xec>
    80003c1c:	b769                	j	80003ba6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003c1e:	00005517          	auipc	a0,0x5
    80003c22:	9ba50513          	addi	a0,a0,-1606 # 800085d8 <syscalls+0x128>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	964080e7          	jalr	-1692(ra) # 8000058a <printf>
  return 0;
    80003c2e:	4481                	li	s1,0
    80003c30:	bfa9                	j	80003b8a <balloc+0x8a>

0000000080003c32 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c32:	7179                	addi	sp,sp,-48
    80003c34:	f406                	sd	ra,40(sp)
    80003c36:	f022                	sd	s0,32(sp)
    80003c38:	ec26                	sd	s1,24(sp)
    80003c3a:	e84a                	sd	s2,16(sp)
    80003c3c:	e44e                	sd	s3,8(sp)
    80003c3e:	e052                	sd	s4,0(sp)
    80003c40:	1800                	addi	s0,sp,48
    80003c42:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c44:	47ad                	li	a5,11
    80003c46:	02b7e863          	bltu	a5,a1,80003c76 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003c4a:	02059793          	slli	a5,a1,0x20
    80003c4e:	01e7d593          	srli	a1,a5,0x1e
    80003c52:	00b504b3          	add	s1,a0,a1
    80003c56:	0504a903          	lw	s2,80(s1)
    80003c5a:	06091e63          	bnez	s2,80003cd6 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003c5e:	4108                	lw	a0,0(a0)
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	ea0080e7          	jalr	-352(ra) # 80003b00 <balloc>
    80003c68:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c6c:	06090563          	beqz	s2,80003cd6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003c70:	0524a823          	sw	s2,80(s1)
    80003c74:	a08d                	j	80003cd6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003c76:	ff45849b          	addiw	s1,a1,-12
    80003c7a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c7e:	0ff00793          	li	a5,255
    80003c82:	08e7e563          	bltu	a5,a4,80003d0c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003c86:	08052903          	lw	s2,128(a0)
    80003c8a:	00091d63          	bnez	s2,80003ca4 <bmap+0x72>
      addr = balloc(ip->dev);
    80003c8e:	4108                	lw	a0,0(a0)
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	e70080e7          	jalr	-400(ra) # 80003b00 <balloc>
    80003c98:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c9c:	02090d63          	beqz	s2,80003cd6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003ca0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003ca4:	85ca                	mv	a1,s2
    80003ca6:	0009a503          	lw	a0,0(s3)
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	b94080e7          	jalr	-1132(ra) # 8000383e <bread>
    80003cb2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003cb4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003cb8:	02049713          	slli	a4,s1,0x20
    80003cbc:	01e75593          	srli	a1,a4,0x1e
    80003cc0:	00b784b3          	add	s1,a5,a1
    80003cc4:	0004a903          	lw	s2,0(s1)
    80003cc8:	02090063          	beqz	s2,80003ce8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003ccc:	8552                	mv	a0,s4
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	ca0080e7          	jalr	-864(ra) # 8000396e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	70a2                	ld	ra,40(sp)
    80003cda:	7402                	ld	s0,32(sp)
    80003cdc:	64e2                	ld	s1,24(sp)
    80003cde:	6942                	ld	s2,16(sp)
    80003ce0:	69a2                	ld	s3,8(sp)
    80003ce2:	6a02                	ld	s4,0(sp)
    80003ce4:	6145                	addi	sp,sp,48
    80003ce6:	8082                	ret
      addr = balloc(ip->dev);
    80003ce8:	0009a503          	lw	a0,0(s3)
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	e14080e7          	jalr	-492(ra) # 80003b00 <balloc>
    80003cf4:	0005091b          	sext.w	s2,a0
      if(addr){
    80003cf8:	fc090ae3          	beqz	s2,80003ccc <bmap+0x9a>
        a[bn] = addr;
    80003cfc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003d00:	8552                	mv	a0,s4
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	ef6080e7          	jalr	-266(ra) # 80004bf8 <log_write>
    80003d0a:	b7c9                	j	80003ccc <bmap+0x9a>
  panic("bmap: out of range");
    80003d0c:	00005517          	auipc	a0,0x5
    80003d10:	8e450513          	addi	a0,a0,-1820 # 800085f0 <syscalls+0x140>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	82c080e7          	jalr	-2004(ra) # 80000540 <panic>

0000000080003d1c <iget>:
{
    80003d1c:	7179                	addi	sp,sp,-48
    80003d1e:	f406                	sd	ra,40(sp)
    80003d20:	f022                	sd	s0,32(sp)
    80003d22:	ec26                	sd	s1,24(sp)
    80003d24:	e84a                	sd	s2,16(sp)
    80003d26:	e44e                	sd	s3,8(sp)
    80003d28:	e052                	sd	s4,0(sp)
    80003d2a:	1800                	addi	s0,sp,48
    80003d2c:	89aa                	mv	s3,a0
    80003d2e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d30:	0023d517          	auipc	a0,0x23d
    80003d34:	9f050513          	addi	a0,a0,-1552 # 80240720 <itable>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	f92080e7          	jalr	-110(ra) # 80000cca <acquire>
  empty = 0;
    80003d40:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d42:	0023d497          	auipc	s1,0x23d
    80003d46:	9f648493          	addi	s1,s1,-1546 # 80240738 <itable+0x18>
    80003d4a:	0023e697          	auipc	a3,0x23e
    80003d4e:	47e68693          	addi	a3,a3,1150 # 802421c8 <log>
    80003d52:	a039                	j	80003d60 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d54:	02090b63          	beqz	s2,80003d8a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d58:	08848493          	addi	s1,s1,136
    80003d5c:	02d48a63          	beq	s1,a3,80003d90 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d60:	449c                	lw	a5,8(s1)
    80003d62:	fef059e3          	blez	a5,80003d54 <iget+0x38>
    80003d66:	4098                	lw	a4,0(s1)
    80003d68:	ff3716e3          	bne	a4,s3,80003d54 <iget+0x38>
    80003d6c:	40d8                	lw	a4,4(s1)
    80003d6e:	ff4713e3          	bne	a4,s4,80003d54 <iget+0x38>
      ip->ref++;
    80003d72:	2785                	addiw	a5,a5,1
    80003d74:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d76:	0023d517          	auipc	a0,0x23d
    80003d7a:	9aa50513          	addi	a0,a0,-1622 # 80240720 <itable>
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	000080e7          	jalr	ra # 80000d7e <release>
      return ip;
    80003d86:	8926                	mv	s2,s1
    80003d88:	a03d                	j	80003db6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d8a:	f7f9                	bnez	a5,80003d58 <iget+0x3c>
    80003d8c:	8926                	mv	s2,s1
    80003d8e:	b7e9                	j	80003d58 <iget+0x3c>
  if(empty == 0)
    80003d90:	02090c63          	beqz	s2,80003dc8 <iget+0xac>
  ip->dev = dev;
    80003d94:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d98:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d9c:	4785                	li	a5,1
    80003d9e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003da2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003da6:	0023d517          	auipc	a0,0x23d
    80003daa:	97a50513          	addi	a0,a0,-1670 # 80240720 <itable>
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	fd0080e7          	jalr	-48(ra) # 80000d7e <release>
}
    80003db6:	854a                	mv	a0,s2
    80003db8:	70a2                	ld	ra,40(sp)
    80003dba:	7402                	ld	s0,32(sp)
    80003dbc:	64e2                	ld	s1,24(sp)
    80003dbe:	6942                	ld	s2,16(sp)
    80003dc0:	69a2                	ld	s3,8(sp)
    80003dc2:	6a02                	ld	s4,0(sp)
    80003dc4:	6145                	addi	sp,sp,48
    80003dc6:	8082                	ret
    panic("iget: no inodes");
    80003dc8:	00005517          	auipc	a0,0x5
    80003dcc:	84050513          	addi	a0,a0,-1984 # 80008608 <syscalls+0x158>
    80003dd0:	ffffc097          	auipc	ra,0xffffc
    80003dd4:	770080e7          	jalr	1904(ra) # 80000540 <panic>

0000000080003dd8 <fsinit>:
fsinit(int dev) {
    80003dd8:	7179                	addi	sp,sp,-48
    80003dda:	f406                	sd	ra,40(sp)
    80003ddc:	f022                	sd	s0,32(sp)
    80003dde:	ec26                	sd	s1,24(sp)
    80003de0:	e84a                	sd	s2,16(sp)
    80003de2:	e44e                	sd	s3,8(sp)
    80003de4:	1800                	addi	s0,sp,48
    80003de6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003de8:	4585                	li	a1,1
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	a54080e7          	jalr	-1452(ra) # 8000383e <bread>
    80003df2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003df4:	0023d997          	auipc	s3,0x23d
    80003df8:	90c98993          	addi	s3,s3,-1780 # 80240700 <sb>
    80003dfc:	02000613          	li	a2,32
    80003e00:	05850593          	addi	a1,a0,88
    80003e04:	854e                	mv	a0,s3
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	01c080e7          	jalr	28(ra) # 80000e22 <memmove>
  brelse(bp);
    80003e0e:	8526                	mv	a0,s1
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	b5e080e7          	jalr	-1186(ra) # 8000396e <brelse>
  if(sb.magic != FSMAGIC)
    80003e18:	0009a703          	lw	a4,0(s3)
    80003e1c:	102037b7          	lui	a5,0x10203
    80003e20:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e24:	02f71263          	bne	a4,a5,80003e48 <fsinit+0x70>
  initlog(dev, &sb);
    80003e28:	0023d597          	auipc	a1,0x23d
    80003e2c:	8d858593          	addi	a1,a1,-1832 # 80240700 <sb>
    80003e30:	854a                	mv	a0,s2
    80003e32:	00001097          	auipc	ra,0x1
    80003e36:	b4a080e7          	jalr	-1206(ra) # 8000497c <initlog>
}
    80003e3a:	70a2                	ld	ra,40(sp)
    80003e3c:	7402                	ld	s0,32(sp)
    80003e3e:	64e2                	ld	s1,24(sp)
    80003e40:	6942                	ld	s2,16(sp)
    80003e42:	69a2                	ld	s3,8(sp)
    80003e44:	6145                	addi	sp,sp,48
    80003e46:	8082                	ret
    panic("invalid file system");
    80003e48:	00004517          	auipc	a0,0x4
    80003e4c:	7d050513          	addi	a0,a0,2000 # 80008618 <syscalls+0x168>
    80003e50:	ffffc097          	auipc	ra,0xffffc
    80003e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>

0000000080003e58 <iinit>:
{
    80003e58:	7179                	addi	sp,sp,-48
    80003e5a:	f406                	sd	ra,40(sp)
    80003e5c:	f022                	sd	s0,32(sp)
    80003e5e:	ec26                	sd	s1,24(sp)
    80003e60:	e84a                	sd	s2,16(sp)
    80003e62:	e44e                	sd	s3,8(sp)
    80003e64:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e66:	00004597          	auipc	a1,0x4
    80003e6a:	7ca58593          	addi	a1,a1,1994 # 80008630 <syscalls+0x180>
    80003e6e:	0023d517          	auipc	a0,0x23d
    80003e72:	8b250513          	addi	a0,a0,-1870 # 80240720 <itable>
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	dc4080e7          	jalr	-572(ra) # 80000c3a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e7e:	0023d497          	auipc	s1,0x23d
    80003e82:	8ca48493          	addi	s1,s1,-1846 # 80240748 <itable+0x28>
    80003e86:	0023e997          	auipc	s3,0x23e
    80003e8a:	35298993          	addi	s3,s3,850 # 802421d8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e8e:	00004917          	auipc	s2,0x4
    80003e92:	7aa90913          	addi	s2,s2,1962 # 80008638 <syscalls+0x188>
    80003e96:	85ca                	mv	a1,s2
    80003e98:	8526                	mv	a0,s1
    80003e9a:	00001097          	auipc	ra,0x1
    80003e9e:	e42080e7          	jalr	-446(ra) # 80004cdc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ea2:	08848493          	addi	s1,s1,136
    80003ea6:	ff3498e3          	bne	s1,s3,80003e96 <iinit+0x3e>
}
    80003eaa:	70a2                	ld	ra,40(sp)
    80003eac:	7402                	ld	s0,32(sp)
    80003eae:	64e2                	ld	s1,24(sp)
    80003eb0:	6942                	ld	s2,16(sp)
    80003eb2:	69a2                	ld	s3,8(sp)
    80003eb4:	6145                	addi	sp,sp,48
    80003eb6:	8082                	ret

0000000080003eb8 <ialloc>:
{
    80003eb8:	715d                	addi	sp,sp,-80
    80003eba:	e486                	sd	ra,72(sp)
    80003ebc:	e0a2                	sd	s0,64(sp)
    80003ebe:	fc26                	sd	s1,56(sp)
    80003ec0:	f84a                	sd	s2,48(sp)
    80003ec2:	f44e                	sd	s3,40(sp)
    80003ec4:	f052                	sd	s4,32(sp)
    80003ec6:	ec56                	sd	s5,24(sp)
    80003ec8:	e85a                	sd	s6,16(sp)
    80003eca:	e45e                	sd	s7,8(sp)
    80003ecc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ece:	0023d717          	auipc	a4,0x23d
    80003ed2:	83e72703          	lw	a4,-1986(a4) # 8024070c <sb+0xc>
    80003ed6:	4785                	li	a5,1
    80003ed8:	04e7fa63          	bgeu	a5,a4,80003f2c <ialloc+0x74>
    80003edc:	8aaa                	mv	s5,a0
    80003ede:	8bae                	mv	s7,a1
    80003ee0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ee2:	0023da17          	auipc	s4,0x23d
    80003ee6:	81ea0a13          	addi	s4,s4,-2018 # 80240700 <sb>
    80003eea:	00048b1b          	sext.w	s6,s1
    80003eee:	0044d593          	srli	a1,s1,0x4
    80003ef2:	018a2783          	lw	a5,24(s4)
    80003ef6:	9dbd                	addw	a1,a1,a5
    80003ef8:	8556                	mv	a0,s5
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	944080e7          	jalr	-1724(ra) # 8000383e <bread>
    80003f02:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003f04:	05850993          	addi	s3,a0,88
    80003f08:	00f4f793          	andi	a5,s1,15
    80003f0c:	079a                	slli	a5,a5,0x6
    80003f0e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f10:	00099783          	lh	a5,0(s3)
    80003f14:	c3a1                	beqz	a5,80003f54 <ialloc+0x9c>
    brelse(bp);
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	a58080e7          	jalr	-1448(ra) # 8000396e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f1e:	0485                	addi	s1,s1,1
    80003f20:	00ca2703          	lw	a4,12(s4)
    80003f24:	0004879b          	sext.w	a5,s1
    80003f28:	fce7e1e3          	bltu	a5,a4,80003eea <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003f2c:	00004517          	auipc	a0,0x4
    80003f30:	71450513          	addi	a0,a0,1812 # 80008640 <syscalls+0x190>
    80003f34:	ffffc097          	auipc	ra,0xffffc
    80003f38:	656080e7          	jalr	1622(ra) # 8000058a <printf>
  return 0;
    80003f3c:	4501                	li	a0,0
}
    80003f3e:	60a6                	ld	ra,72(sp)
    80003f40:	6406                	ld	s0,64(sp)
    80003f42:	74e2                	ld	s1,56(sp)
    80003f44:	7942                	ld	s2,48(sp)
    80003f46:	79a2                	ld	s3,40(sp)
    80003f48:	7a02                	ld	s4,32(sp)
    80003f4a:	6ae2                	ld	s5,24(sp)
    80003f4c:	6b42                	ld	s6,16(sp)
    80003f4e:	6ba2                	ld	s7,8(sp)
    80003f50:	6161                	addi	sp,sp,80
    80003f52:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003f54:	04000613          	li	a2,64
    80003f58:	4581                	li	a1,0
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	e6a080e7          	jalr	-406(ra) # 80000dc6 <memset>
      dip->type = type;
    80003f64:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f68:	854a                	mv	a0,s2
    80003f6a:	00001097          	auipc	ra,0x1
    80003f6e:	c8e080e7          	jalr	-882(ra) # 80004bf8 <log_write>
      brelse(bp);
    80003f72:	854a                	mv	a0,s2
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	9fa080e7          	jalr	-1542(ra) # 8000396e <brelse>
      return iget(dev, inum);
    80003f7c:	85da                	mv	a1,s6
    80003f7e:	8556                	mv	a0,s5
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	d9c080e7          	jalr	-612(ra) # 80003d1c <iget>
    80003f88:	bf5d                	j	80003f3e <ialloc+0x86>

0000000080003f8a <iupdate>:
{
    80003f8a:	1101                	addi	sp,sp,-32
    80003f8c:	ec06                	sd	ra,24(sp)
    80003f8e:	e822                	sd	s0,16(sp)
    80003f90:	e426                	sd	s1,8(sp)
    80003f92:	e04a                	sd	s2,0(sp)
    80003f94:	1000                	addi	s0,sp,32
    80003f96:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f98:	415c                	lw	a5,4(a0)
    80003f9a:	0047d79b          	srliw	a5,a5,0x4
    80003f9e:	0023c597          	auipc	a1,0x23c
    80003fa2:	77a5a583          	lw	a1,1914(a1) # 80240718 <sb+0x18>
    80003fa6:	9dbd                	addw	a1,a1,a5
    80003fa8:	4108                	lw	a0,0(a0)
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	894080e7          	jalr	-1900(ra) # 8000383e <bread>
    80003fb2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fb4:	05850793          	addi	a5,a0,88
    80003fb8:	40d8                	lw	a4,4(s1)
    80003fba:	8b3d                	andi	a4,a4,15
    80003fbc:	071a                	slli	a4,a4,0x6
    80003fbe:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003fc0:	04449703          	lh	a4,68(s1)
    80003fc4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003fc8:	04649703          	lh	a4,70(s1)
    80003fcc:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003fd0:	04849703          	lh	a4,72(s1)
    80003fd4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003fd8:	04a49703          	lh	a4,74(s1)
    80003fdc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003fe0:	44f8                	lw	a4,76(s1)
    80003fe2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003fe4:	03400613          	li	a2,52
    80003fe8:	05048593          	addi	a1,s1,80
    80003fec:	00c78513          	addi	a0,a5,12
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	e32080e7          	jalr	-462(ra) # 80000e22 <memmove>
  log_write(bp);
    80003ff8:	854a                	mv	a0,s2
    80003ffa:	00001097          	auipc	ra,0x1
    80003ffe:	bfe080e7          	jalr	-1026(ra) # 80004bf8 <log_write>
  brelse(bp);
    80004002:	854a                	mv	a0,s2
    80004004:	00000097          	auipc	ra,0x0
    80004008:	96a080e7          	jalr	-1686(ra) # 8000396e <brelse>
}
    8000400c:	60e2                	ld	ra,24(sp)
    8000400e:	6442                	ld	s0,16(sp)
    80004010:	64a2                	ld	s1,8(sp)
    80004012:	6902                	ld	s2,0(sp)
    80004014:	6105                	addi	sp,sp,32
    80004016:	8082                	ret

0000000080004018 <idup>:
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	e426                	sd	s1,8(sp)
    80004020:	1000                	addi	s0,sp,32
    80004022:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004024:	0023c517          	auipc	a0,0x23c
    80004028:	6fc50513          	addi	a0,a0,1788 # 80240720 <itable>
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	c9e080e7          	jalr	-866(ra) # 80000cca <acquire>
  ip->ref++;
    80004034:	449c                	lw	a5,8(s1)
    80004036:	2785                	addiw	a5,a5,1
    80004038:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000403a:	0023c517          	auipc	a0,0x23c
    8000403e:	6e650513          	addi	a0,a0,1766 # 80240720 <itable>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	d3c080e7          	jalr	-708(ra) # 80000d7e <release>
}
    8000404a:	8526                	mv	a0,s1
    8000404c:	60e2                	ld	ra,24(sp)
    8000404e:	6442                	ld	s0,16(sp)
    80004050:	64a2                	ld	s1,8(sp)
    80004052:	6105                	addi	sp,sp,32
    80004054:	8082                	ret

0000000080004056 <ilock>:
{
    80004056:	1101                	addi	sp,sp,-32
    80004058:	ec06                	sd	ra,24(sp)
    8000405a:	e822                	sd	s0,16(sp)
    8000405c:	e426                	sd	s1,8(sp)
    8000405e:	e04a                	sd	s2,0(sp)
    80004060:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004062:	c115                	beqz	a0,80004086 <ilock+0x30>
    80004064:	84aa                	mv	s1,a0
    80004066:	451c                	lw	a5,8(a0)
    80004068:	00f05f63          	blez	a5,80004086 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000406c:	0541                	addi	a0,a0,16
    8000406e:	00001097          	auipc	ra,0x1
    80004072:	ca8080e7          	jalr	-856(ra) # 80004d16 <acquiresleep>
  if(ip->valid == 0){
    80004076:	40bc                	lw	a5,64(s1)
    80004078:	cf99                	beqz	a5,80004096 <ilock+0x40>
}
    8000407a:	60e2                	ld	ra,24(sp)
    8000407c:	6442                	ld	s0,16(sp)
    8000407e:	64a2                	ld	s1,8(sp)
    80004080:	6902                	ld	s2,0(sp)
    80004082:	6105                	addi	sp,sp,32
    80004084:	8082                	ret
    panic("ilock");
    80004086:	00004517          	auipc	a0,0x4
    8000408a:	5d250513          	addi	a0,a0,1490 # 80008658 <syscalls+0x1a8>
    8000408e:	ffffc097          	auipc	ra,0xffffc
    80004092:	4b2080e7          	jalr	1202(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004096:	40dc                	lw	a5,4(s1)
    80004098:	0047d79b          	srliw	a5,a5,0x4
    8000409c:	0023c597          	auipc	a1,0x23c
    800040a0:	67c5a583          	lw	a1,1660(a1) # 80240718 <sb+0x18>
    800040a4:	9dbd                	addw	a1,a1,a5
    800040a6:	4088                	lw	a0,0(s1)
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	796080e7          	jalr	1942(ra) # 8000383e <bread>
    800040b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040b2:	05850593          	addi	a1,a0,88
    800040b6:	40dc                	lw	a5,4(s1)
    800040b8:	8bbd                	andi	a5,a5,15
    800040ba:	079a                	slli	a5,a5,0x6
    800040bc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800040be:	00059783          	lh	a5,0(a1)
    800040c2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040c6:	00259783          	lh	a5,2(a1)
    800040ca:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040ce:	00459783          	lh	a5,4(a1)
    800040d2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040d6:	00659783          	lh	a5,6(a1)
    800040da:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040de:	459c                	lw	a5,8(a1)
    800040e0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040e2:	03400613          	li	a2,52
    800040e6:	05b1                	addi	a1,a1,12
    800040e8:	05048513          	addi	a0,s1,80
    800040ec:	ffffd097          	auipc	ra,0xffffd
    800040f0:	d36080e7          	jalr	-714(ra) # 80000e22 <memmove>
    brelse(bp);
    800040f4:	854a                	mv	a0,s2
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	878080e7          	jalr	-1928(ra) # 8000396e <brelse>
    ip->valid = 1;
    800040fe:	4785                	li	a5,1
    80004100:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004102:	04449783          	lh	a5,68(s1)
    80004106:	fbb5                	bnez	a5,8000407a <ilock+0x24>
      panic("ilock: no type");
    80004108:	00004517          	auipc	a0,0x4
    8000410c:	55850513          	addi	a0,a0,1368 # 80008660 <syscalls+0x1b0>
    80004110:	ffffc097          	auipc	ra,0xffffc
    80004114:	430080e7          	jalr	1072(ra) # 80000540 <panic>

0000000080004118 <iunlock>:
{
    80004118:	1101                	addi	sp,sp,-32
    8000411a:	ec06                	sd	ra,24(sp)
    8000411c:	e822                	sd	s0,16(sp)
    8000411e:	e426                	sd	s1,8(sp)
    80004120:	e04a                	sd	s2,0(sp)
    80004122:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004124:	c905                	beqz	a0,80004154 <iunlock+0x3c>
    80004126:	84aa                	mv	s1,a0
    80004128:	01050913          	addi	s2,a0,16
    8000412c:	854a                	mv	a0,s2
    8000412e:	00001097          	auipc	ra,0x1
    80004132:	c82080e7          	jalr	-894(ra) # 80004db0 <holdingsleep>
    80004136:	cd19                	beqz	a0,80004154 <iunlock+0x3c>
    80004138:	449c                	lw	a5,8(s1)
    8000413a:	00f05d63          	blez	a5,80004154 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000413e:	854a                	mv	a0,s2
    80004140:	00001097          	auipc	ra,0x1
    80004144:	c2c080e7          	jalr	-980(ra) # 80004d6c <releasesleep>
}
    80004148:	60e2                	ld	ra,24(sp)
    8000414a:	6442                	ld	s0,16(sp)
    8000414c:	64a2                	ld	s1,8(sp)
    8000414e:	6902                	ld	s2,0(sp)
    80004150:	6105                	addi	sp,sp,32
    80004152:	8082                	ret
    panic("iunlock");
    80004154:	00004517          	auipc	a0,0x4
    80004158:	51c50513          	addi	a0,a0,1308 # 80008670 <syscalls+0x1c0>
    8000415c:	ffffc097          	auipc	ra,0xffffc
    80004160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>

0000000080004164 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004164:	7179                	addi	sp,sp,-48
    80004166:	f406                	sd	ra,40(sp)
    80004168:	f022                	sd	s0,32(sp)
    8000416a:	ec26                	sd	s1,24(sp)
    8000416c:	e84a                	sd	s2,16(sp)
    8000416e:	e44e                	sd	s3,8(sp)
    80004170:	e052                	sd	s4,0(sp)
    80004172:	1800                	addi	s0,sp,48
    80004174:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004176:	05050493          	addi	s1,a0,80
    8000417a:	08050913          	addi	s2,a0,128
    8000417e:	a021                	j	80004186 <itrunc+0x22>
    80004180:	0491                	addi	s1,s1,4
    80004182:	01248d63          	beq	s1,s2,8000419c <itrunc+0x38>
    if(ip->addrs[i]){
    80004186:	408c                	lw	a1,0(s1)
    80004188:	dde5                	beqz	a1,80004180 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000418a:	0009a503          	lw	a0,0(s3)
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	8f6080e7          	jalr	-1802(ra) # 80003a84 <bfree>
      ip->addrs[i] = 0;
    80004196:	0004a023          	sw	zero,0(s1)
    8000419a:	b7dd                	j	80004180 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000419c:	0809a583          	lw	a1,128(s3)
    800041a0:	e185                	bnez	a1,800041c0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800041a2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800041a6:	854e                	mv	a0,s3
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	de2080e7          	jalr	-542(ra) # 80003f8a <iupdate>
}
    800041b0:	70a2                	ld	ra,40(sp)
    800041b2:	7402                	ld	s0,32(sp)
    800041b4:	64e2                	ld	s1,24(sp)
    800041b6:	6942                	ld	s2,16(sp)
    800041b8:	69a2                	ld	s3,8(sp)
    800041ba:	6a02                	ld	s4,0(sp)
    800041bc:	6145                	addi	sp,sp,48
    800041be:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800041c0:	0009a503          	lw	a0,0(s3)
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	67a080e7          	jalr	1658(ra) # 8000383e <bread>
    800041cc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041ce:	05850493          	addi	s1,a0,88
    800041d2:	45850913          	addi	s2,a0,1112
    800041d6:	a021                	j	800041de <itrunc+0x7a>
    800041d8:	0491                	addi	s1,s1,4
    800041da:	01248b63          	beq	s1,s2,800041f0 <itrunc+0x8c>
      if(a[j])
    800041de:	408c                	lw	a1,0(s1)
    800041e0:	dde5                	beqz	a1,800041d8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800041e2:	0009a503          	lw	a0,0(s3)
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	89e080e7          	jalr	-1890(ra) # 80003a84 <bfree>
    800041ee:	b7ed                	j	800041d8 <itrunc+0x74>
    brelse(bp);
    800041f0:	8552                	mv	a0,s4
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	77c080e7          	jalr	1916(ra) # 8000396e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800041fa:	0809a583          	lw	a1,128(s3)
    800041fe:	0009a503          	lw	a0,0(s3)
    80004202:	00000097          	auipc	ra,0x0
    80004206:	882080e7          	jalr	-1918(ra) # 80003a84 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000420a:	0809a023          	sw	zero,128(s3)
    8000420e:	bf51                	j	800041a2 <itrunc+0x3e>

0000000080004210 <iput>:
{
    80004210:	1101                	addi	sp,sp,-32
    80004212:	ec06                	sd	ra,24(sp)
    80004214:	e822                	sd	s0,16(sp)
    80004216:	e426                	sd	s1,8(sp)
    80004218:	e04a                	sd	s2,0(sp)
    8000421a:	1000                	addi	s0,sp,32
    8000421c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000421e:	0023c517          	auipc	a0,0x23c
    80004222:	50250513          	addi	a0,a0,1282 # 80240720 <itable>
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	aa4080e7          	jalr	-1372(ra) # 80000cca <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000422e:	4498                	lw	a4,8(s1)
    80004230:	4785                	li	a5,1
    80004232:	02f70363          	beq	a4,a5,80004258 <iput+0x48>
  ip->ref--;
    80004236:	449c                	lw	a5,8(s1)
    80004238:	37fd                	addiw	a5,a5,-1
    8000423a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000423c:	0023c517          	auipc	a0,0x23c
    80004240:	4e450513          	addi	a0,a0,1252 # 80240720 <itable>
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	b3a080e7          	jalr	-1222(ra) # 80000d7e <release>
}
    8000424c:	60e2                	ld	ra,24(sp)
    8000424e:	6442                	ld	s0,16(sp)
    80004250:	64a2                	ld	s1,8(sp)
    80004252:	6902                	ld	s2,0(sp)
    80004254:	6105                	addi	sp,sp,32
    80004256:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004258:	40bc                	lw	a5,64(s1)
    8000425a:	dff1                	beqz	a5,80004236 <iput+0x26>
    8000425c:	04a49783          	lh	a5,74(s1)
    80004260:	fbf9                	bnez	a5,80004236 <iput+0x26>
    acquiresleep(&ip->lock);
    80004262:	01048913          	addi	s2,s1,16
    80004266:	854a                	mv	a0,s2
    80004268:	00001097          	auipc	ra,0x1
    8000426c:	aae080e7          	jalr	-1362(ra) # 80004d16 <acquiresleep>
    release(&itable.lock);
    80004270:	0023c517          	auipc	a0,0x23c
    80004274:	4b050513          	addi	a0,a0,1200 # 80240720 <itable>
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	b06080e7          	jalr	-1274(ra) # 80000d7e <release>
    itrunc(ip);
    80004280:	8526                	mv	a0,s1
    80004282:	00000097          	auipc	ra,0x0
    80004286:	ee2080e7          	jalr	-286(ra) # 80004164 <itrunc>
    ip->type = 0;
    8000428a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000428e:	8526                	mv	a0,s1
    80004290:	00000097          	auipc	ra,0x0
    80004294:	cfa080e7          	jalr	-774(ra) # 80003f8a <iupdate>
    ip->valid = 0;
    80004298:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000429c:	854a                	mv	a0,s2
    8000429e:	00001097          	auipc	ra,0x1
    800042a2:	ace080e7          	jalr	-1330(ra) # 80004d6c <releasesleep>
    acquire(&itable.lock);
    800042a6:	0023c517          	auipc	a0,0x23c
    800042aa:	47a50513          	addi	a0,a0,1146 # 80240720 <itable>
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	a1c080e7          	jalr	-1508(ra) # 80000cca <acquire>
    800042b6:	b741                	j	80004236 <iput+0x26>

00000000800042b8 <iunlockput>:
{
    800042b8:	1101                	addi	sp,sp,-32
    800042ba:	ec06                	sd	ra,24(sp)
    800042bc:	e822                	sd	s0,16(sp)
    800042be:	e426                	sd	s1,8(sp)
    800042c0:	1000                	addi	s0,sp,32
    800042c2:	84aa                	mv	s1,a0
  iunlock(ip);
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	e54080e7          	jalr	-428(ra) # 80004118 <iunlock>
  iput(ip);
    800042cc:	8526                	mv	a0,s1
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	f42080e7          	jalr	-190(ra) # 80004210 <iput>
}
    800042d6:	60e2                	ld	ra,24(sp)
    800042d8:	6442                	ld	s0,16(sp)
    800042da:	64a2                	ld	s1,8(sp)
    800042dc:	6105                	addi	sp,sp,32
    800042de:	8082                	ret

00000000800042e0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042e0:	1141                	addi	sp,sp,-16
    800042e2:	e422                	sd	s0,8(sp)
    800042e4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042e6:	411c                	lw	a5,0(a0)
    800042e8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800042ea:	415c                	lw	a5,4(a0)
    800042ec:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800042ee:	04451783          	lh	a5,68(a0)
    800042f2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800042f6:	04a51783          	lh	a5,74(a0)
    800042fa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800042fe:	04c56783          	lwu	a5,76(a0)
    80004302:	e99c                	sd	a5,16(a1)
}
    80004304:	6422                	ld	s0,8(sp)
    80004306:	0141                	addi	sp,sp,16
    80004308:	8082                	ret

000000008000430a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000430a:	457c                	lw	a5,76(a0)
    8000430c:	0ed7e963          	bltu	a5,a3,800043fe <readi+0xf4>
{
    80004310:	7159                	addi	sp,sp,-112
    80004312:	f486                	sd	ra,104(sp)
    80004314:	f0a2                	sd	s0,96(sp)
    80004316:	eca6                	sd	s1,88(sp)
    80004318:	e8ca                	sd	s2,80(sp)
    8000431a:	e4ce                	sd	s3,72(sp)
    8000431c:	e0d2                	sd	s4,64(sp)
    8000431e:	fc56                	sd	s5,56(sp)
    80004320:	f85a                	sd	s6,48(sp)
    80004322:	f45e                	sd	s7,40(sp)
    80004324:	f062                	sd	s8,32(sp)
    80004326:	ec66                	sd	s9,24(sp)
    80004328:	e86a                	sd	s10,16(sp)
    8000432a:	e46e                	sd	s11,8(sp)
    8000432c:	1880                	addi	s0,sp,112
    8000432e:	8b2a                	mv	s6,a0
    80004330:	8bae                	mv	s7,a1
    80004332:	8a32                	mv	s4,a2
    80004334:	84b6                	mv	s1,a3
    80004336:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004338:	9f35                	addw	a4,a4,a3
    return 0;
    8000433a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000433c:	0ad76063          	bltu	a4,a3,800043dc <readi+0xd2>
  if(off + n > ip->size)
    80004340:	00e7f463          	bgeu	a5,a4,80004348 <readi+0x3e>
    n = ip->size - off;
    80004344:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004348:	0a0a8963          	beqz	s5,800043fa <readi+0xf0>
    8000434c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000434e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004352:	5c7d                	li	s8,-1
    80004354:	a82d                	j	8000438e <readi+0x84>
    80004356:	020d1d93          	slli	s11,s10,0x20
    8000435a:	020ddd93          	srli	s11,s11,0x20
    8000435e:	05890613          	addi	a2,s2,88
    80004362:	86ee                	mv	a3,s11
    80004364:	963a                	add	a2,a2,a4
    80004366:	85d2                	mv	a1,s4
    80004368:	855e                	mv	a0,s7
    8000436a:	ffffe097          	auipc	ra,0xffffe
    8000436e:	47a080e7          	jalr	1146(ra) # 800027e4 <either_copyout>
    80004372:	05850d63          	beq	a0,s8,800043cc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004376:	854a                	mv	a0,s2
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	5f6080e7          	jalr	1526(ra) # 8000396e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004380:	013d09bb          	addw	s3,s10,s3
    80004384:	009d04bb          	addw	s1,s10,s1
    80004388:	9a6e                	add	s4,s4,s11
    8000438a:	0559f763          	bgeu	s3,s5,800043d8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000438e:	00a4d59b          	srliw	a1,s1,0xa
    80004392:	855a                	mv	a0,s6
    80004394:	00000097          	auipc	ra,0x0
    80004398:	89e080e7          	jalr	-1890(ra) # 80003c32 <bmap>
    8000439c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800043a0:	cd85                	beqz	a1,800043d8 <readi+0xce>
    bp = bread(ip->dev, addr);
    800043a2:	000b2503          	lw	a0,0(s6)
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	498080e7          	jalr	1176(ra) # 8000383e <bread>
    800043ae:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043b0:	3ff4f713          	andi	a4,s1,1023
    800043b4:	40ec87bb          	subw	a5,s9,a4
    800043b8:	413a86bb          	subw	a3,s5,s3
    800043bc:	8d3e                	mv	s10,a5
    800043be:	2781                	sext.w	a5,a5
    800043c0:	0006861b          	sext.w	a2,a3
    800043c4:	f8f679e3          	bgeu	a2,a5,80004356 <readi+0x4c>
    800043c8:	8d36                	mv	s10,a3
    800043ca:	b771                	j	80004356 <readi+0x4c>
      brelse(bp);
    800043cc:	854a                	mv	a0,s2
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	5a0080e7          	jalr	1440(ra) # 8000396e <brelse>
      tot = -1;
    800043d6:	59fd                	li	s3,-1
  }
  return tot;
    800043d8:	0009851b          	sext.w	a0,s3
}
    800043dc:	70a6                	ld	ra,104(sp)
    800043de:	7406                	ld	s0,96(sp)
    800043e0:	64e6                	ld	s1,88(sp)
    800043e2:	6946                	ld	s2,80(sp)
    800043e4:	69a6                	ld	s3,72(sp)
    800043e6:	6a06                	ld	s4,64(sp)
    800043e8:	7ae2                	ld	s5,56(sp)
    800043ea:	7b42                	ld	s6,48(sp)
    800043ec:	7ba2                	ld	s7,40(sp)
    800043ee:	7c02                	ld	s8,32(sp)
    800043f0:	6ce2                	ld	s9,24(sp)
    800043f2:	6d42                	ld	s10,16(sp)
    800043f4:	6da2                	ld	s11,8(sp)
    800043f6:	6165                	addi	sp,sp,112
    800043f8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043fa:	89d6                	mv	s3,s5
    800043fc:	bff1                	j	800043d8 <readi+0xce>
    return 0;
    800043fe:	4501                	li	a0,0
}
    80004400:	8082                	ret

0000000080004402 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004402:	457c                	lw	a5,76(a0)
    80004404:	10d7e863          	bltu	a5,a3,80004514 <writei+0x112>
{
    80004408:	7159                	addi	sp,sp,-112
    8000440a:	f486                	sd	ra,104(sp)
    8000440c:	f0a2                	sd	s0,96(sp)
    8000440e:	eca6                	sd	s1,88(sp)
    80004410:	e8ca                	sd	s2,80(sp)
    80004412:	e4ce                	sd	s3,72(sp)
    80004414:	e0d2                	sd	s4,64(sp)
    80004416:	fc56                	sd	s5,56(sp)
    80004418:	f85a                	sd	s6,48(sp)
    8000441a:	f45e                	sd	s7,40(sp)
    8000441c:	f062                	sd	s8,32(sp)
    8000441e:	ec66                	sd	s9,24(sp)
    80004420:	e86a                	sd	s10,16(sp)
    80004422:	e46e                	sd	s11,8(sp)
    80004424:	1880                	addi	s0,sp,112
    80004426:	8aaa                	mv	s5,a0
    80004428:	8bae                	mv	s7,a1
    8000442a:	8a32                	mv	s4,a2
    8000442c:	8936                	mv	s2,a3
    8000442e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004430:	00e687bb          	addw	a5,a3,a4
    80004434:	0ed7e263          	bltu	a5,a3,80004518 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004438:	00043737          	lui	a4,0x43
    8000443c:	0ef76063          	bltu	a4,a5,8000451c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004440:	0c0b0863          	beqz	s6,80004510 <writei+0x10e>
    80004444:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004446:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000444a:	5c7d                	li	s8,-1
    8000444c:	a091                	j	80004490 <writei+0x8e>
    8000444e:	020d1d93          	slli	s11,s10,0x20
    80004452:	020ddd93          	srli	s11,s11,0x20
    80004456:	05848513          	addi	a0,s1,88
    8000445a:	86ee                	mv	a3,s11
    8000445c:	8652                	mv	a2,s4
    8000445e:	85de                	mv	a1,s7
    80004460:	953a                	add	a0,a0,a4
    80004462:	ffffe097          	auipc	ra,0xffffe
    80004466:	3d8080e7          	jalr	984(ra) # 8000283a <either_copyin>
    8000446a:	07850263          	beq	a0,s8,800044ce <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000446e:	8526                	mv	a0,s1
    80004470:	00000097          	auipc	ra,0x0
    80004474:	788080e7          	jalr	1928(ra) # 80004bf8 <log_write>
    brelse(bp);
    80004478:	8526                	mv	a0,s1
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	4f4080e7          	jalr	1268(ra) # 8000396e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004482:	013d09bb          	addw	s3,s10,s3
    80004486:	012d093b          	addw	s2,s10,s2
    8000448a:	9a6e                	add	s4,s4,s11
    8000448c:	0569f663          	bgeu	s3,s6,800044d8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004490:	00a9559b          	srliw	a1,s2,0xa
    80004494:	8556                	mv	a0,s5
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	79c080e7          	jalr	1948(ra) # 80003c32 <bmap>
    8000449e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800044a2:	c99d                	beqz	a1,800044d8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800044a4:	000aa503          	lw	a0,0(s5)
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	396080e7          	jalr	918(ra) # 8000383e <bread>
    800044b0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044b2:	3ff97713          	andi	a4,s2,1023
    800044b6:	40ec87bb          	subw	a5,s9,a4
    800044ba:	413b06bb          	subw	a3,s6,s3
    800044be:	8d3e                	mv	s10,a5
    800044c0:	2781                	sext.w	a5,a5
    800044c2:	0006861b          	sext.w	a2,a3
    800044c6:	f8f674e3          	bgeu	a2,a5,8000444e <writei+0x4c>
    800044ca:	8d36                	mv	s10,a3
    800044cc:	b749                	j	8000444e <writei+0x4c>
      brelse(bp);
    800044ce:	8526                	mv	a0,s1
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	49e080e7          	jalr	1182(ra) # 8000396e <brelse>
  }

  if(off > ip->size)
    800044d8:	04caa783          	lw	a5,76(s5)
    800044dc:	0127f463          	bgeu	a5,s2,800044e4 <writei+0xe2>
    ip->size = off;
    800044e0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044e4:	8556                	mv	a0,s5
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	aa4080e7          	jalr	-1372(ra) # 80003f8a <iupdate>

  return tot;
    800044ee:	0009851b          	sext.w	a0,s3
}
    800044f2:	70a6                	ld	ra,104(sp)
    800044f4:	7406                	ld	s0,96(sp)
    800044f6:	64e6                	ld	s1,88(sp)
    800044f8:	6946                	ld	s2,80(sp)
    800044fa:	69a6                	ld	s3,72(sp)
    800044fc:	6a06                	ld	s4,64(sp)
    800044fe:	7ae2                	ld	s5,56(sp)
    80004500:	7b42                	ld	s6,48(sp)
    80004502:	7ba2                	ld	s7,40(sp)
    80004504:	7c02                	ld	s8,32(sp)
    80004506:	6ce2                	ld	s9,24(sp)
    80004508:	6d42                	ld	s10,16(sp)
    8000450a:	6da2                	ld	s11,8(sp)
    8000450c:	6165                	addi	sp,sp,112
    8000450e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004510:	89da                	mv	s3,s6
    80004512:	bfc9                	j	800044e4 <writei+0xe2>
    return -1;
    80004514:	557d                	li	a0,-1
}
    80004516:	8082                	ret
    return -1;
    80004518:	557d                	li	a0,-1
    8000451a:	bfe1                	j	800044f2 <writei+0xf0>
    return -1;
    8000451c:	557d                	li	a0,-1
    8000451e:	bfd1                	j	800044f2 <writei+0xf0>

0000000080004520 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004520:	1141                	addi	sp,sp,-16
    80004522:	e406                	sd	ra,8(sp)
    80004524:	e022                	sd	s0,0(sp)
    80004526:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004528:	4639                	li	a2,14
    8000452a:	ffffd097          	auipc	ra,0xffffd
    8000452e:	96c080e7          	jalr	-1684(ra) # 80000e96 <strncmp>
}
    80004532:	60a2                	ld	ra,8(sp)
    80004534:	6402                	ld	s0,0(sp)
    80004536:	0141                	addi	sp,sp,16
    80004538:	8082                	ret

000000008000453a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000453a:	7139                	addi	sp,sp,-64
    8000453c:	fc06                	sd	ra,56(sp)
    8000453e:	f822                	sd	s0,48(sp)
    80004540:	f426                	sd	s1,40(sp)
    80004542:	f04a                	sd	s2,32(sp)
    80004544:	ec4e                	sd	s3,24(sp)
    80004546:	e852                	sd	s4,16(sp)
    80004548:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000454a:	04451703          	lh	a4,68(a0)
    8000454e:	4785                	li	a5,1
    80004550:	00f71a63          	bne	a4,a5,80004564 <dirlookup+0x2a>
    80004554:	892a                	mv	s2,a0
    80004556:	89ae                	mv	s3,a1
    80004558:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000455a:	457c                	lw	a5,76(a0)
    8000455c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000455e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004560:	e79d                	bnez	a5,8000458e <dirlookup+0x54>
    80004562:	a8a5                	j	800045da <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004564:	00004517          	auipc	a0,0x4
    80004568:	11450513          	addi	a0,a0,276 # 80008678 <syscalls+0x1c8>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	fd4080e7          	jalr	-44(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004574:	00004517          	auipc	a0,0x4
    80004578:	11c50513          	addi	a0,a0,284 # 80008690 <syscalls+0x1e0>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	fc4080e7          	jalr	-60(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004584:	24c1                	addiw	s1,s1,16
    80004586:	04c92783          	lw	a5,76(s2)
    8000458a:	04f4f763          	bgeu	s1,a5,800045d8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000458e:	4741                	li	a4,16
    80004590:	86a6                	mv	a3,s1
    80004592:	fc040613          	addi	a2,s0,-64
    80004596:	4581                	li	a1,0
    80004598:	854a                	mv	a0,s2
    8000459a:	00000097          	auipc	ra,0x0
    8000459e:	d70080e7          	jalr	-656(ra) # 8000430a <readi>
    800045a2:	47c1                	li	a5,16
    800045a4:	fcf518e3          	bne	a0,a5,80004574 <dirlookup+0x3a>
    if(de.inum == 0)
    800045a8:	fc045783          	lhu	a5,-64(s0)
    800045ac:	dfe1                	beqz	a5,80004584 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800045ae:	fc240593          	addi	a1,s0,-62
    800045b2:	854e                	mv	a0,s3
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	f6c080e7          	jalr	-148(ra) # 80004520 <namecmp>
    800045bc:	f561                	bnez	a0,80004584 <dirlookup+0x4a>
      if(poff)
    800045be:	000a0463          	beqz	s4,800045c6 <dirlookup+0x8c>
        *poff = off;
    800045c2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045c6:	fc045583          	lhu	a1,-64(s0)
    800045ca:	00092503          	lw	a0,0(s2)
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	74e080e7          	jalr	1870(ra) # 80003d1c <iget>
    800045d6:	a011                	j	800045da <dirlookup+0xa0>
  return 0;
    800045d8:	4501                	li	a0,0
}
    800045da:	70e2                	ld	ra,56(sp)
    800045dc:	7442                	ld	s0,48(sp)
    800045de:	74a2                	ld	s1,40(sp)
    800045e0:	7902                	ld	s2,32(sp)
    800045e2:	69e2                	ld	s3,24(sp)
    800045e4:	6a42                	ld	s4,16(sp)
    800045e6:	6121                	addi	sp,sp,64
    800045e8:	8082                	ret

00000000800045ea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800045ea:	711d                	addi	sp,sp,-96
    800045ec:	ec86                	sd	ra,88(sp)
    800045ee:	e8a2                	sd	s0,80(sp)
    800045f0:	e4a6                	sd	s1,72(sp)
    800045f2:	e0ca                	sd	s2,64(sp)
    800045f4:	fc4e                	sd	s3,56(sp)
    800045f6:	f852                	sd	s4,48(sp)
    800045f8:	f456                	sd	s5,40(sp)
    800045fa:	f05a                	sd	s6,32(sp)
    800045fc:	ec5e                	sd	s7,24(sp)
    800045fe:	e862                	sd	s8,16(sp)
    80004600:	e466                	sd	s9,8(sp)
    80004602:	e06a                	sd	s10,0(sp)
    80004604:	1080                	addi	s0,sp,96
    80004606:	84aa                	mv	s1,a0
    80004608:	8b2e                	mv	s6,a1
    8000460a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000460c:	00054703          	lbu	a4,0(a0)
    80004610:	02f00793          	li	a5,47
    80004614:	02f70363          	beq	a4,a5,8000463a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004618:	ffffd097          	auipc	ra,0xffffd
    8000461c:	54a080e7          	jalr	1354(ra) # 80001b62 <myproc>
    80004620:	15053503          	ld	a0,336(a0)
    80004624:	00000097          	auipc	ra,0x0
    80004628:	9f4080e7          	jalr	-1548(ra) # 80004018 <idup>
    8000462c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000462e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004632:	4cb5                	li	s9,13
  len = path - s;
    80004634:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004636:	4c05                	li	s8,1
    80004638:	a87d                	j	800046f6 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000463a:	4585                	li	a1,1
    8000463c:	4505                	li	a0,1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	6de080e7          	jalr	1758(ra) # 80003d1c <iget>
    80004646:	8a2a                	mv	s4,a0
    80004648:	b7dd                	j	8000462e <namex+0x44>
      iunlockput(ip);
    8000464a:	8552                	mv	a0,s4
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	c6c080e7          	jalr	-916(ra) # 800042b8 <iunlockput>
      return 0;
    80004654:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004656:	8552                	mv	a0,s4
    80004658:	60e6                	ld	ra,88(sp)
    8000465a:	6446                	ld	s0,80(sp)
    8000465c:	64a6                	ld	s1,72(sp)
    8000465e:	6906                	ld	s2,64(sp)
    80004660:	79e2                	ld	s3,56(sp)
    80004662:	7a42                	ld	s4,48(sp)
    80004664:	7aa2                	ld	s5,40(sp)
    80004666:	7b02                	ld	s6,32(sp)
    80004668:	6be2                	ld	s7,24(sp)
    8000466a:	6c42                	ld	s8,16(sp)
    8000466c:	6ca2                	ld	s9,8(sp)
    8000466e:	6d02                	ld	s10,0(sp)
    80004670:	6125                	addi	sp,sp,96
    80004672:	8082                	ret
      iunlock(ip);
    80004674:	8552                	mv	a0,s4
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	aa2080e7          	jalr	-1374(ra) # 80004118 <iunlock>
      return ip;
    8000467e:	bfe1                	j	80004656 <namex+0x6c>
      iunlockput(ip);
    80004680:	8552                	mv	a0,s4
    80004682:	00000097          	auipc	ra,0x0
    80004686:	c36080e7          	jalr	-970(ra) # 800042b8 <iunlockput>
      return 0;
    8000468a:	8a4e                	mv	s4,s3
    8000468c:	b7e9                	j	80004656 <namex+0x6c>
  len = path - s;
    8000468e:	40998633          	sub	a2,s3,s1
    80004692:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004696:	09acd863          	bge	s9,s10,80004726 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000469a:	4639                	li	a2,14
    8000469c:	85a6                	mv	a1,s1
    8000469e:	8556                	mv	a0,s5
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	782080e7          	jalr	1922(ra) # 80000e22 <memmove>
    800046a8:	84ce                	mv	s1,s3
  while(*path == '/')
    800046aa:	0004c783          	lbu	a5,0(s1)
    800046ae:	01279763          	bne	a5,s2,800046bc <namex+0xd2>
    path++;
    800046b2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046b4:	0004c783          	lbu	a5,0(s1)
    800046b8:	ff278de3          	beq	a5,s2,800046b2 <namex+0xc8>
    ilock(ip);
    800046bc:	8552                	mv	a0,s4
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	998080e7          	jalr	-1640(ra) # 80004056 <ilock>
    if(ip->type != T_DIR){
    800046c6:	044a1783          	lh	a5,68(s4)
    800046ca:	f98790e3          	bne	a5,s8,8000464a <namex+0x60>
    if(nameiparent && *path == '\0'){
    800046ce:	000b0563          	beqz	s6,800046d8 <namex+0xee>
    800046d2:	0004c783          	lbu	a5,0(s1)
    800046d6:	dfd9                	beqz	a5,80004674 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046d8:	865e                	mv	a2,s7
    800046da:	85d6                	mv	a1,s5
    800046dc:	8552                	mv	a0,s4
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	e5c080e7          	jalr	-420(ra) # 8000453a <dirlookup>
    800046e6:	89aa                	mv	s3,a0
    800046e8:	dd41                	beqz	a0,80004680 <namex+0x96>
    iunlockput(ip);
    800046ea:	8552                	mv	a0,s4
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	bcc080e7          	jalr	-1076(ra) # 800042b8 <iunlockput>
    ip = next;
    800046f4:	8a4e                	mv	s4,s3
  while(*path == '/')
    800046f6:	0004c783          	lbu	a5,0(s1)
    800046fa:	01279763          	bne	a5,s2,80004708 <namex+0x11e>
    path++;
    800046fe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004700:	0004c783          	lbu	a5,0(s1)
    80004704:	ff278de3          	beq	a5,s2,800046fe <namex+0x114>
  if(*path == 0)
    80004708:	cb9d                	beqz	a5,8000473e <namex+0x154>
  while(*path != '/' && *path != 0)
    8000470a:	0004c783          	lbu	a5,0(s1)
    8000470e:	89a6                	mv	s3,s1
  len = path - s;
    80004710:	8d5e                	mv	s10,s7
    80004712:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004714:	01278963          	beq	a5,s2,80004726 <namex+0x13c>
    80004718:	dbbd                	beqz	a5,8000468e <namex+0xa4>
    path++;
    8000471a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000471c:	0009c783          	lbu	a5,0(s3)
    80004720:	ff279ce3          	bne	a5,s2,80004718 <namex+0x12e>
    80004724:	b7ad                	j	8000468e <namex+0xa4>
    memmove(name, s, len);
    80004726:	2601                	sext.w	a2,a2
    80004728:	85a6                	mv	a1,s1
    8000472a:	8556                	mv	a0,s5
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	6f6080e7          	jalr	1782(ra) # 80000e22 <memmove>
    name[len] = 0;
    80004734:	9d56                	add	s10,s10,s5
    80004736:	000d0023          	sb	zero,0(s10)
    8000473a:	84ce                	mv	s1,s3
    8000473c:	b7bd                	j	800046aa <namex+0xc0>
  if(nameiparent){
    8000473e:	f00b0ce3          	beqz	s6,80004656 <namex+0x6c>
    iput(ip);
    80004742:	8552                	mv	a0,s4
    80004744:	00000097          	auipc	ra,0x0
    80004748:	acc080e7          	jalr	-1332(ra) # 80004210 <iput>
    return 0;
    8000474c:	4a01                	li	s4,0
    8000474e:	b721                	j	80004656 <namex+0x6c>

0000000080004750 <dirlink>:
{
    80004750:	7139                	addi	sp,sp,-64
    80004752:	fc06                	sd	ra,56(sp)
    80004754:	f822                	sd	s0,48(sp)
    80004756:	f426                	sd	s1,40(sp)
    80004758:	f04a                	sd	s2,32(sp)
    8000475a:	ec4e                	sd	s3,24(sp)
    8000475c:	e852                	sd	s4,16(sp)
    8000475e:	0080                	addi	s0,sp,64
    80004760:	892a                	mv	s2,a0
    80004762:	8a2e                	mv	s4,a1
    80004764:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004766:	4601                	li	a2,0
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	dd2080e7          	jalr	-558(ra) # 8000453a <dirlookup>
    80004770:	e93d                	bnez	a0,800047e6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004772:	04c92483          	lw	s1,76(s2)
    80004776:	c49d                	beqz	s1,800047a4 <dirlink+0x54>
    80004778:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000477a:	4741                	li	a4,16
    8000477c:	86a6                	mv	a3,s1
    8000477e:	fc040613          	addi	a2,s0,-64
    80004782:	4581                	li	a1,0
    80004784:	854a                	mv	a0,s2
    80004786:	00000097          	auipc	ra,0x0
    8000478a:	b84080e7          	jalr	-1148(ra) # 8000430a <readi>
    8000478e:	47c1                	li	a5,16
    80004790:	06f51163          	bne	a0,a5,800047f2 <dirlink+0xa2>
    if(de.inum == 0)
    80004794:	fc045783          	lhu	a5,-64(s0)
    80004798:	c791                	beqz	a5,800047a4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000479a:	24c1                	addiw	s1,s1,16
    8000479c:	04c92783          	lw	a5,76(s2)
    800047a0:	fcf4ede3          	bltu	s1,a5,8000477a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800047a4:	4639                	li	a2,14
    800047a6:	85d2                	mv	a1,s4
    800047a8:	fc240513          	addi	a0,s0,-62
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	726080e7          	jalr	1830(ra) # 80000ed2 <strncpy>
  de.inum = inum;
    800047b4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047b8:	4741                	li	a4,16
    800047ba:	86a6                	mv	a3,s1
    800047bc:	fc040613          	addi	a2,s0,-64
    800047c0:	4581                	li	a1,0
    800047c2:	854a                	mv	a0,s2
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	c3e080e7          	jalr	-962(ra) # 80004402 <writei>
    800047cc:	1541                	addi	a0,a0,-16
    800047ce:	00a03533          	snez	a0,a0
    800047d2:	40a00533          	neg	a0,a0
}
    800047d6:	70e2                	ld	ra,56(sp)
    800047d8:	7442                	ld	s0,48(sp)
    800047da:	74a2                	ld	s1,40(sp)
    800047dc:	7902                	ld	s2,32(sp)
    800047de:	69e2                	ld	s3,24(sp)
    800047e0:	6a42                	ld	s4,16(sp)
    800047e2:	6121                	addi	sp,sp,64
    800047e4:	8082                	ret
    iput(ip);
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	a2a080e7          	jalr	-1494(ra) # 80004210 <iput>
    return -1;
    800047ee:	557d                	li	a0,-1
    800047f0:	b7dd                	j	800047d6 <dirlink+0x86>
      panic("dirlink read");
    800047f2:	00004517          	auipc	a0,0x4
    800047f6:	eae50513          	addi	a0,a0,-338 # 800086a0 <syscalls+0x1f0>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	d46080e7          	jalr	-698(ra) # 80000540 <panic>

0000000080004802 <namei>:

struct inode*
namei(char *path)
{
    80004802:	1101                	addi	sp,sp,-32
    80004804:	ec06                	sd	ra,24(sp)
    80004806:	e822                	sd	s0,16(sp)
    80004808:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000480a:	fe040613          	addi	a2,s0,-32
    8000480e:	4581                	li	a1,0
    80004810:	00000097          	auipc	ra,0x0
    80004814:	dda080e7          	jalr	-550(ra) # 800045ea <namex>
}
    80004818:	60e2                	ld	ra,24(sp)
    8000481a:	6442                	ld	s0,16(sp)
    8000481c:	6105                	addi	sp,sp,32
    8000481e:	8082                	ret

0000000080004820 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004820:	1141                	addi	sp,sp,-16
    80004822:	e406                	sd	ra,8(sp)
    80004824:	e022                	sd	s0,0(sp)
    80004826:	0800                	addi	s0,sp,16
    80004828:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000482a:	4585                	li	a1,1
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	dbe080e7          	jalr	-578(ra) # 800045ea <namex>
}
    80004834:	60a2                	ld	ra,8(sp)
    80004836:	6402                	ld	s0,0(sp)
    80004838:	0141                	addi	sp,sp,16
    8000483a:	8082                	ret

000000008000483c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000483c:	1101                	addi	sp,sp,-32
    8000483e:	ec06                	sd	ra,24(sp)
    80004840:	e822                	sd	s0,16(sp)
    80004842:	e426                	sd	s1,8(sp)
    80004844:	e04a                	sd	s2,0(sp)
    80004846:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004848:	0023e917          	auipc	s2,0x23e
    8000484c:	98090913          	addi	s2,s2,-1664 # 802421c8 <log>
    80004850:	01892583          	lw	a1,24(s2)
    80004854:	02892503          	lw	a0,40(s2)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	fe6080e7          	jalr	-26(ra) # 8000383e <bread>
    80004860:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004862:	02c92683          	lw	a3,44(s2)
    80004866:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004868:	02d05863          	blez	a3,80004898 <write_head+0x5c>
    8000486c:	0023e797          	auipc	a5,0x23e
    80004870:	98c78793          	addi	a5,a5,-1652 # 802421f8 <log+0x30>
    80004874:	05c50713          	addi	a4,a0,92
    80004878:	36fd                	addiw	a3,a3,-1
    8000487a:	02069613          	slli	a2,a3,0x20
    8000487e:	01e65693          	srli	a3,a2,0x1e
    80004882:	0023e617          	auipc	a2,0x23e
    80004886:	97a60613          	addi	a2,a2,-1670 # 802421fc <log+0x34>
    8000488a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000488c:	4390                	lw	a2,0(a5)
    8000488e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004890:	0791                	addi	a5,a5,4
    80004892:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004894:	fed79ce3          	bne	a5,a3,8000488c <write_head+0x50>
  }
  bwrite(buf);
    80004898:	8526                	mv	a0,s1
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	096080e7          	jalr	150(ra) # 80003930 <bwrite>
  brelse(buf);
    800048a2:	8526                	mv	a0,s1
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	0ca080e7          	jalr	202(ra) # 8000396e <brelse>
}
    800048ac:	60e2                	ld	ra,24(sp)
    800048ae:	6442                	ld	s0,16(sp)
    800048b0:	64a2                	ld	s1,8(sp)
    800048b2:	6902                	ld	s2,0(sp)
    800048b4:	6105                	addi	sp,sp,32
    800048b6:	8082                	ret

00000000800048b8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800048b8:	0023e797          	auipc	a5,0x23e
    800048bc:	93c7a783          	lw	a5,-1732(a5) # 802421f4 <log+0x2c>
    800048c0:	0af05d63          	blez	a5,8000497a <install_trans+0xc2>
{
    800048c4:	7139                	addi	sp,sp,-64
    800048c6:	fc06                	sd	ra,56(sp)
    800048c8:	f822                	sd	s0,48(sp)
    800048ca:	f426                	sd	s1,40(sp)
    800048cc:	f04a                	sd	s2,32(sp)
    800048ce:	ec4e                	sd	s3,24(sp)
    800048d0:	e852                	sd	s4,16(sp)
    800048d2:	e456                	sd	s5,8(sp)
    800048d4:	e05a                	sd	s6,0(sp)
    800048d6:	0080                	addi	s0,sp,64
    800048d8:	8b2a                	mv	s6,a0
    800048da:	0023ea97          	auipc	s5,0x23e
    800048de:	91ea8a93          	addi	s5,s5,-1762 # 802421f8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048e2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048e4:	0023e997          	auipc	s3,0x23e
    800048e8:	8e498993          	addi	s3,s3,-1820 # 802421c8 <log>
    800048ec:	a00d                	j	8000490e <install_trans+0x56>
    brelse(lbuf);
    800048ee:	854a                	mv	a0,s2
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	07e080e7          	jalr	126(ra) # 8000396e <brelse>
    brelse(dbuf);
    800048f8:	8526                	mv	a0,s1
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	074080e7          	jalr	116(ra) # 8000396e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004902:	2a05                	addiw	s4,s4,1
    80004904:	0a91                	addi	s5,s5,4
    80004906:	02c9a783          	lw	a5,44(s3)
    8000490a:	04fa5e63          	bge	s4,a5,80004966 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000490e:	0189a583          	lw	a1,24(s3)
    80004912:	014585bb          	addw	a1,a1,s4
    80004916:	2585                	addiw	a1,a1,1
    80004918:	0289a503          	lw	a0,40(s3)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	f22080e7          	jalr	-222(ra) # 8000383e <bread>
    80004924:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004926:	000aa583          	lw	a1,0(s5)
    8000492a:	0289a503          	lw	a0,40(s3)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	f10080e7          	jalr	-240(ra) # 8000383e <bread>
    80004936:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004938:	40000613          	li	a2,1024
    8000493c:	05890593          	addi	a1,s2,88
    80004940:	05850513          	addi	a0,a0,88
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	4de080e7          	jalr	1246(ra) # 80000e22 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000494c:	8526                	mv	a0,s1
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	fe2080e7          	jalr	-30(ra) # 80003930 <bwrite>
    if(recovering == 0)
    80004956:	f80b1ce3          	bnez	s6,800048ee <install_trans+0x36>
      bunpin(dbuf);
    8000495a:	8526                	mv	a0,s1
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	0ec080e7          	jalr	236(ra) # 80003a48 <bunpin>
    80004964:	b769                	j	800048ee <install_trans+0x36>
}
    80004966:	70e2                	ld	ra,56(sp)
    80004968:	7442                	ld	s0,48(sp)
    8000496a:	74a2                	ld	s1,40(sp)
    8000496c:	7902                	ld	s2,32(sp)
    8000496e:	69e2                	ld	s3,24(sp)
    80004970:	6a42                	ld	s4,16(sp)
    80004972:	6aa2                	ld	s5,8(sp)
    80004974:	6b02                	ld	s6,0(sp)
    80004976:	6121                	addi	sp,sp,64
    80004978:	8082                	ret
    8000497a:	8082                	ret

000000008000497c <initlog>:
{
    8000497c:	7179                	addi	sp,sp,-48
    8000497e:	f406                	sd	ra,40(sp)
    80004980:	f022                	sd	s0,32(sp)
    80004982:	ec26                	sd	s1,24(sp)
    80004984:	e84a                	sd	s2,16(sp)
    80004986:	e44e                	sd	s3,8(sp)
    80004988:	1800                	addi	s0,sp,48
    8000498a:	892a                	mv	s2,a0
    8000498c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000498e:	0023e497          	auipc	s1,0x23e
    80004992:	83a48493          	addi	s1,s1,-1990 # 802421c8 <log>
    80004996:	00004597          	auipc	a1,0x4
    8000499a:	d1a58593          	addi	a1,a1,-742 # 800086b0 <syscalls+0x200>
    8000499e:	8526                	mv	a0,s1
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	29a080e7          	jalr	666(ra) # 80000c3a <initlock>
  log.start = sb->logstart;
    800049a8:	0149a583          	lw	a1,20(s3)
    800049ac:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800049ae:	0109a783          	lw	a5,16(s3)
    800049b2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800049b4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800049b8:	854a                	mv	a0,s2
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	e84080e7          	jalr	-380(ra) # 8000383e <bread>
  log.lh.n = lh->n;
    800049c2:	4d34                	lw	a3,88(a0)
    800049c4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049c6:	02d05663          	blez	a3,800049f2 <initlog+0x76>
    800049ca:	05c50793          	addi	a5,a0,92
    800049ce:	0023e717          	auipc	a4,0x23e
    800049d2:	82a70713          	addi	a4,a4,-2006 # 802421f8 <log+0x30>
    800049d6:	36fd                	addiw	a3,a3,-1
    800049d8:	02069613          	slli	a2,a3,0x20
    800049dc:	01e65693          	srli	a3,a2,0x1e
    800049e0:	06050613          	addi	a2,a0,96
    800049e4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800049e6:	4390                	lw	a2,0(a5)
    800049e8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800049ea:	0791                	addi	a5,a5,4
    800049ec:	0711                	addi	a4,a4,4
    800049ee:	fed79ce3          	bne	a5,a3,800049e6 <initlog+0x6a>
  brelse(buf);
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	f7c080e7          	jalr	-132(ra) # 8000396e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049fa:	4505                	li	a0,1
    800049fc:	00000097          	auipc	ra,0x0
    80004a00:	ebc080e7          	jalr	-324(ra) # 800048b8 <install_trans>
  log.lh.n = 0;
    80004a04:	0023d797          	auipc	a5,0x23d
    80004a08:	7e07a823          	sw	zero,2032(a5) # 802421f4 <log+0x2c>
  write_head(); // clear the log
    80004a0c:	00000097          	auipc	ra,0x0
    80004a10:	e30080e7          	jalr	-464(ra) # 8000483c <write_head>
}
    80004a14:	70a2                	ld	ra,40(sp)
    80004a16:	7402                	ld	s0,32(sp)
    80004a18:	64e2                	ld	s1,24(sp)
    80004a1a:	6942                	ld	s2,16(sp)
    80004a1c:	69a2                	ld	s3,8(sp)
    80004a1e:	6145                	addi	sp,sp,48
    80004a20:	8082                	ret

0000000080004a22 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a22:	1101                	addi	sp,sp,-32
    80004a24:	ec06                	sd	ra,24(sp)
    80004a26:	e822                	sd	s0,16(sp)
    80004a28:	e426                	sd	s1,8(sp)
    80004a2a:	e04a                	sd	s2,0(sp)
    80004a2c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a2e:	0023d517          	auipc	a0,0x23d
    80004a32:	79a50513          	addi	a0,a0,1946 # 802421c8 <log>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	294080e7          	jalr	660(ra) # 80000cca <acquire>
  while(1){
    if(log.committing){
    80004a3e:	0023d497          	auipc	s1,0x23d
    80004a42:	78a48493          	addi	s1,s1,1930 # 802421c8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a46:	4979                	li	s2,30
    80004a48:	a039                	j	80004a56 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a4a:	85a6                	mv	a1,s1
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffe097          	auipc	ra,0xffffe
    80004a52:	976080e7          	jalr	-1674(ra) # 800023c4 <sleep>
    if(log.committing){
    80004a56:	50dc                	lw	a5,36(s1)
    80004a58:	fbed                	bnez	a5,80004a4a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a5a:	5098                	lw	a4,32(s1)
    80004a5c:	2705                	addiw	a4,a4,1
    80004a5e:	0007069b          	sext.w	a3,a4
    80004a62:	0027179b          	slliw	a5,a4,0x2
    80004a66:	9fb9                	addw	a5,a5,a4
    80004a68:	0017979b          	slliw	a5,a5,0x1
    80004a6c:	54d8                	lw	a4,44(s1)
    80004a6e:	9fb9                	addw	a5,a5,a4
    80004a70:	00f95963          	bge	s2,a5,80004a82 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a74:	85a6                	mv	a1,s1
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	94c080e7          	jalr	-1716(ra) # 800023c4 <sleep>
    80004a80:	bfd9                	j	80004a56 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a82:	0023d517          	auipc	a0,0x23d
    80004a86:	74650513          	addi	a0,a0,1862 # 802421c8 <log>
    80004a8a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	2f2080e7          	jalr	754(ra) # 80000d7e <release>
      break;
    }
  }
}
    80004a94:	60e2                	ld	ra,24(sp)
    80004a96:	6442                	ld	s0,16(sp)
    80004a98:	64a2                	ld	s1,8(sp)
    80004a9a:	6902                	ld	s2,0(sp)
    80004a9c:	6105                	addi	sp,sp,32
    80004a9e:	8082                	ret

0000000080004aa0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004aa0:	7139                	addi	sp,sp,-64
    80004aa2:	fc06                	sd	ra,56(sp)
    80004aa4:	f822                	sd	s0,48(sp)
    80004aa6:	f426                	sd	s1,40(sp)
    80004aa8:	f04a                	sd	s2,32(sp)
    80004aaa:	ec4e                	sd	s3,24(sp)
    80004aac:	e852                	sd	s4,16(sp)
    80004aae:	e456                	sd	s5,8(sp)
    80004ab0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004ab2:	0023d497          	auipc	s1,0x23d
    80004ab6:	71648493          	addi	s1,s1,1814 # 802421c8 <log>
    80004aba:	8526                	mv	a0,s1
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	20e080e7          	jalr	526(ra) # 80000cca <acquire>
  log.outstanding -= 1;
    80004ac4:	509c                	lw	a5,32(s1)
    80004ac6:	37fd                	addiw	a5,a5,-1
    80004ac8:	0007891b          	sext.w	s2,a5
    80004acc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004ace:	50dc                	lw	a5,36(s1)
    80004ad0:	e7b9                	bnez	a5,80004b1e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004ad2:	04091e63          	bnez	s2,80004b2e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004ad6:	0023d497          	auipc	s1,0x23d
    80004ada:	6f248493          	addi	s1,s1,1778 # 802421c8 <log>
    80004ade:	4785                	li	a5,1
    80004ae0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ae2:	8526                	mv	a0,s1
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	29a080e7          	jalr	666(ra) # 80000d7e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004aec:	54dc                	lw	a5,44(s1)
    80004aee:	06f04763          	bgtz	a5,80004b5c <end_op+0xbc>
    acquire(&log.lock);
    80004af2:	0023d497          	auipc	s1,0x23d
    80004af6:	6d648493          	addi	s1,s1,1750 # 802421c8 <log>
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	1ce080e7          	jalr	462(ra) # 80000cca <acquire>
    log.committing = 0;
    80004b04:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	ffffe097          	auipc	ra,0xffffe
    80004b0e:	92a080e7          	jalr	-1750(ra) # 80002434 <wakeup>
    release(&log.lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	26a080e7          	jalr	618(ra) # 80000d7e <release>
}
    80004b1c:	a03d                	j	80004b4a <end_op+0xaa>
    panic("log.committing");
    80004b1e:	00004517          	auipc	a0,0x4
    80004b22:	b9a50513          	addi	a0,a0,-1126 # 800086b8 <syscalls+0x208>
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	a1a080e7          	jalr	-1510(ra) # 80000540 <panic>
    wakeup(&log);
    80004b2e:	0023d497          	auipc	s1,0x23d
    80004b32:	69a48493          	addi	s1,s1,1690 # 802421c8 <log>
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffe097          	auipc	ra,0xffffe
    80004b3c:	8fc080e7          	jalr	-1796(ra) # 80002434 <wakeup>
  release(&log.lock);
    80004b40:	8526                	mv	a0,s1
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	23c080e7          	jalr	572(ra) # 80000d7e <release>
}
    80004b4a:	70e2                	ld	ra,56(sp)
    80004b4c:	7442                	ld	s0,48(sp)
    80004b4e:	74a2                	ld	s1,40(sp)
    80004b50:	7902                	ld	s2,32(sp)
    80004b52:	69e2                	ld	s3,24(sp)
    80004b54:	6a42                	ld	s4,16(sp)
    80004b56:	6aa2                	ld	s5,8(sp)
    80004b58:	6121                	addi	sp,sp,64
    80004b5a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b5c:	0023da97          	auipc	s5,0x23d
    80004b60:	69ca8a93          	addi	s5,s5,1692 # 802421f8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b64:	0023da17          	auipc	s4,0x23d
    80004b68:	664a0a13          	addi	s4,s4,1636 # 802421c8 <log>
    80004b6c:	018a2583          	lw	a1,24(s4)
    80004b70:	012585bb          	addw	a1,a1,s2
    80004b74:	2585                	addiw	a1,a1,1
    80004b76:	028a2503          	lw	a0,40(s4)
    80004b7a:	fffff097          	auipc	ra,0xfffff
    80004b7e:	cc4080e7          	jalr	-828(ra) # 8000383e <bread>
    80004b82:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b84:	000aa583          	lw	a1,0(s5)
    80004b88:	028a2503          	lw	a0,40(s4)
    80004b8c:	fffff097          	auipc	ra,0xfffff
    80004b90:	cb2080e7          	jalr	-846(ra) # 8000383e <bread>
    80004b94:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b96:	40000613          	li	a2,1024
    80004b9a:	05850593          	addi	a1,a0,88
    80004b9e:	05848513          	addi	a0,s1,88
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	280080e7          	jalr	640(ra) # 80000e22 <memmove>
    bwrite(to);  // write the log
    80004baa:	8526                	mv	a0,s1
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	d84080e7          	jalr	-636(ra) # 80003930 <bwrite>
    brelse(from);
    80004bb4:	854e                	mv	a0,s3
    80004bb6:	fffff097          	auipc	ra,0xfffff
    80004bba:	db8080e7          	jalr	-584(ra) # 8000396e <brelse>
    brelse(to);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	dae080e7          	jalr	-594(ra) # 8000396e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bc8:	2905                	addiw	s2,s2,1
    80004bca:	0a91                	addi	s5,s5,4
    80004bcc:	02ca2783          	lw	a5,44(s4)
    80004bd0:	f8f94ee3          	blt	s2,a5,80004b6c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bd4:	00000097          	auipc	ra,0x0
    80004bd8:	c68080e7          	jalr	-920(ra) # 8000483c <write_head>
    install_trans(0); // Now install writes to home locations
    80004bdc:	4501                	li	a0,0
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	cda080e7          	jalr	-806(ra) # 800048b8 <install_trans>
    log.lh.n = 0;
    80004be6:	0023d797          	auipc	a5,0x23d
    80004bea:	6007a723          	sw	zero,1550(a5) # 802421f4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004bee:	00000097          	auipc	ra,0x0
    80004bf2:	c4e080e7          	jalr	-946(ra) # 8000483c <write_head>
    80004bf6:	bdf5                	j	80004af2 <end_op+0x52>

0000000080004bf8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bf8:	1101                	addi	sp,sp,-32
    80004bfa:	ec06                	sd	ra,24(sp)
    80004bfc:	e822                	sd	s0,16(sp)
    80004bfe:	e426                	sd	s1,8(sp)
    80004c00:	e04a                	sd	s2,0(sp)
    80004c02:	1000                	addi	s0,sp,32
    80004c04:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004c06:	0023d917          	auipc	s2,0x23d
    80004c0a:	5c290913          	addi	s2,s2,1474 # 802421c8 <log>
    80004c0e:	854a                	mv	a0,s2
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	0ba080e7          	jalr	186(ra) # 80000cca <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c18:	02c92603          	lw	a2,44(s2)
    80004c1c:	47f5                	li	a5,29
    80004c1e:	06c7c563          	blt	a5,a2,80004c88 <log_write+0x90>
    80004c22:	0023d797          	auipc	a5,0x23d
    80004c26:	5c27a783          	lw	a5,1474(a5) # 802421e4 <log+0x1c>
    80004c2a:	37fd                	addiw	a5,a5,-1
    80004c2c:	04f65e63          	bge	a2,a5,80004c88 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c30:	0023d797          	auipc	a5,0x23d
    80004c34:	5b87a783          	lw	a5,1464(a5) # 802421e8 <log+0x20>
    80004c38:	06f05063          	blez	a5,80004c98 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c3c:	4781                	li	a5,0
    80004c3e:	06c05563          	blez	a2,80004ca8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c42:	44cc                	lw	a1,12(s1)
    80004c44:	0023d717          	auipc	a4,0x23d
    80004c48:	5b470713          	addi	a4,a4,1460 # 802421f8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c4c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c4e:	4314                	lw	a3,0(a4)
    80004c50:	04b68c63          	beq	a3,a1,80004ca8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c54:	2785                	addiw	a5,a5,1
    80004c56:	0711                	addi	a4,a4,4
    80004c58:	fef61be3          	bne	a2,a5,80004c4e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c5c:	0621                	addi	a2,a2,8
    80004c5e:	060a                	slli	a2,a2,0x2
    80004c60:	0023d797          	auipc	a5,0x23d
    80004c64:	56878793          	addi	a5,a5,1384 # 802421c8 <log>
    80004c68:	97b2                	add	a5,a5,a2
    80004c6a:	44d8                	lw	a4,12(s1)
    80004c6c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	d9c080e7          	jalr	-612(ra) # 80003a0c <bpin>
    log.lh.n++;
    80004c78:	0023d717          	auipc	a4,0x23d
    80004c7c:	55070713          	addi	a4,a4,1360 # 802421c8 <log>
    80004c80:	575c                	lw	a5,44(a4)
    80004c82:	2785                	addiw	a5,a5,1
    80004c84:	d75c                	sw	a5,44(a4)
    80004c86:	a82d                	j	80004cc0 <log_write+0xc8>
    panic("too big a transaction");
    80004c88:	00004517          	auipc	a0,0x4
    80004c8c:	a4050513          	addi	a0,a0,-1472 # 800086c8 <syscalls+0x218>
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	8b0080e7          	jalr	-1872(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004c98:	00004517          	auipc	a0,0x4
    80004c9c:	a4850513          	addi	a0,a0,-1464 # 800086e0 <syscalls+0x230>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	8a0080e7          	jalr	-1888(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004ca8:	00878693          	addi	a3,a5,8
    80004cac:	068a                	slli	a3,a3,0x2
    80004cae:	0023d717          	auipc	a4,0x23d
    80004cb2:	51a70713          	addi	a4,a4,1306 # 802421c8 <log>
    80004cb6:	9736                	add	a4,a4,a3
    80004cb8:	44d4                	lw	a3,12(s1)
    80004cba:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004cbc:	faf609e3          	beq	a2,a5,80004c6e <log_write+0x76>
  }
  release(&log.lock);
    80004cc0:	0023d517          	auipc	a0,0x23d
    80004cc4:	50850513          	addi	a0,a0,1288 # 802421c8 <log>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	0b6080e7          	jalr	182(ra) # 80000d7e <release>
}
    80004cd0:	60e2                	ld	ra,24(sp)
    80004cd2:	6442                	ld	s0,16(sp)
    80004cd4:	64a2                	ld	s1,8(sp)
    80004cd6:	6902                	ld	s2,0(sp)
    80004cd8:	6105                	addi	sp,sp,32
    80004cda:	8082                	ret

0000000080004cdc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cdc:	1101                	addi	sp,sp,-32
    80004cde:	ec06                	sd	ra,24(sp)
    80004ce0:	e822                	sd	s0,16(sp)
    80004ce2:	e426                	sd	s1,8(sp)
    80004ce4:	e04a                	sd	s2,0(sp)
    80004ce6:	1000                	addi	s0,sp,32
    80004ce8:	84aa                	mv	s1,a0
    80004cea:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004cec:	00004597          	auipc	a1,0x4
    80004cf0:	a1458593          	addi	a1,a1,-1516 # 80008700 <syscalls+0x250>
    80004cf4:	0521                	addi	a0,a0,8
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	f44080e7          	jalr	-188(ra) # 80000c3a <initlock>
  lk->name = name;
    80004cfe:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004d02:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d06:	0204a423          	sw	zero,40(s1)
}
    80004d0a:	60e2                	ld	ra,24(sp)
    80004d0c:	6442                	ld	s0,16(sp)
    80004d0e:	64a2                	ld	s1,8(sp)
    80004d10:	6902                	ld	s2,0(sp)
    80004d12:	6105                	addi	sp,sp,32
    80004d14:	8082                	ret

0000000080004d16 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d16:	1101                	addi	sp,sp,-32
    80004d18:	ec06                	sd	ra,24(sp)
    80004d1a:	e822                	sd	s0,16(sp)
    80004d1c:	e426                	sd	s1,8(sp)
    80004d1e:	e04a                	sd	s2,0(sp)
    80004d20:	1000                	addi	s0,sp,32
    80004d22:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d24:	00850913          	addi	s2,a0,8
    80004d28:	854a                	mv	a0,s2
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	fa0080e7          	jalr	-96(ra) # 80000cca <acquire>
  while (lk->locked) {
    80004d32:	409c                	lw	a5,0(s1)
    80004d34:	cb89                	beqz	a5,80004d46 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d36:	85ca                	mv	a1,s2
    80004d38:	8526                	mv	a0,s1
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	68a080e7          	jalr	1674(ra) # 800023c4 <sleep>
  while (lk->locked) {
    80004d42:	409c                	lw	a5,0(s1)
    80004d44:	fbed                	bnez	a5,80004d36 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d46:	4785                	li	a5,1
    80004d48:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	e18080e7          	jalr	-488(ra) # 80001b62 <myproc>
    80004d52:	591c                	lw	a5,48(a0)
    80004d54:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d56:	854a                	mv	a0,s2
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	026080e7          	jalr	38(ra) # 80000d7e <release>
}
    80004d60:	60e2                	ld	ra,24(sp)
    80004d62:	6442                	ld	s0,16(sp)
    80004d64:	64a2                	ld	s1,8(sp)
    80004d66:	6902                	ld	s2,0(sp)
    80004d68:	6105                	addi	sp,sp,32
    80004d6a:	8082                	ret

0000000080004d6c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d6c:	1101                	addi	sp,sp,-32
    80004d6e:	ec06                	sd	ra,24(sp)
    80004d70:	e822                	sd	s0,16(sp)
    80004d72:	e426                	sd	s1,8(sp)
    80004d74:	e04a                	sd	s2,0(sp)
    80004d76:	1000                	addi	s0,sp,32
    80004d78:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d7a:	00850913          	addi	s2,a0,8
    80004d7e:	854a                	mv	a0,s2
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	f4a080e7          	jalr	-182(ra) # 80000cca <acquire>
  lk->locked = 0;
    80004d88:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d8c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	6a2080e7          	jalr	1698(ra) # 80002434 <wakeup>
  release(&lk->lk);
    80004d9a:	854a                	mv	a0,s2
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	fe2080e7          	jalr	-30(ra) # 80000d7e <release>
}
    80004da4:	60e2                	ld	ra,24(sp)
    80004da6:	6442                	ld	s0,16(sp)
    80004da8:	64a2                	ld	s1,8(sp)
    80004daa:	6902                	ld	s2,0(sp)
    80004dac:	6105                	addi	sp,sp,32
    80004dae:	8082                	ret

0000000080004db0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004db0:	7179                	addi	sp,sp,-48
    80004db2:	f406                	sd	ra,40(sp)
    80004db4:	f022                	sd	s0,32(sp)
    80004db6:	ec26                	sd	s1,24(sp)
    80004db8:	e84a                	sd	s2,16(sp)
    80004dba:	e44e                	sd	s3,8(sp)
    80004dbc:	1800                	addi	s0,sp,48
    80004dbe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004dc0:	00850913          	addi	s2,a0,8
    80004dc4:	854a                	mv	a0,s2
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	f04080e7          	jalr	-252(ra) # 80000cca <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dce:	409c                	lw	a5,0(s1)
    80004dd0:	ef99                	bnez	a5,80004dee <holdingsleep+0x3e>
    80004dd2:	4481                	li	s1,0
  release(&lk->lk);
    80004dd4:	854a                	mv	a0,s2
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	fa8080e7          	jalr	-88(ra) # 80000d7e <release>
  return r;
}
    80004dde:	8526                	mv	a0,s1
    80004de0:	70a2                	ld	ra,40(sp)
    80004de2:	7402                	ld	s0,32(sp)
    80004de4:	64e2                	ld	s1,24(sp)
    80004de6:	6942                	ld	s2,16(sp)
    80004de8:	69a2                	ld	s3,8(sp)
    80004dea:	6145                	addi	sp,sp,48
    80004dec:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dee:	0284a983          	lw	s3,40(s1)
    80004df2:	ffffd097          	auipc	ra,0xffffd
    80004df6:	d70080e7          	jalr	-656(ra) # 80001b62 <myproc>
    80004dfa:	5904                	lw	s1,48(a0)
    80004dfc:	413484b3          	sub	s1,s1,s3
    80004e00:	0014b493          	seqz	s1,s1
    80004e04:	bfc1                	j	80004dd4 <holdingsleep+0x24>

0000000080004e06 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004e06:	1141                	addi	sp,sp,-16
    80004e08:	e406                	sd	ra,8(sp)
    80004e0a:	e022                	sd	s0,0(sp)
    80004e0c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e0e:	00004597          	auipc	a1,0x4
    80004e12:	90258593          	addi	a1,a1,-1790 # 80008710 <syscalls+0x260>
    80004e16:	0023d517          	auipc	a0,0x23d
    80004e1a:	4fa50513          	addi	a0,a0,1274 # 80242310 <ftable>
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	e1c080e7          	jalr	-484(ra) # 80000c3a <initlock>
}
    80004e26:	60a2                	ld	ra,8(sp)
    80004e28:	6402                	ld	s0,0(sp)
    80004e2a:	0141                	addi	sp,sp,16
    80004e2c:	8082                	ret

0000000080004e2e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e2e:	1101                	addi	sp,sp,-32
    80004e30:	ec06                	sd	ra,24(sp)
    80004e32:	e822                	sd	s0,16(sp)
    80004e34:	e426                	sd	s1,8(sp)
    80004e36:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e38:	0023d517          	auipc	a0,0x23d
    80004e3c:	4d850513          	addi	a0,a0,1240 # 80242310 <ftable>
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	e8a080e7          	jalr	-374(ra) # 80000cca <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e48:	0023d497          	auipc	s1,0x23d
    80004e4c:	4e048493          	addi	s1,s1,1248 # 80242328 <ftable+0x18>
    80004e50:	0023e717          	auipc	a4,0x23e
    80004e54:	47870713          	addi	a4,a4,1144 # 802432c8 <disk>
    if(f->ref == 0){
    80004e58:	40dc                	lw	a5,4(s1)
    80004e5a:	cf99                	beqz	a5,80004e78 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e5c:	02848493          	addi	s1,s1,40
    80004e60:	fee49ce3          	bne	s1,a4,80004e58 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e64:	0023d517          	auipc	a0,0x23d
    80004e68:	4ac50513          	addi	a0,a0,1196 # 80242310 <ftable>
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	f12080e7          	jalr	-238(ra) # 80000d7e <release>
  return 0;
    80004e74:	4481                	li	s1,0
    80004e76:	a819                	j	80004e8c <filealloc+0x5e>
      f->ref = 1;
    80004e78:	4785                	li	a5,1
    80004e7a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e7c:	0023d517          	auipc	a0,0x23d
    80004e80:	49450513          	addi	a0,a0,1172 # 80242310 <ftable>
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	efa080e7          	jalr	-262(ra) # 80000d7e <release>
}
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	60e2                	ld	ra,24(sp)
    80004e90:	6442                	ld	s0,16(sp)
    80004e92:	64a2                	ld	s1,8(sp)
    80004e94:	6105                	addi	sp,sp,32
    80004e96:	8082                	ret

0000000080004e98 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e98:	1101                	addi	sp,sp,-32
    80004e9a:	ec06                	sd	ra,24(sp)
    80004e9c:	e822                	sd	s0,16(sp)
    80004e9e:	e426                	sd	s1,8(sp)
    80004ea0:	1000                	addi	s0,sp,32
    80004ea2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ea4:	0023d517          	auipc	a0,0x23d
    80004ea8:	46c50513          	addi	a0,a0,1132 # 80242310 <ftable>
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	e1e080e7          	jalr	-482(ra) # 80000cca <acquire>
  if(f->ref < 1)
    80004eb4:	40dc                	lw	a5,4(s1)
    80004eb6:	02f05263          	blez	a5,80004eda <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004eba:	2785                	addiw	a5,a5,1
    80004ebc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ebe:	0023d517          	auipc	a0,0x23d
    80004ec2:	45250513          	addi	a0,a0,1106 # 80242310 <ftable>
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	eb8080e7          	jalr	-328(ra) # 80000d7e <release>
  return f;
}
    80004ece:	8526                	mv	a0,s1
    80004ed0:	60e2                	ld	ra,24(sp)
    80004ed2:	6442                	ld	s0,16(sp)
    80004ed4:	64a2                	ld	s1,8(sp)
    80004ed6:	6105                	addi	sp,sp,32
    80004ed8:	8082                	ret
    panic("filedup");
    80004eda:	00004517          	auipc	a0,0x4
    80004ede:	83e50513          	addi	a0,a0,-1986 # 80008718 <syscalls+0x268>
    80004ee2:	ffffb097          	auipc	ra,0xffffb
    80004ee6:	65e080e7          	jalr	1630(ra) # 80000540 <panic>

0000000080004eea <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004eea:	7139                	addi	sp,sp,-64
    80004eec:	fc06                	sd	ra,56(sp)
    80004eee:	f822                	sd	s0,48(sp)
    80004ef0:	f426                	sd	s1,40(sp)
    80004ef2:	f04a                	sd	s2,32(sp)
    80004ef4:	ec4e                	sd	s3,24(sp)
    80004ef6:	e852                	sd	s4,16(sp)
    80004ef8:	e456                	sd	s5,8(sp)
    80004efa:	0080                	addi	s0,sp,64
    80004efc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004efe:	0023d517          	auipc	a0,0x23d
    80004f02:	41250513          	addi	a0,a0,1042 # 80242310 <ftable>
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	dc4080e7          	jalr	-572(ra) # 80000cca <acquire>
  if(f->ref < 1)
    80004f0e:	40dc                	lw	a5,4(s1)
    80004f10:	06f05163          	blez	a5,80004f72 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f14:	37fd                	addiw	a5,a5,-1
    80004f16:	0007871b          	sext.w	a4,a5
    80004f1a:	c0dc                	sw	a5,4(s1)
    80004f1c:	06e04363          	bgtz	a4,80004f82 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f20:	0004a903          	lw	s2,0(s1)
    80004f24:	0094ca83          	lbu	s5,9(s1)
    80004f28:	0104ba03          	ld	s4,16(s1)
    80004f2c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f30:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f34:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f38:	0023d517          	auipc	a0,0x23d
    80004f3c:	3d850513          	addi	a0,a0,984 # 80242310 <ftable>
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	e3e080e7          	jalr	-450(ra) # 80000d7e <release>

  if(ff.type == FD_PIPE){
    80004f48:	4785                	li	a5,1
    80004f4a:	04f90d63          	beq	s2,a5,80004fa4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f4e:	3979                	addiw	s2,s2,-2
    80004f50:	4785                	li	a5,1
    80004f52:	0527e063          	bltu	a5,s2,80004f92 <fileclose+0xa8>
    begin_op();
    80004f56:	00000097          	auipc	ra,0x0
    80004f5a:	acc080e7          	jalr	-1332(ra) # 80004a22 <begin_op>
    iput(ff.ip);
    80004f5e:	854e                	mv	a0,s3
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	2b0080e7          	jalr	688(ra) # 80004210 <iput>
    end_op();
    80004f68:	00000097          	auipc	ra,0x0
    80004f6c:	b38080e7          	jalr	-1224(ra) # 80004aa0 <end_op>
    80004f70:	a00d                	j	80004f92 <fileclose+0xa8>
    panic("fileclose");
    80004f72:	00003517          	auipc	a0,0x3
    80004f76:	7ae50513          	addi	a0,a0,1966 # 80008720 <syscalls+0x270>
    80004f7a:	ffffb097          	auipc	ra,0xffffb
    80004f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004f82:	0023d517          	auipc	a0,0x23d
    80004f86:	38e50513          	addi	a0,a0,910 # 80242310 <ftable>
    80004f8a:	ffffc097          	auipc	ra,0xffffc
    80004f8e:	df4080e7          	jalr	-524(ra) # 80000d7e <release>
  }
}
    80004f92:	70e2                	ld	ra,56(sp)
    80004f94:	7442                	ld	s0,48(sp)
    80004f96:	74a2                	ld	s1,40(sp)
    80004f98:	7902                	ld	s2,32(sp)
    80004f9a:	69e2                	ld	s3,24(sp)
    80004f9c:	6a42                	ld	s4,16(sp)
    80004f9e:	6aa2                	ld	s5,8(sp)
    80004fa0:	6121                	addi	sp,sp,64
    80004fa2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004fa4:	85d6                	mv	a1,s5
    80004fa6:	8552                	mv	a0,s4
    80004fa8:	00000097          	auipc	ra,0x0
    80004fac:	34c080e7          	jalr	844(ra) # 800052f4 <pipeclose>
    80004fb0:	b7cd                	j	80004f92 <fileclose+0xa8>

0000000080004fb2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004fb2:	715d                	addi	sp,sp,-80
    80004fb4:	e486                	sd	ra,72(sp)
    80004fb6:	e0a2                	sd	s0,64(sp)
    80004fb8:	fc26                	sd	s1,56(sp)
    80004fba:	f84a                	sd	s2,48(sp)
    80004fbc:	f44e                	sd	s3,40(sp)
    80004fbe:	0880                	addi	s0,sp,80
    80004fc0:	84aa                	mv	s1,a0
    80004fc2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fc4:	ffffd097          	auipc	ra,0xffffd
    80004fc8:	b9e080e7          	jalr	-1122(ra) # 80001b62 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fcc:	409c                	lw	a5,0(s1)
    80004fce:	37f9                	addiw	a5,a5,-2
    80004fd0:	4705                	li	a4,1
    80004fd2:	04f76763          	bltu	a4,a5,80005020 <filestat+0x6e>
    80004fd6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fd8:	6c88                	ld	a0,24(s1)
    80004fda:	fffff097          	auipc	ra,0xfffff
    80004fde:	07c080e7          	jalr	124(ra) # 80004056 <ilock>
    stati(f->ip, &st);
    80004fe2:	fb840593          	addi	a1,s0,-72
    80004fe6:	6c88                	ld	a0,24(s1)
    80004fe8:	fffff097          	auipc	ra,0xfffff
    80004fec:	2f8080e7          	jalr	760(ra) # 800042e0 <stati>
    iunlock(f->ip);
    80004ff0:	6c88                	ld	a0,24(s1)
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	126080e7          	jalr	294(ra) # 80004118 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ffa:	46e1                	li	a3,24
    80004ffc:	fb840613          	addi	a2,s0,-72
    80005000:	85ce                	mv	a1,s3
    80005002:	05093503          	ld	a0,80(s2)
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	756080e7          	jalr	1878(ra) # 8000175c <copyout>
    8000500e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005012:	60a6                	ld	ra,72(sp)
    80005014:	6406                	ld	s0,64(sp)
    80005016:	74e2                	ld	s1,56(sp)
    80005018:	7942                	ld	s2,48(sp)
    8000501a:	79a2                	ld	s3,40(sp)
    8000501c:	6161                	addi	sp,sp,80
    8000501e:	8082                	ret
  return -1;
    80005020:	557d                	li	a0,-1
    80005022:	bfc5                	j	80005012 <filestat+0x60>

0000000080005024 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005024:	7179                	addi	sp,sp,-48
    80005026:	f406                	sd	ra,40(sp)
    80005028:	f022                	sd	s0,32(sp)
    8000502a:	ec26                	sd	s1,24(sp)
    8000502c:	e84a                	sd	s2,16(sp)
    8000502e:	e44e                	sd	s3,8(sp)
    80005030:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005032:	00854783          	lbu	a5,8(a0)
    80005036:	c3d5                	beqz	a5,800050da <fileread+0xb6>
    80005038:	84aa                	mv	s1,a0
    8000503a:	89ae                	mv	s3,a1
    8000503c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000503e:	411c                	lw	a5,0(a0)
    80005040:	4705                	li	a4,1
    80005042:	04e78963          	beq	a5,a4,80005094 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005046:	470d                	li	a4,3
    80005048:	04e78d63          	beq	a5,a4,800050a2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000504c:	4709                	li	a4,2
    8000504e:	06e79e63          	bne	a5,a4,800050ca <fileread+0xa6>
    ilock(f->ip);
    80005052:	6d08                	ld	a0,24(a0)
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	002080e7          	jalr	2(ra) # 80004056 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000505c:	874a                	mv	a4,s2
    8000505e:	5094                	lw	a3,32(s1)
    80005060:	864e                	mv	a2,s3
    80005062:	4585                	li	a1,1
    80005064:	6c88                	ld	a0,24(s1)
    80005066:	fffff097          	auipc	ra,0xfffff
    8000506a:	2a4080e7          	jalr	676(ra) # 8000430a <readi>
    8000506e:	892a                	mv	s2,a0
    80005070:	00a05563          	blez	a0,8000507a <fileread+0x56>
      f->off += r;
    80005074:	509c                	lw	a5,32(s1)
    80005076:	9fa9                	addw	a5,a5,a0
    80005078:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000507a:	6c88                	ld	a0,24(s1)
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	09c080e7          	jalr	156(ra) # 80004118 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005084:	854a                	mv	a0,s2
    80005086:	70a2                	ld	ra,40(sp)
    80005088:	7402                	ld	s0,32(sp)
    8000508a:	64e2                	ld	s1,24(sp)
    8000508c:	6942                	ld	s2,16(sp)
    8000508e:	69a2                	ld	s3,8(sp)
    80005090:	6145                	addi	sp,sp,48
    80005092:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005094:	6908                	ld	a0,16(a0)
    80005096:	00000097          	auipc	ra,0x0
    8000509a:	3c6080e7          	jalr	966(ra) # 8000545c <piperead>
    8000509e:	892a                	mv	s2,a0
    800050a0:	b7d5                	j	80005084 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800050a2:	02451783          	lh	a5,36(a0)
    800050a6:	03079693          	slli	a3,a5,0x30
    800050aa:	92c1                	srli	a3,a3,0x30
    800050ac:	4725                	li	a4,9
    800050ae:	02d76863          	bltu	a4,a3,800050de <fileread+0xba>
    800050b2:	0792                	slli	a5,a5,0x4
    800050b4:	0023d717          	auipc	a4,0x23d
    800050b8:	1bc70713          	addi	a4,a4,444 # 80242270 <devsw>
    800050bc:	97ba                	add	a5,a5,a4
    800050be:	639c                	ld	a5,0(a5)
    800050c0:	c38d                	beqz	a5,800050e2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050c2:	4505                	li	a0,1
    800050c4:	9782                	jalr	a5
    800050c6:	892a                	mv	s2,a0
    800050c8:	bf75                	j	80005084 <fileread+0x60>
    panic("fileread");
    800050ca:	00003517          	auipc	a0,0x3
    800050ce:	66650513          	addi	a0,a0,1638 # 80008730 <syscalls+0x280>
    800050d2:	ffffb097          	auipc	ra,0xffffb
    800050d6:	46e080e7          	jalr	1134(ra) # 80000540 <panic>
    return -1;
    800050da:	597d                	li	s2,-1
    800050dc:	b765                	j	80005084 <fileread+0x60>
      return -1;
    800050de:	597d                	li	s2,-1
    800050e0:	b755                	j	80005084 <fileread+0x60>
    800050e2:	597d                	li	s2,-1
    800050e4:	b745                	j	80005084 <fileread+0x60>

00000000800050e6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050e6:	715d                	addi	sp,sp,-80
    800050e8:	e486                	sd	ra,72(sp)
    800050ea:	e0a2                	sd	s0,64(sp)
    800050ec:	fc26                	sd	s1,56(sp)
    800050ee:	f84a                	sd	s2,48(sp)
    800050f0:	f44e                	sd	s3,40(sp)
    800050f2:	f052                	sd	s4,32(sp)
    800050f4:	ec56                	sd	s5,24(sp)
    800050f6:	e85a                	sd	s6,16(sp)
    800050f8:	e45e                	sd	s7,8(sp)
    800050fa:	e062                	sd	s8,0(sp)
    800050fc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050fe:	00954783          	lbu	a5,9(a0)
    80005102:	10078663          	beqz	a5,8000520e <filewrite+0x128>
    80005106:	892a                	mv	s2,a0
    80005108:	8b2e                	mv	s6,a1
    8000510a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000510c:	411c                	lw	a5,0(a0)
    8000510e:	4705                	li	a4,1
    80005110:	02e78263          	beq	a5,a4,80005134 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005114:	470d                	li	a4,3
    80005116:	02e78663          	beq	a5,a4,80005142 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000511a:	4709                	li	a4,2
    8000511c:	0ee79163          	bne	a5,a4,800051fe <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005120:	0ac05d63          	blez	a2,800051da <filewrite+0xf4>
    int i = 0;
    80005124:	4981                	li	s3,0
    80005126:	6b85                	lui	s7,0x1
    80005128:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000512c:	6c05                	lui	s8,0x1
    8000512e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005132:	a861                	j	800051ca <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005134:	6908                	ld	a0,16(a0)
    80005136:	00000097          	auipc	ra,0x0
    8000513a:	22e080e7          	jalr	558(ra) # 80005364 <pipewrite>
    8000513e:	8a2a                	mv	s4,a0
    80005140:	a045                	j	800051e0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005142:	02451783          	lh	a5,36(a0)
    80005146:	03079693          	slli	a3,a5,0x30
    8000514a:	92c1                	srli	a3,a3,0x30
    8000514c:	4725                	li	a4,9
    8000514e:	0cd76263          	bltu	a4,a3,80005212 <filewrite+0x12c>
    80005152:	0792                	slli	a5,a5,0x4
    80005154:	0023d717          	auipc	a4,0x23d
    80005158:	11c70713          	addi	a4,a4,284 # 80242270 <devsw>
    8000515c:	97ba                	add	a5,a5,a4
    8000515e:	679c                	ld	a5,8(a5)
    80005160:	cbdd                	beqz	a5,80005216 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005162:	4505                	li	a0,1
    80005164:	9782                	jalr	a5
    80005166:	8a2a                	mv	s4,a0
    80005168:	a8a5                	j	800051e0 <filewrite+0xfa>
    8000516a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000516e:	00000097          	auipc	ra,0x0
    80005172:	8b4080e7          	jalr	-1868(ra) # 80004a22 <begin_op>
      ilock(f->ip);
    80005176:	01893503          	ld	a0,24(s2)
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	edc080e7          	jalr	-292(ra) # 80004056 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005182:	8756                	mv	a4,s5
    80005184:	02092683          	lw	a3,32(s2)
    80005188:	01698633          	add	a2,s3,s6
    8000518c:	4585                	li	a1,1
    8000518e:	01893503          	ld	a0,24(s2)
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	270080e7          	jalr	624(ra) # 80004402 <writei>
    8000519a:	84aa                	mv	s1,a0
    8000519c:	00a05763          	blez	a0,800051aa <filewrite+0xc4>
        f->off += r;
    800051a0:	02092783          	lw	a5,32(s2)
    800051a4:	9fa9                	addw	a5,a5,a0
    800051a6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800051aa:	01893503          	ld	a0,24(s2)
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	f6a080e7          	jalr	-150(ra) # 80004118 <iunlock>
      end_op();
    800051b6:	00000097          	auipc	ra,0x0
    800051ba:	8ea080e7          	jalr	-1814(ra) # 80004aa0 <end_op>

      if(r != n1){
    800051be:	009a9f63          	bne	s5,s1,800051dc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051c2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051c6:	0149db63          	bge	s3,s4,800051dc <filewrite+0xf6>
      int n1 = n - i;
    800051ca:	413a04bb          	subw	s1,s4,s3
    800051ce:	0004879b          	sext.w	a5,s1
    800051d2:	f8fbdce3          	bge	s7,a5,8000516a <filewrite+0x84>
    800051d6:	84e2                	mv	s1,s8
    800051d8:	bf49                	j	8000516a <filewrite+0x84>
    int i = 0;
    800051da:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051dc:	013a1f63          	bne	s4,s3,800051fa <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051e0:	8552                	mv	a0,s4
    800051e2:	60a6                	ld	ra,72(sp)
    800051e4:	6406                	ld	s0,64(sp)
    800051e6:	74e2                	ld	s1,56(sp)
    800051e8:	7942                	ld	s2,48(sp)
    800051ea:	79a2                	ld	s3,40(sp)
    800051ec:	7a02                	ld	s4,32(sp)
    800051ee:	6ae2                	ld	s5,24(sp)
    800051f0:	6b42                	ld	s6,16(sp)
    800051f2:	6ba2                	ld	s7,8(sp)
    800051f4:	6c02                	ld	s8,0(sp)
    800051f6:	6161                	addi	sp,sp,80
    800051f8:	8082                	ret
    ret = (i == n ? n : -1);
    800051fa:	5a7d                	li	s4,-1
    800051fc:	b7d5                	j	800051e0 <filewrite+0xfa>
    panic("filewrite");
    800051fe:	00003517          	auipc	a0,0x3
    80005202:	54250513          	addi	a0,a0,1346 # 80008740 <syscalls+0x290>
    80005206:	ffffb097          	auipc	ra,0xffffb
    8000520a:	33a080e7          	jalr	826(ra) # 80000540 <panic>
    return -1;
    8000520e:	5a7d                	li	s4,-1
    80005210:	bfc1                	j	800051e0 <filewrite+0xfa>
      return -1;
    80005212:	5a7d                	li	s4,-1
    80005214:	b7f1                	j	800051e0 <filewrite+0xfa>
    80005216:	5a7d                	li	s4,-1
    80005218:	b7e1                	j	800051e0 <filewrite+0xfa>

000000008000521a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000521a:	7179                	addi	sp,sp,-48
    8000521c:	f406                	sd	ra,40(sp)
    8000521e:	f022                	sd	s0,32(sp)
    80005220:	ec26                	sd	s1,24(sp)
    80005222:	e84a                	sd	s2,16(sp)
    80005224:	e44e                	sd	s3,8(sp)
    80005226:	e052                	sd	s4,0(sp)
    80005228:	1800                	addi	s0,sp,48
    8000522a:	84aa                	mv	s1,a0
    8000522c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000522e:	0005b023          	sd	zero,0(a1)
    80005232:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005236:	00000097          	auipc	ra,0x0
    8000523a:	bf8080e7          	jalr	-1032(ra) # 80004e2e <filealloc>
    8000523e:	e088                	sd	a0,0(s1)
    80005240:	c551                	beqz	a0,800052cc <pipealloc+0xb2>
    80005242:	00000097          	auipc	ra,0x0
    80005246:	bec080e7          	jalr	-1044(ra) # 80004e2e <filealloc>
    8000524a:	00aa3023          	sd	a0,0(s4)
    8000524e:	c92d                	beqz	a0,800052c0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	912080e7          	jalr	-1774(ra) # 80000b62 <kalloc>
    80005258:	892a                	mv	s2,a0
    8000525a:	c125                	beqz	a0,800052ba <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000525c:	4985                	li	s3,1
    8000525e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005262:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005266:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000526a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000526e:	00003597          	auipc	a1,0x3
    80005272:	4e258593          	addi	a1,a1,1250 # 80008750 <syscalls+0x2a0>
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	9c4080e7          	jalr	-1596(ra) # 80000c3a <initlock>
  (*f0)->type = FD_PIPE;
    8000527e:	609c                	ld	a5,0(s1)
    80005280:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005284:	609c                	ld	a5,0(s1)
    80005286:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000528a:	609c                	ld	a5,0(s1)
    8000528c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005290:	609c                	ld	a5,0(s1)
    80005292:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005296:	000a3783          	ld	a5,0(s4)
    8000529a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000529e:	000a3783          	ld	a5,0(s4)
    800052a2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800052a6:	000a3783          	ld	a5,0(s4)
    800052aa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800052ae:	000a3783          	ld	a5,0(s4)
    800052b2:	0127b823          	sd	s2,16(a5)
  return 0;
    800052b6:	4501                	li	a0,0
    800052b8:	a025                	j	800052e0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800052ba:	6088                	ld	a0,0(s1)
    800052bc:	e501                	bnez	a0,800052c4 <pipealloc+0xaa>
    800052be:	a039                	j	800052cc <pipealloc+0xb2>
    800052c0:	6088                	ld	a0,0(s1)
    800052c2:	c51d                	beqz	a0,800052f0 <pipealloc+0xd6>
    fileclose(*f0);
    800052c4:	00000097          	auipc	ra,0x0
    800052c8:	c26080e7          	jalr	-986(ra) # 80004eea <fileclose>
  if(*f1)
    800052cc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800052d0:	557d                	li	a0,-1
  if(*f1)
    800052d2:	c799                	beqz	a5,800052e0 <pipealloc+0xc6>
    fileclose(*f1);
    800052d4:	853e                	mv	a0,a5
    800052d6:	00000097          	auipc	ra,0x0
    800052da:	c14080e7          	jalr	-1004(ra) # 80004eea <fileclose>
  return -1;
    800052de:	557d                	li	a0,-1
}
    800052e0:	70a2                	ld	ra,40(sp)
    800052e2:	7402                	ld	s0,32(sp)
    800052e4:	64e2                	ld	s1,24(sp)
    800052e6:	6942                	ld	s2,16(sp)
    800052e8:	69a2                	ld	s3,8(sp)
    800052ea:	6a02                	ld	s4,0(sp)
    800052ec:	6145                	addi	sp,sp,48
    800052ee:	8082                	ret
  return -1;
    800052f0:	557d                	li	a0,-1
    800052f2:	b7fd                	j	800052e0 <pipealloc+0xc6>

00000000800052f4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800052f4:	1101                	addi	sp,sp,-32
    800052f6:	ec06                	sd	ra,24(sp)
    800052f8:	e822                	sd	s0,16(sp)
    800052fa:	e426                	sd	s1,8(sp)
    800052fc:	e04a                	sd	s2,0(sp)
    800052fe:	1000                	addi	s0,sp,32
    80005300:	84aa                	mv	s1,a0
    80005302:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	9c6080e7          	jalr	-1594(ra) # 80000cca <acquire>
  if(writable){
    8000530c:	02090d63          	beqz	s2,80005346 <pipeclose+0x52>
    pi->writeopen = 0;
    80005310:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005314:	21848513          	addi	a0,s1,536
    80005318:	ffffd097          	auipc	ra,0xffffd
    8000531c:	11c080e7          	jalr	284(ra) # 80002434 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005320:	2204b783          	ld	a5,544(s1)
    80005324:	eb95                	bnez	a5,80005358 <pipeclose+0x64>
    release(&pi->lock);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	a56080e7          	jalr	-1450(ra) # 80000d7e <release>
    kfree((char*)pi);
    80005330:	8526                	mv	a0,s1
    80005332:	ffffb097          	auipc	ra,0xffffb
    80005336:	6b6080e7          	jalr	1718(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    8000533a:	60e2                	ld	ra,24(sp)
    8000533c:	6442                	ld	s0,16(sp)
    8000533e:	64a2                	ld	s1,8(sp)
    80005340:	6902                	ld	s2,0(sp)
    80005342:	6105                	addi	sp,sp,32
    80005344:	8082                	ret
    pi->readopen = 0;
    80005346:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000534a:	21c48513          	addi	a0,s1,540
    8000534e:	ffffd097          	auipc	ra,0xffffd
    80005352:	0e6080e7          	jalr	230(ra) # 80002434 <wakeup>
    80005356:	b7e9                	j	80005320 <pipeclose+0x2c>
    release(&pi->lock);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	a24080e7          	jalr	-1500(ra) # 80000d7e <release>
}
    80005362:	bfe1                	j	8000533a <pipeclose+0x46>

0000000080005364 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005364:	711d                	addi	sp,sp,-96
    80005366:	ec86                	sd	ra,88(sp)
    80005368:	e8a2                	sd	s0,80(sp)
    8000536a:	e4a6                	sd	s1,72(sp)
    8000536c:	e0ca                	sd	s2,64(sp)
    8000536e:	fc4e                	sd	s3,56(sp)
    80005370:	f852                	sd	s4,48(sp)
    80005372:	f456                	sd	s5,40(sp)
    80005374:	f05a                	sd	s6,32(sp)
    80005376:	ec5e                	sd	s7,24(sp)
    80005378:	e862                	sd	s8,16(sp)
    8000537a:	1080                	addi	s0,sp,96
    8000537c:	84aa                	mv	s1,a0
    8000537e:	8aae                	mv	s5,a1
    80005380:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	7e0080e7          	jalr	2016(ra) # 80001b62 <myproc>
    8000538a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000538c:	8526                	mv	a0,s1
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	93c080e7          	jalr	-1732(ra) # 80000cca <acquire>
  while(i < n){
    80005396:	0b405663          	blez	s4,80005442 <pipewrite+0xde>
  int i = 0;
    8000539a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000539c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000539e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800053a2:	21c48b93          	addi	s7,s1,540
    800053a6:	a089                	j	800053e8 <pipewrite+0x84>
      release(&pi->lock);
    800053a8:	8526                	mv	a0,s1
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	9d4080e7          	jalr	-1580(ra) # 80000d7e <release>
      return -1;
    800053b2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800053b4:	854a                	mv	a0,s2
    800053b6:	60e6                	ld	ra,88(sp)
    800053b8:	6446                	ld	s0,80(sp)
    800053ba:	64a6                	ld	s1,72(sp)
    800053bc:	6906                	ld	s2,64(sp)
    800053be:	79e2                	ld	s3,56(sp)
    800053c0:	7a42                	ld	s4,48(sp)
    800053c2:	7aa2                	ld	s5,40(sp)
    800053c4:	7b02                	ld	s6,32(sp)
    800053c6:	6be2                	ld	s7,24(sp)
    800053c8:	6c42                	ld	s8,16(sp)
    800053ca:	6125                	addi	sp,sp,96
    800053cc:	8082                	ret
      wakeup(&pi->nread);
    800053ce:	8562                	mv	a0,s8
    800053d0:	ffffd097          	auipc	ra,0xffffd
    800053d4:	064080e7          	jalr	100(ra) # 80002434 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800053d8:	85a6                	mv	a1,s1
    800053da:	855e                	mv	a0,s7
    800053dc:	ffffd097          	auipc	ra,0xffffd
    800053e0:	fe8080e7          	jalr	-24(ra) # 800023c4 <sleep>
  while(i < n){
    800053e4:	07495063          	bge	s2,s4,80005444 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800053e8:	2204a783          	lw	a5,544(s1)
    800053ec:	dfd5                	beqz	a5,800053a8 <pipewrite+0x44>
    800053ee:	854e                	mv	a0,s3
    800053f0:	ffffd097          	auipc	ra,0xffffd
    800053f4:	294080e7          	jalr	660(ra) # 80002684 <killed>
    800053f8:	f945                	bnez	a0,800053a8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800053fa:	2184a783          	lw	a5,536(s1)
    800053fe:	21c4a703          	lw	a4,540(s1)
    80005402:	2007879b          	addiw	a5,a5,512
    80005406:	fcf704e3          	beq	a4,a5,800053ce <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000540a:	4685                	li	a3,1
    8000540c:	01590633          	add	a2,s2,s5
    80005410:	faf40593          	addi	a1,s0,-81
    80005414:	0509b503          	ld	a0,80(s3)
    80005418:	ffffc097          	auipc	ra,0xffffc
    8000541c:	496080e7          	jalr	1174(ra) # 800018ae <copyin>
    80005420:	03650263          	beq	a0,s6,80005444 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005424:	21c4a783          	lw	a5,540(s1)
    80005428:	0017871b          	addiw	a4,a5,1
    8000542c:	20e4ae23          	sw	a4,540(s1)
    80005430:	1ff7f793          	andi	a5,a5,511
    80005434:	97a6                	add	a5,a5,s1
    80005436:	faf44703          	lbu	a4,-81(s0)
    8000543a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000543e:	2905                	addiw	s2,s2,1
    80005440:	b755                	j	800053e4 <pipewrite+0x80>
  int i = 0;
    80005442:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005444:	21848513          	addi	a0,s1,536
    80005448:	ffffd097          	auipc	ra,0xffffd
    8000544c:	fec080e7          	jalr	-20(ra) # 80002434 <wakeup>
  release(&pi->lock);
    80005450:	8526                	mv	a0,s1
    80005452:	ffffc097          	auipc	ra,0xffffc
    80005456:	92c080e7          	jalr	-1748(ra) # 80000d7e <release>
  return i;
    8000545a:	bfa9                	j	800053b4 <pipewrite+0x50>

000000008000545c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000545c:	715d                	addi	sp,sp,-80
    8000545e:	e486                	sd	ra,72(sp)
    80005460:	e0a2                	sd	s0,64(sp)
    80005462:	fc26                	sd	s1,56(sp)
    80005464:	f84a                	sd	s2,48(sp)
    80005466:	f44e                	sd	s3,40(sp)
    80005468:	f052                	sd	s4,32(sp)
    8000546a:	ec56                	sd	s5,24(sp)
    8000546c:	e85a                	sd	s6,16(sp)
    8000546e:	0880                	addi	s0,sp,80
    80005470:	84aa                	mv	s1,a0
    80005472:	892e                	mv	s2,a1
    80005474:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005476:	ffffc097          	auipc	ra,0xffffc
    8000547a:	6ec080e7          	jalr	1772(ra) # 80001b62 <myproc>
    8000547e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffc097          	auipc	ra,0xffffc
    80005486:	848080e7          	jalr	-1976(ra) # 80000cca <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000548a:	2184a703          	lw	a4,536(s1)
    8000548e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005492:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005496:	02f71763          	bne	a4,a5,800054c4 <piperead+0x68>
    8000549a:	2244a783          	lw	a5,548(s1)
    8000549e:	c39d                	beqz	a5,800054c4 <piperead+0x68>
    if(killed(pr)){
    800054a0:	8552                	mv	a0,s4
    800054a2:	ffffd097          	auipc	ra,0xffffd
    800054a6:	1e2080e7          	jalr	482(ra) # 80002684 <killed>
    800054aa:	e949                	bnez	a0,8000553c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054ac:	85a6                	mv	a1,s1
    800054ae:	854e                	mv	a0,s3
    800054b0:	ffffd097          	auipc	ra,0xffffd
    800054b4:	f14080e7          	jalr	-236(ra) # 800023c4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054b8:	2184a703          	lw	a4,536(s1)
    800054bc:	21c4a783          	lw	a5,540(s1)
    800054c0:	fcf70de3          	beq	a4,a5,8000549a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054c4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054c6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054c8:	05505463          	blez	s5,80005510 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800054cc:	2184a783          	lw	a5,536(s1)
    800054d0:	21c4a703          	lw	a4,540(s1)
    800054d4:	02f70e63          	beq	a4,a5,80005510 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800054d8:	0017871b          	addiw	a4,a5,1
    800054dc:	20e4ac23          	sw	a4,536(s1)
    800054e0:	1ff7f793          	andi	a5,a5,511
    800054e4:	97a6                	add	a5,a5,s1
    800054e6:	0187c783          	lbu	a5,24(a5)
    800054ea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054ee:	4685                	li	a3,1
    800054f0:	fbf40613          	addi	a2,s0,-65
    800054f4:	85ca                	mv	a1,s2
    800054f6:	050a3503          	ld	a0,80(s4)
    800054fa:	ffffc097          	auipc	ra,0xffffc
    800054fe:	262080e7          	jalr	610(ra) # 8000175c <copyout>
    80005502:	01650763          	beq	a0,s6,80005510 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005506:	2985                	addiw	s3,s3,1
    80005508:	0905                	addi	s2,s2,1
    8000550a:	fd3a91e3          	bne	s5,s3,800054cc <piperead+0x70>
    8000550e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005510:	21c48513          	addi	a0,s1,540
    80005514:	ffffd097          	auipc	ra,0xffffd
    80005518:	f20080e7          	jalr	-224(ra) # 80002434 <wakeup>
  release(&pi->lock);
    8000551c:	8526                	mv	a0,s1
    8000551e:	ffffc097          	auipc	ra,0xffffc
    80005522:	860080e7          	jalr	-1952(ra) # 80000d7e <release>
  return i;
}
    80005526:	854e                	mv	a0,s3
    80005528:	60a6                	ld	ra,72(sp)
    8000552a:	6406                	ld	s0,64(sp)
    8000552c:	74e2                	ld	s1,56(sp)
    8000552e:	7942                	ld	s2,48(sp)
    80005530:	79a2                	ld	s3,40(sp)
    80005532:	7a02                	ld	s4,32(sp)
    80005534:	6ae2                	ld	s5,24(sp)
    80005536:	6b42                	ld	s6,16(sp)
    80005538:	6161                	addi	sp,sp,80
    8000553a:	8082                	ret
      release(&pi->lock);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	840080e7          	jalr	-1984(ra) # 80000d7e <release>
      return -1;
    80005546:	59fd                	li	s3,-1
    80005548:	bff9                	j	80005526 <piperead+0xca>

000000008000554a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000554a:	1141                	addi	sp,sp,-16
    8000554c:	e422                	sd	s0,8(sp)
    8000554e:	0800                	addi	s0,sp,16
    80005550:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005552:	8905                	andi	a0,a0,1
    80005554:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005556:	8b89                	andi	a5,a5,2
    80005558:	c399                	beqz	a5,8000555e <flags2perm+0x14>
      perm |= PTE_W;
    8000555a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000555e:	6422                	ld	s0,8(sp)
    80005560:	0141                	addi	sp,sp,16
    80005562:	8082                	ret

0000000080005564 <exec>:

int
exec(char *path, char **argv)
{
    80005564:	de010113          	addi	sp,sp,-544
    80005568:	20113c23          	sd	ra,536(sp)
    8000556c:	20813823          	sd	s0,528(sp)
    80005570:	20913423          	sd	s1,520(sp)
    80005574:	21213023          	sd	s2,512(sp)
    80005578:	ffce                	sd	s3,504(sp)
    8000557a:	fbd2                	sd	s4,496(sp)
    8000557c:	f7d6                	sd	s5,488(sp)
    8000557e:	f3da                	sd	s6,480(sp)
    80005580:	efde                	sd	s7,472(sp)
    80005582:	ebe2                	sd	s8,464(sp)
    80005584:	e7e6                	sd	s9,456(sp)
    80005586:	e3ea                	sd	s10,448(sp)
    80005588:	ff6e                	sd	s11,440(sp)
    8000558a:	1400                	addi	s0,sp,544
    8000558c:	892a                	mv	s2,a0
    8000558e:	dea43423          	sd	a0,-536(s0)
    80005592:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	5cc080e7          	jalr	1484(ra) # 80001b62 <myproc>
    8000559e:	84aa                	mv	s1,a0

  begin_op();
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	482080e7          	jalr	1154(ra) # 80004a22 <begin_op>

  if((ip = namei(path)) == 0){
    800055a8:	854a                	mv	a0,s2
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	258080e7          	jalr	600(ra) # 80004802 <namei>
    800055b2:	c93d                	beqz	a0,80005628 <exec+0xc4>
    800055b4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	aa0080e7          	jalr	-1376(ra) # 80004056 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800055be:	04000713          	li	a4,64
    800055c2:	4681                	li	a3,0
    800055c4:	e5040613          	addi	a2,s0,-432
    800055c8:	4581                	li	a1,0
    800055ca:	8556                	mv	a0,s5
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	d3e080e7          	jalr	-706(ra) # 8000430a <readi>
    800055d4:	04000793          	li	a5,64
    800055d8:	00f51a63          	bne	a0,a5,800055ec <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800055dc:	e5042703          	lw	a4,-432(s0)
    800055e0:	464c47b7          	lui	a5,0x464c4
    800055e4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800055e8:	04f70663          	beq	a4,a5,80005634 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055ec:	8556                	mv	a0,s5
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	cca080e7          	jalr	-822(ra) # 800042b8 <iunlockput>
    end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	4aa080e7          	jalr	1194(ra) # 80004aa0 <end_op>
  }
  return -1;
    800055fe:	557d                	li	a0,-1
}
    80005600:	21813083          	ld	ra,536(sp)
    80005604:	21013403          	ld	s0,528(sp)
    80005608:	20813483          	ld	s1,520(sp)
    8000560c:	20013903          	ld	s2,512(sp)
    80005610:	79fe                	ld	s3,504(sp)
    80005612:	7a5e                	ld	s4,496(sp)
    80005614:	7abe                	ld	s5,488(sp)
    80005616:	7b1e                	ld	s6,480(sp)
    80005618:	6bfe                	ld	s7,472(sp)
    8000561a:	6c5e                	ld	s8,464(sp)
    8000561c:	6cbe                	ld	s9,456(sp)
    8000561e:	6d1e                	ld	s10,448(sp)
    80005620:	7dfa                	ld	s11,440(sp)
    80005622:	22010113          	addi	sp,sp,544
    80005626:	8082                	ret
    end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	478080e7          	jalr	1144(ra) # 80004aa0 <end_op>
    return -1;
    80005630:	557d                	li	a0,-1
    80005632:	b7f9                	j	80005600 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005634:	8526                	mv	a0,s1
    80005636:	ffffc097          	auipc	ra,0xffffc
    8000563a:	5f0080e7          	jalr	1520(ra) # 80001c26 <proc_pagetable>
    8000563e:	8b2a                	mv	s6,a0
    80005640:	d555                	beqz	a0,800055ec <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005642:	e7042783          	lw	a5,-400(s0)
    80005646:	e8845703          	lhu	a4,-376(s0)
    8000564a:	c735                	beqz	a4,800056b6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000564c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000564e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005652:	6a05                	lui	s4,0x1
    80005654:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005658:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000565c:	6d85                	lui	s11,0x1
    8000565e:	7d7d                	lui	s10,0xfffff
    80005660:	ac3d                	j	8000589e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005662:	00003517          	auipc	a0,0x3
    80005666:	0f650513          	addi	a0,a0,246 # 80008758 <syscalls+0x2a8>
    8000566a:	ffffb097          	auipc	ra,0xffffb
    8000566e:	ed6080e7          	jalr	-298(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005672:	874a                	mv	a4,s2
    80005674:	009c86bb          	addw	a3,s9,s1
    80005678:	4581                	li	a1,0
    8000567a:	8556                	mv	a0,s5
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	c8e080e7          	jalr	-882(ra) # 8000430a <readi>
    80005684:	2501                	sext.w	a0,a0
    80005686:	1aa91963          	bne	s2,a0,80005838 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000568a:	009d84bb          	addw	s1,s11,s1
    8000568e:	013d09bb          	addw	s3,s10,s3
    80005692:	1f74f663          	bgeu	s1,s7,8000587e <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005696:	02049593          	slli	a1,s1,0x20
    8000569a:	9181                	srli	a1,a1,0x20
    8000569c:	95e2                	add	a1,a1,s8
    8000569e:	855a                	mv	a0,s6
    800056a0:	ffffc097          	auipc	ra,0xffffc
    800056a4:	ab0080e7          	jalr	-1360(ra) # 80001150 <walkaddr>
    800056a8:	862a                	mv	a2,a0
    if(pa == 0)
    800056aa:	dd45                	beqz	a0,80005662 <exec+0xfe>
      n = PGSIZE;
    800056ac:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800056ae:	fd49f2e3          	bgeu	s3,s4,80005672 <exec+0x10e>
      n = sz - i;
    800056b2:	894e                	mv	s2,s3
    800056b4:	bf7d                	j	80005672 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056b6:	4901                	li	s2,0
  iunlockput(ip);
    800056b8:	8556                	mv	a0,s5
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	bfe080e7          	jalr	-1026(ra) # 800042b8 <iunlockput>
  end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	3de080e7          	jalr	990(ra) # 80004aa0 <end_op>
  p = myproc();
    800056ca:	ffffc097          	auipc	ra,0xffffc
    800056ce:	498080e7          	jalr	1176(ra) # 80001b62 <myproc>
    800056d2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800056d4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800056d8:	6785                	lui	a5,0x1
    800056da:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800056dc:	97ca                	add	a5,a5,s2
    800056de:	777d                	lui	a4,0xfffff
    800056e0:	8ff9                	and	a5,a5,a4
    800056e2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800056e6:	4691                	li	a3,4
    800056e8:	6609                	lui	a2,0x2
    800056ea:	963e                	add	a2,a2,a5
    800056ec:	85be                	mv	a1,a5
    800056ee:	855a                	mv	a0,s6
    800056f0:	ffffc097          	auipc	ra,0xffffc
    800056f4:	e14080e7          	jalr	-492(ra) # 80001504 <uvmalloc>
    800056f8:	8c2a                	mv	s8,a0
  ip = 0;
    800056fa:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800056fc:	12050e63          	beqz	a0,80005838 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005700:	75f9                	lui	a1,0xffffe
    80005702:	95aa                	add	a1,a1,a0
    80005704:	855a                	mv	a0,s6
    80005706:	ffffc097          	auipc	ra,0xffffc
    8000570a:	024080e7          	jalr	36(ra) # 8000172a <uvmclear>
  stackbase = sp - PGSIZE;
    8000570e:	7afd                	lui	s5,0xfffff
    80005710:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005712:	df043783          	ld	a5,-528(s0)
    80005716:	6388                	ld	a0,0(a5)
    80005718:	c925                	beqz	a0,80005788 <exec+0x224>
    8000571a:	e9040993          	addi	s3,s0,-368
    8000571e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005722:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005724:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005726:	ffffc097          	auipc	ra,0xffffc
    8000572a:	81c080e7          	jalr	-2020(ra) # 80000f42 <strlen>
    8000572e:	0015079b          	addiw	a5,a0,1
    80005732:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005736:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000573a:	13596663          	bltu	s2,s5,80005866 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000573e:	df043d83          	ld	s11,-528(s0)
    80005742:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005746:	8552                	mv	a0,s4
    80005748:	ffffb097          	auipc	ra,0xffffb
    8000574c:	7fa080e7          	jalr	2042(ra) # 80000f42 <strlen>
    80005750:	0015069b          	addiw	a3,a0,1
    80005754:	8652                	mv	a2,s4
    80005756:	85ca                	mv	a1,s2
    80005758:	855a                	mv	a0,s6
    8000575a:	ffffc097          	auipc	ra,0xffffc
    8000575e:	002080e7          	jalr	2(ra) # 8000175c <copyout>
    80005762:	10054663          	bltz	a0,8000586e <exec+0x30a>
    ustack[argc] = sp;
    80005766:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000576a:	0485                	addi	s1,s1,1
    8000576c:	008d8793          	addi	a5,s11,8
    80005770:	def43823          	sd	a5,-528(s0)
    80005774:	008db503          	ld	a0,8(s11)
    80005778:	c911                	beqz	a0,8000578c <exec+0x228>
    if(argc >= MAXARG)
    8000577a:	09a1                	addi	s3,s3,8
    8000577c:	fb3c95e3          	bne	s9,s3,80005726 <exec+0x1c2>
  sz = sz1;
    80005780:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005784:	4a81                	li	s5,0
    80005786:	a84d                	j	80005838 <exec+0x2d4>
  sp = sz;
    80005788:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000578a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000578c:	00349793          	slli	a5,s1,0x3
    80005790:	f9078793          	addi	a5,a5,-112
    80005794:	97a2                	add	a5,a5,s0
    80005796:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000579a:	00148693          	addi	a3,s1,1
    8000579e:	068e                	slli	a3,a3,0x3
    800057a0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800057a4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800057a8:	01597663          	bgeu	s2,s5,800057b4 <exec+0x250>
  sz = sz1;
    800057ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057b0:	4a81                	li	s5,0
    800057b2:	a059                	j	80005838 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800057b4:	e9040613          	addi	a2,s0,-368
    800057b8:	85ca                	mv	a1,s2
    800057ba:	855a                	mv	a0,s6
    800057bc:	ffffc097          	auipc	ra,0xffffc
    800057c0:	fa0080e7          	jalr	-96(ra) # 8000175c <copyout>
    800057c4:	0a054963          	bltz	a0,80005876 <exec+0x312>
  p->trapframe->a1 = sp;
    800057c8:	058bb783          	ld	a5,88(s7)
    800057cc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800057d0:	de843783          	ld	a5,-536(s0)
    800057d4:	0007c703          	lbu	a4,0(a5)
    800057d8:	cf11                	beqz	a4,800057f4 <exec+0x290>
    800057da:	0785                	addi	a5,a5,1
    if(*s == '/')
    800057dc:	02f00693          	li	a3,47
    800057e0:	a039                	j	800057ee <exec+0x28a>
      last = s+1;
    800057e2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800057e6:	0785                	addi	a5,a5,1
    800057e8:	fff7c703          	lbu	a4,-1(a5)
    800057ec:	c701                	beqz	a4,800057f4 <exec+0x290>
    if(*s == '/')
    800057ee:	fed71ce3          	bne	a4,a3,800057e6 <exec+0x282>
    800057f2:	bfc5                	j	800057e2 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800057f4:	4641                	li	a2,16
    800057f6:	de843583          	ld	a1,-536(s0)
    800057fa:	158b8513          	addi	a0,s7,344
    800057fe:	ffffb097          	auipc	ra,0xffffb
    80005802:	712080e7          	jalr	1810(ra) # 80000f10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005806:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000580a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000580e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005812:	058bb783          	ld	a5,88(s7)
    80005816:	e6843703          	ld	a4,-408(s0)
    8000581a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000581c:	058bb783          	ld	a5,88(s7)
    80005820:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005824:	85ea                	mv	a1,s10
    80005826:	ffffc097          	auipc	ra,0xffffc
    8000582a:	49c080e7          	jalr	1180(ra) # 80001cc2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000582e:	0004851b          	sext.w	a0,s1
    80005832:	b3f9                	j	80005600 <exec+0x9c>
    80005834:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005838:	df843583          	ld	a1,-520(s0)
    8000583c:	855a                	mv	a0,s6
    8000583e:	ffffc097          	auipc	ra,0xffffc
    80005842:	484080e7          	jalr	1156(ra) # 80001cc2 <proc_freepagetable>
  if(ip){
    80005846:	da0a93e3          	bnez	s5,800055ec <exec+0x88>
  return -1;
    8000584a:	557d                	li	a0,-1
    8000584c:	bb55                	j	80005600 <exec+0x9c>
    8000584e:	df243c23          	sd	s2,-520(s0)
    80005852:	b7dd                	j	80005838 <exec+0x2d4>
    80005854:	df243c23          	sd	s2,-520(s0)
    80005858:	b7c5                	j	80005838 <exec+0x2d4>
    8000585a:	df243c23          	sd	s2,-520(s0)
    8000585e:	bfe9                	j	80005838 <exec+0x2d4>
    80005860:	df243c23          	sd	s2,-520(s0)
    80005864:	bfd1                	j	80005838 <exec+0x2d4>
  sz = sz1;
    80005866:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000586a:	4a81                	li	s5,0
    8000586c:	b7f1                	j	80005838 <exec+0x2d4>
  sz = sz1;
    8000586e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005872:	4a81                	li	s5,0
    80005874:	b7d1                	j	80005838 <exec+0x2d4>
  sz = sz1;
    80005876:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000587a:	4a81                	li	s5,0
    8000587c:	bf75                	j	80005838 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000587e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005882:	e0843783          	ld	a5,-504(s0)
    80005886:	0017869b          	addiw	a3,a5,1
    8000588a:	e0d43423          	sd	a3,-504(s0)
    8000588e:	e0043783          	ld	a5,-512(s0)
    80005892:	0387879b          	addiw	a5,a5,56
    80005896:	e8845703          	lhu	a4,-376(s0)
    8000589a:	e0e6dfe3          	bge	a3,a4,800056b8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000589e:	2781                	sext.w	a5,a5
    800058a0:	e0f43023          	sd	a5,-512(s0)
    800058a4:	03800713          	li	a4,56
    800058a8:	86be                	mv	a3,a5
    800058aa:	e1840613          	addi	a2,s0,-488
    800058ae:	4581                	li	a1,0
    800058b0:	8556                	mv	a0,s5
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	a58080e7          	jalr	-1448(ra) # 8000430a <readi>
    800058ba:	03800793          	li	a5,56
    800058be:	f6f51be3          	bne	a0,a5,80005834 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800058c2:	e1842783          	lw	a5,-488(s0)
    800058c6:	4705                	li	a4,1
    800058c8:	fae79de3          	bne	a5,a4,80005882 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800058cc:	e4043483          	ld	s1,-448(s0)
    800058d0:	e3843783          	ld	a5,-456(s0)
    800058d4:	f6f4ede3          	bltu	s1,a5,8000584e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800058d8:	e2843783          	ld	a5,-472(s0)
    800058dc:	94be                	add	s1,s1,a5
    800058de:	f6f4ebe3          	bltu	s1,a5,80005854 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800058e2:	de043703          	ld	a4,-544(s0)
    800058e6:	8ff9                	and	a5,a5,a4
    800058e8:	fbad                	bnez	a5,8000585a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800058ea:	e1c42503          	lw	a0,-484(s0)
    800058ee:	00000097          	auipc	ra,0x0
    800058f2:	c5c080e7          	jalr	-932(ra) # 8000554a <flags2perm>
    800058f6:	86aa                	mv	a3,a0
    800058f8:	8626                	mv	a2,s1
    800058fa:	85ca                	mv	a1,s2
    800058fc:	855a                	mv	a0,s6
    800058fe:	ffffc097          	auipc	ra,0xffffc
    80005902:	c06080e7          	jalr	-1018(ra) # 80001504 <uvmalloc>
    80005906:	dea43c23          	sd	a0,-520(s0)
    8000590a:	d939                	beqz	a0,80005860 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000590c:	e2843c03          	ld	s8,-472(s0)
    80005910:	e2042c83          	lw	s9,-480(s0)
    80005914:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005918:	f60b83e3          	beqz	s7,8000587e <exec+0x31a>
    8000591c:	89de                	mv	s3,s7
    8000591e:	4481                	li	s1,0
    80005920:	bb9d                	j	80005696 <exec+0x132>

0000000080005922 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005922:	7179                	addi	sp,sp,-48
    80005924:	f406                	sd	ra,40(sp)
    80005926:	f022                	sd	s0,32(sp)
    80005928:	ec26                	sd	s1,24(sp)
    8000592a:	e84a                	sd	s2,16(sp)
    8000592c:	1800                	addi	s0,sp,48
    8000592e:	892e                	mv	s2,a1
    80005930:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005932:	fdc40593          	addi	a1,s0,-36
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	a46080e7          	jalr	-1466(ra) # 8000337c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000593e:	fdc42703          	lw	a4,-36(s0)
    80005942:	47bd                	li	a5,15
    80005944:	02e7eb63          	bltu	a5,a4,8000597a <argfd+0x58>
    80005948:	ffffc097          	auipc	ra,0xffffc
    8000594c:	21a080e7          	jalr	538(ra) # 80001b62 <myproc>
    80005950:	fdc42703          	lw	a4,-36(s0)
    80005954:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbbc12>
    80005958:	078e                	slli	a5,a5,0x3
    8000595a:	953e                	add	a0,a0,a5
    8000595c:	611c                	ld	a5,0(a0)
    8000595e:	c385                	beqz	a5,8000597e <argfd+0x5c>
    return -1;
  if(pfd)
    80005960:	00090463          	beqz	s2,80005968 <argfd+0x46>
    *pfd = fd;
    80005964:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005968:	4501                	li	a0,0
  if(pf)
    8000596a:	c091                	beqz	s1,8000596e <argfd+0x4c>
    *pf = f;
    8000596c:	e09c                	sd	a5,0(s1)
}
    8000596e:	70a2                	ld	ra,40(sp)
    80005970:	7402                	ld	s0,32(sp)
    80005972:	64e2                	ld	s1,24(sp)
    80005974:	6942                	ld	s2,16(sp)
    80005976:	6145                	addi	sp,sp,48
    80005978:	8082                	ret
    return -1;
    8000597a:	557d                	li	a0,-1
    8000597c:	bfcd                	j	8000596e <argfd+0x4c>
    8000597e:	557d                	li	a0,-1
    80005980:	b7fd                	j	8000596e <argfd+0x4c>

0000000080005982 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005982:	1101                	addi	sp,sp,-32
    80005984:	ec06                	sd	ra,24(sp)
    80005986:	e822                	sd	s0,16(sp)
    80005988:	e426                	sd	s1,8(sp)
    8000598a:	1000                	addi	s0,sp,32
    8000598c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000598e:	ffffc097          	auipc	ra,0xffffc
    80005992:	1d4080e7          	jalr	468(ra) # 80001b62 <myproc>
    80005996:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005998:	0d050793          	addi	a5,a0,208
    8000599c:	4501                	li	a0,0
    8000599e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800059a0:	6398                	ld	a4,0(a5)
    800059a2:	cb19                	beqz	a4,800059b8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800059a4:	2505                	addiw	a0,a0,1
    800059a6:	07a1                	addi	a5,a5,8
    800059a8:	fed51ce3          	bne	a0,a3,800059a0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800059ac:	557d                	li	a0,-1
}
    800059ae:	60e2                	ld	ra,24(sp)
    800059b0:	6442                	ld	s0,16(sp)
    800059b2:	64a2                	ld	s1,8(sp)
    800059b4:	6105                	addi	sp,sp,32
    800059b6:	8082                	ret
      p->ofile[fd] = f;
    800059b8:	01a50793          	addi	a5,a0,26
    800059bc:	078e                	slli	a5,a5,0x3
    800059be:	963e                	add	a2,a2,a5
    800059c0:	e204                	sd	s1,0(a2)
      return fd;
    800059c2:	b7f5                	j	800059ae <fdalloc+0x2c>

00000000800059c4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800059c4:	715d                	addi	sp,sp,-80
    800059c6:	e486                	sd	ra,72(sp)
    800059c8:	e0a2                	sd	s0,64(sp)
    800059ca:	fc26                	sd	s1,56(sp)
    800059cc:	f84a                	sd	s2,48(sp)
    800059ce:	f44e                	sd	s3,40(sp)
    800059d0:	f052                	sd	s4,32(sp)
    800059d2:	ec56                	sd	s5,24(sp)
    800059d4:	e85a                	sd	s6,16(sp)
    800059d6:	0880                	addi	s0,sp,80
    800059d8:	8b2e                	mv	s6,a1
    800059da:	89b2                	mv	s3,a2
    800059dc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800059de:	fb040593          	addi	a1,s0,-80
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	e3e080e7          	jalr	-450(ra) # 80004820 <nameiparent>
    800059ea:	84aa                	mv	s1,a0
    800059ec:	14050f63          	beqz	a0,80005b4a <create+0x186>
    return 0;

  ilock(dp);
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	666080e7          	jalr	1638(ra) # 80004056 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059f8:	4601                	li	a2,0
    800059fa:	fb040593          	addi	a1,s0,-80
    800059fe:	8526                	mv	a0,s1
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	b3a080e7          	jalr	-1222(ra) # 8000453a <dirlookup>
    80005a08:	8aaa                	mv	s5,a0
    80005a0a:	c931                	beqz	a0,80005a5e <create+0x9a>
    iunlockput(dp);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	8aa080e7          	jalr	-1878(ra) # 800042b8 <iunlockput>
    ilock(ip);
    80005a16:	8556                	mv	a0,s5
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	63e080e7          	jalr	1598(ra) # 80004056 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005a20:	000b059b          	sext.w	a1,s6
    80005a24:	4789                	li	a5,2
    80005a26:	02f59563          	bne	a1,a5,80005a50 <create+0x8c>
    80005a2a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbbc3c>
    80005a2e:	37f9                	addiw	a5,a5,-2
    80005a30:	17c2                	slli	a5,a5,0x30
    80005a32:	93c1                	srli	a5,a5,0x30
    80005a34:	4705                	li	a4,1
    80005a36:	00f76d63          	bltu	a4,a5,80005a50 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005a3a:	8556                	mv	a0,s5
    80005a3c:	60a6                	ld	ra,72(sp)
    80005a3e:	6406                	ld	s0,64(sp)
    80005a40:	74e2                	ld	s1,56(sp)
    80005a42:	7942                	ld	s2,48(sp)
    80005a44:	79a2                	ld	s3,40(sp)
    80005a46:	7a02                	ld	s4,32(sp)
    80005a48:	6ae2                	ld	s5,24(sp)
    80005a4a:	6b42                	ld	s6,16(sp)
    80005a4c:	6161                	addi	sp,sp,80
    80005a4e:	8082                	ret
    iunlockput(ip);
    80005a50:	8556                	mv	a0,s5
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	866080e7          	jalr	-1946(ra) # 800042b8 <iunlockput>
    return 0;
    80005a5a:	4a81                	li	s5,0
    80005a5c:	bff9                	j	80005a3a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005a5e:	85da                	mv	a1,s6
    80005a60:	4088                	lw	a0,0(s1)
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	456080e7          	jalr	1110(ra) # 80003eb8 <ialloc>
    80005a6a:	8a2a                	mv	s4,a0
    80005a6c:	c539                	beqz	a0,80005aba <create+0xf6>
  ilock(ip);
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	5e8080e7          	jalr	1512(ra) # 80004056 <ilock>
  ip->major = major;
    80005a76:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005a7a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005a7e:	4905                	li	s2,1
    80005a80:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005a84:	8552                	mv	a0,s4
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	504080e7          	jalr	1284(ra) # 80003f8a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a8e:	000b059b          	sext.w	a1,s6
    80005a92:	03258b63          	beq	a1,s2,80005ac8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a96:	004a2603          	lw	a2,4(s4)
    80005a9a:	fb040593          	addi	a1,s0,-80
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	cb0080e7          	jalr	-848(ra) # 80004750 <dirlink>
    80005aa8:	06054f63          	bltz	a0,80005b26 <create+0x162>
  iunlockput(dp);
    80005aac:	8526                	mv	a0,s1
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	80a080e7          	jalr	-2038(ra) # 800042b8 <iunlockput>
  return ip;
    80005ab6:	8ad2                	mv	s5,s4
    80005ab8:	b749                	j	80005a3a <create+0x76>
    iunlockput(dp);
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	7fc080e7          	jalr	2044(ra) # 800042b8 <iunlockput>
    return 0;
    80005ac4:	8ad2                	mv	s5,s4
    80005ac6:	bf95                	j	80005a3a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005ac8:	004a2603          	lw	a2,4(s4)
    80005acc:	00003597          	auipc	a1,0x3
    80005ad0:	cac58593          	addi	a1,a1,-852 # 80008778 <syscalls+0x2c8>
    80005ad4:	8552                	mv	a0,s4
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	c7a080e7          	jalr	-902(ra) # 80004750 <dirlink>
    80005ade:	04054463          	bltz	a0,80005b26 <create+0x162>
    80005ae2:	40d0                	lw	a2,4(s1)
    80005ae4:	00003597          	auipc	a1,0x3
    80005ae8:	c9c58593          	addi	a1,a1,-868 # 80008780 <syscalls+0x2d0>
    80005aec:	8552                	mv	a0,s4
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	c62080e7          	jalr	-926(ra) # 80004750 <dirlink>
    80005af6:	02054863          	bltz	a0,80005b26 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005afa:	004a2603          	lw	a2,4(s4)
    80005afe:	fb040593          	addi	a1,s0,-80
    80005b02:	8526                	mv	a0,s1
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	c4c080e7          	jalr	-948(ra) # 80004750 <dirlink>
    80005b0c:	00054d63          	bltz	a0,80005b26 <create+0x162>
    dp->nlink++;  // for ".."
    80005b10:	04a4d783          	lhu	a5,74(s1)
    80005b14:	2785                	addiw	a5,a5,1
    80005b16:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	46e080e7          	jalr	1134(ra) # 80003f8a <iupdate>
    80005b24:	b761                	j	80005aac <create+0xe8>
  ip->nlink = 0;
    80005b26:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005b2a:	8552                	mv	a0,s4
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	45e080e7          	jalr	1118(ra) # 80003f8a <iupdate>
  iunlockput(ip);
    80005b34:	8552                	mv	a0,s4
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	782080e7          	jalr	1922(ra) # 800042b8 <iunlockput>
  iunlockput(dp);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	778080e7          	jalr	1912(ra) # 800042b8 <iunlockput>
  return 0;
    80005b48:	bdcd                	j	80005a3a <create+0x76>
    return 0;
    80005b4a:	8aaa                	mv	s5,a0
    80005b4c:	b5fd                	j	80005a3a <create+0x76>

0000000080005b4e <sys_dup>:
{
    80005b4e:	7179                	addi	sp,sp,-48
    80005b50:	f406                	sd	ra,40(sp)
    80005b52:	f022                	sd	s0,32(sp)
    80005b54:	ec26                	sd	s1,24(sp)
    80005b56:	e84a                	sd	s2,16(sp)
    80005b58:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005b5a:	fd840613          	addi	a2,s0,-40
    80005b5e:	4581                	li	a1,0
    80005b60:	4501                	li	a0,0
    80005b62:	00000097          	auipc	ra,0x0
    80005b66:	dc0080e7          	jalr	-576(ra) # 80005922 <argfd>
    return -1;
    80005b6a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b6c:	02054363          	bltz	a0,80005b92 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005b70:	fd843903          	ld	s2,-40(s0)
    80005b74:	854a                	mv	a0,s2
    80005b76:	00000097          	auipc	ra,0x0
    80005b7a:	e0c080e7          	jalr	-500(ra) # 80005982 <fdalloc>
    80005b7e:	84aa                	mv	s1,a0
    return -1;
    80005b80:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b82:	00054863          	bltz	a0,80005b92 <sys_dup+0x44>
  filedup(f);
    80005b86:	854a                	mv	a0,s2
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	310080e7          	jalr	784(ra) # 80004e98 <filedup>
  return fd;
    80005b90:	87a6                	mv	a5,s1
}
    80005b92:	853e                	mv	a0,a5
    80005b94:	70a2                	ld	ra,40(sp)
    80005b96:	7402                	ld	s0,32(sp)
    80005b98:	64e2                	ld	s1,24(sp)
    80005b9a:	6942                	ld	s2,16(sp)
    80005b9c:	6145                	addi	sp,sp,48
    80005b9e:	8082                	ret

0000000080005ba0 <sys_read>:
{
    80005ba0:	7179                	addi	sp,sp,-48
    80005ba2:	f406                	sd	ra,40(sp)
    80005ba4:	f022                	sd	s0,32(sp)
    80005ba6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ba8:	fd840593          	addi	a1,s0,-40
    80005bac:	4505                	li	a0,1
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	7ee080e7          	jalr	2030(ra) # 8000339c <argaddr>
  argint(2, &n);
    80005bb6:	fe440593          	addi	a1,s0,-28
    80005bba:	4509                	li	a0,2
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	7c0080e7          	jalr	1984(ra) # 8000337c <argint>
  if(argfd(0, 0, &f) < 0)
    80005bc4:	fe840613          	addi	a2,s0,-24
    80005bc8:	4581                	li	a1,0
    80005bca:	4501                	li	a0,0
    80005bcc:	00000097          	auipc	ra,0x0
    80005bd0:	d56080e7          	jalr	-682(ra) # 80005922 <argfd>
    80005bd4:	87aa                	mv	a5,a0
    return -1;
    80005bd6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005bd8:	0007cc63          	bltz	a5,80005bf0 <sys_read+0x50>
  return fileread(f, p, n);
    80005bdc:	fe442603          	lw	a2,-28(s0)
    80005be0:	fd843583          	ld	a1,-40(s0)
    80005be4:	fe843503          	ld	a0,-24(s0)
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	43c080e7          	jalr	1084(ra) # 80005024 <fileread>
}
    80005bf0:	70a2                	ld	ra,40(sp)
    80005bf2:	7402                	ld	s0,32(sp)
    80005bf4:	6145                	addi	sp,sp,48
    80005bf6:	8082                	ret

0000000080005bf8 <sys_write>:
{
    80005bf8:	7179                	addi	sp,sp,-48
    80005bfa:	f406                	sd	ra,40(sp)
    80005bfc:	f022                	sd	s0,32(sp)
    80005bfe:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005c00:	fd840593          	addi	a1,s0,-40
    80005c04:	4505                	li	a0,1
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	796080e7          	jalr	1942(ra) # 8000339c <argaddr>
  argint(2, &n);
    80005c0e:	fe440593          	addi	a1,s0,-28
    80005c12:	4509                	li	a0,2
    80005c14:	ffffd097          	auipc	ra,0xffffd
    80005c18:	768080e7          	jalr	1896(ra) # 8000337c <argint>
  if(argfd(0, 0, &f) < 0)
    80005c1c:	fe840613          	addi	a2,s0,-24
    80005c20:	4581                	li	a1,0
    80005c22:	4501                	li	a0,0
    80005c24:	00000097          	auipc	ra,0x0
    80005c28:	cfe080e7          	jalr	-770(ra) # 80005922 <argfd>
    80005c2c:	87aa                	mv	a5,a0
    return -1;
    80005c2e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c30:	0007cc63          	bltz	a5,80005c48 <sys_write+0x50>
  return filewrite(f, p, n);
    80005c34:	fe442603          	lw	a2,-28(s0)
    80005c38:	fd843583          	ld	a1,-40(s0)
    80005c3c:	fe843503          	ld	a0,-24(s0)
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	4a6080e7          	jalr	1190(ra) # 800050e6 <filewrite>
}
    80005c48:	70a2                	ld	ra,40(sp)
    80005c4a:	7402                	ld	s0,32(sp)
    80005c4c:	6145                	addi	sp,sp,48
    80005c4e:	8082                	ret

0000000080005c50 <sys_close>:
{
    80005c50:	1101                	addi	sp,sp,-32
    80005c52:	ec06                	sd	ra,24(sp)
    80005c54:	e822                	sd	s0,16(sp)
    80005c56:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005c58:	fe040613          	addi	a2,s0,-32
    80005c5c:	fec40593          	addi	a1,s0,-20
    80005c60:	4501                	li	a0,0
    80005c62:	00000097          	auipc	ra,0x0
    80005c66:	cc0080e7          	jalr	-832(ra) # 80005922 <argfd>
    return -1;
    80005c6a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c6c:	02054463          	bltz	a0,80005c94 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c70:	ffffc097          	auipc	ra,0xffffc
    80005c74:	ef2080e7          	jalr	-270(ra) # 80001b62 <myproc>
    80005c78:	fec42783          	lw	a5,-20(s0)
    80005c7c:	07e9                	addi	a5,a5,26
    80005c7e:	078e                	slli	a5,a5,0x3
    80005c80:	953e                	add	a0,a0,a5
    80005c82:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005c86:	fe043503          	ld	a0,-32(s0)
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	260080e7          	jalr	608(ra) # 80004eea <fileclose>
  return 0;
    80005c92:	4781                	li	a5,0
}
    80005c94:	853e                	mv	a0,a5
    80005c96:	60e2                	ld	ra,24(sp)
    80005c98:	6442                	ld	s0,16(sp)
    80005c9a:	6105                	addi	sp,sp,32
    80005c9c:	8082                	ret

0000000080005c9e <sys_fstat>:
{
    80005c9e:	1101                	addi	sp,sp,-32
    80005ca0:	ec06                	sd	ra,24(sp)
    80005ca2:	e822                	sd	s0,16(sp)
    80005ca4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005ca6:	fe040593          	addi	a1,s0,-32
    80005caa:	4505                	li	a0,1
    80005cac:	ffffd097          	auipc	ra,0xffffd
    80005cb0:	6f0080e7          	jalr	1776(ra) # 8000339c <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005cb4:	fe840613          	addi	a2,s0,-24
    80005cb8:	4581                	li	a1,0
    80005cba:	4501                	li	a0,0
    80005cbc:	00000097          	auipc	ra,0x0
    80005cc0:	c66080e7          	jalr	-922(ra) # 80005922 <argfd>
    80005cc4:	87aa                	mv	a5,a0
    return -1;
    80005cc6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005cc8:	0007ca63          	bltz	a5,80005cdc <sys_fstat+0x3e>
  return filestat(f, st);
    80005ccc:	fe043583          	ld	a1,-32(s0)
    80005cd0:	fe843503          	ld	a0,-24(s0)
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	2de080e7          	jalr	734(ra) # 80004fb2 <filestat>
}
    80005cdc:	60e2                	ld	ra,24(sp)
    80005cde:	6442                	ld	s0,16(sp)
    80005ce0:	6105                	addi	sp,sp,32
    80005ce2:	8082                	ret

0000000080005ce4 <sys_link>:
{
    80005ce4:	7169                	addi	sp,sp,-304
    80005ce6:	f606                	sd	ra,296(sp)
    80005ce8:	f222                	sd	s0,288(sp)
    80005cea:	ee26                	sd	s1,280(sp)
    80005cec:	ea4a                	sd	s2,272(sp)
    80005cee:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cf0:	08000613          	li	a2,128
    80005cf4:	ed040593          	addi	a1,s0,-304
    80005cf8:	4501                	li	a0,0
    80005cfa:	ffffd097          	auipc	ra,0xffffd
    80005cfe:	6c2080e7          	jalr	1730(ra) # 800033bc <argstr>
    return -1;
    80005d02:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d04:	10054e63          	bltz	a0,80005e20 <sys_link+0x13c>
    80005d08:	08000613          	li	a2,128
    80005d0c:	f5040593          	addi	a1,s0,-176
    80005d10:	4505                	li	a0,1
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	6aa080e7          	jalr	1706(ra) # 800033bc <argstr>
    return -1;
    80005d1a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d1c:	10054263          	bltz	a0,80005e20 <sys_link+0x13c>
  begin_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	d02080e7          	jalr	-766(ra) # 80004a22 <begin_op>
  if((ip = namei(old)) == 0){
    80005d28:	ed040513          	addi	a0,s0,-304
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	ad6080e7          	jalr	-1322(ra) # 80004802 <namei>
    80005d34:	84aa                	mv	s1,a0
    80005d36:	c551                	beqz	a0,80005dc2 <sys_link+0xde>
  ilock(ip);
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	31e080e7          	jalr	798(ra) # 80004056 <ilock>
  if(ip->type == T_DIR){
    80005d40:	04449703          	lh	a4,68(s1)
    80005d44:	4785                	li	a5,1
    80005d46:	08f70463          	beq	a4,a5,80005dce <sys_link+0xea>
  ip->nlink++;
    80005d4a:	04a4d783          	lhu	a5,74(s1)
    80005d4e:	2785                	addiw	a5,a5,1
    80005d50:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d54:	8526                	mv	a0,s1
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	234080e7          	jalr	564(ra) # 80003f8a <iupdate>
  iunlock(ip);
    80005d5e:	8526                	mv	a0,s1
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	3b8080e7          	jalr	952(ra) # 80004118 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d68:	fd040593          	addi	a1,s0,-48
    80005d6c:	f5040513          	addi	a0,s0,-176
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	ab0080e7          	jalr	-1360(ra) # 80004820 <nameiparent>
    80005d78:	892a                	mv	s2,a0
    80005d7a:	c935                	beqz	a0,80005dee <sys_link+0x10a>
  ilock(dp);
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	2da080e7          	jalr	730(ra) # 80004056 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d84:	00092703          	lw	a4,0(s2)
    80005d88:	409c                	lw	a5,0(s1)
    80005d8a:	04f71d63          	bne	a4,a5,80005de4 <sys_link+0x100>
    80005d8e:	40d0                	lw	a2,4(s1)
    80005d90:	fd040593          	addi	a1,s0,-48
    80005d94:	854a                	mv	a0,s2
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	9ba080e7          	jalr	-1606(ra) # 80004750 <dirlink>
    80005d9e:	04054363          	bltz	a0,80005de4 <sys_link+0x100>
  iunlockput(dp);
    80005da2:	854a                	mv	a0,s2
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	514080e7          	jalr	1300(ra) # 800042b8 <iunlockput>
  iput(ip);
    80005dac:	8526                	mv	a0,s1
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	462080e7          	jalr	1122(ra) # 80004210 <iput>
  end_op();
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	cea080e7          	jalr	-790(ra) # 80004aa0 <end_op>
  return 0;
    80005dbe:	4781                	li	a5,0
    80005dc0:	a085                	j	80005e20 <sys_link+0x13c>
    end_op();
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	cde080e7          	jalr	-802(ra) # 80004aa0 <end_op>
    return -1;
    80005dca:	57fd                	li	a5,-1
    80005dcc:	a891                	j	80005e20 <sys_link+0x13c>
    iunlockput(ip);
    80005dce:	8526                	mv	a0,s1
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	4e8080e7          	jalr	1256(ra) # 800042b8 <iunlockput>
    end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	cc8080e7          	jalr	-824(ra) # 80004aa0 <end_op>
    return -1;
    80005de0:	57fd                	li	a5,-1
    80005de2:	a83d                	j	80005e20 <sys_link+0x13c>
    iunlockput(dp);
    80005de4:	854a                	mv	a0,s2
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	4d2080e7          	jalr	1234(ra) # 800042b8 <iunlockput>
  ilock(ip);
    80005dee:	8526                	mv	a0,s1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	266080e7          	jalr	614(ra) # 80004056 <ilock>
  ip->nlink--;
    80005df8:	04a4d783          	lhu	a5,74(s1)
    80005dfc:	37fd                	addiw	a5,a5,-1
    80005dfe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	186080e7          	jalr	390(ra) # 80003f8a <iupdate>
  iunlockput(ip);
    80005e0c:	8526                	mv	a0,s1
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	4aa080e7          	jalr	1194(ra) # 800042b8 <iunlockput>
  end_op();
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	c8a080e7          	jalr	-886(ra) # 80004aa0 <end_op>
  return -1;
    80005e1e:	57fd                	li	a5,-1
}
    80005e20:	853e                	mv	a0,a5
    80005e22:	70b2                	ld	ra,296(sp)
    80005e24:	7412                	ld	s0,288(sp)
    80005e26:	64f2                	ld	s1,280(sp)
    80005e28:	6952                	ld	s2,272(sp)
    80005e2a:	6155                	addi	sp,sp,304
    80005e2c:	8082                	ret

0000000080005e2e <sys_unlink>:
{
    80005e2e:	7151                	addi	sp,sp,-240
    80005e30:	f586                	sd	ra,232(sp)
    80005e32:	f1a2                	sd	s0,224(sp)
    80005e34:	eda6                	sd	s1,216(sp)
    80005e36:	e9ca                	sd	s2,208(sp)
    80005e38:	e5ce                	sd	s3,200(sp)
    80005e3a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005e3c:	08000613          	li	a2,128
    80005e40:	f3040593          	addi	a1,s0,-208
    80005e44:	4501                	li	a0,0
    80005e46:	ffffd097          	auipc	ra,0xffffd
    80005e4a:	576080e7          	jalr	1398(ra) # 800033bc <argstr>
    80005e4e:	18054163          	bltz	a0,80005fd0 <sys_unlink+0x1a2>
  begin_op();
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	bd0080e7          	jalr	-1072(ra) # 80004a22 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e5a:	fb040593          	addi	a1,s0,-80
    80005e5e:	f3040513          	addi	a0,s0,-208
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	9be080e7          	jalr	-1602(ra) # 80004820 <nameiparent>
    80005e6a:	84aa                	mv	s1,a0
    80005e6c:	c979                	beqz	a0,80005f42 <sys_unlink+0x114>
  ilock(dp);
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	1e8080e7          	jalr	488(ra) # 80004056 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e76:	00003597          	auipc	a1,0x3
    80005e7a:	90258593          	addi	a1,a1,-1790 # 80008778 <syscalls+0x2c8>
    80005e7e:	fb040513          	addi	a0,s0,-80
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	69e080e7          	jalr	1694(ra) # 80004520 <namecmp>
    80005e8a:	14050a63          	beqz	a0,80005fde <sys_unlink+0x1b0>
    80005e8e:	00003597          	auipc	a1,0x3
    80005e92:	8f258593          	addi	a1,a1,-1806 # 80008780 <syscalls+0x2d0>
    80005e96:	fb040513          	addi	a0,s0,-80
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	686080e7          	jalr	1670(ra) # 80004520 <namecmp>
    80005ea2:	12050e63          	beqz	a0,80005fde <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ea6:	f2c40613          	addi	a2,s0,-212
    80005eaa:	fb040593          	addi	a1,s0,-80
    80005eae:	8526                	mv	a0,s1
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	68a080e7          	jalr	1674(ra) # 8000453a <dirlookup>
    80005eb8:	892a                	mv	s2,a0
    80005eba:	12050263          	beqz	a0,80005fde <sys_unlink+0x1b0>
  ilock(ip);
    80005ebe:	ffffe097          	auipc	ra,0xffffe
    80005ec2:	198080e7          	jalr	408(ra) # 80004056 <ilock>
  if(ip->nlink < 1)
    80005ec6:	04a91783          	lh	a5,74(s2)
    80005eca:	08f05263          	blez	a5,80005f4e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ece:	04491703          	lh	a4,68(s2)
    80005ed2:	4785                	li	a5,1
    80005ed4:	08f70563          	beq	a4,a5,80005f5e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ed8:	4641                	li	a2,16
    80005eda:	4581                	li	a1,0
    80005edc:	fc040513          	addi	a0,s0,-64
    80005ee0:	ffffb097          	auipc	ra,0xffffb
    80005ee4:	ee6080e7          	jalr	-282(ra) # 80000dc6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ee8:	4741                	li	a4,16
    80005eea:	f2c42683          	lw	a3,-212(s0)
    80005eee:	fc040613          	addi	a2,s0,-64
    80005ef2:	4581                	li	a1,0
    80005ef4:	8526                	mv	a0,s1
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	50c080e7          	jalr	1292(ra) # 80004402 <writei>
    80005efe:	47c1                	li	a5,16
    80005f00:	0af51563          	bne	a0,a5,80005faa <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005f04:	04491703          	lh	a4,68(s2)
    80005f08:	4785                	li	a5,1
    80005f0a:	0af70863          	beq	a4,a5,80005fba <sys_unlink+0x18c>
  iunlockput(dp);
    80005f0e:	8526                	mv	a0,s1
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	3a8080e7          	jalr	936(ra) # 800042b8 <iunlockput>
  ip->nlink--;
    80005f18:	04a95783          	lhu	a5,74(s2)
    80005f1c:	37fd                	addiw	a5,a5,-1
    80005f1e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005f22:	854a                	mv	a0,s2
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	066080e7          	jalr	102(ra) # 80003f8a <iupdate>
  iunlockput(ip);
    80005f2c:	854a                	mv	a0,s2
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	38a080e7          	jalr	906(ra) # 800042b8 <iunlockput>
  end_op();
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	b6a080e7          	jalr	-1174(ra) # 80004aa0 <end_op>
  return 0;
    80005f3e:	4501                	li	a0,0
    80005f40:	a84d                	j	80005ff2 <sys_unlink+0x1c4>
    end_op();
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	b5e080e7          	jalr	-1186(ra) # 80004aa0 <end_op>
    return -1;
    80005f4a:	557d                	li	a0,-1
    80005f4c:	a05d                	j	80005ff2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005f4e:	00003517          	auipc	a0,0x3
    80005f52:	83a50513          	addi	a0,a0,-1990 # 80008788 <syscalls+0x2d8>
    80005f56:	ffffa097          	auipc	ra,0xffffa
    80005f5a:	5ea080e7          	jalr	1514(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f5e:	04c92703          	lw	a4,76(s2)
    80005f62:	02000793          	li	a5,32
    80005f66:	f6e7f9e3          	bgeu	a5,a4,80005ed8 <sys_unlink+0xaa>
    80005f6a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f6e:	4741                	li	a4,16
    80005f70:	86ce                	mv	a3,s3
    80005f72:	f1840613          	addi	a2,s0,-232
    80005f76:	4581                	li	a1,0
    80005f78:	854a                	mv	a0,s2
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	390080e7          	jalr	912(ra) # 8000430a <readi>
    80005f82:	47c1                	li	a5,16
    80005f84:	00f51b63          	bne	a0,a5,80005f9a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f88:	f1845783          	lhu	a5,-232(s0)
    80005f8c:	e7a1                	bnez	a5,80005fd4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f8e:	29c1                	addiw	s3,s3,16
    80005f90:	04c92783          	lw	a5,76(s2)
    80005f94:	fcf9ede3          	bltu	s3,a5,80005f6e <sys_unlink+0x140>
    80005f98:	b781                	j	80005ed8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f9a:	00003517          	auipc	a0,0x3
    80005f9e:	80650513          	addi	a0,a0,-2042 # 800087a0 <syscalls+0x2f0>
    80005fa2:	ffffa097          	auipc	ra,0xffffa
    80005fa6:	59e080e7          	jalr	1438(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005faa:	00003517          	auipc	a0,0x3
    80005fae:	80e50513          	addi	a0,a0,-2034 # 800087b8 <syscalls+0x308>
    80005fb2:	ffffa097          	auipc	ra,0xffffa
    80005fb6:	58e080e7          	jalr	1422(ra) # 80000540 <panic>
    dp->nlink--;
    80005fba:	04a4d783          	lhu	a5,74(s1)
    80005fbe:	37fd                	addiw	a5,a5,-1
    80005fc0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005fc4:	8526                	mv	a0,s1
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	fc4080e7          	jalr	-60(ra) # 80003f8a <iupdate>
    80005fce:	b781                	j	80005f0e <sys_unlink+0xe0>
    return -1;
    80005fd0:	557d                	li	a0,-1
    80005fd2:	a005                	j	80005ff2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005fd4:	854a                	mv	a0,s2
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	2e2080e7          	jalr	738(ra) # 800042b8 <iunlockput>
  iunlockput(dp);
    80005fde:	8526                	mv	a0,s1
    80005fe0:	ffffe097          	auipc	ra,0xffffe
    80005fe4:	2d8080e7          	jalr	728(ra) # 800042b8 <iunlockput>
  end_op();
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	ab8080e7          	jalr	-1352(ra) # 80004aa0 <end_op>
  return -1;
    80005ff0:	557d                	li	a0,-1
}
    80005ff2:	70ae                	ld	ra,232(sp)
    80005ff4:	740e                	ld	s0,224(sp)
    80005ff6:	64ee                	ld	s1,216(sp)
    80005ff8:	694e                	ld	s2,208(sp)
    80005ffa:	69ae                	ld	s3,200(sp)
    80005ffc:	616d                	addi	sp,sp,240
    80005ffe:	8082                	ret

0000000080006000 <sys_open>:

uint64
sys_open(void)
{
    80006000:	7131                	addi	sp,sp,-192
    80006002:	fd06                	sd	ra,184(sp)
    80006004:	f922                	sd	s0,176(sp)
    80006006:	f526                	sd	s1,168(sp)
    80006008:	f14a                	sd	s2,160(sp)
    8000600a:	ed4e                	sd	s3,152(sp)
    8000600c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000600e:	f4c40593          	addi	a1,s0,-180
    80006012:	4505                	li	a0,1
    80006014:	ffffd097          	auipc	ra,0xffffd
    80006018:	368080e7          	jalr	872(ra) # 8000337c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000601c:	08000613          	li	a2,128
    80006020:	f5040593          	addi	a1,s0,-176
    80006024:	4501                	li	a0,0
    80006026:	ffffd097          	auipc	ra,0xffffd
    8000602a:	396080e7          	jalr	918(ra) # 800033bc <argstr>
    8000602e:	87aa                	mv	a5,a0
    return -1;
    80006030:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006032:	0a07c963          	bltz	a5,800060e4 <sys_open+0xe4>

  begin_op();
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	9ec080e7          	jalr	-1556(ra) # 80004a22 <begin_op>

  if(omode & O_CREATE){
    8000603e:	f4c42783          	lw	a5,-180(s0)
    80006042:	2007f793          	andi	a5,a5,512
    80006046:	cfc5                	beqz	a5,800060fe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006048:	4681                	li	a3,0
    8000604a:	4601                	li	a2,0
    8000604c:	4589                	li	a1,2
    8000604e:	f5040513          	addi	a0,s0,-176
    80006052:	00000097          	auipc	ra,0x0
    80006056:	972080e7          	jalr	-1678(ra) # 800059c4 <create>
    8000605a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000605c:	c959                	beqz	a0,800060f2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000605e:	04449703          	lh	a4,68(s1)
    80006062:	478d                	li	a5,3
    80006064:	00f71763          	bne	a4,a5,80006072 <sys_open+0x72>
    80006068:	0464d703          	lhu	a4,70(s1)
    8000606c:	47a5                	li	a5,9
    8000606e:	0ce7ed63          	bltu	a5,a4,80006148 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	dbc080e7          	jalr	-580(ra) # 80004e2e <filealloc>
    8000607a:	89aa                	mv	s3,a0
    8000607c:	10050363          	beqz	a0,80006182 <sys_open+0x182>
    80006080:	00000097          	auipc	ra,0x0
    80006084:	902080e7          	jalr	-1790(ra) # 80005982 <fdalloc>
    80006088:	892a                	mv	s2,a0
    8000608a:	0e054763          	bltz	a0,80006178 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000608e:	04449703          	lh	a4,68(s1)
    80006092:	478d                	li	a5,3
    80006094:	0cf70563          	beq	a4,a5,8000615e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006098:	4789                	li	a5,2
    8000609a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000609e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800060a2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800060a6:	f4c42783          	lw	a5,-180(s0)
    800060aa:	0017c713          	xori	a4,a5,1
    800060ae:	8b05                	andi	a4,a4,1
    800060b0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800060b4:	0037f713          	andi	a4,a5,3
    800060b8:	00e03733          	snez	a4,a4
    800060bc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800060c0:	4007f793          	andi	a5,a5,1024
    800060c4:	c791                	beqz	a5,800060d0 <sys_open+0xd0>
    800060c6:	04449703          	lh	a4,68(s1)
    800060ca:	4789                	li	a5,2
    800060cc:	0af70063          	beq	a4,a5,8000616c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800060d0:	8526                	mv	a0,s1
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	046080e7          	jalr	70(ra) # 80004118 <iunlock>
  end_op();
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	9c6080e7          	jalr	-1594(ra) # 80004aa0 <end_op>

  return fd;
    800060e2:	854a                	mv	a0,s2
}
    800060e4:	70ea                	ld	ra,184(sp)
    800060e6:	744a                	ld	s0,176(sp)
    800060e8:	74aa                	ld	s1,168(sp)
    800060ea:	790a                	ld	s2,160(sp)
    800060ec:	69ea                	ld	s3,152(sp)
    800060ee:	6129                	addi	sp,sp,192
    800060f0:	8082                	ret
      end_op();
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	9ae080e7          	jalr	-1618(ra) # 80004aa0 <end_op>
      return -1;
    800060fa:	557d                	li	a0,-1
    800060fc:	b7e5                	j	800060e4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800060fe:	f5040513          	addi	a0,s0,-176
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	700080e7          	jalr	1792(ra) # 80004802 <namei>
    8000610a:	84aa                	mv	s1,a0
    8000610c:	c905                	beqz	a0,8000613c <sys_open+0x13c>
    ilock(ip);
    8000610e:	ffffe097          	auipc	ra,0xffffe
    80006112:	f48080e7          	jalr	-184(ra) # 80004056 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006116:	04449703          	lh	a4,68(s1)
    8000611a:	4785                	li	a5,1
    8000611c:	f4f711e3          	bne	a4,a5,8000605e <sys_open+0x5e>
    80006120:	f4c42783          	lw	a5,-180(s0)
    80006124:	d7b9                	beqz	a5,80006072 <sys_open+0x72>
      iunlockput(ip);
    80006126:	8526                	mv	a0,s1
    80006128:	ffffe097          	auipc	ra,0xffffe
    8000612c:	190080e7          	jalr	400(ra) # 800042b8 <iunlockput>
      end_op();
    80006130:	fffff097          	auipc	ra,0xfffff
    80006134:	970080e7          	jalr	-1680(ra) # 80004aa0 <end_op>
      return -1;
    80006138:	557d                	li	a0,-1
    8000613a:	b76d                	j	800060e4 <sys_open+0xe4>
      end_op();
    8000613c:	fffff097          	auipc	ra,0xfffff
    80006140:	964080e7          	jalr	-1692(ra) # 80004aa0 <end_op>
      return -1;
    80006144:	557d                	li	a0,-1
    80006146:	bf79                	j	800060e4 <sys_open+0xe4>
    iunlockput(ip);
    80006148:	8526                	mv	a0,s1
    8000614a:	ffffe097          	auipc	ra,0xffffe
    8000614e:	16e080e7          	jalr	366(ra) # 800042b8 <iunlockput>
    end_op();
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	94e080e7          	jalr	-1714(ra) # 80004aa0 <end_op>
    return -1;
    8000615a:	557d                	li	a0,-1
    8000615c:	b761                	j	800060e4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000615e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006162:	04649783          	lh	a5,70(s1)
    80006166:	02f99223          	sh	a5,36(s3)
    8000616a:	bf25                	j	800060a2 <sys_open+0xa2>
    itrunc(ip);
    8000616c:	8526                	mv	a0,s1
    8000616e:	ffffe097          	auipc	ra,0xffffe
    80006172:	ff6080e7          	jalr	-10(ra) # 80004164 <itrunc>
    80006176:	bfa9                	j	800060d0 <sys_open+0xd0>
      fileclose(f);
    80006178:	854e                	mv	a0,s3
    8000617a:	fffff097          	auipc	ra,0xfffff
    8000617e:	d70080e7          	jalr	-656(ra) # 80004eea <fileclose>
    iunlockput(ip);
    80006182:	8526                	mv	a0,s1
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	134080e7          	jalr	308(ra) # 800042b8 <iunlockput>
    end_op();
    8000618c:	fffff097          	auipc	ra,0xfffff
    80006190:	914080e7          	jalr	-1772(ra) # 80004aa0 <end_op>
    return -1;
    80006194:	557d                	li	a0,-1
    80006196:	b7b9                	j	800060e4 <sys_open+0xe4>

0000000080006198 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006198:	7175                	addi	sp,sp,-144
    8000619a:	e506                	sd	ra,136(sp)
    8000619c:	e122                	sd	s0,128(sp)
    8000619e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	882080e7          	jalr	-1918(ra) # 80004a22 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800061a8:	08000613          	li	a2,128
    800061ac:	f7040593          	addi	a1,s0,-144
    800061b0:	4501                	li	a0,0
    800061b2:	ffffd097          	auipc	ra,0xffffd
    800061b6:	20a080e7          	jalr	522(ra) # 800033bc <argstr>
    800061ba:	02054963          	bltz	a0,800061ec <sys_mkdir+0x54>
    800061be:	4681                	li	a3,0
    800061c0:	4601                	li	a2,0
    800061c2:	4585                	li	a1,1
    800061c4:	f7040513          	addi	a0,s0,-144
    800061c8:	fffff097          	auipc	ra,0xfffff
    800061cc:	7fc080e7          	jalr	2044(ra) # 800059c4 <create>
    800061d0:	cd11                	beqz	a0,800061ec <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061d2:	ffffe097          	auipc	ra,0xffffe
    800061d6:	0e6080e7          	jalr	230(ra) # 800042b8 <iunlockput>
  end_op();
    800061da:	fffff097          	auipc	ra,0xfffff
    800061de:	8c6080e7          	jalr	-1850(ra) # 80004aa0 <end_op>
  return 0;
    800061e2:	4501                	li	a0,0
}
    800061e4:	60aa                	ld	ra,136(sp)
    800061e6:	640a                	ld	s0,128(sp)
    800061e8:	6149                	addi	sp,sp,144
    800061ea:	8082                	ret
    end_op();
    800061ec:	fffff097          	auipc	ra,0xfffff
    800061f0:	8b4080e7          	jalr	-1868(ra) # 80004aa0 <end_op>
    return -1;
    800061f4:	557d                	li	a0,-1
    800061f6:	b7fd                	j	800061e4 <sys_mkdir+0x4c>

00000000800061f8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800061f8:	7135                	addi	sp,sp,-160
    800061fa:	ed06                	sd	ra,152(sp)
    800061fc:	e922                	sd	s0,144(sp)
    800061fe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006200:	fffff097          	auipc	ra,0xfffff
    80006204:	822080e7          	jalr	-2014(ra) # 80004a22 <begin_op>
  argint(1, &major);
    80006208:	f6c40593          	addi	a1,s0,-148
    8000620c:	4505                	li	a0,1
    8000620e:	ffffd097          	auipc	ra,0xffffd
    80006212:	16e080e7          	jalr	366(ra) # 8000337c <argint>
  argint(2, &minor);
    80006216:	f6840593          	addi	a1,s0,-152
    8000621a:	4509                	li	a0,2
    8000621c:	ffffd097          	auipc	ra,0xffffd
    80006220:	160080e7          	jalr	352(ra) # 8000337c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006224:	08000613          	li	a2,128
    80006228:	f7040593          	addi	a1,s0,-144
    8000622c:	4501                	li	a0,0
    8000622e:	ffffd097          	auipc	ra,0xffffd
    80006232:	18e080e7          	jalr	398(ra) # 800033bc <argstr>
    80006236:	02054b63          	bltz	a0,8000626c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000623a:	f6841683          	lh	a3,-152(s0)
    8000623e:	f6c41603          	lh	a2,-148(s0)
    80006242:	458d                	li	a1,3
    80006244:	f7040513          	addi	a0,s0,-144
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	77c080e7          	jalr	1916(ra) # 800059c4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006250:	cd11                	beqz	a0,8000626c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	066080e7          	jalr	102(ra) # 800042b8 <iunlockput>
  end_op();
    8000625a:	fffff097          	auipc	ra,0xfffff
    8000625e:	846080e7          	jalr	-1978(ra) # 80004aa0 <end_op>
  return 0;
    80006262:	4501                	li	a0,0
}
    80006264:	60ea                	ld	ra,152(sp)
    80006266:	644a                	ld	s0,144(sp)
    80006268:	610d                	addi	sp,sp,160
    8000626a:	8082                	ret
    end_op();
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	834080e7          	jalr	-1996(ra) # 80004aa0 <end_op>
    return -1;
    80006274:	557d                	li	a0,-1
    80006276:	b7fd                	j	80006264 <sys_mknod+0x6c>

0000000080006278 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006278:	7135                	addi	sp,sp,-160
    8000627a:	ed06                	sd	ra,152(sp)
    8000627c:	e922                	sd	s0,144(sp)
    8000627e:	e526                	sd	s1,136(sp)
    80006280:	e14a                	sd	s2,128(sp)
    80006282:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006284:	ffffc097          	auipc	ra,0xffffc
    80006288:	8de080e7          	jalr	-1826(ra) # 80001b62 <myproc>
    8000628c:	892a                	mv	s2,a0
  
  begin_op();
    8000628e:	ffffe097          	auipc	ra,0xffffe
    80006292:	794080e7          	jalr	1940(ra) # 80004a22 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006296:	08000613          	li	a2,128
    8000629a:	f6040593          	addi	a1,s0,-160
    8000629e:	4501                	li	a0,0
    800062a0:	ffffd097          	auipc	ra,0xffffd
    800062a4:	11c080e7          	jalr	284(ra) # 800033bc <argstr>
    800062a8:	04054b63          	bltz	a0,800062fe <sys_chdir+0x86>
    800062ac:	f6040513          	addi	a0,s0,-160
    800062b0:	ffffe097          	auipc	ra,0xffffe
    800062b4:	552080e7          	jalr	1362(ra) # 80004802 <namei>
    800062b8:	84aa                	mv	s1,a0
    800062ba:	c131                	beqz	a0,800062fe <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800062bc:	ffffe097          	auipc	ra,0xffffe
    800062c0:	d9a080e7          	jalr	-614(ra) # 80004056 <ilock>
  if(ip->type != T_DIR){
    800062c4:	04449703          	lh	a4,68(s1)
    800062c8:	4785                	li	a5,1
    800062ca:	04f71063          	bne	a4,a5,8000630a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800062ce:	8526                	mv	a0,s1
    800062d0:	ffffe097          	auipc	ra,0xffffe
    800062d4:	e48080e7          	jalr	-440(ra) # 80004118 <iunlock>
  iput(p->cwd);
    800062d8:	15093503          	ld	a0,336(s2)
    800062dc:	ffffe097          	auipc	ra,0xffffe
    800062e0:	f34080e7          	jalr	-204(ra) # 80004210 <iput>
  end_op();
    800062e4:	ffffe097          	auipc	ra,0xffffe
    800062e8:	7bc080e7          	jalr	1980(ra) # 80004aa0 <end_op>
  p->cwd = ip;
    800062ec:	14993823          	sd	s1,336(s2)
  return 0;
    800062f0:	4501                	li	a0,0
}
    800062f2:	60ea                	ld	ra,152(sp)
    800062f4:	644a                	ld	s0,144(sp)
    800062f6:	64aa                	ld	s1,136(sp)
    800062f8:	690a                	ld	s2,128(sp)
    800062fa:	610d                	addi	sp,sp,160
    800062fc:	8082                	ret
    end_op();
    800062fe:	ffffe097          	auipc	ra,0xffffe
    80006302:	7a2080e7          	jalr	1954(ra) # 80004aa0 <end_op>
    return -1;
    80006306:	557d                	li	a0,-1
    80006308:	b7ed                	j	800062f2 <sys_chdir+0x7a>
    iunlockput(ip);
    8000630a:	8526                	mv	a0,s1
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	fac080e7          	jalr	-84(ra) # 800042b8 <iunlockput>
    end_op();
    80006314:	ffffe097          	auipc	ra,0xffffe
    80006318:	78c080e7          	jalr	1932(ra) # 80004aa0 <end_op>
    return -1;
    8000631c:	557d                	li	a0,-1
    8000631e:	bfd1                	j	800062f2 <sys_chdir+0x7a>

0000000080006320 <sys_exec>:

uint64
sys_exec(void)
{
    80006320:	7145                	addi	sp,sp,-464
    80006322:	e786                	sd	ra,456(sp)
    80006324:	e3a2                	sd	s0,448(sp)
    80006326:	ff26                	sd	s1,440(sp)
    80006328:	fb4a                	sd	s2,432(sp)
    8000632a:	f74e                	sd	s3,424(sp)
    8000632c:	f352                	sd	s4,416(sp)
    8000632e:	ef56                	sd	s5,408(sp)
    80006330:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006332:	e3840593          	addi	a1,s0,-456
    80006336:	4505                	li	a0,1
    80006338:	ffffd097          	auipc	ra,0xffffd
    8000633c:	064080e7          	jalr	100(ra) # 8000339c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006340:	08000613          	li	a2,128
    80006344:	f4040593          	addi	a1,s0,-192
    80006348:	4501                	li	a0,0
    8000634a:	ffffd097          	auipc	ra,0xffffd
    8000634e:	072080e7          	jalr	114(ra) # 800033bc <argstr>
    80006352:	87aa                	mv	a5,a0
    return -1;
    80006354:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006356:	0c07c363          	bltz	a5,8000641c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000635a:	10000613          	li	a2,256
    8000635e:	4581                	li	a1,0
    80006360:	e4040513          	addi	a0,s0,-448
    80006364:	ffffb097          	auipc	ra,0xffffb
    80006368:	a62080e7          	jalr	-1438(ra) # 80000dc6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000636c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006370:	89a6                	mv	s3,s1
    80006372:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006374:	02000a13          	li	s4,32
    80006378:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000637c:	00391513          	slli	a0,s2,0x3
    80006380:	e3040593          	addi	a1,s0,-464
    80006384:	e3843783          	ld	a5,-456(s0)
    80006388:	953e                	add	a0,a0,a5
    8000638a:	ffffd097          	auipc	ra,0xffffd
    8000638e:	f54080e7          	jalr	-172(ra) # 800032de <fetchaddr>
    80006392:	02054a63          	bltz	a0,800063c6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006396:	e3043783          	ld	a5,-464(s0)
    8000639a:	c3b9                	beqz	a5,800063e0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000639c:	ffffa097          	auipc	ra,0xffffa
    800063a0:	7c6080e7          	jalr	1990(ra) # 80000b62 <kalloc>
    800063a4:	85aa                	mv	a1,a0
    800063a6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800063aa:	cd11                	beqz	a0,800063c6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800063ac:	6605                	lui	a2,0x1
    800063ae:	e3043503          	ld	a0,-464(s0)
    800063b2:	ffffd097          	auipc	ra,0xffffd
    800063b6:	f7e080e7          	jalr	-130(ra) # 80003330 <fetchstr>
    800063ba:	00054663          	bltz	a0,800063c6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800063be:	0905                	addi	s2,s2,1
    800063c0:	09a1                	addi	s3,s3,8
    800063c2:	fb491be3          	bne	s2,s4,80006378 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063c6:	f4040913          	addi	s2,s0,-192
    800063ca:	6088                	ld	a0,0(s1)
    800063cc:	c539                	beqz	a0,8000641a <sys_exec+0xfa>
    kfree(argv[i]);
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	61a080e7          	jalr	1562(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063d6:	04a1                	addi	s1,s1,8
    800063d8:	ff2499e3          	bne	s1,s2,800063ca <sys_exec+0xaa>
  return -1;
    800063dc:	557d                	li	a0,-1
    800063de:	a83d                	j	8000641c <sys_exec+0xfc>
      argv[i] = 0;
    800063e0:	0a8e                	slli	s5,s5,0x3
    800063e2:	fc0a8793          	addi	a5,s5,-64
    800063e6:	00878ab3          	add	s5,a5,s0
    800063ea:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800063ee:	e4040593          	addi	a1,s0,-448
    800063f2:	f4040513          	addi	a0,s0,-192
    800063f6:	fffff097          	auipc	ra,0xfffff
    800063fa:	16e080e7          	jalr	366(ra) # 80005564 <exec>
    800063fe:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006400:	f4040993          	addi	s3,s0,-192
    80006404:	6088                	ld	a0,0(s1)
    80006406:	c901                	beqz	a0,80006416 <sys_exec+0xf6>
    kfree(argv[i]);
    80006408:	ffffa097          	auipc	ra,0xffffa
    8000640c:	5e0080e7          	jalr	1504(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006410:	04a1                	addi	s1,s1,8
    80006412:	ff3499e3          	bne	s1,s3,80006404 <sys_exec+0xe4>
  return ret;
    80006416:	854a                	mv	a0,s2
    80006418:	a011                	j	8000641c <sys_exec+0xfc>
  return -1;
    8000641a:	557d                	li	a0,-1
}
    8000641c:	60be                	ld	ra,456(sp)
    8000641e:	641e                	ld	s0,448(sp)
    80006420:	74fa                	ld	s1,440(sp)
    80006422:	795a                	ld	s2,432(sp)
    80006424:	79ba                	ld	s3,424(sp)
    80006426:	7a1a                	ld	s4,416(sp)
    80006428:	6afa                	ld	s5,408(sp)
    8000642a:	6179                	addi	sp,sp,464
    8000642c:	8082                	ret

000000008000642e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000642e:	7139                	addi	sp,sp,-64
    80006430:	fc06                	sd	ra,56(sp)
    80006432:	f822                	sd	s0,48(sp)
    80006434:	f426                	sd	s1,40(sp)
    80006436:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006438:	ffffb097          	auipc	ra,0xffffb
    8000643c:	72a080e7          	jalr	1834(ra) # 80001b62 <myproc>
    80006440:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006442:	fd840593          	addi	a1,s0,-40
    80006446:	4501                	li	a0,0
    80006448:	ffffd097          	auipc	ra,0xffffd
    8000644c:	f54080e7          	jalr	-172(ra) # 8000339c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006450:	fc840593          	addi	a1,s0,-56
    80006454:	fd040513          	addi	a0,s0,-48
    80006458:	fffff097          	auipc	ra,0xfffff
    8000645c:	dc2080e7          	jalr	-574(ra) # 8000521a <pipealloc>
    return -1;
    80006460:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006462:	0c054463          	bltz	a0,8000652a <sys_pipe+0xfc>
  fd0 = -1;
    80006466:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000646a:	fd043503          	ld	a0,-48(s0)
    8000646e:	fffff097          	auipc	ra,0xfffff
    80006472:	514080e7          	jalr	1300(ra) # 80005982 <fdalloc>
    80006476:	fca42223          	sw	a0,-60(s0)
    8000647a:	08054b63          	bltz	a0,80006510 <sys_pipe+0xe2>
    8000647e:	fc843503          	ld	a0,-56(s0)
    80006482:	fffff097          	auipc	ra,0xfffff
    80006486:	500080e7          	jalr	1280(ra) # 80005982 <fdalloc>
    8000648a:	fca42023          	sw	a0,-64(s0)
    8000648e:	06054863          	bltz	a0,800064fe <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006492:	4691                	li	a3,4
    80006494:	fc440613          	addi	a2,s0,-60
    80006498:	fd843583          	ld	a1,-40(s0)
    8000649c:	68a8                	ld	a0,80(s1)
    8000649e:	ffffb097          	auipc	ra,0xffffb
    800064a2:	2be080e7          	jalr	702(ra) # 8000175c <copyout>
    800064a6:	02054063          	bltz	a0,800064c6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800064aa:	4691                	li	a3,4
    800064ac:	fc040613          	addi	a2,s0,-64
    800064b0:	fd843583          	ld	a1,-40(s0)
    800064b4:	0591                	addi	a1,a1,4
    800064b6:	68a8                	ld	a0,80(s1)
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	2a4080e7          	jalr	676(ra) # 8000175c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800064c0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800064c2:	06055463          	bgez	a0,8000652a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800064c6:	fc442783          	lw	a5,-60(s0)
    800064ca:	07e9                	addi	a5,a5,26
    800064cc:	078e                	slli	a5,a5,0x3
    800064ce:	97a6                	add	a5,a5,s1
    800064d0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800064d4:	fc042783          	lw	a5,-64(s0)
    800064d8:	07e9                	addi	a5,a5,26
    800064da:	078e                	slli	a5,a5,0x3
    800064dc:	94be                	add	s1,s1,a5
    800064de:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800064e2:	fd043503          	ld	a0,-48(s0)
    800064e6:	fffff097          	auipc	ra,0xfffff
    800064ea:	a04080e7          	jalr	-1532(ra) # 80004eea <fileclose>
    fileclose(wf);
    800064ee:	fc843503          	ld	a0,-56(s0)
    800064f2:	fffff097          	auipc	ra,0xfffff
    800064f6:	9f8080e7          	jalr	-1544(ra) # 80004eea <fileclose>
    return -1;
    800064fa:	57fd                	li	a5,-1
    800064fc:	a03d                	j	8000652a <sys_pipe+0xfc>
    if(fd0 >= 0)
    800064fe:	fc442783          	lw	a5,-60(s0)
    80006502:	0007c763          	bltz	a5,80006510 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006506:	07e9                	addi	a5,a5,26
    80006508:	078e                	slli	a5,a5,0x3
    8000650a:	97a6                	add	a5,a5,s1
    8000650c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006510:	fd043503          	ld	a0,-48(s0)
    80006514:	fffff097          	auipc	ra,0xfffff
    80006518:	9d6080e7          	jalr	-1578(ra) # 80004eea <fileclose>
    fileclose(wf);
    8000651c:	fc843503          	ld	a0,-56(s0)
    80006520:	fffff097          	auipc	ra,0xfffff
    80006524:	9ca080e7          	jalr	-1590(ra) # 80004eea <fileclose>
    return -1;
    80006528:	57fd                	li	a5,-1
}
    8000652a:	853e                	mv	a0,a5
    8000652c:	70e2                	ld	ra,56(sp)
    8000652e:	7442                	ld	s0,48(sp)
    80006530:	74a2                	ld	s1,40(sp)
    80006532:	6121                	addi	sp,sp,64
    80006534:	8082                	ret

0000000080006536 <sys_getreadcount>:

int sys_getreadcount(void) {
    80006536:	1141                	addi	sp,sp,-16
    80006538:	e422                	sd	s0,8(sp)
    8000653a:	0800                	addi	s0,sp,16
  return readcount;
}
    8000653c:	00002517          	auipc	a0,0x2
    80006540:	43852503          	lw	a0,1080(a0) # 80008974 <readcount>
    80006544:	6422                	ld	s0,8(sp)
    80006546:	0141                	addi	sp,sp,16
    80006548:	8082                	ret

000000008000654a <sys_setpriority>:


//do set priority
uint64
sys_setpriority(int pid, int new_priority)
{
    8000654a:	7179                	addi	sp,sp,-48
    8000654c:	f406                	sd	ra,40(sp)
    8000654e:	f022                	sd	s0,32(sp)
    80006550:	ec26                	sd	s1,24(sp)
    80006552:	e84a                	sd	s2,16(sp)
    80006554:	e44e                	sd	s3,8(sp)
    80006556:	e052                	sd	s4,0(sp)
    80006558:	1800                	addi	s0,sp,48
    8000655a:	892a                	mv	s2,a0
    8000655c:	8a2e                	mv	s4,a1
  //set sp to new p, rbi to 25

  struct proc* p;
  uint64 old_priority = 0; //initalizing to random so the warning goes away

  for(p = proc; p < &proc[NPROC]; p++)
    8000655e:	0022b497          	auipc	s1,0x22b
    80006562:	aca48493          	addi	s1,s1,-1334 # 80231028 <proc>
    80006566:	00232997          	auipc	s3,0x232
    8000656a:	ac298993          	addi	s3,s3,-1342 # 80238028 <tickslock>
  {
    acquire(&p->lock);
    8000656e:	8526                	mv	a0,s1
    80006570:	ffffa097          	auipc	ra,0xffffa
    80006574:	75a080e7          	jalr	1882(ra) # 80000cca <acquire>
    if(p->pid == pid)
    80006578:	589c                	lw	a5,48(s1)
    8000657a:	01278d63          	beq	a5,s2,80006594 <sys_setpriority+0x4a>
      //!set rbi to 25? wtf
      //isnt rbi calculated with all the process tiems during scheudling?

      break;
    }
    release(&p->lock);
    8000657e:	8526                	mv	a0,s1
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	7fe080e7          	jalr	2046(ra) # 80000d7e <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80006588:	1c048493          	addi	s1,s1,448
    8000658c:	ff3491e3          	bne	s1,s3,8000656e <sys_setpriority+0x24>
  uint64 old_priority = 0; //initalizing to random so the warning goes away
    80006590:	4501                	li	a0,0
  }

  return old_priority;
    80006592:	a029                	j	8000659c <sys_setpriority+0x52>
      old_priority = p->statp;
    80006594:	1a04e503          	lwu	a0,416(s1)
      p->statp = new_priority;
    80006598:	1b44a023          	sw	s4,416(s1)
    8000659c:	70a2                	ld	ra,40(sp)
    8000659e:	7402                	ld	s0,32(sp)
    800065a0:	64e2                	ld	s1,24(sp)
    800065a2:	6942                	ld	s2,16(sp)
    800065a4:	69a2                	ld	s3,8(sp)
    800065a6:	6a02                	ld	s4,0(sp)
    800065a8:	6145                	addi	sp,sp,48
    800065aa:	8082                	ret
    800065ac:	0000                	unimp
	...

00000000800065b0 <kernelvec>:
    800065b0:	7111                	addi	sp,sp,-256
    800065b2:	e006                	sd	ra,0(sp)
    800065b4:	e40a                	sd	sp,8(sp)
    800065b6:	e80e                	sd	gp,16(sp)
    800065b8:	ec12                	sd	tp,24(sp)
    800065ba:	f016                	sd	t0,32(sp)
    800065bc:	f41a                	sd	t1,40(sp)
    800065be:	f81e                	sd	t2,48(sp)
    800065c0:	fc22                	sd	s0,56(sp)
    800065c2:	e0a6                	sd	s1,64(sp)
    800065c4:	e4aa                	sd	a0,72(sp)
    800065c6:	e8ae                	sd	a1,80(sp)
    800065c8:	ecb2                	sd	a2,88(sp)
    800065ca:	f0b6                	sd	a3,96(sp)
    800065cc:	f4ba                	sd	a4,104(sp)
    800065ce:	f8be                	sd	a5,112(sp)
    800065d0:	fcc2                	sd	a6,120(sp)
    800065d2:	e146                	sd	a7,128(sp)
    800065d4:	e54a                	sd	s2,136(sp)
    800065d6:	e94e                	sd	s3,144(sp)
    800065d8:	ed52                	sd	s4,152(sp)
    800065da:	f156                	sd	s5,160(sp)
    800065dc:	f55a                	sd	s6,168(sp)
    800065de:	f95e                	sd	s7,176(sp)
    800065e0:	fd62                	sd	s8,184(sp)
    800065e2:	e1e6                	sd	s9,192(sp)
    800065e4:	e5ea                	sd	s10,200(sp)
    800065e6:	e9ee                	sd	s11,208(sp)
    800065e8:	edf2                	sd	t3,216(sp)
    800065ea:	f1f6                	sd	t4,224(sp)
    800065ec:	f5fa                	sd	t5,232(sp)
    800065ee:	f9fe                	sd	t6,240(sp)
    800065f0:	bbbfc0ef          	jal	ra,800031aa <kerneltrap>
    800065f4:	6082                	ld	ra,0(sp)
    800065f6:	6122                	ld	sp,8(sp)
    800065f8:	61c2                	ld	gp,16(sp)
    800065fa:	7282                	ld	t0,32(sp)
    800065fc:	7322                	ld	t1,40(sp)
    800065fe:	73c2                	ld	t2,48(sp)
    80006600:	7462                	ld	s0,56(sp)
    80006602:	6486                	ld	s1,64(sp)
    80006604:	6526                	ld	a0,72(sp)
    80006606:	65c6                	ld	a1,80(sp)
    80006608:	6666                	ld	a2,88(sp)
    8000660a:	7686                	ld	a3,96(sp)
    8000660c:	7726                	ld	a4,104(sp)
    8000660e:	77c6                	ld	a5,112(sp)
    80006610:	7866                	ld	a6,120(sp)
    80006612:	688a                	ld	a7,128(sp)
    80006614:	692a                	ld	s2,136(sp)
    80006616:	69ca                	ld	s3,144(sp)
    80006618:	6a6a                	ld	s4,152(sp)
    8000661a:	7a8a                	ld	s5,160(sp)
    8000661c:	7b2a                	ld	s6,168(sp)
    8000661e:	7bca                	ld	s7,176(sp)
    80006620:	7c6a                	ld	s8,184(sp)
    80006622:	6c8e                	ld	s9,192(sp)
    80006624:	6d2e                	ld	s10,200(sp)
    80006626:	6dce                	ld	s11,208(sp)
    80006628:	6e6e                	ld	t3,216(sp)
    8000662a:	7e8e                	ld	t4,224(sp)
    8000662c:	7f2e                	ld	t5,232(sp)
    8000662e:	7fce                	ld	t6,240(sp)
    80006630:	6111                	addi	sp,sp,256
    80006632:	10200073          	sret
    80006636:	00000013          	nop
    8000663a:	00000013          	nop
    8000663e:	0001                	nop

0000000080006640 <timervec>:
    80006640:	34051573          	csrrw	a0,mscratch,a0
    80006644:	e10c                	sd	a1,0(a0)
    80006646:	e510                	sd	a2,8(a0)
    80006648:	e914                	sd	a3,16(a0)
    8000664a:	6d0c                	ld	a1,24(a0)
    8000664c:	7110                	ld	a2,32(a0)
    8000664e:	6194                	ld	a3,0(a1)
    80006650:	96b2                	add	a3,a3,a2
    80006652:	e194                	sd	a3,0(a1)
    80006654:	4589                	li	a1,2
    80006656:	14459073          	csrw	sip,a1
    8000665a:	6914                	ld	a3,16(a0)
    8000665c:	6510                	ld	a2,8(a0)
    8000665e:	610c                	ld	a1,0(a0)
    80006660:	34051573          	csrrw	a0,mscratch,a0
    80006664:	30200073          	mret
	...

000000008000666a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000666a:	1141                	addi	sp,sp,-16
    8000666c:	e422                	sd	s0,8(sp)
    8000666e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006670:	0c0007b7          	lui	a5,0xc000
    80006674:	4705                	li	a4,1
    80006676:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006678:	c3d8                	sw	a4,4(a5)
}
    8000667a:	6422                	ld	s0,8(sp)
    8000667c:	0141                	addi	sp,sp,16
    8000667e:	8082                	ret

0000000080006680 <plicinithart>:

void
plicinithart(void)
{
    80006680:	1141                	addi	sp,sp,-16
    80006682:	e406                	sd	ra,8(sp)
    80006684:	e022                	sd	s0,0(sp)
    80006686:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006688:	ffffb097          	auipc	ra,0xffffb
    8000668c:	4ae080e7          	jalr	1198(ra) # 80001b36 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006690:	0085171b          	slliw	a4,a0,0x8
    80006694:	0c0027b7          	lui	a5,0xc002
    80006698:	97ba                	add	a5,a5,a4
    8000669a:	40200713          	li	a4,1026
    8000669e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066a2:	00d5151b          	slliw	a0,a0,0xd
    800066a6:	0c2017b7          	lui	a5,0xc201
    800066aa:	97aa                	add	a5,a5,a0
    800066ac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800066b0:	60a2                	ld	ra,8(sp)
    800066b2:	6402                	ld	s0,0(sp)
    800066b4:	0141                	addi	sp,sp,16
    800066b6:	8082                	ret

00000000800066b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800066b8:	1141                	addi	sp,sp,-16
    800066ba:	e406                	sd	ra,8(sp)
    800066bc:	e022                	sd	s0,0(sp)
    800066be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066c0:	ffffb097          	auipc	ra,0xffffb
    800066c4:	476080e7          	jalr	1142(ra) # 80001b36 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800066c8:	00d5151b          	slliw	a0,a0,0xd
    800066cc:	0c2017b7          	lui	a5,0xc201
    800066d0:	97aa                	add	a5,a5,a0
  return irq;
}
    800066d2:	43c8                	lw	a0,4(a5)
    800066d4:	60a2                	ld	ra,8(sp)
    800066d6:	6402                	ld	s0,0(sp)
    800066d8:	0141                	addi	sp,sp,16
    800066da:	8082                	ret

00000000800066dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800066dc:	1101                	addi	sp,sp,-32
    800066de:	ec06                	sd	ra,24(sp)
    800066e0:	e822                	sd	s0,16(sp)
    800066e2:	e426                	sd	s1,8(sp)
    800066e4:	1000                	addi	s0,sp,32
    800066e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800066e8:	ffffb097          	auipc	ra,0xffffb
    800066ec:	44e080e7          	jalr	1102(ra) # 80001b36 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800066f0:	00d5151b          	slliw	a0,a0,0xd
    800066f4:	0c2017b7          	lui	a5,0xc201
    800066f8:	97aa                	add	a5,a5,a0
    800066fa:	c3c4                	sw	s1,4(a5)
}
    800066fc:	60e2                	ld	ra,24(sp)
    800066fe:	6442                	ld	s0,16(sp)
    80006700:	64a2                	ld	s1,8(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret

0000000080006706 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006706:	1141                	addi	sp,sp,-16
    80006708:	e406                	sd	ra,8(sp)
    8000670a:	e022                	sd	s0,0(sp)
    8000670c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000670e:	479d                	li	a5,7
    80006710:	04a7cc63          	blt	a5,a0,80006768 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006714:	0023d797          	auipc	a5,0x23d
    80006718:	bb478793          	addi	a5,a5,-1100 # 802432c8 <disk>
    8000671c:	97aa                	add	a5,a5,a0
    8000671e:	0187c783          	lbu	a5,24(a5)
    80006722:	ebb9                	bnez	a5,80006778 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006724:	00451693          	slli	a3,a0,0x4
    80006728:	0023d797          	auipc	a5,0x23d
    8000672c:	ba078793          	addi	a5,a5,-1120 # 802432c8 <disk>
    80006730:	6398                	ld	a4,0(a5)
    80006732:	9736                	add	a4,a4,a3
    80006734:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006738:	6398                	ld	a4,0(a5)
    8000673a:	9736                	add	a4,a4,a3
    8000673c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006740:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006744:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006748:	97aa                	add	a5,a5,a0
    8000674a:	4705                	li	a4,1
    8000674c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006750:	0023d517          	auipc	a0,0x23d
    80006754:	b9050513          	addi	a0,a0,-1136 # 802432e0 <disk+0x18>
    80006758:	ffffc097          	auipc	ra,0xffffc
    8000675c:	cdc080e7          	jalr	-804(ra) # 80002434 <wakeup>
}
    80006760:	60a2                	ld	ra,8(sp)
    80006762:	6402                	ld	s0,0(sp)
    80006764:	0141                	addi	sp,sp,16
    80006766:	8082                	ret
    panic("free_desc 1");
    80006768:	00002517          	auipc	a0,0x2
    8000676c:	06050513          	addi	a0,a0,96 # 800087c8 <syscalls+0x318>
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	dd0080e7          	jalr	-560(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006778:	00002517          	auipc	a0,0x2
    8000677c:	06050513          	addi	a0,a0,96 # 800087d8 <syscalls+0x328>
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>

0000000080006788 <virtio_disk_init>:
{
    80006788:	1101                	addi	sp,sp,-32
    8000678a:	ec06                	sd	ra,24(sp)
    8000678c:	e822                	sd	s0,16(sp)
    8000678e:	e426                	sd	s1,8(sp)
    80006790:	e04a                	sd	s2,0(sp)
    80006792:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006794:	00002597          	auipc	a1,0x2
    80006798:	05458593          	addi	a1,a1,84 # 800087e8 <syscalls+0x338>
    8000679c:	0023d517          	auipc	a0,0x23d
    800067a0:	c5450513          	addi	a0,a0,-940 # 802433f0 <disk+0x128>
    800067a4:	ffffa097          	auipc	ra,0xffffa
    800067a8:	496080e7          	jalr	1174(ra) # 80000c3a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067ac:	100017b7          	lui	a5,0x10001
    800067b0:	4398                	lw	a4,0(a5)
    800067b2:	2701                	sext.w	a4,a4
    800067b4:	747277b7          	lui	a5,0x74727
    800067b8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067bc:	14f71b63          	bne	a4,a5,80006912 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800067c0:	100017b7          	lui	a5,0x10001
    800067c4:	43dc                	lw	a5,4(a5)
    800067c6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067c8:	4709                	li	a4,2
    800067ca:	14e79463          	bne	a5,a4,80006912 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067ce:	100017b7          	lui	a5,0x10001
    800067d2:	479c                	lw	a5,8(a5)
    800067d4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800067d6:	12e79e63          	bne	a5,a4,80006912 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800067da:	100017b7          	lui	a5,0x10001
    800067de:	47d8                	lw	a4,12(a5)
    800067e0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067e2:	554d47b7          	lui	a5,0x554d4
    800067e6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800067ea:	12f71463          	bne	a4,a5,80006912 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800067ee:	100017b7          	lui	a5,0x10001
    800067f2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800067f6:	4705                	li	a4,1
    800067f8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800067fa:	470d                	li	a4,3
    800067fc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800067fe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006800:	c7ffe6b7          	lui	a3,0xc7ffe
    80006804:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb357>
    80006808:	8f75                	and	a4,a4,a3
    8000680a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000680c:	472d                	li	a4,11
    8000680e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006810:	5bbc                	lw	a5,112(a5)
    80006812:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006816:	8ba1                	andi	a5,a5,8
    80006818:	10078563          	beqz	a5,80006922 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000681c:	100017b7          	lui	a5,0x10001
    80006820:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006824:	43fc                	lw	a5,68(a5)
    80006826:	2781                	sext.w	a5,a5
    80006828:	10079563          	bnez	a5,80006932 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000682c:	100017b7          	lui	a5,0x10001
    80006830:	5bdc                	lw	a5,52(a5)
    80006832:	2781                	sext.w	a5,a5
  if(max == 0)
    80006834:	10078763          	beqz	a5,80006942 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006838:	471d                	li	a4,7
    8000683a:	10f77c63          	bgeu	a4,a5,80006952 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000683e:	ffffa097          	auipc	ra,0xffffa
    80006842:	324080e7          	jalr	804(ra) # 80000b62 <kalloc>
    80006846:	0023d497          	auipc	s1,0x23d
    8000684a:	a8248493          	addi	s1,s1,-1406 # 802432c8 <disk>
    8000684e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006850:	ffffa097          	auipc	ra,0xffffa
    80006854:	312080e7          	jalr	786(ra) # 80000b62 <kalloc>
    80006858:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000685a:	ffffa097          	auipc	ra,0xffffa
    8000685e:	308080e7          	jalr	776(ra) # 80000b62 <kalloc>
    80006862:	87aa                	mv	a5,a0
    80006864:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006866:	6088                	ld	a0,0(s1)
    80006868:	cd6d                	beqz	a0,80006962 <virtio_disk_init+0x1da>
    8000686a:	0023d717          	auipc	a4,0x23d
    8000686e:	a6673703          	ld	a4,-1434(a4) # 802432d0 <disk+0x8>
    80006872:	cb65                	beqz	a4,80006962 <virtio_disk_init+0x1da>
    80006874:	c7fd                	beqz	a5,80006962 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006876:	6605                	lui	a2,0x1
    80006878:	4581                	li	a1,0
    8000687a:	ffffa097          	auipc	ra,0xffffa
    8000687e:	54c080e7          	jalr	1356(ra) # 80000dc6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006882:	0023d497          	auipc	s1,0x23d
    80006886:	a4648493          	addi	s1,s1,-1466 # 802432c8 <disk>
    8000688a:	6605                	lui	a2,0x1
    8000688c:	4581                	li	a1,0
    8000688e:	6488                	ld	a0,8(s1)
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	536080e7          	jalr	1334(ra) # 80000dc6 <memset>
  memset(disk.used, 0, PGSIZE);
    80006898:	6605                	lui	a2,0x1
    8000689a:	4581                	li	a1,0
    8000689c:	6888                	ld	a0,16(s1)
    8000689e:	ffffa097          	auipc	ra,0xffffa
    800068a2:	528080e7          	jalr	1320(ra) # 80000dc6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800068a6:	100017b7          	lui	a5,0x10001
    800068aa:	4721                	li	a4,8
    800068ac:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800068ae:	4098                	lw	a4,0(s1)
    800068b0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800068b4:	40d8                	lw	a4,4(s1)
    800068b6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800068ba:	6498                	ld	a4,8(s1)
    800068bc:	0007069b          	sext.w	a3,a4
    800068c0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800068c4:	9701                	srai	a4,a4,0x20
    800068c6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800068ca:	6898                	ld	a4,16(s1)
    800068cc:	0007069b          	sext.w	a3,a4
    800068d0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800068d4:	9701                	srai	a4,a4,0x20
    800068d6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800068da:	4705                	li	a4,1
    800068dc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800068de:	00e48c23          	sb	a4,24(s1)
    800068e2:	00e48ca3          	sb	a4,25(s1)
    800068e6:	00e48d23          	sb	a4,26(s1)
    800068ea:	00e48da3          	sb	a4,27(s1)
    800068ee:	00e48e23          	sb	a4,28(s1)
    800068f2:	00e48ea3          	sb	a4,29(s1)
    800068f6:	00e48f23          	sb	a4,30(s1)
    800068fa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800068fe:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006902:	0727a823          	sw	s2,112(a5)
}
    80006906:	60e2                	ld	ra,24(sp)
    80006908:	6442                	ld	s0,16(sp)
    8000690a:	64a2                	ld	s1,8(sp)
    8000690c:	6902                	ld	s2,0(sp)
    8000690e:	6105                	addi	sp,sp,32
    80006910:	8082                	ret
    panic("could not find virtio disk");
    80006912:	00002517          	auipc	a0,0x2
    80006916:	ee650513          	addi	a0,a0,-282 # 800087f8 <syscalls+0x348>
    8000691a:	ffffa097          	auipc	ra,0xffffa
    8000691e:	c26080e7          	jalr	-986(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006922:	00002517          	auipc	a0,0x2
    80006926:	ef650513          	addi	a0,a0,-266 # 80008818 <syscalls+0x368>
    8000692a:	ffffa097          	auipc	ra,0xffffa
    8000692e:	c16080e7          	jalr	-1002(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006932:	00002517          	auipc	a0,0x2
    80006936:	f0650513          	addi	a0,a0,-250 # 80008838 <syscalls+0x388>
    8000693a:	ffffa097          	auipc	ra,0xffffa
    8000693e:	c06080e7          	jalr	-1018(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006942:	00002517          	auipc	a0,0x2
    80006946:	f1650513          	addi	a0,a0,-234 # 80008858 <syscalls+0x3a8>
    8000694a:	ffffa097          	auipc	ra,0xffffa
    8000694e:	bf6080e7          	jalr	-1034(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006952:	00002517          	auipc	a0,0x2
    80006956:	f2650513          	addi	a0,a0,-218 # 80008878 <syscalls+0x3c8>
    8000695a:	ffffa097          	auipc	ra,0xffffa
    8000695e:	be6080e7          	jalr	-1050(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006962:	00002517          	auipc	a0,0x2
    80006966:	f3650513          	addi	a0,a0,-202 # 80008898 <syscalls+0x3e8>
    8000696a:	ffffa097          	auipc	ra,0xffffa
    8000696e:	bd6080e7          	jalr	-1066(ra) # 80000540 <panic>

0000000080006972 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006972:	7119                	addi	sp,sp,-128
    80006974:	fc86                	sd	ra,120(sp)
    80006976:	f8a2                	sd	s0,112(sp)
    80006978:	f4a6                	sd	s1,104(sp)
    8000697a:	f0ca                	sd	s2,96(sp)
    8000697c:	ecce                	sd	s3,88(sp)
    8000697e:	e8d2                	sd	s4,80(sp)
    80006980:	e4d6                	sd	s5,72(sp)
    80006982:	e0da                	sd	s6,64(sp)
    80006984:	fc5e                	sd	s7,56(sp)
    80006986:	f862                	sd	s8,48(sp)
    80006988:	f466                	sd	s9,40(sp)
    8000698a:	f06a                	sd	s10,32(sp)
    8000698c:	ec6e                	sd	s11,24(sp)
    8000698e:	0100                	addi	s0,sp,128
    80006990:	8aaa                	mv	s5,a0
    80006992:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006994:	00c52d03          	lw	s10,12(a0)
    80006998:	001d1d1b          	slliw	s10,s10,0x1
    8000699c:	1d02                	slli	s10,s10,0x20
    8000699e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800069a2:	0023d517          	auipc	a0,0x23d
    800069a6:	a4e50513          	addi	a0,a0,-1458 # 802433f0 <disk+0x128>
    800069aa:	ffffa097          	auipc	ra,0xffffa
    800069ae:	320080e7          	jalr	800(ra) # 80000cca <acquire>
  for(int i = 0; i < 3; i++){
    800069b2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800069b4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800069b6:	0023db97          	auipc	s7,0x23d
    800069ba:	912b8b93          	addi	s7,s7,-1774 # 802432c8 <disk>
  for(int i = 0; i < 3; i++){
    800069be:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800069c0:	0023dc97          	auipc	s9,0x23d
    800069c4:	a30c8c93          	addi	s9,s9,-1488 # 802433f0 <disk+0x128>
    800069c8:	a08d                	j	80006a2a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800069ca:	00fb8733          	add	a4,s7,a5
    800069ce:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800069d2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800069d4:	0207c563          	bltz	a5,800069fe <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800069d8:	2905                	addiw	s2,s2,1
    800069da:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800069dc:	05690c63          	beq	s2,s6,80006a34 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800069e0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800069e2:	0023d717          	auipc	a4,0x23d
    800069e6:	8e670713          	addi	a4,a4,-1818 # 802432c8 <disk>
    800069ea:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800069ec:	01874683          	lbu	a3,24(a4)
    800069f0:	fee9                	bnez	a3,800069ca <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800069f2:	2785                	addiw	a5,a5,1
    800069f4:	0705                	addi	a4,a4,1
    800069f6:	fe979be3          	bne	a5,s1,800069ec <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800069fa:	57fd                	li	a5,-1
    800069fc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800069fe:	01205d63          	blez	s2,80006a18 <virtio_disk_rw+0xa6>
    80006a02:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006a04:	000a2503          	lw	a0,0(s4)
    80006a08:	00000097          	auipc	ra,0x0
    80006a0c:	cfe080e7          	jalr	-770(ra) # 80006706 <free_desc>
      for(int j = 0; j < i; j++)
    80006a10:	2d85                	addiw	s11,s11,1
    80006a12:	0a11                	addi	s4,s4,4
    80006a14:	ff2d98e3          	bne	s11,s2,80006a04 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a18:	85e6                	mv	a1,s9
    80006a1a:	0023d517          	auipc	a0,0x23d
    80006a1e:	8c650513          	addi	a0,a0,-1850 # 802432e0 <disk+0x18>
    80006a22:	ffffc097          	auipc	ra,0xffffc
    80006a26:	9a2080e7          	jalr	-1630(ra) # 800023c4 <sleep>
  for(int i = 0; i < 3; i++){
    80006a2a:	f8040a13          	addi	s4,s0,-128
{
    80006a2e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006a30:	894e                	mv	s2,s3
    80006a32:	b77d                	j	800069e0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a34:	f8042503          	lw	a0,-128(s0)
    80006a38:	00a50713          	addi	a4,a0,10
    80006a3c:	0712                	slli	a4,a4,0x4

  if(write)
    80006a3e:	0023d797          	auipc	a5,0x23d
    80006a42:	88a78793          	addi	a5,a5,-1910 # 802432c8 <disk>
    80006a46:	00e786b3          	add	a3,a5,a4
    80006a4a:	01803633          	snez	a2,s8
    80006a4e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006a50:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006a54:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a58:	f6070613          	addi	a2,a4,-160
    80006a5c:	6394                	ld	a3,0(a5)
    80006a5e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a60:	00870593          	addi	a1,a4,8
    80006a64:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a66:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a68:	0007b803          	ld	a6,0(a5)
    80006a6c:	9642                	add	a2,a2,a6
    80006a6e:	46c1                	li	a3,16
    80006a70:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006a72:	4585                	li	a1,1
    80006a74:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006a78:	f8442683          	lw	a3,-124(s0)
    80006a7c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006a80:	0692                	slli	a3,a3,0x4
    80006a82:	9836                	add	a6,a6,a3
    80006a84:	058a8613          	addi	a2,s5,88
    80006a88:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006a8c:	0007b803          	ld	a6,0(a5)
    80006a90:	96c2                	add	a3,a3,a6
    80006a92:	40000613          	li	a2,1024
    80006a96:	c690                	sw	a2,8(a3)
  if(write)
    80006a98:	001c3613          	seqz	a2,s8
    80006a9c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006aa0:	00166613          	ori	a2,a2,1
    80006aa4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006aa8:	f8842603          	lw	a2,-120(s0)
    80006aac:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ab0:	00250693          	addi	a3,a0,2
    80006ab4:	0692                	slli	a3,a3,0x4
    80006ab6:	96be                	add	a3,a3,a5
    80006ab8:	58fd                	li	a7,-1
    80006aba:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006abe:	0612                	slli	a2,a2,0x4
    80006ac0:	9832                	add	a6,a6,a2
    80006ac2:	f9070713          	addi	a4,a4,-112
    80006ac6:	973e                	add	a4,a4,a5
    80006ac8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006acc:	6398                	ld	a4,0(a5)
    80006ace:	9732                	add	a4,a4,a2
    80006ad0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006ad2:	4609                	li	a2,2
    80006ad4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006ad8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006adc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006ae0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ae4:	6794                	ld	a3,8(a5)
    80006ae6:	0026d703          	lhu	a4,2(a3)
    80006aea:	8b1d                	andi	a4,a4,7
    80006aec:	0706                	slli	a4,a4,0x1
    80006aee:	96ba                	add	a3,a3,a4
    80006af0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006af4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006af8:	6798                	ld	a4,8(a5)
    80006afa:	00275783          	lhu	a5,2(a4)
    80006afe:	2785                	addiw	a5,a5,1
    80006b00:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b04:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b08:	100017b7          	lui	a5,0x10001
    80006b0c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b10:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006b14:	0023d917          	auipc	s2,0x23d
    80006b18:	8dc90913          	addi	s2,s2,-1828 # 802433f0 <disk+0x128>
  while(b->disk == 1) {
    80006b1c:	4485                	li	s1,1
    80006b1e:	00b79c63          	bne	a5,a1,80006b36 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006b22:	85ca                	mv	a1,s2
    80006b24:	8556                	mv	a0,s5
    80006b26:	ffffc097          	auipc	ra,0xffffc
    80006b2a:	89e080e7          	jalr	-1890(ra) # 800023c4 <sleep>
  while(b->disk == 1) {
    80006b2e:	004aa783          	lw	a5,4(s5)
    80006b32:	fe9788e3          	beq	a5,s1,80006b22 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006b36:	f8042903          	lw	s2,-128(s0)
    80006b3a:	00290713          	addi	a4,s2,2
    80006b3e:	0712                	slli	a4,a4,0x4
    80006b40:	0023c797          	auipc	a5,0x23c
    80006b44:	78878793          	addi	a5,a5,1928 # 802432c8 <disk>
    80006b48:	97ba                	add	a5,a5,a4
    80006b4a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006b4e:	0023c997          	auipc	s3,0x23c
    80006b52:	77a98993          	addi	s3,s3,1914 # 802432c8 <disk>
    80006b56:	00491713          	slli	a4,s2,0x4
    80006b5a:	0009b783          	ld	a5,0(s3)
    80006b5e:	97ba                	add	a5,a5,a4
    80006b60:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b64:	854a                	mv	a0,s2
    80006b66:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b6a:	00000097          	auipc	ra,0x0
    80006b6e:	b9c080e7          	jalr	-1124(ra) # 80006706 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006b72:	8885                	andi	s1,s1,1
    80006b74:	f0ed                	bnez	s1,80006b56 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006b76:	0023d517          	auipc	a0,0x23d
    80006b7a:	87a50513          	addi	a0,a0,-1926 # 802433f0 <disk+0x128>
    80006b7e:	ffffa097          	auipc	ra,0xffffa
    80006b82:	200080e7          	jalr	512(ra) # 80000d7e <release>
}
    80006b86:	70e6                	ld	ra,120(sp)
    80006b88:	7446                	ld	s0,112(sp)
    80006b8a:	74a6                	ld	s1,104(sp)
    80006b8c:	7906                	ld	s2,96(sp)
    80006b8e:	69e6                	ld	s3,88(sp)
    80006b90:	6a46                	ld	s4,80(sp)
    80006b92:	6aa6                	ld	s5,72(sp)
    80006b94:	6b06                	ld	s6,64(sp)
    80006b96:	7be2                	ld	s7,56(sp)
    80006b98:	7c42                	ld	s8,48(sp)
    80006b9a:	7ca2                	ld	s9,40(sp)
    80006b9c:	7d02                	ld	s10,32(sp)
    80006b9e:	6de2                	ld	s11,24(sp)
    80006ba0:	6109                	addi	sp,sp,128
    80006ba2:	8082                	ret

0000000080006ba4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ba4:	1101                	addi	sp,sp,-32
    80006ba6:	ec06                	sd	ra,24(sp)
    80006ba8:	e822                	sd	s0,16(sp)
    80006baa:	e426                	sd	s1,8(sp)
    80006bac:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006bae:	0023c497          	auipc	s1,0x23c
    80006bb2:	71a48493          	addi	s1,s1,1818 # 802432c8 <disk>
    80006bb6:	0023d517          	auipc	a0,0x23d
    80006bba:	83a50513          	addi	a0,a0,-1990 # 802433f0 <disk+0x128>
    80006bbe:	ffffa097          	auipc	ra,0xffffa
    80006bc2:	10c080e7          	jalr	268(ra) # 80000cca <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006bc6:	10001737          	lui	a4,0x10001
    80006bca:	533c                	lw	a5,96(a4)
    80006bcc:	8b8d                	andi	a5,a5,3
    80006bce:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006bd0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006bd4:	689c                	ld	a5,16(s1)
    80006bd6:	0204d703          	lhu	a4,32(s1)
    80006bda:	0027d783          	lhu	a5,2(a5)
    80006bde:	04f70863          	beq	a4,a5,80006c2e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006be2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006be6:	6898                	ld	a4,16(s1)
    80006be8:	0204d783          	lhu	a5,32(s1)
    80006bec:	8b9d                	andi	a5,a5,7
    80006bee:	078e                	slli	a5,a5,0x3
    80006bf0:	97ba                	add	a5,a5,a4
    80006bf2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006bf4:	00278713          	addi	a4,a5,2
    80006bf8:	0712                	slli	a4,a4,0x4
    80006bfa:	9726                	add	a4,a4,s1
    80006bfc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006c00:	e721                	bnez	a4,80006c48 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c02:	0789                	addi	a5,a5,2
    80006c04:	0792                	slli	a5,a5,0x4
    80006c06:	97a6                	add	a5,a5,s1
    80006c08:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006c0a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c0e:	ffffc097          	auipc	ra,0xffffc
    80006c12:	826080e7          	jalr	-2010(ra) # 80002434 <wakeup>

    disk.used_idx += 1;
    80006c16:	0204d783          	lhu	a5,32(s1)
    80006c1a:	2785                	addiw	a5,a5,1
    80006c1c:	17c2                	slli	a5,a5,0x30
    80006c1e:	93c1                	srli	a5,a5,0x30
    80006c20:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006c24:	6898                	ld	a4,16(s1)
    80006c26:	00275703          	lhu	a4,2(a4)
    80006c2a:	faf71ce3          	bne	a4,a5,80006be2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006c2e:	0023c517          	auipc	a0,0x23c
    80006c32:	7c250513          	addi	a0,a0,1986 # 802433f0 <disk+0x128>
    80006c36:	ffffa097          	auipc	ra,0xffffa
    80006c3a:	148080e7          	jalr	328(ra) # 80000d7e <release>
}
    80006c3e:	60e2                	ld	ra,24(sp)
    80006c40:	6442                	ld	s0,16(sp)
    80006c42:	64a2                	ld	s1,8(sp)
    80006c44:	6105                	addi	sp,sp,32
    80006c46:	8082                	ret
      panic("virtio_disk_intr status");
    80006c48:	00002517          	auipc	a0,0x2
    80006c4c:	c6850513          	addi	a0,a0,-920 # 800088b0 <syscalls+0x400>
    80006c50:	ffffa097          	auipc	ra,0xffffa
    80006c54:	8f0080e7          	jalr	-1808(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
