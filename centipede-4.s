##################################################################### 
# 
# Author: Ziyuan (Jerry) Zhang
#
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 
# - Unit height in pixels: 8 
# - Display width in pixels: 256 
# - Display height in pixels: 256 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# 
# How to play in Mars:
# - connect to bitmap display (specs above) and keyboard simulator 
# - click the triangular run button on top
# - enter j for left move, k for right move, s to restart, x to shoot darts (bullets)
# - replay option is given by popup prompt, similar to java option pane. 
# 
#####################################################################

.data 
 	displayAddress: .word 0x10008000 
 	
 	#a centipede struct has address x, int y, int direction, int isHead(0 if not, 1 if yes), int isTail(0 if not, 1 if yes)
 	#, int isDestroyed(0 if not, 1 if yes), in this order
 	#10 centipedes in total, so 4*6 * 10 = 240
 	#and centipedeStructs is an array of the all 10 structs
 	centipedeStructs: .space 240
 	numCentipede: .word 10
 	# when centipedeLives == 0, the game ends
 	centipedeLives: .word 3
 	
 	# number of mushroom on screen, initially 2
 	numMushroom: .word 25
 	#a mushroom struct has int address, int y, int isDestroyed(0 if not, 1 if yes), in this order
 	# adding 1 so that the flea may drop new mushrooms
 	# (25 + 1) * 12 = 312
 	# we need is destroyed because we don't want destroyed mushrooms reappear
 	mushroomStructs: .space 312
 	
 	# 4 bytes for the address, and 4 bytes for the y pos (for ease of calculation)
 	bugBlasterAddr: .space 8
 	
 	# int address, int y, int isDestroyed, int mushroomAddr, int mushroomY
 	fleaStruct: .space 20
 	
 	# each struct has int address, int y. The maximum number of 
 	# bullets we can have at the same time is 31 (32 - the bug blaster's loc) so this 
 	# array is 31 * 8 = 248
 	dartStructs: .word -1:248
 	# the max number of darts currently on screen
 	maxNumDarts: .word 31
 	
 	red: .word 0xff0000
	skyBlue: .word 0x87CEEB
	orange: .word 0xFFA500
	black: .word 0x000000
	green: .word 0x008000
	blue: .word 0x0000FF
	white: .word 0xFFFFFF
	
	lostGameMessage: .asciiz "You have lost :0"
	wonGameMessage: .asciiz "You have won :P "
	replayMessage: .asciiz "The game has ended. Would you like to replay?"
 	
 	
.text 
#=====================================================
#when the program first executes - init locations of
#all objects and display accordingly
#=====================================================
main: 

repaint_background:
	lw $t0, displayAddress
	addi $t1, $t0, 4096								         
	lw $t2, black			
	
	draw_bg_loop:
		sw $t2, 0($t0)				
		addi $t0, $t0, 4			
		blt $t0, $t1, draw_bg_loop

reset_mem_variables: 
	reset_flea_struct:
		la $t0, fleaStruct
		sw $zero, 0($t0)
		sw $zero, 4($t0)
		sw $zero, 8($t0)
		sw $zero, 12($t0)
		sw $zero, 16($t0)
	la $t0, dartStructs
	li $t1, -1
	lw $t2, maxNumDarts
	move $t3, $zero
	reset_dart_struct:
		beq $t3, $t2, reset_centipede_lives
		sw $t1, 0($t0)
		sw $t1, 4($t0)
		addi $t0, $t0, 8
		addi $t3, $t3, 1
		j reset_dart_struct
	reset_centipede_lives: 
		la $t0, centipedeLives
		li $t1, 3
		sw $t1 0($t0)
	la $t0, mushroomStructs
	lw $t2, numCentipede
	move $t3, $zero
	reset_centipede_struct: 
		beq $t3, $t2, reset_num_mushroom
		sw $zero, 0($t0)
		sw $zero, 4($t0)
		sw $zero, 8($t0)
		addi $t3, $t3, 1
		addi $t0, $t0, 12
	reset_num_mushroom: 
		li $t4, 25
		sw $t4, numMushroom
	end_reset:
		# continue to init
	
