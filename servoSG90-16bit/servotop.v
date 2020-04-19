`timescale 1ns/1ps

module servotop;
    reg                 clk;
    reg                 resetb;
    reg [7:0]           setPwm;     //High width
    reg [15:0]          divClk;     //clk•ªŽü
    wire                pwm;

    servo U1(
        .clk(clk),
        .resetb(resetb),
        .setPwm(setPwm),
        .divClk(divClk),
        .pwm(pwm)
    );

    parameter   clkT = 41.667;      //K14 24MHz
    parameter   SETPWMMAX = 8'h40;
    parameter   DIVCLK = 1800;//600;
    initial begin
        $dumpfile( "servo.vcd" );
        $dumpvars( 0, servotop );

        #0
            clk = 0;
            resetb = 0;
            setPwm = 0;
            divClk = 0;


        #(clkT*2)
            resetb = 1;
            setPwm = SETPWMMAX;
            divClk = DIVCLK;          //24000000Hz/600*2=20000us



        #(clkT*384000)
            setPwm = SETPWMMAX*2;

        #(clkT*384000)
            $finish;

    end

    always#(clkT/2)
            clk = ~clk;

endmodule



            
