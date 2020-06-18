; Input:
; ESI = pointer to the string to convert
; ECX = number of digits in the string (must be > 0)
; Output:
; EAX = integer value
string_to_int:
    xor ebx,ebx    ; clear ebx
    .next_digit:
    movzx eax,byte[esi]
    inc esi
    sub al,'0'    ; convert from ASCII to number
    imul ebx,10
    add ebx,eax   ; ebx = ebx*10 + eax
    loop .next_digit  ; while (--ecx)
    mov eax,ebx
    ret

; Input:
; EAX = integer value to convert
; ESI = pointer to buffer to store the string in (must have room for at least 10 bytes)
; Output:
; EAX = pointer to the first character of the generated string
int_to_string:
    add esi,9
    mov byte [esi],0x00    
    mov ebx,10         
    .next_digit:
    xor edx,edx         ; Clear edx prior to dividing edx:eax by ebx
    div ebx             ; eax /= 10
    add dl,'0'          ; Convert the remainder to ASCII 
    dec esi             ; store characters in reverse order
    mov [esi],dl
    test eax,eax            
    jnz .next_digit     ; Repeat until eax==0
    mov eax,esi
    ret

RANDGENERATOR:
RANDSTART:
    mov AH, 00h       
    int 1AH    

    mov  ax, dx  ; move dx to ax
    xor  dx, dx  ; clear dx
    mov  cx, 10  ; move 10 dec to CX
    div  cx      ; divide ax by cx
    add  dl, '0' ; to ascii from '0' to '9'
    mov ah, 2h   ; call interrupt to display a value in DL
    int 21h    
RET 

print_uint32:
    mov    eax, edi              ; function arg

    mov    ecx, 0xa              ; base 10
    push   rcx                   ; newline = 0xa = base
    mov    rsi, rsp
    sub    rsp, 16               ; not needed on 64-bit Linux, the red-zone is big enough.  Change the LEA below if you remove this.

;;; rsi is pointing at '\n' on the stack, with 16B of "allocated" space below that.
.toascii_digit:                ; do {
    xor    edx, edx
    div    ecx                   ; edx=remainder = low digit = 0..9.  eax/=10
                                 ;; DIV IS SLOW.  use a multiplicative inverse if performance is relevant.
    add    edx, '0'
    dec    rsi                 ; store digits in MSD-first printing order, working backwards from the end of the string
    mov    [rsi], dl

    test   eax,eax             ; } while(x);
    jnz  .toascii_digit
;;; rsi points to the first digit


    mov    eax, 1               ; __NR_write from /usr/include/asm/unistd_64.h
    mov    edi, 1               ; fd = STDOUT_FILENO
    lea    edx, [rsp+16 + 1]    ; yes, it's safe to truncate pointers before subtracting to find length.
    sub    edx, esi             ; length=end-start, including the \n
    syscall                     ; write(1, string,  digits + 1)

    add  rsp, 24                ; (in 32-bit: add esp,20) undo the push and the buffer reservation
ret


section .data
    userMsg db '***Guess Three Number***', 0xa
    lenUserMsg equ $-userMsg
    enterMsg db 'Masukkan tebakan: ', 0xa
    lenEnterMsg equ $-enterMsg
    highMsg db 'Terlalu tinggi!', 0xa
    lenHighMsg equ $-highMsg
    lowMsg db 'Terlalu rendah!', 0xa
    lenLowMsg equ $-lowMsg
    rightMsg db 'Benar!', 0xa
    lenRightMsg equ $-rightMsg
    endMsg db 'Game selesai.', 0xa
    lenEndMsg equ $-endMsg
    diffMsg db 'Masukkan jumlah angka yang akan ditebak: ', 0xa
    lenDiffMsg equ $-diffMsg
    guessMsg db 'Menebak angka ke-'
    lenGuessMsg equ $-guessMsg

section .bss
    num resb 5
    counter resb 8
    cnt resb 8

section .text
    global _start

_start:
    ; displaying first message
    mov eax, 4
    mov ebx, 1
    mov ecx, userMsg
    mov edx, lenUserMsg
    int 80h

    ; choose difficulty
    mov eax, 4
    mov ebx, 1
    mov ecx, diffMsg
    mov edx, lenDiffMsg
    int 80h

    ; Read and store the user input
    mov eax, 3
    mov ebx, 2
    mov ecx, num  
    mov edx, 5          ;5 bytes (numeric, 1 for sign) of that information
    int 80h

    ; 
    mov esi, num
    mov ecx, 1
    call string_to_int
    mov [counter], eax

    xor ebp,ebp   ; cx-register is the counter, set to 0
    inc ebp
    loop1:

    mov eax, 4
    mov ebx, 1
    mov ecx, guessMsg
    mov edx, lenGuessMsg
    int 80h
    
    mov ebx, ebp
    .repeat:
    lea    edi, [rbx + 0]      ; put +whatever constant you want here.
    call   print_uint32
    inc ebp      ; Increment
    mov eax, [counter]
    cmp ebp,eax    ; Compare cx to the limit
    jle loop1   ; Loop while less or equal

    mov	eax,1    ;system call number (sys_exit)
    int	0x80     ;call kernel

