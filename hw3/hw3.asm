##################################
# Part 1 - String Functions
##################################

is_whitespace:
	beq $a0, 0, whitespaceTrue #if argument c is null go to true
	beq $a0, 32, whitespaceTrue #if argumemnt c is a space true
	beq $a0, 10, whitespaceTrue # if new line, go to true
	
	li $v0, 0 #whitespaceFalse so returning 0
	jr $ra
	
	whitespaceTrue:
	li $v0, 1  #is a whitespace so returning 1
	jr $ra
	
cmp_whitespace:
	addi $sp, $sp, -8 # prologue, shifts stack down 8, puts s0 and ra on stack
	sw $s0, 0($sp) #holds the second arg to check for whitespace
	sw $ra, 4($sp)
	
	move $s0, $a1 #moves a1 to s0 so not lost after calling is whitespace on a0
	jal is_whitespace #calls is whitespace
	beqz $v0, cmp_whitespaceFalse #if not a whitespace jumo to whitespace false
	move $a0, $s0 #moves saved a2 from s0 to a0
	jal is_whitespace #calls is whitespace again on the second arg
	beqz $v0, cmp_whitespaceFalse #if return is 0, whitespace true
	
	li $v0, 1 #cmp_whitespaceTrue if got to here, had to have both beeen white spaces so loads 1 to return $v0
	lw $s0, 0($sp) #loads stuff back from the stack
	lw $ra, 4($sp)
	addi $sp, $sp, 8 #moves stack back up
	jr $ra #jumps to the ra
	
	cmp_whitespaceFalse:
	li $v0, 0 #loads 0 because one of the is whitespaces returned a 0 so one is not a 0
	lw $s0, 0($sp) #loads things back from stack, moves stack back up and returns
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra

strcpy:
	ble $a0, $a1, strcpyLoopEnd #if src string is less than or equal to dst, do nothing and return
	move $t0, $a0 #src
	move $t1, $a1 #dest
	move $t2, $a2 #n
	strcpyLoop:
	beqz $t2, strcpyLoopEnd #if the number of bytes left is 0, jump out of the loop
	lb $t3, ($a0) #else load the src byte
	sb $t3, ($a1) #save it in the dest byte
	addi $t0, $t0, 1 #increment both address by 1
	addi $t1, $t1, 1
	addi $t2, $t2, -1 #decrement the number of bytes left to copy by 1
	b strcpyLoop #jump to top of the loop again 
	
	strcpyLoopEnd:
	jr $ra #return

strlen:
	addi $sp, $sp -12 #moves stack down by 12
	sw $ra, 0($sp) #adds ra, s0, s1 to stack
	sw $s0, 4($sp) #holds the string
	sw $s1, 8($sp) #holds the counter
	
	li $s1, 0 #loads 0 into s0
	move $s0, $a0 #moves the arg string to s0
	strlenLoop:
	lb $t0, ($s0) #loads a byte from the string
	move $a0, $t0 #moves the byte to a0 reg 
	jal is_whitespace #calls is whitespace on a0
	beq $v0, 1, strlenLoopEnd #if returned a 0, means it is whitespace so end the loop
	addi $s0, $s0, 1 #add 1 to address for string
	addi $s1, $s1, 1 #add 1 to the counter
	b strlenLoop
	
	strlenLoopEnd:
	move $v0, $s1 # moves the length of the string to v0 so can return
	lw $ra, 0($sp) #loads stuff back from stack
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12 #moves stack back up
	jr $ra #returns
	
##################################
# Part 2 - vt100 MMIO Functions
##################################