init_centipede_loop_prep: 
		lw $t1, numCentipede # $t1 stores the num of centipede (10)
		li $t2, 0 # $t2 stores i, initially 0
		la $t3, centipedeStructs # $t3 stores address of centipedeStructs
		li $t5, 0 #t5 stores the next x, initially 0
		lw $t6, displayAddress # $t6 stores the displayAddress
		lw $t7, red # $t7 stores the color red

# 0 pos = x, 4 pos = y, 8 pos = direction, 12 pos = isHead, 16 pos = isTail, 20 pos = isDestroyed
# we use orange for head and red for body so that checking collision
# via color is doable
init_centipede_loop:
	# if it's the last bug
	addi $t4, $t1, -1
	beq $t2, $t4, last_bug
	# if it's not the first nor last bug
	bne $t2, $zero, not_first_not_last 
	# if here, then it's the first bug
	first_bug:
		# give it a color
		sw $t7, 0($t6)
		# initialize x to displayAddress
		sw $t6, 0($t3)
		# update next x to 4 + display address
		addi $t5, $t6, 4
		#initialize isHead to 0
		li $t4, 0
		sw $t4, 12($t3)
		# initialize isTail to 1
		li $t4, 1
		sw $t4, 16($t3)
		# jump to end_if so we don't execute if block
		j end_if
	last_bug: 
		# give it color orange (which represents head)
		lw $t7, orange
		sw $t7, 0($t5)
		# initialize x to next x
		sw $t5, 0($t3)
		# initialize isHead to 1
		li $t4, 1
		sw $t4, 12($t3)
		# initialize isTail to 0
		li $t4, 0
		sw $t4, 16($t3)
		j end_if
	not_first_not_last: 
		# initialize x to next x
		add $t4, $t5, $zero
		# give it a color
		sw $t7, 0($t4)
		# save x
		sw $t4, 0($t3)
		# update next x to x + 4
		addi $t5, $t5, 4
		# initialize isHead to 0
		li $t4, 0
		sw $t4, 12($t3)
		# initialize isTail to 0
		sw $t4, 16($t3)
	end_if: 
		# initialize y to 0
		li $t4, 0
		sw $t4, 4($t3)
		# initialize direction to 1
		li $t4, 1
		sw $t4, 8($t3)
		# initialize isDestroyed to 0
		li $t4, 0
		sw $t4, 20($t3)
	update_init_centipede_loop: 
		# increment $t3 by 24, to point to next available space for next struct
		addi $t3, $t3, 24
		# increment counter by 1
		addi $t2, $t2, 1
		# branch if we've reached 10 - this can be placed here because we start with 0
		# so if this evaludates to true, we've iterated 0-9 = 10 elements
		beq $t1, $t2, end_init_centipede_loop
		j init_centipede_loop
	end_init_centipede_loop:
		# continue to prep mushrooms
		
mushroom_init_prep:
		lw $t1, numMushroom # $t1 stores the num of mushrooms
		li $t2, 0 # $t2 stores i, initially 0
		la $t3, mushroomStructs # $t3 stores address of mushroomStructs
		lw $t4, displayAddress # $t4 stores the display address
		lw $t7, green # $t7 stores the color green
	
mushroom_init_loop:
	beq $t2, $t1, end_mushroom_init_loop
	generate_x: 
		move $s2, $ra # back up register    
		# generate random x in 0-27
		jal get_random_x
		move $ra, $s2
	save_x:
		# this gets x in 2-29
		addi $a0, $a0, 2
		# multiply by 4 (offset) and store in $s0
		# shift left by 2 = times 4
		sll $s0, $a0, 2
		# add to display address
		# $t5 needs to be added the y value so we'll save later
		add $t5, $t4, $s0
	generate_y: 
		move $s2, $ra # back up register    
		# generate random y in 0-21
		jal get_random_y
		move $ra, $s2
	save_y:
		# this gets y in 1-30
		addi $a0, $a0, 1
		# multiply by 128 = shift left by 7 and store in $s1
		sll $s1, $a0, 7
		# add to display address
		add $t5, $t5, $s1
		# look at new address, if green (i.e. duplicate address) then redo the process 
		lw $t6, 0($t5)
		beq $t6, $t7, generate_x
		# save $t5 into mem and give it a color
		sw $t7, 0($t5)
		sw $t5, 0($t3) 
		# save y
		sw $a0, 4($t3)
	# isDestroyed = False
	sw $zero, 8($t3)
	# increment i
	addi $t2, $t2, 1
	# increment $t3 to point to next struct
	addi $t3, $t3, 12
	j mushroom_init_loop
	end_mushroom_init_loop:

