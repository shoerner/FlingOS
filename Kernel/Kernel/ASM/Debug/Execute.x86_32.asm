﻿; - - - - - - - - - - - - - - - - - - - LICENSE - - - - - - - - - - - - - - - -  ;
;
;    Fling OS - The educational operating system
;    Copyright (C) 2015 Edward Nutting
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http:;www.gnu.org/licenses/>.
;
;  Project owner: 
;		Email: edwardnutting@outlook.com
;		For paper mail address, please contact via email for details.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ;

BITS 32

SECTION .text

GLOBAL BasicDebug_Execute:function
GLOBAL BasicDebug_SetInt1TrapFlag:function
GLOBAL BasicDebug_ClearInt1TrapFlag:function
GLOBAL BasicDebug_SetInt3:function
GLOBAL BasicDebug_ClearInt3:function

EXTERN BasicDebug_WaitForCommand
EXTERN BasicDebug_ContinueCmd
EXTERN BasicDebug_StepNextCmd
EXTERN BasicDebug_GetBreakAddressCmd
EXTERN BasicDebug_GetRegistersCmd
EXTERN BasicDebug_GetArgumentsCmd
EXTERN BasicDebug_GetLocalsCmd
EXTERN BasicDebug_SetInt3Cmd
EXTERN BasicDebug_ClearInt3Cmd
EXTERN BasicDebug_GetMemoryCmd

EXTERN BasicDebug_SendBreakCmd
EXTERN BasicDebug_SendBreakAddress
EXTERN BasicDebug_SendRegisters
EXTERN BasicDebug_SendArguments
EXTERN BasicDebug_SendLocals
EXTERN BasicDebug_SendMemory

EXTERN BasicDebug_CallerESP

EXTERN method_System_UInt32_Kernel_Debug_BasicDebug_Serial_ReadUInt32__

; BEGIN - BasicDebug_Execute
; See BasicDebug_InterruptHandler for global variables

BasicDebug_Execute:

push dword ebp
mov dword ebp, esp

call BasicDebug_SendBreakCmd

BasicDebug_ExecuteLoop:

call BasicDebug_WaitForCommand
; Command received stored in AL

; Continue command
cmp al, [BasicDebug_ContinueCmd]
jne BasicDebug_Execute_Skip1
jmp BasicDebug_ExecuteLoop_Leave
BasicDebug_Execute_Skip1:
 
; Step Next command
cmp al, [BasicDebug_StepNextCmd]
jne BasicDebug_Execute_Skip2
call BasicDebug_SetInt1TrapFlag
jmp BasicDebug_ExecuteLoop_Leave
BasicDebug_Execute_Skip2:
 
; Get Break Address command
cmp al, [BasicDebug_GetBreakAddressCmd]
jne BasicDebug_Execute_Skip3
call BasicDebug_SendBreakAddress
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip3:
 
; Get Registers command
cmp al, [BasicDebug_GetRegistersCmd]
jne BasicDebug_Execute_Skip4
call BasicDebug_SendRegisters
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip4:

; Get Arguments command
cmp al, [BasicDebug_GetArgumentsCmd]
jne BasicDebug_Execute_Skip5
call BasicDebug_SendArguments
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip5:

; Get Locals command
cmp al, [BasicDebug_GetLocalsCmd]
jne BasicDebug_Execute_Skip6
call BasicDebug_SendLocals
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip6:

; Set Int3 command
cmp al, [BasicDebug_SetInt3Cmd]
jne BasicDebug_Execute_Skip7
call BasicDebug_SetInt3
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip7:

; Clear Int3 command
cmp al, [BasicDebug_ClearInt3Cmd]
jne BasicDebug_Execute_Skip8
call BasicDebug_ClearInt3
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip8:

; Get Memory command
cmp al, [BasicDebug_GetMemoryCmd]
jne BasicDebug_Execute_Skip9
call BasicDebug_SendMemory
jmp BasicDebug_ExecuteLoop_Continue
BasicDebug_Execute_Skip9:

BasicDebug_ExecuteLoop_Continue:

mov eax, 0
jmp BasicDebug_ExecuteLoop
BasicDebug_ExecuteLoop_Leave:

pop dword ebp

ret


BasicDebug_SetInt1TrapFlag:
push ebp
push eax

; Load the stack to the correct location for accessing EFLAGS
; This is lower down the stack than EFLAGS
mov ebp, [BasicDebug_CallerESP]

; Set the Trap Flag (http://en.wikipedia.org/wiki/Trap_flag)
; For EFLAGS we want - the interrupt frame = ESP - 12
;					 - The interrupt frame + 8 for correct byte = ESP - 12 + 8 = ESP - 4
;					 - Therefore, ESP - 4 to get to the correct position
sub ebp, 4
mov eax, [ebp]
or eax, 0x0100
mov [ebp], eax

pop eax
pop ebp
ret


BasicDebug_ClearInt1TrapFlag:
push ebp
push eax

; See SetInt1TrapFlag
mov ebp, [BasicDebug_CallerESP]

sub ebp, 4
mov eax, [ebp]
and eax, 0xFEFF
mov [ebp], eax

pop eax
pop ebp
ret



BasicDebug_SetInt3:
push ebp
push eax

; Get the address to set Int3 at
call method_System_UInt32_Kernel_Debug_BasicDebug_Serial_ReadUInt32__
; Set the Int3
mov byte [eax], 0xCC

pop eax
pop ebp
ret


BasicDebug_ClearInt3:
push ebp
push eax

; Get the address to clear Int3 at
call method_System_UInt32_Kernel_Debug_BasicDebug_Serial_ReadUInt32__
; Clear the Int3 to 1-byte Nop
mov byte [eax], 0x90

pop eax
pop ebp
ret


; END - BasicDebug_Execute