set_state_color:
	bne $a3, 2, mode_1 #this is if mode is 2 so updating bg
	
		bne $a2, 1, mode_2_default #this is if updating highlight
		
		move $t0, $a1 #moves the byte for color into t0
		andi $t0, $t0, 240
		lb $t1, 1($a0) #loads the second byte from a0, the one with highlight colors
		andi $t1, $t1, 15
		or $t0, $t0, $t1 #creates the new byte with the new highlight
		sb $t0, 1($a0) # saves the updated byte into the struct
		jr $ra
		
		mode_2_default: #this is if updating default
		move $t0, $a1 #moves the color into t0
		andi $t0, $t0, 240
		lb $t1, ($a0) #loads the byte holding default color for fore and back
		andi $t1, $t1, 15
		or $t0, $t0, $t1 #creates the new byte with the new d_b
		sb $t0, ($a0) #saves the updated byte into the struct
		jr $ra
		
	mode_1:
	bne $a3, 1, mode_0 #this is if mode is 1 su updating fg
	
		bne $a2, 1, mode_1_default #this is if updateing highlight
		move $t0, $a1 #moves color into t0
		andi $t0, $t0, 15
		lb $t1, 1($a0) #loads the byte with highlight
		andi $t1, $t1, 240
		or $t0, $t0, $t1 #ors to make the new byte
		sb $t0, 1($a0) #saves the byte back in highlight
		jr $ra
		
		mode_1_default:#updating default color
		move $t0, $a1 #moves the color into t0
		andi $t0, $t0, 15 
		lb $t1, ($a0) #loads the default byte
		andi $t1, $t1, 240
		or $t0, $t0, $t1 #ors to make new df byte
		sb $t0, ($a0) #saves it back in df
		jr $ra
	
	mode_0: #if mode is 0 so updating both
	
		bne $a2, 1, mode_0_default #for updating highlight
		sb $a1, 1($a0) #saves the color byte in highlight byte
		jr $ra
	mode_0_default: #for updating default color
		sb $a1, ($a0) #saves the color byte in the default byte
		jr $ra

save_char:
	lb $t0, 2($a0) #xpos as int
	lb $t1, 3($a0) #ypos as int
	li $t2, 0xffff0000 #base address
	li $t3, 80 #num cols
	li $t4, 2 #elem size
	mul $t3, $t0, $t3 # i * col
	add $t3, $t3, $t1 # + j
	mul $t3, $t3, $t4 # * elem_size
	add $t2, $t2, $t3 # + base address
	sb $a1, ($t2) #stores c into the address, the first byte is the char, second is color
	jr $ra #returns
reset:
	li $t0, 0xffff0000 # base address
	li $t1, 0xffff0fa0 # end address
	reset_loop: #loop that starts at base adress and ends when greater than end address
		bgt $t0, $t1, reset_loop_end #if base adress gets incremented greater than end
		beq $a1, 1, reset_loop_color #if color only is 1, than only need to clear color
		sb $0, ($t0) #loads null into char byte 
		reset_loop_color:
		lb $t3, ($a0) #laods default colors into t3
		sb $t3, 1($t0) #saves it inmto the color byte
		addi $t0, $t0, 2 #shifts address by 2 bytes
		b reset_loop # branches back tp top of loop
	reset_loop_end:
	jr $ra
clear_line:
	li $t0, 0xffff0000 # base address
	li $t1, 80 # num of cols
	li $t6, 79 #last y i need to clear
	li $t9, 2
	move $t7, $a2
	move $t2, $a0, #the x pos
	move $t3, $a1, #the y pos
	mul $t4, $t1, $t2 # i * num cols
	add $t4, $t4, $t3 # + j
	mul $t4, $t4, $t9 #shifts by 2, same as muliplying by 2, 2 = elem size 2bytes per thing
	add $t4, $t4, $t0, # + base addr
	mul $t5, $t1, $t2 # i * num cols
	add $t5, $t5, $t6 # + 79
	mul $t5, $t5, $t9 # mul by 2, 2 == elem size
	add $t5, $t5, $t0 # + base addr
	#t4 === starting address and t5 === end
	clear_line_loop:
		bgt $t4, $t5, clear_line_loop_end
		sb $0, ($t4) #saves null into character
		sb $t7, 1($t4) #saves the color into the color byte
		addi $t4, $t4, 2 #increments the address by 2, each thing is 2 bytes
		b clear_line_loop
	clear_line_loop_end:
	jr $ra
	