bug_blaster_init_prep: 
	# init x
	li $t1, 16
	# init y
	li $t2, 31
	lw $t3, displayAddress
	lw $t4, white
	la $t5, bugBlasterAddr

bug_blaster_init:
	# save y 
	sw $t2, 4($t5)
	# x *= 4
	sll $t1, $t1, 2
	# y *= 128
	sll $t2, $t2, 7
	# add to display address
	add $t3, $t3, $t1
	add $t3, $t3, $t2
	# color white and save it to bugBlasterAddr
	sw $t4, 0($t3)
	sw $t3, 0($t5)

init_flea_occur_time_prep: 
	la $t0, fleaStruct
	lw $t1, displayAddress
	
# return flea occur time in $v0 
init_flea_occur_time_and_loc: 
	move $s7, $ra
	jal get_random_flea_occur_time
	move $s7, $ra
	move $v0, $a0
	move $s7, $ra
	jal get_random_flea
	move $ra, $s7
	# this gets $a0 in 12-20, not too far from bug blaster's init loc
	# so that it's defeatable
	addi $a0, $a0, 8
	# offset the random x by 4
	sll $a0, $a0, 2
	# add to displayAddress
	add $t1, $t1, $a0
	# flea's x, for mushroom generation afterwards
	move $t4, $t1
	# save to mem
	sw $t1, 0($t0)
	# y = 0 and save
	sw $zero, 4($t0)
	# isDestroyed = 0
	sw $zero, 8($t0)
	move $t2, $zero
	li $t3, 3
	get_new_mushroom: 
		# if we have tried 3 times but no luck, then we won't drop new mushrooms
		beq $t2, $t3, wont_drop_new_mushrooms
		# get random mushroom y
		move $s7, $ra
		jal get_random_flea_mushroom_y
		move $s7, $ra
		# add 16 to it 
		addi $a0, $a0, 16
		# the resulting y
		move $t9, $a0
		# offset by 7 and add to flea's x
		sll $a0, $a0, 7
		add $t5, $a0, $t4
		# check if this unit is already green (i.e. a mushroom already here)
		lw $t6, green
		lw $t7, 0($t5)
		beq $t6, $t7, need_to_try_new_mushroom
		save_locs:
			# save the result addr and y
			sw $t5, 12($t0)
			sw $t9, 16($t0)
			j end_get_new_mushroom
		need_to_try_new_mushroom:
			addi $t2, $t2, 1
			j get_new_mushroom
		wont_drop_new_mushrooms:
			# then we sub in -1 as placeholders
			li $t2, -1
			sw $t2, 12($t0)
			sw $t2, 16($t0)
	end_get_new_mushroom:
		# dont do anything
			
		
# the main method
# counter for flea
li $s6, 0
# flea's occur time
move $s7, $v0
move $a3, $zero
# $a1 == 0 -> game not end
move $a1, $zero
central_game_loop:
	li $v0, 32
	li $a0, 30
	syscall 
	
	jal check_keystroke
	jal check_darts_collision_and_move_prep
	# if structure: 
	# if (s6 == s7) paint_flea_prep
	# else if (s6 > s7) check_flea_collision_and_move_prep
	bne $s6, $s7, dont_initialize_flea
	initialize_flea: 
		bgt $s6, $s7, dont_initialize_flea
		jal paint_flea_prep
	dont_initialize_flea:
	ble $s6, $s7, dont_check_and_move_flea
	check_and_move_flea: 
		jal check_flea_collision_and_move_prep
	dont_check_and_move_flea:
	jal check_if_reach_disp_end_or_mushroom_prep
	move $a3, $v1
	jal check_if_game_ends_prep
	jal repaint_mushrooms_prep
	jal repaint_centipede_prep
	jal repaint_bug_blaster
	addi $s6, $s6, 1
	j central_game_loop

paint_flea_prep: 
	la $t0, fleaStruct
	lw $t1, skyBlue
paint_flea: 
	# paint the address skyBlue
	lw $t2, 0($t0)
	sw $t1, 0($t2)
	jr $ra

