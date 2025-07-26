rmdir /S /Q ..\releases\MisterPack\
mkdir ..\releases\MisterPack\

COPY CreateCRC\createDB.py ..\releases\MisterPack\CreateCRC\
COPY CreateCRC\mappers.json ..\releases\MisterPack\CreateCRC\


robocopy CreateMSXpack\Computer\ ..\releases\MisterPack\CreateMSXpack\Computer\ /E /COPY:DAT
robocopy CreateMSXpack\Extension\ ..\releases\MisterPack\CreateMSXpack\Extension\ /E /COPY:DAT
robocopy CreateMSXpack\ROM\Cbios\ ..\releases\MisterPack\CreateMSXpack\ROM\Cbios /E /COPY:DAT 
COPY CreateMSXpack\ROM\kbd_svg8240.bin ..\releases\MisterPack\CreateMSXpack\ROM\ 
robocopy CreateMSXpack\MSX\C-BIOS\ ..\releases\MisterPack\CreateMSXpack\MSX\C-BIOS\ /E /COPY:DAT 
COPY CreateMSXpack\*.json ..\releases\MisterPack\CreateMSXpack\
COPY CreateMSXpack\createComp.py ..\releases\MisterPack\CreateMSXpack\
COPY CreateMSXpack\createDev.py ..\releases\MisterPack\CreateMSXpack\
COPY CreateMSXpack\tools.py ..\releases\MisterPack\CreateMSXpack\


robocopy CreateKeyMap\ ..\releases\MisterPack\CreateKeyMap\ /E /COPY:DAT 

mkdir ..\releases\MisterPack\CreateCRC_DB\
COPY CreateCRC\mappersOverride.txt ..\releases\MisterPack\CreateCRC_DB\
COPY CreateCRC\mappers.json ..\releases\MisterPack\CreateCRC_DB\
COPY CreateCRC\createDB.py ..\releases\MisterPack\CreateCRC_DB\
COPY CreateCRC\createDB.py ..\releases\MisterPack\CreateCRC_DB\
COPY CreateCRC\crc32toTxt.py ..\releases\MisterPack\CreateCRC_DB\
COPY CreateCRC\vampier.db ..\releases\MisterPack\CreateCRC_DB\

COPY ..\output_files\MSX1.rbf ..\releases\MisterPack\

powershell Compress-Archive -Path "..\releases\MisterPack\*" -D "..\releases\MSX1.zip"
move ..\releases\MSX1.zip c:\Users\tomas\OneDrive\share\MSX1\