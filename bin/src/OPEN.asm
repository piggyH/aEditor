INCLUDE MACRO.ASM

PUBLIC _OPEN_FILE
PUBLIC _SAVE_FILE

EXTRN _DISPLAY_STRING:FAR

DATA SEGMENT
	BMP_HEADER			DB		42H,4DH,0F6H,0BDH,01H,00H,00H,00H,00H,00H,76H,00H,00H,00H,28H,00H
						DB		00H,00H,10H,02H,00H,00H,0B0H,01H,00H,00H,01H,00H,04H,00H,00H,00H
						DB		00H,00H,80H,0BDH,01H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
						DB		00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,80H,00H,00H,80H
						DB		00H,00H,00H,80H,80H,00H,80H,00H,00H,00H,80H,00H,80H,00H,80H,80H
						DB		00H,00H,80H,80H,80H,00H,0C0H,0C0H,0C0H,00H,00H,00H,0FFH,00H,00H,0FFH
						DB		00H,00H,00H,0FFH,0FFH,00H,0FFH,00H,00H,00H,0FFH,00H,0FFH,00H,0FFH,0FFH
						DB		00H,00H,0FFH,0FFH,0FFH,00H
	FILE_NAME1			DB  'NAME1.BMP',0
	FILE_NAME2          DB  'NAME2.BMP',0
	BMP_HEAD			DB	54   DUP(?)     ;存放位图的头信息
	BMP_PAL				DB	64   DUP(?)     ;存放位图文件的调色板信息（256色×4=1024B）
	BMP_DATA			DB	4224 DUP(?)     ;存放图片信息	
    BUG                 DB 'BUG !!!'	
DATA ENDS

DATA3 SEGMENT
	X      DW ?
	Y      DW ?
	COLOR  DB ?
	
DATA3 ENDS

__CHANGE_COLOR MACRO COLOR
	LOCAL L1,L2,FINISH
	CMP COLOR,04H
	JZ L1
	CMP COLOR,01H
	JZ L1
	CMP COLOR,07H
	JZ L2
	CMP COLOR,08H
	JZ L2
	CMP COLOR,09H
	JZ L1
	CMP COLOR,0CH
	JZ L1
	CMP COLOR,0EH
	JZ L1
	CMP COLOR,0BH
	JZ L1
	JMP FINISH
L1:
	XOR COLOR,05H
	JMP FINISH
L2:
	XOR COLOR,0FH
FINISH:
ENDM
	
__DISPLAY_FILE_BLOCK MACRO INIT_X,INIT_Y  ;读入一行16x528像素
	LOCAL FINISH,INNER_LOOP,OUTER_LOOP,L1
	__PUSH_REGS
	PUSH DS
	PUSH ES
	PUSH SI
	
	MOV AX,DATA
	MOV DS,AX
	MOV AX,DATA3
	MOV ES,AX
	
	LEA SI,BMP_DATA
	MOV AX,INIT_Y
	MOV ES:Y,AX
	MOV CX,16
OUTER_LOOP:
	PUSH CX
	MOV AX,INIT_X
	MOV ES:X,AX
	MOV CX,264
INNER_LOOP:
	MOV AL,[SI]
	MOV ES:COLOR,0F0H
	AND ES:COLOR,AL
	SHR ES:COLOR,1
	SHR ES:COLOR,1
	SHR ES:COLOR,1
	SHR ES:COLOR,1
	;;;	
	__CHANGE_COLOR ES:COLOR
	__WRITE_PIXEL ES:X,ES:Y,ES:COLOR
	INC ES:X
	MOV ES:COLOR,0FH
	AND ES:COLOR,AL
	;;;
	__CHANGE_COLOR ES:COLOR
	__WRITE_PIXEL ES:X,ES:Y,ES:COLOR
	INC ES:X
	INC SI
	DEC CX
	CMP CX,0
	JZ L1
	JMP INNER_LOOP
	
L1:	;LOOP INNER_LOOP
	POP CX
	DEC ES:Y
	DEC CX
	CMP CX,0
	JZ FINISH
	JMP OUTER_LOOP
FINISH:
	POP SI
	POP ES
	POP DS
	__POP_REGS
ENDM

CODE SEGMENT
    ASSUME CS:CODE,DS:DATA,ES:DATA3

_OPEN_FILE PROC FAR
	__PUSH_REGS
	PUSH DS
	PUSH ES
	PUSH SI
	PUSH DI

	MOV AX,DATA3
	MOV ES,AX
    MOV AX,DATA
	MOV DS,AX
	
