call "c:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

msbuild -p:Configuration=Release;Platform=x64 sim.sln /m

x64\Release\sim_modules.exe

pause