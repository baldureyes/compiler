.data
   .text
   .global main
main:
   li $t0,222
   addi $t0,1
   li $t2,3
   sub $t0,$t2
   # print
   move $a0,$t0
   li $v0,1
   syscall
   # exit program
   jr $ra

   .data
   .text
CS_test:
   # dec param "a" at stack loc 0 
   li $t0,0
   sw $t0,0($sp)
   # dec param "b" at stack loc 4 
   li $t0,0
   sw $t0,4($sp)
   # assign 5 to "b"
   li $t0,5
   sw $t0,4($sp)
   # print param "b"
   lw $a0,4($sp)
   li $v0,1
   syscall