check_flea_collision_and_move_prep: 
	la $t0, fleaStruct
	lw $t1, black
	lw $t2, skyBlue
	lw $t3, white
	
check_flea_collision_and_move: 
	lw $t5, 8($t0)
	# if flea is destroyed then we don't do anything
	bnez $t5, end_check_flea_collision_and_move
	# first we check if the flea is at last row by checking if y == 31
	li $t4, 31
	lw $t5, 4($t0)
	beq $t4, $t5, flea_at_last_row
	flea_not_at_last_row: 
		# check if it's at the mushroom address already
		lw $t4, 0($t0)
		# if we don't have a mushroom, $t5 == -1 so we won't enter the loop
		lw $t5, 12($t0)
		bne $t4, $t5, continue_with_others
		should_produce_mushroom: 
			# then we save the mushroom info into mushroomStructs, and update numMushroom
			la $t6, mushroomStructs
			lw $t7, numMushroom
			# increment the structs address by numMushrooms
			# size of a single mushroom struct
			li $t8, 12
			mult $t7, $t8
			mflo $t8
			add $t6, $t6, $t8
			# set address
			sw $t4, 0($t6)
			# set y
			lw $t4, 16($t0)
			sw $t4, 4($t6)
			# set isDestroyed = 0
			sw $zero, 8($t6)
			# increment numMushroom
			addi $t7, $t7, 1
			sw $t7, numMushroom
		continue_with_others:
		# then we check if it'll run into the bug blaster by looking at its next address
		lw $t4, 0($t0)
		addi $t5, $t4, 128
		lw $t6, 0($t5)
		beq $t3, $t6, will_hit_bug_blaster
		lw $t3, blue
		beq $t3, $t6, will_hit_dart
		wont_hit_bug_blaster:
			# then paint curr address black, color and save new address
			sw $t1, 0($t4)
			sw $t2, 0($t5)
			sw $t5, 0($t0)
			# y += 1
			lw $t4, 4($t0)
			addi $t4, $t4, 1
			sw $t4, 4($t0)
			j end_check_flea_collision_and_move
		will_hit_dart: 
			# then search through the dart array for that address
			la $t7, dartStructs
			keep_incrementing_till_target_dart: 
				lw $t8, 0($t7)
				beq $t8, $t5, start_changing_dart
				addi $t7, $t7, 8
			start_changing_dart:
				sw $t1, 0($t5)
				li $t9, -1
				sw $t9, 0($t7)
				sw $t9, 4($t7)
			# then paint curr address black and set isDestroyed = 1
				sw $t1, 0($t4)
				li $t5, 1
				sw $t5, 8($t0)
				j end_check_flea_collision_and_move
		will_hit_bug_blaster: 
			# then paint curr address black and set isDestroyed = 1
			sw $t1, 0($t4)
			li $t5, 1
			sw $t5, 8($t0)
			# signifies end of game
			move $a1, $t5
			j end_check_flea_collision_and_move
	flea_at_last_row:
		# then paint curr address black and set isDestroyed = 1
			lw $t4, 0($t0)
			sw $t1, 0($t4)
			li $t5, 1
			sw $t5, 8($t0)
	end_check_flea_collision_and_move: 
		jr $ra
		
repaint_bug_blaster: 
	la $t1, bugBlasterAddr
	lw $t2, 0($t1)
	lw $t3, white
	lw $t4, 0($t2)
	beq $t3, $t4, still_white
	not_white:
		sw $t3, 0($t2)
	still_white:
		jr $ra

repaint_mushrooms_prep: 
	la $t0, mushroomStructs
	lw $t1, numMushroom
	move $t2, $zero
	
repaint_mushrooms:
	beq $t1, $t2, end_repaint_mushrooms
	# look at is destroyed.
	lw $t3, 8($t0)
	# doesn't = 0 -> destroyed
	bnez $t3, mushroom_destroyed
	not_destroyed: 
		# check if it's green
		lw $t4, green
		lw $t5, 0($t0)
		lw $t6, 0($t5)
		beq $t5, $t6, update_repaint_mushrooms
		# if not then paint
		sw $t4, 0($t5)
		j update_repaint_mushrooms
	mushroom_destroyed: 
		# check if it's black
		lw $t4, black
		lw $t5, 0($t0)
		lw $t6, 0($t5)
		beq $t5, $t6, update_repaint_mushrooms
		# if not then paint
		sw $t4, 0($t5)
	update_repaint_mushrooms:
		addi $t2, $t2, 1
		addi $t0, $t0, 12
		j repaint_mushrooms
	end_repaint_mushrooms: 
		jr $ra
