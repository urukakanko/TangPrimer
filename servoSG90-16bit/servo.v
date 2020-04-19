module servo(
	input	wire			clk,        //原発CLK
	input	wire			resetb,     //リセット
	input	wire	[15:0]	setPwm,     //PWMがHigh->Lowになる値
	input	wire	[15:0]	divClk,     //原発クロック減速値 -> 0d1800で23.6ms
	output	wire			pwm	        //PWM出力
);

    parameter SETPWMMIN = 16'h0001;//16'h056c;		//0.5ms/23.6ms*0xffff

    //assign setPwm = ( setPwm < SETPWMNIM ) ? SETPWMNIN : setPWM;


    //原発のクロックを分周する
	reg		[15:0]	rclkCounter;
	wire	[15:0]	wclkCounter;
	assign wclkCounter = rclkCounter;
	always@( posedge clk ) begin
		if( !resetb || ( wclkCounter == divClk ) ) begin
			rclkCounter <= 16'h0000;
		end
		else begin
			rclkCounter <= wclkCounter + 1;
		end
	end

    //周波数を落としたクロックの同期微分を取る
	reg		[1:0]	rdiffClk;
	wire	[1:0]	wdiffClk;
	assign wdiffClk = rdiffClk;
	always@( posedge clk ) begin
		if( !resetb ) begin
			rdiffClk <= 2'b00;
		end
		else begin
			rdiffClk <= {wdiffClk[1],(wclkCounter[15:0]==divClk)};
		end
	end

    //PWM用クロックを同期微分信号から生成
    reg             rsclk;
    wire            sclk;
    assign sclk = rsclk;
    always@( posedge clk ) begin
        if( !resetb ) begin
            rsclk <= 1'b0;
        end
        else if ( wdiffClk == 2'b01 ) begin
            rsclk <= ~rsclk;
        end
        else begin
            rsclk <= sclk;
        end
    end


	parameter	PWMMIN = 8'h0a;
	
	//PWM生成用8bitカウンタ
	//reg		[7:0]	rpwm;
	//wire	[7:0]	wpwm;
	reg		[15:0]	rpwm;
	wire	[15:0]	wpwm;
	assign wpwm = rpwm;
	always@( posedge clk ) begin
		if( !resetb  ) begin
			rpwm <= 16'h0000;
		end
        else if ( wdiffClk == 2'b01 ) begin
			rpwm <= wpwm + 1;
        end
		else begin
			rpwm <= wpwm;
		end
	end

    //serPwmで与えられたカウント値が設定可能値より小さかったら修する
    //また、設定値setPwmをrpwmカウンタがゼロになったら有効にする
    wire    limit;
    wire    [15:0]   setPwmMin;
    reg     [15:0]   rsetPwm;
    wire    [15:0]   wsetPwm;
    assign setPwmMin = SETPWMMIN;
    assign limit = ( setPwm < setPwmMin );
    assign wsetPwm = rsetPwm;

    always@( posedge clk ) begin
        if( !resetb ) begin
            rsetPwm <= 16'h0000;
        end
        else if( limit && (wpwm == 16'h0000) ) begin
            rsetPwm <= setPwmMin;
        end
        else if( !limit && (wpwm == 16'h0000) ) begin
            rsetPwm <= setPwm;
        end
    end


    //PWM信号生成組み合わせ回路
	wire			wpwmOUT;
	assign wpwmOUT = ( ( 0 <= wpwm ) && ( wpwm <= wsetPwm ) ) ? 1 : 0;
    assign pwm = wpwmOUT;

endmodule
