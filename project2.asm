.data
   .text
   .global main
main:
   li $a0,222
   li $v0,1
   syscall
   .data
   .text
   # init param dec
   li $t0,0
   sw $t0,0($sp)
   # init param dec
   li $t0,0
   sw $t0,4($sp)
   lw $a0,0($sp)
   li $v0,1
   syscall