repaint_centipede_prep: 
	la $t0, centipedeStructs
	lw $t1, numCentipede
	move $t2, $zero
	
repaint_centipede:
	beq $t1, $t2, end_repaint_centipede
	# look at isHead
	lw $t3, 12($t0)
	# 0 -> not head
	beqz $t3, not_head
	head: 
		# check if it's orange
		lw $t4, orange
		lw $t5, 0($t0)
		lw $t6, 0($t5)
		beq $t5, $t6, update_repaint_centipede
		# if not then paint
		sw $t4, 0($t5)
		j update_repaint_centipede
	not_head: 
		# check if it's red
		lw $t4, red
		lw $t5, 0($t0)
		lw $t6, 0($t5)
		beq $t5, $t6, update_repaint_centipede
		# if not then paint
		sw $t4, 0($t5)
	update_repaint_centipede:
		addi $t2, $t2, 1
		addi $t0, $t0, 24
		j repaint_centipede
	end_repaint_centipede: 
		jr $ra
# called when x is pressed	
init_darts_prep: 
	la $t0, dartStructs
	li $t1, -1
	move $t2, $zero
	la $t3, bugBlasterAddr
	lw $t4, maxNumDarts
	
# each dart: int address at pos 0, int y at pos 4, int hasHit at pos 8
init_darts: 
	keep_incrementing: 
		# look for the 
		li $t1, -1
		# move till we find the first -1
		lw $t5, 0($t0)
		beq $t1, $t5, start_init_darts
		# if we can't find a single -1, then there's too many on the screen already
		beq $t2, $t4, end_init_darts
		addi $t0, $t0, 8
		addi $t2, $t2, 1
	 start_init_darts: 
	 	# y location of the bug blaster is always 31, so the starting pos for darts
	 	# is always 30
	 	li $t5, 30
	 	sw $t5, 4($t0)
	 	# bug blaster's curr address
	 	lw $t5, 0($t3)
	 	# subtract it by 128 to get the unit directly above it
	 	subi $t5, $t5, 128
	 	# color it blue and save it 
	 	lw $t6, blue
	 	sw $t6, 0($t5)
	 	sw $t5, 0($t0)
	 end_init_darts: 
	 	jr $ra


check_darts_collision_and_move_prep: 
	la $t0, dartStructs
	lw $t1, maxNumDarts
	la $t2, bugBlasterAddr
	move $t3, $zero
