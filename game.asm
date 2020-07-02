; Input:
; ESI = pointer to the string to convert
; ECX = number of digits in the string (must be > 0)
; Output:
; EAX = integer value
; Credit : Michael, https://stackoverflow.com/questions/19309749/nasm-assembly-convert-input-to-integer
string_to_int:
    xor ebx, ebx    ; clear ebx
    .next_digit:
    movzx eax,byte[esi]
    inc esi
    sub al, '0'    ; convert from ASCII to number
    imul ebx, 10
    add ebx, eax   ; ebx = ebx*10 + eax
    loop .next_digit  ; while (--ecx)
    mov eax, ebx
ret

; input
loop_round:

    loop2:
    ; ronde ke-
    mov eax, 4
    mov ebx, 1
    mov ecx, roundMsg
    mov edx, lenRoundMsg
    int 80h
    
    xor eax, eax
    mov eax, [round]
    inc eax
    mov [round], eax
    mov    edi, eax      ; put +whatever constant you want here.
    call   print_int
    
    xor eax, eax
    mov [query], eax
    mov [query+4], eax
    mov [query+8], eax

    ; Read and store the user input
    mov eax, 3
    mov ebx, 2
    mov ecx, query  
    mov edx, 5
    int 80h


    xor eax, eax
    mov [cnt], eax
    loop_query:

    mov eax, [cnt]
    lea esi, [query+eax]
    mov ecx, 1
    call string_to_int
    mov edx, [random]
    cmp eax, 208
    je loop2
    cmp eax, 218
    je loop2
    cmp eax, edx
    jg greater_than
    je equal
    less_than:
    mov eax, 4
    mov ebx, 1
    mov ecx, lowMsg
    mov edx, lenLowMsg
    int 80h
    

    mov ebx, [cnt]
    add ebx, 2
    mov [cnt], ebx
    xor eax, eax
    lea esi, [query+ebx]
    mov ecx, 1
    call string_to_int
    cmp eax, 0

    jne loop_query



    jmp loop2

    greater_than:
    mov eax, 4
    mov ebx, 1
    mov ecx, highMsg
    mov edx, lenHighMsg
    int 80h

    mov ebx, [cnt]
    add ebx, 2
    mov [cnt], ebx
    xor eax, eax
    lea esi, [query+ebx]
    mov ecx, 1
    call string_to_int
    cmp eax,0
    jne loop_query

    jmp loop2

    equal:
    mov eax, 4
    mov ebx, 1
    mov ecx, rightMsg
    mov edx, lenRightMsg
    int 80h


; pseudo random generator
; Input:
; rand = input value
; EDX = output -> pseudo random number
random_generator:
    mov eax, [rand]
    mov ecx, 10
    div ecx         ; edx = remainder
    mov eax, edx
    mov ecx, edx
    mul ecx         ; eax = product
    mul ecx         ; eax = product
    add edx, ecx    ;
    mov eax, edx
    mov ecx, 10
    div ecx         ; edx = remainder
ret  

; Input:
; EDI = integer to be displayed
; Credit : Peter Cordes, https://stackoverflow.com/questions/13166064/how-do-i-print-an-integer-in-assembly-level-programming-without-printf-from-the
print_int:
    mov    eax, edi
    mov    ecx, 0xa     ; base 10
    push   rcx          
    mov    rsi, rsp
    sub    rsp, 16      ; add space

    .digit_to_char:
    xor    edx, edx
    div    ecx          ; edx = remainder
    add    edx, '0'     ; to string
    dec    rsi          ; WARNING!!! working backward for printing
    mov    [rsi], dl

    test   eax, eax     ; } while(x);
    jnz  .digit_to_char

    ; syscall print

    mov    eax, 1
    mov    edi, 1
    lea    edx, [rsp+16 + 1]    ; truncate pointers before subtracting to find length.
    sub    edx, esi             ; edx = length -> edx - esi, including the \n
    syscall                     ; call kernel using syscall 64bit:)

    add  rsp, 24                ; undo the push and the buffer reservation
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
    roundMsg db 'Ronde ke-'
    lenRoundMsg equ $-roundMsg
    sumRoundMsg db 'Jumlah total ronde = '
    lenSumRoundMsg equ $-sumRoundMsg

section .bss
    num resb 5
    counter resb 8
    cnt resb 8
    random resb 8
    rand resb 8
    round resb 8
    query resb 8
    

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

    xor eax, eax  ; round counter
    mov [round], eax
    loop1:
    mov eax, [round]
    mov [rand], eax
    ; menebak angka ke-
    mov eax, 4
    mov ebx, 1
    mov ecx, guessMsg
    mov edx, lenGuessMsg
    int 80h
    
    mov ebx, ebp

    .repeat:
    mov    edi, ebp      ; put +whatever constant you want here.
    call   print_int

    call random_generator
    

    mov eax, edx
    mov [random], eax

    call loop_round

    inc ebp      ; Increment
    mov eax, [counter]
    cmp ebp,eax    ; Compare cx to the limit
    jle loop1   ; Loop while less or equal

    mov eax, 4
    mov ebx, 1
    mov ecx, sumRoundMsg
    mov edx, lenSumRoundMsg
    int 80h

    mov    edi, [round]      ; put +whatever constant you want here.
    call   print_int

    mov	eax,1    ;system call number (sys_exit)
    int	0x80     ;call kernel

