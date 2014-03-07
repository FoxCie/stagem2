	.file	"first.c"
	.intel_syntax noprefix
	.section	.rodata
.LC0:
	.string	"%s "
	.text
	.globl	main
	.type	main, @function
main:
.LFB2:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 32
	mov	DWORD PTR [rbp-20], edi
	mov	QWORD PTR [rbp-32], rsi
	mov	DWORD PTR [rbp-4], 1
	jmp	.L2
.L3:
	mov	eax, DWORD PTR [rbp-4]
	cdqe
	lea	rdx, [0+rax*8]
	mov	rax, QWORD PTR [rbp-32]
	add	rax, rdx
	mov	rax, QWORD PTR [rax]
	mov	rsi, rax
	mov	edi, OFFSET FLAT:.LC0
	mov	eax, 0
	call	printf
	add	DWORD PTR [rbp-4], 1
.L2:
	mov	eax, DWORD PTR [rbp-4]
	cmp	eax, DWORD PTR [rbp-20]
	jl	.L3
	mov	eax, 0
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	main, .-main
	.ident	"GCC: (Debian 4.8.2-16) 4.8.2"
	.section	.note.GNU-stack,"",@progbits