# recap: 
# centipede head: orange
# centipede body: red
# mushroom: green
# dart: blue
# flea: skyBlue
check_darts_collision_and_move: 
	beq $t3, $t1, end_check_darts_collision_and_move
	# look at the address, if it's -1 then we skip
	lw $t4, 0($t0)
	li $t5, -1
	beq $t4, $t5, increment_darts_loop
	check_darts_collision: 
		# first check if it's at the first row
		# this is easy because we do save y
		lw $t4, 4($t0)
		# y = 0 -> first row -> this bullet needs to disappear
		beqz $t4, destroy_bullet
		not_at_first_row: 
			# then we check collisions with game objects by looking at the next address (subtracting 128)
			lw $t4, 0($t0)
			subi $t4, $t4, 128
			# look at the new address's color
			lw $t5, 0($t4)
			lw $t6, orange
			beq $t5, $t6, will_hit_centipede
			lw $t6, red
			beq $t5, $t6, will_hit_centipede
			lw $t6, green
			beq $t5, $t6, will_hit_mushroom
			lw $t6, skyBlue
			beq $t5, $t6, will_hit_flea
			wont_hit_anything: 
				# great, then we just draw the bullet
				# color curr address black
				lw $t6, 0($t0)
				lw $t7, black
				sw $t7, 0($t6)
				# color and save new address 
				lw $t7, blue
				sw $t7, 0($t4)
				sw $t4, 0($t0)
				# decrement and save y
				lw $t6, 4($t0)
				subi $t6, $t6, 1
				sw $t6, 4($t0)
				j increment_darts_loop
			will_hit_centipede: 
				# then we decrease centipedeLives and destroy the bullet
				la $t6, centipedeLives
				lw $t7, 0($t6)
				subi $t7, $t7, 1
				sw $t7, 0($t6)
				j destroy_bullet
			will_hit_mushroom: 
				# then we set that mushroom's isDestroyed to 1, paint it black, and destroy the bullet
				la $t5, mushroomStructs
				keep_incrementing_mushroomStructs:
					# look at curr mushroom's address
					lw $t6, 0($t5)
					# this works because we guarantee no mushrooms have 
					# duplicate address
					beq $t6, $t4, start_updating_mushroom
					addi $t5, $t5, 12
					j keep_incrementing_mushroomStructs
				start_updating_mushroom: 
					# isDestroyed = 1 
					# we don't change numMushrooms because technically that mushroom is 
					# "still there"
					li $t7, 1
					sw $t7, 8($t5)
				j destroy_bullet
			will_hit_flea: 
				# then we set flea's isDestroyed to True, paint it black, and destroy the bullet
				la $t5, fleaStruct
				li $t7, 1
				sw $t7, 8($t5)
				lw $t7, black
				lw $t8, 0($t5)
				sw $t7, 0($t8)
		destroy_bullet: 
			# color curr address black
			lw $t6, 0($t0)
			lw $t7, black
			sw $t7, 0($t6)
			# reset everything to -1
			li $t5, -1
			sw $t5, 0($t0)
			sw $t5, 4($t0)
	increment_darts_loop: 
		addi $t0, $t0, 8
		addi $t3, $t3, 1
		j check_darts_collision_and_move
	end_check_darts_collision_and_move: 
		jr $ra
move_centipede_except_head_prep: 
	la $t1, centipedeStructs
	lw $t2, black
	lw $t3, red
	lw $t4, numCentipede
	li $t5, 0
	
# 0 pos = address, 4 pos = y, 8 pos = direction, 12 pos = isHead, 16 pos = isTail, 20 pos = isDestroyed
# called by other functions to move bugs 0 - 8 (everything except head) based on their previous indexes
# a2 = 0 if not used, otherwise the old address of head
move_centipede_except_head:
	subi $t4, $t4, 1
	li $t9, 8
	start_moving:
		# only move 0-8 
		beq $t5, $t4, moved_everything
		# direction = next index's direction
		# next direction's pos = 24 + 8 = 32
		lw $t6, 32($t1)
		sw $t6, 8($t1)
		# y = next index's y
		# next y's pos = 24 + 4 = 28
		
		# next index's y
		lw $t6, 28($t1)
		# y = next y
		sw $t6, 4($t1)
		# curr address = next index's address
		# next address's pos = 24 + 0 = 24
		lw $t6, 24($t1)
		# if tail, color old black and new red
		# if not tail, color new red
		lw $t8, 16($t1)
		beqz $t8, not_tail
		beq $t5, $t9, last_before_head
		# save the address after coloring
		is_tail: 
			# color old address to black
			lw $t8, 0($t1)
			sw $t2, 0($t8)
			j save_new_address
		last_before_head: 
			beqz $a2, save_new_address
			move $t6, $a2
			move $a2, $zero
			j save_new_address
		not_tail: 
			# if next address not red then color new address to red
			lw $t7, 0($t6)
			beq $t7, $t3, save_new_address
			sw $t3, 0($t6)
		save_new_address: 
			sw $t6, 0($t1)
		update_move_centipede_except_head:
			addi $t5, $t5, 1
			addi $t1, $t1, 24
			j start_moving
	moved_everything:
		jr $ra
		
# 0 pos = x, 4 pos = y, 8 pos = direction, 12 pos = isHead, 16 pos = isTail, 20 pos = isDestroyed
check_if_reach_disp_end_or_mushroom_prep:
	la $t1, centipedeStructs
	lw $t2, numCentipede
	li $t3, 0
	lw $s0, displayAddress

