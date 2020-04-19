iverilog -t vvp -o servo.vvp -s servotop servotop.v servo.v 
if not %ERRORLEVEL% == 0 goto end

vvp servo.vvp
if not %ERRORLEVEL% == 0 goto end

gtkwave servo.vcd

:end
exit /b 0