OPEN_FILE:
	MOV	AH,3DH                        ;以读方式打开文件
	MOV	AL,02H
	LEA	DX,FILE_NAME1
	INT	21H
	MOV BX,AX                        ;BX保存打开文件号
	JNC FILE_OPENED
	CMP AX,2
	JNZ TESTBUG1
	__DISPLAY_STRING 12,10,DATA,BUG,7,04H
TESTBUG1:
	JMP OPEN_FILE_FINISH                       ;文件打开失败
	
FILE_OPENED:
	MOV AH,3FH
	MOV AL,0
	MOV CX,118
	MOV DX,OFFSET BMP_HEAD           ;读文件信息头
	INT 21H
	
	MOV DI,463                   ;用于控制读取每行数据的Y坐标
	MOV CX,27                     ;共读取27行16x528像素数据
	MOV DX,OFFSET BMP_DATA
READ_DATA:                       ;读数据块
	PUSH CX
	MOV AH,3FH
	MOV CX,4224
	INT 21H
	;;;;;此时AX为实际读取字节数或错误代码
	__DISPLAY_FILE_BLOCK 8,DI   ;;;;;;
	SUB DI,16
	POP CX
	DEC CX
	CMP CX,0
	JZ CLOSE_FILE
	JMP READ_DATA
	
CLOSE_FILE:
	MOV AH,3EH
	INT 21H
	JNC OPEN_FILE_FINISH
	
OPEN_FILE_FINISH:			
	POP DI
	POP SI
	POP ES
	POP DS
	__POP_REGS	
	RET
_OPEN_FILE ENDP


__READ_SCREEN_BLOCK MACRO INIT_X,INIT_Y
	LOCAL FINISH,INNER_LOOP,OUTER_LOOP,L1
	__PUSH_REGS
	PUSH DS
	PUSH ES
	PUSH SI
	
	MOV AX,DATA
	MOV DS,AX
	MOV AX,DATA3
	MOV ES,AX
	
	LEA SI,BMP_DATA
	MOV AX,INIT_Y
	MOV ES:Y,AX
	MOV CX,16
OUTER_LOOP:
	PUSH CX
	MOV AX,INIT_X
	MOV ES:X,AX
	MOV CX,264
INNER_LOOP:
	__READ_PIXEL ES:X,ES:Y
	__CHANGE_COLOR AL
	MOV [SI],AL
	SHL BYTE PTR[SI],1
	SHL BYTE PTR[SI],1
	SHL BYTE PTR[SI],1
	SHL BYTE PTR[SI],1
	INC ES:X
	__READ_PIXEL ES:X,ES:Y
	__CHANGE_COLOR AL
	AND AL,0FH
	ADD [SI],AL
	INC ES:X
	INC SI
	DEC CX
	CMP CX,0
	JZ L1
	JMP INNER_LOOP
L1:	;LOOP INNER_LOOP
	POP CX
	DEC ES:Y
	DEC CX
	CMP CX,0
	JZ FINISH
	JMP OUTER_LOOP
FINISH:
	POP SI
	POP ES
	POP DS
	__POP_REGS
ENDM

_SAVE_FILE PROC FAR
	__PUSH_REGS
	PUSH DS
	PUSH ES
	PUSH SI
	PUSH DI
	
	MOV AX,DATA3
	MOV ES,AX
	MOV AX,DATA
	MOV DS,AX
	
BUILD_FILE:  ;;新建一个文件
	MOV DX,OFFSET FILE_NAME2
	MOV CX,0 ;;读写
	MOV AH,3CH
	INT 21H
	JNC FILE_OPENED_1
	CMP AX,2
	JNZ TESTBUG
	__DISPLAY_STRING 14,10,DATA,BUG,7,01H
TESTBUG:
	JMP SAVE_FILE_FINISH
FILE_OPENED_1:
	MOV BX,AX  ;;BX文件号
	;;写文件头
	MOV DX,OFFSET BMP_HEADER
	MOV CX,118
	MOV AH,40H
	INT 21H
	
	MOV DI,463
	MOV CX,27
	MOV DX,OFFSET BMP_DATA
WRITE_DATA:
	__READ_SCREEN_BLOCK 8,DI   ;;读一行屏幕内容
	PUSH CX
	MOV AH,40H
	MOV CX,4224
	INT 21H
	SUB DI,16
	POP CX
	DEC CX
	CMP CX,0
	JZ SAVE_FILE_FINISH
	JMP WRITE_DATA

SAVE_FILE_FINISH:
	POP DI
	POP SI
	POP ES
	POP DS
	__POP_REGS
	RET
_SAVE_FILE ENDP

CODE ENDS
END	
