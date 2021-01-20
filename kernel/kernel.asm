
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	aec78793          	addi	a5,a5,-1300 # 80005b50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	30c080e7          	jalr	780(ra) # 8000242a <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7be080e7          	jalr	1982(ra) # 80001970 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e6e080e7          	jalr	-402(ra) # 80002030 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	1d6080e7          	jalr	470(ra) # 800023d4 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	1a2080e7          	jalr	418(ra) # 80002480 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	d8a080e7          	jalr	-630(ra) # 800021bc <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	93e080e7          	jalr	-1730(ra) # 800021bc <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	726080e7          	jalr	1830(ra) # 80002030 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	df8080e7          	jalr	-520(ra) # 80001954 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	dc6080e7          	jalr	-570(ra) # 80001954 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dba080e7          	jalr	-582(ra) # 80001954 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	da2080e7          	jalr	-606(ra) # 80001954 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	d62080e7          	jalr	-670(ra) # 80001954 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d36080e7          	jalr	-714(ra) # 80001954 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	ad0080e7          	jalr	-1328(ra) # 80001944 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	ab4080e7          	jalr	-1356(ra) # 80001944 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	710080e7          	jalr	1808(ra) # 800025c2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	cd6080e7          	jalr	-810(ra) # 80005b90 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fbc080e7          	jalr	-68(ra) # 80001e7e <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	972080e7          	jalr	-1678(ra) # 80001894 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	670080e7          	jalr	1648(ra) # 8000259a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	690080e7          	jalr	1680(ra) # 800025c2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	c40080e7          	jalr	-960(ra) # 80005b7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	c4e080e7          	jalr	-946(ra) # 80005b90 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	e20080e7          	jalr	-480(ra) # 80002d6a <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	4b2080e7          	jalr	1202(ra) # 80003404 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	460080e7          	jalr	1120(ra) # 800043ba <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	d50080e7          	jalr	-688(ra) # 80005cb2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cde080e7          	jalr	-802(ra) # 80001c48 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	5f2080e7          	jalr	1522(ra) # 800017fe <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0) continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6a85                	lui	s5,0x1
    8000126e:	0535ea63          	bltu	a1,s3,800012c2 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
    *pte = 0;
    800012b8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012bc:	9956                	add	s2,s2,s5
    800012be:	fb397ae3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012c2:	4601                	li	a2,0
    800012c4:	85ca                	mv	a1,s2
    800012c6:	8552                	mv	a0,s4
    800012c8:	00000097          	auipc	ra,0x0
    800012cc:	cde080e7          	jalr	-802(ra) # 80000fa6 <walk>
    800012d0:	84aa                	mv	s1,a0
    800012d2:	d179                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0) continue;
    800012d4:	611c                	ld	a5,0(a0)
    800012d6:	0017f713          	andi	a4,a5,1
    800012da:	d36d                	beqz	a4,800012bc <uvmunmap+0x7a>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012dc:	3ff7f713          	andi	a4,a5,1023
    800012e0:	fd7704e3          	beq	a4,s7,800012a8 <uvmunmap+0x66>
    if(do_free){
    800012e4:	fc0b0ae3          	beqz	s6,800012b8 <uvmunmap+0x76>
      uint64 pa = PTE2PA(*pte);
    800012e8:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012ea:	00c79513          	slli	a0,a5,0xc
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	6e8080e7          	jalr	1768(ra) # 800009d6 <kfree>
    800012f6:	b7c9                	j	800012b8 <uvmunmap+0x76>

00000000800012f8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800012f8:	1101                	addi	sp,sp,-32
    800012fa:	ec06                	sd	ra,24(sp)
    800012fc:	e822                	sd	s0,16(sp)
    800012fe:	e426                	sd	s1,8(sp)
    80001300:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	7d0080e7          	jalr	2000(ra) # 80000ad2 <kalloc>
    8000130a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000130c:	c519                	beqz	a0,8000131a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000130e:	6605                	lui	a2,0x1
    80001310:	4581                	li	a1,0
    80001312:	00000097          	auipc	ra,0x0
    80001316:	9ac080e7          	jalr	-1620(ra) # 80000cbe <memset>
  return pagetable;
}
    8000131a:	8526                	mv	a0,s1
    8000131c:	60e2                	ld	ra,24(sp)
    8000131e:	6442                	ld	s0,16(sp)
    80001320:	64a2                	ld	s1,8(sp)
    80001322:	6105                	addi	sp,sp,32
    80001324:	8082                	ret

0000000080001326 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001326:	7179                	addi	sp,sp,-48
    80001328:	f406                	sd	ra,40(sp)
    8000132a:	f022                	sd	s0,32(sp)
    8000132c:	ec26                	sd	s1,24(sp)
    8000132e:	e84a                	sd	s2,16(sp)
    80001330:	e44e                	sd	s3,8(sp)
    80001332:	e052                	sd	s4,0(sp)
    80001334:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001336:	6785                	lui	a5,0x1
    80001338:	04f67863          	bgeu	a2,a5,80001388 <uvminit+0x62>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	89ae                	mv	s3,a1
    80001340:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	790080e7          	jalr	1936(ra) # 80000ad2 <kalloc>
    8000134a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000134c:	6605                	lui	a2,0x1
    8000134e:	4581                	li	a1,0
    80001350:	00000097          	auipc	ra,0x0
    80001354:	96e080e7          	jalr	-1682(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001358:	4779                	li	a4,30
    8000135a:	86ca                	mv	a3,s2
    8000135c:	6605                	lui	a2,0x1
    8000135e:	4581                	li	a1,0
    80001360:	8552                	mv	a0,s4
    80001362:	00000097          	auipc	ra,0x0
    80001366:	d2c080e7          	jalr	-724(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    8000136a:	8626                	mv	a2,s1
    8000136c:	85ce                	mv	a1,s3
    8000136e:	854a                	mv	a0,s2
    80001370:	00000097          	auipc	ra,0x0
    80001374:	9aa080e7          	jalr	-1622(ra) # 80000d1a <memmove>
}
    80001378:	70a2                	ld	ra,40(sp)
    8000137a:	7402                	ld	s0,32(sp)
    8000137c:	64e2                	ld	s1,24(sp)
    8000137e:	6942                	ld	s2,16(sp)
    80001380:	69a2                	ld	s3,8(sp)
    80001382:	6a02                	ld	s4,0(sp)
    80001384:	6145                	addi	sp,sp,48
    80001386:	8082                	ret
    panic("inituvm: more than a page");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	da050513          	addi	a0,a0,-608 # 80008128 <digits+0xe8>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	19a080e7          	jalr	410(ra) # 8000052a <panic>

0000000080001398 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001398:	1101                	addi	sp,sp,-32
    8000139a:	ec06                	sd	ra,24(sp)
    8000139c:	e822                	sd	s0,16(sp)
    8000139e:	e426                	sd	s1,8(sp)
    800013a0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013a2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013a4:	00b67d63          	bgeu	a2,a1,800013be <uvmdealloc+0x26>
    800013a8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013aa:	6785                	lui	a5,0x1
    800013ac:	17fd                	addi	a5,a5,-1
    800013ae:	00f60733          	add	a4,a2,a5
    800013b2:	767d                	lui	a2,0xfffff
    800013b4:	8f71                	and	a4,a4,a2
    800013b6:	97ae                	add	a5,a5,a1
    800013b8:	8ff1                	and	a5,a5,a2
    800013ba:	00f76863          	bltu	a4,a5,800013ca <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013be:	8526                	mv	a0,s1
    800013c0:	60e2                	ld	ra,24(sp)
    800013c2:	6442                	ld	s0,16(sp)
    800013c4:	64a2                	ld	s1,8(sp)
    800013c6:	6105                	addi	sp,sp,32
    800013c8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013ca:	8f99                	sub	a5,a5,a4
    800013cc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013ce:	4685                	li	a3,1
    800013d0:	0007861b          	sext.w	a2,a5
    800013d4:	85ba                	mv	a1,a4
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	e6c080e7          	jalr	-404(ra) # 80001242 <uvmunmap>
    800013de:	b7c5                	j	800013be <uvmdealloc+0x26>

00000000800013e0 <uvmalloc>:
  if(newsz < oldsz)
    800013e0:	0ab66163          	bltu	a2,a1,80001482 <uvmalloc+0xa2>
{
    800013e4:	7139                	addi	sp,sp,-64
    800013e6:	fc06                	sd	ra,56(sp)
    800013e8:	f822                	sd	s0,48(sp)
    800013ea:	f426                	sd	s1,40(sp)
    800013ec:	f04a                	sd	s2,32(sp)
    800013ee:	ec4e                	sd	s3,24(sp)
    800013f0:	e852                	sd	s4,16(sp)
    800013f2:	e456                	sd	s5,8(sp)
    800013f4:	0080                	addi	s0,sp,64
    800013f6:	8aaa                	mv	s5,a0
    800013f8:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800013fa:	6985                	lui	s3,0x1
    800013fc:	19fd                	addi	s3,s3,-1
    800013fe:	95ce                	add	a1,a1,s3
    80001400:	79fd                	lui	s3,0xfffff
    80001402:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001406:	08c9f063          	bgeu	s3,a2,80001486 <uvmalloc+0xa6>
    8000140a:	894e                	mv	s2,s3
    mem = kalloc();
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	6c6080e7          	jalr	1734(ra) # 80000ad2 <kalloc>
    80001414:	84aa                	mv	s1,a0
    if(mem == 0){
    80001416:	c51d                	beqz	a0,80001444 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001418:	6605                	lui	a2,0x1
    8000141a:	4581                	li	a1,0
    8000141c:	00000097          	auipc	ra,0x0
    80001420:	8a2080e7          	jalr	-1886(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001424:	4779                	li	a4,30
    80001426:	86a6                	mv	a3,s1
    80001428:	6605                	lui	a2,0x1
    8000142a:	85ca                	mv	a1,s2
    8000142c:	8556                	mv	a0,s5
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	c60080e7          	jalr	-928(ra) # 8000108e <mappages>
    80001436:	e905                	bnez	a0,80001466 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	6785                	lui	a5,0x1
    8000143a:	993e                	add	s2,s2,a5
    8000143c:	fd4968e3          	bltu	s2,s4,8000140c <uvmalloc+0x2c>
  return newsz;
    80001440:	8552                	mv	a0,s4
    80001442:	a809                	j	80001454 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001444:	864e                	mv	a2,s3
    80001446:	85ca                	mv	a1,s2
    80001448:	8556                	mv	a0,s5
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	f4e080e7          	jalr	-178(ra) # 80001398 <uvmdealloc>
      return 0;
    80001452:	4501                	li	a0,0
}
    80001454:	70e2                	ld	ra,56(sp)
    80001456:	7442                	ld	s0,48(sp)
    80001458:	74a2                	ld	s1,40(sp)
    8000145a:	7902                	ld	s2,32(sp)
    8000145c:	69e2                	ld	s3,24(sp)
    8000145e:	6a42                	ld	s4,16(sp)
    80001460:	6aa2                	ld	s5,8(sp)
    80001462:	6121                	addi	sp,sp,64
    80001464:	8082                	ret
      kfree(mem);
    80001466:	8526                	mv	a0,s1
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	56e080e7          	jalr	1390(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001470:	864e                	mv	a2,s3
    80001472:	85ca                	mv	a1,s2
    80001474:	8556                	mv	a0,s5
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	f22080e7          	jalr	-222(ra) # 80001398 <uvmdealloc>
      return 0;
    8000147e:	4501                	li	a0,0
    80001480:	bfd1                	j	80001454 <uvmalloc+0x74>
    return oldsz;
    80001482:	852e                	mv	a0,a1
}
    80001484:	8082                	ret
  return newsz;
    80001486:	8532                	mv	a0,a2
    80001488:	b7f1                	j	80001454 <uvmalloc+0x74>

000000008000148a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000148a:	7179                	addi	sp,sp,-48
    8000148c:	f406                	sd	ra,40(sp)
    8000148e:	f022                	sd	s0,32(sp)
    80001490:	ec26                	sd	s1,24(sp)
    80001492:	e84a                	sd	s2,16(sp)
    80001494:	e44e                	sd	s3,8(sp)
    80001496:	e052                	sd	s4,0(sp)
    80001498:	1800                	addi	s0,sp,48
    8000149a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000149c:	84aa                	mv	s1,a0
    8000149e:	6905                	lui	s2,0x1
    800014a0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014a2:	4985                	li	s3,1
    800014a4:	a821                	j	800014bc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014a6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014a8:	0532                	slli	a0,a0,0xc
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	fe0080e7          	jalr	-32(ra) # 8000148a <freewalk>
      pagetable[i] = 0;
    800014b2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014b6:	04a1                	addi	s1,s1,8
    800014b8:	03248163          	beq	s1,s2,800014da <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014bc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014be:	00f57793          	andi	a5,a0,15
    800014c2:	ff3782e3          	beq	a5,s3,800014a6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014c6:	8905                	andi	a0,a0,1
    800014c8:	d57d                	beqz	a0,800014b6 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014ca:	00007517          	auipc	a0,0x7
    800014ce:	c7e50513          	addi	a0,a0,-898 # 80008148 <digits+0x108>
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	058080e7          	jalr	88(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014da:	8552                	mv	a0,s4
    800014dc:	fffff097          	auipc	ra,0xfffff
    800014e0:	4fa080e7          	jalr	1274(ra) # 800009d6 <kfree>
}
    800014e4:	70a2                	ld	ra,40(sp)
    800014e6:	7402                	ld	s0,32(sp)
    800014e8:	64e2                	ld	s1,24(sp)
    800014ea:	6942                	ld	s2,16(sp)
    800014ec:	69a2                	ld	s3,8(sp)
    800014ee:	6a02                	ld	s4,0(sp)
    800014f0:	6145                	addi	sp,sp,48
    800014f2:	8082                	ret

00000000800014f4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800014f4:	1101                	addi	sp,sp,-32
    800014f6:	ec06                	sd	ra,24(sp)
    800014f8:	e822                	sd	s0,16(sp)
    800014fa:	e426                	sd	s1,8(sp)
    800014fc:	1000                	addi	s0,sp,32
    800014fe:	84aa                	mv	s1,a0
  if(sz > 0)
    80001500:	e999                	bnez	a1,80001516 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001502:	8526                	mv	a0,s1
    80001504:	00000097          	auipc	ra,0x0
    80001508:	f86080e7          	jalr	-122(ra) # 8000148a <freewalk>
}
    8000150c:	60e2                	ld	ra,24(sp)
    8000150e:	6442                	ld	s0,16(sp)
    80001510:	64a2                	ld	s1,8(sp)
    80001512:	6105                	addi	sp,sp,32
    80001514:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001516:	6605                	lui	a2,0x1
    80001518:	167d                	addi	a2,a2,-1
    8000151a:	962e                	add	a2,a2,a1
    8000151c:	4685                	li	a3,1
    8000151e:	8231                	srli	a2,a2,0xc
    80001520:	4581                	li	a1,0
    80001522:	00000097          	auipc	ra,0x0
    80001526:	d20080e7          	jalr	-736(ra) # 80001242 <uvmunmap>
    8000152a:	bfe1                	j	80001502 <uvmfree+0xe>

000000008000152c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000152c:	c679                	beqz	a2,800015fa <uvmcopy+0xce>
{
    8000152e:	715d                	addi	sp,sp,-80
    80001530:	e486                	sd	ra,72(sp)
    80001532:	e0a2                	sd	s0,64(sp)
    80001534:	fc26                	sd	s1,56(sp)
    80001536:	f84a                	sd	s2,48(sp)
    80001538:	f44e                	sd	s3,40(sp)
    8000153a:	f052                	sd	s4,32(sp)
    8000153c:	ec56                	sd	s5,24(sp)
    8000153e:	e85a                	sd	s6,16(sp)
    80001540:	e45e                	sd	s7,8(sp)
    80001542:	0880                	addi	s0,sp,80
    80001544:	8b2a                	mv	s6,a0
    80001546:	8aae                	mv	s5,a1
    80001548:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000154a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000154c:	4601                	li	a2,0
    8000154e:	85ce                	mv	a1,s3
    80001550:	855a                	mv	a0,s6
    80001552:	00000097          	auipc	ra,0x0
    80001556:	a54080e7          	jalr	-1452(ra) # 80000fa6 <walk>
    8000155a:	c531                	beqz	a0,800015a6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000155c:	6118                	ld	a4,0(a0)
    8000155e:	00177793          	andi	a5,a4,1
    80001562:	cbb1                	beqz	a5,800015b6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001564:	00a75593          	srli	a1,a4,0xa
    80001568:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000156c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001570:	fffff097          	auipc	ra,0xfffff
    80001574:	562080e7          	jalr	1378(ra) # 80000ad2 <kalloc>
    80001578:	892a                	mv	s2,a0
    8000157a:	c939                	beqz	a0,800015d0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000157c:	6605                	lui	a2,0x1
    8000157e:	85de                	mv	a1,s7
    80001580:	fffff097          	auipc	ra,0xfffff
    80001584:	79a080e7          	jalr	1946(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001588:	8726                	mv	a4,s1
    8000158a:	86ca                	mv	a3,s2
    8000158c:	6605                	lui	a2,0x1
    8000158e:	85ce                	mv	a1,s3
    80001590:	8556                	mv	a0,s5
    80001592:	00000097          	auipc	ra,0x0
    80001596:	afc080e7          	jalr	-1284(ra) # 8000108e <mappages>
    8000159a:	e515                	bnez	a0,800015c6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000159c:	6785                	lui	a5,0x1
    8000159e:	99be                	add	s3,s3,a5
    800015a0:	fb49e6e3          	bltu	s3,s4,8000154c <uvmcopy+0x20>
    800015a4:	a081                	j	800015e4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015a6:	00007517          	auipc	a0,0x7
    800015aa:	bb250513          	addi	a0,a0,-1102 # 80008158 <digits+0x118>
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	f7c080e7          	jalr	-132(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	bc250513          	addi	a0,a0,-1086 # 80008178 <digits+0x138>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f6c080e7          	jalr	-148(ra) # 8000052a <panic>
      kfree(mem);
    800015c6:	854a                	mv	a0,s2
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	40e080e7          	jalr	1038(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015d0:	4685                	li	a3,1
    800015d2:	00c9d613          	srli	a2,s3,0xc
    800015d6:	4581                	li	a1,0
    800015d8:	8556                	mv	a0,s5
    800015da:	00000097          	auipc	ra,0x0
    800015de:	c68080e7          	jalr	-920(ra) # 80001242 <uvmunmap>
  return -1;
    800015e2:	557d                	li	a0,-1
}
    800015e4:	60a6                	ld	ra,72(sp)
    800015e6:	6406                	ld	s0,64(sp)
    800015e8:	74e2                	ld	s1,56(sp)
    800015ea:	7942                	ld	s2,48(sp)
    800015ec:	79a2                	ld	s3,40(sp)
    800015ee:	7a02                	ld	s4,32(sp)
    800015f0:	6ae2                	ld	s5,24(sp)
    800015f2:	6b42                	ld	s6,16(sp)
    800015f4:	6ba2                	ld	s7,8(sp)
    800015f6:	6161                	addi	sp,sp,80
    800015f8:	8082                	ret
  return 0;
    800015fa:	4501                	li	a0,0
}
    800015fc:	8082                	ret

00000000800015fe <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800015fe:	1141                	addi	sp,sp,-16
    80001600:	e406                	sd	ra,8(sp)
    80001602:	e022                	sd	s0,0(sp)
    80001604:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001606:	4601                	li	a2,0
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	99e080e7          	jalr	-1634(ra) # 80000fa6 <walk>
  if(pte == 0)
    80001610:	c901                	beqz	a0,80001620 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001612:	611c                	ld	a5,0(a0)
    80001614:	9bbd                	andi	a5,a5,-17
    80001616:	e11c                	sd	a5,0(a0)
}
    80001618:	60a2                	ld	ra,8(sp)
    8000161a:	6402                	ld	s0,0(sp)
    8000161c:	0141                	addi	sp,sp,16
    8000161e:	8082                	ret
    panic("uvmclear");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b7850513          	addi	a0,a0,-1160 # 80008198 <digits+0x158>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f02080e7          	jalr	-254(ra) # 8000052a <panic>

0000000080001630 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001630:	c6bd                	beqz	a3,8000169e <copyout+0x6e>
{
    80001632:	715d                	addi	sp,sp,-80
    80001634:	e486                	sd	ra,72(sp)
    80001636:	e0a2                	sd	s0,64(sp)
    80001638:	fc26                	sd	s1,56(sp)
    8000163a:	f84a                	sd	s2,48(sp)
    8000163c:	f44e                	sd	s3,40(sp)
    8000163e:	f052                	sd	s4,32(sp)
    80001640:	ec56                	sd	s5,24(sp)
    80001642:	e85a                	sd	s6,16(sp)
    80001644:	e45e                	sd	s7,8(sp)
    80001646:	e062                	sd	s8,0(sp)
    80001648:	0880                	addi	s0,sp,80
    8000164a:	8b2a                	mv	s6,a0
    8000164c:	8c2e                	mv	s8,a1
    8000164e:	8a32                	mv	s4,a2
    80001650:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001652:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001654:	6a85                	lui	s5,0x1
    80001656:	a015                	j	8000167a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001658:	9562                	add	a0,a0,s8
    8000165a:	0004861b          	sext.w	a2,s1
    8000165e:	85d2                	mv	a1,s4
    80001660:	41250533          	sub	a0,a0,s2
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	6b6080e7          	jalr	1718(ra) # 80000d1a <memmove>

    len -= n;
    8000166c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001670:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001672:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001676:	02098263          	beqz	s3,8000169a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000167a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000167e:	85ca                	mv	a1,s2
    80001680:	855a                	mv	a0,s6
    80001682:	00000097          	auipc	ra,0x0
    80001686:	9ca080e7          	jalr	-1590(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    8000168a:	cd01                	beqz	a0,800016a2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000168c:	418904b3          	sub	s1,s2,s8
    80001690:	94d6                	add	s1,s1,s5
    if(n > len)
    80001692:	fc99f3e3          	bgeu	s3,s1,80001658 <copyout+0x28>
    80001696:	84ce                	mv	s1,s3
    80001698:	b7c1                	j	80001658 <copyout+0x28>
  }
  return 0;
    8000169a:	4501                	li	a0,0
    8000169c:	a021                	j	800016a4 <copyout+0x74>
    8000169e:	4501                	li	a0,0
}
    800016a0:	8082                	ret
      return -1;
    800016a2:	557d                	li	a0,-1
}
    800016a4:	60a6                	ld	ra,72(sp)
    800016a6:	6406                	ld	s0,64(sp)
    800016a8:	74e2                	ld	s1,56(sp)
    800016aa:	7942                	ld	s2,48(sp)
    800016ac:	79a2                	ld	s3,40(sp)
    800016ae:	7a02                	ld	s4,32(sp)
    800016b0:	6ae2                	ld	s5,24(sp)
    800016b2:	6b42                	ld	s6,16(sp)
    800016b4:	6ba2                	ld	s7,8(sp)
    800016b6:	6c02                	ld	s8,0(sp)
    800016b8:	6161                	addi	sp,sp,80
    800016ba:	8082                	ret

00000000800016bc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016bc:	caa5                	beqz	a3,8000172c <copyin+0x70>
{
    800016be:	715d                	addi	sp,sp,-80
    800016c0:	e486                	sd	ra,72(sp)
    800016c2:	e0a2                	sd	s0,64(sp)
    800016c4:	fc26                	sd	s1,56(sp)
    800016c6:	f84a                	sd	s2,48(sp)
    800016c8:	f44e                	sd	s3,40(sp)
    800016ca:	f052                	sd	s4,32(sp)
    800016cc:	ec56                	sd	s5,24(sp)
    800016ce:	e85a                	sd	s6,16(sp)
    800016d0:	e45e                	sd	s7,8(sp)
    800016d2:	e062                	sd	s8,0(sp)
    800016d4:	0880                	addi	s0,sp,80
    800016d6:	8b2a                	mv	s6,a0
    800016d8:	8a2e                	mv	s4,a1
    800016da:	8c32                	mv	s8,a2
    800016dc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016de:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016e0:	6a85                	lui	s5,0x1
    800016e2:	a01d                	j	80001708 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016e4:	018505b3          	add	a1,a0,s8
    800016e8:	0004861b          	sext.w	a2,s1
    800016ec:	412585b3          	sub	a1,a1,s2
    800016f0:	8552                	mv	a0,s4
    800016f2:	fffff097          	auipc	ra,0xfffff
    800016f6:	628080e7          	jalr	1576(ra) # 80000d1a <memmove>

    len -= n;
    800016fa:	409989b3          	sub	s3,s3,s1
    dst += n;
    800016fe:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001700:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001704:	02098263          	beqz	s3,80001728 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001708:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000170c:	85ca                	mv	a1,s2
    8000170e:	855a                	mv	a0,s6
    80001710:	00000097          	auipc	ra,0x0
    80001714:	93c080e7          	jalr	-1732(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001718:	cd01                	beqz	a0,80001730 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000171a:	418904b3          	sub	s1,s2,s8
    8000171e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001720:	fc99f2e3          	bgeu	s3,s1,800016e4 <copyin+0x28>
    80001724:	84ce                	mv	s1,s3
    80001726:	bf7d                	j	800016e4 <copyin+0x28>
  }
  return 0;
    80001728:	4501                	li	a0,0
    8000172a:	a021                	j	80001732 <copyin+0x76>
    8000172c:	4501                	li	a0,0
}
    8000172e:	8082                	ret
      return -1;
    80001730:	557d                	li	a0,-1
}
    80001732:	60a6                	ld	ra,72(sp)
    80001734:	6406                	ld	s0,64(sp)
    80001736:	74e2                	ld	s1,56(sp)
    80001738:	7942                	ld	s2,48(sp)
    8000173a:	79a2                	ld	s3,40(sp)
    8000173c:	7a02                	ld	s4,32(sp)
    8000173e:	6ae2                	ld	s5,24(sp)
    80001740:	6b42                	ld	s6,16(sp)
    80001742:	6ba2                	ld	s7,8(sp)
    80001744:	6c02                	ld	s8,0(sp)
    80001746:	6161                	addi	sp,sp,80
    80001748:	8082                	ret

000000008000174a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000174a:	c6c5                	beqz	a3,800017f2 <copyinstr+0xa8>
{
    8000174c:	715d                	addi	sp,sp,-80
    8000174e:	e486                	sd	ra,72(sp)
    80001750:	e0a2                	sd	s0,64(sp)
    80001752:	fc26                	sd	s1,56(sp)
    80001754:	f84a                	sd	s2,48(sp)
    80001756:	f44e                	sd	s3,40(sp)
    80001758:	f052                	sd	s4,32(sp)
    8000175a:	ec56                	sd	s5,24(sp)
    8000175c:	e85a                	sd	s6,16(sp)
    8000175e:	e45e                	sd	s7,8(sp)
    80001760:	0880                	addi	s0,sp,80
    80001762:	8a2a                	mv	s4,a0
    80001764:	8b2e                	mv	s6,a1
    80001766:	8bb2                	mv	s7,a2
    80001768:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000176a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000176c:	6985                	lui	s3,0x1
    8000176e:	a035                	j	8000179a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001770:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001774:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001776:	0017b793          	seqz	a5,a5
    8000177a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000177e:	60a6                	ld	ra,72(sp)
    80001780:	6406                	ld	s0,64(sp)
    80001782:	74e2                	ld	s1,56(sp)
    80001784:	7942                	ld	s2,48(sp)
    80001786:	79a2                	ld	s3,40(sp)
    80001788:	7a02                	ld	s4,32(sp)
    8000178a:	6ae2                	ld	s5,24(sp)
    8000178c:	6b42                	ld	s6,16(sp)
    8000178e:	6ba2                	ld	s7,8(sp)
    80001790:	6161                	addi	sp,sp,80
    80001792:	8082                	ret
    srcva = va0 + PGSIZE;
    80001794:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001798:	c8a9                	beqz	s1,800017ea <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000179a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000179e:	85ca                	mv	a1,s2
    800017a0:	8552                	mv	a0,s4
    800017a2:	00000097          	auipc	ra,0x0
    800017a6:	8aa080e7          	jalr	-1878(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017aa:	c131                	beqz	a0,800017ee <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ac:	41790833          	sub	a6,s2,s7
    800017b0:	984e                	add	a6,a6,s3
    if(n > max)
    800017b2:	0104f363          	bgeu	s1,a6,800017b8 <copyinstr+0x6e>
    800017b6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017b8:	955e                	add	a0,a0,s7
    800017ba:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017be:	fc080be3          	beqz	a6,80001794 <copyinstr+0x4a>
    800017c2:	985a                	add	a6,a6,s6
    800017c4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017c6:	41650633          	sub	a2,a0,s6
    800017ca:	14fd                	addi	s1,s1,-1
    800017cc:	9b26                	add	s6,s6,s1
    800017ce:	00f60733          	add	a4,a2,a5
    800017d2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017d6:	df49                	beqz	a4,80001770 <copyinstr+0x26>
        *dst = *p;
    800017d8:	00e78023          	sb	a4,0(a5)
      --max;
    800017dc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017e0:	0785                	addi	a5,a5,1
    while(n > 0){
    800017e2:	ff0796e3          	bne	a5,a6,800017ce <copyinstr+0x84>
      dst++;
    800017e6:	8b42                	mv	s6,a6
    800017e8:	b775                	j	80001794 <copyinstr+0x4a>
    800017ea:	4781                	li	a5,0
    800017ec:	b769                	j	80001776 <copyinstr+0x2c>
      return -1;
    800017ee:	557d                	li	a0,-1
    800017f0:	b779                	j	8000177e <copyinstr+0x34>
  int got_null = 0;
    800017f2:	4781                	li	a5,0
  if(got_null){
    800017f4:	0017b793          	seqz	a5,a5
    800017f8:	40f00533          	neg	a0,a5
}
    800017fc:	8082                	ret

00000000800017fe <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800017fe:	7139                	addi	sp,sp,-64
    80001800:	fc06                	sd	ra,56(sp)
    80001802:	f822                	sd	s0,48(sp)
    80001804:	f426                	sd	s1,40(sp)
    80001806:	f04a                	sd	s2,32(sp)
    80001808:	ec4e                	sd	s3,24(sp)
    8000180a:	e852                	sd	s4,16(sp)
    8000180c:	e456                	sd	s5,8(sp)
    8000180e:	e05a                	sd	s6,0(sp)
    80001810:	0080                	addi	s0,sp,64
    80001812:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001814:	00010497          	auipc	s1,0x10
    80001818:	ebc48493          	addi	s1,s1,-324 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000181c:	8b26                	mv	s6,s1
    8000181e:	00006a97          	auipc	s5,0x6
    80001822:	7e2a8a93          	addi	s5,s5,2018 # 80008000 <etext>
    80001826:	04000937          	lui	s2,0x4000
    8000182a:	197d                	addi	s2,s2,-1
    8000182c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000182e:	00016a17          	auipc	s4,0x16
    80001832:	8a2a0a13          	addi	s4,s4,-1886 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001836:	fffff097          	auipc	ra,0xfffff
    8000183a:	29c080e7          	jalr	668(ra) # 80000ad2 <kalloc>
    8000183e:	862a                	mv	a2,a0
    if(pa == 0)
    80001840:	c131                	beqz	a0,80001884 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001842:	416485b3          	sub	a1,s1,s6
    80001846:	858d                	srai	a1,a1,0x3
    80001848:	000ab783          	ld	a5,0(s5)
    8000184c:	02f585b3          	mul	a1,a1,a5
    80001850:	2585                	addiw	a1,a1,1
    80001852:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001856:	4719                	li	a4,6
    80001858:	6685                	lui	a3,0x1
    8000185a:	40b905b3          	sub	a1,s2,a1
    8000185e:	854e                	mv	a0,s3
    80001860:	00000097          	auipc	ra,0x0
    80001864:	8bc080e7          	jalr	-1860(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001868:	16848493          	addi	s1,s1,360
    8000186c:	fd4495e3          	bne	s1,s4,80001836 <proc_mapstacks+0x38>
  }
}
    80001870:	70e2                	ld	ra,56(sp)
    80001872:	7442                	ld	s0,48(sp)
    80001874:	74a2                	ld	s1,40(sp)
    80001876:	7902                	ld	s2,32(sp)
    80001878:	69e2                	ld	s3,24(sp)
    8000187a:	6a42                	ld	s4,16(sp)
    8000187c:	6aa2                	ld	s5,8(sp)
    8000187e:	6b02                	ld	s6,0(sp)
    80001880:	6121                	addi	sp,sp,64
    80001882:	8082                	ret
      panic("kalloc");
    80001884:	00007517          	auipc	a0,0x7
    80001888:	92450513          	addi	a0,a0,-1756 # 800081a8 <digits+0x168>
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	c9e080e7          	jalr	-866(ra) # 8000052a <panic>

0000000080001894 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001894:	7139                	addi	sp,sp,-64
    80001896:	fc06                	sd	ra,56(sp)
    80001898:	f822                	sd	s0,48(sp)
    8000189a:	f426                	sd	s1,40(sp)
    8000189c:	f04a                	sd	s2,32(sp)
    8000189e:	ec4e                	sd	s3,24(sp)
    800018a0:	e852                	sd	s4,16(sp)
    800018a2:	e456                	sd	s5,8(sp)
    800018a4:	e05a                	sd	s6,0(sp)
    800018a6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018a8:	00007597          	auipc	a1,0x7
    800018ac:	90858593          	addi	a1,a1,-1784 # 800081b0 <digits+0x170>
    800018b0:	00010517          	auipc	a0,0x10
    800018b4:	9f050513          	addi	a0,a0,-1552 # 800112a0 <pid_lock>
    800018b8:	fffff097          	auipc	ra,0xfffff
    800018bc:	27a080e7          	jalr	634(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018c0:	00007597          	auipc	a1,0x7
    800018c4:	8f858593          	addi	a1,a1,-1800 # 800081b8 <digits+0x178>
    800018c8:	00010517          	auipc	a0,0x10
    800018cc:	9f050513          	addi	a0,a0,-1552 # 800112b8 <wait_lock>
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	262080e7          	jalr	610(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d8:	00010497          	auipc	s1,0x10
    800018dc:	df848493          	addi	s1,s1,-520 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    800018e0:	00007b17          	auipc	s6,0x7
    800018e4:	8e8b0b13          	addi	s6,s6,-1816 # 800081c8 <digits+0x188>
      p->kstack = KSTACK((int) (p - proc));
    800018e8:	8aa6                	mv	s5,s1
    800018ea:	00006a17          	auipc	s4,0x6
    800018ee:	716a0a13          	addi	s4,s4,1814 # 80008000 <etext>
    800018f2:	04000937          	lui	s2,0x4000
    800018f6:	197d                	addi	s2,s2,-1
    800018f8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fa:	00015997          	auipc	s3,0x15
    800018fe:	7d698993          	addi	s3,s3,2006 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001902:	85da                	mv	a1,s6
    80001904:	8526                	mv	a0,s1
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	22c080e7          	jalr	556(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	415487b3          	sub	a5,s1,s5
    80001912:	878d                	srai	a5,a5,0x3
    80001914:	000a3703          	ld	a4,0(s4)
    80001918:	02e787b3          	mul	a5,a5,a4
    8000191c:	2785                	addiw	a5,a5,1
    8000191e:	00d7979b          	slliw	a5,a5,0xd
    80001922:	40f907b3          	sub	a5,s2,a5
    80001926:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	16848493          	addi	s1,s1,360
    8000192c:	fd349be3          	bne	s1,s3,80001902 <procinit+0x6e>
  }
}
    80001930:	70e2                	ld	ra,56(sp)
    80001932:	7442                	ld	s0,48(sp)
    80001934:	74a2                	ld	s1,40(sp)
    80001936:	7902                	ld	s2,32(sp)
    80001938:	69e2                	ld	s3,24(sp)
    8000193a:	6a42                	ld	s4,16(sp)
    8000193c:	6aa2                	ld	s5,8(sp)
    8000193e:	6b02                	ld	s6,0(sp)
    80001940:	6121                	addi	sp,sp,64
    80001942:	8082                	ret

0000000080001944 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001944:	1141                	addi	sp,sp,-16
    80001946:	e422                	sd	s0,8(sp)
    80001948:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000194a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000194c:	2501                	sext.w	a0,a0
    8000194e:	6422                	ld	s0,8(sp)
    80001950:	0141                	addi	sp,sp,16
    80001952:	8082                	ret

0000000080001954 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001954:	1141                	addi	sp,sp,-16
    80001956:	e422                	sd	s0,8(sp)
    80001958:	0800                	addi	s0,sp,16
    8000195a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000195c:	2781                	sext.w	a5,a5
    8000195e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001960:	00010517          	auipc	a0,0x10
    80001964:	97050513          	addi	a0,a0,-1680 # 800112d0 <cpus>
    80001968:	953e                	add	a0,a0,a5
    8000196a:	6422                	ld	s0,8(sp)
    8000196c:	0141                	addi	sp,sp,16
    8000196e:	8082                	ret

0000000080001970 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001970:	1101                	addi	sp,sp,-32
    80001972:	ec06                	sd	ra,24(sp)
    80001974:	e822                	sd	s0,16(sp)
    80001976:	e426                	sd	s1,8(sp)
    80001978:	1000                	addi	s0,sp,32
  push_off();
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	1fc080e7          	jalr	508(ra) # 80000b76 <push_off>
    80001982:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001984:	2781                	sext.w	a5,a5
    80001986:	079e                	slli	a5,a5,0x7
    80001988:	00010717          	auipc	a4,0x10
    8000198c:	91870713          	addi	a4,a4,-1768 # 800112a0 <pid_lock>
    80001990:	97ba                	add	a5,a5,a4
    80001992:	7b84                	ld	s1,48(a5)
  pop_off();
    80001994:	fffff097          	auipc	ra,0xfffff
    80001998:	282080e7          	jalr	642(ra) # 80000c16 <pop_off>
  return p;
}
    8000199c:	8526                	mv	a0,s1
    8000199e:	60e2                	ld	ra,24(sp)
    800019a0:	6442                	ld	s0,16(sp)
    800019a2:	64a2                	ld	s1,8(sp)
    800019a4:	6105                	addi	sp,sp,32
    800019a6:	8082                	ret

00000000800019a8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019a8:	1141                	addi	sp,sp,-16
    800019aa:	e406                	sd	ra,8(sp)
    800019ac:	e022                	sd	s0,0(sp)
    800019ae:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019b0:	00000097          	auipc	ra,0x0
    800019b4:	fc0080e7          	jalr	-64(ra) # 80001970 <myproc>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	2be080e7          	jalr	702(ra) # 80000c76 <release>

  if (first) {
    800019c0:	00007797          	auipc	a5,0x7
    800019c4:	e407a783          	lw	a5,-448(a5) # 80008800 <first.1>
    800019c8:	eb89                	bnez	a5,800019da <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ca:	00001097          	auipc	ra,0x1
    800019ce:	c10080e7          	jalr	-1008(ra) # 800025da <usertrapret>
}
    800019d2:	60a2                	ld	ra,8(sp)
    800019d4:	6402                	ld	s0,0(sp)
    800019d6:	0141                	addi	sp,sp,16
    800019d8:	8082                	ret
    first = 0;
    800019da:	00007797          	auipc	a5,0x7
    800019de:	e207a323          	sw	zero,-474(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    800019e2:	4505                	li	a0,1
    800019e4:	00002097          	auipc	ra,0x2
    800019e8:	9a0080e7          	jalr	-1632(ra) # 80003384 <fsinit>
    800019ec:	bff9                	j	800019ca <forkret+0x22>

00000000800019ee <allocpid>:
allocpid() {
    800019ee:	1101                	addi	sp,sp,-32
    800019f0:	ec06                	sd	ra,24(sp)
    800019f2:	e822                	sd	s0,16(sp)
    800019f4:	e426                	sd	s1,8(sp)
    800019f6:	e04a                	sd	s2,0(sp)
    800019f8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019fa:	00010917          	auipc	s2,0x10
    800019fe:	8a690913          	addi	s2,s2,-1882 # 800112a0 <pid_lock>
    80001a02:	854a                	mv	a0,s2
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	1be080e7          	jalr	446(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a0c:	00007797          	auipc	a5,0x7
    80001a10:	df878793          	addi	a5,a5,-520 # 80008804 <nextpid>
    80001a14:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a16:	0014871b          	addiw	a4,s1,1
    80001a1a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a1c:	854a                	mv	a0,s2
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	258080e7          	jalr	600(ra) # 80000c76 <release>
}
    80001a26:	8526                	mv	a0,s1
    80001a28:	60e2                	ld	ra,24(sp)
    80001a2a:	6442                	ld	s0,16(sp)
    80001a2c:	64a2                	ld	s1,8(sp)
    80001a2e:	6902                	ld	s2,0(sp)
    80001a30:	6105                	addi	sp,sp,32
    80001a32:	8082                	ret

0000000080001a34 <proc_pagetable>:
{
    80001a34:	1101                	addi	sp,sp,-32
    80001a36:	ec06                	sd	ra,24(sp)
    80001a38:	e822                	sd	s0,16(sp)
    80001a3a:	e426                	sd	s1,8(sp)
    80001a3c:	e04a                	sd	s2,0(sp)
    80001a3e:	1000                	addi	s0,sp,32
    80001a40:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	8b6080e7          	jalr	-1866(ra) # 800012f8 <uvmcreate>
    80001a4a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a4c:	c121                	beqz	a0,80001a8c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a4e:	4729                	li	a4,10
    80001a50:	00005697          	auipc	a3,0x5
    80001a54:	5b068693          	addi	a3,a3,1456 # 80007000 <_trampoline>
    80001a58:	6605                	lui	a2,0x1
    80001a5a:	040005b7          	lui	a1,0x4000
    80001a5e:	15fd                	addi	a1,a1,-1
    80001a60:	05b2                	slli	a1,a1,0xc
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	62c080e7          	jalr	1580(ra) # 8000108e <mappages>
    80001a6a:	02054863          	bltz	a0,80001a9a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a6e:	4719                	li	a4,6
    80001a70:	05893683          	ld	a3,88(s2)
    80001a74:	6605                	lui	a2,0x1
    80001a76:	020005b7          	lui	a1,0x2000
    80001a7a:	15fd                	addi	a1,a1,-1
    80001a7c:	05b6                	slli	a1,a1,0xd
    80001a7e:	8526                	mv	a0,s1
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	60e080e7          	jalr	1550(ra) # 8000108e <mappages>
    80001a88:	02054163          	bltz	a0,80001aaa <proc_pagetable+0x76>
}
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	60e2                	ld	ra,24(sp)
    80001a90:	6442                	ld	s0,16(sp)
    80001a92:	64a2                	ld	s1,8(sp)
    80001a94:	6902                	ld	s2,0(sp)
    80001a96:	6105                	addi	sp,sp,32
    80001a98:	8082                	ret
    uvmfree(pagetable, 0);
    80001a9a:	4581                	li	a1,0
    80001a9c:	8526                	mv	a0,s1
    80001a9e:	00000097          	auipc	ra,0x0
    80001aa2:	a56080e7          	jalr	-1450(ra) # 800014f4 <uvmfree>
    return 0;
    80001aa6:	4481                	li	s1,0
    80001aa8:	b7d5                	j	80001a8c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aaa:	4681                	li	a3,0
    80001aac:	4605                	li	a2,1
    80001aae:	040005b7          	lui	a1,0x4000
    80001ab2:	15fd                	addi	a1,a1,-1
    80001ab4:	05b2                	slli	a1,a1,0xc
    80001ab6:	8526                	mv	a0,s1
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	78a080e7          	jalr	1930(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a30080e7          	jalr	-1488(ra) # 800014f4 <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	bf7d                	j	80001a8c <proc_pagetable+0x58>

0000000080001ad0 <proc_freepagetable>:
{
    80001ad0:	1101                	addi	sp,sp,-32
    80001ad2:	ec06                	sd	ra,24(sp)
    80001ad4:	e822                	sd	s0,16(sp)
    80001ad6:	e426                	sd	s1,8(sp)
    80001ad8:	e04a                	sd	s2,0(sp)
    80001ada:	1000                	addi	s0,sp,32
    80001adc:	84aa                	mv	s1,a0
    80001ade:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	756080e7          	jalr	1878(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001af4:	4681                	li	a3,0
    80001af6:	4605                	li	a2,1
    80001af8:	020005b7          	lui	a1,0x2000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b6                	slli	a1,a1,0xd
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	740080e7          	jalr	1856(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b0a:	85ca                	mv	a1,s2
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	9e6080e7          	jalr	-1562(ra) # 800014f4 <uvmfree>
}
    80001b16:	60e2                	ld	ra,24(sp)
    80001b18:	6442                	ld	s0,16(sp)
    80001b1a:	64a2                	ld	s1,8(sp)
    80001b1c:	6902                	ld	s2,0(sp)
    80001b1e:	6105                	addi	sp,sp,32
    80001b20:	8082                	ret

0000000080001b22 <freeproc>:
{
    80001b22:	1101                	addi	sp,sp,-32
    80001b24:	ec06                	sd	ra,24(sp)
    80001b26:	e822                	sd	s0,16(sp)
    80001b28:	e426                	sd	s1,8(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b2e:	6d28                	ld	a0,88(a0)
    80001b30:	c509                	beqz	a0,80001b3a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	ea4080e7          	jalr	-348(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b3a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b3e:	68a8                	ld	a0,80(s1)
    80001b40:	c511                	beqz	a0,80001b4c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b42:	64ac                	ld	a1,72(s1)
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	f8c080e7          	jalr	-116(ra) # 80001ad0 <proc_freepagetable>
  p->pagetable = 0;
    80001b4c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b50:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b54:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b58:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b5c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b60:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b64:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b68:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b6c:	0004ac23          	sw	zero,24(s1)
}
    80001b70:	60e2                	ld	ra,24(sp)
    80001b72:	6442                	ld	s0,16(sp)
    80001b74:	64a2                	ld	s1,8(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret

0000000080001b7a <allocproc>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	e04a                	sd	s2,0(sp)
    80001b84:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b86:	00010497          	auipc	s1,0x10
    80001b8a:	b4a48493          	addi	s1,s1,-1206 # 800116d0 <proc>
    80001b8e:	00015917          	auipc	s2,0x15
    80001b92:	54290913          	addi	s2,s2,1346 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001b96:	8526                	mv	a0,s1
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	02a080e7          	jalr	42(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001ba0:	4c9c                	lw	a5,24(s1)
    80001ba2:	cf81                	beqz	a5,80001bba <allocproc+0x40>
      release(&p->lock);
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	0d0080e7          	jalr	208(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bae:	16848493          	addi	s1,s1,360
    80001bb2:	ff2492e3          	bne	s1,s2,80001b96 <allocproc+0x1c>
  return 0;
    80001bb6:	4481                	li	s1,0
    80001bb8:	a889                	j	80001c0a <allocproc+0x90>
  p->pid = allocpid();
    80001bba:	00000097          	auipc	ra,0x0
    80001bbe:	e34080e7          	jalr	-460(ra) # 800019ee <allocpid>
    80001bc2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bc4:	4785                	li	a5,1
    80001bc6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	f0a080e7          	jalr	-246(ra) # 80000ad2 <kalloc>
    80001bd0:	892a                	mv	s2,a0
    80001bd2:	eca8                	sd	a0,88(s1)
    80001bd4:	c131                	beqz	a0,80001c18 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	00000097          	auipc	ra,0x0
    80001bdc:	e5c080e7          	jalr	-420(ra) # 80001a34 <proc_pagetable>
    80001be0:	892a                	mv	s2,a0
    80001be2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001be4:	c531                	beqz	a0,80001c30 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001be6:	07000613          	li	a2,112
    80001bea:	4581                	li	a1,0
    80001bec:	06048513          	addi	a0,s1,96
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	0ce080e7          	jalr	206(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001bf8:	00000797          	auipc	a5,0x0
    80001bfc:	db078793          	addi	a5,a5,-592 # 800019a8 <forkret>
    80001c00:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c02:	60bc                	ld	a5,64(s1)
    80001c04:	6705                	lui	a4,0x1
    80001c06:	97ba                	add	a5,a5,a4
    80001c08:	f4bc                	sd	a5,104(s1)
}
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	60e2                	ld	ra,24(sp)
    80001c0e:	6442                	ld	s0,16(sp)
    80001c10:	64a2                	ld	s1,8(sp)
    80001c12:	6902                	ld	s2,0(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret
    freeproc(p);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	f08080e7          	jalr	-248(ra) # 80001b22 <freeproc>
    release(&p->lock);
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	052080e7          	jalr	82(ra) # 80000c76 <release>
    return 0;
    80001c2c:	84ca                	mv	s1,s2
    80001c2e:	bff1                	j	80001c0a <allocproc+0x90>
    freeproc(p);
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	ef0080e7          	jalr	-272(ra) # 80001b22 <freeproc>
    release(&p->lock);
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	03a080e7          	jalr	58(ra) # 80000c76 <release>
    return 0;
    80001c44:	84ca                	mv	s1,s2
    80001c46:	b7d1                	j	80001c0a <allocproc+0x90>

0000000080001c48 <userinit>:
{
    80001c48:	1101                	addi	sp,sp,-32
    80001c4a:	ec06                	sd	ra,24(sp)
    80001c4c:	e822                	sd	s0,16(sp)
    80001c4e:	e426                	sd	s1,8(sp)
    80001c50:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	f28080e7          	jalr	-216(ra) # 80001b7a <allocproc>
    80001c5a:	84aa                	mv	s1,a0
  initproc = p;
    80001c5c:	00007797          	auipc	a5,0x7
    80001c60:	3ca7b623          	sd	a0,972(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c64:	03400613          	li	a2,52
    80001c68:	00007597          	auipc	a1,0x7
    80001c6c:	ba858593          	addi	a1,a1,-1112 # 80008810 <initcode>
    80001c70:	6928                	ld	a0,80(a0)
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	6b4080e7          	jalr	1716(ra) # 80001326 <uvminit>
  p->sz = PGSIZE;
    80001c7a:	6785                	lui	a5,0x1
    80001c7c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001c7e:	6cb8                	ld	a4,88(s1)
    80001c80:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001c84:	6cb8                	ld	a4,88(s1)
    80001c86:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c88:	4641                	li	a2,16
    80001c8a:	00006597          	auipc	a1,0x6
    80001c8e:	54658593          	addi	a1,a1,1350 # 800081d0 <digits+0x190>
    80001c92:	15848513          	addi	a0,s1,344
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	17a080e7          	jalr	378(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001c9e:	00006517          	auipc	a0,0x6
    80001ca2:	54250513          	addi	a0,a0,1346 # 800081e0 <digits+0x1a0>
    80001ca6:	00002097          	auipc	ra,0x2
    80001caa:	10c080e7          	jalr	268(ra) # 80003db2 <namei>
    80001cae:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cb2:	478d                	li	a5,3
    80001cb4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fbe080e7          	jalr	-66(ra) # 80000c76 <release>
}
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6105                	addi	sp,sp,32
    80001cc8:	8082                	ret

0000000080001cca <growproc>:
{
    80001cca:	1101                	addi	sp,sp,-32
    80001ccc:	ec06                	sd	ra,24(sp)
    80001cce:	e822                	sd	s0,16(sp)
    80001cd0:	e426                	sd	s1,8(sp)
    80001cd2:	e04a                	sd	s2,0(sp)
    80001cd4:	1000                	addi	s0,sp,32
    80001cd6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	c98080e7          	jalr	-872(ra) # 80001970 <myproc>
    80001ce0:	892a                	mv	s2,a0
  sz = p->sz;
    80001ce2:	652c                	ld	a1,72(a0)
    80001ce4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ce8:	00904f63          	bgtz	s1,80001d06 <growproc+0x3c>
  } else if(n < 0){
    80001cec:	0204cc63          	bltz	s1,80001d24 <growproc+0x5a>
  p->sz = sz;
    80001cf0:	1602                	slli	a2,a2,0x20
    80001cf2:	9201                	srli	a2,a2,0x20
    80001cf4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001cf8:	4501                	li	a0,0
}
    80001cfa:	60e2                	ld	ra,24(sp)
    80001cfc:	6442                	ld	s0,16(sp)
    80001cfe:	64a2                	ld	s1,8(sp)
    80001d00:	6902                	ld	s2,0(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d06:	9e25                	addw	a2,a2,s1
    80001d08:	1602                	slli	a2,a2,0x20
    80001d0a:	9201                	srli	a2,a2,0x20
    80001d0c:	1582                	slli	a1,a1,0x20
    80001d0e:	9181                	srli	a1,a1,0x20
    80001d10:	6928                	ld	a0,80(a0)
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	6ce080e7          	jalr	1742(ra) # 800013e0 <uvmalloc>
    80001d1a:	0005061b          	sext.w	a2,a0
    80001d1e:	fa69                	bnez	a2,80001cf0 <growproc+0x26>
      return -1;
    80001d20:	557d                	li	a0,-1
    80001d22:	bfe1                	j	80001cfa <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d24:	9e25                	addw	a2,a2,s1
    80001d26:	1602                	slli	a2,a2,0x20
    80001d28:	9201                	srli	a2,a2,0x20
    80001d2a:	1582                	slli	a1,a1,0x20
    80001d2c:	9181                	srli	a1,a1,0x20
    80001d2e:	6928                	ld	a0,80(a0)
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	668080e7          	jalr	1640(ra) # 80001398 <uvmdealloc>
    80001d38:	0005061b          	sext.w	a2,a0
    80001d3c:	bf55                	j	80001cf0 <growproc+0x26>

0000000080001d3e <fork>:
{
    80001d3e:	7139                	addi	sp,sp,-64
    80001d40:	fc06                	sd	ra,56(sp)
    80001d42:	f822                	sd	s0,48(sp)
    80001d44:	f426                	sd	s1,40(sp)
    80001d46:	f04a                	sd	s2,32(sp)
    80001d48:	ec4e                	sd	s3,24(sp)
    80001d4a:	e852                	sd	s4,16(sp)
    80001d4c:	e456                	sd	s5,8(sp)
    80001d4e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	c20080e7          	jalr	-992(ra) # 80001970 <myproc>
    80001d58:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	e20080e7          	jalr	-480(ra) # 80001b7a <allocproc>
    80001d62:	10050c63          	beqz	a0,80001e7a <fork+0x13c>
    80001d66:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d68:	048ab603          	ld	a2,72(s5)
    80001d6c:	692c                	ld	a1,80(a0)
    80001d6e:	050ab503          	ld	a0,80(s5)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	7ba080e7          	jalr	1978(ra) # 8000152c <uvmcopy>
    80001d7a:	04054863          	bltz	a0,80001dca <fork+0x8c>
  np->sz = p->sz;
    80001d7e:	048ab783          	ld	a5,72(s5)
    80001d82:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001d86:	058ab683          	ld	a3,88(s5)
    80001d8a:	87b6                	mv	a5,a3
    80001d8c:	058a3703          	ld	a4,88(s4)
    80001d90:	12068693          	addi	a3,a3,288
    80001d94:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001d98:	6788                	ld	a0,8(a5)
    80001d9a:	6b8c                	ld	a1,16(a5)
    80001d9c:	6f90                	ld	a2,24(a5)
    80001d9e:	01073023          	sd	a6,0(a4)
    80001da2:	e708                	sd	a0,8(a4)
    80001da4:	eb0c                	sd	a1,16(a4)
    80001da6:	ef10                	sd	a2,24(a4)
    80001da8:	02078793          	addi	a5,a5,32
    80001dac:	02070713          	addi	a4,a4,32
    80001db0:	fed792e3          	bne	a5,a3,80001d94 <fork+0x56>
  np->trapframe->a0 = 0;
    80001db4:	058a3783          	ld	a5,88(s4)
    80001db8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dbc:	0d0a8493          	addi	s1,s5,208
    80001dc0:	0d0a0913          	addi	s2,s4,208
    80001dc4:	150a8993          	addi	s3,s5,336
    80001dc8:	a00d                	j	80001dea <fork+0xac>
    freeproc(np);
    80001dca:	8552                	mv	a0,s4
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	d56080e7          	jalr	-682(ra) # 80001b22 <freeproc>
    release(&np->lock);
    80001dd4:	8552                	mv	a0,s4
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	ea0080e7          	jalr	-352(ra) # 80000c76 <release>
    return -1;
    80001dde:	597d                	li	s2,-1
    80001de0:	a059                	j	80001e66 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001de2:	04a1                	addi	s1,s1,8
    80001de4:	0921                	addi	s2,s2,8
    80001de6:	01348b63          	beq	s1,s3,80001dfc <fork+0xbe>
    if(p->ofile[i])
    80001dea:	6088                	ld	a0,0(s1)
    80001dec:	d97d                	beqz	a0,80001de2 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001dee:	00002097          	auipc	ra,0x2
    80001df2:	65e080e7          	jalr	1630(ra) # 8000444c <filedup>
    80001df6:	00a93023          	sd	a0,0(s2)
    80001dfa:	b7e5                	j	80001de2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001dfc:	150ab503          	ld	a0,336(s5)
    80001e00:	00001097          	auipc	ra,0x1
    80001e04:	7be080e7          	jalr	1982(ra) # 800035be <idup>
    80001e08:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e0c:	4641                	li	a2,16
    80001e0e:	158a8593          	addi	a1,s5,344
    80001e12:	158a0513          	addi	a0,s4,344
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	ffa080e7          	jalr	-6(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e1e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e22:	8552                	mv	a0,s4
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e52080e7          	jalr	-430(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e2c:	0000f497          	auipc	s1,0xf
    80001e30:	48c48493          	addi	s1,s1,1164 # 800112b8 <wait_lock>
    80001e34:	8526                	mv	a0,s1
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	d8c080e7          	jalr	-628(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e3e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	e32080e7          	jalr	-462(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	d74080e7          	jalr	-652(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e56:	478d                	li	a5,3
    80001e58:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e5c:	8552                	mv	a0,s4
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	e18080e7          	jalr	-488(ra) # 80000c76 <release>
}
    80001e66:	854a                	mv	a0,s2
    80001e68:	70e2                	ld	ra,56(sp)
    80001e6a:	7442                	ld	s0,48(sp)
    80001e6c:	74a2                	ld	s1,40(sp)
    80001e6e:	7902                	ld	s2,32(sp)
    80001e70:	69e2                	ld	s3,24(sp)
    80001e72:	6a42                	ld	s4,16(sp)
    80001e74:	6aa2                	ld	s5,8(sp)
    80001e76:	6121                	addi	sp,sp,64
    80001e78:	8082                	ret
    return -1;
    80001e7a:	597d                	li	s2,-1
    80001e7c:	b7ed                	j	80001e66 <fork+0x128>

0000000080001e7e <scheduler>:
{
    80001e7e:	7139                	addi	sp,sp,-64
    80001e80:	fc06                	sd	ra,56(sp)
    80001e82:	f822                	sd	s0,48(sp)
    80001e84:	f426                	sd	s1,40(sp)
    80001e86:	f04a                	sd	s2,32(sp)
    80001e88:	ec4e                	sd	s3,24(sp)
    80001e8a:	e852                	sd	s4,16(sp)
    80001e8c:	e456                	sd	s5,8(sp)
    80001e8e:	e05a                	sd	s6,0(sp)
    80001e90:	0080                	addi	s0,sp,64
    80001e92:	8792                	mv	a5,tp
  int id = r_tp();
    80001e94:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e96:	00779a93          	slli	s5,a5,0x7
    80001e9a:	0000f717          	auipc	a4,0xf
    80001e9e:	40670713          	addi	a4,a4,1030 # 800112a0 <pid_lock>
    80001ea2:	9756                	add	a4,a4,s5
    80001ea4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ea8:	0000f717          	auipc	a4,0xf
    80001eac:	43070713          	addi	a4,a4,1072 # 800112d8 <cpus+0x8>
    80001eb0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eb2:	498d                	li	s3,3
        p->state = RUNNING;
    80001eb4:	4b11                	li	s6,4
        c->proc = p;
    80001eb6:	079e                	slli	a5,a5,0x7
    80001eb8:	0000fa17          	auipc	s4,0xf
    80001ebc:	3e8a0a13          	addi	s4,s4,1000 # 800112a0 <pid_lock>
    80001ec0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ec2:	00015917          	auipc	s2,0x15
    80001ec6:	20e90913          	addi	s2,s2,526 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ece:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ed2:	10079073          	csrw	sstatus,a5
    80001ed6:	0000f497          	auipc	s1,0xf
    80001eda:	7fa48493          	addi	s1,s1,2042 # 800116d0 <proc>
    80001ede:	a811                	j	80001ef2 <scheduler+0x74>
      release(&p->lock);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	d94080e7          	jalr	-620(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eea:	16848493          	addi	s1,s1,360
    80001eee:	fd248ee3          	beq	s1,s2,80001eca <scheduler+0x4c>
      acquire(&p->lock);
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	cce080e7          	jalr	-818(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001efc:	4c9c                	lw	a5,24(s1)
    80001efe:	ff3791e3          	bne	a5,s3,80001ee0 <scheduler+0x62>
        p->state = RUNNING;
    80001f02:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f06:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f0a:	06048593          	addi	a1,s1,96
    80001f0e:	8556                	mv	a0,s5
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	620080e7          	jalr	1568(ra) # 80002530 <swtch>
        c->proc = 0;
    80001f18:	020a3823          	sd	zero,48(s4)
    80001f1c:	b7d1                	j	80001ee0 <scheduler+0x62>

0000000080001f1e <sched>:
{
    80001f1e:	7179                	addi	sp,sp,-48
    80001f20:	f406                	sd	ra,40(sp)
    80001f22:	f022                	sd	s0,32(sp)
    80001f24:	ec26                	sd	s1,24(sp)
    80001f26:	e84a                	sd	s2,16(sp)
    80001f28:	e44e                	sd	s3,8(sp)
    80001f2a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	a44080e7          	jalr	-1468(ra) # 80001970 <myproc>
    80001f34:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	c12080e7          	jalr	-1006(ra) # 80000b48 <holding>
    80001f3e:	c93d                	beqz	a0,80001fb4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f40:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f42:	2781                	sext.w	a5,a5
    80001f44:	079e                	slli	a5,a5,0x7
    80001f46:	0000f717          	auipc	a4,0xf
    80001f4a:	35a70713          	addi	a4,a4,858 # 800112a0 <pid_lock>
    80001f4e:	97ba                	add	a5,a5,a4
    80001f50:	0a87a703          	lw	a4,168(a5)
    80001f54:	4785                	li	a5,1
    80001f56:	06f71763          	bne	a4,a5,80001fc4 <sched+0xa6>
  if(p->state == RUNNING)
    80001f5a:	4c98                	lw	a4,24(s1)
    80001f5c:	4791                	li	a5,4
    80001f5e:	06f70b63          	beq	a4,a5,80001fd4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f68:	efb5                	bnez	a5,80001fe4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f6c:	0000f917          	auipc	s2,0xf
    80001f70:	33490913          	addi	s2,s2,820 # 800112a0 <pid_lock>
    80001f74:	2781                	sext.w	a5,a5
    80001f76:	079e                	slli	a5,a5,0x7
    80001f78:	97ca                	add	a5,a5,s2
    80001f7a:	0ac7a983          	lw	s3,172(a5)
    80001f7e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f80:	2781                	sext.w	a5,a5
    80001f82:	079e                	slli	a5,a5,0x7
    80001f84:	0000f597          	auipc	a1,0xf
    80001f88:	35458593          	addi	a1,a1,852 # 800112d8 <cpus+0x8>
    80001f8c:	95be                	add	a1,a1,a5
    80001f8e:	06048513          	addi	a0,s1,96
    80001f92:	00000097          	auipc	ra,0x0
    80001f96:	59e080e7          	jalr	1438(ra) # 80002530 <swtch>
    80001f9a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f9c:	2781                	sext.w	a5,a5
    80001f9e:	079e                	slli	a5,a5,0x7
    80001fa0:	97ca                	add	a5,a5,s2
    80001fa2:	0b37a623          	sw	s3,172(a5)
}
    80001fa6:	70a2                	ld	ra,40(sp)
    80001fa8:	7402                	ld	s0,32(sp)
    80001faa:	64e2                	ld	s1,24(sp)
    80001fac:	6942                	ld	s2,16(sp)
    80001fae:	69a2                	ld	s3,8(sp)
    80001fb0:	6145                	addi	sp,sp,48
    80001fb2:	8082                	ret
    panic("sched p->lock");
    80001fb4:	00006517          	auipc	a0,0x6
    80001fb8:	23450513          	addi	a0,a0,564 # 800081e8 <digits+0x1a8>
    80001fbc:	ffffe097          	auipc	ra,0xffffe
    80001fc0:	56e080e7          	jalr	1390(ra) # 8000052a <panic>
    panic("sched locks");
    80001fc4:	00006517          	auipc	a0,0x6
    80001fc8:	23450513          	addi	a0,a0,564 # 800081f8 <digits+0x1b8>
    80001fcc:	ffffe097          	auipc	ra,0xffffe
    80001fd0:	55e080e7          	jalr	1374(ra) # 8000052a <panic>
    panic("sched running");
    80001fd4:	00006517          	auipc	a0,0x6
    80001fd8:	23450513          	addi	a0,a0,564 # 80008208 <digits+0x1c8>
    80001fdc:	ffffe097          	auipc	ra,0xffffe
    80001fe0:	54e080e7          	jalr	1358(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001fe4:	00006517          	auipc	a0,0x6
    80001fe8:	23450513          	addi	a0,a0,564 # 80008218 <digits+0x1d8>
    80001fec:	ffffe097          	auipc	ra,0xffffe
    80001ff0:	53e080e7          	jalr	1342(ra) # 8000052a <panic>

0000000080001ff4 <yield>:
{
    80001ff4:	1101                	addi	sp,sp,-32
    80001ff6:	ec06                	sd	ra,24(sp)
    80001ff8:	e822                	sd	s0,16(sp)
    80001ffa:	e426                	sd	s1,8(sp)
    80001ffc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001ffe:	00000097          	auipc	ra,0x0
    80002002:	972080e7          	jalr	-1678(ra) # 80001970 <myproc>
    80002006:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	bba080e7          	jalr	-1094(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002010:	478d                	li	a5,3
    80002012:	cc9c                	sw	a5,24(s1)
  sched();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	f0a080e7          	jalr	-246(ra) # 80001f1e <sched>
  release(&p->lock);
    8000201c:	8526                	mv	a0,s1
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	c58080e7          	jalr	-936(ra) # 80000c76 <release>
}
    80002026:	60e2                	ld	ra,24(sp)
    80002028:	6442                	ld	s0,16(sp)
    8000202a:	64a2                	ld	s1,8(sp)
    8000202c:	6105                	addi	sp,sp,32
    8000202e:	8082                	ret

0000000080002030 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002030:	7179                	addi	sp,sp,-48
    80002032:	f406                	sd	ra,40(sp)
    80002034:	f022                	sd	s0,32(sp)
    80002036:	ec26                	sd	s1,24(sp)
    80002038:	e84a                	sd	s2,16(sp)
    8000203a:	e44e                	sd	s3,8(sp)
    8000203c:	1800                	addi	s0,sp,48
    8000203e:	89aa                	mv	s3,a0
    80002040:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	92e080e7          	jalr	-1746(ra) # 80001970 <myproc>
    8000204a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b76080e7          	jalr	-1162(ra) # 80000bc2 <acquire>
  release(lk);
    80002054:	854a                	mv	a0,s2
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c20080e7          	jalr	-992(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    8000205e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002062:	4789                	li	a5,2
    80002064:	cc9c                	sw	a5,24(s1)

  sched();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	eb8080e7          	jalr	-328(ra) # 80001f1e <sched>

  // Tidy up.
  p->chan = 0;
    8000206e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c02080e7          	jalr	-1022(ra) # 80000c76 <release>
  acquire(lk);
    8000207c:	854a                	mv	a0,s2
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	b44080e7          	jalr	-1212(ra) # 80000bc2 <acquire>
}
    80002086:	70a2                	ld	ra,40(sp)
    80002088:	7402                	ld	s0,32(sp)
    8000208a:	64e2                	ld	s1,24(sp)
    8000208c:	6942                	ld	s2,16(sp)
    8000208e:	69a2                	ld	s3,8(sp)
    80002090:	6145                	addi	sp,sp,48
    80002092:	8082                	ret

0000000080002094 <wait>:
{
    80002094:	715d                	addi	sp,sp,-80
    80002096:	e486                	sd	ra,72(sp)
    80002098:	e0a2                	sd	s0,64(sp)
    8000209a:	fc26                	sd	s1,56(sp)
    8000209c:	f84a                	sd	s2,48(sp)
    8000209e:	f44e                	sd	s3,40(sp)
    800020a0:	f052                	sd	s4,32(sp)
    800020a2:	ec56                	sd	s5,24(sp)
    800020a4:	e85a                	sd	s6,16(sp)
    800020a6:	e45e                	sd	s7,8(sp)
    800020a8:	e062                	sd	s8,0(sp)
    800020aa:	0880                	addi	s0,sp,80
    800020ac:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	8c2080e7          	jalr	-1854(ra) # 80001970 <myproc>
    800020b6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020b8:	0000f517          	auipc	a0,0xf
    800020bc:	20050513          	addi	a0,a0,512 # 800112b8 <wait_lock>
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b02080e7          	jalr	-1278(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020c8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020ca:	4a15                	li	s4,5
        havekids = 1;
    800020cc:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020ce:	00015997          	auipc	s3,0x15
    800020d2:	00298993          	addi	s3,s3,2 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020d6:	0000fc17          	auipc	s8,0xf
    800020da:	1e2c0c13          	addi	s8,s8,482 # 800112b8 <wait_lock>
    havekids = 0;
    800020de:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	5f048493          	addi	s1,s1,1520 # 800116d0 <proc>
    800020e8:	a0bd                	j	80002156 <wait+0xc2>
          pid = np->pid;
    800020ea:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020ee:	000b0e63          	beqz	s6,8000210a <wait+0x76>
    800020f2:	4691                	li	a3,4
    800020f4:	02c48613          	addi	a2,s1,44
    800020f8:	85da                	mv	a1,s6
    800020fa:	05093503          	ld	a0,80(s2)
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	532080e7          	jalr	1330(ra) # 80001630 <copyout>
    80002106:	02054563          	bltz	a0,80002130 <wait+0x9c>
          freeproc(np);
    8000210a:	8526                	mv	a0,s1
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	a16080e7          	jalr	-1514(ra) # 80001b22 <freeproc>
          release(&np->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b60080e7          	jalr	-1184(ra) # 80000c76 <release>
          release(&wait_lock);
    8000211e:	0000f517          	auipc	a0,0xf
    80002122:	19a50513          	addi	a0,a0,410 # 800112b8 <wait_lock>
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b50080e7          	jalr	-1200(ra) # 80000c76 <release>
          return pid;
    8000212e:	a09d                	j	80002194 <wait+0x100>
            release(&np->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b44080e7          	jalr	-1212(ra) # 80000c76 <release>
            release(&wait_lock);
    8000213a:	0000f517          	auipc	a0,0xf
    8000213e:	17e50513          	addi	a0,a0,382 # 800112b8 <wait_lock>
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b34080e7          	jalr	-1228(ra) # 80000c76 <release>
            return -1;
    8000214a:	59fd                	li	s3,-1
    8000214c:	a0a1                	j	80002194 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000214e:	16848493          	addi	s1,s1,360
    80002152:	03348463          	beq	s1,s3,8000217a <wait+0xe6>
      if(np->parent == p){
    80002156:	7c9c                	ld	a5,56(s1)
    80002158:	ff279be3          	bne	a5,s2,8000214e <wait+0xba>
        acquire(&np->lock);
    8000215c:	8526                	mv	a0,s1
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	a64080e7          	jalr	-1436(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002166:	4c9c                	lw	a5,24(s1)
    80002168:	f94781e3          	beq	a5,s4,800020ea <wait+0x56>
        release(&np->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b08080e7          	jalr	-1272(ra) # 80000c76 <release>
        havekids = 1;
    80002176:	8756                	mv	a4,s5
    80002178:	bfd9                	j	8000214e <wait+0xba>
    if(!havekids || p->killed){
    8000217a:	c701                	beqz	a4,80002182 <wait+0xee>
    8000217c:	02892783          	lw	a5,40(s2)
    80002180:	c79d                	beqz	a5,800021ae <wait+0x11a>
      release(&wait_lock);
    80002182:	0000f517          	auipc	a0,0xf
    80002186:	13650513          	addi	a0,a0,310 # 800112b8 <wait_lock>
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	aec080e7          	jalr	-1300(ra) # 80000c76 <release>
      return -1;
    80002192:	59fd                	li	s3,-1
}
    80002194:	854e                	mv	a0,s3
    80002196:	60a6                	ld	ra,72(sp)
    80002198:	6406                	ld	s0,64(sp)
    8000219a:	74e2                	ld	s1,56(sp)
    8000219c:	7942                	ld	s2,48(sp)
    8000219e:	79a2                	ld	s3,40(sp)
    800021a0:	7a02                	ld	s4,32(sp)
    800021a2:	6ae2                	ld	s5,24(sp)
    800021a4:	6b42                	ld	s6,16(sp)
    800021a6:	6ba2                	ld	s7,8(sp)
    800021a8:	6c02                	ld	s8,0(sp)
    800021aa:	6161                	addi	sp,sp,80
    800021ac:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021ae:	85e2                	mv	a1,s8
    800021b0:	854a                	mv	a0,s2
    800021b2:	00000097          	auipc	ra,0x0
    800021b6:	e7e080e7          	jalr	-386(ra) # 80002030 <sleep>
    havekids = 0;
    800021ba:	b715                	j	800020de <wait+0x4a>

00000000800021bc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021bc:	7139                	addi	sp,sp,-64
    800021be:	fc06                	sd	ra,56(sp)
    800021c0:	f822                	sd	s0,48(sp)
    800021c2:	f426                	sd	s1,40(sp)
    800021c4:	f04a                	sd	s2,32(sp)
    800021c6:	ec4e                	sd	s3,24(sp)
    800021c8:	e852                	sd	s4,16(sp)
    800021ca:	e456                	sd	s5,8(sp)
    800021cc:	0080                	addi	s0,sp,64
    800021ce:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021d0:	0000f497          	auipc	s1,0xf
    800021d4:	50048493          	addi	s1,s1,1280 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021d8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021da:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021dc:	00015917          	auipc	s2,0x15
    800021e0:	ef490913          	addi	s2,s2,-268 # 800170d0 <tickslock>
    800021e4:	a811                	j	800021f8 <wakeup+0x3c>
      }
      release(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	a8e080e7          	jalr	-1394(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f0:	16848493          	addi	s1,s1,360
    800021f4:	03248663          	beq	s1,s2,80002220 <wakeup+0x64>
    if(p != myproc()){
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	778080e7          	jalr	1912(ra) # 80001970 <myproc>
    80002200:	fea488e3          	beq	s1,a0,800021f0 <wakeup+0x34>
      acquire(&p->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	9bc080e7          	jalr	-1604(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000220e:	4c9c                	lw	a5,24(s1)
    80002210:	fd379be3          	bne	a5,s3,800021e6 <wakeup+0x2a>
    80002214:	709c                	ld	a5,32(s1)
    80002216:	fd4798e3          	bne	a5,s4,800021e6 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000221a:	0154ac23          	sw	s5,24(s1)
    8000221e:	b7e1                	j	800021e6 <wakeup+0x2a>
    }
  }
}
    80002220:	70e2                	ld	ra,56(sp)
    80002222:	7442                	ld	s0,48(sp)
    80002224:	74a2                	ld	s1,40(sp)
    80002226:	7902                	ld	s2,32(sp)
    80002228:	69e2                	ld	s3,24(sp)
    8000222a:	6a42                	ld	s4,16(sp)
    8000222c:	6aa2                	ld	s5,8(sp)
    8000222e:	6121                	addi	sp,sp,64
    80002230:	8082                	ret

0000000080002232 <reparent>:
{
    80002232:	7179                	addi	sp,sp,-48
    80002234:	f406                	sd	ra,40(sp)
    80002236:	f022                	sd	s0,32(sp)
    80002238:	ec26                	sd	s1,24(sp)
    8000223a:	e84a                	sd	s2,16(sp)
    8000223c:	e44e                	sd	s3,8(sp)
    8000223e:	e052                	sd	s4,0(sp)
    80002240:	1800                	addi	s0,sp,48
    80002242:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002244:	0000f497          	auipc	s1,0xf
    80002248:	48c48493          	addi	s1,s1,1164 # 800116d0 <proc>
      pp->parent = initproc;
    8000224c:	00007a17          	auipc	s4,0x7
    80002250:	ddca0a13          	addi	s4,s4,-548 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002254:	00015997          	auipc	s3,0x15
    80002258:	e7c98993          	addi	s3,s3,-388 # 800170d0 <tickslock>
    8000225c:	a029                	j	80002266 <reparent+0x34>
    8000225e:	16848493          	addi	s1,s1,360
    80002262:	01348d63          	beq	s1,s3,8000227c <reparent+0x4a>
    if(pp->parent == p){
    80002266:	7c9c                	ld	a5,56(s1)
    80002268:	ff279be3          	bne	a5,s2,8000225e <reparent+0x2c>
      pp->parent = initproc;
    8000226c:	000a3503          	ld	a0,0(s4)
    80002270:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002272:	00000097          	auipc	ra,0x0
    80002276:	f4a080e7          	jalr	-182(ra) # 800021bc <wakeup>
    8000227a:	b7d5                	j	8000225e <reparent+0x2c>
}
    8000227c:	70a2                	ld	ra,40(sp)
    8000227e:	7402                	ld	s0,32(sp)
    80002280:	64e2                	ld	s1,24(sp)
    80002282:	6942                	ld	s2,16(sp)
    80002284:	69a2                	ld	s3,8(sp)
    80002286:	6a02                	ld	s4,0(sp)
    80002288:	6145                	addi	sp,sp,48
    8000228a:	8082                	ret

000000008000228c <exit>:
{
    8000228c:	7179                	addi	sp,sp,-48
    8000228e:	f406                	sd	ra,40(sp)
    80002290:	f022                	sd	s0,32(sp)
    80002292:	ec26                	sd	s1,24(sp)
    80002294:	e84a                	sd	s2,16(sp)
    80002296:	e44e                	sd	s3,8(sp)
    80002298:	e052                	sd	s4,0(sp)
    8000229a:	1800                	addi	s0,sp,48
    8000229c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	6d2080e7          	jalr	1746(ra) # 80001970 <myproc>
    800022a6:	89aa                	mv	s3,a0
  if(p == initproc)
    800022a8:	00007797          	auipc	a5,0x7
    800022ac:	d807b783          	ld	a5,-640(a5) # 80009028 <initproc>
    800022b0:	0d050493          	addi	s1,a0,208
    800022b4:	15050913          	addi	s2,a0,336
    800022b8:	02a79363          	bne	a5,a0,800022de <exit+0x52>
    panic("init exiting");
    800022bc:	00006517          	auipc	a0,0x6
    800022c0:	f7450513          	addi	a0,a0,-140 # 80008230 <digits+0x1f0>
    800022c4:	ffffe097          	auipc	ra,0xffffe
    800022c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
      fileclose(f);
    800022cc:	00002097          	auipc	ra,0x2
    800022d0:	1d2080e7          	jalr	466(ra) # 8000449e <fileclose>
      p->ofile[fd] = 0;
    800022d4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022d8:	04a1                	addi	s1,s1,8
    800022da:	01248563          	beq	s1,s2,800022e4 <exit+0x58>
    if(p->ofile[fd]){
    800022de:	6088                	ld	a0,0(s1)
    800022e0:	f575                	bnez	a0,800022cc <exit+0x40>
    800022e2:	bfdd                	j	800022d8 <exit+0x4c>
  begin_op();
    800022e4:	00002097          	auipc	ra,0x2
    800022e8:	cee080e7          	jalr	-786(ra) # 80003fd2 <begin_op>
  iput(p->cwd);
    800022ec:	1509b503          	ld	a0,336(s3)
    800022f0:	00001097          	auipc	ra,0x1
    800022f4:	4c6080e7          	jalr	1222(ra) # 800037b6 <iput>
  end_op();
    800022f8:	00002097          	auipc	ra,0x2
    800022fc:	d5a080e7          	jalr	-678(ra) # 80004052 <end_op>
  p->cwd = 0;
    80002300:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002304:	0000f497          	auipc	s1,0xf
    80002308:	fb448493          	addi	s1,s1,-76 # 800112b8 <wait_lock>
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	8b4080e7          	jalr	-1868(ra) # 80000bc2 <acquire>
  reparent(p);
    80002316:	854e                	mv	a0,s3
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	f1a080e7          	jalr	-230(ra) # 80002232 <reparent>
  wakeup(p->parent);
    80002320:	0389b503          	ld	a0,56(s3)
    80002324:	00000097          	auipc	ra,0x0
    80002328:	e98080e7          	jalr	-360(ra) # 800021bc <wakeup>
  acquire(&p->lock);
    8000232c:	854e                	mv	a0,s3
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	894080e7          	jalr	-1900(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002336:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000233a:	4795                	li	a5,5
    8000233c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	934080e7          	jalr	-1740(ra) # 80000c76 <release>
  sched();
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	bd4080e7          	jalr	-1068(ra) # 80001f1e <sched>
  panic("zombie exit");
    80002352:	00006517          	auipc	a0,0x6
    80002356:	eee50513          	addi	a0,a0,-274 # 80008240 <digits+0x200>
    8000235a:	ffffe097          	auipc	ra,0xffffe
    8000235e:	1d0080e7          	jalr	464(ra) # 8000052a <panic>

0000000080002362 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002362:	7179                	addi	sp,sp,-48
    80002364:	f406                	sd	ra,40(sp)
    80002366:	f022                	sd	s0,32(sp)
    80002368:	ec26                	sd	s1,24(sp)
    8000236a:	e84a                	sd	s2,16(sp)
    8000236c:	e44e                	sd	s3,8(sp)
    8000236e:	1800                	addi	s0,sp,48
    80002370:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002372:	0000f497          	auipc	s1,0xf
    80002376:	35e48493          	addi	s1,s1,862 # 800116d0 <proc>
    8000237a:	00015997          	auipc	s3,0x15
    8000237e:	d5698993          	addi	s3,s3,-682 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	83e080e7          	jalr	-1986(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    8000238c:	589c                	lw	a5,48(s1)
    8000238e:	01278d63          	beq	a5,s2,800023a8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	8e2080e7          	jalr	-1822(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000239c:	16848493          	addi	s1,s1,360
    800023a0:	ff3491e3          	bne	s1,s3,80002382 <kill+0x20>
  }
  return -1;
    800023a4:	557d                	li	a0,-1
    800023a6:	a829                	j	800023c0 <kill+0x5e>
      p->killed = 1;
    800023a8:	4785                	li	a5,1
    800023aa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023ac:	4c98                	lw	a4,24(s1)
    800023ae:	4789                	li	a5,2
    800023b0:	00f70f63          	beq	a4,a5,800023ce <kill+0x6c>
      release(&p->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8c0080e7          	jalr	-1856(ra) # 80000c76 <release>
      return 0;
    800023be:	4501                	li	a0,0
}
    800023c0:	70a2                	ld	ra,40(sp)
    800023c2:	7402                	ld	s0,32(sp)
    800023c4:	64e2                	ld	s1,24(sp)
    800023c6:	6942                	ld	s2,16(sp)
    800023c8:	69a2                	ld	s3,8(sp)
    800023ca:	6145                	addi	sp,sp,48
    800023cc:	8082                	ret
        p->state = RUNNABLE;
    800023ce:	478d                	li	a5,3
    800023d0:	cc9c                	sw	a5,24(s1)
    800023d2:	b7cd                	j	800023b4 <kill+0x52>

00000000800023d4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023d4:	7179                	addi	sp,sp,-48
    800023d6:	f406                	sd	ra,40(sp)
    800023d8:	f022                	sd	s0,32(sp)
    800023da:	ec26                	sd	s1,24(sp)
    800023dc:	e84a                	sd	s2,16(sp)
    800023de:	e44e                	sd	s3,8(sp)
    800023e0:	e052                	sd	s4,0(sp)
    800023e2:	1800                	addi	s0,sp,48
    800023e4:	84aa                	mv	s1,a0
    800023e6:	892e                	mv	s2,a1
    800023e8:	89b2                	mv	s3,a2
    800023ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	584080e7          	jalr	1412(ra) # 80001970 <myproc>
  if(user_dst){
    800023f4:	c08d                	beqz	s1,80002416 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800023f6:	86d2                	mv	a3,s4
    800023f8:	864e                	mv	a2,s3
    800023fa:	85ca                	mv	a1,s2
    800023fc:	6928                	ld	a0,80(a0)
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	232080e7          	jalr	562(ra) # 80001630 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002406:	70a2                	ld	ra,40(sp)
    80002408:	7402                	ld	s0,32(sp)
    8000240a:	64e2                	ld	s1,24(sp)
    8000240c:	6942                	ld	s2,16(sp)
    8000240e:	69a2                	ld	s3,8(sp)
    80002410:	6a02                	ld	s4,0(sp)
    80002412:	6145                	addi	sp,sp,48
    80002414:	8082                	ret
    memmove((char *)dst, src, len);
    80002416:	000a061b          	sext.w	a2,s4
    8000241a:	85ce                	mv	a1,s3
    8000241c:	854a                	mv	a0,s2
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	8fc080e7          	jalr	-1796(ra) # 80000d1a <memmove>
    return 0;
    80002426:	8526                	mv	a0,s1
    80002428:	bff9                	j	80002406 <either_copyout+0x32>

000000008000242a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000242a:	7179                	addi	sp,sp,-48
    8000242c:	f406                	sd	ra,40(sp)
    8000242e:	f022                	sd	s0,32(sp)
    80002430:	ec26                	sd	s1,24(sp)
    80002432:	e84a                	sd	s2,16(sp)
    80002434:	e44e                	sd	s3,8(sp)
    80002436:	e052                	sd	s4,0(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	892a                	mv	s2,a0
    8000243c:	84ae                	mv	s1,a1
    8000243e:	89b2                	mv	s3,a2
    80002440:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	52e080e7          	jalr	1326(ra) # 80001970 <myproc>
  if(user_src){
    8000244a:	c08d                	beqz	s1,8000246c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000244c:	86d2                	mv	a3,s4
    8000244e:	864e                	mv	a2,s3
    80002450:	85ca                	mv	a1,s2
    80002452:	6928                	ld	a0,80(a0)
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	268080e7          	jalr	616(ra) # 800016bc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000245c:	70a2                	ld	ra,40(sp)
    8000245e:	7402                	ld	s0,32(sp)
    80002460:	64e2                	ld	s1,24(sp)
    80002462:	6942                	ld	s2,16(sp)
    80002464:	69a2                	ld	s3,8(sp)
    80002466:	6a02                	ld	s4,0(sp)
    80002468:	6145                	addi	sp,sp,48
    8000246a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000246c:	000a061b          	sext.w	a2,s4
    80002470:	85ce                	mv	a1,s3
    80002472:	854a                	mv	a0,s2
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	8a6080e7          	jalr	-1882(ra) # 80000d1a <memmove>
    return 0;
    8000247c:	8526                	mv	a0,s1
    8000247e:	bff9                	j	8000245c <either_copyin+0x32>

0000000080002480 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002480:	715d                	addi	sp,sp,-80
    80002482:	e486                	sd	ra,72(sp)
    80002484:	e0a2                	sd	s0,64(sp)
    80002486:	fc26                	sd	s1,56(sp)
    80002488:	f84a                	sd	s2,48(sp)
    8000248a:	f44e                	sd	s3,40(sp)
    8000248c:	f052                	sd	s4,32(sp)
    8000248e:	ec56                	sd	s5,24(sp)
    80002490:	e85a                	sd	s6,16(sp)
    80002492:	e45e                	sd	s7,8(sp)
    80002494:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002496:	00006517          	auipc	a0,0x6
    8000249a:	c3250513          	addi	a0,a0,-974 # 800080c8 <digits+0x88>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	0d6080e7          	jalr	214(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024a6:	0000f497          	auipc	s1,0xf
    800024aa:	38248493          	addi	s1,s1,898 # 80011828 <proc+0x158>
    800024ae:	00015917          	auipc	s2,0x15
    800024b2:	d7a90913          	addi	s2,s2,-646 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024b6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024b8:	00006997          	auipc	s3,0x6
    800024bc:	d9898993          	addi	s3,s3,-616 # 80008250 <digits+0x210>
    printf("%d %s %s", p->pid, state, p->name);
    800024c0:	00006a97          	auipc	s5,0x6
    800024c4:	d98a8a93          	addi	s5,s5,-616 # 80008258 <digits+0x218>
    printf("\n");
    800024c8:	00006a17          	auipc	s4,0x6
    800024cc:	c00a0a13          	addi	s4,s4,-1024 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024d0:	00006b97          	auipc	s7,0x6
    800024d4:	dc0b8b93          	addi	s7,s7,-576 # 80008290 <states.0>
    800024d8:	a00d                	j	800024fa <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800024da:	ed86a583          	lw	a1,-296(a3)
    800024de:	8556                	mv	a0,s5
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	094080e7          	jalr	148(ra) # 80000574 <printf>
    printf("\n");
    800024e8:	8552                	mv	a0,s4
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	08a080e7          	jalr	138(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f2:	16848493          	addi	s1,s1,360
    800024f6:	03248263          	beq	s1,s2,8000251a <procdump+0x9a>
    if(p->state == UNUSED)
    800024fa:	86a6                	mv	a3,s1
    800024fc:	ec04a783          	lw	a5,-320(s1)
    80002500:	dbed                	beqz	a5,800024f2 <procdump+0x72>
      state = "???";
    80002502:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002504:	fcfb6be3          	bltu	s6,a5,800024da <procdump+0x5a>
    80002508:	02079713          	slli	a4,a5,0x20
    8000250c:	01d75793          	srli	a5,a4,0x1d
    80002510:	97de                	add	a5,a5,s7
    80002512:	6390                	ld	a2,0(a5)
    80002514:	f279                	bnez	a2,800024da <procdump+0x5a>
      state = "???";
    80002516:	864e                	mv	a2,s3
    80002518:	b7c9                	j	800024da <procdump+0x5a>
  }
}
    8000251a:	60a6                	ld	ra,72(sp)
    8000251c:	6406                	ld	s0,64(sp)
    8000251e:	74e2                	ld	s1,56(sp)
    80002520:	7942                	ld	s2,48(sp)
    80002522:	79a2                	ld	s3,40(sp)
    80002524:	7a02                	ld	s4,32(sp)
    80002526:	6ae2                	ld	s5,24(sp)
    80002528:	6b42                	ld	s6,16(sp)
    8000252a:	6ba2                	ld	s7,8(sp)
    8000252c:	6161                	addi	sp,sp,80
    8000252e:	8082                	ret

0000000080002530 <swtch>:
    80002530:	00153023          	sd	ra,0(a0)
    80002534:	00253423          	sd	sp,8(a0)
    80002538:	e900                	sd	s0,16(a0)
    8000253a:	ed04                	sd	s1,24(a0)
    8000253c:	03253023          	sd	s2,32(a0)
    80002540:	03353423          	sd	s3,40(a0)
    80002544:	03453823          	sd	s4,48(a0)
    80002548:	03553c23          	sd	s5,56(a0)
    8000254c:	05653023          	sd	s6,64(a0)
    80002550:	05753423          	sd	s7,72(a0)
    80002554:	05853823          	sd	s8,80(a0)
    80002558:	05953c23          	sd	s9,88(a0)
    8000255c:	07a53023          	sd	s10,96(a0)
    80002560:	07b53423          	sd	s11,104(a0)
    80002564:	0005b083          	ld	ra,0(a1)
    80002568:	0085b103          	ld	sp,8(a1)
    8000256c:	6980                	ld	s0,16(a1)
    8000256e:	6d84                	ld	s1,24(a1)
    80002570:	0205b903          	ld	s2,32(a1)
    80002574:	0285b983          	ld	s3,40(a1)
    80002578:	0305ba03          	ld	s4,48(a1)
    8000257c:	0385ba83          	ld	s5,56(a1)
    80002580:	0405bb03          	ld	s6,64(a1)
    80002584:	0485bb83          	ld	s7,72(a1)
    80002588:	0505bc03          	ld	s8,80(a1)
    8000258c:	0585bc83          	ld	s9,88(a1)
    80002590:	0605bd03          	ld	s10,96(a1)
    80002594:	0685bd83          	ld	s11,104(a1)
    80002598:	8082                	ret

000000008000259a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000259a:	1141                	addi	sp,sp,-16
    8000259c:	e406                	sd	ra,8(sp)
    8000259e:	e022                	sd	s0,0(sp)
    800025a0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025a2:	00006597          	auipc	a1,0x6
    800025a6:	d1e58593          	addi	a1,a1,-738 # 800082c0 <states.0+0x30>
    800025aa:	00015517          	auipc	a0,0x15
    800025ae:	b2650513          	addi	a0,a0,-1242 # 800170d0 <tickslock>
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	580080e7          	jalr	1408(ra) # 80000b32 <initlock>
}
    800025ba:	60a2                	ld	ra,8(sp)
    800025bc:	6402                	ld	s0,0(sp)
    800025be:	0141                	addi	sp,sp,16
    800025c0:	8082                	ret

00000000800025c2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025c2:	1141                	addi	sp,sp,-16
    800025c4:	e422                	sd	s0,8(sp)
    800025c6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025c8:	00003797          	auipc	a5,0x3
    800025cc:	4f878793          	addi	a5,a5,1272 # 80005ac0 <kernelvec>
    800025d0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025d4:	6422                	ld	s0,8(sp)
    800025d6:	0141                	addi	sp,sp,16
    800025d8:	8082                	ret

00000000800025da <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800025da:	1141                	addi	sp,sp,-16
    800025dc:	e406                	sd	ra,8(sp)
    800025de:	e022                	sd	s0,0(sp)
    800025e0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	38e080e7          	jalr	910(ra) # 80001970 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800025ee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025f0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800025f4:	00005617          	auipc	a2,0x5
    800025f8:	a0c60613          	addi	a2,a2,-1524 # 80007000 <_trampoline>
    800025fc:	00005697          	auipc	a3,0x5
    80002600:	a0468693          	addi	a3,a3,-1532 # 80007000 <_trampoline>
    80002604:	8e91                	sub	a3,a3,a2
    80002606:	040007b7          	lui	a5,0x4000
    8000260a:	17fd                	addi	a5,a5,-1
    8000260c:	07b2                	slli	a5,a5,0xc
    8000260e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002610:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002614:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002616:	180026f3          	csrr	a3,satp
    8000261a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000261c:	6d38                	ld	a4,88(a0)
    8000261e:	6134                	ld	a3,64(a0)
    80002620:	6585                	lui	a1,0x1
    80002622:	96ae                	add	a3,a3,a1
    80002624:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002626:	6d38                	ld	a4,88(a0)
    80002628:	00000697          	auipc	a3,0x0
    8000262c:	13868693          	addi	a3,a3,312 # 80002760 <usertrap>
    80002630:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002632:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002634:	8692                	mv	a3,tp
    80002636:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002638:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000263c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002640:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002644:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002648:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000264a:	6f18                	ld	a4,24(a4)
    8000264c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002650:	692c                	ld	a1,80(a0)
    80002652:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002654:	00005717          	auipc	a4,0x5
    80002658:	a3c70713          	addi	a4,a4,-1476 # 80007090 <userret>
    8000265c:	8f11                	sub	a4,a4,a2
    8000265e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002660:	577d                	li	a4,-1
    80002662:	177e                	slli	a4,a4,0x3f
    80002664:	8dd9                	or	a1,a1,a4
    80002666:	02000537          	lui	a0,0x2000
    8000266a:	157d                	addi	a0,a0,-1
    8000266c:	0536                	slli	a0,a0,0xd
    8000266e:	9782                	jalr	a5
}
    80002670:	60a2                	ld	ra,8(sp)
    80002672:	6402                	ld	s0,0(sp)
    80002674:	0141                	addi	sp,sp,16
    80002676:	8082                	ret

0000000080002678 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002678:	1101                	addi	sp,sp,-32
    8000267a:	ec06                	sd	ra,24(sp)
    8000267c:	e822                	sd	s0,16(sp)
    8000267e:	e426                	sd	s1,8(sp)
    80002680:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002682:	00015497          	auipc	s1,0x15
    80002686:	a4e48493          	addi	s1,s1,-1458 # 800170d0 <tickslock>
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	536080e7          	jalr	1334(ra) # 80000bc2 <acquire>
  ticks++;
    80002694:	00007517          	auipc	a0,0x7
    80002698:	99c50513          	addi	a0,a0,-1636 # 80009030 <ticks>
    8000269c:	411c                	lw	a5,0(a0)
    8000269e:	2785                	addiw	a5,a5,1
    800026a0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026a2:	00000097          	auipc	ra,0x0
    800026a6:	b1a080e7          	jalr	-1254(ra) # 800021bc <wakeup>
  release(&tickslock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	5ca080e7          	jalr	1482(ra) # 80000c76 <release>
}
    800026b4:	60e2                	ld	ra,24(sp)
    800026b6:	6442                	ld	s0,16(sp)
    800026b8:	64a2                	ld	s1,8(sp)
    800026ba:	6105                	addi	sp,sp,32
    800026bc:	8082                	ret

00000000800026be <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026be:	1101                	addi	sp,sp,-32
    800026c0:	ec06                	sd	ra,24(sp)
    800026c2:	e822                	sd	s0,16(sp)
    800026c4:	e426                	sd	s1,8(sp)
    800026c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026c8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026cc:	00074d63          	bltz	a4,800026e6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026d0:	57fd                	li	a5,-1
    800026d2:	17fe                	slli	a5,a5,0x3f
    800026d4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800026d6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800026d8:	06f70363          	beq	a4,a5,8000273e <devintr+0x80>
  }
}
    800026dc:	60e2                	ld	ra,24(sp)
    800026de:	6442                	ld	s0,16(sp)
    800026e0:	64a2                	ld	s1,8(sp)
    800026e2:	6105                	addi	sp,sp,32
    800026e4:	8082                	ret
     (scause & 0xff) == 9){
    800026e6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800026ea:	46a5                	li	a3,9
    800026ec:	fed792e3          	bne	a5,a3,800026d0 <devintr+0x12>
    int irq = plic_claim();
    800026f0:	00003097          	auipc	ra,0x3
    800026f4:	4d8080e7          	jalr	1240(ra) # 80005bc8 <plic_claim>
    800026f8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800026fa:	47a9                	li	a5,10
    800026fc:	02f50763          	beq	a0,a5,8000272a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002700:	4785                	li	a5,1
    80002702:	02f50963          	beq	a0,a5,80002734 <devintr+0x76>
    return 1;
    80002706:	4505                	li	a0,1
    } else if(irq){
    80002708:	d8f1                	beqz	s1,800026dc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000270a:	85a6                	mv	a1,s1
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	bbc50513          	addi	a0,a0,-1092 # 800082c8 <states.0+0x38>
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	e60080e7          	jalr	-416(ra) # 80000574 <printf>
      plic_complete(irq);
    8000271c:	8526                	mv	a0,s1
    8000271e:	00003097          	auipc	ra,0x3
    80002722:	4ce080e7          	jalr	1230(ra) # 80005bec <plic_complete>
    return 1;
    80002726:	4505                	li	a0,1
    80002728:	bf55                	j	800026dc <devintr+0x1e>
      uartintr();
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	25c080e7          	jalr	604(ra) # 80000986 <uartintr>
    80002732:	b7ed                	j	8000271c <devintr+0x5e>
      virtio_disk_intr();
    80002734:	00004097          	auipc	ra,0x4
    80002738:	94a080e7          	jalr	-1718(ra) # 8000607e <virtio_disk_intr>
    8000273c:	b7c5                	j	8000271c <devintr+0x5e>
    if(cpuid() == 0){
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	206080e7          	jalr	518(ra) # 80001944 <cpuid>
    80002746:	c901                	beqz	a0,80002756 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002748:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000274c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000274e:	14479073          	csrw	sip,a5
    return 2;
    80002752:	4509                	li	a0,2
    80002754:	b761                	j	800026dc <devintr+0x1e>
      clockintr();
    80002756:	00000097          	auipc	ra,0x0
    8000275a:	f22080e7          	jalr	-222(ra) # 80002678 <clockintr>
    8000275e:	b7ed                	j	80002748 <devintr+0x8a>

0000000080002760 <usertrap>:
{
    80002760:	7179                	addi	sp,sp,-48
    80002762:	f406                	sd	ra,40(sp)
    80002764:	f022                	sd	s0,32(sp)
    80002766:	ec26                	sd	s1,24(sp)
    80002768:	e84a                	sd	s2,16(sp)
    8000276a:	e44e                	sd	s3,8(sp)
    8000276c:	e052                	sd	s4,0(sp)
    8000276e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002770:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002774:	1007f793          	andi	a5,a5,256
    80002778:	e3bd                	bnez	a5,800027de <usertrap+0x7e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000277a:	00003797          	auipc	a5,0x3
    8000277e:	34678793          	addi	a5,a5,838 # 80005ac0 <kernelvec>
    80002782:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002786:	fffff097          	auipc	ra,0xfffff
    8000278a:	1ea080e7          	jalr	490(ra) # 80001970 <myproc>
    8000278e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002790:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002792:	14102773          	csrr	a4,sepc
    80002796:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002798:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000279c:	47a1                	li	a5,8
    8000279e:	04f71e63          	bne	a4,a5,800027fa <usertrap+0x9a>
    if(p->killed)
    800027a2:	551c                	lw	a5,40(a0)
    800027a4:	e7a9                	bnez	a5,800027ee <usertrap+0x8e>
    p->trapframe->epc += 4;
    800027a6:	6cb8                	ld	a4,88(s1)
    800027a8:	6f1c                	ld	a5,24(a4)
    800027aa:	0791                	addi	a5,a5,4
    800027ac:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027b2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027b6:	10079073          	csrw	sstatus,a5
    syscall();
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	336080e7          	jalr	822(ra) # 80002af0 <syscall>
  if(p->killed)
    800027c2:	549c                	lw	a5,40(s1)
    800027c4:	e3fd                	bnez	a5,800028aa <usertrap+0x14a>
  usertrapret();
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	e14080e7          	jalr	-492(ra) # 800025da <usertrapret>
}
    800027ce:	70a2                	ld	ra,40(sp)
    800027d0:	7402                	ld	s0,32(sp)
    800027d2:	64e2                	ld	s1,24(sp)
    800027d4:	6942                	ld	s2,16(sp)
    800027d6:	69a2                	ld	s3,8(sp)
    800027d8:	6a02                	ld	s4,0(sp)
    800027da:	6145                	addi	sp,sp,48
    800027dc:	8082                	ret
    panic("usertrap: not from user mode");
    800027de:	00006517          	auipc	a0,0x6
    800027e2:	b0a50513          	addi	a0,a0,-1270 # 800082e8 <states.0+0x58>
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	d44080e7          	jalr	-700(ra) # 8000052a <panic>
      exit(-1);
    800027ee:	557d                	li	a0,-1
    800027f0:	00000097          	auipc	ra,0x0
    800027f4:	a9c080e7          	jalr	-1380(ra) # 8000228c <exit>
    800027f8:	b77d                	j	800027a6 <usertrap+0x46>
  } else if((which_dev = devintr()) != 0){
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	ec4080e7          	jalr	-316(ra) # 800026be <devintr>
    80002802:	892a                	mv	s2,a0
    80002804:	e145                	bnez	a0,800028a4 <usertrap+0x144>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002806:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15){
    8000280a:	47bd                	li	a5,15
    8000280c:	04f70863          	beq	a4,a5,8000285c <usertrap+0xfc>
    80002810:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002814:	5890                	lw	a2,48(s1)
    80002816:	00006517          	auipc	a0,0x6
    8000281a:	b0a50513          	addi	a0,a0,-1270 # 80008320 <states.0+0x90>
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	d56080e7          	jalr	-682(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002826:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000282a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	b2250513          	addi	a0,a0,-1246 # 80008350 <states.0+0xc0>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d3e080e7          	jalr	-706(ra) # 80000574 <printf>
    p->killed = 1;
    8000283e:	4785                	li	a5,1
    80002840:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002842:	557d                	li	a0,-1
    80002844:	00000097          	auipc	ra,0x0
    80002848:	a48080e7          	jalr	-1464(ra) # 8000228c <exit>
  if(which_dev == 2)
    8000284c:	4789                	li	a5,2
    8000284e:	f6f91ce3          	bne	s2,a5,800027c6 <usertrap+0x66>
    yield();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	7a2080e7          	jalr	1954(ra) # 80001ff4 <yield>
    8000285a:	b7b5                	j	800027c6 <usertrap+0x66>
    8000285c:	14302a73          	csrr	s4,stval
    uint64 pa = (uint64)kalloc();
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	272080e7          	jalr	626(ra) # 80000ad2 <kalloc>
    80002868:	89aa                	mv	s3,a0
    if(pa == 0){
    8000286a:	c50d                	beqz	a0,80002894 <usertrap+0x134>
      if(mappages(p->pagetable, va, PGSIZE, pa, PTE_U|PTE_W|PTE_R) != 0){
    8000286c:	4759                	li	a4,22
    8000286e:	86aa                	mv	a3,a0
    80002870:	6605                	lui	a2,0x1
    80002872:	75fd                	lui	a1,0xfffff
    80002874:	00ba75b3          	and	a1,s4,a1
    80002878:	68a8                	ld	a0,80(s1)
    8000287a:	fffff097          	auipc	ra,0xfffff
    8000287e:	814080e7          	jalr	-2028(ra) # 8000108e <mappages>
    80002882:	d121                	beqz	a0,800027c2 <usertrap+0x62>
        kfree((void *)pa);
    80002884:	854e                	mv	a0,s3
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	150080e7          	jalr	336(ra) # 800009d6 <kfree>
        p->killed = 1;
    8000288e:	4785                	li	a5,1
    80002890:	d49c                	sw	a5,40(s1)
    80002892:	bf45                	j	80002842 <usertrap+0xe2>
      panic("usertrap: kalloc");
    80002894:	00006517          	auipc	a0,0x6
    80002898:	a7450513          	addi	a0,a0,-1420 # 80008308 <states.0+0x78>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	c8e080e7          	jalr	-882(ra) # 8000052a <panic>
  if(p->killed)
    800028a4:	549c                	lw	a5,40(s1)
    800028a6:	d3dd                	beqz	a5,8000284c <usertrap+0xec>
    800028a8:	bf69                	j	80002842 <usertrap+0xe2>
    800028aa:	4901                	li	s2,0
    800028ac:	bf59                	j	80002842 <usertrap+0xe2>

00000000800028ae <kerneltrap>:
{
    800028ae:	7179                	addi	sp,sp,-48
    800028b0:	f406                	sd	ra,40(sp)
    800028b2:	f022                	sd	s0,32(sp)
    800028b4:	ec26                	sd	s1,24(sp)
    800028b6:	e84a                	sd	s2,16(sp)
    800028b8:	e44e                	sd	s3,8(sp)
    800028ba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028bc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028c8:	1004f793          	andi	a5,s1,256
    800028cc:	cb85                	beqz	a5,800028fc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028d2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028d4:	ef85                	bnez	a5,8000290c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	de8080e7          	jalr	-536(ra) # 800026be <devintr>
    800028de:	cd1d                	beqz	a0,8000291c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028e0:	4789                	li	a5,2
    800028e2:	06f50a63          	beq	a0,a5,80002956 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028e6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ea:	10049073          	csrw	sstatus,s1
}
    800028ee:	70a2                	ld	ra,40(sp)
    800028f0:	7402                	ld	s0,32(sp)
    800028f2:	64e2                	ld	s1,24(sp)
    800028f4:	6942                	ld	s2,16(sp)
    800028f6:	69a2                	ld	s3,8(sp)
    800028f8:	6145                	addi	sp,sp,48
    800028fa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a7450513          	addi	a0,a0,-1420 # 80008370 <states.0+0xe0>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c26080e7          	jalr	-986(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	a8c50513          	addi	a0,a0,-1396 # 80008398 <states.0+0x108>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c16080e7          	jalr	-1002(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000291c:	85ce                	mv	a1,s3
    8000291e:	00006517          	auipc	a0,0x6
    80002922:	a9a50513          	addi	a0,a0,-1382 # 800083b8 <states.0+0x128>
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	c4e080e7          	jalr	-946(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002932:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a9250513          	addi	a0,a0,-1390 # 800083c8 <states.0+0x138>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c36080e7          	jalr	-970(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a9a50513          	addi	a0,a0,-1382 # 800083e0 <states.0+0x150>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	bdc080e7          	jalr	-1060(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	01a080e7          	jalr	26(ra) # 80001970 <myproc>
    8000295e:	d541                	beqz	a0,800028e6 <kerneltrap+0x38>
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	010080e7          	jalr	16(ra) # 80001970 <myproc>
    80002968:	4d18                	lw	a4,24(a0)
    8000296a:	4791                	li	a5,4
    8000296c:	f6f71de3          	bne	a4,a5,800028e6 <kerneltrap+0x38>
    yield();
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	684080e7          	jalr	1668(ra) # 80001ff4 <yield>
    80002978:	b7bd                	j	800028e6 <kerneltrap+0x38>

000000008000297a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000297a:	1101                	addi	sp,sp,-32
    8000297c:	ec06                	sd	ra,24(sp)
    8000297e:	e822                	sd	s0,16(sp)
    80002980:	e426                	sd	s1,8(sp)
    80002982:	1000                	addi	s0,sp,32
    80002984:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	fea080e7          	jalr	-22(ra) # 80001970 <myproc>
  switch (n) {
    8000298e:	4795                	li	a5,5
    80002990:	0497e163          	bltu	a5,s1,800029d2 <argraw+0x58>
    80002994:	048a                	slli	s1,s1,0x2
    80002996:	00006717          	auipc	a4,0x6
    8000299a:	a8270713          	addi	a4,a4,-1406 # 80008418 <states.0+0x188>
    8000299e:	94ba                	add	s1,s1,a4
    800029a0:	409c                	lw	a5,0(s1)
    800029a2:	97ba                	add	a5,a5,a4
    800029a4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029a6:	6d3c                	ld	a5,88(a0)
    800029a8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029aa:	60e2                	ld	ra,24(sp)
    800029ac:	6442                	ld	s0,16(sp)
    800029ae:	64a2                	ld	s1,8(sp)
    800029b0:	6105                	addi	sp,sp,32
    800029b2:	8082                	ret
    return p->trapframe->a1;
    800029b4:	6d3c                	ld	a5,88(a0)
    800029b6:	7fa8                	ld	a0,120(a5)
    800029b8:	bfcd                	j	800029aa <argraw+0x30>
    return p->trapframe->a2;
    800029ba:	6d3c                	ld	a5,88(a0)
    800029bc:	63c8                	ld	a0,128(a5)
    800029be:	b7f5                	j	800029aa <argraw+0x30>
    return p->trapframe->a3;
    800029c0:	6d3c                	ld	a5,88(a0)
    800029c2:	67c8                	ld	a0,136(a5)
    800029c4:	b7dd                	j	800029aa <argraw+0x30>
    return p->trapframe->a4;
    800029c6:	6d3c                	ld	a5,88(a0)
    800029c8:	6bc8                	ld	a0,144(a5)
    800029ca:	b7c5                	j	800029aa <argraw+0x30>
    return p->trapframe->a5;
    800029cc:	6d3c                	ld	a5,88(a0)
    800029ce:	6fc8                	ld	a0,152(a5)
    800029d0:	bfe9                	j	800029aa <argraw+0x30>
  panic("argraw");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	a1e50513          	addi	a0,a0,-1506 # 800083f0 <states.0+0x160>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b50080e7          	jalr	-1200(ra) # 8000052a <panic>

00000000800029e2 <fetchaddr>:
{
    800029e2:	1101                	addi	sp,sp,-32
    800029e4:	ec06                	sd	ra,24(sp)
    800029e6:	e822                	sd	s0,16(sp)
    800029e8:	e426                	sd	s1,8(sp)
    800029ea:	e04a                	sd	s2,0(sp)
    800029ec:	1000                	addi	s0,sp,32
    800029ee:	84aa                	mv	s1,a0
    800029f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	f7e080e7          	jalr	-130(ra) # 80001970 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029fa:	653c                	ld	a5,72(a0)
    800029fc:	02f4f863          	bgeu	s1,a5,80002a2c <fetchaddr+0x4a>
    80002a00:	00848713          	addi	a4,s1,8
    80002a04:	02e7e663          	bltu	a5,a4,80002a30 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a08:	46a1                	li	a3,8
    80002a0a:	8626                	mv	a2,s1
    80002a0c:	85ca                	mv	a1,s2
    80002a0e:	6928                	ld	a0,80(a0)
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	cac080e7          	jalr	-852(ra) # 800016bc <copyin>
    80002a18:	00a03533          	snez	a0,a0
    80002a1c:	40a00533          	neg	a0,a0
}
    80002a20:	60e2                	ld	ra,24(sp)
    80002a22:	6442                	ld	s0,16(sp)
    80002a24:	64a2                	ld	s1,8(sp)
    80002a26:	6902                	ld	s2,0(sp)
    80002a28:	6105                	addi	sp,sp,32
    80002a2a:	8082                	ret
    return -1;
    80002a2c:	557d                	li	a0,-1
    80002a2e:	bfcd                	j	80002a20 <fetchaddr+0x3e>
    80002a30:	557d                	li	a0,-1
    80002a32:	b7fd                	j	80002a20 <fetchaddr+0x3e>

0000000080002a34 <fetchstr>:
{
    80002a34:	7179                	addi	sp,sp,-48
    80002a36:	f406                	sd	ra,40(sp)
    80002a38:	f022                	sd	s0,32(sp)
    80002a3a:	ec26                	sd	s1,24(sp)
    80002a3c:	e84a                	sd	s2,16(sp)
    80002a3e:	e44e                	sd	s3,8(sp)
    80002a40:	1800                	addi	s0,sp,48
    80002a42:	892a                	mv	s2,a0
    80002a44:	84ae                	mv	s1,a1
    80002a46:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	f28080e7          	jalr	-216(ra) # 80001970 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a50:	86ce                	mv	a3,s3
    80002a52:	864a                	mv	a2,s2
    80002a54:	85a6                	mv	a1,s1
    80002a56:	6928                	ld	a0,80(a0)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	cf2080e7          	jalr	-782(ra) # 8000174a <copyinstr>
  if(err < 0)
    80002a60:	00054763          	bltz	a0,80002a6e <fetchstr+0x3a>
  return strlen(buf);
    80002a64:	8526                	mv	a0,s1
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	3dc080e7          	jalr	988(ra) # 80000e42 <strlen>
}
    80002a6e:	70a2                	ld	ra,40(sp)
    80002a70:	7402                	ld	s0,32(sp)
    80002a72:	64e2                	ld	s1,24(sp)
    80002a74:	6942                	ld	s2,16(sp)
    80002a76:	69a2                	ld	s3,8(sp)
    80002a78:	6145                	addi	sp,sp,48
    80002a7a:	8082                	ret

0000000080002a7c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a7c:	1101                	addi	sp,sp,-32
    80002a7e:	ec06                	sd	ra,24(sp)
    80002a80:	e822                	sd	s0,16(sp)
    80002a82:	e426                	sd	s1,8(sp)
    80002a84:	1000                	addi	s0,sp,32
    80002a86:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	ef2080e7          	jalr	-270(ra) # 8000297a <argraw>
    80002a90:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a92:	4501                	li	a0,0
    80002a94:	60e2                	ld	ra,24(sp)
    80002a96:	6442                	ld	s0,16(sp)
    80002a98:	64a2                	ld	s1,8(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret

0000000080002a9e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a9e:	1101                	addi	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	e426                	sd	s1,8(sp)
    80002aa6:	1000                	addi	s0,sp,32
    80002aa8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	ed0080e7          	jalr	-304(ra) # 8000297a <argraw>
    80002ab2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ab4:	4501                	li	a0,0
    80002ab6:	60e2                	ld	ra,24(sp)
    80002ab8:	6442                	ld	s0,16(sp)
    80002aba:	64a2                	ld	s1,8(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret

0000000080002ac0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	e04a                	sd	s2,0(sp)
    80002aca:	1000                	addi	s0,sp,32
    80002acc:	84ae                	mv	s1,a1
    80002ace:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	eaa080e7          	jalr	-342(ra) # 8000297a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ad8:	864a                	mv	a2,s2
    80002ada:	85a6                	mv	a1,s1
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	f58080e7          	jalr	-168(ra) # 80002a34 <fetchstr>
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret

0000000080002af0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002af0:	1101                	addi	sp,sp,-32
    80002af2:	ec06                	sd	ra,24(sp)
    80002af4:	e822                	sd	s0,16(sp)
    80002af6:	e426                	sd	s1,8(sp)
    80002af8:	e04a                	sd	s2,0(sp)
    80002afa:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	e74080e7          	jalr	-396(ra) # 80001970 <myproc>
    80002b04:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b06:	05853903          	ld	s2,88(a0)
    80002b0a:	0a893783          	ld	a5,168(s2)
    80002b0e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b12:	37fd                	addiw	a5,a5,-1
    80002b14:	4751                	li	a4,20
    80002b16:	00f76f63          	bltu	a4,a5,80002b34 <syscall+0x44>
    80002b1a:	00369713          	slli	a4,a3,0x3
    80002b1e:	00006797          	auipc	a5,0x6
    80002b22:	91278793          	addi	a5,a5,-1774 # 80008430 <syscalls>
    80002b26:	97ba                	add	a5,a5,a4
    80002b28:	639c                	ld	a5,0(a5)
    80002b2a:	c789                	beqz	a5,80002b34 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b2c:	9782                	jalr	a5
    80002b2e:	06a93823          	sd	a0,112(s2)
    80002b32:	a839                	j	80002b50 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b34:	15848613          	addi	a2,s1,344
    80002b38:	588c                	lw	a1,48(s1)
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	8be50513          	addi	a0,a0,-1858 # 800083f8 <states.0+0x168>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	a32080e7          	jalr	-1486(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b4a:	6cbc                	ld	a5,88(s1)
    80002b4c:	577d                	li	a4,-1
    80002b4e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b50:	60e2                	ld	ra,24(sp)
    80002b52:	6442                	ld	s0,16(sp)
    80002b54:	64a2                	ld	s1,8(sp)
    80002b56:	6902                	ld	s2,0(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret

0000000080002b5c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b64:	fec40593          	addi	a1,s0,-20
    80002b68:	4501                	li	a0,0
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	f12080e7          	jalr	-238(ra) # 80002a7c <argint>
    return -1;
    80002b72:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b74:	00054963          	bltz	a0,80002b86 <sys_exit+0x2a>
  exit(n);
    80002b78:	fec42503          	lw	a0,-20(s0)
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	710080e7          	jalr	1808(ra) # 8000228c <exit>
  return 0;  // not reached
    80002b84:	4781                	li	a5,0
}
    80002b86:	853e                	mv	a0,a5
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret

0000000080002b90 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b90:	1141                	addi	sp,sp,-16
    80002b92:	e406                	sd	ra,8(sp)
    80002b94:	e022                	sd	s0,0(sp)
    80002b96:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	dd8080e7          	jalr	-552(ra) # 80001970 <myproc>
}
    80002ba0:	5908                	lw	a0,48(a0)
    80002ba2:	60a2                	ld	ra,8(sp)
    80002ba4:	6402                	ld	s0,0(sp)
    80002ba6:	0141                	addi	sp,sp,16
    80002ba8:	8082                	ret

0000000080002baa <sys_fork>:

uint64
sys_fork(void)
{
    80002baa:	1141                	addi	sp,sp,-16
    80002bac:	e406                	sd	ra,8(sp)
    80002bae:	e022                	sd	s0,0(sp)
    80002bb0:	0800                	addi	s0,sp,16
  return fork();
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	18c080e7          	jalr	396(ra) # 80001d3e <fork>
}
    80002bba:	60a2                	ld	ra,8(sp)
    80002bbc:	6402                	ld	s0,0(sp)
    80002bbe:	0141                	addi	sp,sp,16
    80002bc0:	8082                	ret

0000000080002bc2 <sys_wait>:

uint64
sys_wait(void)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bca:	fe840593          	addi	a1,s0,-24
    80002bce:	4501                	li	a0,0
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	ece080e7          	jalr	-306(ra) # 80002a9e <argaddr>
    80002bd8:	87aa                	mv	a5,a0
    return -1;
    80002bda:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bdc:	0007c863          	bltz	a5,80002bec <sys_wait+0x2a>
  return wait(p);
    80002be0:	fe843503          	ld	a0,-24(s0)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	4b0080e7          	jalr	1200(ra) # 80002094 <wait>
}
    80002bec:	60e2                	ld	ra,24(sp)
    80002bee:	6442                	ld	s0,16(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bf4:	7179                	addi	sp,sp,-48
    80002bf6:	f406                	sd	ra,40(sp)
    80002bf8:	f022                	sd	s0,32(sp)
    80002bfa:	ec26                	sd	s1,24(sp)
    80002bfc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bfe:	fdc40593          	addi	a1,s0,-36
    80002c02:	4501                	li	a0,0
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	e78080e7          	jalr	-392(ra) # 80002a7c <argint>
    return -1;
    80002c0c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c0e:	02054363          	bltz	a0,80002c34 <sys_sbrk+0x40>
  addr = myproc()->sz;
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	d5e080e7          	jalr	-674(ra) # 80001970 <myproc>
    80002c1a:	4524                	lw	s1,72(a0)
  myproc()->sz += n;
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	d54080e7          	jalr	-684(ra) # 80001970 <myproc>
    80002c24:	87aa                	mv	a5,a0
    80002c26:	fdc42503          	lw	a0,-36(s0)
    80002c2a:	67b8                	ld	a4,72(a5)
    80002c2c:	972a                	add	a4,a4,a0
    80002c2e:	e7b8                	sd	a4,72(a5)
  //if(growproc(n) < 0)
  //  return -1;
  if(n < 0)
    80002c30:	00054863          	bltz	a0,80002c40 <sys_sbrk+0x4c>
    growproc(n);
  return addr;
}
    80002c34:	8526                	mv	a0,s1
    80002c36:	70a2                	ld	ra,40(sp)
    80002c38:	7402                	ld	s0,32(sp)
    80002c3a:	64e2                	ld	s1,24(sp)
    80002c3c:	6145                	addi	sp,sp,48
    80002c3e:	8082                	ret
    growproc(n);
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	08a080e7          	jalr	138(ra) # 80001cca <growproc>
  return addr;
    80002c48:	b7f5                	j	80002c34 <sys_sbrk+0x40>

0000000080002c4a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c4a:	7139                	addi	sp,sp,-64
    80002c4c:	fc06                	sd	ra,56(sp)
    80002c4e:	f822                	sd	s0,48(sp)
    80002c50:	f426                	sd	s1,40(sp)
    80002c52:	f04a                	sd	s2,32(sp)
    80002c54:	ec4e                	sd	s3,24(sp)
    80002c56:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c58:	fcc40593          	addi	a1,s0,-52
    80002c5c:	4501                	li	a0,0
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	e1e080e7          	jalr	-482(ra) # 80002a7c <argint>
    return -1;
    80002c66:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c68:	06054563          	bltz	a0,80002cd2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c6c:	00014517          	auipc	a0,0x14
    80002c70:	46450513          	addi	a0,a0,1124 # 800170d0 <tickslock>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	f4e080e7          	jalr	-178(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c7c:	00006917          	auipc	s2,0x6
    80002c80:	3b492903          	lw	s2,948(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c84:	fcc42783          	lw	a5,-52(s0)
    80002c88:	cf85                	beqz	a5,80002cc0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c8a:	00014997          	auipc	s3,0x14
    80002c8e:	44698993          	addi	s3,s3,1094 # 800170d0 <tickslock>
    80002c92:	00006497          	auipc	s1,0x6
    80002c96:	39e48493          	addi	s1,s1,926 # 80009030 <ticks>
    if(myproc()->killed){
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	cd6080e7          	jalr	-810(ra) # 80001970 <myproc>
    80002ca2:	551c                	lw	a5,40(a0)
    80002ca4:	ef9d                	bnez	a5,80002ce2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ca6:	85ce                	mv	a1,s3
    80002ca8:	8526                	mv	a0,s1
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	386080e7          	jalr	902(ra) # 80002030 <sleep>
  while(ticks - ticks0 < n){
    80002cb2:	409c                	lw	a5,0(s1)
    80002cb4:	412787bb          	subw	a5,a5,s2
    80002cb8:	fcc42703          	lw	a4,-52(s0)
    80002cbc:	fce7efe3          	bltu	a5,a4,80002c9a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cc0:	00014517          	auipc	a0,0x14
    80002cc4:	41050513          	addi	a0,a0,1040 # 800170d0 <tickslock>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	fae080e7          	jalr	-82(ra) # 80000c76 <release>
  return 0;
    80002cd0:	4781                	li	a5,0
}
    80002cd2:	853e                	mv	a0,a5
    80002cd4:	70e2                	ld	ra,56(sp)
    80002cd6:	7442                	ld	s0,48(sp)
    80002cd8:	74a2                	ld	s1,40(sp)
    80002cda:	7902                	ld	s2,32(sp)
    80002cdc:	69e2                	ld	s3,24(sp)
    80002cde:	6121                	addi	sp,sp,64
    80002ce0:	8082                	ret
      release(&tickslock);
    80002ce2:	00014517          	auipc	a0,0x14
    80002ce6:	3ee50513          	addi	a0,a0,1006 # 800170d0 <tickslock>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	f8c080e7          	jalr	-116(ra) # 80000c76 <release>
      return -1;
    80002cf2:	57fd                	li	a5,-1
    80002cf4:	bff9                	j	80002cd2 <sys_sleep+0x88>

0000000080002cf6 <sys_kill>:

uint64
sys_kill(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cfe:	fec40593          	addi	a1,s0,-20
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	d78080e7          	jalr	-648(ra) # 80002a7c <argint>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_kill+0x2a>
  return kill(pid);
    80002d14:	fec42503          	lw	a0,-20(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	64a080e7          	jalr	1610(ra) # 80002362 <kill>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d32:	00014517          	auipc	a0,0x14
    80002d36:	39e50513          	addi	a0,a0,926 # 800170d0 <tickslock>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	e88080e7          	jalr	-376(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002d42:	00006497          	auipc	s1,0x6
    80002d46:	2ee4a483          	lw	s1,750(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d4a:	00014517          	auipc	a0,0x14
    80002d4e:	38650513          	addi	a0,a0,902 # 800170d0 <tickslock>
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	f24080e7          	jalr	-220(ra) # 80000c76 <release>
  return xticks;
}
    80002d5a:	02049513          	slli	a0,s1,0x20
    80002d5e:	9101                	srli	a0,a0,0x20
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	64a2                	ld	s1,8(sp)
    80002d66:	6105                	addi	sp,sp,32
    80002d68:	8082                	ret

0000000080002d6a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d6a:	7179                	addi	sp,sp,-48
    80002d6c:	f406                	sd	ra,40(sp)
    80002d6e:	f022                	sd	s0,32(sp)
    80002d70:	ec26                	sd	s1,24(sp)
    80002d72:	e84a                	sd	s2,16(sp)
    80002d74:	e44e                	sd	s3,8(sp)
    80002d76:	e052                	sd	s4,0(sp)
    80002d78:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d7a:	00005597          	auipc	a1,0x5
    80002d7e:	76658593          	addi	a1,a1,1894 # 800084e0 <syscalls+0xb0>
    80002d82:	00014517          	auipc	a0,0x14
    80002d86:	36650513          	addi	a0,a0,870 # 800170e8 <bcache>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	da8080e7          	jalr	-600(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d92:	0001c797          	auipc	a5,0x1c
    80002d96:	35678793          	addi	a5,a5,854 # 8001f0e8 <bcache+0x8000>
    80002d9a:	0001c717          	auipc	a4,0x1c
    80002d9e:	5b670713          	addi	a4,a4,1462 # 8001f350 <bcache+0x8268>
    80002da2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002da6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002daa:	00014497          	auipc	s1,0x14
    80002dae:	35648493          	addi	s1,s1,854 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002db2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002db4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002db6:	00005a17          	auipc	s4,0x5
    80002dba:	732a0a13          	addi	s4,s4,1842 # 800084e8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dbe:	2b893783          	ld	a5,696(s2)
    80002dc2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dc4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dc8:	85d2                	mv	a1,s4
    80002dca:	01048513          	addi	a0,s1,16
    80002dce:	00001097          	auipc	ra,0x1
    80002dd2:	4c2080e7          	jalr	1218(ra) # 80004290 <initsleeplock>
    bcache.head.next->prev = b;
    80002dd6:	2b893783          	ld	a5,696(s2)
    80002dda:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ddc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002de0:	45848493          	addi	s1,s1,1112
    80002de4:	fd349de3          	bne	s1,s3,80002dbe <binit+0x54>
  }
}
    80002de8:	70a2                	ld	ra,40(sp)
    80002dea:	7402                	ld	s0,32(sp)
    80002dec:	64e2                	ld	s1,24(sp)
    80002dee:	6942                	ld	s2,16(sp)
    80002df0:	69a2                	ld	s3,8(sp)
    80002df2:	6a02                	ld	s4,0(sp)
    80002df4:	6145                	addi	sp,sp,48
    80002df6:	8082                	ret

0000000080002df8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002df8:	7179                	addi	sp,sp,-48
    80002dfa:	f406                	sd	ra,40(sp)
    80002dfc:	f022                	sd	s0,32(sp)
    80002dfe:	ec26                	sd	s1,24(sp)
    80002e00:	e84a                	sd	s2,16(sp)
    80002e02:	e44e                	sd	s3,8(sp)
    80002e04:	1800                	addi	s0,sp,48
    80002e06:	892a                	mv	s2,a0
    80002e08:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e0a:	00014517          	auipc	a0,0x14
    80002e0e:	2de50513          	addi	a0,a0,734 # 800170e8 <bcache>
    80002e12:	ffffe097          	auipc	ra,0xffffe
    80002e16:	db0080e7          	jalr	-592(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e1a:	0001c497          	auipc	s1,0x1c
    80002e1e:	5864b483          	ld	s1,1414(s1) # 8001f3a0 <bcache+0x82b8>
    80002e22:	0001c797          	auipc	a5,0x1c
    80002e26:	52e78793          	addi	a5,a5,1326 # 8001f350 <bcache+0x8268>
    80002e2a:	02f48f63          	beq	s1,a5,80002e68 <bread+0x70>
    80002e2e:	873e                	mv	a4,a5
    80002e30:	a021                	j	80002e38 <bread+0x40>
    80002e32:	68a4                	ld	s1,80(s1)
    80002e34:	02e48a63          	beq	s1,a4,80002e68 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e38:	449c                	lw	a5,8(s1)
    80002e3a:	ff279ce3          	bne	a5,s2,80002e32 <bread+0x3a>
    80002e3e:	44dc                	lw	a5,12(s1)
    80002e40:	ff3799e3          	bne	a5,s3,80002e32 <bread+0x3a>
      b->refcnt++;
    80002e44:	40bc                	lw	a5,64(s1)
    80002e46:	2785                	addiw	a5,a5,1
    80002e48:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e4a:	00014517          	auipc	a0,0x14
    80002e4e:	29e50513          	addi	a0,a0,670 # 800170e8 <bcache>
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	e24080e7          	jalr	-476(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e5a:	01048513          	addi	a0,s1,16
    80002e5e:	00001097          	auipc	ra,0x1
    80002e62:	46c080e7          	jalr	1132(ra) # 800042ca <acquiresleep>
      return b;
    80002e66:	a8b9                	j	80002ec4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e68:	0001c497          	auipc	s1,0x1c
    80002e6c:	5304b483          	ld	s1,1328(s1) # 8001f398 <bcache+0x82b0>
    80002e70:	0001c797          	auipc	a5,0x1c
    80002e74:	4e078793          	addi	a5,a5,1248 # 8001f350 <bcache+0x8268>
    80002e78:	00f48863          	beq	s1,a5,80002e88 <bread+0x90>
    80002e7c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e7e:	40bc                	lw	a5,64(s1)
    80002e80:	cf81                	beqz	a5,80002e98 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e82:	64a4                	ld	s1,72(s1)
    80002e84:	fee49de3          	bne	s1,a4,80002e7e <bread+0x86>
  panic("bget: no buffers");
    80002e88:	00005517          	auipc	a0,0x5
    80002e8c:	66850513          	addi	a0,a0,1640 # 800084f0 <syscalls+0xc0>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	69a080e7          	jalr	1690(ra) # 8000052a <panic>
      b->dev = dev;
    80002e98:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e9c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ea0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ea4:	4785                	li	a5,1
    80002ea6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	24050513          	addi	a0,a0,576 # 800170e8 <bcache>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	dc6080e7          	jalr	-570(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002eb8:	01048513          	addi	a0,s1,16
    80002ebc:	00001097          	auipc	ra,0x1
    80002ec0:	40e080e7          	jalr	1038(ra) # 800042ca <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ec4:	409c                	lw	a5,0(s1)
    80002ec6:	cb89                	beqz	a5,80002ed8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ec8:	8526                	mv	a0,s1
    80002eca:	70a2                	ld	ra,40(sp)
    80002ecc:	7402                	ld	s0,32(sp)
    80002ece:	64e2                	ld	s1,24(sp)
    80002ed0:	6942                	ld	s2,16(sp)
    80002ed2:	69a2                	ld	s3,8(sp)
    80002ed4:	6145                	addi	sp,sp,48
    80002ed6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ed8:	4581                	li	a1,0
    80002eda:	8526                	mv	a0,s1
    80002edc:	00003097          	auipc	ra,0x3
    80002ee0:	f1a080e7          	jalr	-230(ra) # 80005df6 <virtio_disk_rw>
    b->valid = 1;
    80002ee4:	4785                	li	a5,1
    80002ee6:	c09c                	sw	a5,0(s1)
  return b;
    80002ee8:	b7c5                	j	80002ec8 <bread+0xd0>

0000000080002eea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002eea:	1101                	addi	sp,sp,-32
    80002eec:	ec06                	sd	ra,24(sp)
    80002eee:	e822                	sd	s0,16(sp)
    80002ef0:	e426                	sd	s1,8(sp)
    80002ef2:	1000                	addi	s0,sp,32
    80002ef4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ef6:	0541                	addi	a0,a0,16
    80002ef8:	00001097          	auipc	ra,0x1
    80002efc:	46c080e7          	jalr	1132(ra) # 80004364 <holdingsleep>
    80002f00:	cd01                	beqz	a0,80002f18 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f02:	4585                	li	a1,1
    80002f04:	8526                	mv	a0,s1
    80002f06:	00003097          	auipc	ra,0x3
    80002f0a:	ef0080e7          	jalr	-272(ra) # 80005df6 <virtio_disk_rw>
}
    80002f0e:	60e2                	ld	ra,24(sp)
    80002f10:	6442                	ld	s0,16(sp)
    80002f12:	64a2                	ld	s1,8(sp)
    80002f14:	6105                	addi	sp,sp,32
    80002f16:	8082                	ret
    panic("bwrite");
    80002f18:	00005517          	auipc	a0,0x5
    80002f1c:	5f050513          	addi	a0,a0,1520 # 80008508 <syscalls+0xd8>
    80002f20:	ffffd097          	auipc	ra,0xffffd
    80002f24:	60a080e7          	jalr	1546(ra) # 8000052a <panic>

0000000080002f28 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f28:	1101                	addi	sp,sp,-32
    80002f2a:	ec06                	sd	ra,24(sp)
    80002f2c:	e822                	sd	s0,16(sp)
    80002f2e:	e426                	sd	s1,8(sp)
    80002f30:	e04a                	sd	s2,0(sp)
    80002f32:	1000                	addi	s0,sp,32
    80002f34:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f36:	01050913          	addi	s2,a0,16
    80002f3a:	854a                	mv	a0,s2
    80002f3c:	00001097          	auipc	ra,0x1
    80002f40:	428080e7          	jalr	1064(ra) # 80004364 <holdingsleep>
    80002f44:	c92d                	beqz	a0,80002fb6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f46:	854a                	mv	a0,s2
    80002f48:	00001097          	auipc	ra,0x1
    80002f4c:	3d8080e7          	jalr	984(ra) # 80004320 <releasesleep>

  acquire(&bcache.lock);
    80002f50:	00014517          	auipc	a0,0x14
    80002f54:	19850513          	addi	a0,a0,408 # 800170e8 <bcache>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	c6a080e7          	jalr	-918(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002f60:	40bc                	lw	a5,64(s1)
    80002f62:	37fd                	addiw	a5,a5,-1
    80002f64:	0007871b          	sext.w	a4,a5
    80002f68:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f6a:	eb05                	bnez	a4,80002f9a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f6c:	68bc                	ld	a5,80(s1)
    80002f6e:	64b8                	ld	a4,72(s1)
    80002f70:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f72:	64bc                	ld	a5,72(s1)
    80002f74:	68b8                	ld	a4,80(s1)
    80002f76:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f78:	0001c797          	auipc	a5,0x1c
    80002f7c:	17078793          	addi	a5,a5,368 # 8001f0e8 <bcache+0x8000>
    80002f80:	2b87b703          	ld	a4,696(a5)
    80002f84:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f86:	0001c717          	auipc	a4,0x1c
    80002f8a:	3ca70713          	addi	a4,a4,970 # 8001f350 <bcache+0x8268>
    80002f8e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f90:	2b87b703          	ld	a4,696(a5)
    80002f94:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f96:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f9a:	00014517          	auipc	a0,0x14
    80002f9e:	14e50513          	addi	a0,a0,334 # 800170e8 <bcache>
    80002fa2:	ffffe097          	auipc	ra,0xffffe
    80002fa6:	cd4080e7          	jalr	-812(ra) # 80000c76 <release>
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6902                	ld	s2,0(sp)
    80002fb2:	6105                	addi	sp,sp,32
    80002fb4:	8082                	ret
    panic("brelse");
    80002fb6:	00005517          	auipc	a0,0x5
    80002fba:	55a50513          	addi	a0,a0,1370 # 80008510 <syscalls+0xe0>
    80002fbe:	ffffd097          	auipc	ra,0xffffd
    80002fc2:	56c080e7          	jalr	1388(ra) # 8000052a <panic>

0000000080002fc6 <bpin>:

void
bpin(struct buf *b) {
    80002fc6:	1101                	addi	sp,sp,-32
    80002fc8:	ec06                	sd	ra,24(sp)
    80002fca:	e822                	sd	s0,16(sp)
    80002fcc:	e426                	sd	s1,8(sp)
    80002fce:	1000                	addi	s0,sp,32
    80002fd0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fd2:	00014517          	auipc	a0,0x14
    80002fd6:	11650513          	addi	a0,a0,278 # 800170e8 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	be8080e7          	jalr	-1048(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	2785                	addiw	a5,a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	10050513          	addi	a0,a0,256 # 800170e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	c86080e7          	jalr	-890(ra) # 80000c76 <release>
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	64a2                	ld	s1,8(sp)
    80002ffe:	6105                	addi	sp,sp,32
    80003000:	8082                	ret

0000000080003002 <bunpin>:

void
bunpin(struct buf *b) {
    80003002:	1101                	addi	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	e426                	sd	s1,8(sp)
    8000300a:	1000                	addi	s0,sp,32
    8000300c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	0da50513          	addi	a0,a0,218 # 800170e8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	bac080e7          	jalr	-1108(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000301e:	40bc                	lw	a5,64(s1)
    80003020:	37fd                	addiw	a5,a5,-1
    80003022:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	0c450513          	addi	a0,a0,196 # 800170e8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	c4a080e7          	jalr	-950(ra) # 80000c76 <release>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	e04a                	sd	s2,0(sp)
    80003048:	1000                	addi	s0,sp,32
    8000304a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000304c:	00d5d59b          	srliw	a1,a1,0xd
    80003050:	0001c797          	auipc	a5,0x1c
    80003054:	7747a783          	lw	a5,1908(a5) # 8001f7c4 <sb+0x1c>
    80003058:	9dbd                	addw	a1,a1,a5
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	d9e080e7          	jalr	-610(ra) # 80002df8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003062:	0074f713          	andi	a4,s1,7
    80003066:	4785                	li	a5,1
    80003068:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000306c:	14ce                	slli	s1,s1,0x33
    8000306e:	90d9                	srli	s1,s1,0x36
    80003070:	00950733          	add	a4,a0,s1
    80003074:	05874703          	lbu	a4,88(a4)
    80003078:	00e7f6b3          	and	a3,a5,a4
    8000307c:	c69d                	beqz	a3,800030aa <bfree+0x6c>
    8000307e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003080:	94aa                	add	s1,s1,a0
    80003082:	fff7c793          	not	a5,a5
    80003086:	8ff9                	and	a5,a5,a4
    80003088:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000308c:	00001097          	auipc	ra,0x1
    80003090:	11e080e7          	jalr	286(ra) # 800041aa <log_write>
  brelse(bp);
    80003094:	854a                	mv	a0,s2
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	e92080e7          	jalr	-366(ra) # 80002f28 <brelse>
}
    8000309e:	60e2                	ld	ra,24(sp)
    800030a0:	6442                	ld	s0,16(sp)
    800030a2:	64a2                	ld	s1,8(sp)
    800030a4:	6902                	ld	s2,0(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret
    panic("freeing free block");
    800030aa:	00005517          	auipc	a0,0x5
    800030ae:	46e50513          	addi	a0,a0,1134 # 80008518 <syscalls+0xe8>
    800030b2:	ffffd097          	auipc	ra,0xffffd
    800030b6:	478080e7          	jalr	1144(ra) # 8000052a <panic>

00000000800030ba <balloc>:
{
    800030ba:	711d                	addi	sp,sp,-96
    800030bc:	ec86                	sd	ra,88(sp)
    800030be:	e8a2                	sd	s0,80(sp)
    800030c0:	e4a6                	sd	s1,72(sp)
    800030c2:	e0ca                	sd	s2,64(sp)
    800030c4:	fc4e                	sd	s3,56(sp)
    800030c6:	f852                	sd	s4,48(sp)
    800030c8:	f456                	sd	s5,40(sp)
    800030ca:	f05a                	sd	s6,32(sp)
    800030cc:	ec5e                	sd	s7,24(sp)
    800030ce:	e862                	sd	s8,16(sp)
    800030d0:	e466                	sd	s9,8(sp)
    800030d2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030d4:	0001c797          	auipc	a5,0x1c
    800030d8:	6d87a783          	lw	a5,1752(a5) # 8001f7ac <sb+0x4>
    800030dc:	cbd1                	beqz	a5,80003170 <balloc+0xb6>
    800030de:	8baa                	mv	s7,a0
    800030e0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030e2:	0001cb17          	auipc	s6,0x1c
    800030e6:	6c6b0b13          	addi	s6,s6,1734 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030ea:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030ec:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030ee:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030f0:	6c89                	lui	s9,0x2
    800030f2:	a831                	j	8000310e <balloc+0x54>
    brelse(bp);
    800030f4:	854a                	mv	a0,s2
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	e32080e7          	jalr	-462(ra) # 80002f28 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030fe:	015c87bb          	addw	a5,s9,s5
    80003102:	00078a9b          	sext.w	s5,a5
    80003106:	004b2703          	lw	a4,4(s6)
    8000310a:	06eaf363          	bgeu	s5,a4,80003170 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000310e:	41fad79b          	sraiw	a5,s5,0x1f
    80003112:	0137d79b          	srliw	a5,a5,0x13
    80003116:	015787bb          	addw	a5,a5,s5
    8000311a:	40d7d79b          	sraiw	a5,a5,0xd
    8000311e:	01cb2583          	lw	a1,28(s6)
    80003122:	9dbd                	addw	a1,a1,a5
    80003124:	855e                	mv	a0,s7
    80003126:	00000097          	auipc	ra,0x0
    8000312a:	cd2080e7          	jalr	-814(ra) # 80002df8 <bread>
    8000312e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003130:	004b2503          	lw	a0,4(s6)
    80003134:	000a849b          	sext.w	s1,s5
    80003138:	8662                	mv	a2,s8
    8000313a:	faa4fde3          	bgeu	s1,a0,800030f4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000313e:	41f6579b          	sraiw	a5,a2,0x1f
    80003142:	01d7d69b          	srliw	a3,a5,0x1d
    80003146:	00c6873b          	addw	a4,a3,a2
    8000314a:	00777793          	andi	a5,a4,7
    8000314e:	9f95                	subw	a5,a5,a3
    80003150:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003154:	4037571b          	sraiw	a4,a4,0x3
    80003158:	00e906b3          	add	a3,s2,a4
    8000315c:	0586c683          	lbu	a3,88(a3)
    80003160:	00d7f5b3          	and	a1,a5,a3
    80003164:	cd91                	beqz	a1,80003180 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003166:	2605                	addiw	a2,a2,1
    80003168:	2485                	addiw	s1,s1,1
    8000316a:	fd4618e3          	bne	a2,s4,8000313a <balloc+0x80>
    8000316e:	b759                	j	800030f4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	3c050513          	addi	a0,a0,960 # 80008530 <syscalls+0x100>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3b2080e7          	jalr	946(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003180:	974a                	add	a4,a4,s2
    80003182:	8fd5                	or	a5,a5,a3
    80003184:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003188:	854a                	mv	a0,s2
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	020080e7          	jalr	32(ra) # 800041aa <log_write>
        brelse(bp);
    80003192:	854a                	mv	a0,s2
    80003194:	00000097          	auipc	ra,0x0
    80003198:	d94080e7          	jalr	-620(ra) # 80002f28 <brelse>
  bp = bread(dev, bno);
    8000319c:	85a6                	mv	a1,s1
    8000319e:	855e                	mv	a0,s7
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	c58080e7          	jalr	-936(ra) # 80002df8 <bread>
    800031a8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031aa:	40000613          	li	a2,1024
    800031ae:	4581                	li	a1,0
    800031b0:	05850513          	addi	a0,a0,88
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	b0a080e7          	jalr	-1270(ra) # 80000cbe <memset>
  log_write(bp);
    800031bc:	854a                	mv	a0,s2
    800031be:	00001097          	auipc	ra,0x1
    800031c2:	fec080e7          	jalr	-20(ra) # 800041aa <log_write>
  brelse(bp);
    800031c6:	854a                	mv	a0,s2
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	d60080e7          	jalr	-672(ra) # 80002f28 <brelse>
}
    800031d0:	8526                	mv	a0,s1
    800031d2:	60e6                	ld	ra,88(sp)
    800031d4:	6446                	ld	s0,80(sp)
    800031d6:	64a6                	ld	s1,72(sp)
    800031d8:	6906                	ld	s2,64(sp)
    800031da:	79e2                	ld	s3,56(sp)
    800031dc:	7a42                	ld	s4,48(sp)
    800031de:	7aa2                	ld	s5,40(sp)
    800031e0:	7b02                	ld	s6,32(sp)
    800031e2:	6be2                	ld	s7,24(sp)
    800031e4:	6c42                	ld	s8,16(sp)
    800031e6:	6ca2                	ld	s9,8(sp)
    800031e8:	6125                	addi	sp,sp,96
    800031ea:	8082                	ret

00000000800031ec <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031ec:	7179                	addi	sp,sp,-48
    800031ee:	f406                	sd	ra,40(sp)
    800031f0:	f022                	sd	s0,32(sp)
    800031f2:	ec26                	sd	s1,24(sp)
    800031f4:	e84a                	sd	s2,16(sp)
    800031f6:	e44e                	sd	s3,8(sp)
    800031f8:	e052                	sd	s4,0(sp)
    800031fa:	1800                	addi	s0,sp,48
    800031fc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031fe:	47ad                	li	a5,11
    80003200:	04b7fe63          	bgeu	a5,a1,8000325c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003204:	ff45849b          	addiw	s1,a1,-12
    80003208:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000320c:	0ff00793          	li	a5,255
    80003210:	0ae7e463          	bltu	a5,a4,800032b8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003214:	08052583          	lw	a1,128(a0)
    80003218:	c5b5                	beqz	a1,80003284 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000321a:	00092503          	lw	a0,0(s2)
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	bda080e7          	jalr	-1062(ra) # 80002df8 <bread>
    80003226:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003228:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000322c:	02049713          	slli	a4,s1,0x20
    80003230:	01e75593          	srli	a1,a4,0x1e
    80003234:	00b784b3          	add	s1,a5,a1
    80003238:	0004a983          	lw	s3,0(s1)
    8000323c:	04098e63          	beqz	s3,80003298 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003240:	8552                	mv	a0,s4
    80003242:	00000097          	auipc	ra,0x0
    80003246:	ce6080e7          	jalr	-794(ra) # 80002f28 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000324a:	854e                	mv	a0,s3
    8000324c:	70a2                	ld	ra,40(sp)
    8000324e:	7402                	ld	s0,32(sp)
    80003250:	64e2                	ld	s1,24(sp)
    80003252:	6942                	ld	s2,16(sp)
    80003254:	69a2                	ld	s3,8(sp)
    80003256:	6a02                	ld	s4,0(sp)
    80003258:	6145                	addi	sp,sp,48
    8000325a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000325c:	02059793          	slli	a5,a1,0x20
    80003260:	01e7d593          	srli	a1,a5,0x1e
    80003264:	00b504b3          	add	s1,a0,a1
    80003268:	0504a983          	lw	s3,80(s1)
    8000326c:	fc099fe3          	bnez	s3,8000324a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003270:	4108                	lw	a0,0(a0)
    80003272:	00000097          	auipc	ra,0x0
    80003276:	e48080e7          	jalr	-440(ra) # 800030ba <balloc>
    8000327a:	0005099b          	sext.w	s3,a0
    8000327e:	0534a823          	sw	s3,80(s1)
    80003282:	b7e1                	j	8000324a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003284:	4108                	lw	a0,0(a0)
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	e34080e7          	jalr	-460(ra) # 800030ba <balloc>
    8000328e:	0005059b          	sext.w	a1,a0
    80003292:	08b92023          	sw	a1,128(s2)
    80003296:	b751                	j	8000321a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003298:	00092503          	lw	a0,0(s2)
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	e1e080e7          	jalr	-482(ra) # 800030ba <balloc>
    800032a4:	0005099b          	sext.w	s3,a0
    800032a8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032ac:	8552                	mv	a0,s4
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	efc080e7          	jalr	-260(ra) # 800041aa <log_write>
    800032b6:	b769                	j	80003240 <bmap+0x54>
  panic("bmap: out of range");
    800032b8:	00005517          	auipc	a0,0x5
    800032bc:	29050513          	addi	a0,a0,656 # 80008548 <syscalls+0x118>
    800032c0:	ffffd097          	auipc	ra,0xffffd
    800032c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>

00000000800032c8 <iget>:
{
    800032c8:	7179                	addi	sp,sp,-48
    800032ca:	f406                	sd	ra,40(sp)
    800032cc:	f022                	sd	s0,32(sp)
    800032ce:	ec26                	sd	s1,24(sp)
    800032d0:	e84a                	sd	s2,16(sp)
    800032d2:	e44e                	sd	s3,8(sp)
    800032d4:	e052                	sd	s4,0(sp)
    800032d6:	1800                	addi	s0,sp,48
    800032d8:	89aa                	mv	s3,a0
    800032da:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032dc:	0001c517          	auipc	a0,0x1c
    800032e0:	4ec50513          	addi	a0,a0,1260 # 8001f7c8 <itable>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	8de080e7          	jalr	-1826(ra) # 80000bc2 <acquire>
  empty = 0;
    800032ec:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032ee:	0001c497          	auipc	s1,0x1c
    800032f2:	4f248493          	addi	s1,s1,1266 # 8001f7e0 <itable+0x18>
    800032f6:	0001e697          	auipc	a3,0x1e
    800032fa:	f7a68693          	addi	a3,a3,-134 # 80021270 <log>
    800032fe:	a039                	j	8000330c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003300:	02090b63          	beqz	s2,80003336 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003304:	08848493          	addi	s1,s1,136
    80003308:	02d48a63          	beq	s1,a3,8000333c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000330c:	449c                	lw	a5,8(s1)
    8000330e:	fef059e3          	blez	a5,80003300 <iget+0x38>
    80003312:	4098                	lw	a4,0(s1)
    80003314:	ff3716e3          	bne	a4,s3,80003300 <iget+0x38>
    80003318:	40d8                	lw	a4,4(s1)
    8000331a:	ff4713e3          	bne	a4,s4,80003300 <iget+0x38>
      ip->ref++;
    8000331e:	2785                	addiw	a5,a5,1
    80003320:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003322:	0001c517          	auipc	a0,0x1c
    80003326:	4a650513          	addi	a0,a0,1190 # 8001f7c8 <itable>
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	94c080e7          	jalr	-1716(ra) # 80000c76 <release>
      return ip;
    80003332:	8926                	mv	s2,s1
    80003334:	a03d                	j	80003362 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003336:	f7f9                	bnez	a5,80003304 <iget+0x3c>
    80003338:	8926                	mv	s2,s1
    8000333a:	b7e9                	j	80003304 <iget+0x3c>
  if(empty == 0)
    8000333c:	02090c63          	beqz	s2,80003374 <iget+0xac>
  ip->dev = dev;
    80003340:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003344:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003348:	4785                	li	a5,1
    8000334a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000334e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003352:	0001c517          	auipc	a0,0x1c
    80003356:	47650513          	addi	a0,a0,1142 # 8001f7c8 <itable>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	91c080e7          	jalr	-1764(ra) # 80000c76 <release>
}
    80003362:	854a                	mv	a0,s2
    80003364:	70a2                	ld	ra,40(sp)
    80003366:	7402                	ld	s0,32(sp)
    80003368:	64e2                	ld	s1,24(sp)
    8000336a:	6942                	ld	s2,16(sp)
    8000336c:	69a2                	ld	s3,8(sp)
    8000336e:	6a02                	ld	s4,0(sp)
    80003370:	6145                	addi	sp,sp,48
    80003372:	8082                	ret
    panic("iget: no inodes");
    80003374:	00005517          	auipc	a0,0x5
    80003378:	1ec50513          	addi	a0,a0,492 # 80008560 <syscalls+0x130>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	1ae080e7          	jalr	430(ra) # 8000052a <panic>

0000000080003384 <fsinit>:
fsinit(int dev) {
    80003384:	7179                	addi	sp,sp,-48
    80003386:	f406                	sd	ra,40(sp)
    80003388:	f022                	sd	s0,32(sp)
    8000338a:	ec26                	sd	s1,24(sp)
    8000338c:	e84a                	sd	s2,16(sp)
    8000338e:	e44e                	sd	s3,8(sp)
    80003390:	1800                	addi	s0,sp,48
    80003392:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003394:	4585                	li	a1,1
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	a62080e7          	jalr	-1438(ra) # 80002df8 <bread>
    8000339e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033a0:	0001c997          	auipc	s3,0x1c
    800033a4:	40898993          	addi	s3,s3,1032 # 8001f7a8 <sb>
    800033a8:	02000613          	li	a2,32
    800033ac:	05850593          	addi	a1,a0,88
    800033b0:	854e                	mv	a0,s3
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	968080e7          	jalr	-1688(ra) # 80000d1a <memmove>
  brelse(bp);
    800033ba:	8526                	mv	a0,s1
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	b6c080e7          	jalr	-1172(ra) # 80002f28 <brelse>
  if(sb.magic != FSMAGIC)
    800033c4:	0009a703          	lw	a4,0(s3)
    800033c8:	102037b7          	lui	a5,0x10203
    800033cc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033d0:	02f71263          	bne	a4,a5,800033f4 <fsinit+0x70>
  initlog(dev, &sb);
    800033d4:	0001c597          	auipc	a1,0x1c
    800033d8:	3d458593          	addi	a1,a1,980 # 8001f7a8 <sb>
    800033dc:	854a                	mv	a0,s2
    800033de:	00001097          	auipc	ra,0x1
    800033e2:	b4e080e7          	jalr	-1202(ra) # 80003f2c <initlog>
}
    800033e6:	70a2                	ld	ra,40(sp)
    800033e8:	7402                	ld	s0,32(sp)
    800033ea:	64e2                	ld	s1,24(sp)
    800033ec:	6942                	ld	s2,16(sp)
    800033ee:	69a2                	ld	s3,8(sp)
    800033f0:	6145                	addi	sp,sp,48
    800033f2:	8082                	ret
    panic("invalid file system");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	17c50513          	addi	a0,a0,380 # 80008570 <syscalls+0x140>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	12e080e7          	jalr	302(ra) # 8000052a <panic>

0000000080003404 <iinit>:
{
    80003404:	7179                	addi	sp,sp,-48
    80003406:	f406                	sd	ra,40(sp)
    80003408:	f022                	sd	s0,32(sp)
    8000340a:	ec26                	sd	s1,24(sp)
    8000340c:	e84a                	sd	s2,16(sp)
    8000340e:	e44e                	sd	s3,8(sp)
    80003410:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003412:	00005597          	auipc	a1,0x5
    80003416:	17658593          	addi	a1,a1,374 # 80008588 <syscalls+0x158>
    8000341a:	0001c517          	auipc	a0,0x1c
    8000341e:	3ae50513          	addi	a0,a0,942 # 8001f7c8 <itable>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	710080e7          	jalr	1808(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000342a:	0001c497          	auipc	s1,0x1c
    8000342e:	3c648493          	addi	s1,s1,966 # 8001f7f0 <itable+0x28>
    80003432:	0001e997          	auipc	s3,0x1e
    80003436:	e4e98993          	addi	s3,s3,-434 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000343a:	00005917          	auipc	s2,0x5
    8000343e:	15690913          	addi	s2,s2,342 # 80008590 <syscalls+0x160>
    80003442:	85ca                	mv	a1,s2
    80003444:	8526                	mv	a0,s1
    80003446:	00001097          	auipc	ra,0x1
    8000344a:	e4a080e7          	jalr	-438(ra) # 80004290 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000344e:	08848493          	addi	s1,s1,136
    80003452:	ff3498e3          	bne	s1,s3,80003442 <iinit+0x3e>
}
    80003456:	70a2                	ld	ra,40(sp)
    80003458:	7402                	ld	s0,32(sp)
    8000345a:	64e2                	ld	s1,24(sp)
    8000345c:	6942                	ld	s2,16(sp)
    8000345e:	69a2                	ld	s3,8(sp)
    80003460:	6145                	addi	sp,sp,48
    80003462:	8082                	ret

0000000080003464 <ialloc>:
{
    80003464:	715d                	addi	sp,sp,-80
    80003466:	e486                	sd	ra,72(sp)
    80003468:	e0a2                	sd	s0,64(sp)
    8000346a:	fc26                	sd	s1,56(sp)
    8000346c:	f84a                	sd	s2,48(sp)
    8000346e:	f44e                	sd	s3,40(sp)
    80003470:	f052                	sd	s4,32(sp)
    80003472:	ec56                	sd	s5,24(sp)
    80003474:	e85a                	sd	s6,16(sp)
    80003476:	e45e                	sd	s7,8(sp)
    80003478:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000347a:	0001c717          	auipc	a4,0x1c
    8000347e:	33a72703          	lw	a4,826(a4) # 8001f7b4 <sb+0xc>
    80003482:	4785                	li	a5,1
    80003484:	04e7fa63          	bgeu	a5,a4,800034d8 <ialloc+0x74>
    80003488:	8aaa                	mv	s5,a0
    8000348a:	8bae                	mv	s7,a1
    8000348c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000348e:	0001ca17          	auipc	s4,0x1c
    80003492:	31aa0a13          	addi	s4,s4,794 # 8001f7a8 <sb>
    80003496:	00048b1b          	sext.w	s6,s1
    8000349a:	0044d793          	srli	a5,s1,0x4
    8000349e:	018a2583          	lw	a1,24(s4)
    800034a2:	9dbd                	addw	a1,a1,a5
    800034a4:	8556                	mv	a0,s5
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	952080e7          	jalr	-1710(ra) # 80002df8 <bread>
    800034ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034b0:	05850993          	addi	s3,a0,88
    800034b4:	00f4f793          	andi	a5,s1,15
    800034b8:	079a                	slli	a5,a5,0x6
    800034ba:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034bc:	00099783          	lh	a5,0(s3)
    800034c0:	c785                	beqz	a5,800034e8 <ialloc+0x84>
    brelse(bp);
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	a66080e7          	jalr	-1434(ra) # 80002f28 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034ca:	0485                	addi	s1,s1,1
    800034cc:	00ca2703          	lw	a4,12(s4)
    800034d0:	0004879b          	sext.w	a5,s1
    800034d4:	fce7e1e3          	bltu	a5,a4,80003496 <ialloc+0x32>
  panic("ialloc: no inodes");
    800034d8:	00005517          	auipc	a0,0x5
    800034dc:	0c050513          	addi	a0,a0,192 # 80008598 <syscalls+0x168>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800034e8:	04000613          	li	a2,64
    800034ec:	4581                	li	a1,0
    800034ee:	854e                	mv	a0,s3
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	7ce080e7          	jalr	1998(ra) # 80000cbe <memset>
      dip->type = type;
    800034f8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034fc:	854a                	mv	a0,s2
    800034fe:	00001097          	auipc	ra,0x1
    80003502:	cac080e7          	jalr	-852(ra) # 800041aa <log_write>
      brelse(bp);
    80003506:	854a                	mv	a0,s2
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	a20080e7          	jalr	-1504(ra) # 80002f28 <brelse>
      return iget(dev, inum);
    80003510:	85da                	mv	a1,s6
    80003512:	8556                	mv	a0,s5
    80003514:	00000097          	auipc	ra,0x0
    80003518:	db4080e7          	jalr	-588(ra) # 800032c8 <iget>
}
    8000351c:	60a6                	ld	ra,72(sp)
    8000351e:	6406                	ld	s0,64(sp)
    80003520:	74e2                	ld	s1,56(sp)
    80003522:	7942                	ld	s2,48(sp)
    80003524:	79a2                	ld	s3,40(sp)
    80003526:	7a02                	ld	s4,32(sp)
    80003528:	6ae2                	ld	s5,24(sp)
    8000352a:	6b42                	ld	s6,16(sp)
    8000352c:	6ba2                	ld	s7,8(sp)
    8000352e:	6161                	addi	sp,sp,80
    80003530:	8082                	ret

0000000080003532 <iupdate>:
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	e04a                	sd	s2,0(sp)
    8000353c:	1000                	addi	s0,sp,32
    8000353e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003540:	415c                	lw	a5,4(a0)
    80003542:	0047d79b          	srliw	a5,a5,0x4
    80003546:	0001c597          	auipc	a1,0x1c
    8000354a:	27a5a583          	lw	a1,634(a1) # 8001f7c0 <sb+0x18>
    8000354e:	9dbd                	addw	a1,a1,a5
    80003550:	4108                	lw	a0,0(a0)
    80003552:	00000097          	auipc	ra,0x0
    80003556:	8a6080e7          	jalr	-1882(ra) # 80002df8 <bread>
    8000355a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000355c:	05850793          	addi	a5,a0,88
    80003560:	40c8                	lw	a0,4(s1)
    80003562:	893d                	andi	a0,a0,15
    80003564:	051a                	slli	a0,a0,0x6
    80003566:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003568:	04449703          	lh	a4,68(s1)
    8000356c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003570:	04649703          	lh	a4,70(s1)
    80003574:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003578:	04849703          	lh	a4,72(s1)
    8000357c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003580:	04a49703          	lh	a4,74(s1)
    80003584:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003588:	44f8                	lw	a4,76(s1)
    8000358a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000358c:	03400613          	li	a2,52
    80003590:	05048593          	addi	a1,s1,80
    80003594:	0531                	addi	a0,a0,12
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	784080e7          	jalr	1924(ra) # 80000d1a <memmove>
  log_write(bp);
    8000359e:	854a                	mv	a0,s2
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	c0a080e7          	jalr	-1014(ra) # 800041aa <log_write>
  brelse(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	97e080e7          	jalr	-1666(ra) # 80002f28 <brelse>
}
    800035b2:	60e2                	ld	ra,24(sp)
    800035b4:	6442                	ld	s0,16(sp)
    800035b6:	64a2                	ld	s1,8(sp)
    800035b8:	6902                	ld	s2,0(sp)
    800035ba:	6105                	addi	sp,sp,32
    800035bc:	8082                	ret

00000000800035be <idup>:
{
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	e426                	sd	s1,8(sp)
    800035c6:	1000                	addi	s0,sp,32
    800035c8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035ca:	0001c517          	auipc	a0,0x1c
    800035ce:	1fe50513          	addi	a0,a0,510 # 8001f7c8 <itable>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	5f0080e7          	jalr	1520(ra) # 80000bc2 <acquire>
  ip->ref++;
    800035da:	449c                	lw	a5,8(s1)
    800035dc:	2785                	addiw	a5,a5,1
    800035de:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035e0:	0001c517          	auipc	a0,0x1c
    800035e4:	1e850513          	addi	a0,a0,488 # 8001f7c8 <itable>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	68e080e7          	jalr	1678(ra) # 80000c76 <release>
}
    800035f0:	8526                	mv	a0,s1
    800035f2:	60e2                	ld	ra,24(sp)
    800035f4:	6442                	ld	s0,16(sp)
    800035f6:	64a2                	ld	s1,8(sp)
    800035f8:	6105                	addi	sp,sp,32
    800035fa:	8082                	ret

00000000800035fc <ilock>:
{
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	e426                	sd	s1,8(sp)
    80003604:	e04a                	sd	s2,0(sp)
    80003606:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003608:	c115                	beqz	a0,8000362c <ilock+0x30>
    8000360a:	84aa                	mv	s1,a0
    8000360c:	451c                	lw	a5,8(a0)
    8000360e:	00f05f63          	blez	a5,8000362c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003612:	0541                	addi	a0,a0,16
    80003614:	00001097          	auipc	ra,0x1
    80003618:	cb6080e7          	jalr	-842(ra) # 800042ca <acquiresleep>
  if(ip->valid == 0){
    8000361c:	40bc                	lw	a5,64(s1)
    8000361e:	cf99                	beqz	a5,8000363c <ilock+0x40>
}
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	64a2                	ld	s1,8(sp)
    80003626:	6902                	ld	s2,0(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret
    panic("ilock");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	f8450513          	addi	a0,a0,-124 # 800085b0 <syscalls+0x180>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	ef6080e7          	jalr	-266(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000363c:	40dc                	lw	a5,4(s1)
    8000363e:	0047d79b          	srliw	a5,a5,0x4
    80003642:	0001c597          	auipc	a1,0x1c
    80003646:	17e5a583          	lw	a1,382(a1) # 8001f7c0 <sb+0x18>
    8000364a:	9dbd                	addw	a1,a1,a5
    8000364c:	4088                	lw	a0,0(s1)
    8000364e:	fffff097          	auipc	ra,0xfffff
    80003652:	7aa080e7          	jalr	1962(ra) # 80002df8 <bread>
    80003656:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003658:	05850593          	addi	a1,a0,88
    8000365c:	40dc                	lw	a5,4(s1)
    8000365e:	8bbd                	andi	a5,a5,15
    80003660:	079a                	slli	a5,a5,0x6
    80003662:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003664:	00059783          	lh	a5,0(a1)
    80003668:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000366c:	00259783          	lh	a5,2(a1)
    80003670:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003674:	00459783          	lh	a5,4(a1)
    80003678:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000367c:	00659783          	lh	a5,6(a1)
    80003680:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003684:	459c                	lw	a5,8(a1)
    80003686:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003688:	03400613          	li	a2,52
    8000368c:	05b1                	addi	a1,a1,12
    8000368e:	05048513          	addi	a0,s1,80
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	688080e7          	jalr	1672(ra) # 80000d1a <memmove>
    brelse(bp);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	88c080e7          	jalr	-1908(ra) # 80002f28 <brelse>
    ip->valid = 1;
    800036a4:	4785                	li	a5,1
    800036a6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036a8:	04449783          	lh	a5,68(s1)
    800036ac:	fbb5                	bnez	a5,80003620 <ilock+0x24>
      panic("ilock: no type");
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	f0a50513          	addi	a0,a0,-246 # 800085b8 <syscalls+0x188>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	e74080e7          	jalr	-396(ra) # 8000052a <panic>

00000000800036be <iunlock>:
{
    800036be:	1101                	addi	sp,sp,-32
    800036c0:	ec06                	sd	ra,24(sp)
    800036c2:	e822                	sd	s0,16(sp)
    800036c4:	e426                	sd	s1,8(sp)
    800036c6:	e04a                	sd	s2,0(sp)
    800036c8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036ca:	c905                	beqz	a0,800036fa <iunlock+0x3c>
    800036cc:	84aa                	mv	s1,a0
    800036ce:	01050913          	addi	s2,a0,16
    800036d2:	854a                	mv	a0,s2
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	c90080e7          	jalr	-880(ra) # 80004364 <holdingsleep>
    800036dc:	cd19                	beqz	a0,800036fa <iunlock+0x3c>
    800036de:	449c                	lw	a5,8(s1)
    800036e0:	00f05d63          	blez	a5,800036fa <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036e4:	854a                	mv	a0,s2
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	c3a080e7          	jalr	-966(ra) # 80004320 <releasesleep>
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6902                	ld	s2,0(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret
    panic("iunlock");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	ece50513          	addi	a0,a0,-306 # 800085c8 <syscalls+0x198>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e28080e7          	jalr	-472(ra) # 8000052a <panic>

000000008000370a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000370a:	7179                	addi	sp,sp,-48
    8000370c:	f406                	sd	ra,40(sp)
    8000370e:	f022                	sd	s0,32(sp)
    80003710:	ec26                	sd	s1,24(sp)
    80003712:	e84a                	sd	s2,16(sp)
    80003714:	e44e                	sd	s3,8(sp)
    80003716:	e052                	sd	s4,0(sp)
    80003718:	1800                	addi	s0,sp,48
    8000371a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000371c:	05050493          	addi	s1,a0,80
    80003720:	08050913          	addi	s2,a0,128
    80003724:	a021                	j	8000372c <itrunc+0x22>
    80003726:	0491                	addi	s1,s1,4
    80003728:	01248d63          	beq	s1,s2,80003742 <itrunc+0x38>
    if(ip->addrs[i]){
    8000372c:	408c                	lw	a1,0(s1)
    8000372e:	dde5                	beqz	a1,80003726 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003730:	0009a503          	lw	a0,0(s3)
    80003734:	00000097          	auipc	ra,0x0
    80003738:	90a080e7          	jalr	-1782(ra) # 8000303e <bfree>
      ip->addrs[i] = 0;
    8000373c:	0004a023          	sw	zero,0(s1)
    80003740:	b7dd                	j	80003726 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003742:	0809a583          	lw	a1,128(s3)
    80003746:	e185                	bnez	a1,80003766 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003748:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000374c:	854e                	mv	a0,s3
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	de4080e7          	jalr	-540(ra) # 80003532 <iupdate>
}
    80003756:	70a2                	ld	ra,40(sp)
    80003758:	7402                	ld	s0,32(sp)
    8000375a:	64e2                	ld	s1,24(sp)
    8000375c:	6942                	ld	s2,16(sp)
    8000375e:	69a2                	ld	s3,8(sp)
    80003760:	6a02                	ld	s4,0(sp)
    80003762:	6145                	addi	sp,sp,48
    80003764:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003766:	0009a503          	lw	a0,0(s3)
    8000376a:	fffff097          	auipc	ra,0xfffff
    8000376e:	68e080e7          	jalr	1678(ra) # 80002df8 <bread>
    80003772:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003774:	05850493          	addi	s1,a0,88
    80003778:	45850913          	addi	s2,a0,1112
    8000377c:	a021                	j	80003784 <itrunc+0x7a>
    8000377e:	0491                	addi	s1,s1,4
    80003780:	01248b63          	beq	s1,s2,80003796 <itrunc+0x8c>
      if(a[j])
    80003784:	408c                	lw	a1,0(s1)
    80003786:	dde5                	beqz	a1,8000377e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003788:	0009a503          	lw	a0,0(s3)
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	8b2080e7          	jalr	-1870(ra) # 8000303e <bfree>
    80003794:	b7ed                	j	8000377e <itrunc+0x74>
    brelse(bp);
    80003796:	8552                	mv	a0,s4
    80003798:	fffff097          	auipc	ra,0xfffff
    8000379c:	790080e7          	jalr	1936(ra) # 80002f28 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037a0:	0809a583          	lw	a1,128(s3)
    800037a4:	0009a503          	lw	a0,0(s3)
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	896080e7          	jalr	-1898(ra) # 8000303e <bfree>
    ip->addrs[NDIRECT] = 0;
    800037b0:	0809a023          	sw	zero,128(s3)
    800037b4:	bf51                	j	80003748 <itrunc+0x3e>

00000000800037b6 <iput>:
{
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	e04a                	sd	s2,0(sp)
    800037c0:	1000                	addi	s0,sp,32
    800037c2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037c4:	0001c517          	auipc	a0,0x1c
    800037c8:	00450513          	addi	a0,a0,4 # 8001f7c8 <itable>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	3f6080e7          	jalr	1014(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037d4:	4498                	lw	a4,8(s1)
    800037d6:	4785                	li	a5,1
    800037d8:	02f70363          	beq	a4,a5,800037fe <iput+0x48>
  ip->ref--;
    800037dc:	449c                	lw	a5,8(s1)
    800037de:	37fd                	addiw	a5,a5,-1
    800037e0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037e2:	0001c517          	auipc	a0,0x1c
    800037e6:	fe650513          	addi	a0,a0,-26 # 8001f7c8 <itable>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	48c080e7          	jalr	1164(ra) # 80000c76 <release>
}
    800037f2:	60e2                	ld	ra,24(sp)
    800037f4:	6442                	ld	s0,16(sp)
    800037f6:	64a2                	ld	s1,8(sp)
    800037f8:	6902                	ld	s2,0(sp)
    800037fa:	6105                	addi	sp,sp,32
    800037fc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037fe:	40bc                	lw	a5,64(s1)
    80003800:	dff1                	beqz	a5,800037dc <iput+0x26>
    80003802:	04a49783          	lh	a5,74(s1)
    80003806:	fbf9                	bnez	a5,800037dc <iput+0x26>
    acquiresleep(&ip->lock);
    80003808:	01048913          	addi	s2,s1,16
    8000380c:	854a                	mv	a0,s2
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	abc080e7          	jalr	-1348(ra) # 800042ca <acquiresleep>
    release(&itable.lock);
    80003816:	0001c517          	auipc	a0,0x1c
    8000381a:	fb250513          	addi	a0,a0,-78 # 8001f7c8 <itable>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	458080e7          	jalr	1112(ra) # 80000c76 <release>
    itrunc(ip);
    80003826:	8526                	mv	a0,s1
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	ee2080e7          	jalr	-286(ra) # 8000370a <itrunc>
    ip->type = 0;
    80003830:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003834:	8526                	mv	a0,s1
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	cfc080e7          	jalr	-772(ra) # 80003532 <iupdate>
    ip->valid = 0;
    8000383e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003842:	854a                	mv	a0,s2
    80003844:	00001097          	auipc	ra,0x1
    80003848:	adc080e7          	jalr	-1316(ra) # 80004320 <releasesleep>
    acquire(&itable.lock);
    8000384c:	0001c517          	auipc	a0,0x1c
    80003850:	f7c50513          	addi	a0,a0,-132 # 8001f7c8 <itable>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	36e080e7          	jalr	878(ra) # 80000bc2 <acquire>
    8000385c:	b741                	j	800037dc <iput+0x26>

000000008000385e <iunlockput>:
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	e426                	sd	s1,8(sp)
    80003866:	1000                	addi	s0,sp,32
    80003868:	84aa                	mv	s1,a0
  iunlock(ip);
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	e54080e7          	jalr	-428(ra) # 800036be <iunlock>
  iput(ip);
    80003872:	8526                	mv	a0,s1
    80003874:	00000097          	auipc	ra,0x0
    80003878:	f42080e7          	jalr	-190(ra) # 800037b6 <iput>
}
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret

0000000080003886 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003886:	1141                	addi	sp,sp,-16
    80003888:	e422                	sd	s0,8(sp)
    8000388a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000388c:	411c                	lw	a5,0(a0)
    8000388e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003890:	415c                	lw	a5,4(a0)
    80003892:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003894:	04451783          	lh	a5,68(a0)
    80003898:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000389c:	04a51783          	lh	a5,74(a0)
    800038a0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038a4:	04c56783          	lwu	a5,76(a0)
    800038a8:	e99c                	sd	a5,16(a1)
}
    800038aa:	6422                	ld	s0,8(sp)
    800038ac:	0141                	addi	sp,sp,16
    800038ae:	8082                	ret

00000000800038b0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038b0:	457c                	lw	a5,76(a0)
    800038b2:	0ed7e963          	bltu	a5,a3,800039a4 <readi+0xf4>
{
    800038b6:	7159                	addi	sp,sp,-112
    800038b8:	f486                	sd	ra,104(sp)
    800038ba:	f0a2                	sd	s0,96(sp)
    800038bc:	eca6                	sd	s1,88(sp)
    800038be:	e8ca                	sd	s2,80(sp)
    800038c0:	e4ce                	sd	s3,72(sp)
    800038c2:	e0d2                	sd	s4,64(sp)
    800038c4:	fc56                	sd	s5,56(sp)
    800038c6:	f85a                	sd	s6,48(sp)
    800038c8:	f45e                	sd	s7,40(sp)
    800038ca:	f062                	sd	s8,32(sp)
    800038cc:	ec66                	sd	s9,24(sp)
    800038ce:	e86a                	sd	s10,16(sp)
    800038d0:	e46e                	sd	s11,8(sp)
    800038d2:	1880                	addi	s0,sp,112
    800038d4:	8baa                	mv	s7,a0
    800038d6:	8c2e                	mv	s8,a1
    800038d8:	8ab2                	mv	s5,a2
    800038da:	84b6                	mv	s1,a3
    800038dc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038de:	9f35                	addw	a4,a4,a3
    return 0;
    800038e0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038e2:	0ad76063          	bltu	a4,a3,80003982 <readi+0xd2>
  if(off + n > ip->size)
    800038e6:	00e7f463          	bgeu	a5,a4,800038ee <readi+0x3e>
    n = ip->size - off;
    800038ea:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038ee:	0a0b0963          	beqz	s6,800039a0 <readi+0xf0>
    800038f2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038f4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038f8:	5cfd                	li	s9,-1
    800038fa:	a82d                	j	80003934 <readi+0x84>
    800038fc:	020a1d93          	slli	s11,s4,0x20
    80003900:	020ddd93          	srli	s11,s11,0x20
    80003904:	05890793          	addi	a5,s2,88
    80003908:	86ee                	mv	a3,s11
    8000390a:	963e                	add	a2,a2,a5
    8000390c:	85d6                	mv	a1,s5
    8000390e:	8562                	mv	a0,s8
    80003910:	fffff097          	auipc	ra,0xfffff
    80003914:	ac4080e7          	jalr	-1340(ra) # 800023d4 <either_copyout>
    80003918:	05950d63          	beq	a0,s9,80003972 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000391c:	854a                	mv	a0,s2
    8000391e:	fffff097          	auipc	ra,0xfffff
    80003922:	60a080e7          	jalr	1546(ra) # 80002f28 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003926:	013a09bb          	addw	s3,s4,s3
    8000392a:	009a04bb          	addw	s1,s4,s1
    8000392e:	9aee                	add	s5,s5,s11
    80003930:	0569f763          	bgeu	s3,s6,8000397e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003934:	000ba903          	lw	s2,0(s7)
    80003938:	00a4d59b          	srliw	a1,s1,0xa
    8000393c:	855e                	mv	a0,s7
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	8ae080e7          	jalr	-1874(ra) # 800031ec <bmap>
    80003946:	0005059b          	sext.w	a1,a0
    8000394a:	854a                	mv	a0,s2
    8000394c:	fffff097          	auipc	ra,0xfffff
    80003950:	4ac080e7          	jalr	1196(ra) # 80002df8 <bread>
    80003954:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003956:	3ff4f613          	andi	a2,s1,1023
    8000395a:	40cd07bb          	subw	a5,s10,a2
    8000395e:	413b073b          	subw	a4,s6,s3
    80003962:	8a3e                	mv	s4,a5
    80003964:	2781                	sext.w	a5,a5
    80003966:	0007069b          	sext.w	a3,a4
    8000396a:	f8f6f9e3          	bgeu	a3,a5,800038fc <readi+0x4c>
    8000396e:	8a3a                	mv	s4,a4
    80003970:	b771                	j	800038fc <readi+0x4c>
      brelse(bp);
    80003972:	854a                	mv	a0,s2
    80003974:	fffff097          	auipc	ra,0xfffff
    80003978:	5b4080e7          	jalr	1460(ra) # 80002f28 <brelse>
      tot = -1;
    8000397c:	59fd                	li	s3,-1
  }
  return tot;
    8000397e:	0009851b          	sext.w	a0,s3
}
    80003982:	70a6                	ld	ra,104(sp)
    80003984:	7406                	ld	s0,96(sp)
    80003986:	64e6                	ld	s1,88(sp)
    80003988:	6946                	ld	s2,80(sp)
    8000398a:	69a6                	ld	s3,72(sp)
    8000398c:	6a06                	ld	s4,64(sp)
    8000398e:	7ae2                	ld	s5,56(sp)
    80003990:	7b42                	ld	s6,48(sp)
    80003992:	7ba2                	ld	s7,40(sp)
    80003994:	7c02                	ld	s8,32(sp)
    80003996:	6ce2                	ld	s9,24(sp)
    80003998:	6d42                	ld	s10,16(sp)
    8000399a:	6da2                	ld	s11,8(sp)
    8000399c:	6165                	addi	sp,sp,112
    8000399e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a0:	89da                	mv	s3,s6
    800039a2:	bff1                	j	8000397e <readi+0xce>
    return 0;
    800039a4:	4501                	li	a0,0
}
    800039a6:	8082                	ret

00000000800039a8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039a8:	457c                	lw	a5,76(a0)
    800039aa:	10d7e863          	bltu	a5,a3,80003aba <writei+0x112>
{
    800039ae:	7159                	addi	sp,sp,-112
    800039b0:	f486                	sd	ra,104(sp)
    800039b2:	f0a2                	sd	s0,96(sp)
    800039b4:	eca6                	sd	s1,88(sp)
    800039b6:	e8ca                	sd	s2,80(sp)
    800039b8:	e4ce                	sd	s3,72(sp)
    800039ba:	e0d2                	sd	s4,64(sp)
    800039bc:	fc56                	sd	s5,56(sp)
    800039be:	f85a                	sd	s6,48(sp)
    800039c0:	f45e                	sd	s7,40(sp)
    800039c2:	f062                	sd	s8,32(sp)
    800039c4:	ec66                	sd	s9,24(sp)
    800039c6:	e86a                	sd	s10,16(sp)
    800039c8:	e46e                	sd	s11,8(sp)
    800039ca:	1880                	addi	s0,sp,112
    800039cc:	8b2a                	mv	s6,a0
    800039ce:	8c2e                	mv	s8,a1
    800039d0:	8ab2                	mv	s5,a2
    800039d2:	8936                	mv	s2,a3
    800039d4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039d6:	00e687bb          	addw	a5,a3,a4
    800039da:	0ed7e263          	bltu	a5,a3,80003abe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039de:	00043737          	lui	a4,0x43
    800039e2:	0ef76063          	bltu	a4,a5,80003ac2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039e6:	0c0b8863          	beqz	s7,80003ab6 <writei+0x10e>
    800039ea:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ec:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039f0:	5cfd                	li	s9,-1
    800039f2:	a091                	j	80003a36 <writei+0x8e>
    800039f4:	02099d93          	slli	s11,s3,0x20
    800039f8:	020ddd93          	srli	s11,s11,0x20
    800039fc:	05848793          	addi	a5,s1,88
    80003a00:	86ee                	mv	a3,s11
    80003a02:	8656                	mv	a2,s5
    80003a04:	85e2                	mv	a1,s8
    80003a06:	953e                	add	a0,a0,a5
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	a22080e7          	jalr	-1502(ra) # 8000242a <either_copyin>
    80003a10:	07950263          	beq	a0,s9,80003a74 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a14:	8526                	mv	a0,s1
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	794080e7          	jalr	1940(ra) # 800041aa <log_write>
    brelse(bp);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	fffff097          	auipc	ra,0xfffff
    80003a24:	508080e7          	jalr	1288(ra) # 80002f28 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a28:	01498a3b          	addw	s4,s3,s4
    80003a2c:	0129893b          	addw	s2,s3,s2
    80003a30:	9aee                	add	s5,s5,s11
    80003a32:	057a7663          	bgeu	s4,s7,80003a7e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a36:	000b2483          	lw	s1,0(s6)
    80003a3a:	00a9559b          	srliw	a1,s2,0xa
    80003a3e:	855a                	mv	a0,s6
    80003a40:	fffff097          	auipc	ra,0xfffff
    80003a44:	7ac080e7          	jalr	1964(ra) # 800031ec <bmap>
    80003a48:	0005059b          	sext.w	a1,a0
    80003a4c:	8526                	mv	a0,s1
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	3aa080e7          	jalr	938(ra) # 80002df8 <bread>
    80003a56:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a58:	3ff97513          	andi	a0,s2,1023
    80003a5c:	40ad07bb          	subw	a5,s10,a0
    80003a60:	414b873b          	subw	a4,s7,s4
    80003a64:	89be                	mv	s3,a5
    80003a66:	2781                	sext.w	a5,a5
    80003a68:	0007069b          	sext.w	a3,a4
    80003a6c:	f8f6f4e3          	bgeu	a3,a5,800039f4 <writei+0x4c>
    80003a70:	89ba                	mv	s3,a4
    80003a72:	b749                	j	800039f4 <writei+0x4c>
      brelse(bp);
    80003a74:	8526                	mv	a0,s1
    80003a76:	fffff097          	auipc	ra,0xfffff
    80003a7a:	4b2080e7          	jalr	1202(ra) # 80002f28 <brelse>
  }

  if(off > ip->size)
    80003a7e:	04cb2783          	lw	a5,76(s6)
    80003a82:	0127f463          	bgeu	a5,s2,80003a8a <writei+0xe2>
    ip->size = off;
    80003a86:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a8a:	855a                	mv	a0,s6
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	aa6080e7          	jalr	-1370(ra) # 80003532 <iupdate>

  return tot;
    80003a94:	000a051b          	sext.w	a0,s4
}
    80003a98:	70a6                	ld	ra,104(sp)
    80003a9a:	7406                	ld	s0,96(sp)
    80003a9c:	64e6                	ld	s1,88(sp)
    80003a9e:	6946                	ld	s2,80(sp)
    80003aa0:	69a6                	ld	s3,72(sp)
    80003aa2:	6a06                	ld	s4,64(sp)
    80003aa4:	7ae2                	ld	s5,56(sp)
    80003aa6:	7b42                	ld	s6,48(sp)
    80003aa8:	7ba2                	ld	s7,40(sp)
    80003aaa:	7c02                	ld	s8,32(sp)
    80003aac:	6ce2                	ld	s9,24(sp)
    80003aae:	6d42                	ld	s10,16(sp)
    80003ab0:	6da2                	ld	s11,8(sp)
    80003ab2:	6165                	addi	sp,sp,112
    80003ab4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ab6:	8a5e                	mv	s4,s7
    80003ab8:	bfc9                	j	80003a8a <writei+0xe2>
    return -1;
    80003aba:	557d                	li	a0,-1
}
    80003abc:	8082                	ret
    return -1;
    80003abe:	557d                	li	a0,-1
    80003ac0:	bfe1                	j	80003a98 <writei+0xf0>
    return -1;
    80003ac2:	557d                	li	a0,-1
    80003ac4:	bfd1                	j	80003a98 <writei+0xf0>

0000000080003ac6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ac6:	1141                	addi	sp,sp,-16
    80003ac8:	e406                	sd	ra,8(sp)
    80003aca:	e022                	sd	s0,0(sp)
    80003acc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ace:	4639                	li	a2,14
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	2c6080e7          	jalr	710(ra) # 80000d96 <strncmp>
}
    80003ad8:	60a2                	ld	ra,8(sp)
    80003ada:	6402                	ld	s0,0(sp)
    80003adc:	0141                	addi	sp,sp,16
    80003ade:	8082                	ret

0000000080003ae0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ae0:	7139                	addi	sp,sp,-64
    80003ae2:	fc06                	sd	ra,56(sp)
    80003ae4:	f822                	sd	s0,48(sp)
    80003ae6:	f426                	sd	s1,40(sp)
    80003ae8:	f04a                	sd	s2,32(sp)
    80003aea:	ec4e                	sd	s3,24(sp)
    80003aec:	e852                	sd	s4,16(sp)
    80003aee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003af0:	04451703          	lh	a4,68(a0)
    80003af4:	4785                	li	a5,1
    80003af6:	00f71a63          	bne	a4,a5,80003b0a <dirlookup+0x2a>
    80003afa:	892a                	mv	s2,a0
    80003afc:	89ae                	mv	s3,a1
    80003afe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b00:	457c                	lw	a5,76(a0)
    80003b02:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b04:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b06:	e79d                	bnez	a5,80003b34 <dirlookup+0x54>
    80003b08:	a8a5                	j	80003b80 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b0a:	00005517          	auipc	a0,0x5
    80003b0e:	ac650513          	addi	a0,a0,-1338 # 800085d0 <syscalls+0x1a0>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	a18080e7          	jalr	-1512(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003b1a:	00005517          	auipc	a0,0x5
    80003b1e:	ace50513          	addi	a0,a0,-1330 # 800085e8 <syscalls+0x1b8>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	a08080e7          	jalr	-1528(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b2a:	24c1                	addiw	s1,s1,16
    80003b2c:	04c92783          	lw	a5,76(s2)
    80003b30:	04f4f763          	bgeu	s1,a5,80003b7e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b34:	4741                	li	a4,16
    80003b36:	86a6                	mv	a3,s1
    80003b38:	fc040613          	addi	a2,s0,-64
    80003b3c:	4581                	li	a1,0
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	d70080e7          	jalr	-656(ra) # 800038b0 <readi>
    80003b48:	47c1                	li	a5,16
    80003b4a:	fcf518e3          	bne	a0,a5,80003b1a <dirlookup+0x3a>
    if(de.inum == 0)
    80003b4e:	fc045783          	lhu	a5,-64(s0)
    80003b52:	dfe1                	beqz	a5,80003b2a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b54:	fc240593          	addi	a1,s0,-62
    80003b58:	854e                	mv	a0,s3
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	f6c080e7          	jalr	-148(ra) # 80003ac6 <namecmp>
    80003b62:	f561                	bnez	a0,80003b2a <dirlookup+0x4a>
      if(poff)
    80003b64:	000a0463          	beqz	s4,80003b6c <dirlookup+0x8c>
        *poff = off;
    80003b68:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b6c:	fc045583          	lhu	a1,-64(s0)
    80003b70:	00092503          	lw	a0,0(s2)
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	754080e7          	jalr	1876(ra) # 800032c8 <iget>
    80003b7c:	a011                	j	80003b80 <dirlookup+0xa0>
  return 0;
    80003b7e:	4501                	li	a0,0
}
    80003b80:	70e2                	ld	ra,56(sp)
    80003b82:	7442                	ld	s0,48(sp)
    80003b84:	74a2                	ld	s1,40(sp)
    80003b86:	7902                	ld	s2,32(sp)
    80003b88:	69e2                	ld	s3,24(sp)
    80003b8a:	6a42                	ld	s4,16(sp)
    80003b8c:	6121                	addi	sp,sp,64
    80003b8e:	8082                	ret

0000000080003b90 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b90:	711d                	addi	sp,sp,-96
    80003b92:	ec86                	sd	ra,88(sp)
    80003b94:	e8a2                	sd	s0,80(sp)
    80003b96:	e4a6                	sd	s1,72(sp)
    80003b98:	e0ca                	sd	s2,64(sp)
    80003b9a:	fc4e                	sd	s3,56(sp)
    80003b9c:	f852                	sd	s4,48(sp)
    80003b9e:	f456                	sd	s5,40(sp)
    80003ba0:	f05a                	sd	s6,32(sp)
    80003ba2:	ec5e                	sd	s7,24(sp)
    80003ba4:	e862                	sd	s8,16(sp)
    80003ba6:	e466                	sd	s9,8(sp)
    80003ba8:	1080                	addi	s0,sp,96
    80003baa:	84aa                	mv	s1,a0
    80003bac:	8aae                	mv	s5,a1
    80003bae:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bb0:	00054703          	lbu	a4,0(a0)
    80003bb4:	02f00793          	li	a5,47
    80003bb8:	02f70363          	beq	a4,a5,80003bde <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bbc:	ffffe097          	auipc	ra,0xffffe
    80003bc0:	db4080e7          	jalr	-588(ra) # 80001970 <myproc>
    80003bc4:	15053503          	ld	a0,336(a0)
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	9f6080e7          	jalr	-1546(ra) # 800035be <idup>
    80003bd0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003bd2:	02f00913          	li	s2,47
  len = path - s;
    80003bd6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003bd8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bda:	4b85                	li	s7,1
    80003bdc:	a865                	j	80003c94 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bde:	4585                	li	a1,1
    80003be0:	4505                	li	a0,1
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	6e6080e7          	jalr	1766(ra) # 800032c8 <iget>
    80003bea:	89aa                	mv	s3,a0
    80003bec:	b7dd                	j	80003bd2 <namex+0x42>
      iunlockput(ip);
    80003bee:	854e                	mv	a0,s3
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	c6e080e7          	jalr	-914(ra) # 8000385e <iunlockput>
      return 0;
    80003bf8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bfa:	854e                	mv	a0,s3
    80003bfc:	60e6                	ld	ra,88(sp)
    80003bfe:	6446                	ld	s0,80(sp)
    80003c00:	64a6                	ld	s1,72(sp)
    80003c02:	6906                	ld	s2,64(sp)
    80003c04:	79e2                	ld	s3,56(sp)
    80003c06:	7a42                	ld	s4,48(sp)
    80003c08:	7aa2                	ld	s5,40(sp)
    80003c0a:	7b02                	ld	s6,32(sp)
    80003c0c:	6be2                	ld	s7,24(sp)
    80003c0e:	6c42                	ld	s8,16(sp)
    80003c10:	6ca2                	ld	s9,8(sp)
    80003c12:	6125                	addi	sp,sp,96
    80003c14:	8082                	ret
      iunlock(ip);
    80003c16:	854e                	mv	a0,s3
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	aa6080e7          	jalr	-1370(ra) # 800036be <iunlock>
      return ip;
    80003c20:	bfe9                	j	80003bfa <namex+0x6a>
      iunlockput(ip);
    80003c22:	854e                	mv	a0,s3
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	c3a080e7          	jalr	-966(ra) # 8000385e <iunlockput>
      return 0;
    80003c2c:	89e6                	mv	s3,s9
    80003c2e:	b7f1                	j	80003bfa <namex+0x6a>
  len = path - s;
    80003c30:	40b48633          	sub	a2,s1,a1
    80003c34:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c38:	099c5463          	bge	s8,s9,80003cc0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c3c:	4639                	li	a2,14
    80003c3e:	8552                	mv	a0,s4
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	0da080e7          	jalr	218(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003c48:	0004c783          	lbu	a5,0(s1)
    80003c4c:	01279763          	bne	a5,s2,80003c5a <namex+0xca>
    path++;
    80003c50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c52:	0004c783          	lbu	a5,0(s1)
    80003c56:	ff278de3          	beq	a5,s2,80003c50 <namex+0xc0>
    ilock(ip);
    80003c5a:	854e                	mv	a0,s3
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	9a0080e7          	jalr	-1632(ra) # 800035fc <ilock>
    if(ip->type != T_DIR){
    80003c64:	04499783          	lh	a5,68(s3)
    80003c68:	f97793e3          	bne	a5,s7,80003bee <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c6c:	000a8563          	beqz	s5,80003c76 <namex+0xe6>
    80003c70:	0004c783          	lbu	a5,0(s1)
    80003c74:	d3cd                	beqz	a5,80003c16 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c76:	865a                	mv	a2,s6
    80003c78:	85d2                	mv	a1,s4
    80003c7a:	854e                	mv	a0,s3
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	e64080e7          	jalr	-412(ra) # 80003ae0 <dirlookup>
    80003c84:	8caa                	mv	s9,a0
    80003c86:	dd51                	beqz	a0,80003c22 <namex+0x92>
    iunlockput(ip);
    80003c88:	854e                	mv	a0,s3
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	bd4080e7          	jalr	-1068(ra) # 8000385e <iunlockput>
    ip = next;
    80003c92:	89e6                	mv	s3,s9
  while(*path == '/')
    80003c94:	0004c783          	lbu	a5,0(s1)
    80003c98:	05279763          	bne	a5,s2,80003ce6 <namex+0x156>
    path++;
    80003c9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c9e:	0004c783          	lbu	a5,0(s1)
    80003ca2:	ff278de3          	beq	a5,s2,80003c9c <namex+0x10c>
  if(*path == 0)
    80003ca6:	c79d                	beqz	a5,80003cd4 <namex+0x144>
    path++;
    80003ca8:	85a6                	mv	a1,s1
  len = path - s;
    80003caa:	8cda                	mv	s9,s6
    80003cac:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003cae:	01278963          	beq	a5,s2,80003cc0 <namex+0x130>
    80003cb2:	dfbd                	beqz	a5,80003c30 <namex+0xa0>
    path++;
    80003cb4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003cb6:	0004c783          	lbu	a5,0(s1)
    80003cba:	ff279ce3          	bne	a5,s2,80003cb2 <namex+0x122>
    80003cbe:	bf8d                	j	80003c30 <namex+0xa0>
    memmove(name, s, len);
    80003cc0:	2601                	sext.w	a2,a2
    80003cc2:	8552                	mv	a0,s4
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	056080e7          	jalr	86(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003ccc:	9cd2                	add	s9,s9,s4
    80003cce:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cd2:	bf9d                	j	80003c48 <namex+0xb8>
  if(nameiparent){
    80003cd4:	f20a83e3          	beqz	s5,80003bfa <namex+0x6a>
    iput(ip);
    80003cd8:	854e                	mv	a0,s3
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	adc080e7          	jalr	-1316(ra) # 800037b6 <iput>
    return 0;
    80003ce2:	4981                	li	s3,0
    80003ce4:	bf19                	j	80003bfa <namex+0x6a>
  if(*path == 0)
    80003ce6:	d7fd                	beqz	a5,80003cd4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ce8:	0004c783          	lbu	a5,0(s1)
    80003cec:	85a6                	mv	a1,s1
    80003cee:	b7d1                	j	80003cb2 <namex+0x122>

0000000080003cf0 <dirlink>:
{
    80003cf0:	7139                	addi	sp,sp,-64
    80003cf2:	fc06                	sd	ra,56(sp)
    80003cf4:	f822                	sd	s0,48(sp)
    80003cf6:	f426                	sd	s1,40(sp)
    80003cf8:	f04a                	sd	s2,32(sp)
    80003cfa:	ec4e                	sd	s3,24(sp)
    80003cfc:	e852                	sd	s4,16(sp)
    80003cfe:	0080                	addi	s0,sp,64
    80003d00:	892a                	mv	s2,a0
    80003d02:	8a2e                	mv	s4,a1
    80003d04:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d06:	4601                	li	a2,0
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	dd8080e7          	jalr	-552(ra) # 80003ae0 <dirlookup>
    80003d10:	e93d                	bnez	a0,80003d86 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d12:	04c92483          	lw	s1,76(s2)
    80003d16:	c49d                	beqz	s1,80003d44 <dirlink+0x54>
    80003d18:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d1a:	4741                	li	a4,16
    80003d1c:	86a6                	mv	a3,s1
    80003d1e:	fc040613          	addi	a2,s0,-64
    80003d22:	4581                	li	a1,0
    80003d24:	854a                	mv	a0,s2
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	b8a080e7          	jalr	-1142(ra) # 800038b0 <readi>
    80003d2e:	47c1                	li	a5,16
    80003d30:	06f51163          	bne	a0,a5,80003d92 <dirlink+0xa2>
    if(de.inum == 0)
    80003d34:	fc045783          	lhu	a5,-64(s0)
    80003d38:	c791                	beqz	a5,80003d44 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3a:	24c1                	addiw	s1,s1,16
    80003d3c:	04c92783          	lw	a5,76(s2)
    80003d40:	fcf4ede3          	bltu	s1,a5,80003d1a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d44:	4639                	li	a2,14
    80003d46:	85d2                	mv	a1,s4
    80003d48:	fc240513          	addi	a0,s0,-62
    80003d4c:	ffffd097          	auipc	ra,0xffffd
    80003d50:	086080e7          	jalr	134(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003d54:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d58:	4741                	li	a4,16
    80003d5a:	86a6                	mv	a3,s1
    80003d5c:	fc040613          	addi	a2,s0,-64
    80003d60:	4581                	li	a1,0
    80003d62:	854a                	mv	a0,s2
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	c44080e7          	jalr	-956(ra) # 800039a8 <writei>
    80003d6c:	872a                	mv	a4,a0
    80003d6e:	47c1                	li	a5,16
  return 0;
    80003d70:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d72:	02f71863          	bne	a4,a5,80003da2 <dirlink+0xb2>
}
    80003d76:	70e2                	ld	ra,56(sp)
    80003d78:	7442                	ld	s0,48(sp)
    80003d7a:	74a2                	ld	s1,40(sp)
    80003d7c:	7902                	ld	s2,32(sp)
    80003d7e:	69e2                	ld	s3,24(sp)
    80003d80:	6a42                	ld	s4,16(sp)
    80003d82:	6121                	addi	sp,sp,64
    80003d84:	8082                	ret
    iput(ip);
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	a30080e7          	jalr	-1488(ra) # 800037b6 <iput>
    return -1;
    80003d8e:	557d                	li	a0,-1
    80003d90:	b7dd                	j	80003d76 <dirlink+0x86>
      panic("dirlink read");
    80003d92:	00005517          	auipc	a0,0x5
    80003d96:	86650513          	addi	a0,a0,-1946 # 800085f8 <syscalls+0x1c8>
    80003d9a:	ffffc097          	auipc	ra,0xffffc
    80003d9e:	790080e7          	jalr	1936(ra) # 8000052a <panic>
    panic("dirlink");
    80003da2:	00005517          	auipc	a0,0x5
    80003da6:	96650513          	addi	a0,a0,-1690 # 80008708 <syscalls+0x2d8>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	780080e7          	jalr	1920(ra) # 8000052a <panic>

0000000080003db2 <namei>:

struct inode*
namei(char *path)
{
    80003db2:	1101                	addi	sp,sp,-32
    80003db4:	ec06                	sd	ra,24(sp)
    80003db6:	e822                	sd	s0,16(sp)
    80003db8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dba:	fe040613          	addi	a2,s0,-32
    80003dbe:	4581                	li	a1,0
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	dd0080e7          	jalr	-560(ra) # 80003b90 <namex>
}
    80003dc8:	60e2                	ld	ra,24(sp)
    80003dca:	6442                	ld	s0,16(sp)
    80003dcc:	6105                	addi	sp,sp,32
    80003dce:	8082                	ret

0000000080003dd0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dd0:	1141                	addi	sp,sp,-16
    80003dd2:	e406                	sd	ra,8(sp)
    80003dd4:	e022                	sd	s0,0(sp)
    80003dd6:	0800                	addi	s0,sp,16
    80003dd8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dda:	4585                	li	a1,1
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	db4080e7          	jalr	-588(ra) # 80003b90 <namex>
}
    80003de4:	60a2                	ld	ra,8(sp)
    80003de6:	6402                	ld	s0,0(sp)
    80003de8:	0141                	addi	sp,sp,16
    80003dea:	8082                	ret

0000000080003dec <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dec:	1101                	addi	sp,sp,-32
    80003dee:	ec06                	sd	ra,24(sp)
    80003df0:	e822                	sd	s0,16(sp)
    80003df2:	e426                	sd	s1,8(sp)
    80003df4:	e04a                	sd	s2,0(sp)
    80003df6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003df8:	0001d917          	auipc	s2,0x1d
    80003dfc:	47890913          	addi	s2,s2,1144 # 80021270 <log>
    80003e00:	01892583          	lw	a1,24(s2)
    80003e04:	02892503          	lw	a0,40(s2)
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	ff0080e7          	jalr	-16(ra) # 80002df8 <bread>
    80003e10:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e12:	02c92683          	lw	a3,44(s2)
    80003e16:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e18:	02d05863          	blez	a3,80003e48 <write_head+0x5c>
    80003e1c:	0001d797          	auipc	a5,0x1d
    80003e20:	48478793          	addi	a5,a5,1156 # 800212a0 <log+0x30>
    80003e24:	05c50713          	addi	a4,a0,92
    80003e28:	36fd                	addiw	a3,a3,-1
    80003e2a:	02069613          	slli	a2,a3,0x20
    80003e2e:	01e65693          	srli	a3,a2,0x1e
    80003e32:	0001d617          	auipc	a2,0x1d
    80003e36:	47260613          	addi	a2,a2,1138 # 800212a4 <log+0x34>
    80003e3a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e3c:	4390                	lw	a2,0(a5)
    80003e3e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e40:	0791                	addi	a5,a5,4
    80003e42:	0711                	addi	a4,a4,4
    80003e44:	fed79ce3          	bne	a5,a3,80003e3c <write_head+0x50>
  }
  bwrite(buf);
    80003e48:	8526                	mv	a0,s1
    80003e4a:	fffff097          	auipc	ra,0xfffff
    80003e4e:	0a0080e7          	jalr	160(ra) # 80002eea <bwrite>
  brelse(buf);
    80003e52:	8526                	mv	a0,s1
    80003e54:	fffff097          	auipc	ra,0xfffff
    80003e58:	0d4080e7          	jalr	212(ra) # 80002f28 <brelse>
}
    80003e5c:	60e2                	ld	ra,24(sp)
    80003e5e:	6442                	ld	s0,16(sp)
    80003e60:	64a2                	ld	s1,8(sp)
    80003e62:	6902                	ld	s2,0(sp)
    80003e64:	6105                	addi	sp,sp,32
    80003e66:	8082                	ret

0000000080003e68 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e68:	0001d797          	auipc	a5,0x1d
    80003e6c:	4347a783          	lw	a5,1076(a5) # 8002129c <log+0x2c>
    80003e70:	0af05d63          	blez	a5,80003f2a <install_trans+0xc2>
{
    80003e74:	7139                	addi	sp,sp,-64
    80003e76:	fc06                	sd	ra,56(sp)
    80003e78:	f822                	sd	s0,48(sp)
    80003e7a:	f426                	sd	s1,40(sp)
    80003e7c:	f04a                	sd	s2,32(sp)
    80003e7e:	ec4e                	sd	s3,24(sp)
    80003e80:	e852                	sd	s4,16(sp)
    80003e82:	e456                	sd	s5,8(sp)
    80003e84:	e05a                	sd	s6,0(sp)
    80003e86:	0080                	addi	s0,sp,64
    80003e88:	8b2a                	mv	s6,a0
    80003e8a:	0001da97          	auipc	s5,0x1d
    80003e8e:	416a8a93          	addi	s5,s5,1046 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e92:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e94:	0001d997          	auipc	s3,0x1d
    80003e98:	3dc98993          	addi	s3,s3,988 # 80021270 <log>
    80003e9c:	a00d                	j	80003ebe <install_trans+0x56>
    brelse(lbuf);
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	088080e7          	jalr	136(ra) # 80002f28 <brelse>
    brelse(dbuf);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	07e080e7          	jalr	126(ra) # 80002f28 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb2:	2a05                	addiw	s4,s4,1
    80003eb4:	0a91                	addi	s5,s5,4
    80003eb6:	02c9a783          	lw	a5,44(s3)
    80003eba:	04fa5e63          	bge	s4,a5,80003f16 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ebe:	0189a583          	lw	a1,24(s3)
    80003ec2:	014585bb          	addw	a1,a1,s4
    80003ec6:	2585                	addiw	a1,a1,1
    80003ec8:	0289a503          	lw	a0,40(s3)
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	f2c080e7          	jalr	-212(ra) # 80002df8 <bread>
    80003ed4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ed6:	000aa583          	lw	a1,0(s5)
    80003eda:	0289a503          	lw	a0,40(s3)
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	f1a080e7          	jalr	-230(ra) # 80002df8 <bread>
    80003ee6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ee8:	40000613          	li	a2,1024
    80003eec:	05890593          	addi	a1,s2,88
    80003ef0:	05850513          	addi	a0,a0,88
    80003ef4:	ffffd097          	auipc	ra,0xffffd
    80003ef8:	e26080e7          	jalr	-474(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003efc:	8526                	mv	a0,s1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	fec080e7          	jalr	-20(ra) # 80002eea <bwrite>
    if(recovering == 0)
    80003f06:	f80b1ce3          	bnez	s6,80003e9e <install_trans+0x36>
      bunpin(dbuf);
    80003f0a:	8526                	mv	a0,s1
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	0f6080e7          	jalr	246(ra) # 80003002 <bunpin>
    80003f14:	b769                	j	80003e9e <install_trans+0x36>
}
    80003f16:	70e2                	ld	ra,56(sp)
    80003f18:	7442                	ld	s0,48(sp)
    80003f1a:	74a2                	ld	s1,40(sp)
    80003f1c:	7902                	ld	s2,32(sp)
    80003f1e:	69e2                	ld	s3,24(sp)
    80003f20:	6a42                	ld	s4,16(sp)
    80003f22:	6aa2                	ld	s5,8(sp)
    80003f24:	6b02                	ld	s6,0(sp)
    80003f26:	6121                	addi	sp,sp,64
    80003f28:	8082                	ret
    80003f2a:	8082                	ret

0000000080003f2c <initlog>:
{
    80003f2c:	7179                	addi	sp,sp,-48
    80003f2e:	f406                	sd	ra,40(sp)
    80003f30:	f022                	sd	s0,32(sp)
    80003f32:	ec26                	sd	s1,24(sp)
    80003f34:	e84a                	sd	s2,16(sp)
    80003f36:	e44e                	sd	s3,8(sp)
    80003f38:	1800                	addi	s0,sp,48
    80003f3a:	892a                	mv	s2,a0
    80003f3c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f3e:	0001d497          	auipc	s1,0x1d
    80003f42:	33248493          	addi	s1,s1,818 # 80021270 <log>
    80003f46:	00004597          	auipc	a1,0x4
    80003f4a:	6c258593          	addi	a1,a1,1730 # 80008608 <syscalls+0x1d8>
    80003f4e:	8526                	mv	a0,s1
    80003f50:	ffffd097          	auipc	ra,0xffffd
    80003f54:	be2080e7          	jalr	-1054(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80003f58:	0149a583          	lw	a1,20(s3)
    80003f5c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f5e:	0109a783          	lw	a5,16(s3)
    80003f62:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f64:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f68:	854a                	mv	a0,s2
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	e8e080e7          	jalr	-370(ra) # 80002df8 <bread>
  log.lh.n = lh->n;
    80003f72:	4d34                	lw	a3,88(a0)
    80003f74:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f76:	02d05663          	blez	a3,80003fa2 <initlog+0x76>
    80003f7a:	05c50793          	addi	a5,a0,92
    80003f7e:	0001d717          	auipc	a4,0x1d
    80003f82:	32270713          	addi	a4,a4,802 # 800212a0 <log+0x30>
    80003f86:	36fd                	addiw	a3,a3,-1
    80003f88:	02069613          	slli	a2,a3,0x20
    80003f8c:	01e65693          	srli	a3,a2,0x1e
    80003f90:	06050613          	addi	a2,a0,96
    80003f94:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003f96:	4390                	lw	a2,0(a5)
    80003f98:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f9a:	0791                	addi	a5,a5,4
    80003f9c:	0711                	addi	a4,a4,4
    80003f9e:	fed79ce3          	bne	a5,a3,80003f96 <initlog+0x6a>
  brelse(buf);
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	f86080e7          	jalr	-122(ra) # 80002f28 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003faa:	4505                	li	a0,1
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	ebc080e7          	jalr	-324(ra) # 80003e68 <install_trans>
  log.lh.n = 0;
    80003fb4:	0001d797          	auipc	a5,0x1d
    80003fb8:	2e07a423          	sw	zero,744(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	e30080e7          	jalr	-464(ra) # 80003dec <write_head>
}
    80003fc4:	70a2                	ld	ra,40(sp)
    80003fc6:	7402                	ld	s0,32(sp)
    80003fc8:	64e2                	ld	s1,24(sp)
    80003fca:	6942                	ld	s2,16(sp)
    80003fcc:	69a2                	ld	s3,8(sp)
    80003fce:	6145                	addi	sp,sp,48
    80003fd0:	8082                	ret

0000000080003fd2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fd2:	1101                	addi	sp,sp,-32
    80003fd4:	ec06                	sd	ra,24(sp)
    80003fd6:	e822                	sd	s0,16(sp)
    80003fd8:	e426                	sd	s1,8(sp)
    80003fda:	e04a                	sd	s2,0(sp)
    80003fdc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fde:	0001d517          	auipc	a0,0x1d
    80003fe2:	29250513          	addi	a0,a0,658 # 80021270 <log>
    80003fe6:	ffffd097          	auipc	ra,0xffffd
    80003fea:	bdc080e7          	jalr	-1060(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80003fee:	0001d497          	auipc	s1,0x1d
    80003ff2:	28248493          	addi	s1,s1,642 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ff6:	4979                	li	s2,30
    80003ff8:	a039                	j	80004006 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003ffa:	85a6                	mv	a1,s1
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	ffffe097          	auipc	ra,0xffffe
    80004002:	032080e7          	jalr	50(ra) # 80002030 <sleep>
    if(log.committing){
    80004006:	50dc                	lw	a5,36(s1)
    80004008:	fbed                	bnez	a5,80003ffa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000400a:	509c                	lw	a5,32(s1)
    8000400c:	0017871b          	addiw	a4,a5,1
    80004010:	0007069b          	sext.w	a3,a4
    80004014:	0027179b          	slliw	a5,a4,0x2
    80004018:	9fb9                	addw	a5,a5,a4
    8000401a:	0017979b          	slliw	a5,a5,0x1
    8000401e:	54d8                	lw	a4,44(s1)
    80004020:	9fb9                	addw	a5,a5,a4
    80004022:	00f95963          	bge	s2,a5,80004034 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004026:	85a6                	mv	a1,s1
    80004028:	8526                	mv	a0,s1
    8000402a:	ffffe097          	auipc	ra,0xffffe
    8000402e:	006080e7          	jalr	6(ra) # 80002030 <sleep>
    80004032:	bfd1                	j	80004006 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004034:	0001d517          	auipc	a0,0x1d
    80004038:	23c50513          	addi	a0,a0,572 # 80021270 <log>
    8000403c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	c38080e7          	jalr	-968(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	64a2                	ld	s1,8(sp)
    8000404c:	6902                	ld	s2,0(sp)
    8000404e:	6105                	addi	sp,sp,32
    80004050:	8082                	ret

0000000080004052 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004052:	7139                	addi	sp,sp,-64
    80004054:	fc06                	sd	ra,56(sp)
    80004056:	f822                	sd	s0,48(sp)
    80004058:	f426                	sd	s1,40(sp)
    8000405a:	f04a                	sd	s2,32(sp)
    8000405c:	ec4e                	sd	s3,24(sp)
    8000405e:	e852                	sd	s4,16(sp)
    80004060:	e456                	sd	s5,8(sp)
    80004062:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004064:	0001d497          	auipc	s1,0x1d
    80004068:	20c48493          	addi	s1,s1,524 # 80021270 <log>
    8000406c:	8526                	mv	a0,s1
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	b54080e7          	jalr	-1196(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004076:	509c                	lw	a5,32(s1)
    80004078:	37fd                	addiw	a5,a5,-1
    8000407a:	0007891b          	sext.w	s2,a5
    8000407e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004080:	50dc                	lw	a5,36(s1)
    80004082:	e7b9                	bnez	a5,800040d0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004084:	04091e63          	bnez	s2,800040e0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	1e848493          	addi	s1,s1,488 # 80021270 <log>
    80004090:	4785                	li	a5,1
    80004092:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004094:	8526                	mv	a0,s1
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	be0080e7          	jalr	-1056(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000409e:	54dc                	lw	a5,44(s1)
    800040a0:	06f04763          	bgtz	a5,8000410e <end_op+0xbc>
    acquire(&log.lock);
    800040a4:	0001d497          	auipc	s1,0x1d
    800040a8:	1cc48493          	addi	s1,s1,460 # 80021270 <log>
    800040ac:	8526                	mv	a0,s1
    800040ae:	ffffd097          	auipc	ra,0xffffd
    800040b2:	b14080e7          	jalr	-1260(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800040b6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040ba:	8526                	mv	a0,s1
    800040bc:	ffffe097          	auipc	ra,0xffffe
    800040c0:	100080e7          	jalr	256(ra) # 800021bc <wakeup>
    release(&log.lock);
    800040c4:	8526                	mv	a0,s1
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	bb0080e7          	jalr	-1104(ra) # 80000c76 <release>
}
    800040ce:	a03d                	j	800040fc <end_op+0xaa>
    panic("log.committing");
    800040d0:	00004517          	auipc	a0,0x4
    800040d4:	54050513          	addi	a0,a0,1344 # 80008610 <syscalls+0x1e0>
    800040d8:	ffffc097          	auipc	ra,0xffffc
    800040dc:	452080e7          	jalr	1106(ra) # 8000052a <panic>
    wakeup(&log);
    800040e0:	0001d497          	auipc	s1,0x1d
    800040e4:	19048493          	addi	s1,s1,400 # 80021270 <log>
    800040e8:	8526                	mv	a0,s1
    800040ea:	ffffe097          	auipc	ra,0xffffe
    800040ee:	0d2080e7          	jalr	210(ra) # 800021bc <wakeup>
  release(&log.lock);
    800040f2:	8526                	mv	a0,s1
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	b82080e7          	jalr	-1150(ra) # 80000c76 <release>
}
    800040fc:	70e2                	ld	ra,56(sp)
    800040fe:	7442                	ld	s0,48(sp)
    80004100:	74a2                	ld	s1,40(sp)
    80004102:	7902                	ld	s2,32(sp)
    80004104:	69e2                	ld	s3,24(sp)
    80004106:	6a42                	ld	s4,16(sp)
    80004108:	6aa2                	ld	s5,8(sp)
    8000410a:	6121                	addi	sp,sp,64
    8000410c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410e:	0001da97          	auipc	s5,0x1d
    80004112:	192a8a93          	addi	s5,s5,402 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004116:	0001da17          	auipc	s4,0x1d
    8000411a:	15aa0a13          	addi	s4,s4,346 # 80021270 <log>
    8000411e:	018a2583          	lw	a1,24(s4)
    80004122:	012585bb          	addw	a1,a1,s2
    80004126:	2585                	addiw	a1,a1,1
    80004128:	028a2503          	lw	a0,40(s4)
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	ccc080e7          	jalr	-820(ra) # 80002df8 <bread>
    80004134:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004136:	000aa583          	lw	a1,0(s5)
    8000413a:	028a2503          	lw	a0,40(s4)
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	cba080e7          	jalr	-838(ra) # 80002df8 <bread>
    80004146:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004148:	40000613          	li	a2,1024
    8000414c:	05850593          	addi	a1,a0,88
    80004150:	05848513          	addi	a0,s1,88
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	bc6080e7          	jalr	-1082(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000415c:	8526                	mv	a0,s1
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	d8c080e7          	jalr	-628(ra) # 80002eea <bwrite>
    brelse(from);
    80004166:	854e                	mv	a0,s3
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	dc0080e7          	jalr	-576(ra) # 80002f28 <brelse>
    brelse(to);
    80004170:	8526                	mv	a0,s1
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	db6080e7          	jalr	-586(ra) # 80002f28 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000417a:	2905                	addiw	s2,s2,1
    8000417c:	0a91                	addi	s5,s5,4
    8000417e:	02ca2783          	lw	a5,44(s4)
    80004182:	f8f94ee3          	blt	s2,a5,8000411e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	c66080e7          	jalr	-922(ra) # 80003dec <write_head>
    install_trans(0); // Now install writes to home locations
    8000418e:	4501                	li	a0,0
    80004190:	00000097          	auipc	ra,0x0
    80004194:	cd8080e7          	jalr	-808(ra) # 80003e68 <install_trans>
    log.lh.n = 0;
    80004198:	0001d797          	auipc	a5,0x1d
    8000419c:	1007a223          	sw	zero,260(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	c4c080e7          	jalr	-948(ra) # 80003dec <write_head>
    800041a8:	bdf5                	j	800040a4 <end_op+0x52>

00000000800041aa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041aa:	1101                	addi	sp,sp,-32
    800041ac:	ec06                	sd	ra,24(sp)
    800041ae:	e822                	sd	s0,16(sp)
    800041b0:	e426                	sd	s1,8(sp)
    800041b2:	e04a                	sd	s2,0(sp)
    800041b4:	1000                	addi	s0,sp,32
    800041b6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041b8:	0001d917          	auipc	s2,0x1d
    800041bc:	0b890913          	addi	s2,s2,184 # 80021270 <log>
    800041c0:	854a                	mv	a0,s2
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	a00080e7          	jalr	-1536(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041ca:	02c92603          	lw	a2,44(s2)
    800041ce:	47f5                	li	a5,29
    800041d0:	06c7c563          	blt	a5,a2,8000423a <log_write+0x90>
    800041d4:	0001d797          	auipc	a5,0x1d
    800041d8:	0b87a783          	lw	a5,184(a5) # 8002128c <log+0x1c>
    800041dc:	37fd                	addiw	a5,a5,-1
    800041de:	04f65e63          	bge	a2,a5,8000423a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041e2:	0001d797          	auipc	a5,0x1d
    800041e6:	0ae7a783          	lw	a5,174(a5) # 80021290 <log+0x20>
    800041ea:	06f05063          	blez	a5,8000424a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041ee:	4781                	li	a5,0
    800041f0:	06c05563          	blez	a2,8000425a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041f4:	44cc                	lw	a1,12(s1)
    800041f6:	0001d717          	auipc	a4,0x1d
    800041fa:	0aa70713          	addi	a4,a4,170 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041fe:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004200:	4314                	lw	a3,0(a4)
    80004202:	04b68c63          	beq	a3,a1,8000425a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004206:	2785                	addiw	a5,a5,1
    80004208:	0711                	addi	a4,a4,4
    8000420a:	fef61be3          	bne	a2,a5,80004200 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000420e:	0621                	addi	a2,a2,8
    80004210:	060a                	slli	a2,a2,0x2
    80004212:	0001d797          	auipc	a5,0x1d
    80004216:	05e78793          	addi	a5,a5,94 # 80021270 <log>
    8000421a:	963e                	add	a2,a2,a5
    8000421c:	44dc                	lw	a5,12(s1)
    8000421e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004220:	8526                	mv	a0,s1
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	da4080e7          	jalr	-604(ra) # 80002fc6 <bpin>
    log.lh.n++;
    8000422a:	0001d717          	auipc	a4,0x1d
    8000422e:	04670713          	addi	a4,a4,70 # 80021270 <log>
    80004232:	575c                	lw	a5,44(a4)
    80004234:	2785                	addiw	a5,a5,1
    80004236:	d75c                	sw	a5,44(a4)
    80004238:	a835                	j	80004274 <log_write+0xca>
    panic("too big a transaction");
    8000423a:	00004517          	auipc	a0,0x4
    8000423e:	3e650513          	addi	a0,a0,998 # 80008620 <syscalls+0x1f0>
    80004242:	ffffc097          	auipc	ra,0xffffc
    80004246:	2e8080e7          	jalr	744(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000424a:	00004517          	auipc	a0,0x4
    8000424e:	3ee50513          	addi	a0,a0,1006 # 80008638 <syscalls+0x208>
    80004252:	ffffc097          	auipc	ra,0xffffc
    80004256:	2d8080e7          	jalr	728(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000425a:	00878713          	addi	a4,a5,8
    8000425e:	00271693          	slli	a3,a4,0x2
    80004262:	0001d717          	auipc	a4,0x1d
    80004266:	00e70713          	addi	a4,a4,14 # 80021270 <log>
    8000426a:	9736                	add	a4,a4,a3
    8000426c:	44d4                	lw	a3,12(s1)
    8000426e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004270:	faf608e3          	beq	a2,a5,80004220 <log_write+0x76>
  }
  release(&log.lock);
    80004274:	0001d517          	auipc	a0,0x1d
    80004278:	ffc50513          	addi	a0,a0,-4 # 80021270 <log>
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	9fa080e7          	jalr	-1542(ra) # 80000c76 <release>
}
    80004284:	60e2                	ld	ra,24(sp)
    80004286:	6442                	ld	s0,16(sp)
    80004288:	64a2                	ld	s1,8(sp)
    8000428a:	6902                	ld	s2,0(sp)
    8000428c:	6105                	addi	sp,sp,32
    8000428e:	8082                	ret

0000000080004290 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004290:	1101                	addi	sp,sp,-32
    80004292:	ec06                	sd	ra,24(sp)
    80004294:	e822                	sd	s0,16(sp)
    80004296:	e426                	sd	s1,8(sp)
    80004298:	e04a                	sd	s2,0(sp)
    8000429a:	1000                	addi	s0,sp,32
    8000429c:	84aa                	mv	s1,a0
    8000429e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042a0:	00004597          	auipc	a1,0x4
    800042a4:	3b858593          	addi	a1,a1,952 # 80008658 <syscalls+0x228>
    800042a8:	0521                	addi	a0,a0,8
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	888080e7          	jalr	-1912(ra) # 80000b32 <initlock>
  lk->name = name;
    800042b2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042ba:	0204a423          	sw	zero,40(s1)
}
    800042be:	60e2                	ld	ra,24(sp)
    800042c0:	6442                	ld	s0,16(sp)
    800042c2:	64a2                	ld	s1,8(sp)
    800042c4:	6902                	ld	s2,0(sp)
    800042c6:	6105                	addi	sp,sp,32
    800042c8:	8082                	ret

00000000800042ca <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042ca:	1101                	addi	sp,sp,-32
    800042cc:	ec06                	sd	ra,24(sp)
    800042ce:	e822                	sd	s0,16(sp)
    800042d0:	e426                	sd	s1,8(sp)
    800042d2:	e04a                	sd	s2,0(sp)
    800042d4:	1000                	addi	s0,sp,32
    800042d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042d8:	00850913          	addi	s2,a0,8
    800042dc:	854a                	mv	a0,s2
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	8e4080e7          	jalr	-1820(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800042e6:	409c                	lw	a5,0(s1)
    800042e8:	cb89                	beqz	a5,800042fa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042ea:	85ca                	mv	a1,s2
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffe097          	auipc	ra,0xffffe
    800042f2:	d42080e7          	jalr	-702(ra) # 80002030 <sleep>
  while (lk->locked) {
    800042f6:	409c                	lw	a5,0(s1)
    800042f8:	fbed                	bnez	a5,800042ea <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042fa:	4785                	li	a5,1
    800042fc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	672080e7          	jalr	1650(ra) # 80001970 <myproc>
    80004306:	591c                	lw	a5,48(a0)
    80004308:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000430a:	854a                	mv	a0,s2
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	96a080e7          	jalr	-1686(ra) # 80000c76 <release>
}
    80004314:	60e2                	ld	ra,24(sp)
    80004316:	6442                	ld	s0,16(sp)
    80004318:	64a2                	ld	s1,8(sp)
    8000431a:	6902                	ld	s2,0(sp)
    8000431c:	6105                	addi	sp,sp,32
    8000431e:	8082                	ret

0000000080004320 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004320:	1101                	addi	sp,sp,-32
    80004322:	ec06                	sd	ra,24(sp)
    80004324:	e822                	sd	s0,16(sp)
    80004326:	e426                	sd	s1,8(sp)
    80004328:	e04a                	sd	s2,0(sp)
    8000432a:	1000                	addi	s0,sp,32
    8000432c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000432e:	00850913          	addi	s2,a0,8
    80004332:	854a                	mv	a0,s2
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	88e080e7          	jalr	-1906(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000433c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004340:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004344:	8526                	mv	a0,s1
    80004346:	ffffe097          	auipc	ra,0xffffe
    8000434a:	e76080e7          	jalr	-394(ra) # 800021bc <wakeup>
  release(&lk->lk);
    8000434e:	854a                	mv	a0,s2
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	926080e7          	jalr	-1754(ra) # 80000c76 <release>
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004364:	7179                	addi	sp,sp,-48
    80004366:	f406                	sd	ra,40(sp)
    80004368:	f022                	sd	s0,32(sp)
    8000436a:	ec26                	sd	s1,24(sp)
    8000436c:	e84a                	sd	s2,16(sp)
    8000436e:	e44e                	sd	s3,8(sp)
    80004370:	1800                	addi	s0,sp,48
    80004372:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004374:	00850913          	addi	s2,a0,8
    80004378:	854a                	mv	a0,s2
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	848080e7          	jalr	-1976(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004382:	409c                	lw	a5,0(s1)
    80004384:	ef99                	bnez	a5,800043a2 <holdingsleep+0x3e>
    80004386:	4481                	li	s1,0
  release(&lk->lk);
    80004388:	854a                	mv	a0,s2
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	8ec080e7          	jalr	-1812(ra) # 80000c76 <release>
  return r;
}
    80004392:	8526                	mv	a0,s1
    80004394:	70a2                	ld	ra,40(sp)
    80004396:	7402                	ld	s0,32(sp)
    80004398:	64e2                	ld	s1,24(sp)
    8000439a:	6942                	ld	s2,16(sp)
    8000439c:	69a2                	ld	s3,8(sp)
    8000439e:	6145                	addi	sp,sp,48
    800043a0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043a2:	0284a983          	lw	s3,40(s1)
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	5ca080e7          	jalr	1482(ra) # 80001970 <myproc>
    800043ae:	5904                	lw	s1,48(a0)
    800043b0:	413484b3          	sub	s1,s1,s3
    800043b4:	0014b493          	seqz	s1,s1
    800043b8:	bfc1                	j	80004388 <holdingsleep+0x24>

00000000800043ba <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043ba:	1141                	addi	sp,sp,-16
    800043bc:	e406                	sd	ra,8(sp)
    800043be:	e022                	sd	s0,0(sp)
    800043c0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043c2:	00004597          	auipc	a1,0x4
    800043c6:	2a658593          	addi	a1,a1,678 # 80008668 <syscalls+0x238>
    800043ca:	0001d517          	auipc	a0,0x1d
    800043ce:	fee50513          	addi	a0,a0,-18 # 800213b8 <ftable>
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	760080e7          	jalr	1888(ra) # 80000b32 <initlock>
}
    800043da:	60a2                	ld	ra,8(sp)
    800043dc:	6402                	ld	s0,0(sp)
    800043de:	0141                	addi	sp,sp,16
    800043e0:	8082                	ret

00000000800043e2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	e426                	sd	s1,8(sp)
    800043ea:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043ec:	0001d517          	auipc	a0,0x1d
    800043f0:	fcc50513          	addi	a0,a0,-52 # 800213b8 <ftable>
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	7ce080e7          	jalr	1998(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043fc:	0001d497          	auipc	s1,0x1d
    80004400:	fd448493          	addi	s1,s1,-44 # 800213d0 <ftable+0x18>
    80004404:	0001e717          	auipc	a4,0x1e
    80004408:	f6c70713          	addi	a4,a4,-148 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000440c:	40dc                	lw	a5,4(s1)
    8000440e:	cf99                	beqz	a5,8000442c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004410:	02848493          	addi	s1,s1,40
    80004414:	fee49ce3          	bne	s1,a4,8000440c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004418:	0001d517          	auipc	a0,0x1d
    8000441c:	fa050513          	addi	a0,a0,-96 # 800213b8 <ftable>
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	856080e7          	jalr	-1962(ra) # 80000c76 <release>
  return 0;
    80004428:	4481                	li	s1,0
    8000442a:	a819                	j	80004440 <filealloc+0x5e>
      f->ref = 1;
    8000442c:	4785                	li	a5,1
    8000442e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004430:	0001d517          	auipc	a0,0x1d
    80004434:	f8850513          	addi	a0,a0,-120 # 800213b8 <ftable>
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	83e080e7          	jalr	-1986(ra) # 80000c76 <release>
}
    80004440:	8526                	mv	a0,s1
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6105                	addi	sp,sp,32
    8000444a:	8082                	ret

000000008000444c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	1000                	addi	s0,sp,32
    80004456:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004458:	0001d517          	auipc	a0,0x1d
    8000445c:	f6050513          	addi	a0,a0,-160 # 800213b8 <ftable>
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	762080e7          	jalr	1890(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004468:	40dc                	lw	a5,4(s1)
    8000446a:	02f05263          	blez	a5,8000448e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000446e:	2785                	addiw	a5,a5,1
    80004470:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004472:	0001d517          	auipc	a0,0x1d
    80004476:	f4650513          	addi	a0,a0,-186 # 800213b8 <ftable>
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	7fc080e7          	jalr	2044(ra) # 80000c76 <release>
  return f;
}
    80004482:	8526                	mv	a0,s1
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret
    panic("filedup");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	1e250513          	addi	a0,a0,482 # 80008670 <syscalls+0x240>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	094080e7          	jalr	148(ra) # 8000052a <panic>

000000008000449e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000449e:	7139                	addi	sp,sp,-64
    800044a0:	fc06                	sd	ra,56(sp)
    800044a2:	f822                	sd	s0,48(sp)
    800044a4:	f426                	sd	s1,40(sp)
    800044a6:	f04a                	sd	s2,32(sp)
    800044a8:	ec4e                	sd	s3,24(sp)
    800044aa:	e852                	sd	s4,16(sp)
    800044ac:	e456                	sd	s5,8(sp)
    800044ae:	0080                	addi	s0,sp,64
    800044b0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	f0650513          	addi	a0,a0,-250 # 800213b8 <ftable>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	708080e7          	jalr	1800(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800044c2:	40dc                	lw	a5,4(s1)
    800044c4:	06f05163          	blez	a5,80004526 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044c8:	37fd                	addiw	a5,a5,-1
    800044ca:	0007871b          	sext.w	a4,a5
    800044ce:	c0dc                	sw	a5,4(s1)
    800044d0:	06e04363          	bgtz	a4,80004536 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044d4:	0004a903          	lw	s2,0(s1)
    800044d8:	0094ca83          	lbu	s5,9(s1)
    800044dc:	0104ba03          	ld	s4,16(s1)
    800044e0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044e4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044e8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044ec:	0001d517          	auipc	a0,0x1d
    800044f0:	ecc50513          	addi	a0,a0,-308 # 800213b8 <ftable>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	782080e7          	jalr	1922(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800044fc:	4785                	li	a5,1
    800044fe:	04f90d63          	beq	s2,a5,80004558 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004502:	3979                	addiw	s2,s2,-2
    80004504:	4785                	li	a5,1
    80004506:	0527e063          	bltu	a5,s2,80004546 <fileclose+0xa8>
    begin_op();
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	ac8080e7          	jalr	-1336(ra) # 80003fd2 <begin_op>
    iput(ff.ip);
    80004512:	854e                	mv	a0,s3
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	2a2080e7          	jalr	674(ra) # 800037b6 <iput>
    end_op();
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	b36080e7          	jalr	-1226(ra) # 80004052 <end_op>
    80004524:	a00d                	j	80004546 <fileclose+0xa8>
    panic("fileclose");
    80004526:	00004517          	auipc	a0,0x4
    8000452a:	15250513          	addi	a0,a0,338 # 80008678 <syscalls+0x248>
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	ffc080e7          	jalr	-4(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004536:	0001d517          	auipc	a0,0x1d
    8000453a:	e8250513          	addi	a0,a0,-382 # 800213b8 <ftable>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	738080e7          	jalr	1848(ra) # 80000c76 <release>
  }
}
    80004546:	70e2                	ld	ra,56(sp)
    80004548:	7442                	ld	s0,48(sp)
    8000454a:	74a2                	ld	s1,40(sp)
    8000454c:	7902                	ld	s2,32(sp)
    8000454e:	69e2                	ld	s3,24(sp)
    80004550:	6a42                	ld	s4,16(sp)
    80004552:	6aa2                	ld	s5,8(sp)
    80004554:	6121                	addi	sp,sp,64
    80004556:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004558:	85d6                	mv	a1,s5
    8000455a:	8552                	mv	a0,s4
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	34c080e7          	jalr	844(ra) # 800048a8 <pipeclose>
    80004564:	b7cd                	j	80004546 <fileclose+0xa8>

0000000080004566 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004566:	715d                	addi	sp,sp,-80
    80004568:	e486                	sd	ra,72(sp)
    8000456a:	e0a2                	sd	s0,64(sp)
    8000456c:	fc26                	sd	s1,56(sp)
    8000456e:	f84a                	sd	s2,48(sp)
    80004570:	f44e                	sd	s3,40(sp)
    80004572:	0880                	addi	s0,sp,80
    80004574:	84aa                	mv	s1,a0
    80004576:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004578:	ffffd097          	auipc	ra,0xffffd
    8000457c:	3f8080e7          	jalr	1016(ra) # 80001970 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004580:	409c                	lw	a5,0(s1)
    80004582:	37f9                	addiw	a5,a5,-2
    80004584:	4705                	li	a4,1
    80004586:	04f76763          	bltu	a4,a5,800045d4 <filestat+0x6e>
    8000458a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000458c:	6c88                	ld	a0,24(s1)
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	06e080e7          	jalr	110(ra) # 800035fc <ilock>
    stati(f->ip, &st);
    80004596:	fb840593          	addi	a1,s0,-72
    8000459a:	6c88                	ld	a0,24(s1)
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	2ea080e7          	jalr	746(ra) # 80003886 <stati>
    iunlock(f->ip);
    800045a4:	6c88                	ld	a0,24(s1)
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	118080e7          	jalr	280(ra) # 800036be <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045ae:	46e1                	li	a3,24
    800045b0:	fb840613          	addi	a2,s0,-72
    800045b4:	85ce                	mv	a1,s3
    800045b6:	05093503          	ld	a0,80(s2)
    800045ba:	ffffd097          	auipc	ra,0xffffd
    800045be:	076080e7          	jalr	118(ra) # 80001630 <copyout>
    800045c2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045c6:	60a6                	ld	ra,72(sp)
    800045c8:	6406                	ld	s0,64(sp)
    800045ca:	74e2                	ld	s1,56(sp)
    800045cc:	7942                	ld	s2,48(sp)
    800045ce:	79a2                	ld	s3,40(sp)
    800045d0:	6161                	addi	sp,sp,80
    800045d2:	8082                	ret
  return -1;
    800045d4:	557d                	li	a0,-1
    800045d6:	bfc5                	j	800045c6 <filestat+0x60>

00000000800045d8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045d8:	7179                	addi	sp,sp,-48
    800045da:	f406                	sd	ra,40(sp)
    800045dc:	f022                	sd	s0,32(sp)
    800045de:	ec26                	sd	s1,24(sp)
    800045e0:	e84a                	sd	s2,16(sp)
    800045e2:	e44e                	sd	s3,8(sp)
    800045e4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045e6:	00854783          	lbu	a5,8(a0)
    800045ea:	c3d5                	beqz	a5,8000468e <fileread+0xb6>
    800045ec:	84aa                	mv	s1,a0
    800045ee:	89ae                	mv	s3,a1
    800045f0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045f2:	411c                	lw	a5,0(a0)
    800045f4:	4705                	li	a4,1
    800045f6:	04e78963          	beq	a5,a4,80004648 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045fa:	470d                	li	a4,3
    800045fc:	04e78d63          	beq	a5,a4,80004656 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004600:	4709                	li	a4,2
    80004602:	06e79e63          	bne	a5,a4,8000467e <fileread+0xa6>
    ilock(f->ip);
    80004606:	6d08                	ld	a0,24(a0)
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	ff4080e7          	jalr	-12(ra) # 800035fc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004610:	874a                	mv	a4,s2
    80004612:	5094                	lw	a3,32(s1)
    80004614:	864e                	mv	a2,s3
    80004616:	4585                	li	a1,1
    80004618:	6c88                	ld	a0,24(s1)
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	296080e7          	jalr	662(ra) # 800038b0 <readi>
    80004622:	892a                	mv	s2,a0
    80004624:	00a05563          	blez	a0,8000462e <fileread+0x56>
      f->off += r;
    80004628:	509c                	lw	a5,32(s1)
    8000462a:	9fa9                	addw	a5,a5,a0
    8000462c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000462e:	6c88                	ld	a0,24(s1)
    80004630:	fffff097          	auipc	ra,0xfffff
    80004634:	08e080e7          	jalr	142(ra) # 800036be <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004638:	854a                	mv	a0,s2
    8000463a:	70a2                	ld	ra,40(sp)
    8000463c:	7402                	ld	s0,32(sp)
    8000463e:	64e2                	ld	s1,24(sp)
    80004640:	6942                	ld	s2,16(sp)
    80004642:	69a2                	ld	s3,8(sp)
    80004644:	6145                	addi	sp,sp,48
    80004646:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004648:	6908                	ld	a0,16(a0)
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	3c0080e7          	jalr	960(ra) # 80004a0a <piperead>
    80004652:	892a                	mv	s2,a0
    80004654:	b7d5                	j	80004638 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004656:	02451783          	lh	a5,36(a0)
    8000465a:	03079693          	slli	a3,a5,0x30
    8000465e:	92c1                	srli	a3,a3,0x30
    80004660:	4725                	li	a4,9
    80004662:	02d76863          	bltu	a4,a3,80004692 <fileread+0xba>
    80004666:	0792                	slli	a5,a5,0x4
    80004668:	0001d717          	auipc	a4,0x1d
    8000466c:	cb070713          	addi	a4,a4,-848 # 80021318 <devsw>
    80004670:	97ba                	add	a5,a5,a4
    80004672:	639c                	ld	a5,0(a5)
    80004674:	c38d                	beqz	a5,80004696 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004676:	4505                	li	a0,1
    80004678:	9782                	jalr	a5
    8000467a:	892a                	mv	s2,a0
    8000467c:	bf75                	j	80004638 <fileread+0x60>
    panic("fileread");
    8000467e:	00004517          	auipc	a0,0x4
    80004682:	00a50513          	addi	a0,a0,10 # 80008688 <syscalls+0x258>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	ea4080e7          	jalr	-348(ra) # 8000052a <panic>
    return -1;
    8000468e:	597d                	li	s2,-1
    80004690:	b765                	j	80004638 <fileread+0x60>
      return -1;
    80004692:	597d                	li	s2,-1
    80004694:	b755                	j	80004638 <fileread+0x60>
    80004696:	597d                	li	s2,-1
    80004698:	b745                	j	80004638 <fileread+0x60>

000000008000469a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000469a:	715d                	addi	sp,sp,-80
    8000469c:	e486                	sd	ra,72(sp)
    8000469e:	e0a2                	sd	s0,64(sp)
    800046a0:	fc26                	sd	s1,56(sp)
    800046a2:	f84a                	sd	s2,48(sp)
    800046a4:	f44e                	sd	s3,40(sp)
    800046a6:	f052                	sd	s4,32(sp)
    800046a8:	ec56                	sd	s5,24(sp)
    800046aa:	e85a                	sd	s6,16(sp)
    800046ac:	e45e                	sd	s7,8(sp)
    800046ae:	e062                	sd	s8,0(sp)
    800046b0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046b2:	00954783          	lbu	a5,9(a0)
    800046b6:	10078663          	beqz	a5,800047c2 <filewrite+0x128>
    800046ba:	892a                	mv	s2,a0
    800046bc:	8aae                	mv	s5,a1
    800046be:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046c0:	411c                	lw	a5,0(a0)
    800046c2:	4705                	li	a4,1
    800046c4:	02e78263          	beq	a5,a4,800046e8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046c8:	470d                	li	a4,3
    800046ca:	02e78663          	beq	a5,a4,800046f6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046ce:	4709                	li	a4,2
    800046d0:	0ee79163          	bne	a5,a4,800047b2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046d4:	0ac05d63          	blez	a2,8000478e <filewrite+0xf4>
    int i = 0;
    800046d8:	4981                	li	s3,0
    800046da:	6b05                	lui	s6,0x1
    800046dc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046e0:	6b85                	lui	s7,0x1
    800046e2:	c00b8b9b          	addiw	s7,s7,-1024
    800046e6:	a861                	j	8000477e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046e8:	6908                	ld	a0,16(a0)
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	22e080e7          	jalr	558(ra) # 80004918 <pipewrite>
    800046f2:	8a2a                	mv	s4,a0
    800046f4:	a045                	j	80004794 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046f6:	02451783          	lh	a5,36(a0)
    800046fa:	03079693          	slli	a3,a5,0x30
    800046fe:	92c1                	srli	a3,a3,0x30
    80004700:	4725                	li	a4,9
    80004702:	0cd76263          	bltu	a4,a3,800047c6 <filewrite+0x12c>
    80004706:	0792                	slli	a5,a5,0x4
    80004708:	0001d717          	auipc	a4,0x1d
    8000470c:	c1070713          	addi	a4,a4,-1008 # 80021318 <devsw>
    80004710:	97ba                	add	a5,a5,a4
    80004712:	679c                	ld	a5,8(a5)
    80004714:	cbdd                	beqz	a5,800047ca <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004716:	4505                	li	a0,1
    80004718:	9782                	jalr	a5
    8000471a:	8a2a                	mv	s4,a0
    8000471c:	a8a5                	j	80004794 <filewrite+0xfa>
    8000471e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004722:	00000097          	auipc	ra,0x0
    80004726:	8b0080e7          	jalr	-1872(ra) # 80003fd2 <begin_op>
      ilock(f->ip);
    8000472a:	01893503          	ld	a0,24(s2)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	ece080e7          	jalr	-306(ra) # 800035fc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004736:	8762                	mv	a4,s8
    80004738:	02092683          	lw	a3,32(s2)
    8000473c:	01598633          	add	a2,s3,s5
    80004740:	4585                	li	a1,1
    80004742:	01893503          	ld	a0,24(s2)
    80004746:	fffff097          	auipc	ra,0xfffff
    8000474a:	262080e7          	jalr	610(ra) # 800039a8 <writei>
    8000474e:	84aa                	mv	s1,a0
    80004750:	00a05763          	blez	a0,8000475e <filewrite+0xc4>
        f->off += r;
    80004754:	02092783          	lw	a5,32(s2)
    80004758:	9fa9                	addw	a5,a5,a0
    8000475a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000475e:	01893503          	ld	a0,24(s2)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	f5c080e7          	jalr	-164(ra) # 800036be <iunlock>
      end_op();
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	8e8080e7          	jalr	-1816(ra) # 80004052 <end_op>

      if(r != n1){
    80004772:	009c1f63          	bne	s8,s1,80004790 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004776:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000477a:	0149db63          	bge	s3,s4,80004790 <filewrite+0xf6>
      int n1 = n - i;
    8000477e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004782:	84be                	mv	s1,a5
    80004784:	2781                	sext.w	a5,a5
    80004786:	f8fb5ce3          	bge	s6,a5,8000471e <filewrite+0x84>
    8000478a:	84de                	mv	s1,s7
    8000478c:	bf49                	j	8000471e <filewrite+0x84>
    int i = 0;
    8000478e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004790:	013a1f63          	bne	s4,s3,800047ae <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004794:	8552                	mv	a0,s4
    80004796:	60a6                	ld	ra,72(sp)
    80004798:	6406                	ld	s0,64(sp)
    8000479a:	74e2                	ld	s1,56(sp)
    8000479c:	7942                	ld	s2,48(sp)
    8000479e:	79a2                	ld	s3,40(sp)
    800047a0:	7a02                	ld	s4,32(sp)
    800047a2:	6ae2                	ld	s5,24(sp)
    800047a4:	6b42                	ld	s6,16(sp)
    800047a6:	6ba2                	ld	s7,8(sp)
    800047a8:	6c02                	ld	s8,0(sp)
    800047aa:	6161                	addi	sp,sp,80
    800047ac:	8082                	ret
    ret = (i == n ? n : -1);
    800047ae:	5a7d                	li	s4,-1
    800047b0:	b7d5                	j	80004794 <filewrite+0xfa>
    panic("filewrite");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	ee650513          	addi	a0,a0,-282 # 80008698 <syscalls+0x268>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d70080e7          	jalr	-656(ra) # 8000052a <panic>
    return -1;
    800047c2:	5a7d                	li	s4,-1
    800047c4:	bfc1                	j	80004794 <filewrite+0xfa>
      return -1;
    800047c6:	5a7d                	li	s4,-1
    800047c8:	b7f1                	j	80004794 <filewrite+0xfa>
    800047ca:	5a7d                	li	s4,-1
    800047cc:	b7e1                	j	80004794 <filewrite+0xfa>

00000000800047ce <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047ce:	7179                	addi	sp,sp,-48
    800047d0:	f406                	sd	ra,40(sp)
    800047d2:	f022                	sd	s0,32(sp)
    800047d4:	ec26                	sd	s1,24(sp)
    800047d6:	e84a                	sd	s2,16(sp)
    800047d8:	e44e                	sd	s3,8(sp)
    800047da:	e052                	sd	s4,0(sp)
    800047dc:	1800                	addi	s0,sp,48
    800047de:	84aa                	mv	s1,a0
    800047e0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047e2:	0005b023          	sd	zero,0(a1)
    800047e6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	bf8080e7          	jalr	-1032(ra) # 800043e2 <filealloc>
    800047f2:	e088                	sd	a0,0(s1)
    800047f4:	c551                	beqz	a0,80004880 <pipealloc+0xb2>
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	bec080e7          	jalr	-1044(ra) # 800043e2 <filealloc>
    800047fe:	00aa3023          	sd	a0,0(s4)
    80004802:	c92d                	beqz	a0,80004874 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	2ce080e7          	jalr	718(ra) # 80000ad2 <kalloc>
    8000480c:	892a                	mv	s2,a0
    8000480e:	c125                	beqz	a0,8000486e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004810:	4985                	li	s3,1
    80004812:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004816:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000481a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000481e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004822:	00004597          	auipc	a1,0x4
    80004826:	e8658593          	addi	a1,a1,-378 # 800086a8 <syscalls+0x278>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	308080e7          	jalr	776(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004832:	609c                	ld	a5,0(s1)
    80004834:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004838:	609c                	ld	a5,0(s1)
    8000483a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000483e:	609c                	ld	a5,0(s1)
    80004840:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004844:	609c                	ld	a5,0(s1)
    80004846:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000484a:	000a3783          	ld	a5,0(s4)
    8000484e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004852:	000a3783          	ld	a5,0(s4)
    80004856:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000485a:	000a3783          	ld	a5,0(s4)
    8000485e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004862:	000a3783          	ld	a5,0(s4)
    80004866:	0127b823          	sd	s2,16(a5)
  return 0;
    8000486a:	4501                	li	a0,0
    8000486c:	a025                	j	80004894 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000486e:	6088                	ld	a0,0(s1)
    80004870:	e501                	bnez	a0,80004878 <pipealloc+0xaa>
    80004872:	a039                	j	80004880 <pipealloc+0xb2>
    80004874:	6088                	ld	a0,0(s1)
    80004876:	c51d                	beqz	a0,800048a4 <pipealloc+0xd6>
    fileclose(*f0);
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	c26080e7          	jalr	-986(ra) # 8000449e <fileclose>
  if(*f1)
    80004880:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004884:	557d                	li	a0,-1
  if(*f1)
    80004886:	c799                	beqz	a5,80004894 <pipealloc+0xc6>
    fileclose(*f1);
    80004888:	853e                	mv	a0,a5
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	c14080e7          	jalr	-1004(ra) # 8000449e <fileclose>
  return -1;
    80004892:	557d                	li	a0,-1
}
    80004894:	70a2                	ld	ra,40(sp)
    80004896:	7402                	ld	s0,32(sp)
    80004898:	64e2                	ld	s1,24(sp)
    8000489a:	6942                	ld	s2,16(sp)
    8000489c:	69a2                	ld	s3,8(sp)
    8000489e:	6a02                	ld	s4,0(sp)
    800048a0:	6145                	addi	sp,sp,48
    800048a2:	8082                	ret
  return -1;
    800048a4:	557d                	li	a0,-1
    800048a6:	b7fd                	j	80004894 <pipealloc+0xc6>

00000000800048a8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048a8:	1101                	addi	sp,sp,-32
    800048aa:	ec06                	sd	ra,24(sp)
    800048ac:	e822                	sd	s0,16(sp)
    800048ae:	e426                	sd	s1,8(sp)
    800048b0:	e04a                	sd	s2,0(sp)
    800048b2:	1000                	addi	s0,sp,32
    800048b4:	84aa                	mv	s1,a0
    800048b6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	30a080e7          	jalr	778(ra) # 80000bc2 <acquire>
  if(writable){
    800048c0:	02090d63          	beqz	s2,800048fa <pipeclose+0x52>
    pi->writeopen = 0;
    800048c4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048c8:	21848513          	addi	a0,s1,536
    800048cc:	ffffe097          	auipc	ra,0xffffe
    800048d0:	8f0080e7          	jalr	-1808(ra) # 800021bc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048d4:	2204b783          	ld	a5,544(s1)
    800048d8:	eb95                	bnez	a5,8000490c <pipeclose+0x64>
    release(&pi->lock);
    800048da:	8526                	mv	a0,s1
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	39a080e7          	jalr	922(ra) # 80000c76 <release>
    kfree((char*)pi);
    800048e4:	8526                	mv	a0,s1
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	0f0080e7          	jalr	240(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800048ee:	60e2                	ld	ra,24(sp)
    800048f0:	6442                	ld	s0,16(sp)
    800048f2:	64a2                	ld	s1,8(sp)
    800048f4:	6902                	ld	s2,0(sp)
    800048f6:	6105                	addi	sp,sp,32
    800048f8:	8082                	ret
    pi->readopen = 0;
    800048fa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048fe:	21c48513          	addi	a0,s1,540
    80004902:	ffffe097          	auipc	ra,0xffffe
    80004906:	8ba080e7          	jalr	-1862(ra) # 800021bc <wakeup>
    8000490a:	b7e9                	j	800048d4 <pipeclose+0x2c>
    release(&pi->lock);
    8000490c:	8526                	mv	a0,s1
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	368080e7          	jalr	872(ra) # 80000c76 <release>
}
    80004916:	bfe1                	j	800048ee <pipeclose+0x46>

0000000080004918 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004918:	711d                	addi	sp,sp,-96
    8000491a:	ec86                	sd	ra,88(sp)
    8000491c:	e8a2                	sd	s0,80(sp)
    8000491e:	e4a6                	sd	s1,72(sp)
    80004920:	e0ca                	sd	s2,64(sp)
    80004922:	fc4e                	sd	s3,56(sp)
    80004924:	f852                	sd	s4,48(sp)
    80004926:	f456                	sd	s5,40(sp)
    80004928:	f05a                	sd	s6,32(sp)
    8000492a:	ec5e                	sd	s7,24(sp)
    8000492c:	e862                	sd	s8,16(sp)
    8000492e:	1080                	addi	s0,sp,96
    80004930:	84aa                	mv	s1,a0
    80004932:	8aae                	mv	s5,a1
    80004934:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004936:	ffffd097          	auipc	ra,0xffffd
    8000493a:	03a080e7          	jalr	58(ra) # 80001970 <myproc>
    8000493e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004940:	8526                	mv	a0,s1
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	280080e7          	jalr	640(ra) # 80000bc2 <acquire>
  while(i < n){
    8000494a:	0b405363          	blez	s4,800049f0 <pipewrite+0xd8>
  int i = 0;
    8000494e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004950:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004952:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004956:	21c48b93          	addi	s7,s1,540
    8000495a:	a089                	j	8000499c <pipewrite+0x84>
      release(&pi->lock);
    8000495c:	8526                	mv	a0,s1
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	318080e7          	jalr	792(ra) # 80000c76 <release>
      return -1;
    80004966:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004968:	854a                	mv	a0,s2
    8000496a:	60e6                	ld	ra,88(sp)
    8000496c:	6446                	ld	s0,80(sp)
    8000496e:	64a6                	ld	s1,72(sp)
    80004970:	6906                	ld	s2,64(sp)
    80004972:	79e2                	ld	s3,56(sp)
    80004974:	7a42                	ld	s4,48(sp)
    80004976:	7aa2                	ld	s5,40(sp)
    80004978:	7b02                	ld	s6,32(sp)
    8000497a:	6be2                	ld	s7,24(sp)
    8000497c:	6c42                	ld	s8,16(sp)
    8000497e:	6125                	addi	sp,sp,96
    80004980:	8082                	ret
      wakeup(&pi->nread);
    80004982:	8562                	mv	a0,s8
    80004984:	ffffe097          	auipc	ra,0xffffe
    80004988:	838080e7          	jalr	-1992(ra) # 800021bc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000498c:	85a6                	mv	a1,s1
    8000498e:	855e                	mv	a0,s7
    80004990:	ffffd097          	auipc	ra,0xffffd
    80004994:	6a0080e7          	jalr	1696(ra) # 80002030 <sleep>
  while(i < n){
    80004998:	05495d63          	bge	s2,s4,800049f2 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000499c:	2204a783          	lw	a5,544(s1)
    800049a0:	dfd5                	beqz	a5,8000495c <pipewrite+0x44>
    800049a2:	0289a783          	lw	a5,40(s3)
    800049a6:	fbdd                	bnez	a5,8000495c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049a8:	2184a783          	lw	a5,536(s1)
    800049ac:	21c4a703          	lw	a4,540(s1)
    800049b0:	2007879b          	addiw	a5,a5,512
    800049b4:	fcf707e3          	beq	a4,a5,80004982 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049b8:	4685                	li	a3,1
    800049ba:	01590633          	add	a2,s2,s5
    800049be:	faf40593          	addi	a1,s0,-81
    800049c2:	0509b503          	ld	a0,80(s3)
    800049c6:	ffffd097          	auipc	ra,0xffffd
    800049ca:	cf6080e7          	jalr	-778(ra) # 800016bc <copyin>
    800049ce:	03650263          	beq	a0,s6,800049f2 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049d2:	21c4a783          	lw	a5,540(s1)
    800049d6:	0017871b          	addiw	a4,a5,1
    800049da:	20e4ae23          	sw	a4,540(s1)
    800049de:	1ff7f793          	andi	a5,a5,511
    800049e2:	97a6                	add	a5,a5,s1
    800049e4:	faf44703          	lbu	a4,-81(s0)
    800049e8:	00e78c23          	sb	a4,24(a5)
      i++;
    800049ec:	2905                	addiw	s2,s2,1
    800049ee:	b76d                	j	80004998 <pipewrite+0x80>
  int i = 0;
    800049f0:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049f2:	21848513          	addi	a0,s1,536
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	7c6080e7          	jalr	1990(ra) # 800021bc <wakeup>
  release(&pi->lock);
    800049fe:	8526                	mv	a0,s1
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	276080e7          	jalr	630(ra) # 80000c76 <release>
  return i;
    80004a08:	b785                	j	80004968 <pipewrite+0x50>

0000000080004a0a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a0a:	715d                	addi	sp,sp,-80
    80004a0c:	e486                	sd	ra,72(sp)
    80004a0e:	e0a2                	sd	s0,64(sp)
    80004a10:	fc26                	sd	s1,56(sp)
    80004a12:	f84a                	sd	s2,48(sp)
    80004a14:	f44e                	sd	s3,40(sp)
    80004a16:	f052                	sd	s4,32(sp)
    80004a18:	ec56                	sd	s5,24(sp)
    80004a1a:	e85a                	sd	s6,16(sp)
    80004a1c:	0880                	addi	s0,sp,80
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	892e                	mv	s2,a1
    80004a22:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a24:	ffffd097          	auipc	ra,0xffffd
    80004a28:	f4c080e7          	jalr	-180(ra) # 80001970 <myproc>
    80004a2c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	192080e7          	jalr	402(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a38:	2184a703          	lw	a4,536(s1)
    80004a3c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a40:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a44:	02f71463          	bne	a4,a5,80004a6c <piperead+0x62>
    80004a48:	2244a783          	lw	a5,548(s1)
    80004a4c:	c385                	beqz	a5,80004a6c <piperead+0x62>
    if(pr->killed){
    80004a4e:	028a2783          	lw	a5,40(s4)
    80004a52:	ebc1                	bnez	a5,80004ae2 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a54:	85a6                	mv	a1,s1
    80004a56:	854e                	mv	a0,s3
    80004a58:	ffffd097          	auipc	ra,0xffffd
    80004a5c:	5d8080e7          	jalr	1496(ra) # 80002030 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a60:	2184a703          	lw	a4,536(s1)
    80004a64:	21c4a783          	lw	a5,540(s1)
    80004a68:	fef700e3          	beq	a4,a5,80004a48 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a6c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a6e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a70:	05505363          	blez	s5,80004ab6 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004a74:	2184a783          	lw	a5,536(s1)
    80004a78:	21c4a703          	lw	a4,540(s1)
    80004a7c:	02f70d63          	beq	a4,a5,80004ab6 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a80:	0017871b          	addiw	a4,a5,1
    80004a84:	20e4ac23          	sw	a4,536(s1)
    80004a88:	1ff7f793          	andi	a5,a5,511
    80004a8c:	97a6                	add	a5,a5,s1
    80004a8e:	0187c783          	lbu	a5,24(a5)
    80004a92:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a96:	4685                	li	a3,1
    80004a98:	fbf40613          	addi	a2,s0,-65
    80004a9c:	85ca                	mv	a1,s2
    80004a9e:	050a3503          	ld	a0,80(s4)
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	b8e080e7          	jalr	-1138(ra) # 80001630 <copyout>
    80004aaa:	01650663          	beq	a0,s6,80004ab6 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aae:	2985                	addiw	s3,s3,1
    80004ab0:	0905                	addi	s2,s2,1
    80004ab2:	fd3a91e3          	bne	s5,s3,80004a74 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ab6:	21c48513          	addi	a0,s1,540
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	702080e7          	jalr	1794(ra) # 800021bc <wakeup>
  release(&pi->lock);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	1b2080e7          	jalr	434(ra) # 80000c76 <release>
  return i;
}
    80004acc:	854e                	mv	a0,s3
    80004ace:	60a6                	ld	ra,72(sp)
    80004ad0:	6406                	ld	s0,64(sp)
    80004ad2:	74e2                	ld	s1,56(sp)
    80004ad4:	7942                	ld	s2,48(sp)
    80004ad6:	79a2                	ld	s3,40(sp)
    80004ad8:	7a02                	ld	s4,32(sp)
    80004ada:	6ae2                	ld	s5,24(sp)
    80004adc:	6b42                	ld	s6,16(sp)
    80004ade:	6161                	addi	sp,sp,80
    80004ae0:	8082                	ret
      release(&pi->lock);
    80004ae2:	8526                	mv	a0,s1
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	192080e7          	jalr	402(ra) # 80000c76 <release>
      return -1;
    80004aec:	59fd                	li	s3,-1
    80004aee:	bff9                	j	80004acc <piperead+0xc2>

0000000080004af0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004af0:	de010113          	addi	sp,sp,-544
    80004af4:	20113c23          	sd	ra,536(sp)
    80004af8:	20813823          	sd	s0,528(sp)
    80004afc:	20913423          	sd	s1,520(sp)
    80004b00:	21213023          	sd	s2,512(sp)
    80004b04:	ffce                	sd	s3,504(sp)
    80004b06:	fbd2                	sd	s4,496(sp)
    80004b08:	f7d6                	sd	s5,488(sp)
    80004b0a:	f3da                	sd	s6,480(sp)
    80004b0c:	efde                	sd	s7,472(sp)
    80004b0e:	ebe2                	sd	s8,464(sp)
    80004b10:	e7e6                	sd	s9,456(sp)
    80004b12:	e3ea                	sd	s10,448(sp)
    80004b14:	ff6e                	sd	s11,440(sp)
    80004b16:	1400                	addi	s0,sp,544
    80004b18:	892a                	mv	s2,a0
    80004b1a:	dea43423          	sd	a0,-536(s0)
    80004b1e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	e4e080e7          	jalr	-434(ra) # 80001970 <myproc>
    80004b2a:	84aa                	mv	s1,a0

  begin_op();
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	4a6080e7          	jalr	1190(ra) # 80003fd2 <begin_op>

  if((ip = namei(path)) == 0){
    80004b34:	854a                	mv	a0,s2
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	27c080e7          	jalr	636(ra) # 80003db2 <namei>
    80004b3e:	c93d                	beqz	a0,80004bb4 <exec+0xc4>
    80004b40:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	aba080e7          	jalr	-1350(ra) # 800035fc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b4a:	04000713          	li	a4,64
    80004b4e:	4681                	li	a3,0
    80004b50:	e4840613          	addi	a2,s0,-440
    80004b54:	4581                	li	a1,0
    80004b56:	8556                	mv	a0,s5
    80004b58:	fffff097          	auipc	ra,0xfffff
    80004b5c:	d58080e7          	jalr	-680(ra) # 800038b0 <readi>
    80004b60:	04000793          	li	a5,64
    80004b64:	00f51a63          	bne	a0,a5,80004b78 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b68:	e4842703          	lw	a4,-440(s0)
    80004b6c:	464c47b7          	lui	a5,0x464c4
    80004b70:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b74:	04f70663          	beq	a4,a5,80004bc0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b78:	8556                	mv	a0,s5
    80004b7a:	fffff097          	auipc	ra,0xfffff
    80004b7e:	ce4080e7          	jalr	-796(ra) # 8000385e <iunlockput>
    end_op();
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	4d0080e7          	jalr	1232(ra) # 80004052 <end_op>
  }
  return -1;
    80004b8a:	557d                	li	a0,-1
}
    80004b8c:	21813083          	ld	ra,536(sp)
    80004b90:	21013403          	ld	s0,528(sp)
    80004b94:	20813483          	ld	s1,520(sp)
    80004b98:	20013903          	ld	s2,512(sp)
    80004b9c:	79fe                	ld	s3,504(sp)
    80004b9e:	7a5e                	ld	s4,496(sp)
    80004ba0:	7abe                	ld	s5,488(sp)
    80004ba2:	7b1e                	ld	s6,480(sp)
    80004ba4:	6bfe                	ld	s7,472(sp)
    80004ba6:	6c5e                	ld	s8,464(sp)
    80004ba8:	6cbe                	ld	s9,456(sp)
    80004baa:	6d1e                	ld	s10,448(sp)
    80004bac:	7dfa                	ld	s11,440(sp)
    80004bae:	22010113          	addi	sp,sp,544
    80004bb2:	8082                	ret
    end_op();
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	49e080e7          	jalr	1182(ra) # 80004052 <end_op>
    return -1;
    80004bbc:	557d                	li	a0,-1
    80004bbe:	b7f9                	j	80004b8c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	e72080e7          	jalr	-398(ra) # 80001a34 <proc_pagetable>
    80004bca:	8b2a                	mv	s6,a0
    80004bcc:	d555                	beqz	a0,80004b78 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bce:	e6842783          	lw	a5,-408(s0)
    80004bd2:	e8045703          	lhu	a4,-384(s0)
    80004bd6:	c735                	beqz	a4,80004c42 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004bd8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bda:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004bde:	6a05                	lui	s4,0x1
    80004be0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004be4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004be8:	6d85                	lui	s11,0x1
    80004bea:	7d7d                	lui	s10,0xfffff
    80004bec:	ac1d                	j	80004e22 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bee:	00004517          	auipc	a0,0x4
    80004bf2:	ac250513          	addi	a0,a0,-1342 # 800086b0 <syscalls+0x280>
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	934080e7          	jalr	-1740(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bfe:	874a                	mv	a4,s2
    80004c00:	009c86bb          	addw	a3,s9,s1
    80004c04:	4581                	li	a1,0
    80004c06:	8556                	mv	a0,s5
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	ca8080e7          	jalr	-856(ra) # 800038b0 <readi>
    80004c10:	2501                	sext.w	a0,a0
    80004c12:	1aa91863          	bne	s2,a0,80004dc2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c16:	009d84bb          	addw	s1,s11,s1
    80004c1a:	013d09bb          	addw	s3,s10,s3
    80004c1e:	1f74f263          	bgeu	s1,s7,80004e02 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c22:	02049593          	slli	a1,s1,0x20
    80004c26:	9181                	srli	a1,a1,0x20
    80004c28:	95e2                	add	a1,a1,s8
    80004c2a:	855a                	mv	a0,s6
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	420080e7          	jalr	1056(ra) # 8000104c <walkaddr>
    80004c34:	862a                	mv	a2,a0
    if(pa == 0)
    80004c36:	dd45                	beqz	a0,80004bee <exec+0xfe>
      n = PGSIZE;
    80004c38:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c3a:	fd49f2e3          	bgeu	s3,s4,80004bfe <exec+0x10e>
      n = sz - i;
    80004c3e:	894e                	mv	s2,s3
    80004c40:	bf7d                	j	80004bfe <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c42:	4481                	li	s1,0
  iunlockput(ip);
    80004c44:	8556                	mv	a0,s5
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	c18080e7          	jalr	-1000(ra) # 8000385e <iunlockput>
  end_op();
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	404080e7          	jalr	1028(ra) # 80004052 <end_op>
  p = myproc();
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	d1a080e7          	jalr	-742(ra) # 80001970 <myproc>
    80004c5e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c60:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c64:	6785                	lui	a5,0x1
    80004c66:	17fd                	addi	a5,a5,-1
    80004c68:	94be                	add	s1,s1,a5
    80004c6a:	77fd                	lui	a5,0xfffff
    80004c6c:	8fe5                	and	a5,a5,s1
    80004c6e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c72:	6609                	lui	a2,0x2
    80004c74:	963e                	add	a2,a2,a5
    80004c76:	85be                	mv	a1,a5
    80004c78:	855a                	mv	a0,s6
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	766080e7          	jalr	1894(ra) # 800013e0 <uvmalloc>
    80004c82:	8c2a                	mv	s8,a0
  ip = 0;
    80004c84:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c86:	12050e63          	beqz	a0,80004dc2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c8a:	75f9                	lui	a1,0xffffe
    80004c8c:	95aa                	add	a1,a1,a0
    80004c8e:	855a                	mv	a0,s6
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	96e080e7          	jalr	-1682(ra) # 800015fe <uvmclear>
  stackbase = sp - PGSIZE;
    80004c98:	7afd                	lui	s5,0xfffff
    80004c9a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c9c:	df043783          	ld	a5,-528(s0)
    80004ca0:	6388                	ld	a0,0(a5)
    80004ca2:	c925                	beqz	a0,80004d12 <exec+0x222>
    80004ca4:	e8840993          	addi	s3,s0,-376
    80004ca8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004cac:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004cae:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	192080e7          	jalr	402(ra) # 80000e42 <strlen>
    80004cb8:	0015079b          	addiw	a5,a0,1
    80004cbc:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cc0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cc4:	13596363          	bltu	s2,s5,80004dea <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cc8:	df043d83          	ld	s11,-528(s0)
    80004ccc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004cd0:	8552                	mv	a0,s4
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	170080e7          	jalr	368(ra) # 80000e42 <strlen>
    80004cda:	0015069b          	addiw	a3,a0,1
    80004cde:	8652                	mv	a2,s4
    80004ce0:	85ca                	mv	a1,s2
    80004ce2:	855a                	mv	a0,s6
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	94c080e7          	jalr	-1716(ra) # 80001630 <copyout>
    80004cec:	10054363          	bltz	a0,80004df2 <exec+0x302>
    ustack[argc] = sp;
    80004cf0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cf4:	0485                	addi	s1,s1,1
    80004cf6:	008d8793          	addi	a5,s11,8
    80004cfa:	def43823          	sd	a5,-528(s0)
    80004cfe:	008db503          	ld	a0,8(s11)
    80004d02:	c911                	beqz	a0,80004d16 <exec+0x226>
    if(argc >= MAXARG)
    80004d04:	09a1                	addi	s3,s3,8
    80004d06:	fb3c95e3          	bne	s9,s3,80004cb0 <exec+0x1c0>
  sz = sz1;
    80004d0a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d0e:	4a81                	li	s5,0
    80004d10:	a84d                	j	80004dc2 <exec+0x2d2>
  sp = sz;
    80004d12:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d14:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d16:	00349793          	slli	a5,s1,0x3
    80004d1a:	f9040713          	addi	a4,s0,-112
    80004d1e:	97ba                	add	a5,a5,a4
    80004d20:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004d24:	00148693          	addi	a3,s1,1
    80004d28:	068e                	slli	a3,a3,0x3
    80004d2a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d2e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d32:	01597663          	bgeu	s2,s5,80004d3e <exec+0x24e>
  sz = sz1;
    80004d36:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d3a:	4a81                	li	s5,0
    80004d3c:	a059                	j	80004dc2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d3e:	e8840613          	addi	a2,s0,-376
    80004d42:	85ca                	mv	a1,s2
    80004d44:	855a                	mv	a0,s6
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	8ea080e7          	jalr	-1814(ra) # 80001630 <copyout>
    80004d4e:	0a054663          	bltz	a0,80004dfa <exec+0x30a>
  p->trapframe->a1 = sp;
    80004d52:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004d56:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d5a:	de843783          	ld	a5,-536(s0)
    80004d5e:	0007c703          	lbu	a4,0(a5)
    80004d62:	cf11                	beqz	a4,80004d7e <exec+0x28e>
    80004d64:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d66:	02f00693          	li	a3,47
    80004d6a:	a039                	j	80004d78 <exec+0x288>
      last = s+1;
    80004d6c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d70:	0785                	addi	a5,a5,1
    80004d72:	fff7c703          	lbu	a4,-1(a5)
    80004d76:	c701                	beqz	a4,80004d7e <exec+0x28e>
    if(*s == '/')
    80004d78:	fed71ce3          	bne	a4,a3,80004d70 <exec+0x280>
    80004d7c:	bfc5                	j	80004d6c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d7e:	4641                	li	a2,16
    80004d80:	de843583          	ld	a1,-536(s0)
    80004d84:	158b8513          	addi	a0,s7,344
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	088080e7          	jalr	136(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d90:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d94:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004d98:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d9c:	058bb783          	ld	a5,88(s7)
    80004da0:	e6043703          	ld	a4,-416(s0)
    80004da4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004da6:	058bb783          	ld	a5,88(s7)
    80004daa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004dae:	85ea                	mv	a1,s10
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	d20080e7          	jalr	-736(ra) # 80001ad0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004db8:	0004851b          	sext.w	a0,s1
    80004dbc:	bbc1                	j	80004b8c <exec+0x9c>
    80004dbe:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004dc2:	df843583          	ld	a1,-520(s0)
    80004dc6:	855a                	mv	a0,s6
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	d08080e7          	jalr	-760(ra) # 80001ad0 <proc_freepagetable>
  if(ip){
    80004dd0:	da0a94e3          	bnez	s5,80004b78 <exec+0x88>
  return -1;
    80004dd4:	557d                	li	a0,-1
    80004dd6:	bb5d                	j	80004b8c <exec+0x9c>
    80004dd8:	de943c23          	sd	s1,-520(s0)
    80004ddc:	b7dd                	j	80004dc2 <exec+0x2d2>
    80004dde:	de943c23          	sd	s1,-520(s0)
    80004de2:	b7c5                	j	80004dc2 <exec+0x2d2>
    80004de4:	de943c23          	sd	s1,-520(s0)
    80004de8:	bfe9                	j	80004dc2 <exec+0x2d2>
  sz = sz1;
    80004dea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dee:	4a81                	li	s5,0
    80004df0:	bfc9                	j	80004dc2 <exec+0x2d2>
  sz = sz1;
    80004df2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004df6:	4a81                	li	s5,0
    80004df8:	b7e9                	j	80004dc2 <exec+0x2d2>
  sz = sz1;
    80004dfa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dfe:	4a81                	li	s5,0
    80004e00:	b7c9                	j	80004dc2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e02:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e06:	e0843783          	ld	a5,-504(s0)
    80004e0a:	0017869b          	addiw	a3,a5,1
    80004e0e:	e0d43423          	sd	a3,-504(s0)
    80004e12:	e0043783          	ld	a5,-512(s0)
    80004e16:	0387879b          	addiw	a5,a5,56
    80004e1a:	e8045703          	lhu	a4,-384(s0)
    80004e1e:	e2e6d3e3          	bge	a3,a4,80004c44 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e22:	2781                	sext.w	a5,a5
    80004e24:	e0f43023          	sd	a5,-512(s0)
    80004e28:	03800713          	li	a4,56
    80004e2c:	86be                	mv	a3,a5
    80004e2e:	e1040613          	addi	a2,s0,-496
    80004e32:	4581                	li	a1,0
    80004e34:	8556                	mv	a0,s5
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	a7a080e7          	jalr	-1414(ra) # 800038b0 <readi>
    80004e3e:	03800793          	li	a5,56
    80004e42:	f6f51ee3          	bne	a0,a5,80004dbe <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e46:	e1042783          	lw	a5,-496(s0)
    80004e4a:	4705                	li	a4,1
    80004e4c:	fae79de3          	bne	a5,a4,80004e06 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004e50:	e3843603          	ld	a2,-456(s0)
    80004e54:	e3043783          	ld	a5,-464(s0)
    80004e58:	f8f660e3          	bltu	a2,a5,80004dd8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e5c:	e2043783          	ld	a5,-480(s0)
    80004e60:	963e                	add	a2,a2,a5
    80004e62:	f6f66ee3          	bltu	a2,a5,80004dde <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e66:	85a6                	mv	a1,s1
    80004e68:	855a                	mv	a0,s6
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	576080e7          	jalr	1398(ra) # 800013e0 <uvmalloc>
    80004e72:	dea43c23          	sd	a0,-520(s0)
    80004e76:	d53d                	beqz	a0,80004de4 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004e78:	e2043c03          	ld	s8,-480(s0)
    80004e7c:	de043783          	ld	a5,-544(s0)
    80004e80:	00fc77b3          	and	a5,s8,a5
    80004e84:	ff9d                	bnez	a5,80004dc2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e86:	e1842c83          	lw	s9,-488(s0)
    80004e8a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e8e:	f60b8ae3          	beqz	s7,80004e02 <exec+0x312>
    80004e92:	89de                	mv	s3,s7
    80004e94:	4481                	li	s1,0
    80004e96:	b371                	j	80004c22 <exec+0x132>

0000000080004e98 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e98:	7179                	addi	sp,sp,-48
    80004e9a:	f406                	sd	ra,40(sp)
    80004e9c:	f022                	sd	s0,32(sp)
    80004e9e:	ec26                	sd	s1,24(sp)
    80004ea0:	e84a                	sd	s2,16(sp)
    80004ea2:	1800                	addi	s0,sp,48
    80004ea4:	892e                	mv	s2,a1
    80004ea6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ea8:	fdc40593          	addi	a1,s0,-36
    80004eac:	ffffe097          	auipc	ra,0xffffe
    80004eb0:	bd0080e7          	jalr	-1072(ra) # 80002a7c <argint>
    80004eb4:	04054063          	bltz	a0,80004ef4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004eb8:	fdc42703          	lw	a4,-36(s0)
    80004ebc:	47bd                	li	a5,15
    80004ebe:	02e7ed63          	bltu	a5,a4,80004ef8 <argfd+0x60>
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	aae080e7          	jalr	-1362(ra) # 80001970 <myproc>
    80004eca:	fdc42703          	lw	a4,-36(s0)
    80004ece:	01a70793          	addi	a5,a4,26
    80004ed2:	078e                	slli	a5,a5,0x3
    80004ed4:	953e                	add	a0,a0,a5
    80004ed6:	611c                	ld	a5,0(a0)
    80004ed8:	c395                	beqz	a5,80004efc <argfd+0x64>
    return -1;
  if(pfd)
    80004eda:	00090463          	beqz	s2,80004ee2 <argfd+0x4a>
    *pfd = fd;
    80004ede:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ee2:	4501                	li	a0,0
  if(pf)
    80004ee4:	c091                	beqz	s1,80004ee8 <argfd+0x50>
    *pf = f;
    80004ee6:	e09c                	sd	a5,0(s1)
}
    80004ee8:	70a2                	ld	ra,40(sp)
    80004eea:	7402                	ld	s0,32(sp)
    80004eec:	64e2                	ld	s1,24(sp)
    80004eee:	6942                	ld	s2,16(sp)
    80004ef0:	6145                	addi	sp,sp,48
    80004ef2:	8082                	ret
    return -1;
    80004ef4:	557d                	li	a0,-1
    80004ef6:	bfcd                	j	80004ee8 <argfd+0x50>
    return -1;
    80004ef8:	557d                	li	a0,-1
    80004efa:	b7fd                	j	80004ee8 <argfd+0x50>
    80004efc:	557d                	li	a0,-1
    80004efe:	b7ed                	j	80004ee8 <argfd+0x50>

0000000080004f00 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f00:	1101                	addi	sp,sp,-32
    80004f02:	ec06                	sd	ra,24(sp)
    80004f04:	e822                	sd	s0,16(sp)
    80004f06:	e426                	sd	s1,8(sp)
    80004f08:	1000                	addi	s0,sp,32
    80004f0a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	a64080e7          	jalr	-1436(ra) # 80001970 <myproc>
    80004f14:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f16:	0d050793          	addi	a5,a0,208
    80004f1a:	4501                	li	a0,0
    80004f1c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f1e:	6398                	ld	a4,0(a5)
    80004f20:	cb19                	beqz	a4,80004f36 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f22:	2505                	addiw	a0,a0,1
    80004f24:	07a1                	addi	a5,a5,8
    80004f26:	fed51ce3          	bne	a0,a3,80004f1e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f2a:	557d                	li	a0,-1
}
    80004f2c:	60e2                	ld	ra,24(sp)
    80004f2e:	6442                	ld	s0,16(sp)
    80004f30:	64a2                	ld	s1,8(sp)
    80004f32:	6105                	addi	sp,sp,32
    80004f34:	8082                	ret
      p->ofile[fd] = f;
    80004f36:	01a50793          	addi	a5,a0,26
    80004f3a:	078e                	slli	a5,a5,0x3
    80004f3c:	963e                	add	a2,a2,a5
    80004f3e:	e204                	sd	s1,0(a2)
      return fd;
    80004f40:	b7f5                	j	80004f2c <fdalloc+0x2c>

0000000080004f42 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f42:	715d                	addi	sp,sp,-80
    80004f44:	e486                	sd	ra,72(sp)
    80004f46:	e0a2                	sd	s0,64(sp)
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f84a                	sd	s2,48(sp)
    80004f4c:	f44e                	sd	s3,40(sp)
    80004f4e:	f052                	sd	s4,32(sp)
    80004f50:	ec56                	sd	s5,24(sp)
    80004f52:	0880                	addi	s0,sp,80
    80004f54:	89ae                	mv	s3,a1
    80004f56:	8ab2                	mv	s5,a2
    80004f58:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f5a:	fb040593          	addi	a1,s0,-80
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	e72080e7          	jalr	-398(ra) # 80003dd0 <nameiparent>
    80004f66:	892a                	mv	s2,a0
    80004f68:	12050e63          	beqz	a0,800050a4 <create+0x162>
    return 0;

  ilock(dp);
    80004f6c:	ffffe097          	auipc	ra,0xffffe
    80004f70:	690080e7          	jalr	1680(ra) # 800035fc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f74:	4601                	li	a2,0
    80004f76:	fb040593          	addi	a1,s0,-80
    80004f7a:	854a                	mv	a0,s2
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	b64080e7          	jalr	-1180(ra) # 80003ae0 <dirlookup>
    80004f84:	84aa                	mv	s1,a0
    80004f86:	c921                	beqz	a0,80004fd6 <create+0x94>
    iunlockput(dp);
    80004f88:	854a                	mv	a0,s2
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	8d4080e7          	jalr	-1836(ra) # 8000385e <iunlockput>
    ilock(ip);
    80004f92:	8526                	mv	a0,s1
    80004f94:	ffffe097          	auipc	ra,0xffffe
    80004f98:	668080e7          	jalr	1640(ra) # 800035fc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f9c:	2981                	sext.w	s3,s3
    80004f9e:	4789                	li	a5,2
    80004fa0:	02f99463          	bne	s3,a5,80004fc8 <create+0x86>
    80004fa4:	0444d783          	lhu	a5,68(s1)
    80004fa8:	37f9                	addiw	a5,a5,-2
    80004faa:	17c2                	slli	a5,a5,0x30
    80004fac:	93c1                	srli	a5,a5,0x30
    80004fae:	4705                	li	a4,1
    80004fb0:	00f76c63          	bltu	a4,a5,80004fc8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	60a6                	ld	ra,72(sp)
    80004fb8:	6406                	ld	s0,64(sp)
    80004fba:	74e2                	ld	s1,56(sp)
    80004fbc:	7942                	ld	s2,48(sp)
    80004fbe:	79a2                	ld	s3,40(sp)
    80004fc0:	7a02                	ld	s4,32(sp)
    80004fc2:	6ae2                	ld	s5,24(sp)
    80004fc4:	6161                	addi	sp,sp,80
    80004fc6:	8082                	ret
    iunlockput(ip);
    80004fc8:	8526                	mv	a0,s1
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	894080e7          	jalr	-1900(ra) # 8000385e <iunlockput>
    return 0;
    80004fd2:	4481                	li	s1,0
    80004fd4:	b7c5                	j	80004fb4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fd6:	85ce                	mv	a1,s3
    80004fd8:	00092503          	lw	a0,0(s2)
    80004fdc:	ffffe097          	auipc	ra,0xffffe
    80004fe0:	488080e7          	jalr	1160(ra) # 80003464 <ialloc>
    80004fe4:	84aa                	mv	s1,a0
    80004fe6:	c521                	beqz	a0,8000502e <create+0xec>
  ilock(ip);
    80004fe8:	ffffe097          	auipc	ra,0xffffe
    80004fec:	614080e7          	jalr	1556(ra) # 800035fc <ilock>
  ip->major = major;
    80004ff0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004ff4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004ff8:	4a05                	li	s4,1
    80004ffa:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004ffe:	8526                	mv	a0,s1
    80005000:	ffffe097          	auipc	ra,0xffffe
    80005004:	532080e7          	jalr	1330(ra) # 80003532 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005008:	2981                	sext.w	s3,s3
    8000500a:	03498a63          	beq	s3,s4,8000503e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000500e:	40d0                	lw	a2,4(s1)
    80005010:	fb040593          	addi	a1,s0,-80
    80005014:	854a                	mv	a0,s2
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	cda080e7          	jalr	-806(ra) # 80003cf0 <dirlink>
    8000501e:	06054b63          	bltz	a0,80005094 <create+0x152>
  iunlockput(dp);
    80005022:	854a                	mv	a0,s2
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	83a080e7          	jalr	-1990(ra) # 8000385e <iunlockput>
  return ip;
    8000502c:	b761                	j	80004fb4 <create+0x72>
    panic("create: ialloc");
    8000502e:	00003517          	auipc	a0,0x3
    80005032:	6a250513          	addi	a0,a0,1698 # 800086d0 <syscalls+0x2a0>
    80005036:	ffffb097          	auipc	ra,0xffffb
    8000503a:	4f4080e7          	jalr	1268(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000503e:	04a95783          	lhu	a5,74(s2)
    80005042:	2785                	addiw	a5,a5,1
    80005044:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005048:	854a                	mv	a0,s2
    8000504a:	ffffe097          	auipc	ra,0xffffe
    8000504e:	4e8080e7          	jalr	1256(ra) # 80003532 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005052:	40d0                	lw	a2,4(s1)
    80005054:	00003597          	auipc	a1,0x3
    80005058:	68c58593          	addi	a1,a1,1676 # 800086e0 <syscalls+0x2b0>
    8000505c:	8526                	mv	a0,s1
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	c92080e7          	jalr	-878(ra) # 80003cf0 <dirlink>
    80005066:	00054f63          	bltz	a0,80005084 <create+0x142>
    8000506a:	00492603          	lw	a2,4(s2)
    8000506e:	00003597          	auipc	a1,0x3
    80005072:	67a58593          	addi	a1,a1,1658 # 800086e8 <syscalls+0x2b8>
    80005076:	8526                	mv	a0,s1
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	c78080e7          	jalr	-904(ra) # 80003cf0 <dirlink>
    80005080:	f80557e3          	bgez	a0,8000500e <create+0xcc>
      panic("create dots");
    80005084:	00003517          	auipc	a0,0x3
    80005088:	66c50513          	addi	a0,a0,1644 # 800086f0 <syscalls+0x2c0>
    8000508c:	ffffb097          	auipc	ra,0xffffb
    80005090:	49e080e7          	jalr	1182(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005094:	00003517          	auipc	a0,0x3
    80005098:	66c50513          	addi	a0,a0,1644 # 80008700 <syscalls+0x2d0>
    8000509c:	ffffb097          	auipc	ra,0xffffb
    800050a0:	48e080e7          	jalr	1166(ra) # 8000052a <panic>
    return 0;
    800050a4:	84aa                	mv	s1,a0
    800050a6:	b739                	j	80004fb4 <create+0x72>

00000000800050a8 <sys_dup>:
{
    800050a8:	7179                	addi	sp,sp,-48
    800050aa:	f406                	sd	ra,40(sp)
    800050ac:	f022                	sd	s0,32(sp)
    800050ae:	ec26                	sd	s1,24(sp)
    800050b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050b2:	fd840613          	addi	a2,s0,-40
    800050b6:	4581                	li	a1,0
    800050b8:	4501                	li	a0,0
    800050ba:	00000097          	auipc	ra,0x0
    800050be:	dde080e7          	jalr	-546(ra) # 80004e98 <argfd>
    return -1;
    800050c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050c4:	02054363          	bltz	a0,800050ea <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050c8:	fd843503          	ld	a0,-40(s0)
    800050cc:	00000097          	auipc	ra,0x0
    800050d0:	e34080e7          	jalr	-460(ra) # 80004f00 <fdalloc>
    800050d4:	84aa                	mv	s1,a0
    return -1;
    800050d6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050d8:	00054963          	bltz	a0,800050ea <sys_dup+0x42>
  filedup(f);
    800050dc:	fd843503          	ld	a0,-40(s0)
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	36c080e7          	jalr	876(ra) # 8000444c <filedup>
  return fd;
    800050e8:	87a6                	mv	a5,s1
}
    800050ea:	853e                	mv	a0,a5
    800050ec:	70a2                	ld	ra,40(sp)
    800050ee:	7402                	ld	s0,32(sp)
    800050f0:	64e2                	ld	s1,24(sp)
    800050f2:	6145                	addi	sp,sp,48
    800050f4:	8082                	ret

00000000800050f6 <sys_read>:
{
    800050f6:	7179                	addi	sp,sp,-48
    800050f8:	f406                	sd	ra,40(sp)
    800050fa:	f022                	sd	s0,32(sp)
    800050fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050fe:	fe840613          	addi	a2,s0,-24
    80005102:	4581                	li	a1,0
    80005104:	4501                	li	a0,0
    80005106:	00000097          	auipc	ra,0x0
    8000510a:	d92080e7          	jalr	-622(ra) # 80004e98 <argfd>
    return -1;
    8000510e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005110:	04054163          	bltz	a0,80005152 <sys_read+0x5c>
    80005114:	fe440593          	addi	a1,s0,-28
    80005118:	4509                	li	a0,2
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	962080e7          	jalr	-1694(ra) # 80002a7c <argint>
    return -1;
    80005122:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005124:	02054763          	bltz	a0,80005152 <sys_read+0x5c>
    80005128:	fd840593          	addi	a1,s0,-40
    8000512c:	4505                	li	a0,1
    8000512e:	ffffe097          	auipc	ra,0xffffe
    80005132:	970080e7          	jalr	-1680(ra) # 80002a9e <argaddr>
    return -1;
    80005136:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005138:	00054d63          	bltz	a0,80005152 <sys_read+0x5c>
  return fileread(f, p, n);
    8000513c:	fe442603          	lw	a2,-28(s0)
    80005140:	fd843583          	ld	a1,-40(s0)
    80005144:	fe843503          	ld	a0,-24(s0)
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	490080e7          	jalr	1168(ra) # 800045d8 <fileread>
    80005150:	87aa                	mv	a5,a0
}
    80005152:	853e                	mv	a0,a5
    80005154:	70a2                	ld	ra,40(sp)
    80005156:	7402                	ld	s0,32(sp)
    80005158:	6145                	addi	sp,sp,48
    8000515a:	8082                	ret

000000008000515c <sys_write>:
{
    8000515c:	7179                	addi	sp,sp,-48
    8000515e:	f406                	sd	ra,40(sp)
    80005160:	f022                	sd	s0,32(sp)
    80005162:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005164:	fe840613          	addi	a2,s0,-24
    80005168:	4581                	li	a1,0
    8000516a:	4501                	li	a0,0
    8000516c:	00000097          	auipc	ra,0x0
    80005170:	d2c080e7          	jalr	-724(ra) # 80004e98 <argfd>
    return -1;
    80005174:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005176:	04054163          	bltz	a0,800051b8 <sys_write+0x5c>
    8000517a:	fe440593          	addi	a1,s0,-28
    8000517e:	4509                	li	a0,2
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	8fc080e7          	jalr	-1796(ra) # 80002a7c <argint>
    return -1;
    80005188:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000518a:	02054763          	bltz	a0,800051b8 <sys_write+0x5c>
    8000518e:	fd840593          	addi	a1,s0,-40
    80005192:	4505                	li	a0,1
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	90a080e7          	jalr	-1782(ra) # 80002a9e <argaddr>
    return -1;
    8000519c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000519e:	00054d63          	bltz	a0,800051b8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051a2:	fe442603          	lw	a2,-28(s0)
    800051a6:	fd843583          	ld	a1,-40(s0)
    800051aa:	fe843503          	ld	a0,-24(s0)
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	4ec080e7          	jalr	1260(ra) # 8000469a <filewrite>
    800051b6:	87aa                	mv	a5,a0
}
    800051b8:	853e                	mv	a0,a5
    800051ba:	70a2                	ld	ra,40(sp)
    800051bc:	7402                	ld	s0,32(sp)
    800051be:	6145                	addi	sp,sp,48
    800051c0:	8082                	ret

00000000800051c2 <sys_close>:
{
    800051c2:	1101                	addi	sp,sp,-32
    800051c4:	ec06                	sd	ra,24(sp)
    800051c6:	e822                	sd	s0,16(sp)
    800051c8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051ca:	fe040613          	addi	a2,s0,-32
    800051ce:	fec40593          	addi	a1,s0,-20
    800051d2:	4501                	li	a0,0
    800051d4:	00000097          	auipc	ra,0x0
    800051d8:	cc4080e7          	jalr	-828(ra) # 80004e98 <argfd>
    return -1;
    800051dc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051de:	02054463          	bltz	a0,80005206 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	78e080e7          	jalr	1934(ra) # 80001970 <myproc>
    800051ea:	fec42783          	lw	a5,-20(s0)
    800051ee:	07e9                	addi	a5,a5,26
    800051f0:	078e                	slli	a5,a5,0x3
    800051f2:	97aa                	add	a5,a5,a0
    800051f4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051f8:	fe043503          	ld	a0,-32(s0)
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	2a2080e7          	jalr	674(ra) # 8000449e <fileclose>
  return 0;
    80005204:	4781                	li	a5,0
}
    80005206:	853e                	mv	a0,a5
    80005208:	60e2                	ld	ra,24(sp)
    8000520a:	6442                	ld	s0,16(sp)
    8000520c:	6105                	addi	sp,sp,32
    8000520e:	8082                	ret

0000000080005210 <sys_fstat>:
{
    80005210:	1101                	addi	sp,sp,-32
    80005212:	ec06                	sd	ra,24(sp)
    80005214:	e822                	sd	s0,16(sp)
    80005216:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005218:	fe840613          	addi	a2,s0,-24
    8000521c:	4581                	li	a1,0
    8000521e:	4501                	li	a0,0
    80005220:	00000097          	auipc	ra,0x0
    80005224:	c78080e7          	jalr	-904(ra) # 80004e98 <argfd>
    return -1;
    80005228:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000522a:	02054563          	bltz	a0,80005254 <sys_fstat+0x44>
    8000522e:	fe040593          	addi	a1,s0,-32
    80005232:	4505                	li	a0,1
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	86a080e7          	jalr	-1942(ra) # 80002a9e <argaddr>
    return -1;
    8000523c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000523e:	00054b63          	bltz	a0,80005254 <sys_fstat+0x44>
  return filestat(f, st);
    80005242:	fe043583          	ld	a1,-32(s0)
    80005246:	fe843503          	ld	a0,-24(s0)
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	31c080e7          	jalr	796(ra) # 80004566 <filestat>
    80005252:	87aa                	mv	a5,a0
}
    80005254:	853e                	mv	a0,a5
    80005256:	60e2                	ld	ra,24(sp)
    80005258:	6442                	ld	s0,16(sp)
    8000525a:	6105                	addi	sp,sp,32
    8000525c:	8082                	ret

000000008000525e <sys_link>:
{
    8000525e:	7169                	addi	sp,sp,-304
    80005260:	f606                	sd	ra,296(sp)
    80005262:	f222                	sd	s0,288(sp)
    80005264:	ee26                	sd	s1,280(sp)
    80005266:	ea4a                	sd	s2,272(sp)
    80005268:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000526a:	08000613          	li	a2,128
    8000526e:	ed040593          	addi	a1,s0,-304
    80005272:	4501                	li	a0,0
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	84c080e7          	jalr	-1972(ra) # 80002ac0 <argstr>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000527e:	10054e63          	bltz	a0,8000539a <sys_link+0x13c>
    80005282:	08000613          	li	a2,128
    80005286:	f5040593          	addi	a1,s0,-176
    8000528a:	4505                	li	a0,1
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	834080e7          	jalr	-1996(ra) # 80002ac0 <argstr>
    return -1;
    80005294:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005296:	10054263          	bltz	a0,8000539a <sys_link+0x13c>
  begin_op();
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	d38080e7          	jalr	-712(ra) # 80003fd2 <begin_op>
  if((ip = namei(old)) == 0){
    800052a2:	ed040513          	addi	a0,s0,-304
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	b0c080e7          	jalr	-1268(ra) # 80003db2 <namei>
    800052ae:	84aa                	mv	s1,a0
    800052b0:	c551                	beqz	a0,8000533c <sys_link+0xde>
  ilock(ip);
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	34a080e7          	jalr	842(ra) # 800035fc <ilock>
  if(ip->type == T_DIR){
    800052ba:	04449703          	lh	a4,68(s1)
    800052be:	4785                	li	a5,1
    800052c0:	08f70463          	beq	a4,a5,80005348 <sys_link+0xea>
  ip->nlink++;
    800052c4:	04a4d783          	lhu	a5,74(s1)
    800052c8:	2785                	addiw	a5,a5,1
    800052ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052ce:	8526                	mv	a0,s1
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	262080e7          	jalr	610(ra) # 80003532 <iupdate>
  iunlock(ip);
    800052d8:	8526                	mv	a0,s1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	3e4080e7          	jalr	996(ra) # 800036be <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052e2:	fd040593          	addi	a1,s0,-48
    800052e6:	f5040513          	addi	a0,s0,-176
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	ae6080e7          	jalr	-1306(ra) # 80003dd0 <nameiparent>
    800052f2:	892a                	mv	s2,a0
    800052f4:	c935                	beqz	a0,80005368 <sys_link+0x10a>
  ilock(dp);
    800052f6:	ffffe097          	auipc	ra,0xffffe
    800052fa:	306080e7          	jalr	774(ra) # 800035fc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052fe:	00092703          	lw	a4,0(s2)
    80005302:	409c                	lw	a5,0(s1)
    80005304:	04f71d63          	bne	a4,a5,8000535e <sys_link+0x100>
    80005308:	40d0                	lw	a2,4(s1)
    8000530a:	fd040593          	addi	a1,s0,-48
    8000530e:	854a                	mv	a0,s2
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	9e0080e7          	jalr	-1568(ra) # 80003cf0 <dirlink>
    80005318:	04054363          	bltz	a0,8000535e <sys_link+0x100>
  iunlockput(dp);
    8000531c:	854a                	mv	a0,s2
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	540080e7          	jalr	1344(ra) # 8000385e <iunlockput>
  iput(ip);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	48e080e7          	jalr	1166(ra) # 800037b6 <iput>
  end_op();
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	d22080e7          	jalr	-734(ra) # 80004052 <end_op>
  return 0;
    80005338:	4781                	li	a5,0
    8000533a:	a085                	j	8000539a <sys_link+0x13c>
    end_op();
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	d16080e7          	jalr	-746(ra) # 80004052 <end_op>
    return -1;
    80005344:	57fd                	li	a5,-1
    80005346:	a891                	j	8000539a <sys_link+0x13c>
    iunlockput(ip);
    80005348:	8526                	mv	a0,s1
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	514080e7          	jalr	1300(ra) # 8000385e <iunlockput>
    end_op();
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	d00080e7          	jalr	-768(ra) # 80004052 <end_op>
    return -1;
    8000535a:	57fd                	li	a5,-1
    8000535c:	a83d                	j	8000539a <sys_link+0x13c>
    iunlockput(dp);
    8000535e:	854a                	mv	a0,s2
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	4fe080e7          	jalr	1278(ra) # 8000385e <iunlockput>
  ilock(ip);
    80005368:	8526                	mv	a0,s1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	292080e7          	jalr	658(ra) # 800035fc <ilock>
  ip->nlink--;
    80005372:	04a4d783          	lhu	a5,74(s1)
    80005376:	37fd                	addiw	a5,a5,-1
    80005378:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	1b4080e7          	jalr	436(ra) # 80003532 <iupdate>
  iunlockput(ip);
    80005386:	8526                	mv	a0,s1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	4d6080e7          	jalr	1238(ra) # 8000385e <iunlockput>
  end_op();
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	cc2080e7          	jalr	-830(ra) # 80004052 <end_op>
  return -1;
    80005398:	57fd                	li	a5,-1
}
    8000539a:	853e                	mv	a0,a5
    8000539c:	70b2                	ld	ra,296(sp)
    8000539e:	7412                	ld	s0,288(sp)
    800053a0:	64f2                	ld	s1,280(sp)
    800053a2:	6952                	ld	s2,272(sp)
    800053a4:	6155                	addi	sp,sp,304
    800053a6:	8082                	ret

00000000800053a8 <sys_unlink>:
{
    800053a8:	7151                	addi	sp,sp,-240
    800053aa:	f586                	sd	ra,232(sp)
    800053ac:	f1a2                	sd	s0,224(sp)
    800053ae:	eda6                	sd	s1,216(sp)
    800053b0:	e9ca                	sd	s2,208(sp)
    800053b2:	e5ce                	sd	s3,200(sp)
    800053b4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053b6:	08000613          	li	a2,128
    800053ba:	f3040593          	addi	a1,s0,-208
    800053be:	4501                	li	a0,0
    800053c0:	ffffd097          	auipc	ra,0xffffd
    800053c4:	700080e7          	jalr	1792(ra) # 80002ac0 <argstr>
    800053c8:	18054163          	bltz	a0,8000554a <sys_unlink+0x1a2>
  begin_op();
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	c06080e7          	jalr	-1018(ra) # 80003fd2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053d4:	fb040593          	addi	a1,s0,-80
    800053d8:	f3040513          	addi	a0,s0,-208
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	9f4080e7          	jalr	-1548(ra) # 80003dd0 <nameiparent>
    800053e4:	84aa                	mv	s1,a0
    800053e6:	c979                	beqz	a0,800054bc <sys_unlink+0x114>
  ilock(dp);
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	214080e7          	jalr	532(ra) # 800035fc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053f0:	00003597          	auipc	a1,0x3
    800053f4:	2f058593          	addi	a1,a1,752 # 800086e0 <syscalls+0x2b0>
    800053f8:	fb040513          	addi	a0,s0,-80
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	6ca080e7          	jalr	1738(ra) # 80003ac6 <namecmp>
    80005404:	14050a63          	beqz	a0,80005558 <sys_unlink+0x1b0>
    80005408:	00003597          	auipc	a1,0x3
    8000540c:	2e058593          	addi	a1,a1,736 # 800086e8 <syscalls+0x2b8>
    80005410:	fb040513          	addi	a0,s0,-80
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	6b2080e7          	jalr	1714(ra) # 80003ac6 <namecmp>
    8000541c:	12050e63          	beqz	a0,80005558 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005420:	f2c40613          	addi	a2,s0,-212
    80005424:	fb040593          	addi	a1,s0,-80
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	6b6080e7          	jalr	1718(ra) # 80003ae0 <dirlookup>
    80005432:	892a                	mv	s2,a0
    80005434:	12050263          	beqz	a0,80005558 <sys_unlink+0x1b0>
  ilock(ip);
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	1c4080e7          	jalr	452(ra) # 800035fc <ilock>
  if(ip->nlink < 1)
    80005440:	04a91783          	lh	a5,74(s2)
    80005444:	08f05263          	blez	a5,800054c8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005448:	04491703          	lh	a4,68(s2)
    8000544c:	4785                	li	a5,1
    8000544e:	08f70563          	beq	a4,a5,800054d8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005452:	4641                	li	a2,16
    80005454:	4581                	li	a1,0
    80005456:	fc040513          	addi	a0,s0,-64
    8000545a:	ffffc097          	auipc	ra,0xffffc
    8000545e:	864080e7          	jalr	-1948(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005462:	4741                	li	a4,16
    80005464:	f2c42683          	lw	a3,-212(s0)
    80005468:	fc040613          	addi	a2,s0,-64
    8000546c:	4581                	li	a1,0
    8000546e:	8526                	mv	a0,s1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	538080e7          	jalr	1336(ra) # 800039a8 <writei>
    80005478:	47c1                	li	a5,16
    8000547a:	0af51563          	bne	a0,a5,80005524 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000547e:	04491703          	lh	a4,68(s2)
    80005482:	4785                	li	a5,1
    80005484:	0af70863          	beq	a4,a5,80005534 <sys_unlink+0x18c>
  iunlockput(dp);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	3d4080e7          	jalr	980(ra) # 8000385e <iunlockput>
  ip->nlink--;
    80005492:	04a95783          	lhu	a5,74(s2)
    80005496:	37fd                	addiw	a5,a5,-1
    80005498:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000549c:	854a                	mv	a0,s2
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	094080e7          	jalr	148(ra) # 80003532 <iupdate>
  iunlockput(ip);
    800054a6:	854a                	mv	a0,s2
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	3b6080e7          	jalr	950(ra) # 8000385e <iunlockput>
  end_op();
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	ba2080e7          	jalr	-1118(ra) # 80004052 <end_op>
  return 0;
    800054b8:	4501                	li	a0,0
    800054ba:	a84d                	j	8000556c <sys_unlink+0x1c4>
    end_op();
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	b96080e7          	jalr	-1130(ra) # 80004052 <end_op>
    return -1;
    800054c4:	557d                	li	a0,-1
    800054c6:	a05d                	j	8000556c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054c8:	00003517          	auipc	a0,0x3
    800054cc:	24850513          	addi	a0,a0,584 # 80008710 <syscalls+0x2e0>
    800054d0:	ffffb097          	auipc	ra,0xffffb
    800054d4:	05a080e7          	jalr	90(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054d8:	04c92703          	lw	a4,76(s2)
    800054dc:	02000793          	li	a5,32
    800054e0:	f6e7f9e3          	bgeu	a5,a4,80005452 <sys_unlink+0xaa>
    800054e4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054e8:	4741                	li	a4,16
    800054ea:	86ce                	mv	a3,s3
    800054ec:	f1840613          	addi	a2,s0,-232
    800054f0:	4581                	li	a1,0
    800054f2:	854a                	mv	a0,s2
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	3bc080e7          	jalr	956(ra) # 800038b0 <readi>
    800054fc:	47c1                	li	a5,16
    800054fe:	00f51b63          	bne	a0,a5,80005514 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005502:	f1845783          	lhu	a5,-232(s0)
    80005506:	e7a1                	bnez	a5,8000554e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005508:	29c1                	addiw	s3,s3,16
    8000550a:	04c92783          	lw	a5,76(s2)
    8000550e:	fcf9ede3          	bltu	s3,a5,800054e8 <sys_unlink+0x140>
    80005512:	b781                	j	80005452 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005514:	00003517          	auipc	a0,0x3
    80005518:	21450513          	addi	a0,a0,532 # 80008728 <syscalls+0x2f8>
    8000551c:	ffffb097          	auipc	ra,0xffffb
    80005520:	00e080e7          	jalr	14(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005524:	00003517          	auipc	a0,0x3
    80005528:	21c50513          	addi	a0,a0,540 # 80008740 <syscalls+0x310>
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	ffe080e7          	jalr	-2(ra) # 8000052a <panic>
    dp->nlink--;
    80005534:	04a4d783          	lhu	a5,74(s1)
    80005538:	37fd                	addiw	a5,a5,-1
    8000553a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	ff2080e7          	jalr	-14(ra) # 80003532 <iupdate>
    80005548:	b781                	j	80005488 <sys_unlink+0xe0>
    return -1;
    8000554a:	557d                	li	a0,-1
    8000554c:	a005                	j	8000556c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000554e:	854a                	mv	a0,s2
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	30e080e7          	jalr	782(ra) # 8000385e <iunlockput>
  iunlockput(dp);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	304080e7          	jalr	772(ra) # 8000385e <iunlockput>
  end_op();
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	af0080e7          	jalr	-1296(ra) # 80004052 <end_op>
  return -1;
    8000556a:	557d                	li	a0,-1
}
    8000556c:	70ae                	ld	ra,232(sp)
    8000556e:	740e                	ld	s0,224(sp)
    80005570:	64ee                	ld	s1,216(sp)
    80005572:	694e                	ld	s2,208(sp)
    80005574:	69ae                	ld	s3,200(sp)
    80005576:	616d                	addi	sp,sp,240
    80005578:	8082                	ret

000000008000557a <sys_open>:

uint64
sys_open(void)
{
    8000557a:	7131                	addi	sp,sp,-192
    8000557c:	fd06                	sd	ra,184(sp)
    8000557e:	f922                	sd	s0,176(sp)
    80005580:	f526                	sd	s1,168(sp)
    80005582:	f14a                	sd	s2,160(sp)
    80005584:	ed4e                	sd	s3,152(sp)
    80005586:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005588:	08000613          	li	a2,128
    8000558c:	f5040593          	addi	a1,s0,-176
    80005590:	4501                	li	a0,0
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	52e080e7          	jalr	1326(ra) # 80002ac0 <argstr>
    return -1;
    8000559a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000559c:	0c054163          	bltz	a0,8000565e <sys_open+0xe4>
    800055a0:	f4c40593          	addi	a1,s0,-180
    800055a4:	4505                	li	a0,1
    800055a6:	ffffd097          	auipc	ra,0xffffd
    800055aa:	4d6080e7          	jalr	1238(ra) # 80002a7c <argint>
    800055ae:	0a054863          	bltz	a0,8000565e <sys_open+0xe4>

  begin_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	a20080e7          	jalr	-1504(ra) # 80003fd2 <begin_op>

  if(omode & O_CREATE){
    800055ba:	f4c42783          	lw	a5,-180(s0)
    800055be:	2007f793          	andi	a5,a5,512
    800055c2:	cbdd                	beqz	a5,80005678 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055c4:	4681                	li	a3,0
    800055c6:	4601                	li	a2,0
    800055c8:	4589                	li	a1,2
    800055ca:	f5040513          	addi	a0,s0,-176
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	974080e7          	jalr	-1676(ra) # 80004f42 <create>
    800055d6:	892a                	mv	s2,a0
    if(ip == 0){
    800055d8:	c959                	beqz	a0,8000566e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055da:	04491703          	lh	a4,68(s2)
    800055de:	478d                	li	a5,3
    800055e0:	00f71763          	bne	a4,a5,800055ee <sys_open+0x74>
    800055e4:	04695703          	lhu	a4,70(s2)
    800055e8:	47a5                	li	a5,9
    800055ea:	0ce7ec63          	bltu	a5,a4,800056c2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	df4080e7          	jalr	-524(ra) # 800043e2 <filealloc>
    800055f6:	89aa                	mv	s3,a0
    800055f8:	10050263          	beqz	a0,800056fc <sys_open+0x182>
    800055fc:	00000097          	auipc	ra,0x0
    80005600:	904080e7          	jalr	-1788(ra) # 80004f00 <fdalloc>
    80005604:	84aa                	mv	s1,a0
    80005606:	0e054663          	bltz	a0,800056f2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000560a:	04491703          	lh	a4,68(s2)
    8000560e:	478d                	li	a5,3
    80005610:	0cf70463          	beq	a4,a5,800056d8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005614:	4789                	li	a5,2
    80005616:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000561a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000561e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005622:	f4c42783          	lw	a5,-180(s0)
    80005626:	0017c713          	xori	a4,a5,1
    8000562a:	8b05                	andi	a4,a4,1
    8000562c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005630:	0037f713          	andi	a4,a5,3
    80005634:	00e03733          	snez	a4,a4
    80005638:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000563c:	4007f793          	andi	a5,a5,1024
    80005640:	c791                	beqz	a5,8000564c <sys_open+0xd2>
    80005642:	04491703          	lh	a4,68(s2)
    80005646:	4789                	li	a5,2
    80005648:	08f70f63          	beq	a4,a5,800056e6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	070080e7          	jalr	112(ra) # 800036be <iunlock>
  end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	9fc080e7          	jalr	-1540(ra) # 80004052 <end_op>

  return fd;
}
    8000565e:	8526                	mv	a0,s1
    80005660:	70ea                	ld	ra,184(sp)
    80005662:	744a                	ld	s0,176(sp)
    80005664:	74aa                	ld	s1,168(sp)
    80005666:	790a                	ld	s2,160(sp)
    80005668:	69ea                	ld	s3,152(sp)
    8000566a:	6129                	addi	sp,sp,192
    8000566c:	8082                	ret
      end_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	9e4080e7          	jalr	-1564(ra) # 80004052 <end_op>
      return -1;
    80005676:	b7e5                	j	8000565e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005678:	f5040513          	addi	a0,s0,-176
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	736080e7          	jalr	1846(ra) # 80003db2 <namei>
    80005684:	892a                	mv	s2,a0
    80005686:	c905                	beqz	a0,800056b6 <sys_open+0x13c>
    ilock(ip);
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	f74080e7          	jalr	-140(ra) # 800035fc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005690:	04491703          	lh	a4,68(s2)
    80005694:	4785                	li	a5,1
    80005696:	f4f712e3          	bne	a4,a5,800055da <sys_open+0x60>
    8000569a:	f4c42783          	lw	a5,-180(s0)
    8000569e:	dba1                	beqz	a5,800055ee <sys_open+0x74>
      iunlockput(ip);
    800056a0:	854a                	mv	a0,s2
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	1bc080e7          	jalr	444(ra) # 8000385e <iunlockput>
      end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	9a8080e7          	jalr	-1624(ra) # 80004052 <end_op>
      return -1;
    800056b2:	54fd                	li	s1,-1
    800056b4:	b76d                	j	8000565e <sys_open+0xe4>
      end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	99c080e7          	jalr	-1636(ra) # 80004052 <end_op>
      return -1;
    800056be:	54fd                	li	s1,-1
    800056c0:	bf79                	j	8000565e <sys_open+0xe4>
    iunlockput(ip);
    800056c2:	854a                	mv	a0,s2
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	19a080e7          	jalr	410(ra) # 8000385e <iunlockput>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	986080e7          	jalr	-1658(ra) # 80004052 <end_op>
    return -1;
    800056d4:	54fd                	li	s1,-1
    800056d6:	b761                	j	8000565e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056d8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056dc:	04691783          	lh	a5,70(s2)
    800056e0:	02f99223          	sh	a5,36(s3)
    800056e4:	bf2d                	j	8000561e <sys_open+0xa4>
    itrunc(ip);
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	022080e7          	jalr	34(ra) # 8000370a <itrunc>
    800056f0:	bfb1                	j	8000564c <sys_open+0xd2>
      fileclose(f);
    800056f2:	854e                	mv	a0,s3
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	daa080e7          	jalr	-598(ra) # 8000449e <fileclose>
    iunlockput(ip);
    800056fc:	854a                	mv	a0,s2
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	160080e7          	jalr	352(ra) # 8000385e <iunlockput>
    end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	94c080e7          	jalr	-1716(ra) # 80004052 <end_op>
    return -1;
    8000570e:	54fd                	li	s1,-1
    80005710:	b7b9                	j	8000565e <sys_open+0xe4>

0000000080005712 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005712:	7175                	addi	sp,sp,-144
    80005714:	e506                	sd	ra,136(sp)
    80005716:	e122                	sd	s0,128(sp)
    80005718:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	8b8080e7          	jalr	-1864(ra) # 80003fd2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005722:	08000613          	li	a2,128
    80005726:	f7040593          	addi	a1,s0,-144
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	394080e7          	jalr	916(ra) # 80002ac0 <argstr>
    80005734:	02054963          	bltz	a0,80005766 <sys_mkdir+0x54>
    80005738:	4681                	li	a3,0
    8000573a:	4601                	li	a2,0
    8000573c:	4585                	li	a1,1
    8000573e:	f7040513          	addi	a0,s0,-144
    80005742:	00000097          	auipc	ra,0x0
    80005746:	800080e7          	jalr	-2048(ra) # 80004f42 <create>
    8000574a:	cd11                	beqz	a0,80005766 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	112080e7          	jalr	274(ra) # 8000385e <iunlockput>
  end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	8fe080e7          	jalr	-1794(ra) # 80004052 <end_op>
  return 0;
    8000575c:	4501                	li	a0,0
}
    8000575e:	60aa                	ld	ra,136(sp)
    80005760:	640a                	ld	s0,128(sp)
    80005762:	6149                	addi	sp,sp,144
    80005764:	8082                	ret
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	8ec080e7          	jalr	-1812(ra) # 80004052 <end_op>
    return -1;
    8000576e:	557d                	li	a0,-1
    80005770:	b7fd                	j	8000575e <sys_mkdir+0x4c>

0000000080005772 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005772:	7135                	addi	sp,sp,-160
    80005774:	ed06                	sd	ra,152(sp)
    80005776:	e922                	sd	s0,144(sp)
    80005778:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	858080e7          	jalr	-1960(ra) # 80003fd2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005782:	08000613          	li	a2,128
    80005786:	f7040593          	addi	a1,s0,-144
    8000578a:	4501                	li	a0,0
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	334080e7          	jalr	820(ra) # 80002ac0 <argstr>
    80005794:	04054a63          	bltz	a0,800057e8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005798:	f6c40593          	addi	a1,s0,-148
    8000579c:	4505                	li	a0,1
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	2de080e7          	jalr	734(ra) # 80002a7c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057a6:	04054163          	bltz	a0,800057e8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057aa:	f6840593          	addi	a1,s0,-152
    800057ae:	4509                	li	a0,2
    800057b0:	ffffd097          	auipc	ra,0xffffd
    800057b4:	2cc080e7          	jalr	716(ra) # 80002a7c <argint>
     argint(1, &major) < 0 ||
    800057b8:	02054863          	bltz	a0,800057e8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057bc:	f6841683          	lh	a3,-152(s0)
    800057c0:	f6c41603          	lh	a2,-148(s0)
    800057c4:	458d                	li	a1,3
    800057c6:	f7040513          	addi	a0,s0,-144
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	778080e7          	jalr	1912(ra) # 80004f42 <create>
     argint(2, &minor) < 0 ||
    800057d2:	c919                	beqz	a0,800057e8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	08a080e7          	jalr	138(ra) # 8000385e <iunlockput>
  end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	876080e7          	jalr	-1930(ra) # 80004052 <end_op>
  return 0;
    800057e4:	4501                	li	a0,0
    800057e6:	a031                	j	800057f2 <sys_mknod+0x80>
    end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	86a080e7          	jalr	-1942(ra) # 80004052 <end_op>
    return -1;
    800057f0:	557d                	li	a0,-1
}
    800057f2:	60ea                	ld	ra,152(sp)
    800057f4:	644a                	ld	s0,144(sp)
    800057f6:	610d                	addi	sp,sp,160
    800057f8:	8082                	ret

00000000800057fa <sys_chdir>:

uint64
sys_chdir(void)
{
    800057fa:	7135                	addi	sp,sp,-160
    800057fc:	ed06                	sd	ra,152(sp)
    800057fe:	e922                	sd	s0,144(sp)
    80005800:	e526                	sd	s1,136(sp)
    80005802:	e14a                	sd	s2,128(sp)
    80005804:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005806:	ffffc097          	auipc	ra,0xffffc
    8000580a:	16a080e7          	jalr	362(ra) # 80001970 <myproc>
    8000580e:	892a                	mv	s2,a0
  
  begin_op();
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	7c2080e7          	jalr	1986(ra) # 80003fd2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005818:	08000613          	li	a2,128
    8000581c:	f6040593          	addi	a1,s0,-160
    80005820:	4501                	li	a0,0
    80005822:	ffffd097          	auipc	ra,0xffffd
    80005826:	29e080e7          	jalr	670(ra) # 80002ac0 <argstr>
    8000582a:	04054b63          	bltz	a0,80005880 <sys_chdir+0x86>
    8000582e:	f6040513          	addi	a0,s0,-160
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	580080e7          	jalr	1408(ra) # 80003db2 <namei>
    8000583a:	84aa                	mv	s1,a0
    8000583c:	c131                	beqz	a0,80005880 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	dbe080e7          	jalr	-578(ra) # 800035fc <ilock>
  if(ip->type != T_DIR){
    80005846:	04449703          	lh	a4,68(s1)
    8000584a:	4785                	li	a5,1
    8000584c:	04f71063          	bne	a4,a5,8000588c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	e6c080e7          	jalr	-404(ra) # 800036be <iunlock>
  iput(p->cwd);
    8000585a:	15093503          	ld	a0,336(s2)
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	f58080e7          	jalr	-168(ra) # 800037b6 <iput>
  end_op();
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	7ec080e7          	jalr	2028(ra) # 80004052 <end_op>
  p->cwd = ip;
    8000586e:	14993823          	sd	s1,336(s2)
  return 0;
    80005872:	4501                	li	a0,0
}
    80005874:	60ea                	ld	ra,152(sp)
    80005876:	644a                	ld	s0,144(sp)
    80005878:	64aa                	ld	s1,136(sp)
    8000587a:	690a                	ld	s2,128(sp)
    8000587c:	610d                	addi	sp,sp,160
    8000587e:	8082                	ret
    end_op();
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	7d2080e7          	jalr	2002(ra) # 80004052 <end_op>
    return -1;
    80005888:	557d                	li	a0,-1
    8000588a:	b7ed                	j	80005874 <sys_chdir+0x7a>
    iunlockput(ip);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	fd0080e7          	jalr	-48(ra) # 8000385e <iunlockput>
    end_op();
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	7bc080e7          	jalr	1980(ra) # 80004052 <end_op>
    return -1;
    8000589e:	557d                	li	a0,-1
    800058a0:	bfd1                	j	80005874 <sys_chdir+0x7a>

00000000800058a2 <sys_exec>:

uint64
sys_exec(void)
{
    800058a2:	7145                	addi	sp,sp,-464
    800058a4:	e786                	sd	ra,456(sp)
    800058a6:	e3a2                	sd	s0,448(sp)
    800058a8:	ff26                	sd	s1,440(sp)
    800058aa:	fb4a                	sd	s2,432(sp)
    800058ac:	f74e                	sd	s3,424(sp)
    800058ae:	f352                	sd	s4,416(sp)
    800058b0:	ef56                	sd	s5,408(sp)
    800058b2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058b4:	08000613          	li	a2,128
    800058b8:	f4040593          	addi	a1,s0,-192
    800058bc:	4501                	li	a0,0
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	202080e7          	jalr	514(ra) # 80002ac0 <argstr>
    return -1;
    800058c6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058c8:	0c054a63          	bltz	a0,8000599c <sys_exec+0xfa>
    800058cc:	e3840593          	addi	a1,s0,-456
    800058d0:	4505                	li	a0,1
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	1cc080e7          	jalr	460(ra) # 80002a9e <argaddr>
    800058da:	0c054163          	bltz	a0,8000599c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058de:	10000613          	li	a2,256
    800058e2:	4581                	li	a1,0
    800058e4:	e4040513          	addi	a0,s0,-448
    800058e8:	ffffb097          	auipc	ra,0xffffb
    800058ec:	3d6080e7          	jalr	982(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058f0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058f4:	89a6                	mv	s3,s1
    800058f6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058f8:	02000a13          	li	s4,32
    800058fc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005900:	00391793          	slli	a5,s2,0x3
    80005904:	e3040593          	addi	a1,s0,-464
    80005908:	e3843503          	ld	a0,-456(s0)
    8000590c:	953e                	add	a0,a0,a5
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	0d4080e7          	jalr	212(ra) # 800029e2 <fetchaddr>
    80005916:	02054a63          	bltz	a0,8000594a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000591a:	e3043783          	ld	a5,-464(s0)
    8000591e:	c3b9                	beqz	a5,80005964 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005920:	ffffb097          	auipc	ra,0xffffb
    80005924:	1b2080e7          	jalr	434(ra) # 80000ad2 <kalloc>
    80005928:	85aa                	mv	a1,a0
    8000592a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000592e:	cd11                	beqz	a0,8000594a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005930:	6605                	lui	a2,0x1
    80005932:	e3043503          	ld	a0,-464(s0)
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	0fe080e7          	jalr	254(ra) # 80002a34 <fetchstr>
    8000593e:	00054663          	bltz	a0,8000594a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005942:	0905                	addi	s2,s2,1
    80005944:	09a1                	addi	s3,s3,8
    80005946:	fb491be3          	bne	s2,s4,800058fc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000594a:	10048913          	addi	s2,s1,256
    8000594e:	6088                	ld	a0,0(s1)
    80005950:	c529                	beqz	a0,8000599a <sys_exec+0xf8>
    kfree(argv[i]);
    80005952:	ffffb097          	auipc	ra,0xffffb
    80005956:	084080e7          	jalr	132(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000595a:	04a1                	addi	s1,s1,8
    8000595c:	ff2499e3          	bne	s1,s2,8000594e <sys_exec+0xac>
  return -1;
    80005960:	597d                	li	s2,-1
    80005962:	a82d                	j	8000599c <sys_exec+0xfa>
      argv[i] = 0;
    80005964:	0a8e                	slli	s5,s5,0x3
    80005966:	fc040793          	addi	a5,s0,-64
    8000596a:	9abe                	add	s5,s5,a5
    8000596c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005970:	e4040593          	addi	a1,s0,-448
    80005974:	f4040513          	addi	a0,s0,-192
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	178080e7          	jalr	376(ra) # 80004af0 <exec>
    80005980:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005982:	10048993          	addi	s3,s1,256
    80005986:	6088                	ld	a0,0(s1)
    80005988:	c911                	beqz	a0,8000599c <sys_exec+0xfa>
    kfree(argv[i]);
    8000598a:	ffffb097          	auipc	ra,0xffffb
    8000598e:	04c080e7          	jalr	76(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005992:	04a1                	addi	s1,s1,8
    80005994:	ff3499e3          	bne	s1,s3,80005986 <sys_exec+0xe4>
    80005998:	a011                	j	8000599c <sys_exec+0xfa>
  return -1;
    8000599a:	597d                	li	s2,-1
}
    8000599c:	854a                	mv	a0,s2
    8000599e:	60be                	ld	ra,456(sp)
    800059a0:	641e                	ld	s0,448(sp)
    800059a2:	74fa                	ld	s1,440(sp)
    800059a4:	795a                	ld	s2,432(sp)
    800059a6:	79ba                	ld	s3,424(sp)
    800059a8:	7a1a                	ld	s4,416(sp)
    800059aa:	6afa                	ld	s5,408(sp)
    800059ac:	6179                	addi	sp,sp,464
    800059ae:	8082                	ret

00000000800059b0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059b0:	7139                	addi	sp,sp,-64
    800059b2:	fc06                	sd	ra,56(sp)
    800059b4:	f822                	sd	s0,48(sp)
    800059b6:	f426                	sd	s1,40(sp)
    800059b8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059ba:	ffffc097          	auipc	ra,0xffffc
    800059be:	fb6080e7          	jalr	-74(ra) # 80001970 <myproc>
    800059c2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059c4:	fd840593          	addi	a1,s0,-40
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	0d4080e7          	jalr	212(ra) # 80002a9e <argaddr>
    return -1;
    800059d2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059d4:	0e054063          	bltz	a0,80005ab4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059d8:	fc840593          	addi	a1,s0,-56
    800059dc:	fd040513          	addi	a0,s0,-48
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	dee080e7          	jalr	-530(ra) # 800047ce <pipealloc>
    return -1;
    800059e8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059ea:	0c054563          	bltz	a0,80005ab4 <sys_pipe+0x104>
  fd0 = -1;
    800059ee:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059f2:	fd043503          	ld	a0,-48(s0)
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	50a080e7          	jalr	1290(ra) # 80004f00 <fdalloc>
    800059fe:	fca42223          	sw	a0,-60(s0)
    80005a02:	08054c63          	bltz	a0,80005a9a <sys_pipe+0xea>
    80005a06:	fc843503          	ld	a0,-56(s0)
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	4f6080e7          	jalr	1270(ra) # 80004f00 <fdalloc>
    80005a12:	fca42023          	sw	a0,-64(s0)
    80005a16:	06054863          	bltz	a0,80005a86 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a1a:	4691                	li	a3,4
    80005a1c:	fc440613          	addi	a2,s0,-60
    80005a20:	fd843583          	ld	a1,-40(s0)
    80005a24:	68a8                	ld	a0,80(s1)
    80005a26:	ffffc097          	auipc	ra,0xffffc
    80005a2a:	c0a080e7          	jalr	-1014(ra) # 80001630 <copyout>
    80005a2e:	02054063          	bltz	a0,80005a4e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a32:	4691                	li	a3,4
    80005a34:	fc040613          	addi	a2,s0,-64
    80005a38:	fd843583          	ld	a1,-40(s0)
    80005a3c:	0591                	addi	a1,a1,4
    80005a3e:	68a8                	ld	a0,80(s1)
    80005a40:	ffffc097          	auipc	ra,0xffffc
    80005a44:	bf0080e7          	jalr	-1040(ra) # 80001630 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a48:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a4a:	06055563          	bgez	a0,80005ab4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a4e:	fc442783          	lw	a5,-60(s0)
    80005a52:	07e9                	addi	a5,a5,26
    80005a54:	078e                	slli	a5,a5,0x3
    80005a56:	97a6                	add	a5,a5,s1
    80005a58:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a5c:	fc042503          	lw	a0,-64(s0)
    80005a60:	0569                	addi	a0,a0,26
    80005a62:	050e                	slli	a0,a0,0x3
    80005a64:	9526                	add	a0,a0,s1
    80005a66:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a6a:	fd043503          	ld	a0,-48(s0)
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	a30080e7          	jalr	-1488(ra) # 8000449e <fileclose>
    fileclose(wf);
    80005a76:	fc843503          	ld	a0,-56(s0)
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	a24080e7          	jalr	-1500(ra) # 8000449e <fileclose>
    return -1;
    80005a82:	57fd                	li	a5,-1
    80005a84:	a805                	j	80005ab4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a86:	fc442783          	lw	a5,-60(s0)
    80005a8a:	0007c863          	bltz	a5,80005a9a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a8e:	01a78513          	addi	a0,a5,26
    80005a92:	050e                	slli	a0,a0,0x3
    80005a94:	9526                	add	a0,a0,s1
    80005a96:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a9a:	fd043503          	ld	a0,-48(s0)
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	a00080e7          	jalr	-1536(ra) # 8000449e <fileclose>
    fileclose(wf);
    80005aa6:	fc843503          	ld	a0,-56(s0)
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	9f4080e7          	jalr	-1548(ra) # 8000449e <fileclose>
    return -1;
    80005ab2:	57fd                	li	a5,-1
}
    80005ab4:	853e                	mv	a0,a5
    80005ab6:	70e2                	ld	ra,56(sp)
    80005ab8:	7442                	ld	s0,48(sp)
    80005aba:	74a2                	ld	s1,40(sp)
    80005abc:	6121                	addi	sp,sp,64
    80005abe:	8082                	ret

0000000080005ac0 <kernelvec>:
    80005ac0:	7111                	addi	sp,sp,-256
    80005ac2:	e006                	sd	ra,0(sp)
    80005ac4:	e40a                	sd	sp,8(sp)
    80005ac6:	e80e                	sd	gp,16(sp)
    80005ac8:	ec12                	sd	tp,24(sp)
    80005aca:	f016                	sd	t0,32(sp)
    80005acc:	f41a                	sd	t1,40(sp)
    80005ace:	f81e                	sd	t2,48(sp)
    80005ad0:	fc22                	sd	s0,56(sp)
    80005ad2:	e0a6                	sd	s1,64(sp)
    80005ad4:	e4aa                	sd	a0,72(sp)
    80005ad6:	e8ae                	sd	a1,80(sp)
    80005ad8:	ecb2                	sd	a2,88(sp)
    80005ada:	f0b6                	sd	a3,96(sp)
    80005adc:	f4ba                	sd	a4,104(sp)
    80005ade:	f8be                	sd	a5,112(sp)
    80005ae0:	fcc2                	sd	a6,120(sp)
    80005ae2:	e146                	sd	a7,128(sp)
    80005ae4:	e54a                	sd	s2,136(sp)
    80005ae6:	e94e                	sd	s3,144(sp)
    80005ae8:	ed52                	sd	s4,152(sp)
    80005aea:	f156                	sd	s5,160(sp)
    80005aec:	f55a                	sd	s6,168(sp)
    80005aee:	f95e                	sd	s7,176(sp)
    80005af0:	fd62                	sd	s8,184(sp)
    80005af2:	e1e6                	sd	s9,192(sp)
    80005af4:	e5ea                	sd	s10,200(sp)
    80005af6:	e9ee                	sd	s11,208(sp)
    80005af8:	edf2                	sd	t3,216(sp)
    80005afa:	f1f6                	sd	t4,224(sp)
    80005afc:	f5fa                	sd	t5,232(sp)
    80005afe:	f9fe                	sd	t6,240(sp)
    80005b00:	daffc0ef          	jal	ra,800028ae <kerneltrap>
    80005b04:	6082                	ld	ra,0(sp)
    80005b06:	6122                	ld	sp,8(sp)
    80005b08:	61c2                	ld	gp,16(sp)
    80005b0a:	7282                	ld	t0,32(sp)
    80005b0c:	7322                	ld	t1,40(sp)
    80005b0e:	73c2                	ld	t2,48(sp)
    80005b10:	7462                	ld	s0,56(sp)
    80005b12:	6486                	ld	s1,64(sp)
    80005b14:	6526                	ld	a0,72(sp)
    80005b16:	65c6                	ld	a1,80(sp)
    80005b18:	6666                	ld	a2,88(sp)
    80005b1a:	7686                	ld	a3,96(sp)
    80005b1c:	7726                	ld	a4,104(sp)
    80005b1e:	77c6                	ld	a5,112(sp)
    80005b20:	7866                	ld	a6,120(sp)
    80005b22:	688a                	ld	a7,128(sp)
    80005b24:	692a                	ld	s2,136(sp)
    80005b26:	69ca                	ld	s3,144(sp)
    80005b28:	6a6a                	ld	s4,152(sp)
    80005b2a:	7a8a                	ld	s5,160(sp)
    80005b2c:	7b2a                	ld	s6,168(sp)
    80005b2e:	7bca                	ld	s7,176(sp)
    80005b30:	7c6a                	ld	s8,184(sp)
    80005b32:	6c8e                	ld	s9,192(sp)
    80005b34:	6d2e                	ld	s10,200(sp)
    80005b36:	6dce                	ld	s11,208(sp)
    80005b38:	6e6e                	ld	t3,216(sp)
    80005b3a:	7e8e                	ld	t4,224(sp)
    80005b3c:	7f2e                	ld	t5,232(sp)
    80005b3e:	7fce                	ld	t6,240(sp)
    80005b40:	6111                	addi	sp,sp,256
    80005b42:	10200073          	sret
    80005b46:	00000013          	nop
    80005b4a:	00000013          	nop
    80005b4e:	0001                	nop

0000000080005b50 <timervec>:
    80005b50:	34051573          	csrrw	a0,mscratch,a0
    80005b54:	e10c                	sd	a1,0(a0)
    80005b56:	e510                	sd	a2,8(a0)
    80005b58:	e914                	sd	a3,16(a0)
    80005b5a:	6d0c                	ld	a1,24(a0)
    80005b5c:	7110                	ld	a2,32(a0)
    80005b5e:	6194                	ld	a3,0(a1)
    80005b60:	96b2                	add	a3,a3,a2
    80005b62:	e194                	sd	a3,0(a1)
    80005b64:	4589                	li	a1,2
    80005b66:	14459073          	csrw	sip,a1
    80005b6a:	6914                	ld	a3,16(a0)
    80005b6c:	6510                	ld	a2,8(a0)
    80005b6e:	610c                	ld	a1,0(a0)
    80005b70:	34051573          	csrrw	a0,mscratch,a0
    80005b74:	30200073          	mret
	...

0000000080005b7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b7a:	1141                	addi	sp,sp,-16
    80005b7c:	e422                	sd	s0,8(sp)
    80005b7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b80:	0c0007b7          	lui	a5,0xc000
    80005b84:	4705                	li	a4,1
    80005b86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b88:	c3d8                	sw	a4,4(a5)
}
    80005b8a:	6422                	ld	s0,8(sp)
    80005b8c:	0141                	addi	sp,sp,16
    80005b8e:	8082                	ret

0000000080005b90 <plicinithart>:

void
plicinithart(void)
{
    80005b90:	1141                	addi	sp,sp,-16
    80005b92:	e406                	sd	ra,8(sp)
    80005b94:	e022                	sd	s0,0(sp)
    80005b96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b98:	ffffc097          	auipc	ra,0xffffc
    80005b9c:	dac080e7          	jalr	-596(ra) # 80001944 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ba0:	0085171b          	slliw	a4,a0,0x8
    80005ba4:	0c0027b7          	lui	a5,0xc002
    80005ba8:	97ba                	add	a5,a5,a4
    80005baa:	40200713          	li	a4,1026
    80005bae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bb2:	00d5151b          	slliw	a0,a0,0xd
    80005bb6:	0c2017b7          	lui	a5,0xc201
    80005bba:	953e                	add	a0,a0,a5
    80005bbc:	00052023          	sw	zero,0(a0)
}
    80005bc0:	60a2                	ld	ra,8(sp)
    80005bc2:	6402                	ld	s0,0(sp)
    80005bc4:	0141                	addi	sp,sp,16
    80005bc6:	8082                	ret

0000000080005bc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bc8:	1141                	addi	sp,sp,-16
    80005bca:	e406                	sd	ra,8(sp)
    80005bcc:	e022                	sd	s0,0(sp)
    80005bce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bd0:	ffffc097          	auipc	ra,0xffffc
    80005bd4:	d74080e7          	jalr	-652(ra) # 80001944 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bd8:	00d5179b          	slliw	a5,a0,0xd
    80005bdc:	0c201537          	lui	a0,0xc201
    80005be0:	953e                	add	a0,a0,a5
  return irq;
}
    80005be2:	4148                	lw	a0,4(a0)
    80005be4:	60a2                	ld	ra,8(sp)
    80005be6:	6402                	ld	s0,0(sp)
    80005be8:	0141                	addi	sp,sp,16
    80005bea:	8082                	ret

0000000080005bec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bec:	1101                	addi	sp,sp,-32
    80005bee:	ec06                	sd	ra,24(sp)
    80005bf0:	e822                	sd	s0,16(sp)
    80005bf2:	e426                	sd	s1,8(sp)
    80005bf4:	1000                	addi	s0,sp,32
    80005bf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	d4c080e7          	jalr	-692(ra) # 80001944 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c00:	00d5151b          	slliw	a0,a0,0xd
    80005c04:	0c2017b7          	lui	a5,0xc201
    80005c08:	97aa                	add	a5,a5,a0
    80005c0a:	c3c4                	sw	s1,4(a5)
}
    80005c0c:	60e2                	ld	ra,24(sp)
    80005c0e:	6442                	ld	s0,16(sp)
    80005c10:	64a2                	ld	s1,8(sp)
    80005c12:	6105                	addi	sp,sp,32
    80005c14:	8082                	ret

0000000080005c16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c16:	1141                	addi	sp,sp,-16
    80005c18:	e406                	sd	ra,8(sp)
    80005c1a:	e022                	sd	s0,0(sp)
    80005c1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c1e:	479d                	li	a5,7
    80005c20:	06a7c963          	blt	a5,a0,80005c92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c24:	0001d797          	auipc	a5,0x1d
    80005c28:	3dc78793          	addi	a5,a5,988 # 80023000 <disk>
    80005c2c:	00a78733          	add	a4,a5,a0
    80005c30:	6789                	lui	a5,0x2
    80005c32:	97ba                	add	a5,a5,a4
    80005c34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c38:	e7ad                	bnez	a5,80005ca2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c3a:	00451793          	slli	a5,a0,0x4
    80005c3e:	0001f717          	auipc	a4,0x1f
    80005c42:	3c270713          	addi	a4,a4,962 # 80025000 <disk+0x2000>
    80005c46:	6314                	ld	a3,0(a4)
    80005c48:	96be                	add	a3,a3,a5
    80005c4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c4e:	6314                	ld	a3,0(a4)
    80005c50:	96be                	add	a3,a3,a5
    80005c52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c56:	6314                	ld	a3,0(a4)
    80005c58:	96be                	add	a3,a3,a5
    80005c5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c5e:	6318                	ld	a4,0(a4)
    80005c60:	97ba                	add	a5,a5,a4
    80005c62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c66:	0001d797          	auipc	a5,0x1d
    80005c6a:	39a78793          	addi	a5,a5,922 # 80023000 <disk>
    80005c6e:	97aa                	add	a5,a5,a0
    80005c70:	6509                	lui	a0,0x2
    80005c72:	953e                	add	a0,a0,a5
    80005c74:	4785                	li	a5,1
    80005c76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c7a:	0001f517          	auipc	a0,0x1f
    80005c7e:	39e50513          	addi	a0,a0,926 # 80025018 <disk+0x2018>
    80005c82:	ffffc097          	auipc	ra,0xffffc
    80005c86:	53a080e7          	jalr	1338(ra) # 800021bc <wakeup>
}
    80005c8a:	60a2                	ld	ra,8(sp)
    80005c8c:	6402                	ld	s0,0(sp)
    80005c8e:	0141                	addi	sp,sp,16
    80005c90:	8082                	ret
    panic("free_desc 1");
    80005c92:	00003517          	auipc	a0,0x3
    80005c96:	abe50513          	addi	a0,a0,-1346 # 80008750 <syscalls+0x320>
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	890080e7          	jalr	-1904(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005ca2:	00003517          	auipc	a0,0x3
    80005ca6:	abe50513          	addi	a0,a0,-1346 # 80008760 <syscalls+0x330>
    80005caa:	ffffb097          	auipc	ra,0xffffb
    80005cae:	880080e7          	jalr	-1920(ra) # 8000052a <panic>

0000000080005cb2 <virtio_disk_init>:
{
    80005cb2:	1101                	addi	sp,sp,-32
    80005cb4:	ec06                	sd	ra,24(sp)
    80005cb6:	e822                	sd	s0,16(sp)
    80005cb8:	e426                	sd	s1,8(sp)
    80005cba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cbc:	00003597          	auipc	a1,0x3
    80005cc0:	ab458593          	addi	a1,a1,-1356 # 80008770 <syscalls+0x340>
    80005cc4:	0001f517          	auipc	a0,0x1f
    80005cc8:	46450513          	addi	a0,a0,1124 # 80025128 <disk+0x2128>
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	e66080e7          	jalr	-410(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cd4:	100017b7          	lui	a5,0x10001
    80005cd8:	4398                	lw	a4,0(a5)
    80005cda:	2701                	sext.w	a4,a4
    80005cdc:	747277b7          	lui	a5,0x74727
    80005ce0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ce4:	0ef71163          	bne	a4,a5,80005dc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ce8:	100017b7          	lui	a5,0x10001
    80005cec:	43dc                	lw	a5,4(a5)
    80005cee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cf0:	4705                	li	a4,1
    80005cf2:	0ce79a63          	bne	a5,a4,80005dc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cf6:	100017b7          	lui	a5,0x10001
    80005cfa:	479c                	lw	a5,8(a5)
    80005cfc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cfe:	4709                	li	a4,2
    80005d00:	0ce79363          	bne	a5,a4,80005dc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d04:	100017b7          	lui	a5,0x10001
    80005d08:	47d8                	lw	a4,12(a5)
    80005d0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d0c:	554d47b7          	lui	a5,0x554d4
    80005d10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d14:	0af71963          	bne	a4,a5,80005dc6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d18:	100017b7          	lui	a5,0x10001
    80005d1c:	4705                	li	a4,1
    80005d1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d20:	470d                	li	a4,3
    80005d22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d26:	c7ffe737          	lui	a4,0xc7ffe
    80005d2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d30:	2701                	sext.w	a4,a4
    80005d32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d34:	472d                	li	a4,11
    80005d36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d38:	473d                	li	a4,15
    80005d3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d3c:	6705                	lui	a4,0x1
    80005d3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d44:	5bdc                	lw	a5,52(a5)
    80005d46:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d48:	c7d9                	beqz	a5,80005dd6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d4a:	471d                	li	a4,7
    80005d4c:	08f77d63          	bgeu	a4,a5,80005de6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d50:	100014b7          	lui	s1,0x10001
    80005d54:	47a1                	li	a5,8
    80005d56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d58:	6609                	lui	a2,0x2
    80005d5a:	4581                	li	a1,0
    80005d5c:	0001d517          	auipc	a0,0x1d
    80005d60:	2a450513          	addi	a0,a0,676 # 80023000 <disk>
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	f5a080e7          	jalr	-166(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d6c:	0001d717          	auipc	a4,0x1d
    80005d70:	29470713          	addi	a4,a4,660 # 80023000 <disk>
    80005d74:	00c75793          	srli	a5,a4,0xc
    80005d78:	2781                	sext.w	a5,a5
    80005d7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d7c:	0001f797          	auipc	a5,0x1f
    80005d80:	28478793          	addi	a5,a5,644 # 80025000 <disk+0x2000>
    80005d84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d86:	0001d717          	auipc	a4,0x1d
    80005d8a:	2fa70713          	addi	a4,a4,762 # 80023080 <disk+0x80>
    80005d8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d90:	0001e717          	auipc	a4,0x1e
    80005d94:	27070713          	addi	a4,a4,624 # 80024000 <disk+0x1000>
    80005d98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d9a:	4705                	li	a4,1
    80005d9c:	00e78c23          	sb	a4,24(a5)
    80005da0:	00e78ca3          	sb	a4,25(a5)
    80005da4:	00e78d23          	sb	a4,26(a5)
    80005da8:	00e78da3          	sb	a4,27(a5)
    80005dac:	00e78e23          	sb	a4,28(a5)
    80005db0:	00e78ea3          	sb	a4,29(a5)
    80005db4:	00e78f23          	sb	a4,30(a5)
    80005db8:	00e78fa3          	sb	a4,31(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret
    panic("could not find virtio disk");
    80005dc6:	00003517          	auipc	a0,0x3
    80005dca:	9ba50513          	addi	a0,a0,-1606 # 80008780 <syscalls+0x350>
    80005dce:	ffffa097          	auipc	ra,0xffffa
    80005dd2:	75c080e7          	jalr	1884(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005dd6:	00003517          	auipc	a0,0x3
    80005dda:	9ca50513          	addi	a0,a0,-1590 # 800087a0 <syscalls+0x370>
    80005dde:	ffffa097          	auipc	ra,0xffffa
    80005de2:	74c080e7          	jalr	1868(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005de6:	00003517          	auipc	a0,0x3
    80005dea:	9da50513          	addi	a0,a0,-1574 # 800087c0 <syscalls+0x390>
    80005dee:	ffffa097          	auipc	ra,0xffffa
    80005df2:	73c080e7          	jalr	1852(ra) # 8000052a <panic>

0000000080005df6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005df6:	7119                	addi	sp,sp,-128
    80005df8:	fc86                	sd	ra,120(sp)
    80005dfa:	f8a2                	sd	s0,112(sp)
    80005dfc:	f4a6                	sd	s1,104(sp)
    80005dfe:	f0ca                	sd	s2,96(sp)
    80005e00:	ecce                	sd	s3,88(sp)
    80005e02:	e8d2                	sd	s4,80(sp)
    80005e04:	e4d6                	sd	s5,72(sp)
    80005e06:	e0da                	sd	s6,64(sp)
    80005e08:	fc5e                	sd	s7,56(sp)
    80005e0a:	f862                	sd	s8,48(sp)
    80005e0c:	f466                	sd	s9,40(sp)
    80005e0e:	f06a                	sd	s10,32(sp)
    80005e10:	ec6e                	sd	s11,24(sp)
    80005e12:	0100                	addi	s0,sp,128
    80005e14:	8aaa                	mv	s5,a0
    80005e16:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e18:	00c52c83          	lw	s9,12(a0)
    80005e1c:	001c9c9b          	slliw	s9,s9,0x1
    80005e20:	1c82                	slli	s9,s9,0x20
    80005e22:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e26:	0001f517          	auipc	a0,0x1f
    80005e2a:	30250513          	addi	a0,a0,770 # 80025128 <disk+0x2128>
    80005e2e:	ffffb097          	auipc	ra,0xffffb
    80005e32:	d94080e7          	jalr	-620(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005e36:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e38:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e3a:	0001dc17          	auipc	s8,0x1d
    80005e3e:	1c6c0c13          	addi	s8,s8,454 # 80023000 <disk>
    80005e42:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005e44:	4b0d                	li	s6,3
    80005e46:	a0ad                	j	80005eb0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005e48:	00fc0733          	add	a4,s8,a5
    80005e4c:	975e                	add	a4,a4,s7
    80005e4e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005e52:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005e54:	0207c563          	bltz	a5,80005e7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e58:	2905                	addiw	s2,s2,1
    80005e5a:	0611                	addi	a2,a2,4
    80005e5c:	19690d63          	beq	s2,s6,80005ff6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005e60:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e62:	0001f717          	auipc	a4,0x1f
    80005e66:	1b670713          	addi	a4,a4,438 # 80025018 <disk+0x2018>
    80005e6a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e6c:	00074683          	lbu	a3,0(a4)
    80005e70:	fee1                	bnez	a3,80005e48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e72:	2785                	addiw	a5,a5,1
    80005e74:	0705                	addi	a4,a4,1
    80005e76:	fe979be3          	bne	a5,s1,80005e6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e7a:	57fd                	li	a5,-1
    80005e7c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e7e:	01205d63          	blez	s2,80005e98 <virtio_disk_rw+0xa2>
    80005e82:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005e84:	000a2503          	lw	a0,0(s4)
    80005e88:	00000097          	auipc	ra,0x0
    80005e8c:	d8e080e7          	jalr	-626(ra) # 80005c16 <free_desc>
      for(int j = 0; j < i; j++)
    80005e90:	2d85                	addiw	s11,s11,1
    80005e92:	0a11                	addi	s4,s4,4
    80005e94:	ffb918e3          	bne	s2,s11,80005e84 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e98:	0001f597          	auipc	a1,0x1f
    80005e9c:	29058593          	addi	a1,a1,656 # 80025128 <disk+0x2128>
    80005ea0:	0001f517          	auipc	a0,0x1f
    80005ea4:	17850513          	addi	a0,a0,376 # 80025018 <disk+0x2018>
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	188080e7          	jalr	392(ra) # 80002030 <sleep>
  for(int i = 0; i < 3; i++){
    80005eb0:	f8040a13          	addi	s4,s0,-128
{
    80005eb4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005eb6:	894e                	mv	s2,s3
    80005eb8:	b765                	j	80005e60 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005eba:	0001f697          	auipc	a3,0x1f
    80005ebe:	1466b683          	ld	a3,326(a3) # 80025000 <disk+0x2000>
    80005ec2:	96ba                	add	a3,a3,a4
    80005ec4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ec8:	0001d817          	auipc	a6,0x1d
    80005ecc:	13880813          	addi	a6,a6,312 # 80023000 <disk>
    80005ed0:	0001f697          	auipc	a3,0x1f
    80005ed4:	13068693          	addi	a3,a3,304 # 80025000 <disk+0x2000>
    80005ed8:	6290                	ld	a2,0(a3)
    80005eda:	963a                	add	a2,a2,a4
    80005edc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005ee0:	0015e593          	ori	a1,a1,1
    80005ee4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005ee8:	f8842603          	lw	a2,-120(s0)
    80005eec:	628c                	ld	a1,0(a3)
    80005eee:	972e                	add	a4,a4,a1
    80005ef0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005ef4:	20050593          	addi	a1,a0,512
    80005ef8:	0592                	slli	a1,a1,0x4
    80005efa:	95c2                	add	a1,a1,a6
    80005efc:	577d                	li	a4,-1
    80005efe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f02:	00461713          	slli	a4,a2,0x4
    80005f06:	6290                	ld	a2,0(a3)
    80005f08:	963a                	add	a2,a2,a4
    80005f0a:	03078793          	addi	a5,a5,48
    80005f0e:	97c2                	add	a5,a5,a6
    80005f10:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005f12:	629c                	ld	a5,0(a3)
    80005f14:	97ba                	add	a5,a5,a4
    80005f16:	4605                	li	a2,1
    80005f18:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f1a:	629c                	ld	a5,0(a3)
    80005f1c:	97ba                	add	a5,a5,a4
    80005f1e:	4809                	li	a6,2
    80005f20:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f24:	629c                	ld	a5,0(a3)
    80005f26:	973e                	add	a4,a4,a5
    80005f28:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f2c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005f30:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005f34:	6698                	ld	a4,8(a3)
    80005f36:	00275783          	lhu	a5,2(a4)
    80005f3a:	8b9d                	andi	a5,a5,7
    80005f3c:	0786                	slli	a5,a5,0x1
    80005f3e:	97ba                	add	a5,a5,a4
    80005f40:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80005f44:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005f48:	6698                	ld	a4,8(a3)
    80005f4a:	00275783          	lhu	a5,2(a4)
    80005f4e:	2785                	addiw	a5,a5,1
    80005f50:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005f54:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f60:	004aa783          	lw	a5,4(s5)
    80005f64:	02c79163          	bne	a5,a2,80005f86 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f68:	0001f917          	auipc	s2,0x1f
    80005f6c:	1c090913          	addi	s2,s2,448 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005f70:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f72:	85ca                	mv	a1,s2
    80005f74:	8556                	mv	a0,s5
    80005f76:	ffffc097          	auipc	ra,0xffffc
    80005f7a:	0ba080e7          	jalr	186(ra) # 80002030 <sleep>
  while(b->disk == 1) {
    80005f7e:	004aa783          	lw	a5,4(s5)
    80005f82:	fe9788e3          	beq	a5,s1,80005f72 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005f86:	f8042903          	lw	s2,-128(s0)
    80005f8a:	20090793          	addi	a5,s2,512
    80005f8e:	00479713          	slli	a4,a5,0x4
    80005f92:	0001d797          	auipc	a5,0x1d
    80005f96:	06e78793          	addi	a5,a5,110 # 80023000 <disk>
    80005f9a:	97ba                	add	a5,a5,a4
    80005f9c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005fa0:	0001f997          	auipc	s3,0x1f
    80005fa4:	06098993          	addi	s3,s3,96 # 80025000 <disk+0x2000>
    80005fa8:	00491713          	slli	a4,s2,0x4
    80005fac:	0009b783          	ld	a5,0(s3)
    80005fb0:	97ba                	add	a5,a5,a4
    80005fb2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005fb6:	854a                	mv	a0,s2
    80005fb8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005fbc:	00000097          	auipc	ra,0x0
    80005fc0:	c5a080e7          	jalr	-934(ra) # 80005c16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005fc4:	8885                	andi	s1,s1,1
    80005fc6:	f0ed                	bnez	s1,80005fa8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005fc8:	0001f517          	auipc	a0,0x1f
    80005fcc:	16050513          	addi	a0,a0,352 # 80025128 <disk+0x2128>
    80005fd0:	ffffb097          	auipc	ra,0xffffb
    80005fd4:	ca6080e7          	jalr	-858(ra) # 80000c76 <release>
}
    80005fd8:	70e6                	ld	ra,120(sp)
    80005fda:	7446                	ld	s0,112(sp)
    80005fdc:	74a6                	ld	s1,104(sp)
    80005fde:	7906                	ld	s2,96(sp)
    80005fe0:	69e6                	ld	s3,88(sp)
    80005fe2:	6a46                	ld	s4,80(sp)
    80005fe4:	6aa6                	ld	s5,72(sp)
    80005fe6:	6b06                	ld	s6,64(sp)
    80005fe8:	7be2                	ld	s7,56(sp)
    80005fea:	7c42                	ld	s8,48(sp)
    80005fec:	7ca2                	ld	s9,40(sp)
    80005fee:	7d02                	ld	s10,32(sp)
    80005ff0:	6de2                	ld	s11,24(sp)
    80005ff2:	6109                	addi	sp,sp,128
    80005ff4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005ff6:	f8042503          	lw	a0,-128(s0)
    80005ffa:	20050793          	addi	a5,a0,512
    80005ffe:	0792                	slli	a5,a5,0x4
  if(write)
    80006000:	0001d817          	auipc	a6,0x1d
    80006004:	00080813          	mv	a6,a6
    80006008:	00f80733          	add	a4,a6,a5
    8000600c:	01a036b3          	snez	a3,s10
    80006010:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006014:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006018:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000601c:	7679                	lui	a2,0xffffe
    8000601e:	963e                	add	a2,a2,a5
    80006020:	0001f697          	auipc	a3,0x1f
    80006024:	fe068693          	addi	a3,a3,-32 # 80025000 <disk+0x2000>
    80006028:	6298                	ld	a4,0(a3)
    8000602a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000602c:	0a878593          	addi	a1,a5,168
    80006030:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006032:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006034:	6298                	ld	a4,0(a3)
    80006036:	9732                	add	a4,a4,a2
    80006038:	45c1                	li	a1,16
    8000603a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000603c:	6298                	ld	a4,0(a3)
    8000603e:	9732                	add	a4,a4,a2
    80006040:	4585                	li	a1,1
    80006042:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006046:	f8442703          	lw	a4,-124(s0)
    8000604a:	628c                	ld	a1,0(a3)
    8000604c:	962e                	add	a2,a2,a1
    8000604e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006052:	0712                	slli	a4,a4,0x4
    80006054:	6290                	ld	a2,0(a3)
    80006056:	963a                	add	a2,a2,a4
    80006058:	058a8593          	addi	a1,s5,88
    8000605c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000605e:	6294                	ld	a3,0(a3)
    80006060:	96ba                	add	a3,a3,a4
    80006062:	40000613          	li	a2,1024
    80006066:	c690                	sw	a2,8(a3)
  if(write)
    80006068:	e40d19e3          	bnez	s10,80005eba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000606c:	0001f697          	auipc	a3,0x1f
    80006070:	f946b683          	ld	a3,-108(a3) # 80025000 <disk+0x2000>
    80006074:	96ba                	add	a3,a3,a4
    80006076:	4609                	li	a2,2
    80006078:	00c69623          	sh	a2,12(a3)
    8000607c:	b5b1                	j	80005ec8 <virtio_disk_rw+0xd2>

000000008000607e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000607e:	1101                	addi	sp,sp,-32
    80006080:	ec06                	sd	ra,24(sp)
    80006082:	e822                	sd	s0,16(sp)
    80006084:	e426                	sd	s1,8(sp)
    80006086:	e04a                	sd	s2,0(sp)
    80006088:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000608a:	0001f517          	auipc	a0,0x1f
    8000608e:	09e50513          	addi	a0,a0,158 # 80025128 <disk+0x2128>
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	b30080e7          	jalr	-1232(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000609a:	10001737          	lui	a4,0x10001
    8000609e:	533c                	lw	a5,96(a4)
    800060a0:	8b8d                	andi	a5,a5,3
    800060a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060a8:	0001f797          	auipc	a5,0x1f
    800060ac:	f5878793          	addi	a5,a5,-168 # 80025000 <disk+0x2000>
    800060b0:	6b94                	ld	a3,16(a5)
    800060b2:	0207d703          	lhu	a4,32(a5)
    800060b6:	0026d783          	lhu	a5,2(a3)
    800060ba:	06f70163          	beq	a4,a5,8000611c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060be:	0001d917          	auipc	s2,0x1d
    800060c2:	f4290913          	addi	s2,s2,-190 # 80023000 <disk>
    800060c6:	0001f497          	auipc	s1,0x1f
    800060ca:	f3a48493          	addi	s1,s1,-198 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800060ce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060d2:	6898                	ld	a4,16(s1)
    800060d4:	0204d783          	lhu	a5,32(s1)
    800060d8:	8b9d                	andi	a5,a5,7
    800060da:	078e                	slli	a5,a5,0x3
    800060dc:	97ba                	add	a5,a5,a4
    800060de:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060e0:	20078713          	addi	a4,a5,512
    800060e4:	0712                	slli	a4,a4,0x4
    800060e6:	974a                	add	a4,a4,s2
    800060e8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800060ec:	e731                	bnez	a4,80006138 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800060ee:	20078793          	addi	a5,a5,512
    800060f2:	0792                	slli	a5,a5,0x4
    800060f4:	97ca                	add	a5,a5,s2
    800060f6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800060f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800060fc:	ffffc097          	auipc	ra,0xffffc
    80006100:	0c0080e7          	jalr	192(ra) # 800021bc <wakeup>

    disk.used_idx += 1;
    80006104:	0204d783          	lhu	a5,32(s1)
    80006108:	2785                	addiw	a5,a5,1
    8000610a:	17c2                	slli	a5,a5,0x30
    8000610c:	93c1                	srli	a5,a5,0x30
    8000610e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006112:	6898                	ld	a4,16(s1)
    80006114:	00275703          	lhu	a4,2(a4)
    80006118:	faf71be3          	bne	a4,a5,800060ce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000611c:	0001f517          	auipc	a0,0x1f
    80006120:	00c50513          	addi	a0,a0,12 # 80025128 <disk+0x2128>
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	b52080e7          	jalr	-1198(ra) # 80000c76 <release>
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6902                	ld	s2,0(sp)
    80006134:	6105                	addi	sp,sp,32
    80006136:	8082                	ret
      panic("virtio_disk_intr status");
    80006138:	00002517          	auipc	a0,0x2
    8000613c:	6a850513          	addi	a0,a0,1704 # 800087e0 <syscalls+0x3b0>
    80006140:	ffffa097          	auipc	ra,0xffffa
    80006144:	3ea080e7          	jalr	1002(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
