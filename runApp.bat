@echo off
set wdir="E:\OneDrive Folder\OneDrive\Programming\D Lang\WinGLib"
set conemu=E:\cmder\vendor\conemu-maximus5\ConEmu64.exe
start /D %wdir% %conemu% -run dmd -i -run app.d
exit
