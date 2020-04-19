`timescale 1ns/1ps

module servoCtrltop;
    reg                 clk;
    reg                 resetb;
    wire                pwm;

    servoCtrl U1(
        .clk(clk),
        .resetb(resetb),
        .pwm(pwm)
    );

    parameter   clkT = 41.667;      //K14 24MHz
    initial begin
        $dumpfile( "servoCtrl.vcd" );
        $dumpvars( 0, servoCtrltop );

        #0
            clk = 0;
            resetb = 0;
            //setPwm = 0;
            //divClk = 0;


        #(clkT*2)
            resetb = 1;
            //divClk = DIVCLK;          //24000000Hz/600*2=20000us



        #(clkT*1536000)
            resetb = 1;

        #(clkT*1536000)
            $finish;

    end

    always#(clkT/2)
            clk = ~clk;

endmodule



            
