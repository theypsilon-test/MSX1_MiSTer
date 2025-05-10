@REM py createDev.py
@py createComp.py --xml-dir Computer_testy --output-dir MSX_test
ssh mist  "rm -rf /media/fat/games/MSX1/NEW/"
scp -r MSX_test/* mist:/media/fat/games/MSX1/NEW/