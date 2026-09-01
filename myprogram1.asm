addi $1, $0, 0
addi $2, $0, 1
addi $3, $0, 5
loop:
add  $1, $1, $2
addi $2, $2, 1
slt  $4, $3, $2
beq  $4, $0, loop
addi $5, $1, 0
done:
j done