.data
   .text
   .globl main
main:
   li $t0, 5
   sw $t0,0($sp)
   
   li $t0, 6
   sw $t0,4($sp)

   li $t0, 7
   sw $t0,8($sp)
   
   # print $a0 value
   lw $a0,0($sp)
   li $v0,1
   syscall

   # return
   jr $ra