# TODO: change to each index watching its next index (i.e. 1 watching 2, 2 watching 3...), except head
# if flag $a3 = 1, then head should drop one line below, otherwise flag = 0, move normally
check_if_reach_disp_end_or_mushroom: 
	bnez $a3, move_head_one_unit_down
	check_head:
		# first check if with next move the head will reach a mushroom
		# by looking at next address
		check_if_reach_mushroom: 
			# head is ALWAYS 9
			lw $t4, 216($t1)
			# check direction and add accordingly
			lw $t5, 224($t1)
			li $t6, 1
			beq $t5, $t6, dir_is_pos
			dir_is_neg: 
				subi $t7, $t4, 4
				j check_color
			dir_is_pos: 
				addi $t7, $t4, 4
			# now we have the next address, look at its color
			check_color: 
				lw $t5, green
				lw $t6, 0($t7)
				beq $t5, $t6, head_will_reach_end
				# check if it'll reach the bug blaster
				lw $t5, white
				bne $t5, $t6, centipede_wont_hit_bug_blaster
				li $t5, 1
				move $a1, $t5
		centipede_wont_hit_bug_blaster: 
		# if it won't reach mushroom nor bug blaster
		# then we first color and save the head's new address
		# then everything else and check if the head'll go over an edge after next move
		move $s2, $t7
		move $s1, $ra # back up register
		jal move_centipede_except_head_prep
		move $ra, $s1 # restore register
		move $t7, $s2
		la $t1, centipedeStructs
		lw $t2, numCentipede
		lw $t5, orange
		sw $t5, 0($t7)
		sw $t7, 216($t1)
		# head is ALWAYS 9
		lw $t4, 216($t1)
		# if it's at an edge then (address - display) % 124 will = 0
		check_head_mod_val: 
			# subtract displayAddress from it
			sub $t4, $t4, $s0
			# subtract the y offsets
			lw $t5, 220($t1)
			sll $t6, $t5, 7
			sub $t4, $t4, $t6 
			# divide by 124
			# 124 because we start at displayAddress, not displayAddress + 4
			li $t5, 124
			div $t4, $t5
			# check the remainder 
			# if the remainder is 0 then head is either at the left or right edge of disp
			mfhi $s4
			beqz $s4, head_will_reach_end
			head_wont_reach_end:
				move $v1, $zero
				j end_check_if_reach_disp_end_or_mushroom
			head_will_reach_end:
				# then $v1 = flag = -1
				li $v1, 1
				j end_check_if_reach_disp_end_or_mushroom
	# then the bug at index is at edge, and we need to move accordingly
	move_head_one_unit_down:
		# move $t1 to point to head struct (i.e. last index)
		addi $t1, $t1, 216
		# update direction
		lw $t5, 8($t1)
		li $t6, 1
		beq $t5, $t6, update_to_neg
		update_to_pos:
			li $t6, 1
			sw $t6, 8($t1)
			j keep_going
		update_to_neg:
			li $t6, -1
			sw $t6, 8($t1)
		keep_going: 
		# if it's already 31 then we should not move it to the next row
		# instead just do a direction *= -1 and move by direction * 4
		lw $t5, 4($t1)
		li $t7, 31
		beq $t5, $t7, at_last_row
		not_at_last_row: 
			move $s1, $ra # back up register
			jal move_centipede_except_head_prep
			move $ra, $s1 # restore register
			# reload registers
			la $t1, centipedeStructs
			lw $t2, numCentipede
			# move $t1 to point to head struct (i.e. last index)
			addi $t1, $t1, 216
			# update y = y + 1
			lw $t5, 4($t1)
			addi $t5, $t5, 1
			# save y 
			sw $t5, 4($t1)
			# old address
			lw $t7, 0($t1)
			# add 128 to this address to make it the unit directly below it
			addi $t8, $t7, 128
			# color the new address orange and save the new address
			lw $t6, orange
			sw $t6, 0($t8)
			sw $t8, 0($t1)
			move $a2, $t7
			j set_return_index
		at_last_row: 
			move $s1, $ra # back up register
			jal move_centipede_except_head_prep
			move $ra, $s1 # restore register
			# reload registers
			la $t1, centipedeStructs
			lw $t2, numCentipede
			# move $t1 to point to head struct (i.e. last index)
			addi $t1, $t1, 216
			lw $t6, 8($t1)
			# direction * 4
			li $t8, 4
			mult $t8, $t6
			mflo $s2
			# old x address
			lw $s0, 0($t1)
			# new x address = old address + direction * 4
			add $s0, $s0, $s2
			lw $t6, orange
			sw $t6, 0($s0)
			# save the new address
			sw $s0, 0($t1)
		set_return_index: 
			move $v1, $zero
		end_check_if_reach_disp_end_or_mushroom:
			jr $ra
		

