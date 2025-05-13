::@echo off
set design=CPUAcc
:: delete file wave
if exist .\vcd\* (
    del .\o\%design%
    del .\vcd\%design%.vcd
)
:: compile tb_cvounter.v & generate file wave
iverilog -o .\o\%design% -y .\src .\tb\%design%_tb.v

:: generate waveform wave.vcd by file wave
vvp .\o\%design%
gtkwave -f .\vcd\%design%.vcd 

:: terminal pause
pause
