WAIT 50
#CALL reset
#CALL writeData 0x03
#CALL writeData 0xdf
#CALL writeData 0x03
#konec cmd
#CALL writeData 0x0F
MISTER LOADIMG 70fddsk.dsk 3 fclk
WAIT 10
#SIGNAL sd_rd 255
#WAIT 200
#CALL writeData 0x14
#CALL writeData 0x05
WAIT 1400
STOP