set_cursor:
	lb $t0, 2($a0) #xpos
	lb $t1, 3($a0) #ypos
	li $t2, 0xffff0000 #base addr
	li $t3, 80 #num cols
	li $t9, 2
	beq $a3, 1 set_curser_not_clear #branches if 1, so that the cursor is not cleared
	mul $t4, $t0, $t3 #i * num cols
	add $t4, $t4, $t1 # + j
	mul $t4, $t4, $t9 # mul by 2 b/c elem size is 2
	add $t4, $t4, $t2 # add to base addr
	lb $t5, 1($t4) #loads the color byte
	li $t6, 0x88 #loads 1000 1000
	xor $t5, $t5, $t6 #xor flips the bold bytes 
	sb $t5, 1($t4) #saves it back
	set_curser_not_clear: #if initial was 1, cursor not cleard
	move $t0, $a1 # xpos
	move $t1, $a2 #ypos
	sb $t0, 2($a0) #saves x into x byte of struct
	sb $t1, 3($a0) #saves y into y byte of struct
	mul $t4, $t0, $t3 #i * num cols
	add $t4, $t4, $t1 # + j
	mul $t4, $t4, $t9 # * byte size == 2
	add $t4, $t4, $t2 # + base addr
	lb $t5, 1($t4) #loads color byte
	li $t6, 0x88 #loads 1000 1000
	xor $t5, $t5, $t6 #flips the bold bits
	sb $t5, 1($t4) #saves it back into color
	jr $ra # returns
move_cursor:
	addi $sp, $sp, -4 #moves stack down 4 and puts $ra onto stack
	sw $ra, ($sp)
	
	lb $t0, 2($a0) #xpos
	lb $t1, 3($a0) #ypos
	li $t2, 0 #initial, used to jal with set_cursor, if 0 cursor gets cleared which is wanted
	
	bne $a1, 107, move_cursor_j #this is for k, or up
	beq $t0, 0, move_cursor_end #if xpos == 0, do nothing
	addi $t0, $t0, -1 #decreases row number by 1 to move up
	move $a1, $t0 # puts xpos into a1
	move $a2, $t1, #puts ypos into a2
	move $a3, $t2 #puts initial value of 0 into a3 so that cursor will be cleared
	jal set_cursor # calls set cursor which takes state, x, y , intial
	b move_cursor_end
	
	move_cursor_j: #this is for k, or down
	bne $a1, 106, move_cursor_h
	beq $t0, 24, move_cursor_end  #if x == 24, do nothing
	addi $t0, $t0, 1 #inc row num by 1 so that the cursor moves down
	move $a1, $t0 # puts xpos into a1
	move $a2, $t1, #puts ypos into a2
	move $a3, $t2 #puts initial value of 0 into a3 so that cursor will be cleared
	jal set_cursor # calls set cursor which takes state, x, y , intial
	b move_cursor_end
	
	move_cursor_h: #this is for h, or left
	bne $a1, 104, move_cursor_l
	beq $t1, 0, move_cursor_end #if the y pos is 0, nothing happens
	addi $t1, $t1, -1 # dec col number by 1 so that the cursor moves right
	move $a1, $t0 # puts xpos into a1
	move $a2, $t1, #puts ypos into a2
	move $a3, $t2 #puts initial value of 0 into a3 so that cursor will be cleared
	jal set_cursor # calls set cursor which takes state, x, y , intial
	b move_cursor_end
	
	
	move_cursor_l: # this is l or right
	bne $a1, 108, move_cursor_end
	beq $t1, 79, move_cursor_end #if y pos is 79, do nothing
	addi $t1, $t1, 1 #inc col number by 1 to move it left
	move $a1, $t0 # puts xpos into a1
	move $a2, $t1, #puts ypos into a2
	move $a3, $t2 #puts initial value of 0 into a3 so that cursor will be cleared
	jal set_cursor # calls set cursor which takes state, x, y , intial
	
	move_cursor_end:
	lw $ra, ($sp) #loads ra from stack and pushes stack back up and returns
	addi $sp, $sp, 4
	jr $ra
