@REM py createDev.py
@py createComp.py
ssh mist  "rm -rf /media/fat/games/MSX1/NEW/"
scp -r MSX_test/* mist:/media/fat/games/MSX1/NEW/