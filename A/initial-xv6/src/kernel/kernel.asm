
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8f070713          	addi	a4,a4,-1808 # 80008940 <timer_scratch>
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
    80000066:	15e78793          	addi	a5,a5,350 # 800061c0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbc4f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
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
    8000012e:	452080e7          	jalr	1106(ra) # 8000257c <either_copyin>
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
    8000018e:	8f650513          	addi	a0,a0,-1802 # 80010a80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8e648493          	addi	s1,s1,-1818 # 80010a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	97690913          	addi	s2,s2,-1674 # 80010b18 <cons+0x98>
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
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1fe080e7          	jalr	510(ra) # 800023c6 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f3c080e7          	jalr	-196(ra) # 80002112 <sleep>
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
    80000216:	314080e7          	jalr	788(ra) # 80002526 <either_copyout>
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
    8000022a:	85a50513          	addi	a0,a0,-1958 # 80010a80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	84450513          	addi	a0,a0,-1980 # 80010a80 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
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
    80000276:	8af72323          	sw	a5,-1882(a4) # 80010b18 <cons+0x98>
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
    800002d0:	7b450513          	addi	a0,a0,1972 # 80010a80 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	2e0080e7          	jalr	736(ra) # 800025d2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	78650513          	addi	a0,a0,1926 # 80010a80 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    80000322:	76270713          	addi	a4,a4,1890 # 80010a80 <cons>
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
    8000034c:	73878793          	addi	a5,a5,1848 # 80010a80 <cons>
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
    8000037a:	7a27a783          	lw	a5,1954(a5) # 80010b18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6f670713          	addi	a4,a4,1782 # 80010a80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6e648493          	addi	s1,s1,1766 # 80010a80 <cons>
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
    800003da:	6aa70713          	addi	a4,a4,1706 # 80010a80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72a23          	sw	a5,1844(a4) # 80010b20 <cons+0xa0>
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
    80000416:	66e78793          	addi	a5,a5,1646 # 80010a80 <cons>
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
    8000043a:	6ec7a323          	sw	a2,1766(a5) # 80010b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6da50513          	addi	a0,a0,1754 # 80010b18 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d30080e7          	jalr	-720(ra) # 80002176 <wakeup>
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
    80000464:	62050513          	addi	a0,a0,1568 # 80010a80 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	5a078793          	addi	a5,a5,1440 # 80021a18 <devsw>
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
    80000550:	5e07aa23          	sw	zero,1524(a5) # 80010b40 <pr+0x18>
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
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	38f72023          	sw	a5,896(a4) # 80008900 <panicked>
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
    800005c0:	584dad83          	lw	s11,1412(s11) # 80010b40 <pr+0x18>
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
    800005fe:	52e50513          	addi	a0,a0,1326 # 80010b28 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
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
    8000075c:	3d050513          	addi	a0,a0,976 # 80010b28 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
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
    80000778:	3b448493          	addi	s1,s1,948 # 80010b28 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
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
    800007d8:	37450513          	addi	a0,a0,884 # 80010b48 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
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
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1007a783          	lw	a5,256(a5) # 80008900 <panicked>
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
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
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
    8000083c:	0d07b783          	ld	a5,208(a5) # 80008908 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0d073703          	ld	a4,208(a4) # 80008910 <uart_tx_w>
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
    80000866:	2e6a0a13          	addi	s4,s4,742 # 80010b48 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	09e48493          	addi	s1,s1,158 # 80008908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	09e98993          	addi	s3,s3,158 # 80008910 <uart_tx_w>
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
    80000898:	8e2080e7          	jalr	-1822(ra) # 80002176 <wakeup>
    
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
    800008d4:	27850513          	addi	a0,a0,632 # 80010b48 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0207a783          	lw	a5,32(a5) # 80008900 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	02673703          	ld	a4,38(a4) # 80008910 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0167b783          	ld	a5,22(a5) # 80008908 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	24a98993          	addi	s3,s3,586 # 80010b48 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	00248493          	addi	s1,s1,2 # 80008908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	00290913          	addi	s2,s2,2 # 80008910 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	7f4080e7          	jalr	2036(ra) # 80002112 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	21448493          	addi	s1,s1,532 # 80010b48 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fce7b423          	sd	a4,-56(a5) # 80008910 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
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
    800009be:	18e48493          	addi	s1,s1,398 # 80010b48 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
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
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	1b478793          	addi	a5,a5,436 # 80022bb0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	16490913          	addi	s2,s2,356 # 80010b80 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0c650513          	addi	a0,a0,198 # 80010b80 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	0e250513          	addi	a0,a0,226 # 80022bb0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	09048493          	addi	s1,s1,144 # 80010b80 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	07850513          	addi	a0,a0,120 # 80010b80 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	04c50513          	addi	a0,a0,76 # 80010b80 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc451>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a9070713          	addi	a4,a4,-1392 # 80008918 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	ba2080e7          	jalr	-1118(ra) # 80002a60 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	33a080e7          	jalr	826(ra) # 80006200 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	03a080e7          	jalr	58(ra) # 80001f08 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	b02080e7          	jalr	-1278(ra) # 80002a38 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	b22080e7          	jalr	-1246(ra) # 80002a60 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	2a4080e7          	jalr	676(ra) # 800061ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	2b2080e7          	jalr	690(ra) # 80006200 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	436080e7          	jalr	1078(ra) # 8000338c <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	ad6080e7          	jalr	-1322(ra) # 80003a34 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	a7c080e7          	jalr	-1412(ra) # 800049e2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	39a080e7          	jalr	922(ra) # 80006308 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d74080e7          	jalr	-652(ra) # 80001cea <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	98f72a23          	sw	a5,-1644(a4) # 80008918 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9887b783          	ld	a5,-1656(a5) # 80008920 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc447>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ca7b623          	sd	a0,1740(a5) # 80008920 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc450>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	78448493          	addi	s1,s1,1924 # 80010fd0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	f6aa0a13          	addi	s4,s4,-150 # 800177d0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8595                	srai	a1,a1,0x5
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a048493          	addi	s1,s1,416
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2b850513          	addi	a0,a0,696 # 80010ba0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2b850513          	addi	a0,a0,696 # 80010bb8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6c048493          	addi	s1,s1,1728 # 80010fd0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	e9e98993          	addi	s3,s3,-354 # 800177d0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8795                	srai	a5,a5,0x5
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a048493          	addi	s1,s1,416
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	23450513          	addi	a0,a0,564 # 80010bd0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1dc70713          	addi	a4,a4,476 # 80010ba0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e947a783          	lw	a5,-364(a5) # 80008890 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	072080e7          	jalr	114(ra) # 80002a78 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e607ad23          	sw	zero,-390(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	f94080e7          	jalr	-108(ra) # 800039b4 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	16a90913          	addi	s2,s2,362 # 80010ba0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e4c78793          	addi	a5,a5,-436 # 80008894 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->alarmtrpfrm)
    80001b7a:	1884b503          	ld	a0,392(s1)
    80001b7e:	c509                	beqz	a0,80001b88 <freeproc+0x2a>
    kfree(p->alarmtrpfrm);
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	e68080e7          	jalr	-408(ra) # 800009e8 <kfree>
  p->alarmtrpfrm = 0;
    80001b88:	1804b423          	sd	zero,392(s1)
  if (p->pagetable)
    80001b8c:	68a8                	ld	a0,80(s1)
    80001b8e:	c511                	beqz	a0,80001b9a <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80001b90:	64ac                	ld	a1,72(s1)
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	f7a080e7          	jalr	-134(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b9a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b9e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ba2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001baa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bae:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bba:	0004ac23          	sw	zero,24(s1)
}
    80001bbe:	60e2                	ld	ra,24(sp)
    80001bc0:	6442                	ld	s0,16(sp)
    80001bc2:	64a2                	ld	s1,8(sp)
    80001bc4:	6105                	addi	sp,sp,32
    80001bc6:	8082                	ret

0000000080001bc8 <allocproc>:
{
    80001bc8:	1101                	addi	sp,sp,-32
    80001bca:	ec06                	sd	ra,24(sp)
    80001bcc:	e822                	sd	s0,16(sp)
    80001bce:	e426                	sd	s1,8(sp)
    80001bd0:	e04a                	sd	s2,0(sp)
    80001bd2:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd4:	0000f497          	auipc	s1,0xf
    80001bd8:	3fc48493          	addi	s1,s1,1020 # 80010fd0 <proc>
    80001bdc:	00016917          	auipc	s2,0x16
    80001be0:	bf490913          	addi	s2,s2,-1036 # 800177d0 <tickslock>
    acquire(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	ff0080e7          	jalr	-16(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bee:	4c9c                	lw	a5,24(s1)
    80001bf0:	cf81                	beqz	a5,80001c08 <allocproc+0x40>
      release(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	096080e7          	jalr	150(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bfc:	1a048493          	addi	s1,s1,416
    80001c00:	ff2492e3          	bne	s1,s2,80001be4 <allocproc+0x1c>
  return 0;
    80001c04:	4481                	li	s1,0
    80001c06:	a079                	j	80001c94 <allocproc+0xcc>
  p->pid = allocpid();
    80001c08:	00000097          	auipc	ra,0x0
    80001c0c:	e22080e7          	jalr	-478(ra) # 80001a2a <allocpid>
    80001c10:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c12:	4785                	li	a5,1
    80001c14:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	ed0080e7          	jalr	-304(ra) # 80000ae6 <kalloc>
    80001c1e:	892a                	mv	s2,a0
    80001c20:	eca8                	sd	a0,88(s1)
    80001c22:	c141                	beqz	a0,80001ca2 <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	e4a080e7          	jalr	-438(ra) # 80001a70 <proc_pagetable>
    80001c2e:	892a                	mv	s2,a0
    80001c30:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c32:	c541                	beqz	a0,80001cba <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80001c34:	07000613          	li	a2,112
    80001c38:	4581                	li	a1,0
    80001c3a:	06048513          	addi	a0,s1,96
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	094080e7          	jalr	148(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c46:	00000797          	auipc	a5,0x0
    80001c4a:	d9e78793          	addi	a5,a5,-610 # 800019e4 <forkret>
    80001c4e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c50:	60bc                	ld	a5,64(s1)
    80001c52:	6705                	lui	a4,0x1
    80001c54:	97ba                	add	a5,a5,a4
    80001c56:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c58:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c5c:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c60:	00007797          	auipc	a5,0x7
    80001c64:	cd07a783          	lw	a5,-816(a5) # 80008930 <ticks>
    80001c68:	16f4a623          	sw	a5,364(s1)
  p->alarm_flag = 0;
    80001c6c:	1804a823          	sw	zero,400(s1)
  if ((p->alarmtrpfrm = (struct trapframe *)kalloc()) == 0)
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	e76080e7          	jalr	-394(ra) # 80000ae6 <kalloc>
    80001c78:	892a                	mv	s2,a0
    80001c7a:	18a4b423          	sd	a0,392(s1)
    80001c7e:	c931                	beqz	a0,80001cd2 <allocproc+0x10a>
  p->currticks = 0;
    80001c80:	1804a223          	sw	zero,388(s1)
  p->ticks = 0;
    80001c84:	1804a023          	sw	zero,384(s1)
  p->waittime = 0;
    80001c88:	1804aa23          	sw	zero,404(s1)
  p->inserttime = 0;
    80001c8c:	1804ac23          	sw	zero,408(s1)
  p->priority = 0;
    80001c90:	1804ae23          	sw	zero,412(s1)
}
    80001c94:	8526                	mv	a0,s1
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret
    freeproc(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	eba080e7          	jalr	-326(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	fdc080e7          	jalr	-36(ra) # 80000c8a <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	bff1                	j	80001c94 <allocproc+0xcc>
    freeproc(p);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	ea2080e7          	jalr	-350(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fc4080e7          	jalr	-60(ra) # 80000c8a <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	b7d1                	j	80001c94 <allocproc+0xcc>
    freeproc(p);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	e8a080e7          	jalr	-374(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fac080e7          	jalr	-84(ra) # 80000c8a <release>
    return 0;
    80001ce6:	84ca                	mv	s1,s2
    80001ce8:	b775                	j	80001c94 <allocproc+0xcc>

0000000080001cea <userinit>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	ed4080e7          	jalr	-300(ra) # 80001bc8 <allocproc>
    80001cfc:	84aa                	mv	s1,a0
  initproc = p;
    80001cfe:	00007797          	auipc	a5,0x7
    80001d02:	c2a7b523          	sd	a0,-982(a5) # 80008928 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d06:	03400613          	li	a2,52
    80001d0a:	00007597          	auipc	a1,0x7
    80001d0e:	b9658593          	addi	a1,a1,-1130 # 800088a0 <initcode>
    80001d12:	6928                	ld	a0,80(a0)
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	642080e7          	jalr	1602(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d1c:	6785                	lui	a5,0x1
    80001d1e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d20:	6cb8                	ld	a4,88(s1)
    80001d22:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d26:	6cb8                	ld	a4,88(s1)
    80001d28:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d2a:	4641                	li	a2,16
    80001d2c:	00006597          	auipc	a1,0x6
    80001d30:	4d458593          	addi	a1,a1,1236 # 80008200 <digits+0x1c0>
    80001d34:	15848513          	addi	a0,s1,344
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	0e4080e7          	jalr	228(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d40:	00006517          	auipc	a0,0x6
    80001d44:	4d050513          	addi	a0,a0,1232 # 80008210 <digits+0x1d0>
    80001d48:	00002097          	auipc	ra,0x2
    80001d4c:	696080e7          	jalr	1686(ra) # 800043de <namei>
    80001d50:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d54:	478d                	li	a5,3
    80001d56:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	f30080e7          	jalr	-208(ra) # 80000c8a <release>
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret

0000000080001d6c <growproc>:
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	e04a                	sd	s2,0(sp)
    80001d76:	1000                	addi	s0,sp,32
    80001d78:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c32080e7          	jalr	-974(ra) # 800019ac <myproc>
    80001d82:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d84:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d86:	01204c63          	bgtz	s2,80001d9e <growproc+0x32>
  else if (n < 0)
    80001d8a:	02094663          	bltz	s2,80001db6 <growproc+0x4a>
  p->sz = sz;
    80001d8e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d90:	4501                	li	a0,0
}
    80001d92:	60e2                	ld	ra,24(sp)
    80001d94:	6442                	ld	s0,16(sp)
    80001d96:	64a2                	ld	s1,8(sp)
    80001d98:	6902                	ld	s2,0(sp)
    80001d9a:	6105                	addi	sp,sp,32
    80001d9c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d9e:	4691                	li	a3,4
    80001da0:	00b90633          	add	a2,s2,a1
    80001da4:	6928                	ld	a0,80(a0)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	66a080e7          	jalr	1642(ra) # 80001410 <uvmalloc>
    80001dae:	85aa                	mv	a1,a0
    80001db0:	fd79                	bnez	a0,80001d8e <growproc+0x22>
      return -1;
    80001db2:	557d                	li	a0,-1
    80001db4:	bff9                	j	80001d92 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db6:	00b90633          	add	a2,s2,a1
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	60c080e7          	jalr	1548(ra) # 800013c8 <uvmdealloc>
    80001dc4:	85aa                	mv	a1,a0
    80001dc6:	b7e1                	j	80001d8e <growproc+0x22>

0000000080001dc8 <fork>:
{
    80001dc8:	7139                	addi	sp,sp,-64
    80001dca:	fc06                	sd	ra,56(sp)
    80001dcc:	f822                	sd	s0,48(sp)
    80001dce:	f426                	sd	s1,40(sp)
    80001dd0:	f04a                	sd	s2,32(sp)
    80001dd2:	ec4e                	sd	s3,24(sp)
    80001dd4:	e852                	sd	s4,16(sp)
    80001dd6:	e456                	sd	s5,8(sp)
    80001dd8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	bd2080e7          	jalr	-1070(ra) # 800019ac <myproc>
    80001de2:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	de4080e7          	jalr	-540(ra) # 80001bc8 <allocproc>
    80001dec:	10050c63          	beqz	a0,80001f04 <fork+0x13c>
    80001df0:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001df2:	048ab603          	ld	a2,72(s5)
    80001df6:	692c                	ld	a1,80(a0)
    80001df8:	050ab503          	ld	a0,80(s5)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	76c080e7          	jalr	1900(ra) # 80001568 <uvmcopy>
    80001e04:	04054863          	bltz	a0,80001e54 <fork+0x8c>
  np->sz = p->sz;
    80001e08:	048ab783          	ld	a5,72(s5)
    80001e0c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e10:	058ab683          	ld	a3,88(s5)
    80001e14:	87b6                	mv	a5,a3
    80001e16:	058a3703          	ld	a4,88(s4)
    80001e1a:	12068693          	addi	a3,a3,288
    80001e1e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e22:	6788                	ld	a0,8(a5)
    80001e24:	6b8c                	ld	a1,16(a5)
    80001e26:	6f90                	ld	a2,24(a5)
    80001e28:	01073023          	sd	a6,0(a4)
    80001e2c:	e708                	sd	a0,8(a4)
    80001e2e:	eb0c                	sd	a1,16(a4)
    80001e30:	ef10                	sd	a2,24(a4)
    80001e32:	02078793          	addi	a5,a5,32
    80001e36:	02070713          	addi	a4,a4,32
    80001e3a:	fed792e3          	bne	a5,a3,80001e1e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e3e:	058a3783          	ld	a5,88(s4)
    80001e42:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e46:	0d0a8493          	addi	s1,s5,208
    80001e4a:	0d0a0913          	addi	s2,s4,208
    80001e4e:	150a8993          	addi	s3,s5,336
    80001e52:	a00d                	j	80001e74 <fork+0xac>
    freeproc(np);
    80001e54:	8552                	mv	a0,s4
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	d08080e7          	jalr	-760(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e5e:	8552                	mv	a0,s4
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e2a080e7          	jalr	-470(ra) # 80000c8a <release>
    return -1;
    80001e68:	597d                	li	s2,-1
    80001e6a:	a059                	j	80001ef0 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e6c:	04a1                	addi	s1,s1,8
    80001e6e:	0921                	addi	s2,s2,8
    80001e70:	01348b63          	beq	s1,s3,80001e86 <fork+0xbe>
    if (p->ofile[i])
    80001e74:	6088                	ld	a0,0(s1)
    80001e76:	d97d                	beqz	a0,80001e6c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e78:	00003097          	auipc	ra,0x3
    80001e7c:	bfc080e7          	jalr	-1028(ra) # 80004a74 <filedup>
    80001e80:	00a93023          	sd	a0,0(s2)
    80001e84:	b7e5                	j	80001e6c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e86:	150ab503          	ld	a0,336(s5)
    80001e8a:	00002097          	auipc	ra,0x2
    80001e8e:	d6a080e7          	jalr	-662(ra) # 80003bf4 <idup>
    80001e92:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e96:	4641                	li	a2,16
    80001e98:	158a8593          	addi	a1,s5,344
    80001e9c:	158a0513          	addi	a0,s4,344
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	f7c080e7          	jalr	-132(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001ea8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eac:	8552                	mv	a0,s4
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	ddc080e7          	jalr	-548(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001eb6:	0000f497          	auipc	s1,0xf
    80001eba:	d0248493          	addi	s1,s1,-766 # 80010bb8 <wait_lock>
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	d16080e7          	jalr	-746(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ec8:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dbc080e7          	jalr	-580(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ed6:	8552                	mv	a0,s4
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	cfe080e7          	jalr	-770(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ee0:	478d                	li	a5,3
    80001ee2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ee6:	8552                	mv	a0,s4
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	da2080e7          	jalr	-606(ra) # 80000c8a <release>
}
    80001ef0:	854a                	mv	a0,s2
    80001ef2:	70e2                	ld	ra,56(sp)
    80001ef4:	7442                	ld	s0,48(sp)
    80001ef6:	74a2                	ld	s1,40(sp)
    80001ef8:	7902                	ld	s2,32(sp)
    80001efa:	69e2                	ld	s3,24(sp)
    80001efc:	6a42                	ld	s4,16(sp)
    80001efe:	6aa2                	ld	s5,8(sp)
    80001f00:	6121                	addi	sp,sp,64
    80001f02:	8082                	ret
    return -1;
    80001f04:	597d                	li	s2,-1
    80001f06:	b7ed                	j	80001ef0 <fork+0x128>

0000000080001f08 <scheduler>:
{
    80001f08:	711d                	addi	sp,sp,-96
    80001f0a:	ec86                	sd	ra,88(sp)
    80001f0c:	e8a2                	sd	s0,80(sp)
    80001f0e:	e4a6                	sd	s1,72(sp)
    80001f10:	e0ca                	sd	s2,64(sp)
    80001f12:	fc4e                	sd	s3,56(sp)
    80001f14:	f852                	sd	s4,48(sp)
    80001f16:	f456                	sd	s5,40(sp)
    80001f18:	f05a                	sd	s6,32(sp)
    80001f1a:	ec5e                	sd	s7,24(sp)
    80001f1c:	e862                	sd	s8,16(sp)
    80001f1e:	e466                	sd	s9,8(sp)
    80001f20:	e06a                	sd	s10,0(sp)
    80001f22:	1080                	addi	s0,sp,96
    80001f24:	8792                	mv	a5,tp
  int id = r_tp();
    80001f26:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f28:	00779c93          	slli	s9,a5,0x7
    80001f2c:	0000f717          	auipc	a4,0xf
    80001f30:	c7470713          	addi	a4,a4,-908 # 80010ba0 <pid_lock>
    80001f34:	9766                	add	a4,a4,s9
    80001f36:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &p->context);
    80001f3a:	0000f717          	auipc	a4,0xf
    80001f3e:	c9e70713          	addi	a4,a4,-866 # 80010bd8 <cpus+0x8>
    80001f42:	9cba                	add	s9,s9,a4
    int ctimeflag = 0;
    80001f44:	4b81                	li	s7,0
      if (p->state == RUNNABLE)
    80001f46:	490d                	li	s2,3
          ctimeflag = 1;
    80001f48:	4b05                	li	s6,1
    for (p = proc; p < &proc[NPROC]; p++)
    80001f4a:	00016997          	auipc	s3,0x16
    80001f4e:	88698993          	addi	s3,s3,-1914 # 800177d0 <tickslock>
      p->state = RUNNING;
    80001f52:	4d11                	li	s10,4
      c->proc = p;
    80001f54:	079e                	slli	a5,a5,0x7
    80001f56:	0000fc17          	auipc	s8,0xf
    80001f5a:	c4ac0c13          	addi	s8,s8,-950 # 80010ba0 <pid_lock>
    80001f5e:	9c3e                	add	s8,s8,a5
    80001f60:	a085                	j	80001fc0 <scheduler+0xb8>
          release(&minproc->lock);
    80001f62:	8552                	mv	a0,s4
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	d26080e7          	jalr	-730(ra) # 80000c8a <release>
          continue;
    80001f6c:	8a26                	mv	s4,s1
    80001f6e:	a031                	j	80001f7a <scheduler+0x72>
        release(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d18080e7          	jalr	-744(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f7a:	1a048493          	addi	s1,s1,416
    80001f7e:	03348b63          	beq	s1,s3,80001fb4 <scheduler+0xac>
      acquire(&p->lock);
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	c52080e7          	jalr	-942(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f8c:	4c9c                	lw	a5,24(s1)
    80001f8e:	ff2791e3          	bne	a5,s2,80001f70 <scheduler+0x68>
        if(ctimeflag == 0) //initialize mintime
    80001f92:	000a8e63          	beqz	s5,80001fae <scheduler+0xa6>
        else if(p->ctime < minproc->ctime)
    80001f96:	16c4a703          	lw	a4,364(s1)
    80001f9a:	16ca2783          	lw	a5,364(s4)
    80001f9e:	fcf762e3          	bltu	a4,a5,80001f62 <scheduler+0x5a>
        release(&p->lock);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	ce6080e7          	jalr	-794(ra) # 80000c8a <release>
    80001fac:	b7f9                	j	80001f7a <scheduler+0x72>
    80001fae:	8a26                	mv	s4,s1
          ctimeflag = 1;
    80001fb0:	8ada                	mv	s5,s6
    80001fb2:	b7e1                	j	80001f7a <scheduler+0x72>
    if (p != 0 && p->state == RUNNABLE)
    80001fb4:	000a0663          	beqz	s4,80001fc0 <scheduler+0xb8>
    80001fb8:	018a2783          	lw	a5,24(s4)
    80001fbc:	01278f63          	beq	a5,s2,80001fda <scheduler+0xd2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc8:	10079073          	csrw	sstatus,a5
    int ctimeflag = 0;
    80001fcc:	8ade                	mv	s5,s7
    struct proc* minproc = 0;
    80001fce:	8a5e                	mv	s4,s7
    for (p = proc; p < &proc[NPROC]; p++)
    80001fd0:	0000f497          	auipc	s1,0xf
    80001fd4:	00048493          	mv	s1,s1
    80001fd8:	b76d                	j	80001f82 <scheduler+0x7a>
      p->state = RUNNING;
    80001fda:	01aa2c23          	sw	s10,24(s4)
      c->proc = p;
    80001fde:	034c3823          	sd	s4,48(s8)
      swtch(&c->context, &p->context);
    80001fe2:	060a0593          	addi	a1,s4,96
    80001fe6:	8566                	mv	a0,s9
    80001fe8:	00001097          	auipc	ra,0x1
    80001fec:	9e6080e7          	jalr	-1562(ra) # 800029ce <swtch>
      c->proc = 0;  
    80001ff0:	020c3823          	sd	zero,48(s8)
      release(&p->lock);
    80001ff4:	8552                	mv	a0,s4
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	c94080e7          	jalr	-876(ra) # 80000c8a <release>
    80001ffe:	b7c9                	j	80001fc0 <scheduler+0xb8>

0000000080002000 <sched>:
{
    80002000:	7179                	addi	sp,sp,-48
    80002002:	f406                	sd	ra,40(sp)
    80002004:	f022                	sd	s0,32(sp)
    80002006:	ec26                	sd	s1,24(sp)
    80002008:	e84a                	sd	s2,16(sp)
    8000200a:	e44e                	sd	s3,8(sp)
    8000200c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	99e080e7          	jalr	-1634(ra) # 800019ac <myproc>
    80002016:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	b44080e7          	jalr	-1212(ra) # 80000b5c <holding>
    80002020:	c93d                	beqz	a0,80002096 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002024:	2781                	sext.w	a5,a5
    80002026:	079e                	slli	a5,a5,0x7
    80002028:	0000f717          	auipc	a4,0xf
    8000202c:	b7870713          	addi	a4,a4,-1160 # 80010ba0 <pid_lock>
    80002030:	97ba                	add	a5,a5,a4
    80002032:	0a87a703          	lw	a4,168(a5)
    80002036:	4785                	li	a5,1
    80002038:	06f71763          	bne	a4,a5,800020a6 <sched+0xa6>
  if (p->state == RUNNING)
    8000203c:	4c98                	lw	a4,24(s1)
    8000203e:	4791                	li	a5,4
    80002040:	06f70b63          	beq	a4,a5,800020b6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002044:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002048:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000204a:	efb5                	bnez	a5,800020c6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000204e:	0000f917          	auipc	s2,0xf
    80002052:	b5290913          	addi	s2,s2,-1198 # 80010ba0 <pid_lock>
    80002056:	2781                	sext.w	a5,a5
    80002058:	079e                	slli	a5,a5,0x7
    8000205a:	97ca                	add	a5,a5,s2
    8000205c:	0ac7a983          	lw	s3,172(a5)
    80002060:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002062:	2781                	sext.w	a5,a5
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	0000f597          	auipc	a1,0xf
    8000206a:	b7258593          	addi	a1,a1,-1166 # 80010bd8 <cpus+0x8>
    8000206e:	95be                	add	a1,a1,a5
    80002070:	06048513          	addi	a0,s1,96 # 80011030 <proc+0x60>
    80002074:	00001097          	auipc	ra,0x1
    80002078:	95a080e7          	jalr	-1702(ra) # 800029ce <swtch>
    8000207c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000207e:	2781                	sext.w	a5,a5
    80002080:	079e                	slli	a5,a5,0x7
    80002082:	993e                	add	s2,s2,a5
    80002084:	0b392623          	sw	s3,172(s2)
}
    80002088:	70a2                	ld	ra,40(sp)
    8000208a:	7402                	ld	s0,32(sp)
    8000208c:	64e2                	ld	s1,24(sp)
    8000208e:	6942                	ld	s2,16(sp)
    80002090:	69a2                	ld	s3,8(sp)
    80002092:	6145                	addi	sp,sp,48
    80002094:	8082                	ret
    panic("sched p->lock");
    80002096:	00006517          	auipc	a0,0x6
    8000209a:	18250513          	addi	a0,a0,386 # 80008218 <digits+0x1d8>
    8000209e:	ffffe097          	auipc	ra,0xffffe
    800020a2:	4a2080e7          	jalr	1186(ra) # 80000540 <panic>
    panic("sched locks");
    800020a6:	00006517          	auipc	a0,0x6
    800020aa:	18250513          	addi	a0,a0,386 # 80008228 <digits+0x1e8>
    800020ae:	ffffe097          	auipc	ra,0xffffe
    800020b2:	492080e7          	jalr	1170(ra) # 80000540 <panic>
    panic("sched running");
    800020b6:	00006517          	auipc	a0,0x6
    800020ba:	18250513          	addi	a0,a0,386 # 80008238 <digits+0x1f8>
    800020be:	ffffe097          	auipc	ra,0xffffe
    800020c2:	482080e7          	jalr	1154(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	18250513          	addi	a0,a0,386 # 80008248 <digits+0x208>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	472080e7          	jalr	1138(ra) # 80000540 <panic>

00000000800020d6 <yield>:
{
    800020d6:	1101                	addi	sp,sp,-32
    800020d8:	ec06                	sd	ra,24(sp)
    800020da:	e822                	sd	s0,16(sp)
    800020dc:	e426                	sd	s1,8(sp)
    800020de:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	8cc080e7          	jalr	-1844(ra) # 800019ac <myproc>
    800020e8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	aec080e7          	jalr	-1300(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020f2:	478d                	li	a5,3
    800020f4:	cc9c                	sw	a5,24(s1)
  sched();
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	f0a080e7          	jalr	-246(ra) # 80002000 <sched>
  release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b8a080e7          	jalr	-1142(ra) # 80000c8a <release>
}
    80002108:	60e2                	ld	ra,24(sp)
    8000210a:	6442                	ld	s0,16(sp)
    8000210c:	64a2                	ld	s1,8(sp)
    8000210e:	6105                	addi	sp,sp,32
    80002110:	8082                	ret

0000000080002112 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002112:	7179                	addi	sp,sp,-48
    80002114:	f406                	sd	ra,40(sp)
    80002116:	f022                	sd	s0,32(sp)
    80002118:	ec26                	sd	s1,24(sp)
    8000211a:	e84a                	sd	s2,16(sp)
    8000211c:	e44e                	sd	s3,8(sp)
    8000211e:	1800                	addi	s0,sp,48
    80002120:	89aa                	mv	s3,a0
    80002122:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	888080e7          	jalr	-1912(ra) # 800019ac <myproc>
    8000212c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	aa8080e7          	jalr	-1368(ra) # 80000bd6 <acquire>
  release(lk);
    80002136:	854a                	mv	a0,s2
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002140:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002144:	4789                	li	a5,2
    80002146:	cc9c                	sw	a5,24(s1)

  sched();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	eb8080e7          	jalr	-328(ra) # 80002000 <sched>

  // Tidy up.
  p->chan = 0;
    80002150:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b34080e7          	jalr	-1228(ra) # 80000c8a <release>
  acquire(lk);
    8000215e:	854a                	mv	a0,s2
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	a76080e7          	jalr	-1418(ra) # 80000bd6 <acquire>
}
    80002168:	70a2                	ld	ra,40(sp)
    8000216a:	7402                	ld	s0,32(sp)
    8000216c:	64e2                	ld	s1,24(sp)
    8000216e:	6942                	ld	s2,16(sp)
    80002170:	69a2                	ld	s3,8(sp)
    80002172:	6145                	addi	sp,sp,48
    80002174:	8082                	ret

0000000080002176 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002176:	7139                	addi	sp,sp,-64
    80002178:	fc06                	sd	ra,56(sp)
    8000217a:	f822                	sd	s0,48(sp)
    8000217c:	f426                	sd	s1,40(sp)
    8000217e:	f04a                	sd	s2,32(sp)
    80002180:	ec4e                	sd	s3,24(sp)
    80002182:	e852                	sd	s4,16(sp)
    80002184:	e456                	sd	s5,8(sp)
    80002186:	0080                	addi	s0,sp,64
    80002188:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000218a:	0000f497          	auipc	s1,0xf
    8000218e:	e4648493          	addi	s1,s1,-442 # 80010fd0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002192:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002194:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002196:	00015917          	auipc	s2,0x15
    8000219a:	63a90913          	addi	s2,s2,1594 # 800177d0 <tickslock>
    8000219e:	a811                	j	800021b2 <wakeup+0x3c>
      }
      release(&p->lock);
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	ae8080e7          	jalr	-1304(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800021aa:	1a048493          	addi	s1,s1,416
    800021ae:	03248663          	beq	s1,s2,800021da <wakeup+0x64>
    if (p != myproc())
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	7fa080e7          	jalr	2042(ra) # 800019ac <myproc>
    800021ba:	fea488e3          	beq	s1,a0,800021aa <wakeup+0x34>
      acquire(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a16080e7          	jalr	-1514(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021c8:	4c9c                	lw	a5,24(s1)
    800021ca:	fd379be3          	bne	a5,s3,800021a0 <wakeup+0x2a>
    800021ce:	709c                	ld	a5,32(s1)
    800021d0:	fd4798e3          	bne	a5,s4,800021a0 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021d4:	0154ac23          	sw	s5,24(s1)
    800021d8:	b7e1                	j	800021a0 <wakeup+0x2a>
    }
  }
}
    800021da:	70e2                	ld	ra,56(sp)
    800021dc:	7442                	ld	s0,48(sp)
    800021de:	74a2                	ld	s1,40(sp)
    800021e0:	7902                	ld	s2,32(sp)
    800021e2:	69e2                	ld	s3,24(sp)
    800021e4:	6a42                	ld	s4,16(sp)
    800021e6:	6aa2                	ld	s5,8(sp)
    800021e8:	6121                	addi	sp,sp,64
    800021ea:	8082                	ret

00000000800021ec <reparent>:
{
    800021ec:	7179                	addi	sp,sp,-48
    800021ee:	f406                	sd	ra,40(sp)
    800021f0:	f022                	sd	s0,32(sp)
    800021f2:	ec26                	sd	s1,24(sp)
    800021f4:	e84a                	sd	s2,16(sp)
    800021f6:	e44e                	sd	s3,8(sp)
    800021f8:	e052                	sd	s4,0(sp)
    800021fa:	1800                	addi	s0,sp,48
    800021fc:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021fe:	0000f497          	auipc	s1,0xf
    80002202:	dd248493          	addi	s1,s1,-558 # 80010fd0 <proc>
      pp->parent = initproc;
    80002206:	00006a17          	auipc	s4,0x6
    8000220a:	722a0a13          	addi	s4,s4,1826 # 80008928 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000220e:	00015997          	auipc	s3,0x15
    80002212:	5c298993          	addi	s3,s3,1474 # 800177d0 <tickslock>
    80002216:	a029                	j	80002220 <reparent+0x34>
    80002218:	1a048493          	addi	s1,s1,416
    8000221c:	01348d63          	beq	s1,s3,80002236 <reparent+0x4a>
    if (pp->parent == p)
    80002220:	7c9c                	ld	a5,56(s1)
    80002222:	ff279be3          	bne	a5,s2,80002218 <reparent+0x2c>
      pp->parent = initproc;
    80002226:	000a3503          	ld	a0,0(s4)
    8000222a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	f4a080e7          	jalr	-182(ra) # 80002176 <wakeup>
    80002234:	b7d5                	j	80002218 <reparent+0x2c>
}
    80002236:	70a2                	ld	ra,40(sp)
    80002238:	7402                	ld	s0,32(sp)
    8000223a:	64e2                	ld	s1,24(sp)
    8000223c:	6942                	ld	s2,16(sp)
    8000223e:	69a2                	ld	s3,8(sp)
    80002240:	6a02                	ld	s4,0(sp)
    80002242:	6145                	addi	sp,sp,48
    80002244:	8082                	ret

0000000080002246 <exit>:
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	e052                	sd	s4,0(sp)
    80002254:	1800                	addi	s0,sp,48
    80002256:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	754080e7          	jalr	1876(ra) # 800019ac <myproc>
    80002260:	89aa                	mv	s3,a0
  if (p == initproc)
    80002262:	00006797          	auipc	a5,0x6
    80002266:	6c67b783          	ld	a5,1734(a5) # 80008928 <initproc>
    8000226a:	0d050493          	addi	s1,a0,208
    8000226e:	15050913          	addi	s2,a0,336
    80002272:	02a79363          	bne	a5,a0,80002298 <exit+0x52>
    panic("init exiting");
    80002276:	00006517          	auipc	a0,0x6
    8000227a:	fea50513          	addi	a0,a0,-22 # 80008260 <digits+0x220>
    8000227e:	ffffe097          	auipc	ra,0xffffe
    80002282:	2c2080e7          	jalr	706(ra) # 80000540 <panic>
      fileclose(f);
    80002286:	00003097          	auipc	ra,0x3
    8000228a:	840080e7          	jalr	-1984(ra) # 80004ac6 <fileclose>
      p->ofile[fd] = 0;
    8000228e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002292:	04a1                	addi	s1,s1,8
    80002294:	01248563          	beq	s1,s2,8000229e <exit+0x58>
    if (p->ofile[fd])
    80002298:	6088                	ld	a0,0(s1)
    8000229a:	f575                	bnez	a0,80002286 <exit+0x40>
    8000229c:	bfdd                	j	80002292 <exit+0x4c>
  begin_op();
    8000229e:	00002097          	auipc	ra,0x2
    800022a2:	360080e7          	jalr	864(ra) # 800045fe <begin_op>
  iput(p->cwd);
    800022a6:	1509b503          	ld	a0,336(s3)
    800022aa:	00002097          	auipc	ra,0x2
    800022ae:	b42080e7          	jalr	-1214(ra) # 80003dec <iput>
  end_op();
    800022b2:	00002097          	auipc	ra,0x2
    800022b6:	3ca080e7          	jalr	970(ra) # 8000467c <end_op>
  p->cwd = 0;
    800022ba:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022be:	0000f497          	auipc	s1,0xf
    800022c2:	8fa48493          	addi	s1,s1,-1798 # 80010bb8 <wait_lock>
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	90e080e7          	jalr	-1778(ra) # 80000bd6 <acquire>
  reparent(p);
    800022d0:	854e                	mv	a0,s3
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	f1a080e7          	jalr	-230(ra) # 800021ec <reparent>
  wakeup(p->parent);
    800022da:	0389b503          	ld	a0,56(s3)
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	e98080e7          	jalr	-360(ra) # 80002176 <wakeup>
  acquire(&p->lock);
    800022e6:	854e                	mv	a0,s3
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	8ee080e7          	jalr	-1810(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022f0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022f4:	4795                	li	a5,5
    800022f6:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022fa:	00006797          	auipc	a5,0x6
    800022fe:	6367a783          	lw	a5,1590(a5) # 80008930 <ticks>
    80002302:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	982080e7          	jalr	-1662(ra) # 80000c8a <release>
  sched();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	cf0080e7          	jalr	-784(ra) # 80002000 <sched>
  panic("zombie exit");
    80002318:	00006517          	auipc	a0,0x6
    8000231c:	f5850513          	addi	a0,a0,-168 # 80008270 <digits+0x230>
    80002320:	ffffe097          	auipc	ra,0xffffe
    80002324:	220080e7          	jalr	544(ra) # 80000540 <panic>

0000000080002328 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	1800                	addi	s0,sp,48
    80002336:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002338:	0000f497          	auipc	s1,0xf
    8000233c:	c9848493          	addi	s1,s1,-872 # 80010fd0 <proc>
    80002340:	00015997          	auipc	s3,0x15
    80002344:	49098993          	addi	s3,s3,1168 # 800177d0 <tickslock>
  {
    acquire(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	88c080e7          	jalr	-1908(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002352:	589c                	lw	a5,48(s1)
    80002354:	01278d63          	beq	a5,s2,8000236e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	930080e7          	jalr	-1744(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002362:	1a048493          	addi	s1,s1,416
    80002366:	ff3491e3          	bne	s1,s3,80002348 <kill+0x20>
  }
  return -1;
    8000236a:	557d                	li	a0,-1
    8000236c:	a829                	j	80002386 <kill+0x5e>
      p->killed = 1;
    8000236e:	4785                	li	a5,1
    80002370:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002372:	4c98                	lw	a4,24(s1)
    80002374:	4789                	li	a5,2
    80002376:	00f70f63          	beq	a4,a5,80002394 <kill+0x6c>
      release(&p->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	90e080e7          	jalr	-1778(ra) # 80000c8a <release>
      return 0;
    80002384:	4501                	li	a0,0
}
    80002386:	70a2                	ld	ra,40(sp)
    80002388:	7402                	ld	s0,32(sp)
    8000238a:	64e2                	ld	s1,24(sp)
    8000238c:	6942                	ld	s2,16(sp)
    8000238e:	69a2                	ld	s3,8(sp)
    80002390:	6145                	addi	sp,sp,48
    80002392:	8082                	ret
        p->state = RUNNABLE;
    80002394:	478d                	li	a5,3
    80002396:	cc9c                	sw	a5,24(s1)
    80002398:	b7cd                	j	8000237a <kill+0x52>

000000008000239a <setkilled>:

void setkilled(struct proc *p)
{
    8000239a:	1101                	addi	sp,sp,-32
    8000239c:	ec06                	sd	ra,24(sp)
    8000239e:	e822                	sd	s0,16(sp)
    800023a0:	e426                	sd	s1,8(sp)
    800023a2:	1000                	addi	s0,sp,32
    800023a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800023ae:	4785                	li	a5,1
    800023b0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
}
    800023bc:	60e2                	ld	ra,24(sp)
    800023be:	6442                	ld	s0,16(sp)
    800023c0:	64a2                	ld	s1,8(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <killed>:

int killed(struct proc *p)
{
    800023c6:	1101                	addi	sp,sp,-32
    800023c8:	ec06                	sd	ra,24(sp)
    800023ca:	e822                	sd	s0,16(sp)
    800023cc:	e426                	sd	s1,8(sp)
    800023ce:	e04a                	sd	s2,0(sp)
    800023d0:	1000                	addi	s0,sp,32
    800023d2:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	802080e7          	jalr	-2046(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023dc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8a8080e7          	jalr	-1880(ra) # 80000c8a <release>
  return k;
}
    800023ea:	854a                	mv	a0,s2
    800023ec:	60e2                	ld	ra,24(sp)
    800023ee:	6442                	ld	s0,16(sp)
    800023f0:	64a2                	ld	s1,8(sp)
    800023f2:	6902                	ld	s2,0(sp)
    800023f4:	6105                	addi	sp,sp,32
    800023f6:	8082                	ret

00000000800023f8 <wait>:
{
    800023f8:	715d                	addi	sp,sp,-80
    800023fa:	e486                	sd	ra,72(sp)
    800023fc:	e0a2                	sd	s0,64(sp)
    800023fe:	fc26                	sd	s1,56(sp)
    80002400:	f84a                	sd	s2,48(sp)
    80002402:	f44e                	sd	s3,40(sp)
    80002404:	f052                	sd	s4,32(sp)
    80002406:	ec56                	sd	s5,24(sp)
    80002408:	e85a                	sd	s6,16(sp)
    8000240a:	e45e                	sd	s7,8(sp)
    8000240c:	e062                	sd	s8,0(sp)
    8000240e:	0880                	addi	s0,sp,80
    80002410:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	59a080e7          	jalr	1434(ra) # 800019ac <myproc>
    8000241a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000241c:	0000e517          	auipc	a0,0xe
    80002420:	79c50513          	addi	a0,a0,1948 # 80010bb8 <wait_lock>
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7b2080e7          	jalr	1970(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000242c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000242e:	4a15                	li	s4,5
        havekids = 1;
    80002430:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002432:	00015997          	auipc	s3,0x15
    80002436:	39e98993          	addi	s3,s3,926 # 800177d0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000243a:	0000ec17          	auipc	s8,0xe
    8000243e:	77ec0c13          	addi	s8,s8,1918 # 80010bb8 <wait_lock>
    havekids = 0;
    80002442:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002444:	0000f497          	auipc	s1,0xf
    80002448:	b8c48493          	addi	s1,s1,-1140 # 80010fd0 <proc>
    8000244c:	a0bd                	j	800024ba <wait+0xc2>
          pid = pp->pid;
    8000244e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002452:	000b0e63          	beqz	s6,8000246e <wait+0x76>
    80002456:	4691                	li	a3,4
    80002458:	02c48613          	addi	a2,s1,44
    8000245c:	85da                	mv	a1,s6
    8000245e:	05093503          	ld	a0,80(s2)
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	20a080e7          	jalr	522(ra) # 8000166c <copyout>
    8000246a:	02054563          	bltz	a0,80002494 <wait+0x9c>
          freeproc(pp);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	6ee080e7          	jalr	1774(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
          release(&wait_lock);
    80002482:	0000e517          	auipc	a0,0xe
    80002486:	73650513          	addi	a0,a0,1846 # 80010bb8 <wait_lock>
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	800080e7          	jalr	-2048(ra) # 80000c8a <release>
          return pid;
    80002492:	a0b5                	j	800024fe <wait+0x106>
            release(&pp->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	7f4080e7          	jalr	2036(ra) # 80000c8a <release>
            release(&wait_lock);
    8000249e:	0000e517          	auipc	a0,0xe
    800024a2:	71a50513          	addi	a0,a0,1818 # 80010bb8 <wait_lock>
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	7e4080e7          	jalr	2020(ra) # 80000c8a <release>
            return -1;
    800024ae:	59fd                	li	s3,-1
    800024b0:	a0b9                	j	800024fe <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b2:	1a048493          	addi	s1,s1,416
    800024b6:	03348463          	beq	s1,s3,800024de <wait+0xe6>
      if (pp->parent == p)
    800024ba:	7c9c                	ld	a5,56(s1)
    800024bc:	ff279be3          	bne	a5,s2,800024b2 <wait+0xba>
        acquire(&pp->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	714080e7          	jalr	1812(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    800024ca:	4c9c                	lw	a5,24(s1)
    800024cc:	f94781e3          	beq	a5,s4,8000244e <wait+0x56>
        release(&pp->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7b8080e7          	jalr	1976(ra) # 80000c8a <release>
        havekids = 1;
    800024da:	8756                	mv	a4,s5
    800024dc:	bfd9                	j	800024b2 <wait+0xba>
    if (!havekids || killed(p))
    800024de:	c719                	beqz	a4,800024ec <wait+0xf4>
    800024e0:	854a                	mv	a0,s2
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	ee4080e7          	jalr	-284(ra) # 800023c6 <killed>
    800024ea:	c51d                	beqz	a0,80002518 <wait+0x120>
      release(&wait_lock);
    800024ec:	0000e517          	auipc	a0,0xe
    800024f0:	6cc50513          	addi	a0,a0,1740 # 80010bb8 <wait_lock>
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	796080e7          	jalr	1942(ra) # 80000c8a <release>
      return -1;
    800024fc:	59fd                	li	s3,-1
}
    800024fe:	854e                	mv	a0,s3
    80002500:	60a6                	ld	ra,72(sp)
    80002502:	6406                	ld	s0,64(sp)
    80002504:	74e2                	ld	s1,56(sp)
    80002506:	7942                	ld	s2,48(sp)
    80002508:	79a2                	ld	s3,40(sp)
    8000250a:	7a02                	ld	s4,32(sp)
    8000250c:	6ae2                	ld	s5,24(sp)
    8000250e:	6b42                	ld	s6,16(sp)
    80002510:	6ba2                	ld	s7,8(sp)
    80002512:	6c02                	ld	s8,0(sp)
    80002514:	6161                	addi	sp,sp,80
    80002516:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002518:	85e2                	mv	a1,s8
    8000251a:	854a                	mv	a0,s2
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	bf6080e7          	jalr	-1034(ra) # 80002112 <sleep>
    havekids = 0;
    80002524:	bf39                	j	80002442 <wait+0x4a>

0000000080002526 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002526:	7179                	addi	sp,sp,-48
    80002528:	f406                	sd	ra,40(sp)
    8000252a:	f022                	sd	s0,32(sp)
    8000252c:	ec26                	sd	s1,24(sp)
    8000252e:	e84a                	sd	s2,16(sp)
    80002530:	e44e                	sd	s3,8(sp)
    80002532:	e052                	sd	s4,0(sp)
    80002534:	1800                	addi	s0,sp,48
    80002536:	84aa                	mv	s1,a0
    80002538:	892e                	mv	s2,a1
    8000253a:	89b2                	mv	s3,a2
    8000253c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	46e080e7          	jalr	1134(ra) # 800019ac <myproc>
  if (user_dst)
    80002546:	c08d                	beqz	s1,80002568 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002548:	86d2                	mv	a3,s4
    8000254a:	864e                	mv	a2,s3
    8000254c:	85ca                	mv	a1,s2
    8000254e:	6928                	ld	a0,80(a0)
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	11c080e7          	jalr	284(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002558:	70a2                	ld	ra,40(sp)
    8000255a:	7402                	ld	s0,32(sp)
    8000255c:	64e2                	ld	s1,24(sp)
    8000255e:	6942                	ld	s2,16(sp)
    80002560:	69a2                	ld	s3,8(sp)
    80002562:	6a02                	ld	s4,0(sp)
    80002564:	6145                	addi	sp,sp,48
    80002566:	8082                	ret
    memmove((char *)dst, src, len);
    80002568:	000a061b          	sext.w	a2,s4
    8000256c:	85ce                	mv	a1,s3
    8000256e:	854a                	mv	a0,s2
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	7be080e7          	jalr	1982(ra) # 80000d2e <memmove>
    return 0;
    80002578:	8526                	mv	a0,s1
    8000257a:	bff9                	j	80002558 <either_copyout+0x32>

000000008000257c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000257c:	7179                	addi	sp,sp,-48
    8000257e:	f406                	sd	ra,40(sp)
    80002580:	f022                	sd	s0,32(sp)
    80002582:	ec26                	sd	s1,24(sp)
    80002584:	e84a                	sd	s2,16(sp)
    80002586:	e44e                	sd	s3,8(sp)
    80002588:	e052                	sd	s4,0(sp)
    8000258a:	1800                	addi	s0,sp,48
    8000258c:	892a                	mv	s2,a0
    8000258e:	84ae                	mv	s1,a1
    80002590:	89b2                	mv	s3,a2
    80002592:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	418080e7          	jalr	1048(ra) # 800019ac <myproc>
  if (user_src)
    8000259c:	c08d                	beqz	s1,800025be <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000259e:	86d2                	mv	a3,s4
    800025a0:	864e                	mv	a2,s3
    800025a2:	85ca                	mv	a1,s2
    800025a4:	6928                	ld	a0,80(a0)
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	152080e7          	jalr	338(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800025ae:	70a2                	ld	ra,40(sp)
    800025b0:	7402                	ld	s0,32(sp)
    800025b2:	64e2                	ld	s1,24(sp)
    800025b4:	6942                	ld	s2,16(sp)
    800025b6:	69a2                	ld	s3,8(sp)
    800025b8:	6a02                	ld	s4,0(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret
    memmove(dst, (char *)src, len);
    800025be:	000a061b          	sext.w	a2,s4
    800025c2:	85ce                	mv	a1,s3
    800025c4:	854a                	mv	a0,s2
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	768080e7          	jalr	1896(ra) # 80000d2e <memmove>
    return 0;
    800025ce:	8526                	mv	a0,s1
    800025d0:	bff9                	j	800025ae <either_copyin+0x32>

00000000800025d2 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025d2:	715d                	addi	sp,sp,-80
    800025d4:	e486                	sd	ra,72(sp)
    800025d6:	e0a2                	sd	s0,64(sp)
    800025d8:	fc26                	sd	s1,56(sp)
    800025da:	f84a                	sd	s2,48(sp)
    800025dc:	f44e                	sd	s3,40(sp)
    800025de:	f052                	sd	s4,32(sp)
    800025e0:	ec56                	sd	s5,24(sp)
    800025e2:	e85a                	sd	s6,16(sp)
    800025e4:	e45e                	sd	s7,8(sp)
    800025e6:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025e8:	00006517          	auipc	a0,0x6
    800025ec:	ae050513          	addi	a0,a0,-1312 # 800080c8 <digits+0x88>
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	f9a080e7          	jalr	-102(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025f8:	0000f497          	auipc	s1,0xf
    800025fc:	b3048493          	addi	s1,s1,-1232 # 80011128 <proc+0x158>
    80002600:	00015917          	auipc	s2,0x15
    80002604:	32890913          	addi	s2,s2,808 # 80017928 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000260a:	00006997          	auipc	s3,0x6
    8000260e:	c7698993          	addi	s3,s3,-906 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002612:	00006a97          	auipc	s5,0x6
    80002616:	c76a8a93          	addi	s5,s5,-906 # 80008288 <digits+0x248>
    printf("\n");
    8000261a:	00006a17          	auipc	s4,0x6
    8000261e:	aaea0a13          	addi	s4,s4,-1362 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002622:	00006b97          	auipc	s7,0x6
    80002626:	cd6b8b93          	addi	s7,s7,-810 # 800082f8 <states.0>
    8000262a:	a00d                	j	8000264c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000262c:	ed86a583          	lw	a1,-296(a3)
    80002630:	8556                	mv	a0,s5
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	f58080e7          	jalr	-168(ra) # 8000058a <printf>
    printf("\n");
    8000263a:	8552                	mv	a0,s4
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	f4e080e7          	jalr	-178(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002644:	1a048493          	addi	s1,s1,416
    80002648:	03248263          	beq	s1,s2,8000266c <procdump+0x9a>
    if (p->state == UNUSED)
    8000264c:	86a6                	mv	a3,s1
    8000264e:	ec04a783          	lw	a5,-320(s1)
    80002652:	dbed                	beqz	a5,80002644 <procdump+0x72>
      state = "???";
    80002654:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002656:	fcfb6be3          	bltu	s6,a5,8000262c <procdump+0x5a>
    8000265a:	02079713          	slli	a4,a5,0x20
    8000265e:	01d75793          	srli	a5,a4,0x1d
    80002662:	97de                	add	a5,a5,s7
    80002664:	6390                	ld	a2,0(a5)
    80002666:	f279                	bnez	a2,8000262c <procdump+0x5a>
      state = "???";
    80002668:	864e                	mv	a2,s3
    8000266a:	b7c9                	j	8000262c <procdump+0x5a>
  }
}
    8000266c:	60a6                	ld	ra,72(sp)
    8000266e:	6406                	ld	s0,64(sp)
    80002670:	74e2                	ld	s1,56(sp)
    80002672:	7942                	ld	s2,48(sp)
    80002674:	79a2                	ld	s3,40(sp)
    80002676:	7a02                	ld	s4,32(sp)
    80002678:	6ae2                	ld	s5,24(sp)
    8000267a:	6b42                	ld	s6,16(sp)
    8000267c:	6ba2                	ld	s7,8(sp)
    8000267e:	6161                	addi	sp,sp,80
    80002680:	8082                	ret

0000000080002682 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002682:	711d                	addi	sp,sp,-96
    80002684:	ec86                	sd	ra,88(sp)
    80002686:	e8a2                	sd	s0,80(sp)
    80002688:	e4a6                	sd	s1,72(sp)
    8000268a:	e0ca                	sd	s2,64(sp)
    8000268c:	fc4e                	sd	s3,56(sp)
    8000268e:	f852                	sd	s4,48(sp)
    80002690:	f456                	sd	s5,40(sp)
    80002692:	f05a                	sd	s6,32(sp)
    80002694:	ec5e                	sd	s7,24(sp)
    80002696:	e862                	sd	s8,16(sp)
    80002698:	e466                	sd	s9,8(sp)
    8000269a:	e06a                	sd	s10,0(sp)
    8000269c:	1080                	addi	s0,sp,96
    8000269e:	8b2a                	mv	s6,a0
    800026a0:	8bae                	mv	s7,a1
    800026a2:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	308080e7          	jalr	776(ra) # 800019ac <myproc>
    800026ac:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800026ae:	0000e517          	auipc	a0,0xe
    800026b2:	50a50513          	addi	a0,a0,1290 # 80010bb8 <wait_lock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	520080e7          	jalr	1312(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800026be:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800026c0:	4a15                	li	s4,5
        havekids = 1;
    800026c2:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800026c4:	00015997          	auipc	s3,0x15
    800026c8:	10c98993          	addi	s3,s3,268 # 800177d0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026cc:	0000ed17          	auipc	s10,0xe
    800026d0:	4ecd0d13          	addi	s10,s10,1260 # 80010bb8 <wait_lock>
    havekids = 0;
    800026d4:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800026d6:	0000f497          	auipc	s1,0xf
    800026da:	8fa48493          	addi	s1,s1,-1798 # 80010fd0 <proc>
    800026de:	a059                	j	80002764 <waitx+0xe2>
          pid = np->pid;
    800026e0:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800026e4:	1684a783          	lw	a5,360(s1)
    800026e8:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800026ec:	16c4a703          	lw	a4,364(s1)
    800026f0:	9f3d                	addw	a4,a4,a5
    800026f2:	1704a783          	lw	a5,368(s1)
    800026f6:	9f99                	subw	a5,a5,a4
    800026f8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026fc:	000b0e63          	beqz	s6,80002718 <waitx+0x96>
    80002700:	4691                	li	a3,4
    80002702:	02c48613          	addi	a2,s1,44
    80002706:	85da                	mv	a1,s6
    80002708:	05093503          	ld	a0,80(s2)
    8000270c:	fffff097          	auipc	ra,0xfffff
    80002710:	f60080e7          	jalr	-160(ra) # 8000166c <copyout>
    80002714:	02054563          	bltz	a0,8000273e <waitx+0xbc>
          freeproc(np);
    80002718:	8526                	mv	a0,s1
    8000271a:	fffff097          	auipc	ra,0xfffff
    8000271e:	444080e7          	jalr	1092(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	566080e7          	jalr	1382(ra) # 80000c8a <release>
          release(&wait_lock);
    8000272c:	0000e517          	auipc	a0,0xe
    80002730:	48c50513          	addi	a0,a0,1164 # 80010bb8 <wait_lock>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	556080e7          	jalr	1366(ra) # 80000c8a <release>
          return pid;
    8000273c:	a09d                	j	800027a2 <waitx+0x120>
            release(&np->lock);
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	54a080e7          	jalr	1354(ra) # 80000c8a <release>
            release(&wait_lock);
    80002748:	0000e517          	auipc	a0,0xe
    8000274c:	47050513          	addi	a0,a0,1136 # 80010bb8 <wait_lock>
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	53a080e7          	jalr	1338(ra) # 80000c8a <release>
            return -1;
    80002758:	59fd                	li	s3,-1
    8000275a:	a0a1                	j	800027a2 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    8000275c:	1a048493          	addi	s1,s1,416
    80002760:	03348463          	beq	s1,s3,80002788 <waitx+0x106>
      if (np->parent == p)
    80002764:	7c9c                	ld	a5,56(s1)
    80002766:	ff279be3          	bne	a5,s2,8000275c <waitx+0xda>
        acquire(&np->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	46a080e7          	jalr	1130(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002774:	4c9c                	lw	a5,24(s1)
    80002776:	f74785e3          	beq	a5,s4,800026e0 <waitx+0x5e>
        release(&np->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	50e080e7          	jalr	1294(ra) # 80000c8a <release>
        havekids = 1;
    80002784:	8756                	mv	a4,s5
    80002786:	bfd9                	j	8000275c <waitx+0xda>
    if (!havekids || p->killed)
    80002788:	c701                	beqz	a4,80002790 <waitx+0x10e>
    8000278a:	02892783          	lw	a5,40(s2)
    8000278e:	cb8d                	beqz	a5,800027c0 <waitx+0x13e>
      release(&wait_lock);
    80002790:	0000e517          	auipc	a0,0xe
    80002794:	42850513          	addi	a0,a0,1064 # 80010bb8 <wait_lock>
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	4f2080e7          	jalr	1266(ra) # 80000c8a <release>
      return -1;
    800027a0:	59fd                	li	s3,-1
  }
}
    800027a2:	854e                	mv	a0,s3
    800027a4:	60e6                	ld	ra,88(sp)
    800027a6:	6446                	ld	s0,80(sp)
    800027a8:	64a6                	ld	s1,72(sp)
    800027aa:	6906                	ld	s2,64(sp)
    800027ac:	79e2                	ld	s3,56(sp)
    800027ae:	7a42                	ld	s4,48(sp)
    800027b0:	7aa2                	ld	s5,40(sp)
    800027b2:	7b02                	ld	s6,32(sp)
    800027b4:	6be2                	ld	s7,24(sp)
    800027b6:	6c42                	ld	s8,16(sp)
    800027b8:	6ca2                	ld	s9,8(sp)
    800027ba:	6d02                	ld	s10,0(sp)
    800027bc:	6125                	addi	sp,sp,96
    800027be:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027c0:	85ea                	mv	a1,s10
    800027c2:	854a                	mv	a0,s2
    800027c4:	00000097          	auipc	ra,0x0
    800027c8:	94e080e7          	jalr	-1714(ra) # 80002112 <sleep>
    havekids = 0;
    800027cc:	b721                	j	800026d4 <waitx+0x52>

00000000800027ce <update_time>:

void update_time()
{
    800027ce:	7179                	addi	sp,sp,-48
    800027d0:	f406                	sd	ra,40(sp)
    800027d2:	f022                	sd	s0,32(sp)
    800027d4:	ec26                	sd	s1,24(sp)
    800027d6:	e84a                	sd	s2,16(sp)
    800027d8:	e44e                	sd	s3,8(sp)
    800027da:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800027dc:	0000e497          	auipc	s1,0xe
    800027e0:	7f448493          	addi	s1,s1,2036 # 80010fd0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800027e4:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800027e6:	00015917          	auipc	s2,0x15
    800027ea:	fea90913          	addi	s2,s2,-22 # 800177d0 <tickslock>
    800027ee:	a811                	j	80002802 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800027f0:	8526                	mv	a0,s1
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	498080e7          	jalr	1176(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027fa:	1a048493          	addi	s1,s1,416
    800027fe:	03248063          	beq	s1,s2,8000281e <update_time+0x50>
    acquire(&p->lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	3d2080e7          	jalr	978(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000280c:	4c9c                	lw	a5,24(s1)
    8000280e:	ff3791e3          	bne	a5,s3,800027f0 <update_time+0x22>
      p->rtime++;
    80002812:	1684a783          	lw	a5,360(s1)
    80002816:	2785                	addiw	a5,a5,1
    80002818:	16f4a423          	sw	a5,360(s1)
    8000281c:	bfd1                	j	800027f0 <update_time+0x22>
  }
}
    8000281e:	70a2                	ld	ra,40(sp)
    80002820:	7402                	ld	s0,32(sp)
    80002822:	64e2                	ld	s1,24(sp)
    80002824:	6942                	ld	s2,16(sp)
    80002826:	69a2                	ld	s3,8(sp)
    80002828:	6145                	addi	sp,sp,48
    8000282a:	8082                	ret

000000008000282c <InitQueue>:

Queue InitQueue()
{
    8000282c:	7179                	addi	sp,sp,-48
    8000282e:	f422                	sd	s0,40(sp)
    80002830:	1800                	addi	s0,sp,48
    80002832:	04000793          	li	a5,64
  que.front = -1;
  que.rear = -1;
  que.size = NPROC;
  struct proc* arr[NPROC];
  que.arr = arr;
  for(int i = 0; i < NPROC; i++)
    80002836:	37fd                	addiw	a5,a5,-1
    80002838:	fffd                	bnez	a5,80002836 <InitQueue+0xa>
  }

  Queue q = &que;

  return q;
}
    8000283a:	fd840513          	addi	a0,s0,-40
    8000283e:	7422                	ld	s0,40(sp)
    80002840:	6145                	addi	sp,sp,48
    80002842:	8082                	ret

0000000080002844 <IsEmpty>:

int IsEmpty(Queue q)
{
    80002844:	1141                	addi	sp,sp,-16
    80002846:	e422                	sd	s0,8(sp)
    80002848:	0800                	addi	s0,sp,16
  return q->front == -1;
    8000284a:	4108                	lw	a0,0(a0)
    8000284c:	0505                	addi	a0,a0,1
}
    8000284e:	00153513          	seqz	a0,a0
    80002852:	6422                	ld	s0,8(sp)
    80002854:	0141                	addi	sp,sp,16
    80002856:	8082                	ret

0000000080002858 <IsFull>:

int IsFull(Queue q)
{
    80002858:	1141                	addi	sp,sp,-16
    8000285a:	e422                	sd	s0,8(sp)
    8000285c:	0800                	addi	s0,sp,16
  return (q->rear + 1) % q->size == q->front;
    8000285e:	415c                	lw	a5,4(a0)
    80002860:	2785                	addiw	a5,a5,1
    80002862:	4518                	lw	a4,8(a0)
    80002864:	02e7e7bb          	remw	a5,a5,a4
    80002868:	4118                	lw	a4,0(a0)
    8000286a:	40e78533          	sub	a0,a5,a4
}
    8000286e:	00153513          	seqz	a0,a0
    80002872:	6422                	ld	s0,8(sp)
    80002874:	0141                	addi	sp,sp,16
    80002876:	8082                	ret

0000000080002878 <Enqueue>:


void Enqueue(Queue q, struct proc* pro) 
{
    80002878:	1101                	addi	sp,sp,-32
    8000287a:	ec06                	sd	ra,24(sp)
    8000287c:	e822                	sd	s0,16(sp)
    8000287e:	e426                	sd	s1,8(sp)
    80002880:	e04a                	sd	s2,0(sp)
    80002882:	1000                	addi	s0,sp,32
    80002884:	84aa                	mv	s1,a0
    80002886:	892e                	mv	s2,a1
  if (IsFull(q) || ((q->front == 0) && (q->rear == q->size-1)))
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	fd0080e7          	jalr	-48(ra) # 80002858 <IsFull>
    80002890:	ed01                	bnez	a0,800028a8 <Enqueue+0x30>
    80002892:	409c                	lw	a5,0(s1)
    80002894:	e39d                	bnez	a5,800028ba <Enqueue+0x42>
    80002896:	449c                	lw	a5,8(s1)
    80002898:	40d8                	lw	a4,4(s1)
    8000289a:	37fd                	addiw	a5,a5,-1
    8000289c:	00f70663          	beq	a4,a5,800028a8 <Enqueue+0x30>
  if (IsEmpty(q))
  {
    q->front = 0;
    q->rear = 0;
  }
  else if(q->rear == q->size-1 && q->front != 0)
    800028a0:	40dc                	lw	a5,4(s1)
  {
    q->rear = 0;
  }
  else
  {
    q->rear++;
    800028a2:	0017851b          	addiw	a0,a5,1
    800028a6:	a839                	j	800028c4 <Enqueue+0x4c>
    printf("Process queue is full\n");
    800028a8:	00006517          	auipc	a0,0x6
    800028ac:	9f050513          	addi	a0,a0,-1552 # 80008298 <digits+0x258>
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	cda080e7          	jalr	-806(ra) # 8000058a <printf>
    return;
    800028b8:	a821                	j	800028d0 <Enqueue+0x58>
  if (IsEmpty(q))
    800028ba:	577d                	li	a4,-1
    800028bc:	02e79063          	bne	a5,a4,800028dc <Enqueue+0x64>
    q->front = 0;
    800028c0:	0004a023          	sw	zero,0(s1)
    q->rear = 0;
    800028c4:	c0c8                	sw	a0,4(s1)
  }
  q->arr[q->rear] = pro;
    800028c6:	689c                	ld	a5,16(s1)
    800028c8:	050e                	slli	a0,a0,0x3
    800028ca:	97aa                	add	a5,a5,a0
    800028cc:	0127b023          	sd	s2,0(a5)
}
    800028d0:	60e2                	ld	ra,24(sp)
    800028d2:	6442                	ld	s0,16(sp)
    800028d4:	64a2                	ld	s1,8(sp)
    800028d6:	6902                	ld	s2,0(sp)
    800028d8:	6105                	addi	sp,sp,32
    800028da:	8082                	ret
  else if(q->rear == q->size-1 && q->front != 0)
    800028dc:	40dc                	lw	a5,4(s1)
    800028de:	4498                	lw	a4,8(s1)
    800028e0:	377d                	addiw	a4,a4,-1
    800028e2:	fef701e3          	beq	a4,a5,800028c4 <Enqueue+0x4c>
    800028e6:	bf75                	j	800028a2 <Enqueue+0x2a>

00000000800028e8 <Dequeue>:
  return q->front == -1;
    800028e8:	4118                	lw	a4,0(a0)

struct proc* Dequeue(Queue q)
{
  struct proc * ret;

  if (IsEmpty(q))
    800028ea:	56fd                	li	a3,-1
    800028ec:	02d70163          	beq	a4,a3,8000290e <Dequeue+0x26>
    800028f0:	87aa                	mv	a5,a0
  {
    printf("Process queue is empty\n");
    return 0;
  }
  if (q->front == q->rear)
    800028f2:	4154                	lw	a3,4(a0)
    800028f4:	02e68e63          	beq	a3,a4,80002930 <Dequeue+0x48>
    q->rear = -1;
      
  }
  else
  {
    ret = q->arr[q->front];
    800028f8:	6914                	ld	a3,16(a0)
    800028fa:	00371613          	slli	a2,a4,0x3
    800028fe:	96b2                	add	a3,a3,a2
    80002900:	6288                	ld	a0,0(a3)
    q->front = (q->front + 1) % q->size;
    80002902:	2705                	addiw	a4,a4,1
    80002904:	4794                	lw	a3,8(a5)
    80002906:	02d7673b          	remw	a4,a4,a3
    8000290a:	c398                	sw	a4,0(a5)
  }
  return ret;
}
    8000290c:	8082                	ret
{
    8000290e:	1141                	addi	sp,sp,-16
    80002910:	e406                	sd	ra,8(sp)
    80002912:	e022                	sd	s0,0(sp)
    80002914:	0800                	addi	s0,sp,16
    printf("Process queue is empty\n");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	99a50513          	addi	a0,a0,-1638 # 800082b0 <digits+0x270>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c6c080e7          	jalr	-916(ra) # 8000058a <printf>
    return 0;
    80002926:	4501                	li	a0,0
}
    80002928:	60a2                	ld	ra,8(sp)
    8000292a:	6402                	ld	s0,0(sp)
    8000292c:	0141                	addi	sp,sp,16
    8000292e:	8082                	ret
    ret = q->arr[q->front];
    80002930:	6914                	ld	a3,16(a0)
    80002932:	070e                	slli	a4,a4,0x3
    80002934:	9736                	add	a4,a4,a3
    80002936:	6308                	ld	a0,0(a4)
    q->front = -1;
    80002938:	577d                	li	a4,-1
    8000293a:	c398                	sw	a4,0(a5)
    q->rear = -1;
    8000293c:	c3d8                	sw	a4,4(a5)
    8000293e:	8082                	ret

0000000080002940 <DeqyuElement>:

struct proc* DeqyuElement(Queue q, struct proc* pro)
{
    80002940:	7179                	addi	sp,sp,-48
    80002942:	f406                	sd	ra,40(sp)
    80002944:	f022                	sd	s0,32(sp)
    80002946:	ec26                	sd	s1,24(sp)
    80002948:	e84a                	sd	s2,16(sp)
    8000294a:	e44e                	sd	s3,8(sp)
    8000294c:	1800                	addi	s0,sp,48
    8000294e:	84aa                	mv	s1,a0
  struct proc * ret;
  struct proc* deq;
  
  int oldfront = q->front;
    80002950:	00052983          	lw	s3,0(a0)

  int curindex = 0;
  while(q->arr[curindex] != pro)
    80002954:	691c                	ld	a5,16(a0)
    80002956:	6398                	ld	a4,0(a5)
    80002958:	06e58963          	beq	a1,a4,800029ca <DeqyuElement+0x8a>
    8000295c:	07a1                	addi	a5,a5,8
  int curindex = 0;
    8000295e:	4901                	li	s2,0
  {
    curindex++;
    80002960:	2905                	addiw	s2,s2,1
  while(q->arr[curindex] != pro)
    80002962:	07a1                	addi	a5,a5,8
    80002964:	ff87b703          	ld	a4,-8(a5)
    80002968:	feb71ce3          	bne	a4,a1,80002960 <DeqyuElement+0x20>
  }

  while(q->front != curindex)
    8000296c:	03298063          	beq	s3,s2,8000298c <DeqyuElement+0x4c>
  //while(q->front != curindex)
  {
    deq = Dequeue(q);
    80002970:	8526                	mv	a0,s1
    80002972:	00000097          	auipc	ra,0x0
    80002976:	f76080e7          	jalr	-138(ra) # 800028e8 <Dequeue>
    8000297a:	85aa                	mv	a1,a0
    Enqueue(q, deq);
    8000297c:	8526                	mv	a0,s1
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	efa080e7          	jalr	-262(ra) # 80002878 <Enqueue>
  while(q->front != curindex)
    80002986:	409c                	lw	a5,0(s1)
    80002988:	ff2794e3          	bne	a5,s2,80002970 <DeqyuElement+0x30>
  }
  ret = Dequeue(q);
    8000298c:	8526                	mv	a0,s1
    8000298e:	00000097          	auipc	ra,0x0
    80002992:	f5a080e7          	jalr	-166(ra) # 800028e8 <Dequeue>
    80002996:	892a                	mv	s2,a0
  //while(!IsEmpty(q) && q->front != oldfront)
  while(q->front != oldfront)
    80002998:	409c                	lw	a5,0(s1)
    8000299a:	03378063          	beq	a5,s3,800029ba <DeqyuElement+0x7a>
  {
    deq = Dequeue(q);
    8000299e:	8526                	mv	a0,s1
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	f48080e7          	jalr	-184(ra) # 800028e8 <Dequeue>
    800029a8:	85aa                	mv	a1,a0
    Enqueue(q, deq);
    800029aa:	8526                	mv	a0,s1
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	ecc080e7          	jalr	-308(ra) # 80002878 <Enqueue>
  while(q->front != oldfront)
    800029b4:	409c                	lw	a5,0(s1)
    800029b6:	ff3794e3          	bne	a5,s3,8000299e <DeqyuElement+0x5e>
  }
  return ret;
    800029ba:	854a                	mv	a0,s2
    800029bc:	70a2                	ld	ra,40(sp)
    800029be:	7402                	ld	s0,32(sp)
    800029c0:	64e2                	ld	s1,24(sp)
    800029c2:	6942                	ld	s2,16(sp)
    800029c4:	69a2                	ld	s3,8(sp)
    800029c6:	6145                	addi	sp,sp,48
    800029c8:	8082                	ret
  int curindex = 0;
    800029ca:	4901                	li	s2,0
    800029cc:	b745                	j	8000296c <DeqyuElement+0x2c>

00000000800029ce <swtch>:
    800029ce:	00153023          	sd	ra,0(a0)
    800029d2:	00253423          	sd	sp,8(a0)
    800029d6:	e900                	sd	s0,16(a0)
    800029d8:	ed04                	sd	s1,24(a0)
    800029da:	03253023          	sd	s2,32(a0)
    800029de:	03353423          	sd	s3,40(a0)
    800029e2:	03453823          	sd	s4,48(a0)
    800029e6:	03553c23          	sd	s5,56(a0)
    800029ea:	05653023          	sd	s6,64(a0)
    800029ee:	05753423          	sd	s7,72(a0)
    800029f2:	05853823          	sd	s8,80(a0)
    800029f6:	05953c23          	sd	s9,88(a0)
    800029fa:	07a53023          	sd	s10,96(a0)
    800029fe:	07b53423          	sd	s11,104(a0)
    80002a02:	0005b083          	ld	ra,0(a1)
    80002a06:	0085b103          	ld	sp,8(a1)
    80002a0a:	6980                	ld	s0,16(a1)
    80002a0c:	6d84                	ld	s1,24(a1)
    80002a0e:	0205b903          	ld	s2,32(a1)
    80002a12:	0285b983          	ld	s3,40(a1)
    80002a16:	0305ba03          	ld	s4,48(a1)
    80002a1a:	0385ba83          	ld	s5,56(a1)
    80002a1e:	0405bb03          	ld	s6,64(a1)
    80002a22:	0485bb83          	ld	s7,72(a1)
    80002a26:	0505bc03          	ld	s8,80(a1)
    80002a2a:	0585bc83          	ld	s9,88(a1)
    80002a2e:	0605bd03          	ld	s10,96(a1)
    80002a32:	0685bd83          	ld	s11,104(a1)
    80002a36:	8082                	ret

0000000080002a38 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a38:	1141                	addi	sp,sp,-16
    80002a3a:	e406                	sd	ra,8(sp)
    80002a3c:	e022                	sd	s0,0(sp)
    80002a3e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a40:	00006597          	auipc	a1,0x6
    80002a44:	8e858593          	addi	a1,a1,-1816 # 80008328 <states.0+0x30>
    80002a48:	00015517          	auipc	a0,0x15
    80002a4c:	d8850513          	addi	a0,a0,-632 # 800177d0 <tickslock>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	0f6080e7          	jalr	246(ra) # 80000b46 <initlock>
}
    80002a58:	60a2                	ld	ra,8(sp)
    80002a5a:	6402                	ld	s0,0(sp)
    80002a5c:	0141                	addi	sp,sp,16
    80002a5e:	8082                	ret

0000000080002a60 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002a60:	1141                	addi	sp,sp,-16
    80002a62:	e422                	sd	s0,8(sp)
    80002a64:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a66:	00003797          	auipc	a5,0x3
    80002a6a:	6ca78793          	addi	a5,a5,1738 # 80006130 <kernelvec>
    80002a6e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a72:	6422                	ld	s0,8(sp)
    80002a74:	0141                	addi	sp,sp,16
    80002a76:	8082                	ret

0000000080002a78 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a78:	1141                	addi	sp,sp,-16
    80002a7a:	e406                	sd	ra,8(sp)
    80002a7c:	e022                	sd	s0,0(sp)
    80002a7e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	f2c080e7          	jalr	-212(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a92:	00004697          	auipc	a3,0x4
    80002a96:	56e68693          	addi	a3,a3,1390 # 80007000 <_trampoline>
    80002a9a:	00004717          	auipc	a4,0x4
    80002a9e:	56670713          	addi	a4,a4,1382 # 80007000 <_trampoline>
    80002aa2:	8f15                	sub	a4,a4,a3
    80002aa4:	040007b7          	lui	a5,0x4000
    80002aa8:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002aaa:	07b2                	slli	a5,a5,0xc
    80002aac:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aae:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ab2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ab4:	18002673          	csrr	a2,satp
    80002ab8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aba:	6d30                	ld	a2,88(a0)
    80002abc:	6138                	ld	a4,64(a0)
    80002abe:	6585                	lui	a1,0x1
    80002ac0:	972e                	add	a4,a4,a1
    80002ac2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ac4:	6d38                	ld	a4,88(a0)
    80002ac6:	00000617          	auipc	a2,0x0
    80002aca:	13e60613          	addi	a2,a2,318 # 80002c04 <usertrap>
    80002ace:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ad0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ad2:	8612                	mv	a2,tp
    80002ad4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ada:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ade:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ae6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae8:	6f18                	ld	a4,24(a4)
    80002aea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aee:	6928                	ld	a0,80(a0)
    80002af0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002af2:	00004717          	auipc	a4,0x4
    80002af6:	5aa70713          	addi	a4,a4,1450 # 8000709c <userret>
    80002afa:	8f15                	sub	a4,a4,a3
    80002afc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002afe:	577d                	li	a4,-1
    80002b00:	177e                	slli	a4,a4,0x3f
    80002b02:	8d59                	or	a0,a0,a4
    80002b04:	9782                	jalr	a5
}
    80002b06:	60a2                	ld	ra,8(sp)
    80002b08:	6402                	ld	s0,0(sp)
    80002b0a:	0141                	addi	sp,sp,16
    80002b0c:	8082                	ret

0000000080002b0e <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	e426                	sd	s1,8(sp)
    80002b16:	e04a                	sd	s2,0(sp)
    80002b18:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b1a:	00015917          	auipc	s2,0x15
    80002b1e:	cb690913          	addi	s2,s2,-842 # 800177d0 <tickslock>
    80002b22:	854a                	mv	a0,s2
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	0b2080e7          	jalr	178(ra) # 80000bd6 <acquire>
  ticks++;
    80002b2c:	00006497          	auipc	s1,0x6
    80002b30:	e0448493          	addi	s1,s1,-508 # 80008930 <ticks>
    80002b34:	409c                	lw	a5,0(s1)
    80002b36:	2785                	addiw	a5,a5,1
    80002b38:	c09c                	sw	a5,0(s1)
  update_time();
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	c94080e7          	jalr	-876(ra) # 800027ce <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002b42:	8526                	mv	a0,s1
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	632080e7          	jalr	1586(ra) # 80002176 <wakeup>
  release(&tickslock);
    80002b4c:	854a                	mv	a0,s2
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	13c080e7          	jalr	316(ra) # 80000c8a <release>
}
    80002b56:	60e2                	ld	ra,24(sp)
    80002b58:	6442                	ld	s0,16(sp)
    80002b5a:	64a2                	ld	s1,8(sp)
    80002b5c:	6902                	ld	s2,0(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b70:	00074d63          	bltz	a4,80002b8a <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b74:	57fd                	li	a5,-1
    80002b76:	17fe                	slli	a5,a5,0x3f
    80002b78:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002b7a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b7c:	06f70363          	beq	a4,a5,80002be2 <devintr+0x80>
  }
}
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	64a2                	ld	s1,8(sp)
    80002b86:	6105                	addi	sp,sp,32
    80002b88:	8082                	ret
      (scause & 0xff) == 9)
    80002b8a:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002b8e:	46a5                	li	a3,9
    80002b90:	fed792e3          	bne	a5,a3,80002b74 <devintr+0x12>
    int irq = plic_claim();
    80002b94:	00003097          	auipc	ra,0x3
    80002b98:	6a4080e7          	jalr	1700(ra) # 80006238 <plic_claim>
    80002b9c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002b9e:	47a9                	li	a5,10
    80002ba0:	02f50763          	beq	a0,a5,80002bce <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ba4:	4785                	li	a5,1
    80002ba6:	02f50963          	beq	a0,a5,80002bd8 <devintr+0x76>
    return 1;
    80002baa:	4505                	li	a0,1
    else if (irq)
    80002bac:	d8f1                	beqz	s1,80002b80 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bae:	85a6                	mv	a1,s1
    80002bb0:	00005517          	auipc	a0,0x5
    80002bb4:	78050513          	addi	a0,a0,1920 # 80008330 <states.0+0x38>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9d2080e7          	jalr	-1582(ra) # 8000058a <printf>
      plic_complete(irq);
    80002bc0:	8526                	mv	a0,s1
    80002bc2:	00003097          	auipc	ra,0x3
    80002bc6:	69a080e7          	jalr	1690(ra) # 8000625c <plic_complete>
    return 1;
    80002bca:	4505                	li	a0,1
    80002bcc:	bf55                	j	80002b80 <devintr+0x1e>
      uartintr();
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	dca080e7          	jalr	-566(ra) # 80000998 <uartintr>
    80002bd6:	b7ed                	j	80002bc0 <devintr+0x5e>
      virtio_disk_intr();
    80002bd8:	00004097          	auipc	ra,0x4
    80002bdc:	b4c080e7          	jalr	-1204(ra) # 80006724 <virtio_disk_intr>
    80002be0:	b7c5                	j	80002bc0 <devintr+0x5e>
    if (cpuid() == 0)
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	d9e080e7          	jalr	-610(ra) # 80001980 <cpuid>
    80002bea:	c901                	beqz	a0,80002bfa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bec:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bf2:	14479073          	csrw	sip,a5
    return 2;
    80002bf6:	4509                	li	a0,2
    80002bf8:	b761                	j	80002b80 <devintr+0x1e>
      clockintr();
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	f14080e7          	jalr	-236(ra) # 80002b0e <clockintr>
    80002c02:	b7ed                	j	80002bec <devintr+0x8a>

0000000080002c04 <usertrap>:
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	e04a                	sd	s2,0(sp)
    80002c0e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c10:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c14:	1007f793          	andi	a5,a5,256
    80002c18:	ebdd                	bnez	a5,80002cce <usertrap+0xca>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c1a:	00003797          	auipc	a5,0x3
    80002c1e:	51678793          	addi	a5,a5,1302 # 80006130 <kernelvec>
    80002c22:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d86080e7          	jalr	-634(ra) # 800019ac <myproc>
    80002c2e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c30:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c32:	14102773          	csrr	a4,sepc
    80002c36:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c38:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c3c:	47a1                	li	a5,8
    80002c3e:	0af70063          	beq	a4,a5,80002cde <usertrap+0xda>
  else if ((which_dev = devintr()) != 0)
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	f20080e7          	jalr	-224(ra) # 80002b62 <devintr>
    80002c4a:	892a                	mv	s2,a0
    80002c4c:	c17d                	beqz	a0,80002d32 <usertrap+0x12e>
    if((which_dev = devintr()) == 2 && p->alarm_flag == 0 && p->ticks != 0)
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	f14080e7          	jalr	-236(ra) # 80002b62 <devintr>
    80002c56:	892a                	mv	s2,a0
    80002c58:	4789                	li	a5,2
    80002c5a:	0af51663          	bne	a0,a5,80002d06 <usertrap+0x102>
    80002c5e:	1904a783          	lw	a5,400(s1)
    80002c62:	ebb1                	bnez	a5,80002cb6 <usertrap+0xb2>
    80002c64:	1804a783          	lw	a5,384(s1)
    80002c68:	c7b9                	beqz	a5,80002cb6 <usertrap+0xb2>
      p->currticks++;
    80002c6a:	1844a703          	lw	a4,388(s1)
    80002c6e:	2705                	addiw	a4,a4,1
    80002c70:	0007069b          	sext.w	a3,a4
    80002c74:	18e4a223          	sw	a4,388(s1)
      if(p->currticks >= p->ticks)
    80002c78:	02f6cf63          	blt	a3,a5,80002cb6 <usertrap+0xb2>
        *p->alarmtrpfrm = *p->trapframe;
    80002c7c:	6cb4                	ld	a3,88(s1)
    80002c7e:	87b6                	mv	a5,a3
    80002c80:	1884b703          	ld	a4,392(s1)
    80002c84:	12068693          	addi	a3,a3,288
    80002c88:	0007b803          	ld	a6,0(a5)
    80002c8c:	6788                	ld	a0,8(a5)
    80002c8e:	6b8c                	ld	a1,16(a5)
    80002c90:	6f90                	ld	a2,24(a5)
    80002c92:	01073023          	sd	a6,0(a4)
    80002c96:	e708                	sd	a0,8(a4)
    80002c98:	eb0c                	sd	a1,16(a4)
    80002c9a:	ef10                	sd	a2,24(a4)
    80002c9c:	02078793          	addi	a5,a5,32
    80002ca0:	02070713          	addi	a4,a4,32
    80002ca4:	fed792e3          	bne	a5,a3,80002c88 <usertrap+0x84>
        p->alarm_flag = 1;
    80002ca8:	4785                	li	a5,1
    80002caa:	18f4a823          	sw	a5,400(s1)
        p->trapframe->epc = p->handlerfn;
    80002cae:	6cbc                	ld	a5,88(s1)
    80002cb0:	1784b703          	ld	a4,376(s1)
    80002cb4:	ef98                	sd	a4,24(a5)
  if (killed(p))
    80002cb6:	8526                	mv	a0,s1
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	70e080e7          	jalr	1806(ra) # 800023c6 <killed>
    80002cc0:	cd55                	beqz	a0,80002d7c <usertrap+0x178>
    exit(-1);
    80002cc2:	557d                	li	a0,-1
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	582080e7          	jalr	1410(ra) # 80002246 <exit>
  if (which_dev == 2)
    80002ccc:	a845                	j	80002d7c <usertrap+0x178>
    panic("usertrap: not from user mode");
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	68250513          	addi	a0,a0,1666 # 80008350 <states.0+0x58>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	86a080e7          	jalr	-1942(ra) # 80000540 <panic>
    if (killed(p))
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	6e8080e7          	jalr	1768(ra) # 800023c6 <killed>
    80002ce6:	e121                	bnez	a0,80002d26 <usertrap+0x122>
    p->trapframe->epc += 4;
    80002ce8:	6cb8                	ld	a4,88(s1)
    80002cea:	6f1c                	ld	a5,24(a4)
    80002cec:	0791                	addi	a5,a5,4
    80002cee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cf4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf8:	10079073          	csrw	sstatus,a5
    syscall();
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	2d4080e7          	jalr	724(ra) # 80002fd0 <syscall>
  int which_dev = 0;
    80002d04:	4901                	li	s2,0
  if (killed(p))
    80002d06:	8526                	mv	a0,s1
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	6be080e7          	jalr	1726(ra) # 800023c6 <killed>
    80002d10:	ed31                	bnez	a0,80002d6c <usertrap+0x168>
  usertrapret();
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	d66080e7          	jalr	-666(ra) # 80002a78 <usertrapret>
}
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	64a2                	ld	s1,8(sp)
    80002d20:	6902                	ld	s2,0(sp)
    80002d22:	6105                	addi	sp,sp,32
    80002d24:	8082                	ret
      exit(-1);
    80002d26:	557d                	li	a0,-1
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	51e080e7          	jalr	1310(ra) # 80002246 <exit>
    80002d30:	bf65                	j	80002ce8 <usertrap+0xe4>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d32:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d36:	5890                	lw	a2,48(s1)
    80002d38:	00005517          	auipc	a0,0x5
    80002d3c:	63850513          	addi	a0,a0,1592 # 80008370 <states.0+0x78>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	84a080e7          	jalr	-1974(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d48:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d4c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d50:	00005517          	auipc	a0,0x5
    80002d54:	65050513          	addi	a0,a0,1616 # 800083a0 <states.0+0xa8>
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	832080e7          	jalr	-1998(ra) # 8000058a <printf>
    setkilled(p);
    80002d60:	8526                	mv	a0,s1
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	638080e7          	jalr	1592(ra) # 8000239a <setkilled>
    80002d6a:	bf71                	j	80002d06 <usertrap+0x102>
    exit(-1);
    80002d6c:	557d                	li	a0,-1
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	4d8080e7          	jalr	1240(ra) # 80002246 <exit>
  if (which_dev == 2)
    80002d76:	4789                	li	a5,2
    80002d78:	f8f91de3          	bne	s2,a5,80002d12 <usertrap+0x10e>
    yield();
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	35a080e7          	jalr	858(ra) # 800020d6 <yield>
    80002d84:	b779                	j	80002d12 <usertrap+0x10e>

0000000080002d86 <kerneltrap>:
{
    80002d86:	7179                	addi	sp,sp,-48
    80002d88:	f406                	sd	ra,40(sp)
    80002d8a:	f022                	sd	s0,32(sp)
    80002d8c:	ec26                	sd	s1,24(sp)
    80002d8e:	e84a                	sd	s2,16(sp)
    80002d90:	e44e                	sd	s3,8(sp)
    80002d92:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d94:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d98:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d9c:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002da0:	1004f793          	andi	a5,s1,256
    80002da4:	cb85                	beqz	a5,80002dd4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002daa:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002dac:	ef85                	bnez	a5,80002de4 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	db4080e7          	jalr	-588(ra) # 80002b62 <devintr>
    80002db6:	cd1d                	beqz	a0,80002df4 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002db8:	4789                	li	a5,2
    80002dba:	06f50a63          	beq	a0,a5,80002e2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dbe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc2:	10049073          	csrw	sstatus,s1
}
    80002dc6:	70a2                	ld	ra,40(sp)
    80002dc8:	7402                	ld	s0,32(sp)
    80002dca:	64e2                	ld	s1,24(sp)
    80002dcc:	6942                	ld	s2,16(sp)
    80002dce:	69a2                	ld	s3,8(sp)
    80002dd0:	6145                	addi	sp,sp,48
    80002dd2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002dd4:	00005517          	auipc	a0,0x5
    80002dd8:	5ec50513          	addi	a0,a0,1516 # 800083c0 <states.0+0xc8>
    80002ddc:	ffffd097          	auipc	ra,0xffffd
    80002de0:	764080e7          	jalr	1892(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002de4:	00005517          	auipc	a0,0x5
    80002de8:	60450513          	addi	a0,a0,1540 # 800083e8 <states.0+0xf0>
    80002dec:	ffffd097          	auipc	ra,0xffffd
    80002df0:	754080e7          	jalr	1876(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002df4:	85ce                	mv	a1,s3
    80002df6:	00005517          	auipc	a0,0x5
    80002dfa:	61250513          	addi	a0,a0,1554 # 80008408 <states.0+0x110>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	78c080e7          	jalr	1932(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	60a50513          	addi	a0,a0,1546 # 80008418 <states.0+0x120>
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	774080e7          	jalr	1908(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002e1e:	00005517          	auipc	a0,0x5
    80002e22:	61250513          	addi	a0,a0,1554 # 80008430 <states.0+0x138>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	71a080e7          	jalr	1818(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	b7e080e7          	jalr	-1154(ra) # 800019ac <myproc>
    80002e36:	d541                	beqz	a0,80002dbe <kerneltrap+0x38>
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	b74080e7          	jalr	-1164(ra) # 800019ac <myproc>
    80002e40:	4d18                	lw	a4,24(a0)
    80002e42:	4791                	li	a5,4
    80002e44:	f6f71de3          	bne	a4,a5,80002dbe <kerneltrap+0x38>
    yield();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	28e080e7          	jalr	654(ra) # 800020d6 <yield>
    80002e50:	b7bd                	j	80002dbe <kerneltrap+0x38>

0000000080002e52 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	e426                	sd	s1,8(sp)
    80002e5a:	1000                	addi	s0,sp,32
    80002e5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	b4e080e7          	jalr	-1202(ra) # 800019ac <myproc>
  switch (n) {
    80002e66:	4795                	li	a5,5
    80002e68:	0497e163          	bltu	a5,s1,80002eaa <argraw+0x58>
    80002e6c:	048a                	slli	s1,s1,0x2
    80002e6e:	00005717          	auipc	a4,0x5
    80002e72:	5fa70713          	addi	a4,a4,1530 # 80008468 <states.0+0x170>
    80002e76:	94ba                	add	s1,s1,a4
    80002e78:	409c                	lw	a5,0(s1)
    80002e7a:	97ba                	add	a5,a5,a4
    80002e7c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e7e:	6d3c                	ld	a5,88(a0)
    80002e80:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret
    return p->trapframe->a1;
    80002e8c:	6d3c                	ld	a5,88(a0)
    80002e8e:	7fa8                	ld	a0,120(a5)
    80002e90:	bfcd                	j	80002e82 <argraw+0x30>
    return p->trapframe->a2;
    80002e92:	6d3c                	ld	a5,88(a0)
    80002e94:	63c8                	ld	a0,128(a5)
    80002e96:	b7f5                	j	80002e82 <argraw+0x30>
    return p->trapframe->a3;
    80002e98:	6d3c                	ld	a5,88(a0)
    80002e9a:	67c8                	ld	a0,136(a5)
    80002e9c:	b7dd                	j	80002e82 <argraw+0x30>
    return p->trapframe->a4;
    80002e9e:	6d3c                	ld	a5,88(a0)
    80002ea0:	6bc8                	ld	a0,144(a5)
    80002ea2:	b7c5                	j	80002e82 <argraw+0x30>
    return p->trapframe->a5;
    80002ea4:	6d3c                	ld	a5,88(a0)
    80002ea6:	6fc8                	ld	a0,152(a5)
    80002ea8:	bfe9                	j	80002e82 <argraw+0x30>
  panic("argraw");
    80002eaa:	00005517          	auipc	a0,0x5
    80002eae:	59650513          	addi	a0,a0,1430 # 80008440 <states.0+0x148>
    80002eb2:	ffffd097          	auipc	ra,0xffffd
    80002eb6:	68e080e7          	jalr	1678(ra) # 80000540 <panic>

0000000080002eba <fetchaddr>:
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	e426                	sd	s1,8(sp)
    80002ec2:	e04a                	sd	s2,0(sp)
    80002ec4:	1000                	addi	s0,sp,32
    80002ec6:	84aa                	mv	s1,a0
    80002ec8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	ae2080e7          	jalr	-1310(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ed2:	653c                	ld	a5,72(a0)
    80002ed4:	02f4f863          	bgeu	s1,a5,80002f04 <fetchaddr+0x4a>
    80002ed8:	00848713          	addi	a4,s1,8
    80002edc:	02e7e663          	bltu	a5,a4,80002f08 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ee0:	46a1                	li	a3,8
    80002ee2:	8626                	mv	a2,s1
    80002ee4:	85ca                	mv	a1,s2
    80002ee6:	6928                	ld	a0,80(a0)
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	810080e7          	jalr	-2032(ra) # 800016f8 <copyin>
    80002ef0:	00a03533          	snez	a0,a0
    80002ef4:	40a00533          	neg	a0,a0
}
    80002ef8:	60e2                	ld	ra,24(sp)
    80002efa:	6442                	ld	s0,16(sp)
    80002efc:	64a2                	ld	s1,8(sp)
    80002efe:	6902                	ld	s2,0(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret
    return -1;
    80002f04:	557d                	li	a0,-1
    80002f06:	bfcd                	j	80002ef8 <fetchaddr+0x3e>
    80002f08:	557d                	li	a0,-1
    80002f0a:	b7fd                	j	80002ef8 <fetchaddr+0x3e>

0000000080002f0c <fetchstr>:
{
    80002f0c:	7179                	addi	sp,sp,-48
    80002f0e:	f406                	sd	ra,40(sp)
    80002f10:	f022                	sd	s0,32(sp)
    80002f12:	ec26                	sd	s1,24(sp)
    80002f14:	e84a                	sd	s2,16(sp)
    80002f16:	e44e                	sd	s3,8(sp)
    80002f18:	1800                	addi	s0,sp,48
    80002f1a:	892a                	mv	s2,a0
    80002f1c:	84ae                	mv	s1,a1
    80002f1e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	a8c080e7          	jalr	-1396(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f28:	86ce                	mv	a3,s3
    80002f2a:	864a                	mv	a2,s2
    80002f2c:	85a6                	mv	a1,s1
    80002f2e:	6928                	ld	a0,80(a0)
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	856080e7          	jalr	-1962(ra) # 80001786 <copyinstr>
    80002f38:	00054e63          	bltz	a0,80002f54 <fetchstr+0x48>
  return strlen(buf);
    80002f3c:	8526                	mv	a0,s1
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	f10080e7          	jalr	-240(ra) # 80000e4e <strlen>
}
    80002f46:	70a2                	ld	ra,40(sp)
    80002f48:	7402                	ld	s0,32(sp)
    80002f4a:	64e2                	ld	s1,24(sp)
    80002f4c:	6942                	ld	s2,16(sp)
    80002f4e:	69a2                	ld	s3,8(sp)
    80002f50:	6145                	addi	sp,sp,48
    80002f52:	8082                	ret
    return -1;
    80002f54:	557d                	li	a0,-1
    80002f56:	bfc5                	j	80002f46 <fetchstr+0x3a>

0000000080002f58 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	1000                	addi	s0,sp,32
    80002f62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	eee080e7          	jalr	-274(ra) # 80002e52 <argraw>
    80002f6c:	c088                	sw	a0,0(s1)
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	e426                	sd	s1,8(sp)
    80002f80:	1000                	addi	s0,sp,32
    80002f82:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	ece080e7          	jalr	-306(ra) # 80002e52 <argraw>
    80002f8c:	e088                	sd	a0,0(s1)
}
    80002f8e:	60e2                	ld	ra,24(sp)
    80002f90:	6442                	ld	s0,16(sp)
    80002f92:	64a2                	ld	s1,8(sp)
    80002f94:	6105                	addi	sp,sp,32
    80002f96:	8082                	ret

0000000080002f98 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f98:	7179                	addi	sp,sp,-48
    80002f9a:	f406                	sd	ra,40(sp)
    80002f9c:	f022                	sd	s0,32(sp)
    80002f9e:	ec26                	sd	s1,24(sp)
    80002fa0:	e84a                	sd	s2,16(sp)
    80002fa2:	1800                	addi	s0,sp,48
    80002fa4:	84ae                	mv	s1,a1
    80002fa6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002fa8:	fd840593          	addi	a1,s0,-40
    80002fac:	00000097          	auipc	ra,0x0
    80002fb0:	fcc080e7          	jalr	-52(ra) # 80002f78 <argaddr>
  return fetchstr(addr, buf, max);
    80002fb4:	864a                	mv	a2,s2
    80002fb6:	85a6                	mv	a1,s1
    80002fb8:	fd843503          	ld	a0,-40(s0)
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	f50080e7          	jalr	-176(ra) # 80002f0c <fetchstr>
}
    80002fc4:	70a2                	ld	ra,40(sp)
    80002fc6:	7402                	ld	s0,32(sp)
    80002fc8:	64e2                	ld	s1,24(sp)
    80002fca:	6942                	ld	s2,16(sp)
    80002fcc:	6145                	addi	sp,sp,48
    80002fce:	8082                	ret

0000000080002fd0 <syscall>:
[SYS_sigreturn] sys_sigreturn
};

void
syscall(void)
{
    80002fd0:	1101                	addi	sp,sp,-32
    80002fd2:	ec06                	sd	ra,24(sp)
    80002fd4:	e822                	sd	s0,16(sp)
    80002fd6:	e426                	sd	s1,8(sp)
    80002fd8:	e04a                	sd	s2,0(sp)
    80002fda:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	9d0080e7          	jalr	-1584(ra) # 800019ac <myproc>
    80002fe4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fe6:	05853903          	ld	s2,88(a0)
    80002fea:	0a893783          	ld	a5,168(s2)
    80002fee:	0007869b          	sext.w	a3,a5
  //num = * (int *) 0;

  if (num==SYS_read){
    80002ff2:	4715                	li	a4,5
    80002ff4:	02e68763          	beq	a3,a4,80003022 <syscall+0x52>
    readcount++;
  }

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ff8:	37fd                	addiw	a5,a5,-1
    80002ffa:	4761                	li	a4,24
    80002ffc:	04f76663          	bltu	a4,a5,80003048 <syscall+0x78>
    80003000:	00369713          	slli	a4,a3,0x3
    80003004:	00005797          	auipc	a5,0x5
    80003008:	47c78793          	addi	a5,a5,1148 # 80008480 <syscalls>
    8000300c:	97ba                	add	a5,a5,a4
    8000300e:	6398                	ld	a4,0(a5)
    80003010:	cf05                	beqz	a4,80003048 <syscall+0x78>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    if(num != 25)
    80003012:	47e5                	li	a5,25
    80003014:	02f69663          	bne	a3,a5,80003040 <syscall+0x70>
    {
      p->trapframe->a0 = syscalls[num]();
    }
    else
    {
      syscalls[num]();
    80003018:	00000097          	auipc	ra,0x0
    8000301c:	322080e7          	jalr	802(ra) # 8000333a <sys_sigreturn>
    80003020:	a091                	j	80003064 <syscall+0x94>
    readcount++;
    80003022:	00006617          	auipc	a2,0x6
    80003026:	91260613          	addi	a2,a2,-1774 # 80008934 <readcount>
    8000302a:	4218                	lw	a4,0(a2)
    8000302c:	2705                	addiw	a4,a4,1
    8000302e:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003030:	37fd                	addiw	a5,a5,-1
    80003032:	4661                	li	a2,24
    80003034:	00002717          	auipc	a4,0x2
    80003038:	74870713          	addi	a4,a4,1864 # 8000577c <sys_read>
    8000303c:	00f66663          	bltu	a2,a5,80003048 <syscall+0x78>
      p->trapframe->a0 = syscalls[num]();
    80003040:	9702                	jalr	a4
    80003042:	06a93823          	sd	a0,112(s2)
    80003046:	a839                	j	80003064 <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80003048:	15848613          	addi	a2,s1,344
    8000304c:	588c                	lw	a1,48(s1)
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	3fa50513          	addi	a0,a0,1018 # 80008448 <states.0+0x150>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	534080e7          	jalr	1332(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000305e:	6cbc                	ld	a5,88(s1)
    80003060:	577d                	li	a4,-1
    80003062:	fbb8                	sd	a4,112(a5)
  }
}
    80003064:	60e2                	ld	ra,24(sp)
    80003066:	6442                	ld	s0,16(sp)
    80003068:	64a2                	ld	s1,8(sp)
    8000306a:	6902                	ld	s2,0(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret

0000000080003070 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003070:	1101                	addi	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003078:	fec40593          	addi	a1,s0,-20
    8000307c:	4501                	li	a0,0
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	eda080e7          	jalr	-294(ra) # 80002f58 <argint>
  exit(n);
    80003086:	fec42503          	lw	a0,-20(s0)
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	1bc080e7          	jalr	444(ra) # 80002246 <exit>
  return 0; // not reached
}
    80003092:	4501                	li	a0,0
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000309c:	1141                	addi	sp,sp,-16
    8000309e:	e406                	sd	ra,8(sp)
    800030a0:	e022                	sd	s0,0(sp)
    800030a2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	908080e7          	jalr	-1784(ra) # 800019ac <myproc>
}
    800030ac:	5908                	lw	a0,48(a0)
    800030ae:	60a2                	ld	ra,8(sp)
    800030b0:	6402                	ld	s0,0(sp)
    800030b2:	0141                	addi	sp,sp,16
    800030b4:	8082                	ret

00000000800030b6 <sys_fork>:

uint64
sys_fork(void)
{
    800030b6:	1141                	addi	sp,sp,-16
    800030b8:	e406                	sd	ra,8(sp)
    800030ba:	e022                	sd	s0,0(sp)
    800030bc:	0800                	addi	s0,sp,16
  return fork();
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	d0a080e7          	jalr	-758(ra) # 80001dc8 <fork>
}
    800030c6:	60a2                	ld	ra,8(sp)
    800030c8:	6402                	ld	s0,0(sp)
    800030ca:	0141                	addi	sp,sp,16
    800030cc:	8082                	ret

00000000800030ce <sys_wait>:

uint64
sys_wait(void)
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800030d6:	fe840593          	addi	a1,s0,-24
    800030da:	4501                	li	a0,0
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	e9c080e7          	jalr	-356(ra) # 80002f78 <argaddr>
  return wait(p);
    800030e4:	fe843503          	ld	a0,-24(s0)
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	310080e7          	jalr	784(ra) # 800023f8 <wait>
}
    800030f0:	60e2                	ld	ra,24(sp)
    800030f2:	6442                	ld	s0,16(sp)
    800030f4:	6105                	addi	sp,sp,32
    800030f6:	8082                	ret

00000000800030f8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030f8:	7179                	addi	sp,sp,-48
    800030fa:	f406                	sd	ra,40(sp)
    800030fc:	f022                	sd	s0,32(sp)
    800030fe:	ec26                	sd	s1,24(sp)
    80003100:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003102:	fdc40593          	addi	a1,s0,-36
    80003106:	4501                	li	a0,0
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	e50080e7          	jalr	-432(ra) # 80002f58 <argint>
  addr = myproc()->sz;
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	89c080e7          	jalr	-1892(ra) # 800019ac <myproc>
    80003118:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000311a:	fdc42503          	lw	a0,-36(s0)
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	c4e080e7          	jalr	-946(ra) # 80001d6c <growproc>
    80003126:	00054863          	bltz	a0,80003136 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000312a:	8526                	mv	a0,s1
    8000312c:	70a2                	ld	ra,40(sp)
    8000312e:	7402                	ld	s0,32(sp)
    80003130:	64e2                	ld	s1,24(sp)
    80003132:	6145                	addi	sp,sp,48
    80003134:	8082                	ret
    return -1;
    80003136:	54fd                	li	s1,-1
    80003138:	bfcd                	j	8000312a <sys_sbrk+0x32>

000000008000313a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000313a:	7139                	addi	sp,sp,-64
    8000313c:	fc06                	sd	ra,56(sp)
    8000313e:	f822                	sd	s0,48(sp)
    80003140:	f426                	sd	s1,40(sp)
    80003142:	f04a                	sd	s2,32(sp)
    80003144:	ec4e                	sd	s3,24(sp)
    80003146:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003148:	fcc40593          	addi	a1,s0,-52
    8000314c:	4501                	li	a0,0
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	e0a080e7          	jalr	-502(ra) # 80002f58 <argint>
  acquire(&tickslock);
    80003156:	00014517          	auipc	a0,0x14
    8000315a:	67a50513          	addi	a0,a0,1658 # 800177d0 <tickslock>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	a78080e7          	jalr	-1416(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003166:	00005917          	auipc	s2,0x5
    8000316a:	7ca92903          	lw	s2,1994(s2) # 80008930 <ticks>
  while (ticks - ticks0 < n)
    8000316e:	fcc42783          	lw	a5,-52(s0)
    80003172:	cf9d                	beqz	a5,800031b0 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003174:	00014997          	auipc	s3,0x14
    80003178:	65c98993          	addi	s3,s3,1628 # 800177d0 <tickslock>
    8000317c:	00005497          	auipc	s1,0x5
    80003180:	7b448493          	addi	s1,s1,1972 # 80008930 <ticks>
    if (killed(myproc()))
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	828080e7          	jalr	-2008(ra) # 800019ac <myproc>
    8000318c:	fffff097          	auipc	ra,0xfffff
    80003190:	23a080e7          	jalr	570(ra) # 800023c6 <killed>
    80003194:	ed15                	bnez	a0,800031d0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003196:	85ce                	mv	a1,s3
    80003198:	8526                	mv	a0,s1
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	f78080e7          	jalr	-136(ra) # 80002112 <sleep>
  while (ticks - ticks0 < n)
    800031a2:	409c                	lw	a5,0(s1)
    800031a4:	412787bb          	subw	a5,a5,s2
    800031a8:	fcc42703          	lw	a4,-52(s0)
    800031ac:	fce7ece3          	bltu	a5,a4,80003184 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800031b0:	00014517          	auipc	a0,0x14
    800031b4:	62050513          	addi	a0,a0,1568 # 800177d0 <tickslock>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	ad2080e7          	jalr	-1326(ra) # 80000c8a <release>
  return 0;
    800031c0:	4501                	li	a0,0
}
    800031c2:	70e2                	ld	ra,56(sp)
    800031c4:	7442                	ld	s0,48(sp)
    800031c6:	74a2                	ld	s1,40(sp)
    800031c8:	7902                	ld	s2,32(sp)
    800031ca:	69e2                	ld	s3,24(sp)
    800031cc:	6121                	addi	sp,sp,64
    800031ce:	8082                	ret
      release(&tickslock);
    800031d0:	00014517          	auipc	a0,0x14
    800031d4:	60050513          	addi	a0,a0,1536 # 800177d0 <tickslock>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	ab2080e7          	jalr	-1358(ra) # 80000c8a <release>
      return -1;
    800031e0:	557d                	li	a0,-1
    800031e2:	b7c5                	j	800031c2 <sys_sleep+0x88>

00000000800031e4 <sys_kill>:

uint64
sys_kill(void)
{
    800031e4:	1101                	addi	sp,sp,-32
    800031e6:	ec06                	sd	ra,24(sp)
    800031e8:	e822                	sd	s0,16(sp)
    800031ea:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800031ec:	fec40593          	addi	a1,s0,-20
    800031f0:	4501                	li	a0,0
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	d66080e7          	jalr	-666(ra) # 80002f58 <argint>
  return kill(pid);
    800031fa:	fec42503          	lw	a0,-20(s0)
    800031fe:	fffff097          	auipc	ra,0xfffff
    80003202:	12a080e7          	jalr	298(ra) # 80002328 <kill>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret

000000008000320e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	5b850513          	addi	a0,a0,1464 # 800177d0 <tickslock>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	9b6080e7          	jalr	-1610(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003228:	00005497          	auipc	s1,0x5
    8000322c:	7084a483          	lw	s1,1800(s1) # 80008930 <ticks>
  release(&tickslock);
    80003230:	00014517          	auipc	a0,0x14
    80003234:	5a050513          	addi	a0,a0,1440 # 800177d0 <tickslock>
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	a52080e7          	jalr	-1454(ra) # 80000c8a <release>
  return xticks;
}
    80003240:	02049513          	slli	a0,s1,0x20
    80003244:	9101                	srli	a0,a0,0x20
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6105                	addi	sp,sp,32
    8000324e:	8082                	ret

0000000080003250 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003250:	7139                	addi	sp,sp,-64
    80003252:	fc06                	sd	ra,56(sp)
    80003254:	f822                	sd	s0,48(sp)
    80003256:	f426                	sd	s1,40(sp)
    80003258:	f04a                	sd	s2,32(sp)
    8000325a:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000325c:	fd840593          	addi	a1,s0,-40
    80003260:	4501                	li	a0,0
    80003262:	00000097          	auipc	ra,0x0
    80003266:	d16080e7          	jalr	-746(ra) # 80002f78 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000326a:	fd040593          	addi	a1,s0,-48
    8000326e:	4505                	li	a0,1
    80003270:	00000097          	auipc	ra,0x0
    80003274:	d08080e7          	jalr	-760(ra) # 80002f78 <argaddr>
  argaddr(2, &addr2);
    80003278:	fc840593          	addi	a1,s0,-56
    8000327c:	4509                	li	a0,2
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	cfa080e7          	jalr	-774(ra) # 80002f78 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003286:	fc040613          	addi	a2,s0,-64
    8000328a:	fc440593          	addi	a1,s0,-60
    8000328e:	fd843503          	ld	a0,-40(s0)
    80003292:	fffff097          	auipc	ra,0xfffff
    80003296:	3f0080e7          	jalr	1008(ra) # 80002682 <waitx>
    8000329a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	710080e7          	jalr	1808(ra) # 800019ac <myproc>
    800032a4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800032a6:	4691                	li	a3,4
    800032a8:	fc440613          	addi	a2,s0,-60
    800032ac:	fd043583          	ld	a1,-48(s0)
    800032b0:	6928                	ld	a0,80(a0)
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	3ba080e7          	jalr	954(ra) # 8000166c <copyout>
    return -1;
    800032ba:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800032bc:	00054f63          	bltz	a0,800032da <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800032c0:	4691                	li	a3,4
    800032c2:	fc040613          	addi	a2,s0,-64
    800032c6:	fc843583          	ld	a1,-56(s0)
    800032ca:	68a8                	ld	a0,80(s1)
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	3a0080e7          	jalr	928(ra) # 8000166c <copyout>
    800032d4:	00054a63          	bltz	a0,800032e8 <sys_waitx+0x98>
    return -1;
  return ret;
    800032d8:	87ca                	mv	a5,s2
}
    800032da:	853e                	mv	a0,a5
    800032dc:	70e2                	ld	ra,56(sp)
    800032de:	7442                	ld	s0,48(sp)
    800032e0:	74a2                	ld	s1,40(sp)
    800032e2:	7902                	ld	s2,32(sp)
    800032e4:	6121                	addi	sp,sp,64
    800032e6:	8082                	ret
    return -1;
    800032e8:	57fd                	li	a5,-1
    800032ea:	bfc5                	j	800032da <sys_waitx+0x8a>

00000000800032ec <sys_sigalarm>:

//alarm amd return
uint64
sys_sigalarm(void)
{
    800032ec:	1101                	addi	sp,sp,-32
    800032ee:	ec06                	sd	ra,24(sp)
    800032f0:	e822                	sd	s0,16(sp)
    800032f2:	1000                	addi	s0,sp,32
  uint64 handleraddr;
  int ticks;

  argint(0, &ticks);
    800032f4:	fe440593          	addi	a1,s0,-28
    800032f8:	4501                	li	a0,0
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	c5e080e7          	jalr	-930(ra) # 80002f58 <argint>
  argaddr(1, &handleraddr);
    80003302:	fe840593          	addi	a1,s0,-24
    80003306:	4505                	li	a0,1
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	c70080e7          	jalr	-912(ra) # 80002f78 <argaddr>

  myproc()->ticks = ticks;
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	69c080e7          	jalr	1692(ra) # 800019ac <myproc>
    80003318:	fe442783          	lw	a5,-28(s0)
    8000331c:	18f52023          	sw	a5,384(a0)
  myproc()->handlerfn = handleraddr;
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	68c080e7          	jalr	1676(ra) # 800019ac <myproc>
    80003328:	fe843783          	ld	a5,-24(s0)
    8000332c:	16f53c23          	sd	a5,376(a0)

  return 0;
}
    80003330:	4501                	li	a0,0
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    8000333a:	1141                	addi	sp,sp,-16
    8000333c:	e406                	sd	ra,8(sp)
    8000333e:	e022                	sd	s0,0(sp)
    80003340:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	66a080e7          	jalr	1642(ra) # 800019ac <myproc>
  
  *p->trapframe= *p->alarmtrpfrm;
    8000334a:	18853683          	ld	a3,392(a0)
    8000334e:	87b6                	mv	a5,a3
    80003350:	6d38                	ld	a4,88(a0)
    80003352:	12068693          	addi	a3,a3,288
    80003356:	0007b883          	ld	a7,0(a5)
    8000335a:	0087b803          	ld	a6,8(a5)
    8000335e:	6b8c                	ld	a1,16(a5)
    80003360:	6f90                	ld	a2,24(a5)
    80003362:	01173023          	sd	a7,0(a4)
    80003366:	01073423          	sd	a6,8(a4)
    8000336a:	eb0c                	sd	a1,16(a4)
    8000336c:	ef10                	sd	a2,24(a4)
    8000336e:	02078793          	addi	a5,a5,32
    80003372:	02070713          	addi	a4,a4,32
    80003376:	fed790e3          	bne	a5,a3,80003356 <sys_sigreturn+0x1c>

  p->alarm_flag = 0;
    8000337a:	18052823          	sw	zero,400(a0)
  p->currticks = 0;
    8000337e:	18052223          	sw	zero,388(a0)

  return 0;
    80003382:	4501                	li	a0,0
    80003384:	60a2                	ld	ra,8(sp)
    80003386:	6402                	ld	s0,0(sp)
    80003388:	0141                	addi	sp,sp,16
    8000338a:	8082                	ret

000000008000338c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000338c:	7179                	addi	sp,sp,-48
    8000338e:	f406                	sd	ra,40(sp)
    80003390:	f022                	sd	s0,32(sp)
    80003392:	ec26                	sd	s1,24(sp)
    80003394:	e84a                	sd	s2,16(sp)
    80003396:	e44e                	sd	s3,8(sp)
    80003398:	e052                	sd	s4,0(sp)
    8000339a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000339c:	00005597          	auipc	a1,0x5
    800033a0:	1b458593          	addi	a1,a1,436 # 80008550 <syscalls+0xd0>
    800033a4:	00014517          	auipc	a0,0x14
    800033a8:	44450513          	addi	a0,a0,1092 # 800177e8 <bcache>
    800033ac:	ffffd097          	auipc	ra,0xffffd
    800033b0:	79a080e7          	jalr	1946(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033b4:	0001c797          	auipc	a5,0x1c
    800033b8:	43478793          	addi	a5,a5,1076 # 8001f7e8 <bcache+0x8000>
    800033bc:	0001c717          	auipc	a4,0x1c
    800033c0:	69470713          	addi	a4,a4,1684 # 8001fa50 <bcache+0x8268>
    800033c4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033c8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033cc:	00014497          	auipc	s1,0x14
    800033d0:	43448493          	addi	s1,s1,1076 # 80017800 <bcache+0x18>
    b->next = bcache.head.next;
    800033d4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033d6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033d8:	00005a17          	auipc	s4,0x5
    800033dc:	180a0a13          	addi	s4,s4,384 # 80008558 <syscalls+0xd8>
    b->next = bcache.head.next;
    800033e0:	2b893783          	ld	a5,696(s2)
    800033e4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033e6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033ea:	85d2                	mv	a1,s4
    800033ec:	01048513          	addi	a0,s1,16
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	4c8080e7          	jalr	1224(ra) # 800048b8 <initsleeplock>
    bcache.head.next->prev = b;
    800033f8:	2b893783          	ld	a5,696(s2)
    800033fc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033fe:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003402:	45848493          	addi	s1,s1,1112
    80003406:	fd349de3          	bne	s1,s3,800033e0 <binit+0x54>
  }
}
    8000340a:	70a2                	ld	ra,40(sp)
    8000340c:	7402                	ld	s0,32(sp)
    8000340e:	64e2                	ld	s1,24(sp)
    80003410:	6942                	ld	s2,16(sp)
    80003412:	69a2                	ld	s3,8(sp)
    80003414:	6a02                	ld	s4,0(sp)
    80003416:	6145                	addi	sp,sp,48
    80003418:	8082                	ret

000000008000341a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000341a:	7179                	addi	sp,sp,-48
    8000341c:	f406                	sd	ra,40(sp)
    8000341e:	f022                	sd	s0,32(sp)
    80003420:	ec26                	sd	s1,24(sp)
    80003422:	e84a                	sd	s2,16(sp)
    80003424:	e44e                	sd	s3,8(sp)
    80003426:	1800                	addi	s0,sp,48
    80003428:	892a                	mv	s2,a0
    8000342a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000342c:	00014517          	auipc	a0,0x14
    80003430:	3bc50513          	addi	a0,a0,956 # 800177e8 <bcache>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	7a2080e7          	jalr	1954(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000343c:	0001c497          	auipc	s1,0x1c
    80003440:	6644b483          	ld	s1,1636(s1) # 8001faa0 <bcache+0x82b8>
    80003444:	0001c797          	auipc	a5,0x1c
    80003448:	60c78793          	addi	a5,a5,1548 # 8001fa50 <bcache+0x8268>
    8000344c:	02f48f63          	beq	s1,a5,8000348a <bread+0x70>
    80003450:	873e                	mv	a4,a5
    80003452:	a021                	j	8000345a <bread+0x40>
    80003454:	68a4                	ld	s1,80(s1)
    80003456:	02e48a63          	beq	s1,a4,8000348a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000345a:	449c                	lw	a5,8(s1)
    8000345c:	ff279ce3          	bne	a5,s2,80003454 <bread+0x3a>
    80003460:	44dc                	lw	a5,12(s1)
    80003462:	ff3799e3          	bne	a5,s3,80003454 <bread+0x3a>
      b->refcnt++;
    80003466:	40bc                	lw	a5,64(s1)
    80003468:	2785                	addiw	a5,a5,1
    8000346a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000346c:	00014517          	auipc	a0,0x14
    80003470:	37c50513          	addi	a0,a0,892 # 800177e8 <bcache>
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	816080e7          	jalr	-2026(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000347c:	01048513          	addi	a0,s1,16
    80003480:	00001097          	auipc	ra,0x1
    80003484:	472080e7          	jalr	1138(ra) # 800048f2 <acquiresleep>
      return b;
    80003488:	a8b9                	j	800034e6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000348a:	0001c497          	auipc	s1,0x1c
    8000348e:	60e4b483          	ld	s1,1550(s1) # 8001fa98 <bcache+0x82b0>
    80003492:	0001c797          	auipc	a5,0x1c
    80003496:	5be78793          	addi	a5,a5,1470 # 8001fa50 <bcache+0x8268>
    8000349a:	00f48863          	beq	s1,a5,800034aa <bread+0x90>
    8000349e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034a0:	40bc                	lw	a5,64(s1)
    800034a2:	cf81                	beqz	a5,800034ba <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034a4:	64a4                	ld	s1,72(s1)
    800034a6:	fee49de3          	bne	s1,a4,800034a0 <bread+0x86>
  panic("bget: no buffers");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	0b650513          	addi	a0,a0,182 # 80008560 <syscalls+0xe0>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	08e080e7          	jalr	142(ra) # 80000540 <panic>
      b->dev = dev;
    800034ba:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034be:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034c2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034c6:	4785                	li	a5,1
    800034c8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034ca:	00014517          	auipc	a0,0x14
    800034ce:	31e50513          	addi	a0,a0,798 # 800177e8 <bcache>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	7b8080e7          	jalr	1976(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034da:	01048513          	addi	a0,s1,16
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	414080e7          	jalr	1044(ra) # 800048f2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034e6:	409c                	lw	a5,0(s1)
    800034e8:	cb89                	beqz	a5,800034fa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034ea:	8526                	mv	a0,s1
    800034ec:	70a2                	ld	ra,40(sp)
    800034ee:	7402                	ld	s0,32(sp)
    800034f0:	64e2                	ld	s1,24(sp)
    800034f2:	6942                	ld	s2,16(sp)
    800034f4:	69a2                	ld	s3,8(sp)
    800034f6:	6145                	addi	sp,sp,48
    800034f8:	8082                	ret
    virtio_disk_rw(b, 0);
    800034fa:	4581                	li	a1,0
    800034fc:	8526                	mv	a0,s1
    800034fe:	00003097          	auipc	ra,0x3
    80003502:	ff4080e7          	jalr	-12(ra) # 800064f2 <virtio_disk_rw>
    b->valid = 1;
    80003506:	4785                	li	a5,1
    80003508:	c09c                	sw	a5,0(s1)
  return b;
    8000350a:	b7c5                	j	800034ea <bread+0xd0>

000000008000350c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	e426                	sd	s1,8(sp)
    80003514:	1000                	addi	s0,sp,32
    80003516:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003518:	0541                	addi	a0,a0,16
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	472080e7          	jalr	1138(ra) # 8000498c <holdingsleep>
    80003522:	cd01                	beqz	a0,8000353a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003524:	4585                	li	a1,1
    80003526:	8526                	mv	a0,s1
    80003528:	00003097          	auipc	ra,0x3
    8000352c:	fca080e7          	jalr	-54(ra) # 800064f2 <virtio_disk_rw>
}
    80003530:	60e2                	ld	ra,24(sp)
    80003532:	6442                	ld	s0,16(sp)
    80003534:	64a2                	ld	s1,8(sp)
    80003536:	6105                	addi	sp,sp,32
    80003538:	8082                	ret
    panic("bwrite");
    8000353a:	00005517          	auipc	a0,0x5
    8000353e:	03e50513          	addi	a0,a0,62 # 80008578 <syscalls+0xf8>
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	ffe080e7          	jalr	-2(ra) # 80000540 <panic>

000000008000354a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000354a:	1101                	addi	sp,sp,-32
    8000354c:	ec06                	sd	ra,24(sp)
    8000354e:	e822                	sd	s0,16(sp)
    80003550:	e426                	sd	s1,8(sp)
    80003552:	e04a                	sd	s2,0(sp)
    80003554:	1000                	addi	s0,sp,32
    80003556:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003558:	01050913          	addi	s2,a0,16
    8000355c:	854a                	mv	a0,s2
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	42e080e7          	jalr	1070(ra) # 8000498c <holdingsleep>
    80003566:	c92d                	beqz	a0,800035d8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003568:	854a                	mv	a0,s2
    8000356a:	00001097          	auipc	ra,0x1
    8000356e:	3de080e7          	jalr	990(ra) # 80004948 <releasesleep>

  acquire(&bcache.lock);
    80003572:	00014517          	auipc	a0,0x14
    80003576:	27650513          	addi	a0,a0,630 # 800177e8 <bcache>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	65c080e7          	jalr	1628(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003582:	40bc                	lw	a5,64(s1)
    80003584:	37fd                	addiw	a5,a5,-1
    80003586:	0007871b          	sext.w	a4,a5
    8000358a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000358c:	eb05                	bnez	a4,800035bc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000358e:	68bc                	ld	a5,80(s1)
    80003590:	64b8                	ld	a4,72(s1)
    80003592:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003594:	64bc                	ld	a5,72(s1)
    80003596:	68b8                	ld	a4,80(s1)
    80003598:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000359a:	0001c797          	auipc	a5,0x1c
    8000359e:	24e78793          	addi	a5,a5,590 # 8001f7e8 <bcache+0x8000>
    800035a2:	2b87b703          	ld	a4,696(a5)
    800035a6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035a8:	0001c717          	auipc	a4,0x1c
    800035ac:	4a870713          	addi	a4,a4,1192 # 8001fa50 <bcache+0x8268>
    800035b0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035b2:	2b87b703          	ld	a4,696(a5)
    800035b6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035b8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035bc:	00014517          	auipc	a0,0x14
    800035c0:	22c50513          	addi	a0,a0,556 # 800177e8 <bcache>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	6c6080e7          	jalr	1734(ra) # 80000c8a <release>
}
    800035cc:	60e2                	ld	ra,24(sp)
    800035ce:	6442                	ld	s0,16(sp)
    800035d0:	64a2                	ld	s1,8(sp)
    800035d2:	6902                	ld	s2,0(sp)
    800035d4:	6105                	addi	sp,sp,32
    800035d6:	8082                	ret
    panic("brelse");
    800035d8:	00005517          	auipc	a0,0x5
    800035dc:	fa850513          	addi	a0,a0,-88 # 80008580 <syscalls+0x100>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	f60080e7          	jalr	-160(ra) # 80000540 <panic>

00000000800035e8 <bpin>:

void
bpin(struct buf *b) {
    800035e8:	1101                	addi	sp,sp,-32
    800035ea:	ec06                	sd	ra,24(sp)
    800035ec:	e822                	sd	s0,16(sp)
    800035ee:	e426                	sd	s1,8(sp)
    800035f0:	1000                	addi	s0,sp,32
    800035f2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035f4:	00014517          	auipc	a0,0x14
    800035f8:	1f450513          	addi	a0,a0,500 # 800177e8 <bcache>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	5da080e7          	jalr	1498(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003604:	40bc                	lw	a5,64(s1)
    80003606:	2785                	addiw	a5,a5,1
    80003608:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000360a:	00014517          	auipc	a0,0x14
    8000360e:	1de50513          	addi	a0,a0,478 # 800177e8 <bcache>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	678080e7          	jalr	1656(ra) # 80000c8a <release>
}
    8000361a:	60e2                	ld	ra,24(sp)
    8000361c:	6442                	ld	s0,16(sp)
    8000361e:	64a2                	ld	s1,8(sp)
    80003620:	6105                	addi	sp,sp,32
    80003622:	8082                	ret

0000000080003624 <bunpin>:

void
bunpin(struct buf *b) {
    80003624:	1101                	addi	sp,sp,-32
    80003626:	ec06                	sd	ra,24(sp)
    80003628:	e822                	sd	s0,16(sp)
    8000362a:	e426                	sd	s1,8(sp)
    8000362c:	1000                	addi	s0,sp,32
    8000362e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003630:	00014517          	auipc	a0,0x14
    80003634:	1b850513          	addi	a0,a0,440 # 800177e8 <bcache>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	59e080e7          	jalr	1438(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	37fd                	addiw	a5,a5,-1
    80003644:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003646:	00014517          	auipc	a0,0x14
    8000364a:	1a250513          	addi	a0,a0,418 # 800177e8 <bcache>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	63c080e7          	jalr	1596(ra) # 80000c8a <release>
}
    80003656:	60e2                	ld	ra,24(sp)
    80003658:	6442                	ld	s0,16(sp)
    8000365a:	64a2                	ld	s1,8(sp)
    8000365c:	6105                	addi	sp,sp,32
    8000365e:	8082                	ret

0000000080003660 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003660:	1101                	addi	sp,sp,-32
    80003662:	ec06                	sd	ra,24(sp)
    80003664:	e822                	sd	s0,16(sp)
    80003666:	e426                	sd	s1,8(sp)
    80003668:	e04a                	sd	s2,0(sp)
    8000366a:	1000                	addi	s0,sp,32
    8000366c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000366e:	00d5d59b          	srliw	a1,a1,0xd
    80003672:	0001d797          	auipc	a5,0x1d
    80003676:	8527a783          	lw	a5,-1966(a5) # 8001fec4 <sb+0x1c>
    8000367a:	9dbd                	addw	a1,a1,a5
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	d9e080e7          	jalr	-610(ra) # 8000341a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003684:	0074f713          	andi	a4,s1,7
    80003688:	4785                	li	a5,1
    8000368a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000368e:	14ce                	slli	s1,s1,0x33
    80003690:	90d9                	srli	s1,s1,0x36
    80003692:	00950733          	add	a4,a0,s1
    80003696:	05874703          	lbu	a4,88(a4)
    8000369a:	00e7f6b3          	and	a3,a5,a4
    8000369e:	c69d                	beqz	a3,800036cc <bfree+0x6c>
    800036a0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036a2:	94aa                	add	s1,s1,a0
    800036a4:	fff7c793          	not	a5,a5
    800036a8:	8f7d                	and	a4,a4,a5
    800036aa:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	126080e7          	jalr	294(ra) # 800047d4 <log_write>
  brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	e92080e7          	jalr	-366(ra) # 8000354a <brelse>
}
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6902                	ld	s2,0(sp)
    800036c8:	6105                	addi	sp,sp,32
    800036ca:	8082                	ret
    panic("freeing free block");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	ebc50513          	addi	a0,a0,-324 # 80008588 <syscalls+0x108>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	e6c080e7          	jalr	-404(ra) # 80000540 <panic>

00000000800036dc <balloc>:
{
    800036dc:	711d                	addi	sp,sp,-96
    800036de:	ec86                	sd	ra,88(sp)
    800036e0:	e8a2                	sd	s0,80(sp)
    800036e2:	e4a6                	sd	s1,72(sp)
    800036e4:	e0ca                	sd	s2,64(sp)
    800036e6:	fc4e                	sd	s3,56(sp)
    800036e8:	f852                	sd	s4,48(sp)
    800036ea:	f456                	sd	s5,40(sp)
    800036ec:	f05a                	sd	s6,32(sp)
    800036ee:	ec5e                	sd	s7,24(sp)
    800036f0:	e862                	sd	s8,16(sp)
    800036f2:	e466                	sd	s9,8(sp)
    800036f4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036f6:	0001c797          	auipc	a5,0x1c
    800036fa:	7b67a783          	lw	a5,1974(a5) # 8001feac <sb+0x4>
    800036fe:	cff5                	beqz	a5,800037fa <balloc+0x11e>
    80003700:	8baa                	mv	s7,a0
    80003702:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003704:	0001cb17          	auipc	s6,0x1c
    80003708:	7a4b0b13          	addi	s6,s6,1956 # 8001fea8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000370c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000370e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003710:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003712:	6c89                	lui	s9,0x2
    80003714:	a061                	j	8000379c <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003716:	97ca                	add	a5,a5,s2
    80003718:	8e55                	or	a2,a2,a3
    8000371a:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000371e:	854a                	mv	a0,s2
    80003720:	00001097          	auipc	ra,0x1
    80003724:	0b4080e7          	jalr	180(ra) # 800047d4 <log_write>
        brelse(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	e20080e7          	jalr	-480(ra) # 8000354a <brelse>
  bp = bread(dev, bno);
    80003732:	85a6                	mv	a1,s1
    80003734:	855e                	mv	a0,s7
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	ce4080e7          	jalr	-796(ra) # 8000341a <bread>
    8000373e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003740:	40000613          	li	a2,1024
    80003744:	4581                	li	a1,0
    80003746:	05850513          	addi	a0,a0,88
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	588080e7          	jalr	1416(ra) # 80000cd2 <memset>
  log_write(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	080080e7          	jalr	128(ra) # 800047d4 <log_write>
  brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	dec080e7          	jalr	-532(ra) # 8000354a <brelse>
}
    80003766:	8526                	mv	a0,s1
    80003768:	60e6                	ld	ra,88(sp)
    8000376a:	6446                	ld	s0,80(sp)
    8000376c:	64a6                	ld	s1,72(sp)
    8000376e:	6906                	ld	s2,64(sp)
    80003770:	79e2                	ld	s3,56(sp)
    80003772:	7a42                	ld	s4,48(sp)
    80003774:	7aa2                	ld	s5,40(sp)
    80003776:	7b02                	ld	s6,32(sp)
    80003778:	6be2                	ld	s7,24(sp)
    8000377a:	6c42                	ld	s8,16(sp)
    8000377c:	6ca2                	ld	s9,8(sp)
    8000377e:	6125                	addi	sp,sp,96
    80003780:	8082                	ret
    brelse(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00000097          	auipc	ra,0x0
    80003788:	dc6080e7          	jalr	-570(ra) # 8000354a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000378c:	015c87bb          	addw	a5,s9,s5
    80003790:	00078a9b          	sext.w	s5,a5
    80003794:	004b2703          	lw	a4,4(s6)
    80003798:	06eaf163          	bgeu	s5,a4,800037fa <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000379c:	41fad79b          	sraiw	a5,s5,0x1f
    800037a0:	0137d79b          	srliw	a5,a5,0x13
    800037a4:	015787bb          	addw	a5,a5,s5
    800037a8:	40d7d79b          	sraiw	a5,a5,0xd
    800037ac:	01cb2583          	lw	a1,28(s6)
    800037b0:	9dbd                	addw	a1,a1,a5
    800037b2:	855e                	mv	a0,s7
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	c66080e7          	jalr	-922(ra) # 8000341a <bread>
    800037bc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037be:	004b2503          	lw	a0,4(s6)
    800037c2:	000a849b          	sext.w	s1,s5
    800037c6:	8762                	mv	a4,s8
    800037c8:	faa4fde3          	bgeu	s1,a0,80003782 <balloc+0xa6>
      m = 1 << (bi % 8);
    800037cc:	00777693          	andi	a3,a4,7
    800037d0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037d4:	41f7579b          	sraiw	a5,a4,0x1f
    800037d8:	01d7d79b          	srliw	a5,a5,0x1d
    800037dc:	9fb9                	addw	a5,a5,a4
    800037de:	4037d79b          	sraiw	a5,a5,0x3
    800037e2:	00f90633          	add	a2,s2,a5
    800037e6:	05864603          	lbu	a2,88(a2)
    800037ea:	00c6f5b3          	and	a1,a3,a2
    800037ee:	d585                	beqz	a1,80003716 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f0:	2705                	addiw	a4,a4,1
    800037f2:	2485                	addiw	s1,s1,1
    800037f4:	fd471ae3          	bne	a4,s4,800037c8 <balloc+0xec>
    800037f8:	b769                	j	80003782 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	da650513          	addi	a0,a0,-602 # 800085a0 <syscalls+0x120>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d88080e7          	jalr	-632(ra) # 8000058a <printf>
  return 0;
    8000380a:	4481                	li	s1,0
    8000380c:	bfa9                	j	80003766 <balloc+0x8a>

000000008000380e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000380e:	7179                	addi	sp,sp,-48
    80003810:	f406                	sd	ra,40(sp)
    80003812:	f022                	sd	s0,32(sp)
    80003814:	ec26                	sd	s1,24(sp)
    80003816:	e84a                	sd	s2,16(sp)
    80003818:	e44e                	sd	s3,8(sp)
    8000381a:	e052                	sd	s4,0(sp)
    8000381c:	1800                	addi	s0,sp,48
    8000381e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003820:	47ad                	li	a5,11
    80003822:	02b7e863          	bltu	a5,a1,80003852 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003826:	02059793          	slli	a5,a1,0x20
    8000382a:	01e7d593          	srli	a1,a5,0x1e
    8000382e:	00b504b3          	add	s1,a0,a1
    80003832:	0504a903          	lw	s2,80(s1)
    80003836:	06091e63          	bnez	s2,800038b2 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000383a:	4108                	lw	a0,0(a0)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	ea0080e7          	jalr	-352(ra) # 800036dc <balloc>
    80003844:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003848:	06090563          	beqz	s2,800038b2 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000384c:	0524a823          	sw	s2,80(s1)
    80003850:	a08d                	j	800038b2 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003852:	ff45849b          	addiw	s1,a1,-12
    80003856:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000385a:	0ff00793          	li	a5,255
    8000385e:	08e7e563          	bltu	a5,a4,800038e8 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003862:	08052903          	lw	s2,128(a0)
    80003866:	00091d63          	bnez	s2,80003880 <bmap+0x72>
      addr = balloc(ip->dev);
    8000386a:	4108                	lw	a0,0(a0)
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	e70080e7          	jalr	-400(ra) # 800036dc <balloc>
    80003874:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003878:	02090d63          	beqz	s2,800038b2 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000387c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003880:	85ca                	mv	a1,s2
    80003882:	0009a503          	lw	a0,0(s3)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	b94080e7          	jalr	-1132(ra) # 8000341a <bread>
    8000388e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003890:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003894:	02049713          	slli	a4,s1,0x20
    80003898:	01e75593          	srli	a1,a4,0x1e
    8000389c:	00b784b3          	add	s1,a5,a1
    800038a0:	0004a903          	lw	s2,0(s1)
    800038a4:	02090063          	beqz	s2,800038c4 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038a8:	8552                	mv	a0,s4
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	ca0080e7          	jalr	-864(ra) # 8000354a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038b2:	854a                	mv	a0,s2
    800038b4:	70a2                	ld	ra,40(sp)
    800038b6:	7402                	ld	s0,32(sp)
    800038b8:	64e2                	ld	s1,24(sp)
    800038ba:	6942                	ld	s2,16(sp)
    800038bc:	69a2                	ld	s3,8(sp)
    800038be:	6a02                	ld	s4,0(sp)
    800038c0:	6145                	addi	sp,sp,48
    800038c2:	8082                	ret
      addr = balloc(ip->dev);
    800038c4:	0009a503          	lw	a0,0(s3)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	e14080e7          	jalr	-492(ra) # 800036dc <balloc>
    800038d0:	0005091b          	sext.w	s2,a0
      if(addr){
    800038d4:	fc090ae3          	beqz	s2,800038a8 <bmap+0x9a>
        a[bn] = addr;
    800038d8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038dc:	8552                	mv	a0,s4
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	ef6080e7          	jalr	-266(ra) # 800047d4 <log_write>
    800038e6:	b7c9                	j	800038a8 <bmap+0x9a>
  panic("bmap: out of range");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	cd050513          	addi	a0,a0,-816 # 800085b8 <syscalls+0x138>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c50080e7          	jalr	-944(ra) # 80000540 <panic>

00000000800038f8 <iget>:
{
    800038f8:	7179                	addi	sp,sp,-48
    800038fa:	f406                	sd	ra,40(sp)
    800038fc:	f022                	sd	s0,32(sp)
    800038fe:	ec26                	sd	s1,24(sp)
    80003900:	e84a                	sd	s2,16(sp)
    80003902:	e44e                	sd	s3,8(sp)
    80003904:	e052                	sd	s4,0(sp)
    80003906:	1800                	addi	s0,sp,48
    80003908:	89aa                	mv	s3,a0
    8000390a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000390c:	0001c517          	auipc	a0,0x1c
    80003910:	5bc50513          	addi	a0,a0,1468 # 8001fec8 <itable>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	2c2080e7          	jalr	706(ra) # 80000bd6 <acquire>
  empty = 0;
    8000391c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000391e:	0001c497          	auipc	s1,0x1c
    80003922:	5c248493          	addi	s1,s1,1474 # 8001fee0 <itable+0x18>
    80003926:	0001e697          	auipc	a3,0x1e
    8000392a:	04a68693          	addi	a3,a3,74 # 80021970 <log>
    8000392e:	a039                	j	8000393c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003930:	02090b63          	beqz	s2,80003966 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003934:	08848493          	addi	s1,s1,136
    80003938:	02d48a63          	beq	s1,a3,8000396c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000393c:	449c                	lw	a5,8(s1)
    8000393e:	fef059e3          	blez	a5,80003930 <iget+0x38>
    80003942:	4098                	lw	a4,0(s1)
    80003944:	ff3716e3          	bne	a4,s3,80003930 <iget+0x38>
    80003948:	40d8                	lw	a4,4(s1)
    8000394a:	ff4713e3          	bne	a4,s4,80003930 <iget+0x38>
      ip->ref++;
    8000394e:	2785                	addiw	a5,a5,1
    80003950:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003952:	0001c517          	auipc	a0,0x1c
    80003956:	57650513          	addi	a0,a0,1398 # 8001fec8 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	330080e7          	jalr	816(ra) # 80000c8a <release>
      return ip;
    80003962:	8926                	mv	s2,s1
    80003964:	a03d                	j	80003992 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003966:	f7f9                	bnez	a5,80003934 <iget+0x3c>
    80003968:	8926                	mv	s2,s1
    8000396a:	b7e9                	j	80003934 <iget+0x3c>
  if(empty == 0)
    8000396c:	02090c63          	beqz	s2,800039a4 <iget+0xac>
  ip->dev = dev;
    80003970:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003974:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003978:	4785                	li	a5,1
    8000397a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000397e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003982:	0001c517          	auipc	a0,0x1c
    80003986:	54650513          	addi	a0,a0,1350 # 8001fec8 <itable>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	300080e7          	jalr	768(ra) # 80000c8a <release>
}
    80003992:	854a                	mv	a0,s2
    80003994:	70a2                	ld	ra,40(sp)
    80003996:	7402                	ld	s0,32(sp)
    80003998:	64e2                	ld	s1,24(sp)
    8000399a:	6942                	ld	s2,16(sp)
    8000399c:	69a2                	ld	s3,8(sp)
    8000399e:	6a02                	ld	s4,0(sp)
    800039a0:	6145                	addi	sp,sp,48
    800039a2:	8082                	ret
    panic("iget: no inodes");
    800039a4:	00005517          	auipc	a0,0x5
    800039a8:	c2c50513          	addi	a0,a0,-980 # 800085d0 <syscalls+0x150>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	b94080e7          	jalr	-1132(ra) # 80000540 <panic>

00000000800039b4 <fsinit>:
fsinit(int dev) {
    800039b4:	7179                	addi	sp,sp,-48
    800039b6:	f406                	sd	ra,40(sp)
    800039b8:	f022                	sd	s0,32(sp)
    800039ba:	ec26                	sd	s1,24(sp)
    800039bc:	e84a                	sd	s2,16(sp)
    800039be:	e44e                	sd	s3,8(sp)
    800039c0:	1800                	addi	s0,sp,48
    800039c2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039c4:	4585                	li	a1,1
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	a54080e7          	jalr	-1452(ra) # 8000341a <bread>
    800039ce:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039d0:	0001c997          	auipc	s3,0x1c
    800039d4:	4d898993          	addi	s3,s3,1240 # 8001fea8 <sb>
    800039d8:	02000613          	li	a2,32
    800039dc:	05850593          	addi	a1,a0,88
    800039e0:	854e                	mv	a0,s3
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	34c080e7          	jalr	844(ra) # 80000d2e <memmove>
  brelse(bp);
    800039ea:	8526                	mv	a0,s1
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	b5e080e7          	jalr	-1186(ra) # 8000354a <brelse>
  if(sb.magic != FSMAGIC)
    800039f4:	0009a703          	lw	a4,0(s3)
    800039f8:	102037b7          	lui	a5,0x10203
    800039fc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a00:	02f71263          	bne	a4,a5,80003a24 <fsinit+0x70>
  initlog(dev, &sb);
    80003a04:	0001c597          	auipc	a1,0x1c
    80003a08:	4a458593          	addi	a1,a1,1188 # 8001fea8 <sb>
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	00001097          	auipc	ra,0x1
    80003a12:	b4a080e7          	jalr	-1206(ra) # 80004558 <initlog>
}
    80003a16:	70a2                	ld	ra,40(sp)
    80003a18:	7402                	ld	s0,32(sp)
    80003a1a:	64e2                	ld	s1,24(sp)
    80003a1c:	6942                	ld	s2,16(sp)
    80003a1e:	69a2                	ld	s3,8(sp)
    80003a20:	6145                	addi	sp,sp,48
    80003a22:	8082                	ret
    panic("invalid file system");
    80003a24:	00005517          	auipc	a0,0x5
    80003a28:	bbc50513          	addi	a0,a0,-1092 # 800085e0 <syscalls+0x160>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	b14080e7          	jalr	-1260(ra) # 80000540 <panic>

0000000080003a34 <iinit>:
{
    80003a34:	7179                	addi	sp,sp,-48
    80003a36:	f406                	sd	ra,40(sp)
    80003a38:	f022                	sd	s0,32(sp)
    80003a3a:	ec26                	sd	s1,24(sp)
    80003a3c:	e84a                	sd	s2,16(sp)
    80003a3e:	e44e                	sd	s3,8(sp)
    80003a40:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a42:	00005597          	auipc	a1,0x5
    80003a46:	bb658593          	addi	a1,a1,-1098 # 800085f8 <syscalls+0x178>
    80003a4a:	0001c517          	auipc	a0,0x1c
    80003a4e:	47e50513          	addi	a0,a0,1150 # 8001fec8 <itable>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	0f4080e7          	jalr	244(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a5a:	0001c497          	auipc	s1,0x1c
    80003a5e:	49648493          	addi	s1,s1,1174 # 8001fef0 <itable+0x28>
    80003a62:	0001e997          	auipc	s3,0x1e
    80003a66:	f1e98993          	addi	s3,s3,-226 # 80021980 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a6a:	00005917          	auipc	s2,0x5
    80003a6e:	b9690913          	addi	s2,s2,-1130 # 80008600 <syscalls+0x180>
    80003a72:	85ca                	mv	a1,s2
    80003a74:	8526                	mv	a0,s1
    80003a76:	00001097          	auipc	ra,0x1
    80003a7a:	e42080e7          	jalr	-446(ra) # 800048b8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a7e:	08848493          	addi	s1,s1,136
    80003a82:	ff3498e3          	bne	s1,s3,80003a72 <iinit+0x3e>
}
    80003a86:	70a2                	ld	ra,40(sp)
    80003a88:	7402                	ld	s0,32(sp)
    80003a8a:	64e2                	ld	s1,24(sp)
    80003a8c:	6942                	ld	s2,16(sp)
    80003a8e:	69a2                	ld	s3,8(sp)
    80003a90:	6145                	addi	sp,sp,48
    80003a92:	8082                	ret

0000000080003a94 <ialloc>:
{
    80003a94:	715d                	addi	sp,sp,-80
    80003a96:	e486                	sd	ra,72(sp)
    80003a98:	e0a2                	sd	s0,64(sp)
    80003a9a:	fc26                	sd	s1,56(sp)
    80003a9c:	f84a                	sd	s2,48(sp)
    80003a9e:	f44e                	sd	s3,40(sp)
    80003aa0:	f052                	sd	s4,32(sp)
    80003aa2:	ec56                	sd	s5,24(sp)
    80003aa4:	e85a                	sd	s6,16(sp)
    80003aa6:	e45e                	sd	s7,8(sp)
    80003aa8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aaa:	0001c717          	auipc	a4,0x1c
    80003aae:	40a72703          	lw	a4,1034(a4) # 8001feb4 <sb+0xc>
    80003ab2:	4785                	li	a5,1
    80003ab4:	04e7fa63          	bgeu	a5,a4,80003b08 <ialloc+0x74>
    80003ab8:	8aaa                	mv	s5,a0
    80003aba:	8bae                	mv	s7,a1
    80003abc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003abe:	0001ca17          	auipc	s4,0x1c
    80003ac2:	3eaa0a13          	addi	s4,s4,1002 # 8001fea8 <sb>
    80003ac6:	00048b1b          	sext.w	s6,s1
    80003aca:	0044d593          	srli	a1,s1,0x4
    80003ace:	018a2783          	lw	a5,24(s4)
    80003ad2:	9dbd                	addw	a1,a1,a5
    80003ad4:	8556                	mv	a0,s5
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	944080e7          	jalr	-1724(ra) # 8000341a <bread>
    80003ade:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ae0:	05850993          	addi	s3,a0,88
    80003ae4:	00f4f793          	andi	a5,s1,15
    80003ae8:	079a                	slli	a5,a5,0x6
    80003aea:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aec:	00099783          	lh	a5,0(s3)
    80003af0:	c3a1                	beqz	a5,80003b30 <ialloc+0x9c>
    brelse(bp);
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	a58080e7          	jalr	-1448(ra) # 8000354a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003afa:	0485                	addi	s1,s1,1
    80003afc:	00ca2703          	lw	a4,12(s4)
    80003b00:	0004879b          	sext.w	a5,s1
    80003b04:	fce7e1e3          	bltu	a5,a4,80003ac6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b08:	00005517          	auipc	a0,0x5
    80003b0c:	b0050513          	addi	a0,a0,-1280 # 80008608 <syscalls+0x188>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	a7a080e7          	jalr	-1414(ra) # 8000058a <printf>
  return 0;
    80003b18:	4501                	li	a0,0
}
    80003b1a:	60a6                	ld	ra,72(sp)
    80003b1c:	6406                	ld	s0,64(sp)
    80003b1e:	74e2                	ld	s1,56(sp)
    80003b20:	7942                	ld	s2,48(sp)
    80003b22:	79a2                	ld	s3,40(sp)
    80003b24:	7a02                	ld	s4,32(sp)
    80003b26:	6ae2                	ld	s5,24(sp)
    80003b28:	6b42                	ld	s6,16(sp)
    80003b2a:	6ba2                	ld	s7,8(sp)
    80003b2c:	6161                	addi	sp,sp,80
    80003b2e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b30:	04000613          	li	a2,64
    80003b34:	4581                	li	a1,0
    80003b36:	854e                	mv	a0,s3
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	19a080e7          	jalr	410(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b40:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b44:	854a                	mv	a0,s2
    80003b46:	00001097          	auipc	ra,0x1
    80003b4a:	c8e080e7          	jalr	-882(ra) # 800047d4 <log_write>
      brelse(bp);
    80003b4e:	854a                	mv	a0,s2
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	9fa080e7          	jalr	-1542(ra) # 8000354a <brelse>
      return iget(dev, inum);
    80003b58:	85da                	mv	a1,s6
    80003b5a:	8556                	mv	a0,s5
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	d9c080e7          	jalr	-612(ra) # 800038f8 <iget>
    80003b64:	bf5d                	j	80003b1a <ialloc+0x86>

0000000080003b66 <iupdate>:
{
    80003b66:	1101                	addi	sp,sp,-32
    80003b68:	ec06                	sd	ra,24(sp)
    80003b6a:	e822                	sd	s0,16(sp)
    80003b6c:	e426                	sd	s1,8(sp)
    80003b6e:	e04a                	sd	s2,0(sp)
    80003b70:	1000                	addi	s0,sp,32
    80003b72:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b74:	415c                	lw	a5,4(a0)
    80003b76:	0047d79b          	srliw	a5,a5,0x4
    80003b7a:	0001c597          	auipc	a1,0x1c
    80003b7e:	3465a583          	lw	a1,838(a1) # 8001fec0 <sb+0x18>
    80003b82:	9dbd                	addw	a1,a1,a5
    80003b84:	4108                	lw	a0,0(a0)
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	894080e7          	jalr	-1900(ra) # 8000341a <bread>
    80003b8e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b90:	05850793          	addi	a5,a0,88
    80003b94:	40d8                	lw	a4,4(s1)
    80003b96:	8b3d                	andi	a4,a4,15
    80003b98:	071a                	slli	a4,a4,0x6
    80003b9a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b9c:	04449703          	lh	a4,68(s1)
    80003ba0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003ba4:	04649703          	lh	a4,70(s1)
    80003ba8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003bac:	04849703          	lh	a4,72(s1)
    80003bb0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003bb4:	04a49703          	lh	a4,74(s1)
    80003bb8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bbc:	44f8                	lw	a4,76(s1)
    80003bbe:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bc0:	03400613          	li	a2,52
    80003bc4:	05048593          	addi	a1,s1,80
    80003bc8:	00c78513          	addi	a0,a5,12
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	162080e7          	jalr	354(ra) # 80000d2e <memmove>
  log_write(bp);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	bfe080e7          	jalr	-1026(ra) # 800047d4 <log_write>
  brelse(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	96a080e7          	jalr	-1686(ra) # 8000354a <brelse>
}
    80003be8:	60e2                	ld	ra,24(sp)
    80003bea:	6442                	ld	s0,16(sp)
    80003bec:	64a2                	ld	s1,8(sp)
    80003bee:	6902                	ld	s2,0(sp)
    80003bf0:	6105                	addi	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <idup>:
{
    80003bf4:	1101                	addi	sp,sp,-32
    80003bf6:	ec06                	sd	ra,24(sp)
    80003bf8:	e822                	sd	s0,16(sp)
    80003bfa:	e426                	sd	s1,8(sp)
    80003bfc:	1000                	addi	s0,sp,32
    80003bfe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c00:	0001c517          	auipc	a0,0x1c
    80003c04:	2c850513          	addi	a0,a0,712 # 8001fec8 <itable>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	fce080e7          	jalr	-50(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003c10:	449c                	lw	a5,8(s1)
    80003c12:	2785                	addiw	a5,a5,1
    80003c14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c16:	0001c517          	auipc	a0,0x1c
    80003c1a:	2b250513          	addi	a0,a0,690 # 8001fec8 <itable>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	06c080e7          	jalr	108(ra) # 80000c8a <release>
}
    80003c26:	8526                	mv	a0,s1
    80003c28:	60e2                	ld	ra,24(sp)
    80003c2a:	6442                	ld	s0,16(sp)
    80003c2c:	64a2                	ld	s1,8(sp)
    80003c2e:	6105                	addi	sp,sp,32
    80003c30:	8082                	ret

0000000080003c32 <ilock>:
{
    80003c32:	1101                	addi	sp,sp,-32
    80003c34:	ec06                	sd	ra,24(sp)
    80003c36:	e822                	sd	s0,16(sp)
    80003c38:	e426                	sd	s1,8(sp)
    80003c3a:	e04a                	sd	s2,0(sp)
    80003c3c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c3e:	c115                	beqz	a0,80003c62 <ilock+0x30>
    80003c40:	84aa                	mv	s1,a0
    80003c42:	451c                	lw	a5,8(a0)
    80003c44:	00f05f63          	blez	a5,80003c62 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c48:	0541                	addi	a0,a0,16
    80003c4a:	00001097          	auipc	ra,0x1
    80003c4e:	ca8080e7          	jalr	-856(ra) # 800048f2 <acquiresleep>
  if(ip->valid == 0){
    80003c52:	40bc                	lw	a5,64(s1)
    80003c54:	cf99                	beqz	a5,80003c72 <ilock+0x40>
}
    80003c56:	60e2                	ld	ra,24(sp)
    80003c58:	6442                	ld	s0,16(sp)
    80003c5a:	64a2                	ld	s1,8(sp)
    80003c5c:	6902                	ld	s2,0(sp)
    80003c5e:	6105                	addi	sp,sp,32
    80003c60:	8082                	ret
    panic("ilock");
    80003c62:	00005517          	auipc	a0,0x5
    80003c66:	9be50513          	addi	a0,a0,-1602 # 80008620 <syscalls+0x1a0>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	8d6080e7          	jalr	-1834(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c72:	40dc                	lw	a5,4(s1)
    80003c74:	0047d79b          	srliw	a5,a5,0x4
    80003c78:	0001c597          	auipc	a1,0x1c
    80003c7c:	2485a583          	lw	a1,584(a1) # 8001fec0 <sb+0x18>
    80003c80:	9dbd                	addw	a1,a1,a5
    80003c82:	4088                	lw	a0,0(s1)
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	796080e7          	jalr	1942(ra) # 8000341a <bread>
    80003c8c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c8e:	05850593          	addi	a1,a0,88
    80003c92:	40dc                	lw	a5,4(s1)
    80003c94:	8bbd                	andi	a5,a5,15
    80003c96:	079a                	slli	a5,a5,0x6
    80003c98:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c9a:	00059783          	lh	a5,0(a1)
    80003c9e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ca2:	00259783          	lh	a5,2(a1)
    80003ca6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003caa:	00459783          	lh	a5,4(a1)
    80003cae:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cb2:	00659783          	lh	a5,6(a1)
    80003cb6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cba:	459c                	lw	a5,8(a1)
    80003cbc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cbe:	03400613          	li	a2,52
    80003cc2:	05b1                	addi	a1,a1,12
    80003cc4:	05048513          	addi	a0,s1,80
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	066080e7          	jalr	102(ra) # 80000d2e <memmove>
    brelse(bp);
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	878080e7          	jalr	-1928(ra) # 8000354a <brelse>
    ip->valid = 1;
    80003cda:	4785                	li	a5,1
    80003cdc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cde:	04449783          	lh	a5,68(s1)
    80003ce2:	fbb5                	bnez	a5,80003c56 <ilock+0x24>
      panic("ilock: no type");
    80003ce4:	00005517          	auipc	a0,0x5
    80003ce8:	94450513          	addi	a0,a0,-1724 # 80008628 <syscalls+0x1a8>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	854080e7          	jalr	-1964(ra) # 80000540 <panic>

0000000080003cf4 <iunlock>:
{
    80003cf4:	1101                	addi	sp,sp,-32
    80003cf6:	ec06                	sd	ra,24(sp)
    80003cf8:	e822                	sd	s0,16(sp)
    80003cfa:	e426                	sd	s1,8(sp)
    80003cfc:	e04a                	sd	s2,0(sp)
    80003cfe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d00:	c905                	beqz	a0,80003d30 <iunlock+0x3c>
    80003d02:	84aa                	mv	s1,a0
    80003d04:	01050913          	addi	s2,a0,16
    80003d08:	854a                	mv	a0,s2
    80003d0a:	00001097          	auipc	ra,0x1
    80003d0e:	c82080e7          	jalr	-894(ra) # 8000498c <holdingsleep>
    80003d12:	cd19                	beqz	a0,80003d30 <iunlock+0x3c>
    80003d14:	449c                	lw	a5,8(s1)
    80003d16:	00f05d63          	blez	a5,80003d30 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	00001097          	auipc	ra,0x1
    80003d20:	c2c080e7          	jalr	-980(ra) # 80004948 <releasesleep>
}
    80003d24:	60e2                	ld	ra,24(sp)
    80003d26:	6442                	ld	s0,16(sp)
    80003d28:	64a2                	ld	s1,8(sp)
    80003d2a:	6902                	ld	s2,0(sp)
    80003d2c:	6105                	addi	sp,sp,32
    80003d2e:	8082                	ret
    panic("iunlock");
    80003d30:	00005517          	auipc	a0,0x5
    80003d34:	90850513          	addi	a0,a0,-1784 # 80008638 <syscalls+0x1b8>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	808080e7          	jalr	-2040(ra) # 80000540 <panic>

0000000080003d40 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d40:	7179                	addi	sp,sp,-48
    80003d42:	f406                	sd	ra,40(sp)
    80003d44:	f022                	sd	s0,32(sp)
    80003d46:	ec26                	sd	s1,24(sp)
    80003d48:	e84a                	sd	s2,16(sp)
    80003d4a:	e44e                	sd	s3,8(sp)
    80003d4c:	e052                	sd	s4,0(sp)
    80003d4e:	1800                	addi	s0,sp,48
    80003d50:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d52:	05050493          	addi	s1,a0,80
    80003d56:	08050913          	addi	s2,a0,128
    80003d5a:	a021                	j	80003d62 <itrunc+0x22>
    80003d5c:	0491                	addi	s1,s1,4
    80003d5e:	01248d63          	beq	s1,s2,80003d78 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d62:	408c                	lw	a1,0(s1)
    80003d64:	dde5                	beqz	a1,80003d5c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d66:	0009a503          	lw	a0,0(s3)
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	8f6080e7          	jalr	-1802(ra) # 80003660 <bfree>
      ip->addrs[i] = 0;
    80003d72:	0004a023          	sw	zero,0(s1)
    80003d76:	b7dd                	j	80003d5c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d78:	0809a583          	lw	a1,128(s3)
    80003d7c:	e185                	bnez	a1,80003d9c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d7e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d82:	854e                	mv	a0,s3
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	de2080e7          	jalr	-542(ra) # 80003b66 <iupdate>
}
    80003d8c:	70a2                	ld	ra,40(sp)
    80003d8e:	7402                	ld	s0,32(sp)
    80003d90:	64e2                	ld	s1,24(sp)
    80003d92:	6942                	ld	s2,16(sp)
    80003d94:	69a2                	ld	s3,8(sp)
    80003d96:	6a02                	ld	s4,0(sp)
    80003d98:	6145                	addi	sp,sp,48
    80003d9a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d9c:	0009a503          	lw	a0,0(s3)
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	67a080e7          	jalr	1658(ra) # 8000341a <bread>
    80003da8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003daa:	05850493          	addi	s1,a0,88
    80003dae:	45850913          	addi	s2,a0,1112
    80003db2:	a021                	j	80003dba <itrunc+0x7a>
    80003db4:	0491                	addi	s1,s1,4
    80003db6:	01248b63          	beq	s1,s2,80003dcc <itrunc+0x8c>
      if(a[j])
    80003dba:	408c                	lw	a1,0(s1)
    80003dbc:	dde5                	beqz	a1,80003db4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dbe:	0009a503          	lw	a0,0(s3)
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	89e080e7          	jalr	-1890(ra) # 80003660 <bfree>
    80003dca:	b7ed                	j	80003db4 <itrunc+0x74>
    brelse(bp);
    80003dcc:	8552                	mv	a0,s4
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	77c080e7          	jalr	1916(ra) # 8000354a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dd6:	0809a583          	lw	a1,128(s3)
    80003dda:	0009a503          	lw	a0,0(s3)
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	882080e7          	jalr	-1918(ra) # 80003660 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003de6:	0809a023          	sw	zero,128(s3)
    80003dea:	bf51                	j	80003d7e <itrunc+0x3e>

0000000080003dec <iput>:
{
    80003dec:	1101                	addi	sp,sp,-32
    80003dee:	ec06                	sd	ra,24(sp)
    80003df0:	e822                	sd	s0,16(sp)
    80003df2:	e426                	sd	s1,8(sp)
    80003df4:	e04a                	sd	s2,0(sp)
    80003df6:	1000                	addi	s0,sp,32
    80003df8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dfa:	0001c517          	auipc	a0,0x1c
    80003dfe:	0ce50513          	addi	a0,a0,206 # 8001fec8 <itable>
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	dd4080e7          	jalr	-556(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e0a:	4498                	lw	a4,8(s1)
    80003e0c:	4785                	li	a5,1
    80003e0e:	02f70363          	beq	a4,a5,80003e34 <iput+0x48>
  ip->ref--;
    80003e12:	449c                	lw	a5,8(s1)
    80003e14:	37fd                	addiw	a5,a5,-1
    80003e16:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e18:	0001c517          	auipc	a0,0x1c
    80003e1c:	0b050513          	addi	a0,a0,176 # 8001fec8 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	e6a080e7          	jalr	-406(ra) # 80000c8a <release>
}
    80003e28:	60e2                	ld	ra,24(sp)
    80003e2a:	6442                	ld	s0,16(sp)
    80003e2c:	64a2                	ld	s1,8(sp)
    80003e2e:	6902                	ld	s2,0(sp)
    80003e30:	6105                	addi	sp,sp,32
    80003e32:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e34:	40bc                	lw	a5,64(s1)
    80003e36:	dff1                	beqz	a5,80003e12 <iput+0x26>
    80003e38:	04a49783          	lh	a5,74(s1)
    80003e3c:	fbf9                	bnez	a5,80003e12 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e3e:	01048913          	addi	s2,s1,16
    80003e42:	854a                	mv	a0,s2
    80003e44:	00001097          	auipc	ra,0x1
    80003e48:	aae080e7          	jalr	-1362(ra) # 800048f2 <acquiresleep>
    release(&itable.lock);
    80003e4c:	0001c517          	auipc	a0,0x1c
    80003e50:	07c50513          	addi	a0,a0,124 # 8001fec8 <itable>
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	e36080e7          	jalr	-458(ra) # 80000c8a <release>
    itrunc(ip);
    80003e5c:	8526                	mv	a0,s1
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	ee2080e7          	jalr	-286(ra) # 80003d40 <itrunc>
    ip->type = 0;
    80003e66:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e6a:	8526                	mv	a0,s1
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	cfa080e7          	jalr	-774(ra) # 80003b66 <iupdate>
    ip->valid = 0;
    80003e74:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e78:	854a                	mv	a0,s2
    80003e7a:	00001097          	auipc	ra,0x1
    80003e7e:	ace080e7          	jalr	-1330(ra) # 80004948 <releasesleep>
    acquire(&itable.lock);
    80003e82:	0001c517          	auipc	a0,0x1c
    80003e86:	04650513          	addi	a0,a0,70 # 8001fec8 <itable>
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	d4c080e7          	jalr	-692(ra) # 80000bd6 <acquire>
    80003e92:	b741                	j	80003e12 <iput+0x26>

0000000080003e94 <iunlockput>:
{
    80003e94:	1101                	addi	sp,sp,-32
    80003e96:	ec06                	sd	ra,24(sp)
    80003e98:	e822                	sd	s0,16(sp)
    80003e9a:	e426                	sd	s1,8(sp)
    80003e9c:	1000                	addi	s0,sp,32
    80003e9e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	e54080e7          	jalr	-428(ra) # 80003cf4 <iunlock>
  iput(ip);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	f42080e7          	jalr	-190(ra) # 80003dec <iput>
}
    80003eb2:	60e2                	ld	ra,24(sp)
    80003eb4:	6442                	ld	s0,16(sp)
    80003eb6:	64a2                	ld	s1,8(sp)
    80003eb8:	6105                	addi	sp,sp,32
    80003eba:	8082                	ret

0000000080003ebc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ebc:	1141                	addi	sp,sp,-16
    80003ebe:	e422                	sd	s0,8(sp)
    80003ec0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ec2:	411c                	lw	a5,0(a0)
    80003ec4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ec6:	415c                	lw	a5,4(a0)
    80003ec8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003eca:	04451783          	lh	a5,68(a0)
    80003ece:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ed2:	04a51783          	lh	a5,74(a0)
    80003ed6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003eda:	04c56783          	lwu	a5,76(a0)
    80003ede:	e99c                	sd	a5,16(a1)
}
    80003ee0:	6422                	ld	s0,8(sp)
    80003ee2:	0141                	addi	sp,sp,16
    80003ee4:	8082                	ret

0000000080003ee6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ee6:	457c                	lw	a5,76(a0)
    80003ee8:	0ed7e963          	bltu	a5,a3,80003fda <readi+0xf4>
{
    80003eec:	7159                	addi	sp,sp,-112
    80003eee:	f486                	sd	ra,104(sp)
    80003ef0:	f0a2                	sd	s0,96(sp)
    80003ef2:	eca6                	sd	s1,88(sp)
    80003ef4:	e8ca                	sd	s2,80(sp)
    80003ef6:	e4ce                	sd	s3,72(sp)
    80003ef8:	e0d2                	sd	s4,64(sp)
    80003efa:	fc56                	sd	s5,56(sp)
    80003efc:	f85a                	sd	s6,48(sp)
    80003efe:	f45e                	sd	s7,40(sp)
    80003f00:	f062                	sd	s8,32(sp)
    80003f02:	ec66                	sd	s9,24(sp)
    80003f04:	e86a                	sd	s10,16(sp)
    80003f06:	e46e                	sd	s11,8(sp)
    80003f08:	1880                	addi	s0,sp,112
    80003f0a:	8b2a                	mv	s6,a0
    80003f0c:	8bae                	mv	s7,a1
    80003f0e:	8a32                	mv	s4,a2
    80003f10:	84b6                	mv	s1,a3
    80003f12:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f14:	9f35                	addw	a4,a4,a3
    return 0;
    80003f16:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f18:	0ad76063          	bltu	a4,a3,80003fb8 <readi+0xd2>
  if(off + n > ip->size)
    80003f1c:	00e7f463          	bgeu	a5,a4,80003f24 <readi+0x3e>
    n = ip->size - off;
    80003f20:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f24:	0a0a8963          	beqz	s5,80003fd6 <readi+0xf0>
    80003f28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f2e:	5c7d                	li	s8,-1
    80003f30:	a82d                	j	80003f6a <readi+0x84>
    80003f32:	020d1d93          	slli	s11,s10,0x20
    80003f36:	020ddd93          	srli	s11,s11,0x20
    80003f3a:	05890613          	addi	a2,s2,88
    80003f3e:	86ee                	mv	a3,s11
    80003f40:	963a                	add	a2,a2,a4
    80003f42:	85d2                	mv	a1,s4
    80003f44:	855e                	mv	a0,s7
    80003f46:	ffffe097          	auipc	ra,0xffffe
    80003f4a:	5e0080e7          	jalr	1504(ra) # 80002526 <either_copyout>
    80003f4e:	05850d63          	beq	a0,s8,80003fa8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f52:	854a                	mv	a0,s2
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	5f6080e7          	jalr	1526(ra) # 8000354a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f5c:	013d09bb          	addw	s3,s10,s3
    80003f60:	009d04bb          	addw	s1,s10,s1
    80003f64:	9a6e                	add	s4,s4,s11
    80003f66:	0559f763          	bgeu	s3,s5,80003fb4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f6a:	00a4d59b          	srliw	a1,s1,0xa
    80003f6e:	855a                	mv	a0,s6
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	89e080e7          	jalr	-1890(ra) # 8000380e <bmap>
    80003f78:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f7c:	cd85                	beqz	a1,80003fb4 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f7e:	000b2503          	lw	a0,0(s6)
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	498080e7          	jalr	1176(ra) # 8000341a <bread>
    80003f8a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f8c:	3ff4f713          	andi	a4,s1,1023
    80003f90:	40ec87bb          	subw	a5,s9,a4
    80003f94:	413a86bb          	subw	a3,s5,s3
    80003f98:	8d3e                	mv	s10,a5
    80003f9a:	2781                	sext.w	a5,a5
    80003f9c:	0006861b          	sext.w	a2,a3
    80003fa0:	f8f679e3          	bgeu	a2,a5,80003f32 <readi+0x4c>
    80003fa4:	8d36                	mv	s10,a3
    80003fa6:	b771                	j	80003f32 <readi+0x4c>
      brelse(bp);
    80003fa8:	854a                	mv	a0,s2
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	5a0080e7          	jalr	1440(ra) # 8000354a <brelse>
      tot = -1;
    80003fb2:	59fd                	li	s3,-1
  }
  return tot;
    80003fb4:	0009851b          	sext.w	a0,s3
}
    80003fb8:	70a6                	ld	ra,104(sp)
    80003fba:	7406                	ld	s0,96(sp)
    80003fbc:	64e6                	ld	s1,88(sp)
    80003fbe:	6946                	ld	s2,80(sp)
    80003fc0:	69a6                	ld	s3,72(sp)
    80003fc2:	6a06                	ld	s4,64(sp)
    80003fc4:	7ae2                	ld	s5,56(sp)
    80003fc6:	7b42                	ld	s6,48(sp)
    80003fc8:	7ba2                	ld	s7,40(sp)
    80003fca:	7c02                	ld	s8,32(sp)
    80003fcc:	6ce2                	ld	s9,24(sp)
    80003fce:	6d42                	ld	s10,16(sp)
    80003fd0:	6da2                	ld	s11,8(sp)
    80003fd2:	6165                	addi	sp,sp,112
    80003fd4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fd6:	89d6                	mv	s3,s5
    80003fd8:	bff1                	j	80003fb4 <readi+0xce>
    return 0;
    80003fda:	4501                	li	a0,0
}
    80003fdc:	8082                	ret

0000000080003fde <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fde:	457c                	lw	a5,76(a0)
    80003fe0:	10d7e863          	bltu	a5,a3,800040f0 <writei+0x112>
{
    80003fe4:	7159                	addi	sp,sp,-112
    80003fe6:	f486                	sd	ra,104(sp)
    80003fe8:	f0a2                	sd	s0,96(sp)
    80003fea:	eca6                	sd	s1,88(sp)
    80003fec:	e8ca                	sd	s2,80(sp)
    80003fee:	e4ce                	sd	s3,72(sp)
    80003ff0:	e0d2                	sd	s4,64(sp)
    80003ff2:	fc56                	sd	s5,56(sp)
    80003ff4:	f85a                	sd	s6,48(sp)
    80003ff6:	f45e                	sd	s7,40(sp)
    80003ff8:	f062                	sd	s8,32(sp)
    80003ffa:	ec66                	sd	s9,24(sp)
    80003ffc:	e86a                	sd	s10,16(sp)
    80003ffe:	e46e                	sd	s11,8(sp)
    80004000:	1880                	addi	s0,sp,112
    80004002:	8aaa                	mv	s5,a0
    80004004:	8bae                	mv	s7,a1
    80004006:	8a32                	mv	s4,a2
    80004008:	8936                	mv	s2,a3
    8000400a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000400c:	00e687bb          	addw	a5,a3,a4
    80004010:	0ed7e263          	bltu	a5,a3,800040f4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004014:	00043737          	lui	a4,0x43
    80004018:	0ef76063          	bltu	a4,a5,800040f8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000401c:	0c0b0863          	beqz	s6,800040ec <writei+0x10e>
    80004020:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004022:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004026:	5c7d                	li	s8,-1
    80004028:	a091                	j	8000406c <writei+0x8e>
    8000402a:	020d1d93          	slli	s11,s10,0x20
    8000402e:	020ddd93          	srli	s11,s11,0x20
    80004032:	05848513          	addi	a0,s1,88
    80004036:	86ee                	mv	a3,s11
    80004038:	8652                	mv	a2,s4
    8000403a:	85de                	mv	a1,s7
    8000403c:	953a                	add	a0,a0,a4
    8000403e:	ffffe097          	auipc	ra,0xffffe
    80004042:	53e080e7          	jalr	1342(ra) # 8000257c <either_copyin>
    80004046:	07850263          	beq	a0,s8,800040aa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000404a:	8526                	mv	a0,s1
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	788080e7          	jalr	1928(ra) # 800047d4 <log_write>
    brelse(bp);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	4f4080e7          	jalr	1268(ra) # 8000354a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000405e:	013d09bb          	addw	s3,s10,s3
    80004062:	012d093b          	addw	s2,s10,s2
    80004066:	9a6e                	add	s4,s4,s11
    80004068:	0569f663          	bgeu	s3,s6,800040b4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000406c:	00a9559b          	srliw	a1,s2,0xa
    80004070:	8556                	mv	a0,s5
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	79c080e7          	jalr	1948(ra) # 8000380e <bmap>
    8000407a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000407e:	c99d                	beqz	a1,800040b4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004080:	000aa503          	lw	a0,0(s5)
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	396080e7          	jalr	918(ra) # 8000341a <bread>
    8000408c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408e:	3ff97713          	andi	a4,s2,1023
    80004092:	40ec87bb          	subw	a5,s9,a4
    80004096:	413b06bb          	subw	a3,s6,s3
    8000409a:	8d3e                	mv	s10,a5
    8000409c:	2781                	sext.w	a5,a5
    8000409e:	0006861b          	sext.w	a2,a3
    800040a2:	f8f674e3          	bgeu	a2,a5,8000402a <writei+0x4c>
    800040a6:	8d36                	mv	s10,a3
    800040a8:	b749                	j	8000402a <writei+0x4c>
      brelse(bp);
    800040aa:	8526                	mv	a0,s1
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	49e080e7          	jalr	1182(ra) # 8000354a <brelse>
  }

  if(off > ip->size)
    800040b4:	04caa783          	lw	a5,76(s5)
    800040b8:	0127f463          	bgeu	a5,s2,800040c0 <writei+0xe2>
    ip->size = off;
    800040bc:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040c0:	8556                	mv	a0,s5
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	aa4080e7          	jalr	-1372(ra) # 80003b66 <iupdate>

  return tot;
    800040ca:	0009851b          	sext.w	a0,s3
}
    800040ce:	70a6                	ld	ra,104(sp)
    800040d0:	7406                	ld	s0,96(sp)
    800040d2:	64e6                	ld	s1,88(sp)
    800040d4:	6946                	ld	s2,80(sp)
    800040d6:	69a6                	ld	s3,72(sp)
    800040d8:	6a06                	ld	s4,64(sp)
    800040da:	7ae2                	ld	s5,56(sp)
    800040dc:	7b42                	ld	s6,48(sp)
    800040de:	7ba2                	ld	s7,40(sp)
    800040e0:	7c02                	ld	s8,32(sp)
    800040e2:	6ce2                	ld	s9,24(sp)
    800040e4:	6d42                	ld	s10,16(sp)
    800040e6:	6da2                	ld	s11,8(sp)
    800040e8:	6165                	addi	sp,sp,112
    800040ea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ec:	89da                	mv	s3,s6
    800040ee:	bfc9                	j	800040c0 <writei+0xe2>
    return -1;
    800040f0:	557d                	li	a0,-1
}
    800040f2:	8082                	ret
    return -1;
    800040f4:	557d                	li	a0,-1
    800040f6:	bfe1                	j	800040ce <writei+0xf0>
    return -1;
    800040f8:	557d                	li	a0,-1
    800040fa:	bfd1                	j	800040ce <writei+0xf0>

00000000800040fc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040fc:	1141                	addi	sp,sp,-16
    800040fe:	e406                	sd	ra,8(sp)
    80004100:	e022                	sd	s0,0(sp)
    80004102:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004104:	4639                	li	a2,14
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	c9c080e7          	jalr	-868(ra) # 80000da2 <strncmp>
}
    8000410e:	60a2                	ld	ra,8(sp)
    80004110:	6402                	ld	s0,0(sp)
    80004112:	0141                	addi	sp,sp,16
    80004114:	8082                	ret

0000000080004116 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004116:	7139                	addi	sp,sp,-64
    80004118:	fc06                	sd	ra,56(sp)
    8000411a:	f822                	sd	s0,48(sp)
    8000411c:	f426                	sd	s1,40(sp)
    8000411e:	f04a                	sd	s2,32(sp)
    80004120:	ec4e                	sd	s3,24(sp)
    80004122:	e852                	sd	s4,16(sp)
    80004124:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004126:	04451703          	lh	a4,68(a0)
    8000412a:	4785                	li	a5,1
    8000412c:	00f71a63          	bne	a4,a5,80004140 <dirlookup+0x2a>
    80004130:	892a                	mv	s2,a0
    80004132:	89ae                	mv	s3,a1
    80004134:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004136:	457c                	lw	a5,76(a0)
    80004138:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000413a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413c:	e79d                	bnez	a5,8000416a <dirlookup+0x54>
    8000413e:	a8a5                	j	800041b6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004140:	00004517          	auipc	a0,0x4
    80004144:	50050513          	addi	a0,a0,1280 # 80008640 <syscalls+0x1c0>
    80004148:	ffffc097          	auipc	ra,0xffffc
    8000414c:	3f8080e7          	jalr	1016(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004150:	00004517          	auipc	a0,0x4
    80004154:	50850513          	addi	a0,a0,1288 # 80008658 <syscalls+0x1d8>
    80004158:	ffffc097          	auipc	ra,0xffffc
    8000415c:	3e8080e7          	jalr	1000(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004160:	24c1                	addiw	s1,s1,16
    80004162:	04c92783          	lw	a5,76(s2)
    80004166:	04f4f763          	bgeu	s1,a5,800041b4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000416a:	4741                	li	a4,16
    8000416c:	86a6                	mv	a3,s1
    8000416e:	fc040613          	addi	a2,s0,-64
    80004172:	4581                	li	a1,0
    80004174:	854a                	mv	a0,s2
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	d70080e7          	jalr	-656(ra) # 80003ee6 <readi>
    8000417e:	47c1                	li	a5,16
    80004180:	fcf518e3          	bne	a0,a5,80004150 <dirlookup+0x3a>
    if(de.inum == 0)
    80004184:	fc045783          	lhu	a5,-64(s0)
    80004188:	dfe1                	beqz	a5,80004160 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000418a:	fc240593          	addi	a1,s0,-62
    8000418e:	854e                	mv	a0,s3
    80004190:	00000097          	auipc	ra,0x0
    80004194:	f6c080e7          	jalr	-148(ra) # 800040fc <namecmp>
    80004198:	f561                	bnez	a0,80004160 <dirlookup+0x4a>
      if(poff)
    8000419a:	000a0463          	beqz	s4,800041a2 <dirlookup+0x8c>
        *poff = off;
    8000419e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041a2:	fc045583          	lhu	a1,-64(s0)
    800041a6:	00092503          	lw	a0,0(s2)
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	74e080e7          	jalr	1870(ra) # 800038f8 <iget>
    800041b2:	a011                	j	800041b6 <dirlookup+0xa0>
  return 0;
    800041b4:	4501                	li	a0,0
}
    800041b6:	70e2                	ld	ra,56(sp)
    800041b8:	7442                	ld	s0,48(sp)
    800041ba:	74a2                	ld	s1,40(sp)
    800041bc:	7902                	ld	s2,32(sp)
    800041be:	69e2                	ld	s3,24(sp)
    800041c0:	6a42                	ld	s4,16(sp)
    800041c2:	6121                	addi	sp,sp,64
    800041c4:	8082                	ret

00000000800041c6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041c6:	711d                	addi	sp,sp,-96
    800041c8:	ec86                	sd	ra,88(sp)
    800041ca:	e8a2                	sd	s0,80(sp)
    800041cc:	e4a6                	sd	s1,72(sp)
    800041ce:	e0ca                	sd	s2,64(sp)
    800041d0:	fc4e                	sd	s3,56(sp)
    800041d2:	f852                	sd	s4,48(sp)
    800041d4:	f456                	sd	s5,40(sp)
    800041d6:	f05a                	sd	s6,32(sp)
    800041d8:	ec5e                	sd	s7,24(sp)
    800041da:	e862                	sd	s8,16(sp)
    800041dc:	e466                	sd	s9,8(sp)
    800041de:	e06a                	sd	s10,0(sp)
    800041e0:	1080                	addi	s0,sp,96
    800041e2:	84aa                	mv	s1,a0
    800041e4:	8b2e                	mv	s6,a1
    800041e6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041e8:	00054703          	lbu	a4,0(a0)
    800041ec:	02f00793          	li	a5,47
    800041f0:	02f70363          	beq	a4,a5,80004216 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	7b8080e7          	jalr	1976(ra) # 800019ac <myproc>
    800041fc:	15053503          	ld	a0,336(a0)
    80004200:	00000097          	auipc	ra,0x0
    80004204:	9f4080e7          	jalr	-1548(ra) # 80003bf4 <idup>
    80004208:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000420a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000420e:	4cb5                	li	s9,13
  len = path - s;
    80004210:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004212:	4c05                	li	s8,1
    80004214:	a87d                	j	800042d2 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004216:	4585                	li	a1,1
    80004218:	4505                	li	a0,1
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	6de080e7          	jalr	1758(ra) # 800038f8 <iget>
    80004222:	8a2a                	mv	s4,a0
    80004224:	b7dd                	j	8000420a <namex+0x44>
      iunlockput(ip);
    80004226:	8552                	mv	a0,s4
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	c6c080e7          	jalr	-916(ra) # 80003e94 <iunlockput>
      return 0;
    80004230:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004232:	8552                	mv	a0,s4
    80004234:	60e6                	ld	ra,88(sp)
    80004236:	6446                	ld	s0,80(sp)
    80004238:	64a6                	ld	s1,72(sp)
    8000423a:	6906                	ld	s2,64(sp)
    8000423c:	79e2                	ld	s3,56(sp)
    8000423e:	7a42                	ld	s4,48(sp)
    80004240:	7aa2                	ld	s5,40(sp)
    80004242:	7b02                	ld	s6,32(sp)
    80004244:	6be2                	ld	s7,24(sp)
    80004246:	6c42                	ld	s8,16(sp)
    80004248:	6ca2                	ld	s9,8(sp)
    8000424a:	6d02                	ld	s10,0(sp)
    8000424c:	6125                	addi	sp,sp,96
    8000424e:	8082                	ret
      iunlock(ip);
    80004250:	8552                	mv	a0,s4
    80004252:	00000097          	auipc	ra,0x0
    80004256:	aa2080e7          	jalr	-1374(ra) # 80003cf4 <iunlock>
      return ip;
    8000425a:	bfe1                	j	80004232 <namex+0x6c>
      iunlockput(ip);
    8000425c:	8552                	mv	a0,s4
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	c36080e7          	jalr	-970(ra) # 80003e94 <iunlockput>
      return 0;
    80004266:	8a4e                	mv	s4,s3
    80004268:	b7e9                	j	80004232 <namex+0x6c>
  len = path - s;
    8000426a:	40998633          	sub	a2,s3,s1
    8000426e:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004272:	09acd863          	bge	s9,s10,80004302 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004276:	4639                	li	a2,14
    80004278:	85a6                	mv	a1,s1
    8000427a:	8556                	mv	a0,s5
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	ab2080e7          	jalr	-1358(ra) # 80000d2e <memmove>
    80004284:	84ce                	mv	s1,s3
  while(*path == '/')
    80004286:	0004c783          	lbu	a5,0(s1)
    8000428a:	01279763          	bne	a5,s2,80004298 <namex+0xd2>
    path++;
    8000428e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004290:	0004c783          	lbu	a5,0(s1)
    80004294:	ff278de3          	beq	a5,s2,8000428e <namex+0xc8>
    ilock(ip);
    80004298:	8552                	mv	a0,s4
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	998080e7          	jalr	-1640(ra) # 80003c32 <ilock>
    if(ip->type != T_DIR){
    800042a2:	044a1783          	lh	a5,68(s4)
    800042a6:	f98790e3          	bne	a5,s8,80004226 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800042aa:	000b0563          	beqz	s6,800042b4 <namex+0xee>
    800042ae:	0004c783          	lbu	a5,0(s1)
    800042b2:	dfd9                	beqz	a5,80004250 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042b4:	865e                	mv	a2,s7
    800042b6:	85d6                	mv	a1,s5
    800042b8:	8552                	mv	a0,s4
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	e5c080e7          	jalr	-420(ra) # 80004116 <dirlookup>
    800042c2:	89aa                	mv	s3,a0
    800042c4:	dd41                	beqz	a0,8000425c <namex+0x96>
    iunlockput(ip);
    800042c6:	8552                	mv	a0,s4
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	bcc080e7          	jalr	-1076(ra) # 80003e94 <iunlockput>
    ip = next;
    800042d0:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042d2:	0004c783          	lbu	a5,0(s1)
    800042d6:	01279763          	bne	a5,s2,800042e4 <namex+0x11e>
    path++;
    800042da:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042dc:	0004c783          	lbu	a5,0(s1)
    800042e0:	ff278de3          	beq	a5,s2,800042da <namex+0x114>
  if(*path == 0)
    800042e4:	cb9d                	beqz	a5,8000431a <namex+0x154>
  while(*path != '/' && *path != 0)
    800042e6:	0004c783          	lbu	a5,0(s1)
    800042ea:	89a6                	mv	s3,s1
  len = path - s;
    800042ec:	8d5e                	mv	s10,s7
    800042ee:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042f0:	01278963          	beq	a5,s2,80004302 <namex+0x13c>
    800042f4:	dbbd                	beqz	a5,8000426a <namex+0xa4>
    path++;
    800042f6:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042f8:	0009c783          	lbu	a5,0(s3)
    800042fc:	ff279ce3          	bne	a5,s2,800042f4 <namex+0x12e>
    80004300:	b7ad                	j	8000426a <namex+0xa4>
    memmove(name, s, len);
    80004302:	2601                	sext.w	a2,a2
    80004304:	85a6                	mv	a1,s1
    80004306:	8556                	mv	a0,s5
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	a26080e7          	jalr	-1498(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004310:	9d56                	add	s10,s10,s5
    80004312:	000d0023          	sb	zero,0(s10)
    80004316:	84ce                	mv	s1,s3
    80004318:	b7bd                	j	80004286 <namex+0xc0>
  if(nameiparent){
    8000431a:	f00b0ce3          	beqz	s6,80004232 <namex+0x6c>
    iput(ip);
    8000431e:	8552                	mv	a0,s4
    80004320:	00000097          	auipc	ra,0x0
    80004324:	acc080e7          	jalr	-1332(ra) # 80003dec <iput>
    return 0;
    80004328:	4a01                	li	s4,0
    8000432a:	b721                	j	80004232 <namex+0x6c>

000000008000432c <dirlink>:
{
    8000432c:	7139                	addi	sp,sp,-64
    8000432e:	fc06                	sd	ra,56(sp)
    80004330:	f822                	sd	s0,48(sp)
    80004332:	f426                	sd	s1,40(sp)
    80004334:	f04a                	sd	s2,32(sp)
    80004336:	ec4e                	sd	s3,24(sp)
    80004338:	e852                	sd	s4,16(sp)
    8000433a:	0080                	addi	s0,sp,64
    8000433c:	892a                	mv	s2,a0
    8000433e:	8a2e                	mv	s4,a1
    80004340:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004342:	4601                	li	a2,0
    80004344:	00000097          	auipc	ra,0x0
    80004348:	dd2080e7          	jalr	-558(ra) # 80004116 <dirlookup>
    8000434c:	e93d                	bnez	a0,800043c2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434e:	04c92483          	lw	s1,76(s2)
    80004352:	c49d                	beqz	s1,80004380 <dirlink+0x54>
    80004354:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004356:	4741                	li	a4,16
    80004358:	86a6                	mv	a3,s1
    8000435a:	fc040613          	addi	a2,s0,-64
    8000435e:	4581                	li	a1,0
    80004360:	854a                	mv	a0,s2
    80004362:	00000097          	auipc	ra,0x0
    80004366:	b84080e7          	jalr	-1148(ra) # 80003ee6 <readi>
    8000436a:	47c1                	li	a5,16
    8000436c:	06f51163          	bne	a0,a5,800043ce <dirlink+0xa2>
    if(de.inum == 0)
    80004370:	fc045783          	lhu	a5,-64(s0)
    80004374:	c791                	beqz	a5,80004380 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004376:	24c1                	addiw	s1,s1,16
    80004378:	04c92783          	lw	a5,76(s2)
    8000437c:	fcf4ede3          	bltu	s1,a5,80004356 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004380:	4639                	li	a2,14
    80004382:	85d2                	mv	a1,s4
    80004384:	fc240513          	addi	a0,s0,-62
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	a56080e7          	jalr	-1450(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004390:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004394:	4741                	li	a4,16
    80004396:	86a6                	mv	a3,s1
    80004398:	fc040613          	addi	a2,s0,-64
    8000439c:	4581                	li	a1,0
    8000439e:	854a                	mv	a0,s2
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	c3e080e7          	jalr	-962(ra) # 80003fde <writei>
    800043a8:	1541                	addi	a0,a0,-16
    800043aa:	00a03533          	snez	a0,a0
    800043ae:	40a00533          	neg	a0,a0
}
    800043b2:	70e2                	ld	ra,56(sp)
    800043b4:	7442                	ld	s0,48(sp)
    800043b6:	74a2                	ld	s1,40(sp)
    800043b8:	7902                	ld	s2,32(sp)
    800043ba:	69e2                	ld	s3,24(sp)
    800043bc:	6a42                	ld	s4,16(sp)
    800043be:	6121                	addi	sp,sp,64
    800043c0:	8082                	ret
    iput(ip);
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	a2a080e7          	jalr	-1494(ra) # 80003dec <iput>
    return -1;
    800043ca:	557d                	li	a0,-1
    800043cc:	b7dd                	j	800043b2 <dirlink+0x86>
      panic("dirlink read");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	29a50513          	addi	a0,a0,666 # 80008668 <syscalls+0x1e8>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	16a080e7          	jalr	362(ra) # 80000540 <panic>

00000000800043de <namei>:

struct inode*
namei(char *path)
{
    800043de:	1101                	addi	sp,sp,-32
    800043e0:	ec06                	sd	ra,24(sp)
    800043e2:	e822                	sd	s0,16(sp)
    800043e4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043e6:	fe040613          	addi	a2,s0,-32
    800043ea:	4581                	li	a1,0
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	dda080e7          	jalr	-550(ra) # 800041c6 <namex>
}
    800043f4:	60e2                	ld	ra,24(sp)
    800043f6:	6442                	ld	s0,16(sp)
    800043f8:	6105                	addi	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043fc:	1141                	addi	sp,sp,-16
    800043fe:	e406                	sd	ra,8(sp)
    80004400:	e022                	sd	s0,0(sp)
    80004402:	0800                	addi	s0,sp,16
    80004404:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004406:	4585                	li	a1,1
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	dbe080e7          	jalr	-578(ra) # 800041c6 <namex>
}
    80004410:	60a2                	ld	ra,8(sp)
    80004412:	6402                	ld	s0,0(sp)
    80004414:	0141                	addi	sp,sp,16
    80004416:	8082                	ret

0000000080004418 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004418:	1101                	addi	sp,sp,-32
    8000441a:	ec06                	sd	ra,24(sp)
    8000441c:	e822                	sd	s0,16(sp)
    8000441e:	e426                	sd	s1,8(sp)
    80004420:	e04a                	sd	s2,0(sp)
    80004422:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004424:	0001d917          	auipc	s2,0x1d
    80004428:	54c90913          	addi	s2,s2,1356 # 80021970 <log>
    8000442c:	01892583          	lw	a1,24(s2)
    80004430:	02892503          	lw	a0,40(s2)
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	fe6080e7          	jalr	-26(ra) # 8000341a <bread>
    8000443c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000443e:	02c92683          	lw	a3,44(s2)
    80004442:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004444:	02d05863          	blez	a3,80004474 <write_head+0x5c>
    80004448:	0001d797          	auipc	a5,0x1d
    8000444c:	55878793          	addi	a5,a5,1368 # 800219a0 <log+0x30>
    80004450:	05c50713          	addi	a4,a0,92
    80004454:	36fd                	addiw	a3,a3,-1
    80004456:	02069613          	slli	a2,a3,0x20
    8000445a:	01e65693          	srli	a3,a2,0x1e
    8000445e:	0001d617          	auipc	a2,0x1d
    80004462:	54660613          	addi	a2,a2,1350 # 800219a4 <log+0x34>
    80004466:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004468:	4390                	lw	a2,0(a5)
    8000446a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000446c:	0791                	addi	a5,a5,4
    8000446e:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004470:	fed79ce3          	bne	a5,a3,80004468 <write_head+0x50>
  }
  bwrite(buf);
    80004474:	8526                	mv	a0,s1
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	096080e7          	jalr	150(ra) # 8000350c <bwrite>
  brelse(buf);
    8000447e:	8526                	mv	a0,s1
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	0ca080e7          	jalr	202(ra) # 8000354a <brelse>
}
    80004488:	60e2                	ld	ra,24(sp)
    8000448a:	6442                	ld	s0,16(sp)
    8000448c:	64a2                	ld	s1,8(sp)
    8000448e:	6902                	ld	s2,0(sp)
    80004490:	6105                	addi	sp,sp,32
    80004492:	8082                	ret

0000000080004494 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004494:	0001d797          	auipc	a5,0x1d
    80004498:	5087a783          	lw	a5,1288(a5) # 8002199c <log+0x2c>
    8000449c:	0af05d63          	blez	a5,80004556 <install_trans+0xc2>
{
    800044a0:	7139                	addi	sp,sp,-64
    800044a2:	fc06                	sd	ra,56(sp)
    800044a4:	f822                	sd	s0,48(sp)
    800044a6:	f426                	sd	s1,40(sp)
    800044a8:	f04a                	sd	s2,32(sp)
    800044aa:	ec4e                	sd	s3,24(sp)
    800044ac:	e852                	sd	s4,16(sp)
    800044ae:	e456                	sd	s5,8(sp)
    800044b0:	e05a                	sd	s6,0(sp)
    800044b2:	0080                	addi	s0,sp,64
    800044b4:	8b2a                	mv	s6,a0
    800044b6:	0001da97          	auipc	s5,0x1d
    800044ba:	4eaa8a93          	addi	s5,s5,1258 # 800219a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044be:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044c0:	0001d997          	auipc	s3,0x1d
    800044c4:	4b098993          	addi	s3,s3,1200 # 80021970 <log>
    800044c8:	a00d                	j	800044ea <install_trans+0x56>
    brelse(lbuf);
    800044ca:	854a                	mv	a0,s2
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	07e080e7          	jalr	126(ra) # 8000354a <brelse>
    brelse(dbuf);
    800044d4:	8526                	mv	a0,s1
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	074080e7          	jalr	116(ra) # 8000354a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044de:	2a05                	addiw	s4,s4,1
    800044e0:	0a91                	addi	s5,s5,4
    800044e2:	02c9a783          	lw	a5,44(s3)
    800044e6:	04fa5e63          	bge	s4,a5,80004542 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044ea:	0189a583          	lw	a1,24(s3)
    800044ee:	014585bb          	addw	a1,a1,s4
    800044f2:	2585                	addiw	a1,a1,1
    800044f4:	0289a503          	lw	a0,40(s3)
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	f22080e7          	jalr	-222(ra) # 8000341a <bread>
    80004500:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004502:	000aa583          	lw	a1,0(s5)
    80004506:	0289a503          	lw	a0,40(s3)
    8000450a:	fffff097          	auipc	ra,0xfffff
    8000450e:	f10080e7          	jalr	-240(ra) # 8000341a <bread>
    80004512:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004514:	40000613          	li	a2,1024
    80004518:	05890593          	addi	a1,s2,88
    8000451c:	05850513          	addi	a0,a0,88
    80004520:	ffffd097          	auipc	ra,0xffffd
    80004524:	80e080e7          	jalr	-2034(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004528:	8526                	mv	a0,s1
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	fe2080e7          	jalr	-30(ra) # 8000350c <bwrite>
    if(recovering == 0)
    80004532:	f80b1ce3          	bnez	s6,800044ca <install_trans+0x36>
      bunpin(dbuf);
    80004536:	8526                	mv	a0,s1
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	0ec080e7          	jalr	236(ra) # 80003624 <bunpin>
    80004540:	b769                	j	800044ca <install_trans+0x36>
}
    80004542:	70e2                	ld	ra,56(sp)
    80004544:	7442                	ld	s0,48(sp)
    80004546:	74a2                	ld	s1,40(sp)
    80004548:	7902                	ld	s2,32(sp)
    8000454a:	69e2                	ld	s3,24(sp)
    8000454c:	6a42                	ld	s4,16(sp)
    8000454e:	6aa2                	ld	s5,8(sp)
    80004550:	6b02                	ld	s6,0(sp)
    80004552:	6121                	addi	sp,sp,64
    80004554:	8082                	ret
    80004556:	8082                	ret

0000000080004558 <initlog>:
{
    80004558:	7179                	addi	sp,sp,-48
    8000455a:	f406                	sd	ra,40(sp)
    8000455c:	f022                	sd	s0,32(sp)
    8000455e:	ec26                	sd	s1,24(sp)
    80004560:	e84a                	sd	s2,16(sp)
    80004562:	e44e                	sd	s3,8(sp)
    80004564:	1800                	addi	s0,sp,48
    80004566:	892a                	mv	s2,a0
    80004568:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000456a:	0001d497          	auipc	s1,0x1d
    8000456e:	40648493          	addi	s1,s1,1030 # 80021970 <log>
    80004572:	00004597          	auipc	a1,0x4
    80004576:	10658593          	addi	a1,a1,262 # 80008678 <syscalls+0x1f8>
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	5ca080e7          	jalr	1482(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004584:	0149a583          	lw	a1,20(s3)
    80004588:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000458a:	0109a783          	lw	a5,16(s3)
    8000458e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004590:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004594:	854a                	mv	a0,s2
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	e84080e7          	jalr	-380(ra) # 8000341a <bread>
  log.lh.n = lh->n;
    8000459e:	4d34                	lw	a3,88(a0)
    800045a0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045a2:	02d05663          	blez	a3,800045ce <initlog+0x76>
    800045a6:	05c50793          	addi	a5,a0,92
    800045aa:	0001d717          	auipc	a4,0x1d
    800045ae:	3f670713          	addi	a4,a4,1014 # 800219a0 <log+0x30>
    800045b2:	36fd                	addiw	a3,a3,-1
    800045b4:	02069613          	slli	a2,a3,0x20
    800045b8:	01e65693          	srli	a3,a2,0x1e
    800045bc:	06050613          	addi	a2,a0,96
    800045c0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045c2:	4390                	lw	a2,0(a5)
    800045c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045c6:	0791                	addi	a5,a5,4
    800045c8:	0711                	addi	a4,a4,4
    800045ca:	fed79ce3          	bne	a5,a3,800045c2 <initlog+0x6a>
  brelse(buf);
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	f7c080e7          	jalr	-132(ra) # 8000354a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045d6:	4505                	li	a0,1
    800045d8:	00000097          	auipc	ra,0x0
    800045dc:	ebc080e7          	jalr	-324(ra) # 80004494 <install_trans>
  log.lh.n = 0;
    800045e0:	0001d797          	auipc	a5,0x1d
    800045e4:	3a07ae23          	sw	zero,956(a5) # 8002199c <log+0x2c>
  write_head(); // clear the log
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	e30080e7          	jalr	-464(ra) # 80004418 <write_head>
}
    800045f0:	70a2                	ld	ra,40(sp)
    800045f2:	7402                	ld	s0,32(sp)
    800045f4:	64e2                	ld	s1,24(sp)
    800045f6:	6942                	ld	s2,16(sp)
    800045f8:	69a2                	ld	s3,8(sp)
    800045fa:	6145                	addi	sp,sp,48
    800045fc:	8082                	ret

00000000800045fe <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	36650513          	addi	a0,a0,870 # 80021970 <log>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5c4080e7          	jalr	1476(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000461a:	0001d497          	auipc	s1,0x1d
    8000461e:	35648493          	addi	s1,s1,854 # 80021970 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004622:	4979                	li	s2,30
    80004624:	a039                	j	80004632 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004626:	85a6                	mv	a1,s1
    80004628:	8526                	mv	a0,s1
    8000462a:	ffffe097          	auipc	ra,0xffffe
    8000462e:	ae8080e7          	jalr	-1304(ra) # 80002112 <sleep>
    if(log.committing){
    80004632:	50dc                	lw	a5,36(s1)
    80004634:	fbed                	bnez	a5,80004626 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004636:	5098                	lw	a4,32(s1)
    80004638:	2705                	addiw	a4,a4,1
    8000463a:	0007069b          	sext.w	a3,a4
    8000463e:	0027179b          	slliw	a5,a4,0x2
    80004642:	9fb9                	addw	a5,a5,a4
    80004644:	0017979b          	slliw	a5,a5,0x1
    80004648:	54d8                	lw	a4,44(s1)
    8000464a:	9fb9                	addw	a5,a5,a4
    8000464c:	00f95963          	bge	s2,a5,8000465e <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004650:	85a6                	mv	a1,s1
    80004652:	8526                	mv	a0,s1
    80004654:	ffffe097          	auipc	ra,0xffffe
    80004658:	abe080e7          	jalr	-1346(ra) # 80002112 <sleep>
    8000465c:	bfd9                	j	80004632 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	31250513          	addi	a0,a0,786 # 80021970 <log>
    80004666:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	622080e7          	jalr	1570(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004670:	60e2                	ld	ra,24(sp)
    80004672:	6442                	ld	s0,16(sp)
    80004674:	64a2                	ld	s1,8(sp)
    80004676:	6902                	ld	s2,0(sp)
    80004678:	6105                	addi	sp,sp,32
    8000467a:	8082                	ret

000000008000467c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000467c:	7139                	addi	sp,sp,-64
    8000467e:	fc06                	sd	ra,56(sp)
    80004680:	f822                	sd	s0,48(sp)
    80004682:	f426                	sd	s1,40(sp)
    80004684:	f04a                	sd	s2,32(sp)
    80004686:	ec4e                	sd	s3,24(sp)
    80004688:	e852                	sd	s4,16(sp)
    8000468a:	e456                	sd	s5,8(sp)
    8000468c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000468e:	0001d497          	auipc	s1,0x1d
    80004692:	2e248493          	addi	s1,s1,738 # 80021970 <log>
    80004696:	8526                	mv	a0,s1
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	53e080e7          	jalr	1342(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800046a0:	509c                	lw	a5,32(s1)
    800046a2:	37fd                	addiw	a5,a5,-1
    800046a4:	0007891b          	sext.w	s2,a5
    800046a8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046aa:	50dc                	lw	a5,36(s1)
    800046ac:	e7b9                	bnez	a5,800046fa <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046ae:	04091e63          	bnez	s2,8000470a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046b2:	0001d497          	auipc	s1,0x1d
    800046b6:	2be48493          	addi	s1,s1,702 # 80021970 <log>
    800046ba:	4785                	li	a5,1
    800046bc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	5ca080e7          	jalr	1482(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046c8:	54dc                	lw	a5,44(s1)
    800046ca:	06f04763          	bgtz	a5,80004738 <end_op+0xbc>
    acquire(&log.lock);
    800046ce:	0001d497          	auipc	s1,0x1d
    800046d2:	2a248493          	addi	s1,s1,674 # 80021970 <log>
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	4fe080e7          	jalr	1278(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800046e0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046e4:	8526                	mv	a0,s1
    800046e6:	ffffe097          	auipc	ra,0xffffe
    800046ea:	a90080e7          	jalr	-1392(ra) # 80002176 <wakeup>
    release(&log.lock);
    800046ee:	8526                	mv	a0,s1
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	59a080e7          	jalr	1434(ra) # 80000c8a <release>
}
    800046f8:	a03d                	j	80004726 <end_op+0xaa>
    panic("log.committing");
    800046fa:	00004517          	auipc	a0,0x4
    800046fe:	f8650513          	addi	a0,a0,-122 # 80008680 <syscalls+0x200>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	e3e080e7          	jalr	-450(ra) # 80000540 <panic>
    wakeup(&log);
    8000470a:	0001d497          	auipc	s1,0x1d
    8000470e:	26648493          	addi	s1,s1,614 # 80021970 <log>
    80004712:	8526                	mv	a0,s1
    80004714:	ffffe097          	auipc	ra,0xffffe
    80004718:	a62080e7          	jalr	-1438(ra) # 80002176 <wakeup>
  release(&log.lock);
    8000471c:	8526                	mv	a0,s1
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
}
    80004726:	70e2                	ld	ra,56(sp)
    80004728:	7442                	ld	s0,48(sp)
    8000472a:	74a2                	ld	s1,40(sp)
    8000472c:	7902                	ld	s2,32(sp)
    8000472e:	69e2                	ld	s3,24(sp)
    80004730:	6a42                	ld	s4,16(sp)
    80004732:	6aa2                	ld	s5,8(sp)
    80004734:	6121                	addi	sp,sp,64
    80004736:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004738:	0001da97          	auipc	s5,0x1d
    8000473c:	268a8a93          	addi	s5,s5,616 # 800219a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004740:	0001da17          	auipc	s4,0x1d
    80004744:	230a0a13          	addi	s4,s4,560 # 80021970 <log>
    80004748:	018a2583          	lw	a1,24(s4)
    8000474c:	012585bb          	addw	a1,a1,s2
    80004750:	2585                	addiw	a1,a1,1
    80004752:	028a2503          	lw	a0,40(s4)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	cc4080e7          	jalr	-828(ra) # 8000341a <bread>
    8000475e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004760:	000aa583          	lw	a1,0(s5)
    80004764:	028a2503          	lw	a0,40(s4)
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	cb2080e7          	jalr	-846(ra) # 8000341a <bread>
    80004770:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004772:	40000613          	li	a2,1024
    80004776:	05850593          	addi	a1,a0,88
    8000477a:	05848513          	addi	a0,s1,88
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	5b0080e7          	jalr	1456(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004786:	8526                	mv	a0,s1
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	d84080e7          	jalr	-636(ra) # 8000350c <bwrite>
    brelse(from);
    80004790:	854e                	mv	a0,s3
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	db8080e7          	jalr	-584(ra) # 8000354a <brelse>
    brelse(to);
    8000479a:	8526                	mv	a0,s1
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	dae080e7          	jalr	-594(ra) # 8000354a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a4:	2905                	addiw	s2,s2,1
    800047a6:	0a91                	addi	s5,s5,4
    800047a8:	02ca2783          	lw	a5,44(s4)
    800047ac:	f8f94ee3          	blt	s2,a5,80004748 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	c68080e7          	jalr	-920(ra) # 80004418 <write_head>
    install_trans(0); // Now install writes to home locations
    800047b8:	4501                	li	a0,0
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	cda080e7          	jalr	-806(ra) # 80004494 <install_trans>
    log.lh.n = 0;
    800047c2:	0001d797          	auipc	a5,0x1d
    800047c6:	1c07ad23          	sw	zero,474(a5) # 8002199c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047ca:	00000097          	auipc	ra,0x0
    800047ce:	c4e080e7          	jalr	-946(ra) # 80004418 <write_head>
    800047d2:	bdf5                	j	800046ce <end_op+0x52>

00000000800047d4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047d4:	1101                	addi	sp,sp,-32
    800047d6:	ec06                	sd	ra,24(sp)
    800047d8:	e822                	sd	s0,16(sp)
    800047da:	e426                	sd	s1,8(sp)
    800047dc:	e04a                	sd	s2,0(sp)
    800047de:	1000                	addi	s0,sp,32
    800047e0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047e2:	0001d917          	auipc	s2,0x1d
    800047e6:	18e90913          	addi	s2,s2,398 # 80021970 <log>
    800047ea:	854a                	mv	a0,s2
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	3ea080e7          	jalr	1002(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047f4:	02c92603          	lw	a2,44(s2)
    800047f8:	47f5                	li	a5,29
    800047fa:	06c7c563          	blt	a5,a2,80004864 <log_write+0x90>
    800047fe:	0001d797          	auipc	a5,0x1d
    80004802:	18e7a783          	lw	a5,398(a5) # 8002198c <log+0x1c>
    80004806:	37fd                	addiw	a5,a5,-1
    80004808:	04f65e63          	bge	a2,a5,80004864 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000480c:	0001d797          	auipc	a5,0x1d
    80004810:	1847a783          	lw	a5,388(a5) # 80021990 <log+0x20>
    80004814:	06f05063          	blez	a5,80004874 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004818:	4781                	li	a5,0
    8000481a:	06c05563          	blez	a2,80004884 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000481e:	44cc                	lw	a1,12(s1)
    80004820:	0001d717          	auipc	a4,0x1d
    80004824:	18070713          	addi	a4,a4,384 # 800219a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004828:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000482a:	4314                	lw	a3,0(a4)
    8000482c:	04b68c63          	beq	a3,a1,80004884 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004830:	2785                	addiw	a5,a5,1
    80004832:	0711                	addi	a4,a4,4
    80004834:	fef61be3          	bne	a2,a5,8000482a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004838:	0621                	addi	a2,a2,8
    8000483a:	060a                	slli	a2,a2,0x2
    8000483c:	0001d797          	auipc	a5,0x1d
    80004840:	13478793          	addi	a5,a5,308 # 80021970 <log>
    80004844:	97b2                	add	a5,a5,a2
    80004846:	44d8                	lw	a4,12(s1)
    80004848:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000484a:	8526                	mv	a0,s1
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	d9c080e7          	jalr	-612(ra) # 800035e8 <bpin>
    log.lh.n++;
    80004854:	0001d717          	auipc	a4,0x1d
    80004858:	11c70713          	addi	a4,a4,284 # 80021970 <log>
    8000485c:	575c                	lw	a5,44(a4)
    8000485e:	2785                	addiw	a5,a5,1
    80004860:	d75c                	sw	a5,44(a4)
    80004862:	a82d                	j	8000489c <log_write+0xc8>
    panic("too big a transaction");
    80004864:	00004517          	auipc	a0,0x4
    80004868:	e2c50513          	addi	a0,a0,-468 # 80008690 <syscalls+0x210>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	cd4080e7          	jalr	-812(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004874:	00004517          	auipc	a0,0x4
    80004878:	e3450513          	addi	a0,a0,-460 # 800086a8 <syscalls+0x228>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	cc4080e7          	jalr	-828(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004884:	00878693          	addi	a3,a5,8
    80004888:	068a                	slli	a3,a3,0x2
    8000488a:	0001d717          	auipc	a4,0x1d
    8000488e:	0e670713          	addi	a4,a4,230 # 80021970 <log>
    80004892:	9736                	add	a4,a4,a3
    80004894:	44d4                	lw	a3,12(s1)
    80004896:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004898:	faf609e3          	beq	a2,a5,8000484a <log_write+0x76>
  }
  release(&log.lock);
    8000489c:	0001d517          	auipc	a0,0x1d
    800048a0:	0d450513          	addi	a0,a0,212 # 80021970 <log>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	3e6080e7          	jalr	998(ra) # 80000c8a <release>
}
    800048ac:	60e2                	ld	ra,24(sp)
    800048ae:	6442                	ld	s0,16(sp)
    800048b0:	64a2                	ld	s1,8(sp)
    800048b2:	6902                	ld	s2,0(sp)
    800048b4:	6105                	addi	sp,sp,32
    800048b6:	8082                	ret

00000000800048b8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	e04a                	sd	s2,0(sp)
    800048c2:	1000                	addi	s0,sp,32
    800048c4:	84aa                	mv	s1,a0
    800048c6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048c8:	00004597          	auipc	a1,0x4
    800048cc:	e0058593          	addi	a1,a1,-512 # 800086c8 <syscalls+0x248>
    800048d0:	0521                	addi	a0,a0,8
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	274080e7          	jalr	628(ra) # 80000b46 <initlock>
  lk->name = name;
    800048da:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048de:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048e2:	0204a423          	sw	zero,40(s1)
}
    800048e6:	60e2                	ld	ra,24(sp)
    800048e8:	6442                	ld	s0,16(sp)
    800048ea:	64a2                	ld	s1,8(sp)
    800048ec:	6902                	ld	s2,0(sp)
    800048ee:	6105                	addi	sp,sp,32
    800048f0:	8082                	ret

00000000800048f2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048f2:	1101                	addi	sp,sp,-32
    800048f4:	ec06                	sd	ra,24(sp)
    800048f6:	e822                	sd	s0,16(sp)
    800048f8:	e426                	sd	s1,8(sp)
    800048fa:	e04a                	sd	s2,0(sp)
    800048fc:	1000                	addi	s0,sp,32
    800048fe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004900:	00850913          	addi	s2,a0,8
    80004904:	854a                	mv	a0,s2
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	2d0080e7          	jalr	720(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000490e:	409c                	lw	a5,0(s1)
    80004910:	cb89                	beqz	a5,80004922 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004912:	85ca                	mv	a1,s2
    80004914:	8526                	mv	a0,s1
    80004916:	ffffd097          	auipc	ra,0xffffd
    8000491a:	7fc080e7          	jalr	2044(ra) # 80002112 <sleep>
  while (lk->locked) {
    8000491e:	409c                	lw	a5,0(s1)
    80004920:	fbed                	bnez	a5,80004912 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004922:	4785                	li	a5,1
    80004924:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004926:	ffffd097          	auipc	ra,0xffffd
    8000492a:	086080e7          	jalr	134(ra) # 800019ac <myproc>
    8000492e:	591c                	lw	a5,48(a0)
    80004930:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004932:	854a                	mv	a0,s2
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	356080e7          	jalr	854(ra) # 80000c8a <release>
}
    8000493c:	60e2                	ld	ra,24(sp)
    8000493e:	6442                	ld	s0,16(sp)
    80004940:	64a2                	ld	s1,8(sp)
    80004942:	6902                	ld	s2,0(sp)
    80004944:	6105                	addi	sp,sp,32
    80004946:	8082                	ret

0000000080004948 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004948:	1101                	addi	sp,sp,-32
    8000494a:	ec06                	sd	ra,24(sp)
    8000494c:	e822                	sd	s0,16(sp)
    8000494e:	e426                	sd	s1,8(sp)
    80004950:	e04a                	sd	s2,0(sp)
    80004952:	1000                	addi	s0,sp,32
    80004954:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004956:	00850913          	addi	s2,a0,8
    8000495a:	854a                	mv	a0,s2
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	27a080e7          	jalr	634(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004964:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004968:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000496c:	8526                	mv	a0,s1
    8000496e:	ffffe097          	auipc	ra,0xffffe
    80004972:	808080e7          	jalr	-2040(ra) # 80002176 <wakeup>
  release(&lk->lk);
    80004976:	854a                	mv	a0,s2
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	312080e7          	jalr	786(ra) # 80000c8a <release>
}
    80004980:	60e2                	ld	ra,24(sp)
    80004982:	6442                	ld	s0,16(sp)
    80004984:	64a2                	ld	s1,8(sp)
    80004986:	6902                	ld	s2,0(sp)
    80004988:	6105                	addi	sp,sp,32
    8000498a:	8082                	ret

000000008000498c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000498c:	7179                	addi	sp,sp,-48
    8000498e:	f406                	sd	ra,40(sp)
    80004990:	f022                	sd	s0,32(sp)
    80004992:	ec26                	sd	s1,24(sp)
    80004994:	e84a                	sd	s2,16(sp)
    80004996:	e44e                	sd	s3,8(sp)
    80004998:	1800                	addi	s0,sp,48
    8000499a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000499c:	00850913          	addi	s2,a0,8
    800049a0:	854a                	mv	a0,s2
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	234080e7          	jalr	564(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049aa:	409c                	lw	a5,0(s1)
    800049ac:	ef99                	bnez	a5,800049ca <holdingsleep+0x3e>
    800049ae:	4481                	li	s1,0
  release(&lk->lk);
    800049b0:	854a                	mv	a0,s2
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	2d8080e7          	jalr	728(ra) # 80000c8a <release>
  return r;
}
    800049ba:	8526                	mv	a0,s1
    800049bc:	70a2                	ld	ra,40(sp)
    800049be:	7402                	ld	s0,32(sp)
    800049c0:	64e2                	ld	s1,24(sp)
    800049c2:	6942                	ld	s2,16(sp)
    800049c4:	69a2                	ld	s3,8(sp)
    800049c6:	6145                	addi	sp,sp,48
    800049c8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ca:	0284a983          	lw	s3,40(s1)
    800049ce:	ffffd097          	auipc	ra,0xffffd
    800049d2:	fde080e7          	jalr	-34(ra) # 800019ac <myproc>
    800049d6:	5904                	lw	s1,48(a0)
    800049d8:	413484b3          	sub	s1,s1,s3
    800049dc:	0014b493          	seqz	s1,s1
    800049e0:	bfc1                	j	800049b0 <holdingsleep+0x24>

00000000800049e2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049e2:	1141                	addi	sp,sp,-16
    800049e4:	e406                	sd	ra,8(sp)
    800049e6:	e022                	sd	s0,0(sp)
    800049e8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049ea:	00004597          	auipc	a1,0x4
    800049ee:	cee58593          	addi	a1,a1,-786 # 800086d8 <syscalls+0x258>
    800049f2:	0001d517          	auipc	a0,0x1d
    800049f6:	0c650513          	addi	a0,a0,198 # 80021ab8 <ftable>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	14c080e7          	jalr	332(ra) # 80000b46 <initlock>
}
    80004a02:	60a2                	ld	ra,8(sp)
    80004a04:	6402                	ld	s0,0(sp)
    80004a06:	0141                	addi	sp,sp,16
    80004a08:	8082                	ret

0000000080004a0a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a0a:	1101                	addi	sp,sp,-32
    80004a0c:	ec06                	sd	ra,24(sp)
    80004a0e:	e822                	sd	s0,16(sp)
    80004a10:	e426                	sd	s1,8(sp)
    80004a12:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a14:	0001d517          	auipc	a0,0x1d
    80004a18:	0a450513          	addi	a0,a0,164 # 80021ab8 <ftable>
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	1ba080e7          	jalr	442(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a24:	0001d497          	auipc	s1,0x1d
    80004a28:	0ac48493          	addi	s1,s1,172 # 80021ad0 <ftable+0x18>
    80004a2c:	0001e717          	auipc	a4,0x1e
    80004a30:	04470713          	addi	a4,a4,68 # 80022a70 <disk>
    if(f->ref == 0){
    80004a34:	40dc                	lw	a5,4(s1)
    80004a36:	cf99                	beqz	a5,80004a54 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a38:	02848493          	addi	s1,s1,40
    80004a3c:	fee49ce3          	bne	s1,a4,80004a34 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a40:	0001d517          	auipc	a0,0x1d
    80004a44:	07850513          	addi	a0,a0,120 # 80021ab8 <ftable>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	242080e7          	jalr	578(ra) # 80000c8a <release>
  return 0;
    80004a50:	4481                	li	s1,0
    80004a52:	a819                	j	80004a68 <filealloc+0x5e>
      f->ref = 1;
    80004a54:	4785                	li	a5,1
    80004a56:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a58:	0001d517          	auipc	a0,0x1d
    80004a5c:	06050513          	addi	a0,a0,96 # 80021ab8 <ftable>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	22a080e7          	jalr	554(ra) # 80000c8a <release>
}
    80004a68:	8526                	mv	a0,s1
    80004a6a:	60e2                	ld	ra,24(sp)
    80004a6c:	6442                	ld	s0,16(sp)
    80004a6e:	64a2                	ld	s1,8(sp)
    80004a70:	6105                	addi	sp,sp,32
    80004a72:	8082                	ret

0000000080004a74 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a74:	1101                	addi	sp,sp,-32
    80004a76:	ec06                	sd	ra,24(sp)
    80004a78:	e822                	sd	s0,16(sp)
    80004a7a:	e426                	sd	s1,8(sp)
    80004a7c:	1000                	addi	s0,sp,32
    80004a7e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a80:	0001d517          	auipc	a0,0x1d
    80004a84:	03850513          	addi	a0,a0,56 # 80021ab8 <ftable>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	14e080e7          	jalr	334(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a90:	40dc                	lw	a5,4(s1)
    80004a92:	02f05263          	blez	a5,80004ab6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a96:	2785                	addiw	a5,a5,1
    80004a98:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a9a:	0001d517          	auipc	a0,0x1d
    80004a9e:	01e50513          	addi	a0,a0,30 # 80021ab8 <ftable>
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	1e8080e7          	jalr	488(ra) # 80000c8a <release>
  return f;
}
    80004aaa:	8526                	mv	a0,s1
    80004aac:	60e2                	ld	ra,24(sp)
    80004aae:	6442                	ld	s0,16(sp)
    80004ab0:	64a2                	ld	s1,8(sp)
    80004ab2:	6105                	addi	sp,sp,32
    80004ab4:	8082                	ret
    panic("filedup");
    80004ab6:	00004517          	auipc	a0,0x4
    80004aba:	c2a50513          	addi	a0,a0,-982 # 800086e0 <syscalls+0x260>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	a82080e7          	jalr	-1406(ra) # 80000540 <panic>

0000000080004ac6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ac6:	7139                	addi	sp,sp,-64
    80004ac8:	fc06                	sd	ra,56(sp)
    80004aca:	f822                	sd	s0,48(sp)
    80004acc:	f426                	sd	s1,40(sp)
    80004ace:	f04a                	sd	s2,32(sp)
    80004ad0:	ec4e                	sd	s3,24(sp)
    80004ad2:	e852                	sd	s4,16(sp)
    80004ad4:	e456                	sd	s5,8(sp)
    80004ad6:	0080                	addi	s0,sp,64
    80004ad8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ada:	0001d517          	auipc	a0,0x1d
    80004ade:	fde50513          	addi	a0,a0,-34 # 80021ab8 <ftable>
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	0f4080e7          	jalr	244(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004aea:	40dc                	lw	a5,4(s1)
    80004aec:	06f05163          	blez	a5,80004b4e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004af0:	37fd                	addiw	a5,a5,-1
    80004af2:	0007871b          	sext.w	a4,a5
    80004af6:	c0dc                	sw	a5,4(s1)
    80004af8:	06e04363          	bgtz	a4,80004b5e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004afc:	0004a903          	lw	s2,0(s1)
    80004b00:	0094ca83          	lbu	s5,9(s1)
    80004b04:	0104ba03          	ld	s4,16(s1)
    80004b08:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b0c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b10:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b14:	0001d517          	auipc	a0,0x1d
    80004b18:	fa450513          	addi	a0,a0,-92 # 80021ab8 <ftable>
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	16e080e7          	jalr	366(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004b24:	4785                	li	a5,1
    80004b26:	04f90d63          	beq	s2,a5,80004b80 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b2a:	3979                	addiw	s2,s2,-2
    80004b2c:	4785                	li	a5,1
    80004b2e:	0527e063          	bltu	a5,s2,80004b6e <fileclose+0xa8>
    begin_op();
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	acc080e7          	jalr	-1332(ra) # 800045fe <begin_op>
    iput(ff.ip);
    80004b3a:	854e                	mv	a0,s3
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	2b0080e7          	jalr	688(ra) # 80003dec <iput>
    end_op();
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	b38080e7          	jalr	-1224(ra) # 8000467c <end_op>
    80004b4c:	a00d                	j	80004b6e <fileclose+0xa8>
    panic("fileclose");
    80004b4e:	00004517          	auipc	a0,0x4
    80004b52:	b9a50513          	addi	a0,a0,-1126 # 800086e8 <syscalls+0x268>
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	9ea080e7          	jalr	-1558(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004b5e:	0001d517          	auipc	a0,0x1d
    80004b62:	f5a50513          	addi	a0,a0,-166 # 80021ab8 <ftable>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	124080e7          	jalr	292(ra) # 80000c8a <release>
  }
}
    80004b6e:	70e2                	ld	ra,56(sp)
    80004b70:	7442                	ld	s0,48(sp)
    80004b72:	74a2                	ld	s1,40(sp)
    80004b74:	7902                	ld	s2,32(sp)
    80004b76:	69e2                	ld	s3,24(sp)
    80004b78:	6a42                	ld	s4,16(sp)
    80004b7a:	6aa2                	ld	s5,8(sp)
    80004b7c:	6121                	addi	sp,sp,64
    80004b7e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b80:	85d6                	mv	a1,s5
    80004b82:	8552                	mv	a0,s4
    80004b84:	00000097          	auipc	ra,0x0
    80004b88:	34c080e7          	jalr	844(ra) # 80004ed0 <pipeclose>
    80004b8c:	b7cd                	j	80004b6e <fileclose+0xa8>

0000000080004b8e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b8e:	715d                	addi	sp,sp,-80
    80004b90:	e486                	sd	ra,72(sp)
    80004b92:	e0a2                	sd	s0,64(sp)
    80004b94:	fc26                	sd	s1,56(sp)
    80004b96:	f84a                	sd	s2,48(sp)
    80004b98:	f44e                	sd	s3,40(sp)
    80004b9a:	0880                	addi	s0,sp,80
    80004b9c:	84aa                	mv	s1,a0
    80004b9e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	e0c080e7          	jalr	-500(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ba8:	409c                	lw	a5,0(s1)
    80004baa:	37f9                	addiw	a5,a5,-2
    80004bac:	4705                	li	a4,1
    80004bae:	04f76763          	bltu	a4,a5,80004bfc <filestat+0x6e>
    80004bb2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bb4:	6c88                	ld	a0,24(s1)
    80004bb6:	fffff097          	auipc	ra,0xfffff
    80004bba:	07c080e7          	jalr	124(ra) # 80003c32 <ilock>
    stati(f->ip, &st);
    80004bbe:	fb840593          	addi	a1,s0,-72
    80004bc2:	6c88                	ld	a0,24(s1)
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	2f8080e7          	jalr	760(ra) # 80003ebc <stati>
    iunlock(f->ip);
    80004bcc:	6c88                	ld	a0,24(s1)
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	126080e7          	jalr	294(ra) # 80003cf4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bd6:	46e1                	li	a3,24
    80004bd8:	fb840613          	addi	a2,s0,-72
    80004bdc:	85ce                	mv	a1,s3
    80004bde:	05093503          	ld	a0,80(s2)
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	a8a080e7          	jalr	-1398(ra) # 8000166c <copyout>
    80004bea:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bee:	60a6                	ld	ra,72(sp)
    80004bf0:	6406                	ld	s0,64(sp)
    80004bf2:	74e2                	ld	s1,56(sp)
    80004bf4:	7942                	ld	s2,48(sp)
    80004bf6:	79a2                	ld	s3,40(sp)
    80004bf8:	6161                	addi	sp,sp,80
    80004bfa:	8082                	ret
  return -1;
    80004bfc:	557d                	li	a0,-1
    80004bfe:	bfc5                	j	80004bee <filestat+0x60>

0000000080004c00 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c00:	7179                	addi	sp,sp,-48
    80004c02:	f406                	sd	ra,40(sp)
    80004c04:	f022                	sd	s0,32(sp)
    80004c06:	ec26                	sd	s1,24(sp)
    80004c08:	e84a                	sd	s2,16(sp)
    80004c0a:	e44e                	sd	s3,8(sp)
    80004c0c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c0e:	00854783          	lbu	a5,8(a0)
    80004c12:	c3d5                	beqz	a5,80004cb6 <fileread+0xb6>
    80004c14:	84aa                	mv	s1,a0
    80004c16:	89ae                	mv	s3,a1
    80004c18:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c1a:	411c                	lw	a5,0(a0)
    80004c1c:	4705                	li	a4,1
    80004c1e:	04e78963          	beq	a5,a4,80004c70 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c22:	470d                	li	a4,3
    80004c24:	04e78d63          	beq	a5,a4,80004c7e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c28:	4709                	li	a4,2
    80004c2a:	06e79e63          	bne	a5,a4,80004ca6 <fileread+0xa6>
    ilock(f->ip);
    80004c2e:	6d08                	ld	a0,24(a0)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	002080e7          	jalr	2(ra) # 80003c32 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c38:	874a                	mv	a4,s2
    80004c3a:	5094                	lw	a3,32(s1)
    80004c3c:	864e                	mv	a2,s3
    80004c3e:	4585                	li	a1,1
    80004c40:	6c88                	ld	a0,24(s1)
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	2a4080e7          	jalr	676(ra) # 80003ee6 <readi>
    80004c4a:	892a                	mv	s2,a0
    80004c4c:	00a05563          	blez	a0,80004c56 <fileread+0x56>
      f->off += r;
    80004c50:	509c                	lw	a5,32(s1)
    80004c52:	9fa9                	addw	a5,a5,a0
    80004c54:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c56:	6c88                	ld	a0,24(s1)
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	09c080e7          	jalr	156(ra) # 80003cf4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c60:	854a                	mv	a0,s2
    80004c62:	70a2                	ld	ra,40(sp)
    80004c64:	7402                	ld	s0,32(sp)
    80004c66:	64e2                	ld	s1,24(sp)
    80004c68:	6942                	ld	s2,16(sp)
    80004c6a:	69a2                	ld	s3,8(sp)
    80004c6c:	6145                	addi	sp,sp,48
    80004c6e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c70:	6908                	ld	a0,16(a0)
    80004c72:	00000097          	auipc	ra,0x0
    80004c76:	3c6080e7          	jalr	966(ra) # 80005038 <piperead>
    80004c7a:	892a                	mv	s2,a0
    80004c7c:	b7d5                	j	80004c60 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c7e:	02451783          	lh	a5,36(a0)
    80004c82:	03079693          	slli	a3,a5,0x30
    80004c86:	92c1                	srli	a3,a3,0x30
    80004c88:	4725                	li	a4,9
    80004c8a:	02d76863          	bltu	a4,a3,80004cba <fileread+0xba>
    80004c8e:	0792                	slli	a5,a5,0x4
    80004c90:	0001d717          	auipc	a4,0x1d
    80004c94:	d8870713          	addi	a4,a4,-632 # 80021a18 <devsw>
    80004c98:	97ba                	add	a5,a5,a4
    80004c9a:	639c                	ld	a5,0(a5)
    80004c9c:	c38d                	beqz	a5,80004cbe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c9e:	4505                	li	a0,1
    80004ca0:	9782                	jalr	a5
    80004ca2:	892a                	mv	s2,a0
    80004ca4:	bf75                	j	80004c60 <fileread+0x60>
    panic("fileread");
    80004ca6:	00004517          	auipc	a0,0x4
    80004caa:	a5250513          	addi	a0,a0,-1454 # 800086f8 <syscalls+0x278>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	892080e7          	jalr	-1902(ra) # 80000540 <panic>
    return -1;
    80004cb6:	597d                	li	s2,-1
    80004cb8:	b765                	j	80004c60 <fileread+0x60>
      return -1;
    80004cba:	597d                	li	s2,-1
    80004cbc:	b755                	j	80004c60 <fileread+0x60>
    80004cbe:	597d                	li	s2,-1
    80004cc0:	b745                	j	80004c60 <fileread+0x60>

0000000080004cc2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cc2:	715d                	addi	sp,sp,-80
    80004cc4:	e486                	sd	ra,72(sp)
    80004cc6:	e0a2                	sd	s0,64(sp)
    80004cc8:	fc26                	sd	s1,56(sp)
    80004cca:	f84a                	sd	s2,48(sp)
    80004ccc:	f44e                	sd	s3,40(sp)
    80004cce:	f052                	sd	s4,32(sp)
    80004cd0:	ec56                	sd	s5,24(sp)
    80004cd2:	e85a                	sd	s6,16(sp)
    80004cd4:	e45e                	sd	s7,8(sp)
    80004cd6:	e062                	sd	s8,0(sp)
    80004cd8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cda:	00954783          	lbu	a5,9(a0)
    80004cde:	10078663          	beqz	a5,80004dea <filewrite+0x128>
    80004ce2:	892a                	mv	s2,a0
    80004ce4:	8b2e                	mv	s6,a1
    80004ce6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ce8:	411c                	lw	a5,0(a0)
    80004cea:	4705                	li	a4,1
    80004cec:	02e78263          	beq	a5,a4,80004d10 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cf0:	470d                	li	a4,3
    80004cf2:	02e78663          	beq	a5,a4,80004d1e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cf6:	4709                	li	a4,2
    80004cf8:	0ee79163          	bne	a5,a4,80004dda <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cfc:	0ac05d63          	blez	a2,80004db6 <filewrite+0xf4>
    int i = 0;
    80004d00:	4981                	li	s3,0
    80004d02:	6b85                	lui	s7,0x1
    80004d04:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d08:	6c05                	lui	s8,0x1
    80004d0a:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d0e:	a861                	j	80004da6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d10:	6908                	ld	a0,16(a0)
    80004d12:	00000097          	auipc	ra,0x0
    80004d16:	22e080e7          	jalr	558(ra) # 80004f40 <pipewrite>
    80004d1a:	8a2a                	mv	s4,a0
    80004d1c:	a045                	j	80004dbc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d1e:	02451783          	lh	a5,36(a0)
    80004d22:	03079693          	slli	a3,a5,0x30
    80004d26:	92c1                	srli	a3,a3,0x30
    80004d28:	4725                	li	a4,9
    80004d2a:	0cd76263          	bltu	a4,a3,80004dee <filewrite+0x12c>
    80004d2e:	0792                	slli	a5,a5,0x4
    80004d30:	0001d717          	auipc	a4,0x1d
    80004d34:	ce870713          	addi	a4,a4,-792 # 80021a18 <devsw>
    80004d38:	97ba                	add	a5,a5,a4
    80004d3a:	679c                	ld	a5,8(a5)
    80004d3c:	cbdd                	beqz	a5,80004df2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d3e:	4505                	li	a0,1
    80004d40:	9782                	jalr	a5
    80004d42:	8a2a                	mv	s4,a0
    80004d44:	a8a5                	j	80004dbc <filewrite+0xfa>
    80004d46:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d4a:	00000097          	auipc	ra,0x0
    80004d4e:	8b4080e7          	jalr	-1868(ra) # 800045fe <begin_op>
      ilock(f->ip);
    80004d52:	01893503          	ld	a0,24(s2)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	edc080e7          	jalr	-292(ra) # 80003c32 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d5e:	8756                	mv	a4,s5
    80004d60:	02092683          	lw	a3,32(s2)
    80004d64:	01698633          	add	a2,s3,s6
    80004d68:	4585                	li	a1,1
    80004d6a:	01893503          	ld	a0,24(s2)
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	270080e7          	jalr	624(ra) # 80003fde <writei>
    80004d76:	84aa                	mv	s1,a0
    80004d78:	00a05763          	blez	a0,80004d86 <filewrite+0xc4>
        f->off += r;
    80004d7c:	02092783          	lw	a5,32(s2)
    80004d80:	9fa9                	addw	a5,a5,a0
    80004d82:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d86:	01893503          	ld	a0,24(s2)
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	f6a080e7          	jalr	-150(ra) # 80003cf4 <iunlock>
      end_op();
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	8ea080e7          	jalr	-1814(ra) # 8000467c <end_op>

      if(r != n1){
    80004d9a:	009a9f63          	bne	s5,s1,80004db8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d9e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004da2:	0149db63          	bge	s3,s4,80004db8 <filewrite+0xf6>
      int n1 = n - i;
    80004da6:	413a04bb          	subw	s1,s4,s3
    80004daa:	0004879b          	sext.w	a5,s1
    80004dae:	f8fbdce3          	bge	s7,a5,80004d46 <filewrite+0x84>
    80004db2:	84e2                	mv	s1,s8
    80004db4:	bf49                	j	80004d46 <filewrite+0x84>
    int i = 0;
    80004db6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004db8:	013a1f63          	bne	s4,s3,80004dd6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dbc:	8552                	mv	a0,s4
    80004dbe:	60a6                	ld	ra,72(sp)
    80004dc0:	6406                	ld	s0,64(sp)
    80004dc2:	74e2                	ld	s1,56(sp)
    80004dc4:	7942                	ld	s2,48(sp)
    80004dc6:	79a2                	ld	s3,40(sp)
    80004dc8:	7a02                	ld	s4,32(sp)
    80004dca:	6ae2                	ld	s5,24(sp)
    80004dcc:	6b42                	ld	s6,16(sp)
    80004dce:	6ba2                	ld	s7,8(sp)
    80004dd0:	6c02                	ld	s8,0(sp)
    80004dd2:	6161                	addi	sp,sp,80
    80004dd4:	8082                	ret
    ret = (i == n ? n : -1);
    80004dd6:	5a7d                	li	s4,-1
    80004dd8:	b7d5                	j	80004dbc <filewrite+0xfa>
    panic("filewrite");
    80004dda:	00004517          	auipc	a0,0x4
    80004dde:	92e50513          	addi	a0,a0,-1746 # 80008708 <syscalls+0x288>
    80004de2:	ffffb097          	auipc	ra,0xffffb
    80004de6:	75e080e7          	jalr	1886(ra) # 80000540 <panic>
    return -1;
    80004dea:	5a7d                	li	s4,-1
    80004dec:	bfc1                	j	80004dbc <filewrite+0xfa>
      return -1;
    80004dee:	5a7d                	li	s4,-1
    80004df0:	b7f1                	j	80004dbc <filewrite+0xfa>
    80004df2:	5a7d                	li	s4,-1
    80004df4:	b7e1                	j	80004dbc <filewrite+0xfa>

0000000080004df6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004df6:	7179                	addi	sp,sp,-48
    80004df8:	f406                	sd	ra,40(sp)
    80004dfa:	f022                	sd	s0,32(sp)
    80004dfc:	ec26                	sd	s1,24(sp)
    80004dfe:	e84a                	sd	s2,16(sp)
    80004e00:	e44e                	sd	s3,8(sp)
    80004e02:	e052                	sd	s4,0(sp)
    80004e04:	1800                	addi	s0,sp,48
    80004e06:	84aa                	mv	s1,a0
    80004e08:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e0a:	0005b023          	sd	zero,0(a1)
    80004e0e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e12:	00000097          	auipc	ra,0x0
    80004e16:	bf8080e7          	jalr	-1032(ra) # 80004a0a <filealloc>
    80004e1a:	e088                	sd	a0,0(s1)
    80004e1c:	c551                	beqz	a0,80004ea8 <pipealloc+0xb2>
    80004e1e:	00000097          	auipc	ra,0x0
    80004e22:	bec080e7          	jalr	-1044(ra) # 80004a0a <filealloc>
    80004e26:	00aa3023          	sd	a0,0(s4)
    80004e2a:	c92d                	beqz	a0,80004e9c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	cba080e7          	jalr	-838(ra) # 80000ae6 <kalloc>
    80004e34:	892a                	mv	s2,a0
    80004e36:	c125                	beqz	a0,80004e96 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e38:	4985                	li	s3,1
    80004e3a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e3e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e42:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e46:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e4a:	00004597          	auipc	a1,0x4
    80004e4e:	8ce58593          	addi	a1,a1,-1842 # 80008718 <syscalls+0x298>
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	cf4080e7          	jalr	-780(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004e5a:	609c                	ld	a5,0(s1)
    80004e5c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e60:	609c                	ld	a5,0(s1)
    80004e62:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e66:	609c                	ld	a5,0(s1)
    80004e68:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e6c:	609c                	ld	a5,0(s1)
    80004e6e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e72:	000a3783          	ld	a5,0(s4)
    80004e76:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e7a:	000a3783          	ld	a5,0(s4)
    80004e7e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e82:	000a3783          	ld	a5,0(s4)
    80004e86:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e8a:	000a3783          	ld	a5,0(s4)
    80004e8e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e92:	4501                	li	a0,0
    80004e94:	a025                	j	80004ebc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e96:	6088                	ld	a0,0(s1)
    80004e98:	e501                	bnez	a0,80004ea0 <pipealloc+0xaa>
    80004e9a:	a039                	j	80004ea8 <pipealloc+0xb2>
    80004e9c:	6088                	ld	a0,0(s1)
    80004e9e:	c51d                	beqz	a0,80004ecc <pipealloc+0xd6>
    fileclose(*f0);
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	c26080e7          	jalr	-986(ra) # 80004ac6 <fileclose>
  if(*f1)
    80004ea8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eac:	557d                	li	a0,-1
  if(*f1)
    80004eae:	c799                	beqz	a5,80004ebc <pipealloc+0xc6>
    fileclose(*f1);
    80004eb0:	853e                	mv	a0,a5
    80004eb2:	00000097          	auipc	ra,0x0
    80004eb6:	c14080e7          	jalr	-1004(ra) # 80004ac6 <fileclose>
  return -1;
    80004eba:	557d                	li	a0,-1
}
    80004ebc:	70a2                	ld	ra,40(sp)
    80004ebe:	7402                	ld	s0,32(sp)
    80004ec0:	64e2                	ld	s1,24(sp)
    80004ec2:	6942                	ld	s2,16(sp)
    80004ec4:	69a2                	ld	s3,8(sp)
    80004ec6:	6a02                	ld	s4,0(sp)
    80004ec8:	6145                	addi	sp,sp,48
    80004eca:	8082                	ret
  return -1;
    80004ecc:	557d                	li	a0,-1
    80004ece:	b7fd                	j	80004ebc <pipealloc+0xc6>

0000000080004ed0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ed0:	1101                	addi	sp,sp,-32
    80004ed2:	ec06                	sd	ra,24(sp)
    80004ed4:	e822                	sd	s0,16(sp)
    80004ed6:	e426                	sd	s1,8(sp)
    80004ed8:	e04a                	sd	s2,0(sp)
    80004eda:	1000                	addi	s0,sp,32
    80004edc:	84aa                	mv	s1,a0
    80004ede:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	cf6080e7          	jalr	-778(ra) # 80000bd6 <acquire>
  if(writable){
    80004ee8:	02090d63          	beqz	s2,80004f22 <pipeclose+0x52>
    pi->writeopen = 0;
    80004eec:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ef0:	21848513          	addi	a0,s1,536
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	282080e7          	jalr	642(ra) # 80002176 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004efc:	2204b783          	ld	a5,544(s1)
    80004f00:	eb95                	bnez	a5,80004f34 <pipeclose+0x64>
    release(&pi->lock);
    80004f02:	8526                	mv	a0,s1
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	d86080e7          	jalr	-634(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	ada080e7          	jalr	-1318(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004f16:	60e2                	ld	ra,24(sp)
    80004f18:	6442                	ld	s0,16(sp)
    80004f1a:	64a2                	ld	s1,8(sp)
    80004f1c:	6902                	ld	s2,0(sp)
    80004f1e:	6105                	addi	sp,sp,32
    80004f20:	8082                	ret
    pi->readopen = 0;
    80004f22:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f26:	21c48513          	addi	a0,s1,540
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	24c080e7          	jalr	588(ra) # 80002176 <wakeup>
    80004f32:	b7e9                	j	80004efc <pipeclose+0x2c>
    release(&pi->lock);
    80004f34:	8526                	mv	a0,s1
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	d54080e7          	jalr	-684(ra) # 80000c8a <release>
}
    80004f3e:	bfe1                	j	80004f16 <pipeclose+0x46>

0000000080004f40 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f40:	711d                	addi	sp,sp,-96
    80004f42:	ec86                	sd	ra,88(sp)
    80004f44:	e8a2                	sd	s0,80(sp)
    80004f46:	e4a6                	sd	s1,72(sp)
    80004f48:	e0ca                	sd	s2,64(sp)
    80004f4a:	fc4e                	sd	s3,56(sp)
    80004f4c:	f852                	sd	s4,48(sp)
    80004f4e:	f456                	sd	s5,40(sp)
    80004f50:	f05a                	sd	s6,32(sp)
    80004f52:	ec5e                	sd	s7,24(sp)
    80004f54:	e862                	sd	s8,16(sp)
    80004f56:	1080                	addi	s0,sp,96
    80004f58:	84aa                	mv	s1,a0
    80004f5a:	8aae                	mv	s5,a1
    80004f5c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	a4e080e7          	jalr	-1458(ra) # 800019ac <myproc>
    80004f66:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f68:	8526                	mv	a0,s1
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	c6c080e7          	jalr	-916(ra) # 80000bd6 <acquire>
  while(i < n){
    80004f72:	0b405663          	blez	s4,8000501e <pipewrite+0xde>
  int i = 0;
    80004f76:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f78:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f7a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f7e:	21c48b93          	addi	s7,s1,540
    80004f82:	a089                	j	80004fc4 <pipewrite+0x84>
      release(&pi->lock);
    80004f84:	8526                	mv	a0,s1
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	d04080e7          	jalr	-764(ra) # 80000c8a <release>
      return -1;
    80004f8e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f90:	854a                	mv	a0,s2
    80004f92:	60e6                	ld	ra,88(sp)
    80004f94:	6446                	ld	s0,80(sp)
    80004f96:	64a6                	ld	s1,72(sp)
    80004f98:	6906                	ld	s2,64(sp)
    80004f9a:	79e2                	ld	s3,56(sp)
    80004f9c:	7a42                	ld	s4,48(sp)
    80004f9e:	7aa2                	ld	s5,40(sp)
    80004fa0:	7b02                	ld	s6,32(sp)
    80004fa2:	6be2                	ld	s7,24(sp)
    80004fa4:	6c42                	ld	s8,16(sp)
    80004fa6:	6125                	addi	sp,sp,96
    80004fa8:	8082                	ret
      wakeup(&pi->nread);
    80004faa:	8562                	mv	a0,s8
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	1ca080e7          	jalr	458(ra) # 80002176 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fb4:	85a6                	mv	a1,s1
    80004fb6:	855e                	mv	a0,s7
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	15a080e7          	jalr	346(ra) # 80002112 <sleep>
  while(i < n){
    80004fc0:	07495063          	bge	s2,s4,80005020 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fc4:	2204a783          	lw	a5,544(s1)
    80004fc8:	dfd5                	beqz	a5,80004f84 <pipewrite+0x44>
    80004fca:	854e                	mv	a0,s3
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	3fa080e7          	jalr	1018(ra) # 800023c6 <killed>
    80004fd4:	f945                	bnez	a0,80004f84 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fd6:	2184a783          	lw	a5,536(s1)
    80004fda:	21c4a703          	lw	a4,540(s1)
    80004fde:	2007879b          	addiw	a5,a5,512
    80004fe2:	fcf704e3          	beq	a4,a5,80004faa <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fe6:	4685                	li	a3,1
    80004fe8:	01590633          	add	a2,s2,s5
    80004fec:	faf40593          	addi	a1,s0,-81
    80004ff0:	0509b503          	ld	a0,80(s3)
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	704080e7          	jalr	1796(ra) # 800016f8 <copyin>
    80004ffc:	03650263          	beq	a0,s6,80005020 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005000:	21c4a783          	lw	a5,540(s1)
    80005004:	0017871b          	addiw	a4,a5,1
    80005008:	20e4ae23          	sw	a4,540(s1)
    8000500c:	1ff7f793          	andi	a5,a5,511
    80005010:	97a6                	add	a5,a5,s1
    80005012:	faf44703          	lbu	a4,-81(s0)
    80005016:	00e78c23          	sb	a4,24(a5)
      i++;
    8000501a:	2905                	addiw	s2,s2,1
    8000501c:	b755                	j	80004fc0 <pipewrite+0x80>
  int i = 0;
    8000501e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005020:	21848513          	addi	a0,s1,536
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	152080e7          	jalr	338(ra) # 80002176 <wakeup>
  release(&pi->lock);
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	c5c080e7          	jalr	-932(ra) # 80000c8a <release>
  return i;
    80005036:	bfa9                	j	80004f90 <pipewrite+0x50>

0000000080005038 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005038:	715d                	addi	sp,sp,-80
    8000503a:	e486                	sd	ra,72(sp)
    8000503c:	e0a2                	sd	s0,64(sp)
    8000503e:	fc26                	sd	s1,56(sp)
    80005040:	f84a                	sd	s2,48(sp)
    80005042:	f44e                	sd	s3,40(sp)
    80005044:	f052                	sd	s4,32(sp)
    80005046:	ec56                	sd	s5,24(sp)
    80005048:	e85a                	sd	s6,16(sp)
    8000504a:	0880                	addi	s0,sp,80
    8000504c:	84aa                	mv	s1,a0
    8000504e:	892e                	mv	s2,a1
    80005050:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	95a080e7          	jalr	-1702(ra) # 800019ac <myproc>
    8000505a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	b78080e7          	jalr	-1160(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005066:	2184a703          	lw	a4,536(s1)
    8000506a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000506e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005072:	02f71763          	bne	a4,a5,800050a0 <piperead+0x68>
    80005076:	2244a783          	lw	a5,548(s1)
    8000507a:	c39d                	beqz	a5,800050a0 <piperead+0x68>
    if(killed(pr)){
    8000507c:	8552                	mv	a0,s4
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	348080e7          	jalr	840(ra) # 800023c6 <killed>
    80005086:	e949                	bnez	a0,80005118 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005088:	85a6                	mv	a1,s1
    8000508a:	854e                	mv	a0,s3
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	086080e7          	jalr	134(ra) # 80002112 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005094:	2184a703          	lw	a4,536(s1)
    80005098:	21c4a783          	lw	a5,540(s1)
    8000509c:	fcf70de3          	beq	a4,a5,80005076 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050a0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050a2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050a4:	05505463          	blez	s5,800050ec <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800050a8:	2184a783          	lw	a5,536(s1)
    800050ac:	21c4a703          	lw	a4,540(s1)
    800050b0:	02f70e63          	beq	a4,a5,800050ec <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050b4:	0017871b          	addiw	a4,a5,1
    800050b8:	20e4ac23          	sw	a4,536(s1)
    800050bc:	1ff7f793          	andi	a5,a5,511
    800050c0:	97a6                	add	a5,a5,s1
    800050c2:	0187c783          	lbu	a5,24(a5)
    800050c6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050ca:	4685                	li	a3,1
    800050cc:	fbf40613          	addi	a2,s0,-65
    800050d0:	85ca                	mv	a1,s2
    800050d2:	050a3503          	ld	a0,80(s4)
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	596080e7          	jalr	1430(ra) # 8000166c <copyout>
    800050de:	01650763          	beq	a0,s6,800050ec <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050e2:	2985                	addiw	s3,s3,1
    800050e4:	0905                	addi	s2,s2,1
    800050e6:	fd3a91e3          	bne	s5,s3,800050a8 <piperead+0x70>
    800050ea:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050ec:	21c48513          	addi	a0,s1,540
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	086080e7          	jalr	134(ra) # 80002176 <wakeup>
  release(&pi->lock);
    800050f8:	8526                	mv	a0,s1
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	b90080e7          	jalr	-1136(ra) # 80000c8a <release>
  return i;
}
    80005102:	854e                	mv	a0,s3
    80005104:	60a6                	ld	ra,72(sp)
    80005106:	6406                	ld	s0,64(sp)
    80005108:	74e2                	ld	s1,56(sp)
    8000510a:	7942                	ld	s2,48(sp)
    8000510c:	79a2                	ld	s3,40(sp)
    8000510e:	7a02                	ld	s4,32(sp)
    80005110:	6ae2                	ld	s5,24(sp)
    80005112:	6b42                	ld	s6,16(sp)
    80005114:	6161                	addi	sp,sp,80
    80005116:	8082                	ret
      release(&pi->lock);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	b70080e7          	jalr	-1168(ra) # 80000c8a <release>
      return -1;
    80005122:	59fd                	li	s3,-1
    80005124:	bff9                	j	80005102 <piperead+0xca>

0000000080005126 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005126:	1141                	addi	sp,sp,-16
    80005128:	e422                	sd	s0,8(sp)
    8000512a:	0800                	addi	s0,sp,16
    8000512c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000512e:	8905                	andi	a0,a0,1
    80005130:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005132:	8b89                	andi	a5,a5,2
    80005134:	c399                	beqz	a5,8000513a <flags2perm+0x14>
      perm |= PTE_W;
    80005136:	00456513          	ori	a0,a0,4
    return perm;
}
    8000513a:	6422                	ld	s0,8(sp)
    8000513c:	0141                	addi	sp,sp,16
    8000513e:	8082                	ret

0000000080005140 <exec>:

int
exec(char *path, char **argv)
{
    80005140:	de010113          	addi	sp,sp,-544
    80005144:	20113c23          	sd	ra,536(sp)
    80005148:	20813823          	sd	s0,528(sp)
    8000514c:	20913423          	sd	s1,520(sp)
    80005150:	21213023          	sd	s2,512(sp)
    80005154:	ffce                	sd	s3,504(sp)
    80005156:	fbd2                	sd	s4,496(sp)
    80005158:	f7d6                	sd	s5,488(sp)
    8000515a:	f3da                	sd	s6,480(sp)
    8000515c:	efde                	sd	s7,472(sp)
    8000515e:	ebe2                	sd	s8,464(sp)
    80005160:	e7e6                	sd	s9,456(sp)
    80005162:	e3ea                	sd	s10,448(sp)
    80005164:	ff6e                	sd	s11,440(sp)
    80005166:	1400                	addi	s0,sp,544
    80005168:	892a                	mv	s2,a0
    8000516a:	dea43423          	sd	a0,-536(s0)
    8000516e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	83a080e7          	jalr	-1990(ra) # 800019ac <myproc>
    8000517a:	84aa                	mv	s1,a0

  begin_op();
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	482080e7          	jalr	1154(ra) # 800045fe <begin_op>

  if((ip = namei(path)) == 0){
    80005184:	854a                	mv	a0,s2
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	258080e7          	jalr	600(ra) # 800043de <namei>
    8000518e:	c93d                	beqz	a0,80005204 <exec+0xc4>
    80005190:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	aa0080e7          	jalr	-1376(ra) # 80003c32 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000519a:	04000713          	li	a4,64
    8000519e:	4681                	li	a3,0
    800051a0:	e5040613          	addi	a2,s0,-432
    800051a4:	4581                	li	a1,0
    800051a6:	8556                	mv	a0,s5
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	d3e080e7          	jalr	-706(ra) # 80003ee6 <readi>
    800051b0:	04000793          	li	a5,64
    800051b4:	00f51a63          	bne	a0,a5,800051c8 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051b8:	e5042703          	lw	a4,-432(s0)
    800051bc:	464c47b7          	lui	a5,0x464c4
    800051c0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051c4:	04f70663          	beq	a4,a5,80005210 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051c8:	8556                	mv	a0,s5
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	cca080e7          	jalr	-822(ra) # 80003e94 <iunlockput>
    end_op();
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	4aa080e7          	jalr	1194(ra) # 8000467c <end_op>
  }
  return -1;
    800051da:	557d                	li	a0,-1
}
    800051dc:	21813083          	ld	ra,536(sp)
    800051e0:	21013403          	ld	s0,528(sp)
    800051e4:	20813483          	ld	s1,520(sp)
    800051e8:	20013903          	ld	s2,512(sp)
    800051ec:	79fe                	ld	s3,504(sp)
    800051ee:	7a5e                	ld	s4,496(sp)
    800051f0:	7abe                	ld	s5,488(sp)
    800051f2:	7b1e                	ld	s6,480(sp)
    800051f4:	6bfe                	ld	s7,472(sp)
    800051f6:	6c5e                	ld	s8,464(sp)
    800051f8:	6cbe                	ld	s9,456(sp)
    800051fa:	6d1e                	ld	s10,448(sp)
    800051fc:	7dfa                	ld	s11,440(sp)
    800051fe:	22010113          	addi	sp,sp,544
    80005202:	8082                	ret
    end_op();
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	478080e7          	jalr	1144(ra) # 8000467c <end_op>
    return -1;
    8000520c:	557d                	li	a0,-1
    8000520e:	b7f9                	j	800051dc <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005210:	8526                	mv	a0,s1
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	85e080e7          	jalr	-1954(ra) # 80001a70 <proc_pagetable>
    8000521a:	8b2a                	mv	s6,a0
    8000521c:	d555                	beqz	a0,800051c8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000521e:	e7042783          	lw	a5,-400(s0)
    80005222:	e8845703          	lhu	a4,-376(s0)
    80005226:	c735                	beqz	a4,80005292 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005228:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000522a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000522e:	6a05                	lui	s4,0x1
    80005230:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005234:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005238:	6d85                	lui	s11,0x1
    8000523a:	7d7d                	lui	s10,0xfffff
    8000523c:	ac3d                	j	8000547a <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000523e:	00003517          	auipc	a0,0x3
    80005242:	4e250513          	addi	a0,a0,1250 # 80008720 <syscalls+0x2a0>
    80005246:	ffffb097          	auipc	ra,0xffffb
    8000524a:	2fa080e7          	jalr	762(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000524e:	874a                	mv	a4,s2
    80005250:	009c86bb          	addw	a3,s9,s1
    80005254:	4581                	li	a1,0
    80005256:	8556                	mv	a0,s5
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	c8e080e7          	jalr	-882(ra) # 80003ee6 <readi>
    80005260:	2501                	sext.w	a0,a0
    80005262:	1aa91963          	bne	s2,a0,80005414 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005266:	009d84bb          	addw	s1,s11,s1
    8000526a:	013d09bb          	addw	s3,s10,s3
    8000526e:	1f74f663          	bgeu	s1,s7,8000545a <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005272:	02049593          	slli	a1,s1,0x20
    80005276:	9181                	srli	a1,a1,0x20
    80005278:	95e2                	add	a1,a1,s8
    8000527a:	855a                	mv	a0,s6
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	de0080e7          	jalr	-544(ra) # 8000105c <walkaddr>
    80005284:	862a                	mv	a2,a0
    if(pa == 0)
    80005286:	dd45                	beqz	a0,8000523e <exec+0xfe>
      n = PGSIZE;
    80005288:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000528a:	fd49f2e3          	bgeu	s3,s4,8000524e <exec+0x10e>
      n = sz - i;
    8000528e:	894e                	mv	s2,s3
    80005290:	bf7d                	j	8000524e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005292:	4901                	li	s2,0
  iunlockput(ip);
    80005294:	8556                	mv	a0,s5
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	bfe080e7          	jalr	-1026(ra) # 80003e94 <iunlockput>
  end_op();
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	3de080e7          	jalr	990(ra) # 8000467c <end_op>
  p = myproc();
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	706080e7          	jalr	1798(ra) # 800019ac <myproc>
    800052ae:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052b0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052b4:	6785                	lui	a5,0x1
    800052b6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800052b8:	97ca                	add	a5,a5,s2
    800052ba:	777d                	lui	a4,0xfffff
    800052bc:	8ff9                	and	a5,a5,a4
    800052be:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052c2:	4691                	li	a3,4
    800052c4:	6609                	lui	a2,0x2
    800052c6:	963e                	add	a2,a2,a5
    800052c8:	85be                	mv	a1,a5
    800052ca:	855a                	mv	a0,s6
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	144080e7          	jalr	324(ra) # 80001410 <uvmalloc>
    800052d4:	8c2a                	mv	s8,a0
  ip = 0;
    800052d6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052d8:	12050e63          	beqz	a0,80005414 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052dc:	75f9                	lui	a1,0xffffe
    800052de:	95aa                	add	a1,a1,a0
    800052e0:	855a                	mv	a0,s6
    800052e2:	ffffc097          	auipc	ra,0xffffc
    800052e6:	358080e7          	jalr	856(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800052ea:	7afd                	lui	s5,0xfffff
    800052ec:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800052ee:	df043783          	ld	a5,-528(s0)
    800052f2:	6388                	ld	a0,0(a5)
    800052f4:	c925                	beqz	a0,80005364 <exec+0x224>
    800052f6:	e9040993          	addi	s3,s0,-368
    800052fa:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052fe:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005300:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	b4c080e7          	jalr	-1204(ra) # 80000e4e <strlen>
    8000530a:	0015079b          	addiw	a5,a0,1
    8000530e:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005312:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005316:	13596663          	bltu	s2,s5,80005442 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000531a:	df043d83          	ld	s11,-528(s0)
    8000531e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005322:	8552                	mv	a0,s4
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	b2a080e7          	jalr	-1238(ra) # 80000e4e <strlen>
    8000532c:	0015069b          	addiw	a3,a0,1
    80005330:	8652                	mv	a2,s4
    80005332:	85ca                	mv	a1,s2
    80005334:	855a                	mv	a0,s6
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	336080e7          	jalr	822(ra) # 8000166c <copyout>
    8000533e:	10054663          	bltz	a0,8000544a <exec+0x30a>
    ustack[argc] = sp;
    80005342:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005346:	0485                	addi	s1,s1,1
    80005348:	008d8793          	addi	a5,s11,8
    8000534c:	def43823          	sd	a5,-528(s0)
    80005350:	008db503          	ld	a0,8(s11)
    80005354:	c911                	beqz	a0,80005368 <exec+0x228>
    if(argc >= MAXARG)
    80005356:	09a1                	addi	s3,s3,8
    80005358:	fb3c95e3          	bne	s9,s3,80005302 <exec+0x1c2>
  sz = sz1;
    8000535c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005360:	4a81                	li	s5,0
    80005362:	a84d                	j	80005414 <exec+0x2d4>
  sp = sz;
    80005364:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005366:	4481                	li	s1,0
  ustack[argc] = 0;
    80005368:	00349793          	slli	a5,s1,0x3
    8000536c:	f9078793          	addi	a5,a5,-112
    80005370:	97a2                	add	a5,a5,s0
    80005372:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005376:	00148693          	addi	a3,s1,1
    8000537a:	068e                	slli	a3,a3,0x3
    8000537c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005380:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005384:	01597663          	bgeu	s2,s5,80005390 <exec+0x250>
  sz = sz1;
    80005388:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000538c:	4a81                	li	s5,0
    8000538e:	a059                	j	80005414 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005390:	e9040613          	addi	a2,s0,-368
    80005394:	85ca                	mv	a1,s2
    80005396:	855a                	mv	a0,s6
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800053a0:	0a054963          	bltz	a0,80005452 <exec+0x312>
  p->trapframe->a1 = sp;
    800053a4:	058bb783          	ld	a5,88(s7)
    800053a8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053ac:	de843783          	ld	a5,-536(s0)
    800053b0:	0007c703          	lbu	a4,0(a5)
    800053b4:	cf11                	beqz	a4,800053d0 <exec+0x290>
    800053b6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053b8:	02f00693          	li	a3,47
    800053bc:	a039                	j	800053ca <exec+0x28a>
      last = s+1;
    800053be:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053c2:	0785                	addi	a5,a5,1
    800053c4:	fff7c703          	lbu	a4,-1(a5)
    800053c8:	c701                	beqz	a4,800053d0 <exec+0x290>
    if(*s == '/')
    800053ca:	fed71ce3          	bne	a4,a3,800053c2 <exec+0x282>
    800053ce:	bfc5                	j	800053be <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800053d0:	4641                	li	a2,16
    800053d2:	de843583          	ld	a1,-536(s0)
    800053d6:	158b8513          	addi	a0,s7,344
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	a42080e7          	jalr	-1470(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800053e2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800053e6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800053ea:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053ee:	058bb783          	ld	a5,88(s7)
    800053f2:	e6843703          	ld	a4,-408(s0)
    800053f6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053f8:	058bb783          	ld	a5,88(s7)
    800053fc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005400:	85ea                	mv	a1,s10
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	70a080e7          	jalr	1802(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000540a:	0004851b          	sext.w	a0,s1
    8000540e:	b3f9                	j	800051dc <exec+0x9c>
    80005410:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005414:	df843583          	ld	a1,-520(s0)
    80005418:	855a                	mv	a0,s6
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	6f2080e7          	jalr	1778(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005422:	da0a93e3          	bnez	s5,800051c8 <exec+0x88>
  return -1;
    80005426:	557d                	li	a0,-1
    80005428:	bb55                	j	800051dc <exec+0x9c>
    8000542a:	df243c23          	sd	s2,-520(s0)
    8000542e:	b7dd                	j	80005414 <exec+0x2d4>
    80005430:	df243c23          	sd	s2,-520(s0)
    80005434:	b7c5                	j	80005414 <exec+0x2d4>
    80005436:	df243c23          	sd	s2,-520(s0)
    8000543a:	bfe9                	j	80005414 <exec+0x2d4>
    8000543c:	df243c23          	sd	s2,-520(s0)
    80005440:	bfd1                	j	80005414 <exec+0x2d4>
  sz = sz1;
    80005442:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005446:	4a81                	li	s5,0
    80005448:	b7f1                	j	80005414 <exec+0x2d4>
  sz = sz1;
    8000544a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000544e:	4a81                	li	s5,0
    80005450:	b7d1                	j	80005414 <exec+0x2d4>
  sz = sz1;
    80005452:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005456:	4a81                	li	s5,0
    80005458:	bf75                	j	80005414 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000545a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000545e:	e0843783          	ld	a5,-504(s0)
    80005462:	0017869b          	addiw	a3,a5,1
    80005466:	e0d43423          	sd	a3,-504(s0)
    8000546a:	e0043783          	ld	a5,-512(s0)
    8000546e:	0387879b          	addiw	a5,a5,56
    80005472:	e8845703          	lhu	a4,-376(s0)
    80005476:	e0e6dfe3          	bge	a3,a4,80005294 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000547a:	2781                	sext.w	a5,a5
    8000547c:	e0f43023          	sd	a5,-512(s0)
    80005480:	03800713          	li	a4,56
    80005484:	86be                	mv	a3,a5
    80005486:	e1840613          	addi	a2,s0,-488
    8000548a:	4581                	li	a1,0
    8000548c:	8556                	mv	a0,s5
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	a58080e7          	jalr	-1448(ra) # 80003ee6 <readi>
    80005496:	03800793          	li	a5,56
    8000549a:	f6f51be3          	bne	a0,a5,80005410 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000549e:	e1842783          	lw	a5,-488(s0)
    800054a2:	4705                	li	a4,1
    800054a4:	fae79de3          	bne	a5,a4,8000545e <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800054a8:	e4043483          	ld	s1,-448(s0)
    800054ac:	e3843783          	ld	a5,-456(s0)
    800054b0:	f6f4ede3          	bltu	s1,a5,8000542a <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054b4:	e2843783          	ld	a5,-472(s0)
    800054b8:	94be                	add	s1,s1,a5
    800054ba:	f6f4ebe3          	bltu	s1,a5,80005430 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800054be:	de043703          	ld	a4,-544(s0)
    800054c2:	8ff9                	and	a5,a5,a4
    800054c4:	fbad                	bnez	a5,80005436 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054c6:	e1c42503          	lw	a0,-484(s0)
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	c5c080e7          	jalr	-932(ra) # 80005126 <flags2perm>
    800054d2:	86aa                	mv	a3,a0
    800054d4:	8626                	mv	a2,s1
    800054d6:	85ca                	mv	a1,s2
    800054d8:	855a                	mv	a0,s6
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	f36080e7          	jalr	-202(ra) # 80001410 <uvmalloc>
    800054e2:	dea43c23          	sd	a0,-520(s0)
    800054e6:	d939                	beqz	a0,8000543c <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054e8:	e2843c03          	ld	s8,-472(s0)
    800054ec:	e2042c83          	lw	s9,-480(s0)
    800054f0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054f4:	f60b83e3          	beqz	s7,8000545a <exec+0x31a>
    800054f8:	89de                	mv	s3,s7
    800054fa:	4481                	li	s1,0
    800054fc:	bb9d                	j	80005272 <exec+0x132>

00000000800054fe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054fe:	7179                	addi	sp,sp,-48
    80005500:	f406                	sd	ra,40(sp)
    80005502:	f022                	sd	s0,32(sp)
    80005504:	ec26                	sd	s1,24(sp)
    80005506:	e84a                	sd	s2,16(sp)
    80005508:	1800                	addi	s0,sp,48
    8000550a:	892e                	mv	s2,a1
    8000550c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000550e:	fdc40593          	addi	a1,s0,-36
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	a46080e7          	jalr	-1466(ra) # 80002f58 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000551a:	fdc42703          	lw	a4,-36(s0)
    8000551e:	47bd                	li	a5,15
    80005520:	02e7eb63          	bltu	a5,a4,80005556 <argfd+0x58>
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	488080e7          	jalr	1160(ra) # 800019ac <myproc>
    8000552c:	fdc42703          	lw	a4,-36(s0)
    80005530:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc46a>
    80005534:	078e                	slli	a5,a5,0x3
    80005536:	953e                	add	a0,a0,a5
    80005538:	611c                	ld	a5,0(a0)
    8000553a:	c385                	beqz	a5,8000555a <argfd+0x5c>
    return -1;
  if(pfd)
    8000553c:	00090463          	beqz	s2,80005544 <argfd+0x46>
    *pfd = fd;
    80005540:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005544:	4501                	li	a0,0
  if(pf)
    80005546:	c091                	beqz	s1,8000554a <argfd+0x4c>
    *pf = f;
    80005548:	e09c                	sd	a5,0(s1)
}
    8000554a:	70a2                	ld	ra,40(sp)
    8000554c:	7402                	ld	s0,32(sp)
    8000554e:	64e2                	ld	s1,24(sp)
    80005550:	6942                	ld	s2,16(sp)
    80005552:	6145                	addi	sp,sp,48
    80005554:	8082                	ret
    return -1;
    80005556:	557d                	li	a0,-1
    80005558:	bfcd                	j	8000554a <argfd+0x4c>
    8000555a:	557d                	li	a0,-1
    8000555c:	b7fd                	j	8000554a <argfd+0x4c>

000000008000555e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000555e:	1101                	addi	sp,sp,-32
    80005560:	ec06                	sd	ra,24(sp)
    80005562:	e822                	sd	s0,16(sp)
    80005564:	e426                	sd	s1,8(sp)
    80005566:	1000                	addi	s0,sp,32
    80005568:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	442080e7          	jalr	1090(ra) # 800019ac <myproc>
    80005572:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005574:	0d050793          	addi	a5,a0,208
    80005578:	4501                	li	a0,0
    8000557a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000557c:	6398                	ld	a4,0(a5)
    8000557e:	cb19                	beqz	a4,80005594 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005580:	2505                	addiw	a0,a0,1
    80005582:	07a1                	addi	a5,a5,8
    80005584:	fed51ce3          	bne	a0,a3,8000557c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005588:	557d                	li	a0,-1
}
    8000558a:	60e2                	ld	ra,24(sp)
    8000558c:	6442                	ld	s0,16(sp)
    8000558e:	64a2                	ld	s1,8(sp)
    80005590:	6105                	addi	sp,sp,32
    80005592:	8082                	ret
      p->ofile[fd] = f;
    80005594:	01a50793          	addi	a5,a0,26
    80005598:	078e                	slli	a5,a5,0x3
    8000559a:	963e                	add	a2,a2,a5
    8000559c:	e204                	sd	s1,0(a2)
      return fd;
    8000559e:	b7f5                	j	8000558a <fdalloc+0x2c>

00000000800055a0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055a0:	715d                	addi	sp,sp,-80
    800055a2:	e486                	sd	ra,72(sp)
    800055a4:	e0a2                	sd	s0,64(sp)
    800055a6:	fc26                	sd	s1,56(sp)
    800055a8:	f84a                	sd	s2,48(sp)
    800055aa:	f44e                	sd	s3,40(sp)
    800055ac:	f052                	sd	s4,32(sp)
    800055ae:	ec56                	sd	s5,24(sp)
    800055b0:	e85a                	sd	s6,16(sp)
    800055b2:	0880                	addi	s0,sp,80
    800055b4:	8b2e                	mv	s6,a1
    800055b6:	89b2                	mv	s3,a2
    800055b8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055ba:	fb040593          	addi	a1,s0,-80
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	e3e080e7          	jalr	-450(ra) # 800043fc <nameiparent>
    800055c6:	84aa                	mv	s1,a0
    800055c8:	14050f63          	beqz	a0,80005726 <create+0x186>
    return 0;

  ilock(dp);
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	666080e7          	jalr	1638(ra) # 80003c32 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055d4:	4601                	li	a2,0
    800055d6:	fb040593          	addi	a1,s0,-80
    800055da:	8526                	mv	a0,s1
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	b3a080e7          	jalr	-1222(ra) # 80004116 <dirlookup>
    800055e4:	8aaa                	mv	s5,a0
    800055e6:	c931                	beqz	a0,8000563a <create+0x9a>
    iunlockput(dp);
    800055e8:	8526                	mv	a0,s1
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	8aa080e7          	jalr	-1878(ra) # 80003e94 <iunlockput>
    ilock(ip);
    800055f2:	8556                	mv	a0,s5
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	63e080e7          	jalr	1598(ra) # 80003c32 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055fc:	000b059b          	sext.w	a1,s6
    80005600:	4789                	li	a5,2
    80005602:	02f59563          	bne	a1,a5,8000562c <create+0x8c>
    80005606:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc494>
    8000560a:	37f9                	addiw	a5,a5,-2
    8000560c:	17c2                	slli	a5,a5,0x30
    8000560e:	93c1                	srli	a5,a5,0x30
    80005610:	4705                	li	a4,1
    80005612:	00f76d63          	bltu	a4,a5,8000562c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005616:	8556                	mv	a0,s5
    80005618:	60a6                	ld	ra,72(sp)
    8000561a:	6406                	ld	s0,64(sp)
    8000561c:	74e2                	ld	s1,56(sp)
    8000561e:	7942                	ld	s2,48(sp)
    80005620:	79a2                	ld	s3,40(sp)
    80005622:	7a02                	ld	s4,32(sp)
    80005624:	6ae2                	ld	s5,24(sp)
    80005626:	6b42                	ld	s6,16(sp)
    80005628:	6161                	addi	sp,sp,80
    8000562a:	8082                	ret
    iunlockput(ip);
    8000562c:	8556                	mv	a0,s5
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	866080e7          	jalr	-1946(ra) # 80003e94 <iunlockput>
    return 0;
    80005636:	4a81                	li	s5,0
    80005638:	bff9                	j	80005616 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000563a:	85da                	mv	a1,s6
    8000563c:	4088                	lw	a0,0(s1)
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	456080e7          	jalr	1110(ra) # 80003a94 <ialloc>
    80005646:	8a2a                	mv	s4,a0
    80005648:	c539                	beqz	a0,80005696 <create+0xf6>
  ilock(ip);
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	5e8080e7          	jalr	1512(ra) # 80003c32 <ilock>
  ip->major = major;
    80005652:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005656:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000565a:	4905                	li	s2,1
    8000565c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005660:	8552                	mv	a0,s4
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	504080e7          	jalr	1284(ra) # 80003b66 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000566a:	000b059b          	sext.w	a1,s6
    8000566e:	03258b63          	beq	a1,s2,800056a4 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005672:	004a2603          	lw	a2,4(s4)
    80005676:	fb040593          	addi	a1,s0,-80
    8000567a:	8526                	mv	a0,s1
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	cb0080e7          	jalr	-848(ra) # 8000432c <dirlink>
    80005684:	06054f63          	bltz	a0,80005702 <create+0x162>
  iunlockput(dp);
    80005688:	8526                	mv	a0,s1
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	80a080e7          	jalr	-2038(ra) # 80003e94 <iunlockput>
  return ip;
    80005692:	8ad2                	mv	s5,s4
    80005694:	b749                	j	80005616 <create+0x76>
    iunlockput(dp);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	7fc080e7          	jalr	2044(ra) # 80003e94 <iunlockput>
    return 0;
    800056a0:	8ad2                	mv	s5,s4
    800056a2:	bf95                	j	80005616 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056a4:	004a2603          	lw	a2,4(s4)
    800056a8:	00003597          	auipc	a1,0x3
    800056ac:	09858593          	addi	a1,a1,152 # 80008740 <syscalls+0x2c0>
    800056b0:	8552                	mv	a0,s4
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	c7a080e7          	jalr	-902(ra) # 8000432c <dirlink>
    800056ba:	04054463          	bltz	a0,80005702 <create+0x162>
    800056be:	40d0                	lw	a2,4(s1)
    800056c0:	00003597          	auipc	a1,0x3
    800056c4:	08858593          	addi	a1,a1,136 # 80008748 <syscalls+0x2c8>
    800056c8:	8552                	mv	a0,s4
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	c62080e7          	jalr	-926(ra) # 8000432c <dirlink>
    800056d2:	02054863          	bltz	a0,80005702 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800056d6:	004a2603          	lw	a2,4(s4)
    800056da:	fb040593          	addi	a1,s0,-80
    800056de:	8526                	mv	a0,s1
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	c4c080e7          	jalr	-948(ra) # 8000432c <dirlink>
    800056e8:	00054d63          	bltz	a0,80005702 <create+0x162>
    dp->nlink++;  // for ".."
    800056ec:	04a4d783          	lhu	a5,74(s1)
    800056f0:	2785                	addiw	a5,a5,1
    800056f2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	46e080e7          	jalr	1134(ra) # 80003b66 <iupdate>
    80005700:	b761                	j	80005688 <create+0xe8>
  ip->nlink = 0;
    80005702:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005706:	8552                	mv	a0,s4
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	45e080e7          	jalr	1118(ra) # 80003b66 <iupdate>
  iunlockput(ip);
    80005710:	8552                	mv	a0,s4
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	782080e7          	jalr	1922(ra) # 80003e94 <iunlockput>
  iunlockput(dp);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	778080e7          	jalr	1912(ra) # 80003e94 <iunlockput>
  return 0;
    80005724:	bdcd                	j	80005616 <create+0x76>
    return 0;
    80005726:	8aaa                	mv	s5,a0
    80005728:	b5fd                	j	80005616 <create+0x76>

000000008000572a <sys_dup>:
{
    8000572a:	7179                	addi	sp,sp,-48
    8000572c:	f406                	sd	ra,40(sp)
    8000572e:	f022                	sd	s0,32(sp)
    80005730:	ec26                	sd	s1,24(sp)
    80005732:	e84a                	sd	s2,16(sp)
    80005734:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005736:	fd840613          	addi	a2,s0,-40
    8000573a:	4581                	li	a1,0
    8000573c:	4501                	li	a0,0
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	dc0080e7          	jalr	-576(ra) # 800054fe <argfd>
    return -1;
    80005746:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005748:	02054363          	bltz	a0,8000576e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000574c:	fd843903          	ld	s2,-40(s0)
    80005750:	854a                	mv	a0,s2
    80005752:	00000097          	auipc	ra,0x0
    80005756:	e0c080e7          	jalr	-500(ra) # 8000555e <fdalloc>
    8000575a:	84aa                	mv	s1,a0
    return -1;
    8000575c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000575e:	00054863          	bltz	a0,8000576e <sys_dup+0x44>
  filedup(f);
    80005762:	854a                	mv	a0,s2
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	310080e7          	jalr	784(ra) # 80004a74 <filedup>
  return fd;
    8000576c:	87a6                	mv	a5,s1
}
    8000576e:	853e                	mv	a0,a5
    80005770:	70a2                	ld	ra,40(sp)
    80005772:	7402                	ld	s0,32(sp)
    80005774:	64e2                	ld	s1,24(sp)
    80005776:	6942                	ld	s2,16(sp)
    80005778:	6145                	addi	sp,sp,48
    8000577a:	8082                	ret

000000008000577c <sys_read>:
{
    8000577c:	7179                	addi	sp,sp,-48
    8000577e:	f406                	sd	ra,40(sp)
    80005780:	f022                	sd	s0,32(sp)
    80005782:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005784:	fd840593          	addi	a1,s0,-40
    80005788:	4505                	li	a0,1
    8000578a:	ffffd097          	auipc	ra,0xffffd
    8000578e:	7ee080e7          	jalr	2030(ra) # 80002f78 <argaddr>
  argint(2, &n);
    80005792:	fe440593          	addi	a1,s0,-28
    80005796:	4509                	li	a0,2
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	7c0080e7          	jalr	1984(ra) # 80002f58 <argint>
  if(argfd(0, 0, &f) < 0)
    800057a0:	fe840613          	addi	a2,s0,-24
    800057a4:	4581                	li	a1,0
    800057a6:	4501                	li	a0,0
    800057a8:	00000097          	auipc	ra,0x0
    800057ac:	d56080e7          	jalr	-682(ra) # 800054fe <argfd>
    800057b0:	87aa                	mv	a5,a0
    return -1;
    800057b2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057b4:	0007cc63          	bltz	a5,800057cc <sys_read+0x50>
  return fileread(f, p, n);
    800057b8:	fe442603          	lw	a2,-28(s0)
    800057bc:	fd843583          	ld	a1,-40(s0)
    800057c0:	fe843503          	ld	a0,-24(s0)
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	43c080e7          	jalr	1084(ra) # 80004c00 <fileread>
}
    800057cc:	70a2                	ld	ra,40(sp)
    800057ce:	7402                	ld	s0,32(sp)
    800057d0:	6145                	addi	sp,sp,48
    800057d2:	8082                	ret

00000000800057d4 <sys_write>:
{
    800057d4:	7179                	addi	sp,sp,-48
    800057d6:	f406                	sd	ra,40(sp)
    800057d8:	f022                	sd	s0,32(sp)
    800057da:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057dc:	fd840593          	addi	a1,s0,-40
    800057e0:	4505                	li	a0,1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	796080e7          	jalr	1942(ra) # 80002f78 <argaddr>
  argint(2, &n);
    800057ea:	fe440593          	addi	a1,s0,-28
    800057ee:	4509                	li	a0,2
    800057f0:	ffffd097          	auipc	ra,0xffffd
    800057f4:	768080e7          	jalr	1896(ra) # 80002f58 <argint>
  if(argfd(0, 0, &f) < 0)
    800057f8:	fe840613          	addi	a2,s0,-24
    800057fc:	4581                	li	a1,0
    800057fe:	4501                	li	a0,0
    80005800:	00000097          	auipc	ra,0x0
    80005804:	cfe080e7          	jalr	-770(ra) # 800054fe <argfd>
    80005808:	87aa                	mv	a5,a0
    return -1;
    8000580a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000580c:	0007cc63          	bltz	a5,80005824 <sys_write+0x50>
  return filewrite(f, p, n);
    80005810:	fe442603          	lw	a2,-28(s0)
    80005814:	fd843583          	ld	a1,-40(s0)
    80005818:	fe843503          	ld	a0,-24(s0)
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	4a6080e7          	jalr	1190(ra) # 80004cc2 <filewrite>
}
    80005824:	70a2                	ld	ra,40(sp)
    80005826:	7402                	ld	s0,32(sp)
    80005828:	6145                	addi	sp,sp,48
    8000582a:	8082                	ret

000000008000582c <sys_close>:
{
    8000582c:	1101                	addi	sp,sp,-32
    8000582e:	ec06                	sd	ra,24(sp)
    80005830:	e822                	sd	s0,16(sp)
    80005832:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005834:	fe040613          	addi	a2,s0,-32
    80005838:	fec40593          	addi	a1,s0,-20
    8000583c:	4501                	li	a0,0
    8000583e:	00000097          	auipc	ra,0x0
    80005842:	cc0080e7          	jalr	-832(ra) # 800054fe <argfd>
    return -1;
    80005846:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005848:	02054463          	bltz	a0,80005870 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000584c:	ffffc097          	auipc	ra,0xffffc
    80005850:	160080e7          	jalr	352(ra) # 800019ac <myproc>
    80005854:	fec42783          	lw	a5,-20(s0)
    80005858:	07e9                	addi	a5,a5,26
    8000585a:	078e                	slli	a5,a5,0x3
    8000585c:	953e                	add	a0,a0,a5
    8000585e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005862:	fe043503          	ld	a0,-32(s0)
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	260080e7          	jalr	608(ra) # 80004ac6 <fileclose>
  return 0;
    8000586e:	4781                	li	a5,0
}
    80005870:	853e                	mv	a0,a5
    80005872:	60e2                	ld	ra,24(sp)
    80005874:	6442                	ld	s0,16(sp)
    80005876:	6105                	addi	sp,sp,32
    80005878:	8082                	ret

000000008000587a <sys_fstat>:
{
    8000587a:	1101                	addi	sp,sp,-32
    8000587c:	ec06                	sd	ra,24(sp)
    8000587e:	e822                	sd	s0,16(sp)
    80005880:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005882:	fe040593          	addi	a1,s0,-32
    80005886:	4505                	li	a0,1
    80005888:	ffffd097          	auipc	ra,0xffffd
    8000588c:	6f0080e7          	jalr	1776(ra) # 80002f78 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005890:	fe840613          	addi	a2,s0,-24
    80005894:	4581                	li	a1,0
    80005896:	4501                	li	a0,0
    80005898:	00000097          	auipc	ra,0x0
    8000589c:	c66080e7          	jalr	-922(ra) # 800054fe <argfd>
    800058a0:	87aa                	mv	a5,a0
    return -1;
    800058a2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058a4:	0007ca63          	bltz	a5,800058b8 <sys_fstat+0x3e>
  return filestat(f, st);
    800058a8:	fe043583          	ld	a1,-32(s0)
    800058ac:	fe843503          	ld	a0,-24(s0)
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	2de080e7          	jalr	734(ra) # 80004b8e <filestat>
}
    800058b8:	60e2                	ld	ra,24(sp)
    800058ba:	6442                	ld	s0,16(sp)
    800058bc:	6105                	addi	sp,sp,32
    800058be:	8082                	ret

00000000800058c0 <sys_link>:
{
    800058c0:	7169                	addi	sp,sp,-304
    800058c2:	f606                	sd	ra,296(sp)
    800058c4:	f222                	sd	s0,288(sp)
    800058c6:	ee26                	sd	s1,280(sp)
    800058c8:	ea4a                	sd	s2,272(sp)
    800058ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058cc:	08000613          	li	a2,128
    800058d0:	ed040593          	addi	a1,s0,-304
    800058d4:	4501                	li	a0,0
    800058d6:	ffffd097          	auipc	ra,0xffffd
    800058da:	6c2080e7          	jalr	1730(ra) # 80002f98 <argstr>
    return -1;
    800058de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e0:	10054e63          	bltz	a0,800059fc <sys_link+0x13c>
    800058e4:	08000613          	li	a2,128
    800058e8:	f5040593          	addi	a1,s0,-176
    800058ec:	4505                	li	a0,1
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	6aa080e7          	jalr	1706(ra) # 80002f98 <argstr>
    return -1;
    800058f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058f8:	10054263          	bltz	a0,800059fc <sys_link+0x13c>
  begin_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	d02080e7          	jalr	-766(ra) # 800045fe <begin_op>
  if((ip = namei(old)) == 0){
    80005904:	ed040513          	addi	a0,s0,-304
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	ad6080e7          	jalr	-1322(ra) # 800043de <namei>
    80005910:	84aa                	mv	s1,a0
    80005912:	c551                	beqz	a0,8000599e <sys_link+0xde>
  ilock(ip);
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	31e080e7          	jalr	798(ra) # 80003c32 <ilock>
  if(ip->type == T_DIR){
    8000591c:	04449703          	lh	a4,68(s1)
    80005920:	4785                	li	a5,1
    80005922:	08f70463          	beq	a4,a5,800059aa <sys_link+0xea>
  ip->nlink++;
    80005926:	04a4d783          	lhu	a5,74(s1)
    8000592a:	2785                	addiw	a5,a5,1
    8000592c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	234080e7          	jalr	564(ra) # 80003b66 <iupdate>
  iunlock(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	3b8080e7          	jalr	952(ra) # 80003cf4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005944:	fd040593          	addi	a1,s0,-48
    80005948:	f5040513          	addi	a0,s0,-176
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	ab0080e7          	jalr	-1360(ra) # 800043fc <nameiparent>
    80005954:	892a                	mv	s2,a0
    80005956:	c935                	beqz	a0,800059ca <sys_link+0x10a>
  ilock(dp);
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	2da080e7          	jalr	730(ra) # 80003c32 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005960:	00092703          	lw	a4,0(s2)
    80005964:	409c                	lw	a5,0(s1)
    80005966:	04f71d63          	bne	a4,a5,800059c0 <sys_link+0x100>
    8000596a:	40d0                	lw	a2,4(s1)
    8000596c:	fd040593          	addi	a1,s0,-48
    80005970:	854a                	mv	a0,s2
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	9ba080e7          	jalr	-1606(ra) # 8000432c <dirlink>
    8000597a:	04054363          	bltz	a0,800059c0 <sys_link+0x100>
  iunlockput(dp);
    8000597e:	854a                	mv	a0,s2
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	514080e7          	jalr	1300(ra) # 80003e94 <iunlockput>
  iput(ip);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	462080e7          	jalr	1122(ra) # 80003dec <iput>
  end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	cea080e7          	jalr	-790(ra) # 8000467c <end_op>
  return 0;
    8000599a:	4781                	li	a5,0
    8000599c:	a085                	j	800059fc <sys_link+0x13c>
    end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	cde080e7          	jalr	-802(ra) # 8000467c <end_op>
    return -1;
    800059a6:	57fd                	li	a5,-1
    800059a8:	a891                	j	800059fc <sys_link+0x13c>
    iunlockput(ip);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	4e8080e7          	jalr	1256(ra) # 80003e94 <iunlockput>
    end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	cc8080e7          	jalr	-824(ra) # 8000467c <end_op>
    return -1;
    800059bc:	57fd                	li	a5,-1
    800059be:	a83d                	j	800059fc <sys_link+0x13c>
    iunlockput(dp);
    800059c0:	854a                	mv	a0,s2
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	4d2080e7          	jalr	1234(ra) # 80003e94 <iunlockput>
  ilock(ip);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	266080e7          	jalr	614(ra) # 80003c32 <ilock>
  ip->nlink--;
    800059d4:	04a4d783          	lhu	a5,74(s1)
    800059d8:	37fd                	addiw	a5,a5,-1
    800059da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059de:	8526                	mv	a0,s1
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	186080e7          	jalr	390(ra) # 80003b66 <iupdate>
  iunlockput(ip);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	4aa080e7          	jalr	1194(ra) # 80003e94 <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	c8a080e7          	jalr	-886(ra) # 8000467c <end_op>
  return -1;
    800059fa:	57fd                	li	a5,-1
}
    800059fc:	853e                	mv	a0,a5
    800059fe:	70b2                	ld	ra,296(sp)
    80005a00:	7412                	ld	s0,288(sp)
    80005a02:	64f2                	ld	s1,280(sp)
    80005a04:	6952                	ld	s2,272(sp)
    80005a06:	6155                	addi	sp,sp,304
    80005a08:	8082                	ret

0000000080005a0a <sys_unlink>:
{
    80005a0a:	7151                	addi	sp,sp,-240
    80005a0c:	f586                	sd	ra,232(sp)
    80005a0e:	f1a2                	sd	s0,224(sp)
    80005a10:	eda6                	sd	s1,216(sp)
    80005a12:	e9ca                	sd	s2,208(sp)
    80005a14:	e5ce                	sd	s3,200(sp)
    80005a16:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a18:	08000613          	li	a2,128
    80005a1c:	f3040593          	addi	a1,s0,-208
    80005a20:	4501                	li	a0,0
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	576080e7          	jalr	1398(ra) # 80002f98 <argstr>
    80005a2a:	18054163          	bltz	a0,80005bac <sys_unlink+0x1a2>
  begin_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	bd0080e7          	jalr	-1072(ra) # 800045fe <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a36:	fb040593          	addi	a1,s0,-80
    80005a3a:	f3040513          	addi	a0,s0,-208
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	9be080e7          	jalr	-1602(ra) # 800043fc <nameiparent>
    80005a46:	84aa                	mv	s1,a0
    80005a48:	c979                	beqz	a0,80005b1e <sys_unlink+0x114>
  ilock(dp);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	1e8080e7          	jalr	488(ra) # 80003c32 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a52:	00003597          	auipc	a1,0x3
    80005a56:	cee58593          	addi	a1,a1,-786 # 80008740 <syscalls+0x2c0>
    80005a5a:	fb040513          	addi	a0,s0,-80
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	69e080e7          	jalr	1694(ra) # 800040fc <namecmp>
    80005a66:	14050a63          	beqz	a0,80005bba <sys_unlink+0x1b0>
    80005a6a:	00003597          	auipc	a1,0x3
    80005a6e:	cde58593          	addi	a1,a1,-802 # 80008748 <syscalls+0x2c8>
    80005a72:	fb040513          	addi	a0,s0,-80
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	686080e7          	jalr	1670(ra) # 800040fc <namecmp>
    80005a7e:	12050e63          	beqz	a0,80005bba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a82:	f2c40613          	addi	a2,s0,-212
    80005a86:	fb040593          	addi	a1,s0,-80
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	68a080e7          	jalr	1674(ra) # 80004116 <dirlookup>
    80005a94:	892a                	mv	s2,a0
    80005a96:	12050263          	beqz	a0,80005bba <sys_unlink+0x1b0>
  ilock(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	198080e7          	jalr	408(ra) # 80003c32 <ilock>
  if(ip->nlink < 1)
    80005aa2:	04a91783          	lh	a5,74(s2)
    80005aa6:	08f05263          	blez	a5,80005b2a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005aaa:	04491703          	lh	a4,68(s2)
    80005aae:	4785                	li	a5,1
    80005ab0:	08f70563          	beq	a4,a5,80005b3a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ab4:	4641                	li	a2,16
    80005ab6:	4581                	li	a1,0
    80005ab8:	fc040513          	addi	a0,s0,-64
    80005abc:	ffffb097          	auipc	ra,0xffffb
    80005ac0:	216080e7          	jalr	534(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ac4:	4741                	li	a4,16
    80005ac6:	f2c42683          	lw	a3,-212(s0)
    80005aca:	fc040613          	addi	a2,s0,-64
    80005ace:	4581                	li	a1,0
    80005ad0:	8526                	mv	a0,s1
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	50c080e7          	jalr	1292(ra) # 80003fde <writei>
    80005ada:	47c1                	li	a5,16
    80005adc:	0af51563          	bne	a0,a5,80005b86 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ae0:	04491703          	lh	a4,68(s2)
    80005ae4:	4785                	li	a5,1
    80005ae6:	0af70863          	beq	a4,a5,80005b96 <sys_unlink+0x18c>
  iunlockput(dp);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	3a8080e7          	jalr	936(ra) # 80003e94 <iunlockput>
  ip->nlink--;
    80005af4:	04a95783          	lhu	a5,74(s2)
    80005af8:	37fd                	addiw	a5,a5,-1
    80005afa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005afe:	854a                	mv	a0,s2
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	066080e7          	jalr	102(ra) # 80003b66 <iupdate>
  iunlockput(ip);
    80005b08:	854a                	mv	a0,s2
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	38a080e7          	jalr	906(ra) # 80003e94 <iunlockput>
  end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	b6a080e7          	jalr	-1174(ra) # 8000467c <end_op>
  return 0;
    80005b1a:	4501                	li	a0,0
    80005b1c:	a84d                	j	80005bce <sys_unlink+0x1c4>
    end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	b5e080e7          	jalr	-1186(ra) # 8000467c <end_op>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	a05d                	j	80005bce <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b2a:	00003517          	auipc	a0,0x3
    80005b2e:	c2650513          	addi	a0,a0,-986 # 80008750 <syscalls+0x2d0>
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	a0e080e7          	jalr	-1522(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b3a:	04c92703          	lw	a4,76(s2)
    80005b3e:	02000793          	li	a5,32
    80005b42:	f6e7f9e3          	bgeu	a5,a4,80005ab4 <sys_unlink+0xaa>
    80005b46:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b4a:	4741                	li	a4,16
    80005b4c:	86ce                	mv	a3,s3
    80005b4e:	f1840613          	addi	a2,s0,-232
    80005b52:	4581                	li	a1,0
    80005b54:	854a                	mv	a0,s2
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	390080e7          	jalr	912(ra) # 80003ee6 <readi>
    80005b5e:	47c1                	li	a5,16
    80005b60:	00f51b63          	bne	a0,a5,80005b76 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b64:	f1845783          	lhu	a5,-232(s0)
    80005b68:	e7a1                	bnez	a5,80005bb0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b6a:	29c1                	addiw	s3,s3,16
    80005b6c:	04c92783          	lw	a5,76(s2)
    80005b70:	fcf9ede3          	bltu	s3,a5,80005b4a <sys_unlink+0x140>
    80005b74:	b781                	j	80005ab4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b76:	00003517          	auipc	a0,0x3
    80005b7a:	bf250513          	addi	a0,a0,-1038 # 80008768 <syscalls+0x2e8>
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	9c2080e7          	jalr	-1598(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005b86:	00003517          	auipc	a0,0x3
    80005b8a:	bfa50513          	addi	a0,a0,-1030 # 80008780 <syscalls+0x300>
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	9b2080e7          	jalr	-1614(ra) # 80000540 <panic>
    dp->nlink--;
    80005b96:	04a4d783          	lhu	a5,74(s1)
    80005b9a:	37fd                	addiw	a5,a5,-1
    80005b9c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ba0:	8526                	mv	a0,s1
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	fc4080e7          	jalr	-60(ra) # 80003b66 <iupdate>
    80005baa:	b781                	j	80005aea <sys_unlink+0xe0>
    return -1;
    80005bac:	557d                	li	a0,-1
    80005bae:	a005                	j	80005bce <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	2e2080e7          	jalr	738(ra) # 80003e94 <iunlockput>
  iunlockput(dp);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	2d8080e7          	jalr	728(ra) # 80003e94 <iunlockput>
  end_op();
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	ab8080e7          	jalr	-1352(ra) # 8000467c <end_op>
  return -1;
    80005bcc:	557d                	li	a0,-1
}
    80005bce:	70ae                	ld	ra,232(sp)
    80005bd0:	740e                	ld	s0,224(sp)
    80005bd2:	64ee                	ld	s1,216(sp)
    80005bd4:	694e                	ld	s2,208(sp)
    80005bd6:	69ae                	ld	s3,200(sp)
    80005bd8:	616d                	addi	sp,sp,240
    80005bda:	8082                	ret

0000000080005bdc <sys_open>:

uint64
sys_open(void)
{
    80005bdc:	7131                	addi	sp,sp,-192
    80005bde:	fd06                	sd	ra,184(sp)
    80005be0:	f922                	sd	s0,176(sp)
    80005be2:	f526                	sd	s1,168(sp)
    80005be4:	f14a                	sd	s2,160(sp)
    80005be6:	ed4e                	sd	s3,152(sp)
    80005be8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005bea:	f4c40593          	addi	a1,s0,-180
    80005bee:	4505                	li	a0,1
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	368080e7          	jalr	872(ra) # 80002f58 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bf8:	08000613          	li	a2,128
    80005bfc:	f5040593          	addi	a1,s0,-176
    80005c00:	4501                	li	a0,0
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	396080e7          	jalr	918(ra) # 80002f98 <argstr>
    80005c0a:	87aa                	mv	a5,a0
    return -1;
    80005c0c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c0e:	0a07c963          	bltz	a5,80005cc0 <sys_open+0xe4>

  begin_op();
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	9ec080e7          	jalr	-1556(ra) # 800045fe <begin_op>

  if(omode & O_CREATE){
    80005c1a:	f4c42783          	lw	a5,-180(s0)
    80005c1e:	2007f793          	andi	a5,a5,512
    80005c22:	cfc5                	beqz	a5,80005cda <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c24:	4681                	li	a3,0
    80005c26:	4601                	li	a2,0
    80005c28:	4589                	li	a1,2
    80005c2a:	f5040513          	addi	a0,s0,-176
    80005c2e:	00000097          	auipc	ra,0x0
    80005c32:	972080e7          	jalr	-1678(ra) # 800055a0 <create>
    80005c36:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c38:	c959                	beqz	a0,80005cce <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c3a:	04449703          	lh	a4,68(s1)
    80005c3e:	478d                	li	a5,3
    80005c40:	00f71763          	bne	a4,a5,80005c4e <sys_open+0x72>
    80005c44:	0464d703          	lhu	a4,70(s1)
    80005c48:	47a5                	li	a5,9
    80005c4a:	0ce7ed63          	bltu	a5,a4,80005d24 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	dbc080e7          	jalr	-580(ra) # 80004a0a <filealloc>
    80005c56:	89aa                	mv	s3,a0
    80005c58:	10050363          	beqz	a0,80005d5e <sys_open+0x182>
    80005c5c:	00000097          	auipc	ra,0x0
    80005c60:	902080e7          	jalr	-1790(ra) # 8000555e <fdalloc>
    80005c64:	892a                	mv	s2,a0
    80005c66:	0e054763          	bltz	a0,80005d54 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c6a:	04449703          	lh	a4,68(s1)
    80005c6e:	478d                	li	a5,3
    80005c70:	0cf70563          	beq	a4,a5,80005d3a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c74:	4789                	li	a5,2
    80005c76:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c7a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c7e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c82:	f4c42783          	lw	a5,-180(s0)
    80005c86:	0017c713          	xori	a4,a5,1
    80005c8a:	8b05                	andi	a4,a4,1
    80005c8c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c90:	0037f713          	andi	a4,a5,3
    80005c94:	00e03733          	snez	a4,a4
    80005c98:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c9c:	4007f793          	andi	a5,a5,1024
    80005ca0:	c791                	beqz	a5,80005cac <sys_open+0xd0>
    80005ca2:	04449703          	lh	a4,68(s1)
    80005ca6:	4789                	li	a5,2
    80005ca8:	0af70063          	beq	a4,a5,80005d48 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cac:	8526                	mv	a0,s1
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	046080e7          	jalr	70(ra) # 80003cf4 <iunlock>
  end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	9c6080e7          	jalr	-1594(ra) # 8000467c <end_op>

  return fd;
    80005cbe:	854a                	mv	a0,s2
}
    80005cc0:	70ea                	ld	ra,184(sp)
    80005cc2:	744a                	ld	s0,176(sp)
    80005cc4:	74aa                	ld	s1,168(sp)
    80005cc6:	790a                	ld	s2,160(sp)
    80005cc8:	69ea                	ld	s3,152(sp)
    80005cca:	6129                	addi	sp,sp,192
    80005ccc:	8082                	ret
      end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	9ae080e7          	jalr	-1618(ra) # 8000467c <end_op>
      return -1;
    80005cd6:	557d                	li	a0,-1
    80005cd8:	b7e5                	j	80005cc0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cda:	f5040513          	addi	a0,s0,-176
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	700080e7          	jalr	1792(ra) # 800043de <namei>
    80005ce6:	84aa                	mv	s1,a0
    80005ce8:	c905                	beqz	a0,80005d18 <sys_open+0x13c>
    ilock(ip);
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	f48080e7          	jalr	-184(ra) # 80003c32 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cf2:	04449703          	lh	a4,68(s1)
    80005cf6:	4785                	li	a5,1
    80005cf8:	f4f711e3          	bne	a4,a5,80005c3a <sys_open+0x5e>
    80005cfc:	f4c42783          	lw	a5,-180(s0)
    80005d00:	d7b9                	beqz	a5,80005c4e <sys_open+0x72>
      iunlockput(ip);
    80005d02:	8526                	mv	a0,s1
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	190080e7          	jalr	400(ra) # 80003e94 <iunlockput>
      end_op();
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	970080e7          	jalr	-1680(ra) # 8000467c <end_op>
      return -1;
    80005d14:	557d                	li	a0,-1
    80005d16:	b76d                	j	80005cc0 <sys_open+0xe4>
      end_op();
    80005d18:	fffff097          	auipc	ra,0xfffff
    80005d1c:	964080e7          	jalr	-1692(ra) # 8000467c <end_op>
      return -1;
    80005d20:	557d                	li	a0,-1
    80005d22:	bf79                	j	80005cc0 <sys_open+0xe4>
    iunlockput(ip);
    80005d24:	8526                	mv	a0,s1
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	16e080e7          	jalr	366(ra) # 80003e94 <iunlockput>
    end_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	94e080e7          	jalr	-1714(ra) # 8000467c <end_op>
    return -1;
    80005d36:	557d                	li	a0,-1
    80005d38:	b761                	j	80005cc0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d3a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d3e:	04649783          	lh	a5,70(s1)
    80005d42:	02f99223          	sh	a5,36(s3)
    80005d46:	bf25                	j	80005c7e <sys_open+0xa2>
    itrunc(ip);
    80005d48:	8526                	mv	a0,s1
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	ff6080e7          	jalr	-10(ra) # 80003d40 <itrunc>
    80005d52:	bfa9                	j	80005cac <sys_open+0xd0>
      fileclose(f);
    80005d54:	854e                	mv	a0,s3
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	d70080e7          	jalr	-656(ra) # 80004ac6 <fileclose>
    iunlockput(ip);
    80005d5e:	8526                	mv	a0,s1
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	134080e7          	jalr	308(ra) # 80003e94 <iunlockput>
    end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	914080e7          	jalr	-1772(ra) # 8000467c <end_op>
    return -1;
    80005d70:	557d                	li	a0,-1
    80005d72:	b7b9                	j	80005cc0 <sys_open+0xe4>

0000000080005d74 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d74:	7175                	addi	sp,sp,-144
    80005d76:	e506                	sd	ra,136(sp)
    80005d78:	e122                	sd	s0,128(sp)
    80005d7a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	882080e7          	jalr	-1918(ra) # 800045fe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d84:	08000613          	li	a2,128
    80005d88:	f7040593          	addi	a1,s0,-144
    80005d8c:	4501                	li	a0,0
    80005d8e:	ffffd097          	auipc	ra,0xffffd
    80005d92:	20a080e7          	jalr	522(ra) # 80002f98 <argstr>
    80005d96:	02054963          	bltz	a0,80005dc8 <sys_mkdir+0x54>
    80005d9a:	4681                	li	a3,0
    80005d9c:	4601                	li	a2,0
    80005d9e:	4585                	li	a1,1
    80005da0:	f7040513          	addi	a0,s0,-144
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	7fc080e7          	jalr	2044(ra) # 800055a0 <create>
    80005dac:	cd11                	beqz	a0,80005dc8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	0e6080e7          	jalr	230(ra) # 80003e94 <iunlockput>
  end_op();
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	8c6080e7          	jalr	-1850(ra) # 8000467c <end_op>
  return 0;
    80005dbe:	4501                	li	a0,0
}
    80005dc0:	60aa                	ld	ra,136(sp)
    80005dc2:	640a                	ld	s0,128(sp)
    80005dc4:	6149                	addi	sp,sp,144
    80005dc6:	8082                	ret
    end_op();
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	8b4080e7          	jalr	-1868(ra) # 8000467c <end_op>
    return -1;
    80005dd0:	557d                	li	a0,-1
    80005dd2:	b7fd                	j	80005dc0 <sys_mkdir+0x4c>

0000000080005dd4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dd4:	7135                	addi	sp,sp,-160
    80005dd6:	ed06                	sd	ra,152(sp)
    80005dd8:	e922                	sd	s0,144(sp)
    80005dda:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	822080e7          	jalr	-2014(ra) # 800045fe <begin_op>
  argint(1, &major);
    80005de4:	f6c40593          	addi	a1,s0,-148
    80005de8:	4505                	li	a0,1
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	16e080e7          	jalr	366(ra) # 80002f58 <argint>
  argint(2, &minor);
    80005df2:	f6840593          	addi	a1,s0,-152
    80005df6:	4509                	li	a0,2
    80005df8:	ffffd097          	auipc	ra,0xffffd
    80005dfc:	160080e7          	jalr	352(ra) # 80002f58 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e00:	08000613          	li	a2,128
    80005e04:	f7040593          	addi	a1,s0,-144
    80005e08:	4501                	li	a0,0
    80005e0a:	ffffd097          	auipc	ra,0xffffd
    80005e0e:	18e080e7          	jalr	398(ra) # 80002f98 <argstr>
    80005e12:	02054b63          	bltz	a0,80005e48 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e16:	f6841683          	lh	a3,-152(s0)
    80005e1a:	f6c41603          	lh	a2,-148(s0)
    80005e1e:	458d                	li	a1,3
    80005e20:	f7040513          	addi	a0,s0,-144
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	77c080e7          	jalr	1916(ra) # 800055a0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e2c:	cd11                	beqz	a0,80005e48 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e2e:	ffffe097          	auipc	ra,0xffffe
    80005e32:	066080e7          	jalr	102(ra) # 80003e94 <iunlockput>
  end_op();
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	846080e7          	jalr	-1978(ra) # 8000467c <end_op>
  return 0;
    80005e3e:	4501                	li	a0,0
}
    80005e40:	60ea                	ld	ra,152(sp)
    80005e42:	644a                	ld	s0,144(sp)
    80005e44:	610d                	addi	sp,sp,160
    80005e46:	8082                	ret
    end_op();
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	834080e7          	jalr	-1996(ra) # 8000467c <end_op>
    return -1;
    80005e50:	557d                	li	a0,-1
    80005e52:	b7fd                	j	80005e40 <sys_mknod+0x6c>

0000000080005e54 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e54:	7135                	addi	sp,sp,-160
    80005e56:	ed06                	sd	ra,152(sp)
    80005e58:	e922                	sd	s0,144(sp)
    80005e5a:	e526                	sd	s1,136(sp)
    80005e5c:	e14a                	sd	s2,128(sp)
    80005e5e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	b4c080e7          	jalr	-1204(ra) # 800019ac <myproc>
    80005e68:	892a                	mv	s2,a0
  
  begin_op();
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	794080e7          	jalr	1940(ra) # 800045fe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e72:	08000613          	li	a2,128
    80005e76:	f6040593          	addi	a1,s0,-160
    80005e7a:	4501                	li	a0,0
    80005e7c:	ffffd097          	auipc	ra,0xffffd
    80005e80:	11c080e7          	jalr	284(ra) # 80002f98 <argstr>
    80005e84:	04054b63          	bltz	a0,80005eda <sys_chdir+0x86>
    80005e88:	f6040513          	addi	a0,s0,-160
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	552080e7          	jalr	1362(ra) # 800043de <namei>
    80005e94:	84aa                	mv	s1,a0
    80005e96:	c131                	beqz	a0,80005eda <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e98:	ffffe097          	auipc	ra,0xffffe
    80005e9c:	d9a080e7          	jalr	-614(ra) # 80003c32 <ilock>
  if(ip->type != T_DIR){
    80005ea0:	04449703          	lh	a4,68(s1)
    80005ea4:	4785                	li	a5,1
    80005ea6:	04f71063          	bne	a4,a5,80005ee6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005eaa:	8526                	mv	a0,s1
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	e48080e7          	jalr	-440(ra) # 80003cf4 <iunlock>
  iput(p->cwd);
    80005eb4:	15093503          	ld	a0,336(s2)
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	f34080e7          	jalr	-204(ra) # 80003dec <iput>
  end_op();
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	7bc080e7          	jalr	1980(ra) # 8000467c <end_op>
  p->cwd = ip;
    80005ec8:	14993823          	sd	s1,336(s2)
  return 0;
    80005ecc:	4501                	li	a0,0
}
    80005ece:	60ea                	ld	ra,152(sp)
    80005ed0:	644a                	ld	s0,144(sp)
    80005ed2:	64aa                	ld	s1,136(sp)
    80005ed4:	690a                	ld	s2,128(sp)
    80005ed6:	610d                	addi	sp,sp,160
    80005ed8:	8082                	ret
    end_op();
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	7a2080e7          	jalr	1954(ra) # 8000467c <end_op>
    return -1;
    80005ee2:	557d                	li	a0,-1
    80005ee4:	b7ed                	j	80005ece <sys_chdir+0x7a>
    iunlockput(ip);
    80005ee6:	8526                	mv	a0,s1
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	fac080e7          	jalr	-84(ra) # 80003e94 <iunlockput>
    end_op();
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	78c080e7          	jalr	1932(ra) # 8000467c <end_op>
    return -1;
    80005ef8:	557d                	li	a0,-1
    80005efa:	bfd1                	j	80005ece <sys_chdir+0x7a>

0000000080005efc <sys_exec>:

uint64
sys_exec(void)
{
    80005efc:	7145                	addi	sp,sp,-464
    80005efe:	e786                	sd	ra,456(sp)
    80005f00:	e3a2                	sd	s0,448(sp)
    80005f02:	ff26                	sd	s1,440(sp)
    80005f04:	fb4a                	sd	s2,432(sp)
    80005f06:	f74e                	sd	s3,424(sp)
    80005f08:	f352                	sd	s4,416(sp)
    80005f0a:	ef56                	sd	s5,408(sp)
    80005f0c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f0e:	e3840593          	addi	a1,s0,-456
    80005f12:	4505                	li	a0,1
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	064080e7          	jalr	100(ra) # 80002f78 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f1c:	08000613          	li	a2,128
    80005f20:	f4040593          	addi	a1,s0,-192
    80005f24:	4501                	li	a0,0
    80005f26:	ffffd097          	auipc	ra,0xffffd
    80005f2a:	072080e7          	jalr	114(ra) # 80002f98 <argstr>
    80005f2e:	87aa                	mv	a5,a0
    return -1;
    80005f30:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f32:	0c07c363          	bltz	a5,80005ff8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005f36:	10000613          	li	a2,256
    80005f3a:	4581                	li	a1,0
    80005f3c:	e4040513          	addi	a0,s0,-448
    80005f40:	ffffb097          	auipc	ra,0xffffb
    80005f44:	d92080e7          	jalr	-622(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f4c:	89a6                	mv	s3,s1
    80005f4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f50:	02000a13          	li	s4,32
    80005f54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f58:	00391513          	slli	a0,s2,0x3
    80005f5c:	e3040593          	addi	a1,s0,-464
    80005f60:	e3843783          	ld	a5,-456(s0)
    80005f64:	953e                	add	a0,a0,a5
    80005f66:	ffffd097          	auipc	ra,0xffffd
    80005f6a:	f54080e7          	jalr	-172(ra) # 80002eba <fetchaddr>
    80005f6e:	02054a63          	bltz	a0,80005fa2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f72:	e3043783          	ld	a5,-464(s0)
    80005f76:	c3b9                	beqz	a5,80005fbc <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f78:	ffffb097          	auipc	ra,0xffffb
    80005f7c:	b6e080e7          	jalr	-1170(ra) # 80000ae6 <kalloc>
    80005f80:	85aa                	mv	a1,a0
    80005f82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f86:	cd11                	beqz	a0,80005fa2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f88:	6605                	lui	a2,0x1
    80005f8a:	e3043503          	ld	a0,-464(s0)
    80005f8e:	ffffd097          	auipc	ra,0xffffd
    80005f92:	f7e080e7          	jalr	-130(ra) # 80002f0c <fetchstr>
    80005f96:	00054663          	bltz	a0,80005fa2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f9a:	0905                	addi	s2,s2,1
    80005f9c:	09a1                	addi	s3,s3,8
    80005f9e:	fb491be3          	bne	s2,s4,80005f54 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fa2:	f4040913          	addi	s2,s0,-192
    80005fa6:	6088                	ld	a0,0(s1)
    80005fa8:	c539                	beqz	a0,80005ff6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	a3e080e7          	jalr	-1474(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb2:	04a1                	addi	s1,s1,8
    80005fb4:	ff2499e3          	bne	s1,s2,80005fa6 <sys_exec+0xaa>
  return -1;
    80005fb8:	557d                	li	a0,-1
    80005fba:	a83d                	j	80005ff8 <sys_exec+0xfc>
      argv[i] = 0;
    80005fbc:	0a8e                	slli	s5,s5,0x3
    80005fbe:	fc0a8793          	addi	a5,s5,-64
    80005fc2:	00878ab3          	add	s5,a5,s0
    80005fc6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fca:	e4040593          	addi	a1,s0,-448
    80005fce:	f4040513          	addi	a0,s0,-192
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	16e080e7          	jalr	366(ra) # 80005140 <exec>
    80005fda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fdc:	f4040993          	addi	s3,s0,-192
    80005fe0:	6088                	ld	a0,0(s1)
    80005fe2:	c901                	beqz	a0,80005ff2 <sys_exec+0xf6>
    kfree(argv[i]);
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	a04080e7          	jalr	-1532(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fec:	04a1                	addi	s1,s1,8
    80005fee:	ff3499e3          	bne	s1,s3,80005fe0 <sys_exec+0xe4>
  return ret;
    80005ff2:	854a                	mv	a0,s2
    80005ff4:	a011                	j	80005ff8 <sys_exec+0xfc>
  return -1;
    80005ff6:	557d                	li	a0,-1
}
    80005ff8:	60be                	ld	ra,456(sp)
    80005ffa:	641e                	ld	s0,448(sp)
    80005ffc:	74fa                	ld	s1,440(sp)
    80005ffe:	795a                	ld	s2,432(sp)
    80006000:	79ba                	ld	s3,424(sp)
    80006002:	7a1a                	ld	s4,416(sp)
    80006004:	6afa                	ld	s5,408(sp)
    80006006:	6179                	addi	sp,sp,464
    80006008:	8082                	ret

000000008000600a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000600a:	7139                	addi	sp,sp,-64
    8000600c:	fc06                	sd	ra,56(sp)
    8000600e:	f822                	sd	s0,48(sp)
    80006010:	f426                	sd	s1,40(sp)
    80006012:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006014:	ffffc097          	auipc	ra,0xffffc
    80006018:	998080e7          	jalr	-1640(ra) # 800019ac <myproc>
    8000601c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000601e:	fd840593          	addi	a1,s0,-40
    80006022:	4501                	li	a0,0
    80006024:	ffffd097          	auipc	ra,0xffffd
    80006028:	f54080e7          	jalr	-172(ra) # 80002f78 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000602c:	fc840593          	addi	a1,s0,-56
    80006030:	fd040513          	addi	a0,s0,-48
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	dc2080e7          	jalr	-574(ra) # 80004df6 <pipealloc>
    return -1;
    8000603c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000603e:	0c054463          	bltz	a0,80006106 <sys_pipe+0xfc>
  fd0 = -1;
    80006042:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006046:	fd043503          	ld	a0,-48(s0)
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	514080e7          	jalr	1300(ra) # 8000555e <fdalloc>
    80006052:	fca42223          	sw	a0,-60(s0)
    80006056:	08054b63          	bltz	a0,800060ec <sys_pipe+0xe2>
    8000605a:	fc843503          	ld	a0,-56(s0)
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	500080e7          	jalr	1280(ra) # 8000555e <fdalloc>
    80006066:	fca42023          	sw	a0,-64(s0)
    8000606a:	06054863          	bltz	a0,800060da <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000606e:	4691                	li	a3,4
    80006070:	fc440613          	addi	a2,s0,-60
    80006074:	fd843583          	ld	a1,-40(s0)
    80006078:	68a8                	ld	a0,80(s1)
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	5f2080e7          	jalr	1522(ra) # 8000166c <copyout>
    80006082:	02054063          	bltz	a0,800060a2 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006086:	4691                	li	a3,4
    80006088:	fc040613          	addi	a2,s0,-64
    8000608c:	fd843583          	ld	a1,-40(s0)
    80006090:	0591                	addi	a1,a1,4
    80006092:	68a8                	ld	a0,80(s1)
    80006094:	ffffb097          	auipc	ra,0xffffb
    80006098:	5d8080e7          	jalr	1496(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000609c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000609e:	06055463          	bgez	a0,80006106 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060a2:	fc442783          	lw	a5,-60(s0)
    800060a6:	07e9                	addi	a5,a5,26
    800060a8:	078e                	slli	a5,a5,0x3
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060b0:	fc042783          	lw	a5,-64(s0)
    800060b4:	07e9                	addi	a5,a5,26
    800060b6:	078e                	slli	a5,a5,0x3
    800060b8:	94be                	add	s1,s1,a5
    800060ba:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060be:	fd043503          	ld	a0,-48(s0)
    800060c2:	fffff097          	auipc	ra,0xfffff
    800060c6:	a04080e7          	jalr	-1532(ra) # 80004ac6 <fileclose>
    fileclose(wf);
    800060ca:	fc843503          	ld	a0,-56(s0)
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	9f8080e7          	jalr	-1544(ra) # 80004ac6 <fileclose>
    return -1;
    800060d6:	57fd                	li	a5,-1
    800060d8:	a03d                	j	80006106 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060da:	fc442783          	lw	a5,-60(s0)
    800060de:	0007c763          	bltz	a5,800060ec <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060e2:	07e9                	addi	a5,a5,26
    800060e4:	078e                	slli	a5,a5,0x3
    800060e6:	97a6                	add	a5,a5,s1
    800060e8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800060ec:	fd043503          	ld	a0,-48(s0)
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	9d6080e7          	jalr	-1578(ra) # 80004ac6 <fileclose>
    fileclose(wf);
    800060f8:	fc843503          	ld	a0,-56(s0)
    800060fc:	fffff097          	auipc	ra,0xfffff
    80006100:	9ca080e7          	jalr	-1590(ra) # 80004ac6 <fileclose>
    return -1;
    80006104:	57fd                	li	a5,-1
}
    80006106:	853e                	mv	a0,a5
    80006108:	70e2                	ld	ra,56(sp)
    8000610a:	7442                	ld	s0,48(sp)
    8000610c:	74a2                	ld	s1,40(sp)
    8000610e:	6121                	addi	sp,sp,64
    80006110:	8082                	ret

0000000080006112 <sys_getreadcount>:

int sys_getreadcount(void) {
    80006112:	1141                	addi	sp,sp,-16
    80006114:	e422                	sd	s0,8(sp)
    80006116:	0800                	addi	s0,sp,16
  return readcount;
}
    80006118:	00003517          	auipc	a0,0x3
    8000611c:	81c52503          	lw	a0,-2020(a0) # 80008934 <readcount>
    80006120:	6422                	ld	s0,8(sp)
    80006122:	0141                	addi	sp,sp,16
    80006124:	8082                	ret
	...

0000000080006130 <kernelvec>:
    80006130:	7111                	addi	sp,sp,-256
    80006132:	e006                	sd	ra,0(sp)
    80006134:	e40a                	sd	sp,8(sp)
    80006136:	e80e                	sd	gp,16(sp)
    80006138:	ec12                	sd	tp,24(sp)
    8000613a:	f016                	sd	t0,32(sp)
    8000613c:	f41a                	sd	t1,40(sp)
    8000613e:	f81e                	sd	t2,48(sp)
    80006140:	fc22                	sd	s0,56(sp)
    80006142:	e0a6                	sd	s1,64(sp)
    80006144:	e4aa                	sd	a0,72(sp)
    80006146:	e8ae                	sd	a1,80(sp)
    80006148:	ecb2                	sd	a2,88(sp)
    8000614a:	f0b6                	sd	a3,96(sp)
    8000614c:	f4ba                	sd	a4,104(sp)
    8000614e:	f8be                	sd	a5,112(sp)
    80006150:	fcc2                	sd	a6,120(sp)
    80006152:	e146                	sd	a7,128(sp)
    80006154:	e54a                	sd	s2,136(sp)
    80006156:	e94e                	sd	s3,144(sp)
    80006158:	ed52                	sd	s4,152(sp)
    8000615a:	f156                	sd	s5,160(sp)
    8000615c:	f55a                	sd	s6,168(sp)
    8000615e:	f95e                	sd	s7,176(sp)
    80006160:	fd62                	sd	s8,184(sp)
    80006162:	e1e6                	sd	s9,192(sp)
    80006164:	e5ea                	sd	s10,200(sp)
    80006166:	e9ee                	sd	s11,208(sp)
    80006168:	edf2                	sd	t3,216(sp)
    8000616a:	f1f6                	sd	t4,224(sp)
    8000616c:	f5fa                	sd	t5,232(sp)
    8000616e:	f9fe                	sd	t6,240(sp)
    80006170:	c17fc0ef          	jal	ra,80002d86 <kerneltrap>
    80006174:	6082                	ld	ra,0(sp)
    80006176:	6122                	ld	sp,8(sp)
    80006178:	61c2                	ld	gp,16(sp)
    8000617a:	7282                	ld	t0,32(sp)
    8000617c:	7322                	ld	t1,40(sp)
    8000617e:	73c2                	ld	t2,48(sp)
    80006180:	7462                	ld	s0,56(sp)
    80006182:	6486                	ld	s1,64(sp)
    80006184:	6526                	ld	a0,72(sp)
    80006186:	65c6                	ld	a1,80(sp)
    80006188:	6666                	ld	a2,88(sp)
    8000618a:	7686                	ld	a3,96(sp)
    8000618c:	7726                	ld	a4,104(sp)
    8000618e:	77c6                	ld	a5,112(sp)
    80006190:	7866                	ld	a6,120(sp)
    80006192:	688a                	ld	a7,128(sp)
    80006194:	692a                	ld	s2,136(sp)
    80006196:	69ca                	ld	s3,144(sp)
    80006198:	6a6a                	ld	s4,152(sp)
    8000619a:	7a8a                	ld	s5,160(sp)
    8000619c:	7b2a                	ld	s6,168(sp)
    8000619e:	7bca                	ld	s7,176(sp)
    800061a0:	7c6a                	ld	s8,184(sp)
    800061a2:	6c8e                	ld	s9,192(sp)
    800061a4:	6d2e                	ld	s10,200(sp)
    800061a6:	6dce                	ld	s11,208(sp)
    800061a8:	6e6e                	ld	t3,216(sp)
    800061aa:	7e8e                	ld	t4,224(sp)
    800061ac:	7f2e                	ld	t5,232(sp)
    800061ae:	7fce                	ld	t6,240(sp)
    800061b0:	6111                	addi	sp,sp,256
    800061b2:	10200073          	sret
    800061b6:	00000013          	nop
    800061ba:	00000013          	nop
    800061be:	0001                	nop

00000000800061c0 <timervec>:
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	e10c                	sd	a1,0(a0)
    800061c6:	e510                	sd	a2,8(a0)
    800061c8:	e914                	sd	a3,16(a0)
    800061ca:	6d0c                	ld	a1,24(a0)
    800061cc:	7110                	ld	a2,32(a0)
    800061ce:	6194                	ld	a3,0(a1)
    800061d0:	96b2                	add	a3,a3,a2
    800061d2:	e194                	sd	a3,0(a1)
    800061d4:	4589                	li	a1,2
    800061d6:	14459073          	csrw	sip,a1
    800061da:	6914                	ld	a3,16(a0)
    800061dc:	6510                	ld	a2,8(a0)
    800061de:	610c                	ld	a1,0(a0)
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	30200073          	mret
	...

00000000800061ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ea:	1141                	addi	sp,sp,-16
    800061ec:	e422                	sd	s0,8(sp)
    800061ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061f0:	0c0007b7          	lui	a5,0xc000
    800061f4:	4705                	li	a4,1
    800061f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061f8:	c3d8                	sw	a4,4(a5)
}
    800061fa:	6422                	ld	s0,8(sp)
    800061fc:	0141                	addi	sp,sp,16
    800061fe:	8082                	ret

0000000080006200 <plicinithart>:

void
plicinithart(void)
{
    80006200:	1141                	addi	sp,sp,-16
    80006202:	e406                	sd	ra,8(sp)
    80006204:	e022                	sd	s0,0(sp)
    80006206:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	778080e7          	jalr	1912(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006210:	0085171b          	slliw	a4,a0,0x8
    80006214:	0c0027b7          	lui	a5,0xc002
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	40200713          	li	a4,1026
    8000621e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006222:	00d5151b          	slliw	a0,a0,0xd
    80006226:	0c2017b7          	lui	a5,0xc201
    8000622a:	97aa                	add	a5,a5,a0
    8000622c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret

0000000080006238 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006238:	1141                	addi	sp,sp,-16
    8000623a:	e406                	sd	ra,8(sp)
    8000623c:	e022                	sd	s0,0(sp)
    8000623e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	740080e7          	jalr	1856(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006248:	00d5151b          	slliw	a0,a0,0xd
    8000624c:	0c2017b7          	lui	a5,0xc201
    80006250:	97aa                	add	a5,a5,a0
  return irq;
}
    80006252:	43c8                	lw	a0,4(a5)
    80006254:	60a2                	ld	ra,8(sp)
    80006256:	6402                	ld	s0,0(sp)
    80006258:	0141                	addi	sp,sp,16
    8000625a:	8082                	ret

000000008000625c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000625c:	1101                	addi	sp,sp,-32
    8000625e:	ec06                	sd	ra,24(sp)
    80006260:	e822                	sd	s0,16(sp)
    80006262:	e426                	sd	s1,8(sp)
    80006264:	1000                	addi	s0,sp,32
    80006266:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006268:	ffffb097          	auipc	ra,0xffffb
    8000626c:	718080e7          	jalr	1816(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006270:	00d5151b          	slliw	a0,a0,0xd
    80006274:	0c2017b7          	lui	a5,0xc201
    80006278:	97aa                	add	a5,a5,a0
    8000627a:	c3c4                	sw	s1,4(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret

0000000080006286 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006286:	1141                	addi	sp,sp,-16
    80006288:	e406                	sd	ra,8(sp)
    8000628a:	e022                	sd	s0,0(sp)
    8000628c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000628e:	479d                	li	a5,7
    80006290:	04a7cc63          	blt	a5,a0,800062e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006294:	0001c797          	auipc	a5,0x1c
    80006298:	7dc78793          	addi	a5,a5,2012 # 80022a70 <disk>
    8000629c:	97aa                	add	a5,a5,a0
    8000629e:	0187c783          	lbu	a5,24(a5)
    800062a2:	ebb9                	bnez	a5,800062f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062a4:	00451693          	slli	a3,a0,0x4
    800062a8:	0001c797          	auipc	a5,0x1c
    800062ac:	7c878793          	addi	a5,a5,1992 # 80022a70 <disk>
    800062b0:	6398                	ld	a4,0(a5)
    800062b2:	9736                	add	a4,a4,a3
    800062b4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800062b8:	6398                	ld	a4,0(a5)
    800062ba:	9736                	add	a4,a4,a3
    800062bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	4705                	li	a4,1
    800062cc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800062d0:	0001c517          	auipc	a0,0x1c
    800062d4:	7b850513          	addi	a0,a0,1976 # 80022a88 <disk+0x18>
    800062d8:	ffffc097          	auipc	ra,0xffffc
    800062dc:	e9e080e7          	jalr	-354(ra) # 80002176 <wakeup>
}
    800062e0:	60a2                	ld	ra,8(sp)
    800062e2:	6402                	ld	s0,0(sp)
    800062e4:	0141                	addi	sp,sp,16
    800062e6:	8082                	ret
    panic("free_desc 1");
    800062e8:	00002517          	auipc	a0,0x2
    800062ec:	4a850513          	addi	a0,a0,1192 # 80008790 <syscalls+0x310>
    800062f0:	ffffa097          	auipc	ra,0xffffa
    800062f4:	250080e7          	jalr	592(ra) # 80000540 <panic>
    panic("free_desc 2");
    800062f8:	00002517          	auipc	a0,0x2
    800062fc:	4a850513          	addi	a0,a0,1192 # 800087a0 <syscalls+0x320>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	240080e7          	jalr	576(ra) # 80000540 <panic>

0000000080006308 <virtio_disk_init>:
{
    80006308:	1101                	addi	sp,sp,-32
    8000630a:	ec06                	sd	ra,24(sp)
    8000630c:	e822                	sd	s0,16(sp)
    8000630e:	e426                	sd	s1,8(sp)
    80006310:	e04a                	sd	s2,0(sp)
    80006312:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006314:	00002597          	auipc	a1,0x2
    80006318:	49c58593          	addi	a1,a1,1180 # 800087b0 <syscalls+0x330>
    8000631c:	0001d517          	auipc	a0,0x1d
    80006320:	87c50513          	addi	a0,a0,-1924 # 80022b98 <disk+0x128>
    80006324:	ffffb097          	auipc	ra,0xffffb
    80006328:	822080e7          	jalr	-2014(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000632c:	100017b7          	lui	a5,0x10001
    80006330:	4398                	lw	a4,0(a5)
    80006332:	2701                	sext.w	a4,a4
    80006334:	747277b7          	lui	a5,0x74727
    80006338:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000633c:	14f71b63          	bne	a4,a5,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006340:	100017b7          	lui	a5,0x10001
    80006344:	43dc                	lw	a5,4(a5)
    80006346:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006348:	4709                	li	a4,2
    8000634a:	14e79463          	bne	a5,a4,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000634e:	100017b7          	lui	a5,0x10001
    80006352:	479c                	lw	a5,8(a5)
    80006354:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006356:	12e79e63          	bne	a5,a4,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000635a:	100017b7          	lui	a5,0x10001
    8000635e:	47d8                	lw	a4,12(a5)
    80006360:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006362:	554d47b7          	lui	a5,0x554d4
    80006366:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000636a:	12f71463          	bne	a4,a5,80006492 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000636e:	100017b7          	lui	a5,0x10001
    80006372:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006376:	4705                	li	a4,1
    80006378:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000637a:	470d                	li	a4,3
    8000637c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000637e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006380:	c7ffe6b7          	lui	a3,0xc7ffe
    80006384:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbbaf>
    80006388:	8f75                	and	a4,a4,a3
    8000638a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638c:	472d                	li	a4,11
    8000638e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006390:	5bbc                	lw	a5,112(a5)
    80006392:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006396:	8ba1                	andi	a5,a5,8
    80006398:	10078563          	beqz	a5,800064a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000639c:	100017b7          	lui	a5,0x10001
    800063a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063a4:	43fc                	lw	a5,68(a5)
    800063a6:	2781                	sext.w	a5,a5
    800063a8:	10079563          	bnez	a5,800064b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063ac:	100017b7          	lui	a5,0x10001
    800063b0:	5bdc                	lw	a5,52(a5)
    800063b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800063b4:	10078763          	beqz	a5,800064c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800063b8:	471d                	li	a4,7
    800063ba:	10f77c63          	bgeu	a4,a5,800064d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	728080e7          	jalr	1832(ra) # 80000ae6 <kalloc>
    800063c6:	0001c497          	auipc	s1,0x1c
    800063ca:	6aa48493          	addi	s1,s1,1706 # 80022a70 <disk>
    800063ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	716080e7          	jalr	1814(ra) # 80000ae6 <kalloc>
    800063d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	70c080e7          	jalr	1804(ra) # 80000ae6 <kalloc>
    800063e2:	87aa                	mv	a5,a0
    800063e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063e6:	6088                	ld	a0,0(s1)
    800063e8:	cd6d                	beqz	a0,800064e2 <virtio_disk_init+0x1da>
    800063ea:	0001c717          	auipc	a4,0x1c
    800063ee:	68e73703          	ld	a4,1678(a4) # 80022a78 <disk+0x8>
    800063f2:	cb65                	beqz	a4,800064e2 <virtio_disk_init+0x1da>
    800063f4:	c7fd                	beqz	a5,800064e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800063f6:	6605                	lui	a2,0x1
    800063f8:	4581                	li	a1,0
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	8d8080e7          	jalr	-1832(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006402:	0001c497          	auipc	s1,0x1c
    80006406:	66e48493          	addi	s1,s1,1646 # 80022a70 <disk>
    8000640a:	6605                	lui	a2,0x1
    8000640c:	4581                	li	a1,0
    8000640e:	6488                	ld	a0,8(s1)
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	8c2080e7          	jalr	-1854(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006418:	6605                	lui	a2,0x1
    8000641a:	4581                	li	a1,0
    8000641c:	6888                	ld	a0,16(s1)
    8000641e:	ffffb097          	auipc	ra,0xffffb
    80006422:	8b4080e7          	jalr	-1868(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006426:	100017b7          	lui	a5,0x10001
    8000642a:	4721                	li	a4,8
    8000642c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000642e:	4098                	lw	a4,0(s1)
    80006430:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006434:	40d8                	lw	a4,4(s1)
    80006436:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000643a:	6498                	ld	a4,8(s1)
    8000643c:	0007069b          	sext.w	a3,a4
    80006440:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006444:	9701                	srai	a4,a4,0x20
    80006446:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000644a:	6898                	ld	a4,16(s1)
    8000644c:	0007069b          	sext.w	a3,a4
    80006450:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006454:	9701                	srai	a4,a4,0x20
    80006456:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000645a:	4705                	li	a4,1
    8000645c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000645e:	00e48c23          	sb	a4,24(s1)
    80006462:	00e48ca3          	sb	a4,25(s1)
    80006466:	00e48d23          	sb	a4,26(s1)
    8000646a:	00e48da3          	sb	a4,27(s1)
    8000646e:	00e48e23          	sb	a4,28(s1)
    80006472:	00e48ea3          	sb	a4,29(s1)
    80006476:	00e48f23          	sb	a4,30(s1)
    8000647a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000647e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006482:	0727a823          	sw	s2,112(a5)
}
    80006486:	60e2                	ld	ra,24(sp)
    80006488:	6442                	ld	s0,16(sp)
    8000648a:	64a2                	ld	s1,8(sp)
    8000648c:	6902                	ld	s2,0(sp)
    8000648e:	6105                	addi	sp,sp,32
    80006490:	8082                	ret
    panic("could not find virtio disk");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	32e50513          	addi	a0,a0,814 # 800087c0 <syscalls+0x340>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a6080e7          	jalr	166(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	33e50513          	addi	a0,a0,830 # 800087e0 <syscalls+0x360>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800064b2:	00002517          	auipc	a0,0x2
    800064b6:	34e50513          	addi	a0,a0,846 # 80008800 <syscalls+0x380>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	086080e7          	jalr	134(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	35e50513          	addi	a0,a0,862 # 80008820 <syscalls+0x3a0>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	076080e7          	jalr	118(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	36e50513          	addi	a0,a0,878 # 80008840 <syscalls+0x3c0>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	066080e7          	jalr	102(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	37e50513          	addi	a0,a0,894 # 80008860 <syscalls+0x3e0>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	056080e7          	jalr	86(ra) # 80000540 <panic>

00000000800064f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064f2:	7119                	addi	sp,sp,-128
    800064f4:	fc86                	sd	ra,120(sp)
    800064f6:	f8a2                	sd	s0,112(sp)
    800064f8:	f4a6                	sd	s1,104(sp)
    800064fa:	f0ca                	sd	s2,96(sp)
    800064fc:	ecce                	sd	s3,88(sp)
    800064fe:	e8d2                	sd	s4,80(sp)
    80006500:	e4d6                	sd	s5,72(sp)
    80006502:	e0da                	sd	s6,64(sp)
    80006504:	fc5e                	sd	s7,56(sp)
    80006506:	f862                	sd	s8,48(sp)
    80006508:	f466                	sd	s9,40(sp)
    8000650a:	f06a                	sd	s10,32(sp)
    8000650c:	ec6e                	sd	s11,24(sp)
    8000650e:	0100                	addi	s0,sp,128
    80006510:	8aaa                	mv	s5,a0
    80006512:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006514:	00c52d03          	lw	s10,12(a0)
    80006518:	001d1d1b          	slliw	s10,s10,0x1
    8000651c:	1d02                	slli	s10,s10,0x20
    8000651e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006522:	0001c517          	auipc	a0,0x1c
    80006526:	67650513          	addi	a0,a0,1654 # 80022b98 <disk+0x128>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	6ac080e7          	jalr	1708(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006532:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006534:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006536:	0001cb97          	auipc	s7,0x1c
    8000653a:	53ab8b93          	addi	s7,s7,1338 # 80022a70 <disk>
  for(int i = 0; i < 3; i++){
    8000653e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006540:	0001cc97          	auipc	s9,0x1c
    80006544:	658c8c93          	addi	s9,s9,1624 # 80022b98 <disk+0x128>
    80006548:	a08d                	j	800065aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000654a:	00fb8733          	add	a4,s7,a5
    8000654e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006552:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006554:	0207c563          	bltz	a5,8000657e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006558:	2905                	addiw	s2,s2,1
    8000655a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000655c:	05690c63          	beq	s2,s6,800065b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006560:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006562:	0001c717          	auipc	a4,0x1c
    80006566:	50e70713          	addi	a4,a4,1294 # 80022a70 <disk>
    8000656a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000656c:	01874683          	lbu	a3,24(a4)
    80006570:	fee9                	bnez	a3,8000654a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006572:	2785                	addiw	a5,a5,1
    80006574:	0705                	addi	a4,a4,1
    80006576:	fe979be3          	bne	a5,s1,8000656c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000657a:	57fd                	li	a5,-1
    8000657c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000657e:	01205d63          	blez	s2,80006598 <virtio_disk_rw+0xa6>
    80006582:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006584:	000a2503          	lw	a0,0(s4)
    80006588:	00000097          	auipc	ra,0x0
    8000658c:	cfe080e7          	jalr	-770(ra) # 80006286 <free_desc>
      for(int j = 0; j < i; j++)
    80006590:	2d85                	addiw	s11,s11,1
    80006592:	0a11                	addi	s4,s4,4
    80006594:	ff2d98e3          	bne	s11,s2,80006584 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006598:	85e6                	mv	a1,s9
    8000659a:	0001c517          	auipc	a0,0x1c
    8000659e:	4ee50513          	addi	a0,a0,1262 # 80022a88 <disk+0x18>
    800065a2:	ffffc097          	auipc	ra,0xffffc
    800065a6:	b70080e7          	jalr	-1168(ra) # 80002112 <sleep>
  for(int i = 0; i < 3; i++){
    800065aa:	f8040a13          	addi	s4,s0,-128
{
    800065ae:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065b0:	894e                	mv	s2,s3
    800065b2:	b77d                	j	80006560 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065b4:	f8042503          	lw	a0,-128(s0)
    800065b8:	00a50713          	addi	a4,a0,10
    800065bc:	0712                	slli	a4,a4,0x4

  if(write)
    800065be:	0001c797          	auipc	a5,0x1c
    800065c2:	4b278793          	addi	a5,a5,1202 # 80022a70 <disk>
    800065c6:	00e786b3          	add	a3,a5,a4
    800065ca:	01803633          	snez	a2,s8
    800065ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800065d4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065d8:	f6070613          	addi	a2,a4,-160
    800065dc:	6394                	ld	a3,0(a5)
    800065de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065e0:	00870593          	addi	a1,a4,8
    800065e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065e8:	0007b803          	ld	a6,0(a5)
    800065ec:	9642                	add	a2,a2,a6
    800065ee:	46c1                	li	a3,16
    800065f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065f2:	4585                	li	a1,1
    800065f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800065f8:	f8442683          	lw	a3,-124(s0)
    800065fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006600:	0692                	slli	a3,a3,0x4
    80006602:	9836                	add	a6,a6,a3
    80006604:	058a8613          	addi	a2,s5,88
    80006608:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000660c:	0007b803          	ld	a6,0(a5)
    80006610:	96c2                	add	a3,a3,a6
    80006612:	40000613          	li	a2,1024
    80006616:	c690                	sw	a2,8(a3)
  if(write)
    80006618:	001c3613          	seqz	a2,s8
    8000661c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006620:	00166613          	ori	a2,a2,1
    80006624:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006628:	f8842603          	lw	a2,-120(s0)
    8000662c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006630:	00250693          	addi	a3,a0,2
    80006634:	0692                	slli	a3,a3,0x4
    80006636:	96be                	add	a3,a3,a5
    80006638:	58fd                	li	a7,-1
    8000663a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000663e:	0612                	slli	a2,a2,0x4
    80006640:	9832                	add	a6,a6,a2
    80006642:	f9070713          	addi	a4,a4,-112
    80006646:	973e                	add	a4,a4,a5
    80006648:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000664c:	6398                	ld	a4,0(a5)
    8000664e:	9732                	add	a4,a4,a2
    80006650:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006652:	4609                	li	a2,2
    80006654:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006658:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000665c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006660:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006664:	6794                	ld	a3,8(a5)
    80006666:	0026d703          	lhu	a4,2(a3)
    8000666a:	8b1d                	andi	a4,a4,7
    8000666c:	0706                	slli	a4,a4,0x1
    8000666e:	96ba                	add	a3,a3,a4
    80006670:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006674:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006678:	6798                	ld	a4,8(a5)
    8000667a:	00275783          	lhu	a5,2(a4)
    8000667e:	2785                	addiw	a5,a5,1
    80006680:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006684:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006688:	100017b7          	lui	a5,0x10001
    8000668c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006690:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006694:	0001c917          	auipc	s2,0x1c
    80006698:	50490913          	addi	s2,s2,1284 # 80022b98 <disk+0x128>
  while(b->disk == 1) {
    8000669c:	4485                	li	s1,1
    8000669e:	00b79c63          	bne	a5,a1,800066b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066a2:	85ca                	mv	a1,s2
    800066a4:	8556                	mv	a0,s5
    800066a6:	ffffc097          	auipc	ra,0xffffc
    800066aa:	a6c080e7          	jalr	-1428(ra) # 80002112 <sleep>
  while(b->disk == 1) {
    800066ae:	004aa783          	lw	a5,4(s5)
    800066b2:	fe9788e3          	beq	a5,s1,800066a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800066b6:	f8042903          	lw	s2,-128(s0)
    800066ba:	00290713          	addi	a4,s2,2
    800066be:	0712                	slli	a4,a4,0x4
    800066c0:	0001c797          	auipc	a5,0x1c
    800066c4:	3b078793          	addi	a5,a5,944 # 80022a70 <disk>
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066ce:	0001c997          	auipc	s3,0x1c
    800066d2:	3a298993          	addi	s3,s3,930 # 80022a70 <disk>
    800066d6:	00491713          	slli	a4,s2,0x4
    800066da:	0009b783          	ld	a5,0(s3)
    800066de:	97ba                	add	a5,a5,a4
    800066e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066e4:	854a                	mv	a0,s2
    800066e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	b9c080e7          	jalr	-1124(ra) # 80006286 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066f2:	8885                	andi	s1,s1,1
    800066f4:	f0ed                	bnez	s1,800066d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066f6:	0001c517          	auipc	a0,0x1c
    800066fa:	4a250513          	addi	a0,a0,1186 # 80022b98 <disk+0x128>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
}
    80006706:	70e6                	ld	ra,120(sp)
    80006708:	7446                	ld	s0,112(sp)
    8000670a:	74a6                	ld	s1,104(sp)
    8000670c:	7906                	ld	s2,96(sp)
    8000670e:	69e6                	ld	s3,88(sp)
    80006710:	6a46                	ld	s4,80(sp)
    80006712:	6aa6                	ld	s5,72(sp)
    80006714:	6b06                	ld	s6,64(sp)
    80006716:	7be2                	ld	s7,56(sp)
    80006718:	7c42                	ld	s8,48(sp)
    8000671a:	7ca2                	ld	s9,40(sp)
    8000671c:	7d02                	ld	s10,32(sp)
    8000671e:	6de2                	ld	s11,24(sp)
    80006720:	6109                	addi	sp,sp,128
    80006722:	8082                	ret

0000000080006724 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006724:	1101                	addi	sp,sp,-32
    80006726:	ec06                	sd	ra,24(sp)
    80006728:	e822                	sd	s0,16(sp)
    8000672a:	e426                	sd	s1,8(sp)
    8000672c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000672e:	0001c497          	auipc	s1,0x1c
    80006732:	34248493          	addi	s1,s1,834 # 80022a70 <disk>
    80006736:	0001c517          	auipc	a0,0x1c
    8000673a:	46250513          	addi	a0,a0,1122 # 80022b98 <disk+0x128>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	498080e7          	jalr	1176(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006746:	10001737          	lui	a4,0x10001
    8000674a:	533c                	lw	a5,96(a4)
    8000674c:	8b8d                	andi	a5,a5,3
    8000674e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006750:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006754:	689c                	ld	a5,16(s1)
    80006756:	0204d703          	lhu	a4,32(s1)
    8000675a:	0027d783          	lhu	a5,2(a5)
    8000675e:	04f70863          	beq	a4,a5,800067ae <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006762:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006766:	6898                	ld	a4,16(s1)
    80006768:	0204d783          	lhu	a5,32(s1)
    8000676c:	8b9d                	andi	a5,a5,7
    8000676e:	078e                	slli	a5,a5,0x3
    80006770:	97ba                	add	a5,a5,a4
    80006772:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006774:	00278713          	addi	a4,a5,2
    80006778:	0712                	slli	a4,a4,0x4
    8000677a:	9726                	add	a4,a4,s1
    8000677c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006780:	e721                	bnez	a4,800067c8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006782:	0789                	addi	a5,a5,2
    80006784:	0792                	slli	a5,a5,0x4
    80006786:	97a6                	add	a5,a5,s1
    80006788:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000678a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000678e:	ffffc097          	auipc	ra,0xffffc
    80006792:	9e8080e7          	jalr	-1560(ra) # 80002176 <wakeup>

    disk.used_idx += 1;
    80006796:	0204d783          	lhu	a5,32(s1)
    8000679a:	2785                	addiw	a5,a5,1
    8000679c:	17c2                	slli	a5,a5,0x30
    8000679e:	93c1                	srli	a5,a5,0x30
    800067a0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067a4:	6898                	ld	a4,16(s1)
    800067a6:	00275703          	lhu	a4,2(a4)
    800067aa:	faf71ce3          	bne	a4,a5,80006762 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067ae:	0001c517          	auipc	a0,0x1c
    800067b2:	3ea50513          	addi	a0,a0,1002 # 80022b98 <disk+0x128>
    800067b6:	ffffa097          	auipc	ra,0xffffa
    800067ba:	4d4080e7          	jalr	1236(ra) # 80000c8a <release>
}
    800067be:	60e2                	ld	ra,24(sp)
    800067c0:	6442                	ld	s0,16(sp)
    800067c2:	64a2                	ld	s1,8(sp)
    800067c4:	6105                	addi	sp,sp,32
    800067c6:	8082                	ret
      panic("virtio_disk_intr status");
    800067c8:	00002517          	auipc	a0,0x2
    800067cc:	0b050513          	addi	a0,a0,176 # 80008878 <syscalls+0x3f8>
    800067d0:	ffffa097          	auipc	ra,0xffffa
    800067d4:	d70080e7          	jalr	-656(ra) # 80000540 <panic>
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