mmio_streq:
	addi $sp, $sp, -12 #prolouge
	sw $ra, ($sp) #sores ra, s0 for mmio string address and s1 for string address
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	move $s0, $a0 #moves mmio string and b string to s reg so the are preserved
	move $s1, $a1
	
	mmio_streq_loop:
	lb $a0, ($s0) #loads the chars from the addresss into the arg registers for cmp whitespace
	lb $a1, ($s1)
	jal cmp_whitespace #calls cmp white space which will return a 1 if they are both white spaces
	beq $v0, 1, mmio_streq_equal #if both white spaces, break loop to true
	lb $t0, ($s0) #else need to load the chars from the address's again and compare 
	lb $t1, ($s1)
	bne $t0, $t1, mmio_streq_not_equal #if they are not equal break loop and return false
	addi $s0, $s0, 2 #else increment mmio address by 2 b/c each elemenet is 2 bytes and string by 1 and run loop
	addi $s1, $s1, 1
	b mmio_streq_loop
	
	mmio_streq_equal: #if equal restore from stack , shift it back up and return 1
	lw $ra, ($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	
	li $v0, 1
	jr $ra
	
	mmio_streq_not_equal: #else do the same but return 0
	lw $ra, ($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	
	li $v0, 0
	jr $ra
	

##################################
# Part 3 - UI/UX Functions
##################################

handle_nl:
	addi $sp, $sp, -8 #moves stack down and saves ra and s0 for the state struct
	sw $ra, ($sp)
	sw $s0, 4($sp)
	
	move $s0, $a0 #moves state struct to s0
	
	li $a1, 10 #loads a newline char into a1
	jal save_char #this will save the newline char into the curent pos at the cursor
	
	move $a0, $s0 #reloads the struct into a0
	li $a1, 108 #loads 108 which is the ascii for l into 
	jal move_cursor #calls move cursor
	
	lb $a0, 2($s0) #loads in the x
	lb $a1, 3($s0) #loads in the y
	lb $a2, ($s0) #loads in the default color
	jal clear_line #calls clear line
	
	move $a0, $s0 #moves state struct back
	li $a1, 106 #loads 106, or j to move down
	jal move_cursor #calls move curosr to move down
	
	move $a0, $s0 #moves state struct back
	lb $a1, 2($s0) # loads in the x
	li $a2, 0 #y is zero becauze needs to be at start of new line
	li $a3, 0 # this needs to be 0 so old cursor is cleared
	jal set_cursor #calls set cursor
	
	lw $ra, ($sp) #loads ra and s0 from stack moves stack up and returns
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra
handle_backspace:
	addi $sp, $sp, -16
	sw $ra, ($sp) #ra
	sw $s0, 4($sp) #struct
	sw $s1, 8($sp) # start_addr
	sw $s2, 12($sp) #end _addr

	move $s0, $a0
	lb $t0, 2($a0) #xpos
	lb $t1, 3($a0) #ypos
	li $t2, 0xffff0000
	li $t3, 80
	li $t4, 79
	li $t5, 2
	mul $t6, $t0, $t3 #i * num cols       this is the starting addr
	add $t6, $t6, $t1 # + j
	mul $t6, $t6, $t5 # * byte size == 2
	add $t6, $t6, $t2 # + base addr
	mul $t7, $t0, $t3 #i * num cols
	add $t7, $t7, $t4 # + j
	mul $t7, $t7, $t5 # * byte size == 2
	add $t7, $t7, $t2 # + base addr                 end address
	
	move $s1, $t6 #moved to s reg to save
	move $s2, $t7
	
	handle_backspace_loop:
		bge $s1, $s2, handle_backspace_loop_end
		addi $a0, $s1, 2
		move $a1, $s1
		li $a2, 2 #copy two bytes to copy the whole cell
		jal strcpy
		addi $s1, $s1, 2
		b handle_backspace_loop
	
	handle_backspace_loop_end:
	lb $t0, ($s0) #gets the default color
	sb $t0, 1($s2)
	sb $0, ($s2)
	
	lw $ra, ($sp) #ra
	lw $s0, 4($sp) #struct
	lw $s1, 8($sp) # start_addr
	lw $s2, 12($sp) #end _addr
	addi $sp, $sp, 16
	
	jr $ra
	
highlight:
	
	move $t8, $a2 #the color 
	move $t0, $a0 #xpos
	move $t1, $a1 #ypos
	move $t2, $a3 #n or number of things to highlight
	li $t3, 0xffff0000 #base addr
	li $t4, 80 #num cols
	li $t5, 2 # elem size
	
	mul $t6, $t0, $t4 # i * num cols
	add $t6, $t6, $t1 # + j
	mul $t6, $t6, $t5 # * elem size or 2
	add $t6, $t6, $t3 # + base addr     so t6 has the starting address
	
	mul $t7, $t2, $t5 #this will give us the amount we need to increment the staring address, n *2 b/c each element is 2 bytes
	add $t7, $t7, $t6 #this is the address of the last mmio cell
	
	highlight_loop:
	bge $t6, $t7, highlight_loop_end
	sb $t8, 1($t6) #saves the color byte at the mmio cell offset 1 b/c the first byte is the char, second is color
	addi $t6, $t6, 2 #increments address by 2 to get to the next mmio cell
	b highlight_loop
	
	highlight_loop_end:
	jr $ra

highlight_all:
	addi $sp, $sp, -32
	sw $ra, ($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	
	
	move $s0, $a0 #moves color and dict to s reg
	move $s1, $a1 #dict
	li $s2, 0xffff0000 #the beginning cell
	li $s3, 0xffff0fa0 # the last cell 
	li $s4, 0 #counter for number of times ran, used in highlighting
	
	highlight_all_main_while_loop:
		bge $s2, $s3, highlight_all_end #if at the last cell, break loop
		highlight_all_is_whitespace_loop: #loop for navigating white space
			bge $s2, $s3, highlight_all_end
			lb $a0, ($s2) #loads the char from the current cell to a0
			jal is_whitespace #calls is white space which will return a 1 if it is whitespace
			bne $v0, 1, highlight_all_is_whitespace_loop_end #if it did not return a 1, not a whitespace so break
			addi $s2, $s2, 2 #increment to next cell
			addi $s4, $s4, 1 #increments counter
			b highlight_all_is_whitespace_loop #go back to top of loop
		highlight_all_is_whitespace_loop_end:
		# move $s4, $s2 #moves the current cell address to s4
		move $s5, $s1 #new dict address to fuck around with
		highlight_all_for_each_word_in_dictionary_loop:
			lw $s6, ($s5)
			beqz $s6, highlight_all_not_is_whitespace_loop
			move $a0, $s2 #moves address for current mmio cell into a0
			move $a1, $s6 #moves address for dictionary into a1
			jal mmio_streq #calls function to see if the two strings are equal
			bne $v0, 1, highlight_all_for_each_word_in_dictionary_loop_highlight #if it returned 1, highlight the word
			move $a0, $s6 #moves address of dict string into a0
			jal strlen #calls strlen to get length
			move $a3, $v0 #length == n so moved to a3 for highlight
			move $a2, $s0 #moves the color into a2
			move $t0, $s4 #gets counter and moves it into t0
			li $t1, 0 #this will be the x pos, in the end t0 will be the y pos
			highlight_all_for_each_word_in_dictionary_loop_findxy_loop:
				ble $t0, 80, highlight_all_for_each_word_in_dictionary_loop_findxy_loop_end # if counter is less than 80, break
				addi $t0, $t0, -80 #decrement counter by 80
				addi $t1, $t1, 1 #increment x by 1
				b highlight_all_for_each_word_in_dictionary_loop_findxy_loop
			highlight_all_for_each_word_in_dictionary_loop_findxy_loop_end:
			move $a0, $t1 #moves x into a0
			move $a1, $t0 #moves y into a1
			jal highlight
			highlight_all_for_each_word_in_dictionary_loop_highlight:
			addi $s5, $s5, 4 #adds it to the address of the dict to be able to get to the next word
			b highlight_all_for_each_word_in_dictionary_loop
		highlight_all_not_is_whitespace_loop:
			lb $a0, ($s2)
			jal is_whitespace
			beq $v0, 1, highlight_all_main_while_loop
			addi $s2, $s2, 2
			addi $s4, $s4, 1
			b highlight_all_not_is_whitespace_loop
	highlight_all_end:
	lw $ra, ($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 32($sp)
	addi $sp, $sp, 32
	jr $ra
