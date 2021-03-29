;compressed_data equ ZP
decompressing   equ ZP+2
copysrc         equ ZP+4


dzx0_standard
             lda   #$ff
             sta   offsetL
             sta   offsetH
             ldy   #$00
             sty   lenL
             sty   lenH
             lda   #$80

; Literal (copy next N bytes from compressed file)
; 0  Elias(length)  byte[1]  byte[2]  ...  byte[N]
dzx0s_literals
              jsr   dzx0s_elias
              pha

cop0          jsr   xBIOS_GET_BYTE
              ldy   #$00
              sta   (decompressing),y
              inw   decompressing
              lda   #$ff
lenL          equ   *-1
              bne   @+
              dec   lenH
@             dec   lenL
              bne   cop0
              lda   #$ff
lenH          equ   *-1
              bne   cop0

              pla
              asl   @
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
; 0  Elias(length)
              jsr   dzx0s_elias
dzx0s_copy
              pha
              lda   decompressing
              clc
              adc   #$ff
offsetL       equ   *-1
              sta   copysrc
              lda   decompressing+1
              adc   #$ff
offsetH       equ   *-1
              sta   copysrc+1

              ldy   #$00
              ldx   lenH
              beq   Remainder
Page          lda   (copysrc),y
              sta   (decompressing),y
              iny
              bne   Page
              inc   copysrc+1
              inc   decompressing+1
              dex
              bne   Page
Remainder     ldx   lenL
              beq   copyDone
copyByte      lda   (copysrc),y
              sta   (decompressing),y
              iny
              dex
              bne   copyByte
              tya
              clc
              adc   decompressing
              sta   decompressing
              bcc   copyDone
              inc   decompressing+1
copyDone      stx   lenH
              stx   lenL

              pla
              asl   @
              bcc   dzx0s_literals

; Copy from new offset (repeat N bytes from new offset)
; 1  Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset
              jsr   dzx0s_elias
              pha
              php
              lda   #$00
              sec
              sbc   lenL
              sta   offsetH
              bne   @+
              plp
              pla
              rts           ; koniec
@             jsr   xBIOS_GET_BYTE
              plp
              sta   offsetL
              ror   offsetH
              ror   offsetL
              ldx   #$00
              stx   lenH
              inx
              stx   lenL
              pla
              bcs   @+
              jsr   dzx0s_elias_backtrack
@             inc   lenL
              bne   @+
              inc   lenH
@             jmp   dzx0s_copy

dzx0s_elias   inc   lenL
dzx0s_elias_loop
              asl   @
              bne   dzx0s_elias_skip
              jsr   xBIOS_GET_BYTE
              sec   ; mo¿na usun¹æ jeœli dekompresja z pamiêci a nie pliku
              rol   @
dzx0s_elias_skip
              bcc   dzx0s_elias_backtrack
              rts
dzx0s_elias_backtrack
              asl   @
              rol   lenL
              rol   lenH
              jmp   dzx0s_elias_loop


; jsr xBIOS_GET_BYTE na jsr GET_BYTE

xBIOS_GET_BYTE
get_byte          lda    $ffff
compressed_data   equ    *-2
                  inw    compressed_data
                  rts