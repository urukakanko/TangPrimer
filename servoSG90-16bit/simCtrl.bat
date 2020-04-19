iverilog -t vvp -o servoCtrl.vvp -s servoCtrltop servoCtrltop.v servo.v servoCtrl.v 
if not %ERRORLEVEL% == 0 goto end

vvp servoCtrl.vvp
if not %ERRORLEVEL% == 0 goto end

gtkwave servoCtrl.vcd

:end
exit /b 0
