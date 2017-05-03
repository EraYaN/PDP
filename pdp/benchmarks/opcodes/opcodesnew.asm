##################################################################
# TITLE: Opcode Tester
# AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
# DATE CREATED: 1/10/02
# FILENAME: opcodes.asm
# PROJECT: Plasma CPU core
# COPYRIGHT: Software placed into the public domain by the author.
#    Software 'as is' without warranty.  Author liable for nothing.
# DESCRIPTION:
#    This assembly file tests all of the opcodes supported by the
#    Plasma core.
#    This test assumes that address 0x20000000 is the UART write register
#    Successful tests will print out "A" or "AB" or "ABC" or ....
#    Missing letters or letters out of order indicate a failure.
##################################################################
	.text
	.align	2
	.globl	entry
	.ent	entry
entry:
   .set noreorder

   la    $gp, _gp           #initialize stack pointer
   la    $4, __bss_start    #$4 = .sbss_start
   la    $5, _end           #$5 = .bss_end
   nop                      #no stack needed
   nop

   b     StartTest
   nop                      #nops required to place ISR at 0x3c
   nop

OS_AsmPatchValue:
   #Code to place at address 0x3c
   lui   $26, 0x1000
   ori   $26, $26, 0x3c
   jr    $26
   nop

InterruptVector:            #Address=0x3c
   mfc0  $26,$14            #C0_EPC=14 (Exception PC)
   jr    $26
   add   $4,$4,5
   
StartTest:
   mtc0  $0,$12             #disable interrupts
   lui   $20,0x2000         #serial port write address
   ori   $21,$0,'\n'        #<CR> letter
   ori   $22,$0,'X'         #'X' letter
   ori   $23,$0,'\r'
   ori   $24,$0,0x0f80      #temp memory

   sb    $23,0($20)
   sb    $21,0($20)
   sb    $23,0($20)
   sb    $21,0($20)
   sb    $23,0($20)
   sb    $21,0($20)
   sb    $23,0($20)
   sb    $21,0($20)

   #Patch interrupt vector to 0x1000003c
   la    $5, OS_AsmPatchValue
   sub   $6,$5,0x1000
   blez  $6,NoPatch
   
   lw    $6, 0($5)
   sw    $6, 0x3c($0)
   lw    $6, 4($5)
   sw    $6, 0x40($0)
   lw    $6, 8($5)
   sw    $6, 0x44($0)
   lw    $6, 12($5)
   sw    $6, 0x48($0)
NoPatch:

   ######################################
   #Arithmetic Instructions
   ######################################

   ori   $11,$0,'A'
   or    $3,$0,$0
   addi  $3,$0,4

$LOOP:
   sb    $11,0($3)
   lb    $4,0($3)
   sb    $4,0($20)
   lb    $5,0($3)
   sb    $5,0($20)
   or    $4,$0,$0
   or    $5,$0,$0
   addi  $3,$3,4
   sb    $23,0($20)
   sb    $21,0($20)
   j     $LOOP

   .set reorder
   .end  entry