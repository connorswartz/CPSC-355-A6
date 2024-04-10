// File: a6.asm
// Author: Connor Swartz
// Date: April 10, 2022
//
// Description: 
// Compute the functions e^x and e^-x using a given set of series expansions. 
// The program will read a series of input values from a file whose name is specified at the command line.
// Read from the file using system I/O. Process the input values one at a time using a loop, calculate e^x and e^-x,
// then print out the input value and its corresponding output values in table form 
// (i.e. in columns, with column headings) to the screen.
// Prints out all values with a precision of 10 decimal digits to the right of the decimal point.
//


define(lr, x30)
define(fp, x29)
define(argc_r, w28)
define(argv_r, x27)
define(arg1, w25)
define(arg2, w24)

define(limit, d28)
define(neg_num, d27)
define(pos_num, d26)
define(denom, d25)
define(factorial, d24)
define(neg_total, d23)
define(pos_total, d22)
define(neg_term, d21)
define(pos_term, d20)
define(const, d19)


fd_o = 16							// Define the offset of fd_o
bytes_read_o = 20						// Define the offset of bytes_read_o
value_o = 24							// Define the offset of value_o


		.data						// .data section (read and write data) initialized by programmer
		.balign 8					// 8 byte alignment
stop:		.double 0r1.0e-10				// Initialized double value

		.balign 4					// 4 byte alignment
error_1:	.string "Usage: a6 <filename.bin>\n"		// Store string in memory with label
error_2:	.string "Incorrect number of bytes\n"		// Store string in memory with label

separate1:	.string " _______________________________________________________________________________\n" 	// Store string/label
col_head:	.string "|         Input value		|          e^x          |         e^-x          |\n" 	// Store string/label
separate2:	.string " -------------------------------------------------------------------------------\n"	// Store string/label
col_vals:	.string "|	  %.10f		|     %.10f	|     %.10f	|\n"				// Store string/label
file_end:	.string "End of file\n"										// Store string/label

		.text						// .text section (read data)
		.balign 4					// 4 byte alignment

		.global main					// Ensure "main" is visible to linker

ex:
		stp	fp, lr, [sp, -16]!			// Load frame pointer (FP) and link register (LR) to the stack
		mov	fp, sp					// Set FP to the top of the stack

		fneg	d9, d0					// Negate d0 (x) and store in d9

		fmov	neg_num, d9				// Set neg_num to d9 (-x)
		fmov	pos_num, d0				// Set pos_num to d0 (x)

		fmov	denom, 1.0				// Set denom to 1.0
		fmov	factorial, 1.0				// Set factorial to 1.0
		fmov	const, 1.0				// Set const to 1.0

		adrp	x11, stop				// Load stop (1.0e-10) into x11
		add	x11, x11, :lo12:stop			// Load stop (1.0e-10) into x11
		ldr	limit, [x11]				// Load x11 (1.0e-10) into limit

		fadd	neg_total, const, neg_num		// Add const (1.0) and neg_num (-x) and store in neg_total
		fadd	pos_total, const, pos_num		// Add const (1.0) and pos_num (x) and store in pos_total

ex_loop:
		fmul	neg_num, neg_num, d9			// Multiply neg_num and d9 (-x) and store in neg_num
		fmul	pos_num, pos_num, d0			// Multiply pos_num and d0 (x) and store in pos_num

		fadd	factorial, factorial, const		// Add factorial and const (1.0) and store in factorial
		fmul	denom, denom, factorial			// Multiply denom by factorial and store in denom

		fdiv	neg_term, neg_num, denom		// Divide neg_num by denom and store in neg_term
		fdiv	pos_term, pos_num, denom		// Divide pos_num by denom and store in pos_term

		fadd	neg_total, neg_total, neg_term		// Add neg_total and neg_term and store in neg_total
		fadd	pos_total, pos_total, pos_term		// Add pos_total and pos_term and store in pos_total

		fcmp	pos_term, limit				// Compare pos_term to limit (1.0e-10)
		b.ge	ex_loop					// Branch to ex_loop if pos_term >= limit (1.0e-10)

print_vals:
		ldr	x0, =col_vals				// Load col_vals into x0
		fmov	d1, pos_total				// Set d1 to pos_total
		fmov	d2, neg_total				// Set d2 to neg_total
		bl	printf					// Call print

ex_end:
		ldp	fp, lr, [sp], 16			// Clean lines and restore the stack
		ret						// Return



// ************************* MAIN *************************
main:
		stp	fp, lr, [sp, -32]!			// Save frame pointer (FP) and link register (LR) to the stack
		mov	fp, sp					// Set FP to the top of the stack

		mov	argc_r, w0				// Set argc_r to w0 (number of arguments)
		mov	argv_r, x1				// Set argv_r to x1 (array of arguments)
		mov	arg1, 0					// Set arg1 to 0
		mov	arg2, 1					// Set arg2 to 1

		cmp	argc_r, 2				// Compare argc_r to 2 (make sure only two command line arguments)
		b.eq	open					// Branch to open if argc_r == 2

		ldr	x0, =error_1				// Load error_1 into x0
		bl	printf					// Call print

		b	end					// Branch to end

open:
		mov	w0, -100				// Move AT_FDCWD = -100 into w0

		ldr	x1, [argv_r, arg2, SXTW 3]		// Load second argument in argv_r into x1
		mov	w2, 0					// Read only
		mov	w3, 0666				// Permissions

		mov	x8, 56					// 56 = openat ID
		svc	0					// openat(-100, filename, 0, 0666)

		str	w0, [fp, fd_o]				// Store w0 into fd_o

		cmp	w0, -1					// Compare w0 to -1
		b.gt	header					// Branch to header if w0 is greater than -1

		mov	x0, -1					// Set x0 to -1

		b	end					// Branch to end

header:
		ldr	x0, =separate1				// Load separate1 into x0
		bl	printf					// Call print

		ldr	x0, =col_head				// Load col_head into x0
		bl	printf					// Call print

		ldr	x0, =separate2				// Load separate2 into x0
		bl	printf					// Call print

read:
		ldr	w0, [fp, fd_o]				// Load fd_o into w0

		add	x1, fp, value_o				// Set x1 to address of value on the stack

		mov	w2, 8					// Set w2 to size to read (8 bytes)

		mov	x8, 63					// 63 = read ID
		svc	0					// read(fd, &value, 8)

		str	w0, [fp, bytes_read_o]			// Store the bytes read into w0
		cmp	w0, 1					// Compare w0 to 1
		b.gt	compute					// Branch to compute if w0 is greater than one

		ldr	x0, =separate2				// Load separate2 into x0
		bl	printf					// Call print

		ldr	x0, =file_end				// Load file_end
		bl	printf					// Call print

		b	close					// Branch to close

compute:
		ldr	d0, [fp, value_o]			// Load value into d0
		bl	ex					// Branch to ex

		b	read					// Branch to read

close:
		ldr	w0, [x29, fd_o]				// Load fd_o into w0
		mov	x8, 57					// 57 = close ID
		svc	0					// close(fd)

end:
		ldp	fp, lr, [sp], 32			// Clean lines and restore the stack
		ret						// Return