# This function assumes that edge(s) of disp wont be reached
# a2 = 0 if last is head, else first is head
# TODO: we should call check_if_reach_end in this function, so that we can decide on the index value 

get_random_x:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 27      
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
  	
get_random_y:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0         # Select random generator 0
  	li $a1, 29      
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
  	
get_random_flea:
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0         # Select random generator 0
  	li $a1, 12      
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
	
get_random_flea_occur_time:
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0         # Select random generator 0
  	li $a1, 300      
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
  	
get_random_flea_mushroom_y:
	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0         # Select random generator 0
  	li $a1, 14      
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
  
# function to detect any keystroke for j and k
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	li $t9, 1
	beq $t8, $t9, get_keyboard_input # if key is pressed, jump to get this key
	move $t8, $zero
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	move $v0, $zero	#default case
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of j key
respond_to_j:
	la $t0, bugBlasterAddr	# load the address of bug location and its y
	lw $t1, 0($t0)		# load the bug blaster location itself into t1
	
	lw $s0, displayAddress
	# subtract displayAddress from it
	sub $t2, $t1, $s0
	# subtract the y offsets
	lw $t3, 4($t0)
	sll $t6, $t3, 7
	sub $t2, $t2, $t6 
	# check if it equals 0 (i.e. since the end of first row = display address + 28)
	# if it does then we're already at the left edge 
	beqz $t2, skip_movement
	# otherwise we continue, starting with painting the old address black
	lw $t2, black
	sw $t2, 0($t1)
	# then we subtract 4 from the old address
	lw $t2, 0($t0)
	subi $t2, $t2, 4
	# paint it white, and save it
	lw $t3, white
	sw $t3, 0($t2)
	sw $t2, 0($t0)
skip_movement:
	jr $ra

# Call back function of k key
respond_to_k:
	la $t0, bugBlasterAddr	# load the address of bug location and its y
	lw $t1, 0($t0)		# load the bug blaster location itself into t1
	
	lw $s0, displayAddress
	# TODO: j should only check left (done) and k should only check right
	# subtract displayAddress from it
	sub $t2, $t1, $s0
	# subtract the y offsets
	lw $t3, 4($t0)
	sll $t6, $t3, 7
	sub $t2, $t2, $t6 
	# check if it equals 124 (i.e. since the end of first row = display address + 124)
	# if it does then we're already at the right edge 
	li $t5, 124
	beq $t2, $t5, skip_movement2
	# otherwise we continue, starting with painting the old address black
	lw $t2, black
	sw $t2, 0($t1)
	# then we add 4 to the old address
	lw $t2, 0($t0)
	addi $t2, $t2, 4
	# paint it white, and save it
	lw $t3, white
	sw $t3, 0($t2)
	sw $t2, 0($t0)
skip_movement2:
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal init_darts_prep
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	j disp_replay_msg
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# if $a1 == 1 then the game has ended (so either flea or centipede hits bug blaster)
# if centipedeLives == 0 then game has ended
check_if_game_ends_prep: 
	lw $t0, centipedeLives

check_if_game_ends: 
	beqz $t0, won_game
	li $t1, 1
	beq $t1, $a1, lost_game
	dont_end_game: 
		j end_check_if_game_ends
	lost_game: 
		li $v0, 56 #syscall value for dialog
		la $a0, lostGameMessage #get message
		syscall
		j disp_replay_msg
	won_game: 
		li $v0, 56 #syscall value for dialog
		la $a0, wonGameMessage #get message
		syscall
	disp_replay_msg: 
		li $v0, 50 #syscall for yes/no dialog
		la $a0, replayMessage #get message
		syscall
	
		beqz $a0, main#jump back to start of program
		j exit
	end_check_if_game_ends:
		jr $ra
exit: 
 	li $v0, 10 # terminate the program gracefully 
 	syscall
