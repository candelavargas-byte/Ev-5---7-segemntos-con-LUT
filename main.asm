.include "m328pdef.inc"

.ORG 0x0000
RJMP Inicio

; Configuración UART (16 MHz, 9600 baudios)
.equ F_CPU = 16000000
.equ baud = 9600
.equ bps = (F_CPU/16/baud) - 1

Inicio:
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16

    ; PD2 a PD7 como salida para 6 segmentos
    ; PD0 y PD1 quedan libres para USART
    ldi r16, 0b11111100
    out DDRD, r16

    ; PB0 como salida para el segmento G
    sbi DDRB, PB0

    ldi r16, LOW(bps)
    ldi r17, HIGH(bps)
    rcall initUART

    rcall guardar_codigos   ; Carga la LUT de 16 posiciones (0..F)

loop:
    rcall getc              ; Lee carácter desde UART
    rcall ascii_a_hex       ; Convierte ASCII ('0'-'F') a índice numérico (0-15)

    cpi r16, 16             ; Valida que esté dentro de 0..15
    brcc loop               ; Ignora caracteres inválidos

    mov r0, r16
    rcall get_7seg_code

    rcall mostrar_display   ; Muestra el valor en el display

    rjmp loop

; --- Conversor de ASCII Hexadecimal (0-9, A-F, a-f) ---
ascii_a_hex:
    cpi r16, '0'
    brlt invalido
    cpi r16, '9' + 1
    brlt es_num
    cpi r16, 'A'
    brlt invalido
    cpi r16, 'F' + 1
    brlt es_mayus
    cpi r16, 'a'
    brlt invalido
    cpi r16, 'f' + 1
    brlt es_minus

invalido:
    ldi r16, 0xFF           ; Valor de error para ignorar el dato
    ret

es_num:
    subi r16, '0'           ; Resta 0x30
    ret

es_mayus:
    subi r16, 'A' - 10      ; Resta 55 (0x37)
    ret

es_minus:
    subi r16, 'a' - 10      ; Resta 87 (0x57)
    ret

; --- Rutinas UART (Plantilla del profesor) ---
initUART:
    sts UBRR0L, r16
    sts UBRR0H, r17
    ldi r16, (1<<RXEN0)|(1<<TXEN0)
    sts UCSR0B, r16
    ret

getc:
    lds r17, UCSR0A
    sbrs r17, RXC0          ; Espera dato en buffer de entrada
    rjmp getc
    lds r16, UDR0
    ret

; --- Lectura de la LUT ---
get_7seg_code:
    ldi r28, 0x00
    ldi r29, 0x01           ; Dirección base SRAM: 0x0100
    add r28, r0
    ld  r20, Y
    ret

; --- Mostrar valor en display ---
mostrar_display:

    ; Primero apago todos los segmentos
    ldi r18, 0x00
    out PORTD, r18
    cbi PORTB, PB0

    ; bit 6 = A -> PD2
    sbrc r20, 6
    sbi PORTD, PD2

    ; bit 5 = B -> PD3
    sbrc r20, 5
    sbi PORTD, PD3

    ; bit 4 = C -> PD4
    sbrc r20, 4
    sbi PORTD, PD4

    ; bit 3 = D -> PD5
    sbrc r20, 3
    sbi PORTD, PD5

    ; bit 2 = E -> PD6
    sbrc r20, 2
    sbi PORTD, PD6

    ; bit 1 = F -> PD7
    sbrc r20, 1
    sbi PORTD, PD7

    ; bit 0 = G -> PB0
    sbrc r20, 0
    sbi PORTB, PB0

    ret


; --- Carga de la LUT en SRAM (16 valores: 0..F) ---
guardar_codigos:
    ldi r28, 0x00
    ldi r29, 0x01

    ; Dígitos 0-9
    ldi r20, 0b01111110    ; '0'
    st  Y+, r20
    ldi r20, 0b00110000    ; '1'
    st  Y+, r20
    ldi r20, 0b01101101    ; '2'
    st  Y+, r20
    ldi r20, 0b01111001    ; '3'
    st  Y+, r20
    ldi r20, 0b00110011    ; '4'
    st  Y+, r20
    ldi r20, 0b01011011    ; '5'
    st  Y+, r20
    ldi r20, 0b01011111    ; '6'
    st  Y+, r20
    ldi r20, 0b01110000    ; '7'
    st  Y+, r20
    ldi r20, 0b01111111    ; '8'
    st  Y+, r20
    ldi r20, 0b01111011    ; '9'
    st  Y+, r20

    ; Letras A-F (Hexadecimal)
    ldi r20, 0b01110111    ; 'A'
    st  Y+, r20
    ldi r20, 0b00011111    ; 'b'
    st  Y+, r20
    ldi r20, 0b01001110    ; 'C'
    st  Y+, r20
    ldi r20, 0b00111101    ; 'd'
    st  Y+, r20
    ldi r20, 0b01001111    ; 'E'
    st  Y+, r20
    ldi r20, 0b01000111    ; 'F'
    st  Y+, r20
    ret