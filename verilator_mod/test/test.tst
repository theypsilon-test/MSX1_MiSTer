CALL reset
MISTER LOADIMG 70fddsk.dsk 0 fclk
SIGNAL USEL   0
SIGNAL MOTORn   0
WAIT 100

WAIT 3000000
#CALL writeData 0x07
#CALL writeData 0x00
#CALL writeData 0xdf
#CALL writeData 0x03
#konec cmd
#CALL writeData 0x0F
#MISTER LOADIMG 70fddsk.dsk 3 fclk
#WAIT 10
#SIGNAL sd_rd 255
#WAIT 200
#CALL writeData 0x14
#CALL writeData 0x05
#WAIT 2147700
STOP