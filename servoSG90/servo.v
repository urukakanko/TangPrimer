module servo(
	input	wire			clk,        //原発CLK
	input	wire			resetb,     //リセット
	input	wire	[7:0]	setPwm,     //PWMがHigh->Lowになる値
	input	wire	[15:0]	divClk,     //原発クロック減速値
	output	wire			pwm	        //PWM出力
);

    parameter SETPWMMIN = 8'h01;

    //assign setPwm = ( setPwm < SETPWMNIM ) ? SETPWMNIN : setPWM;


    //原発のクロックを分周する
	reg		[15:0]	rclkCounter;
	wire	[15:0]	wclkCounter;
	assign wclkCounter = rclkCounter;
	always@( posedge clk ) begin
		if( !resetb || ( wclkCounter == divClk ) ) begin
			rclkCounter <= 16'h0000;
		end
        /**
		else if( wclkCounter == divClk ) begin
			rclkCounter <= 16'h0000;
		end
        **/
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
	reg		[7:0]	rpwm;
	wire	[7:0]	wpwm;
	assign wpwm = rpwm;
	always@( posedge clk ) begin
		if( !resetb  ) begin
			rpwm <= 8'h00;
		end
        else if ( wdiffClk == 2'b01 ) begin
			rpwm <= wpwm + 1;
        end
        //else if ( wpwm == setPwm ) begin
		//	rpwm <= PWMMIN;
        //end
		else begin
			rpwm <= wpwm;
		end
	end

    //serPwmで与えられたカウント値が設定可能値より小さかったら
    //修する
    //また、設定値setPwmをrpwmカウンタがゼロになったら有効にする
    wire    limit;
    wire    [7:0]   setPwmMin;
    reg     [7:0]   rsetPwm;
    wire    [7:0]   wsetPwm;
    assign setPwmMin = SETPWMMIN;
    assign limit = ( setPwm < setPwmMin );
    assign wsetPwm = rsetPwm;

    always@( posedge clk ) begin
        if( !resetb ) begin
            rsetPwm <= 8'h00;
        end
        else if( limit && (wpwm == 8'h00) ) begin
            rsetPwm <= setPwmMin;
        end
        else if( !limit && (wpwm == 8'h00) ) begin
            rsetPwm <= setPwm;
        end
    end


    //PWM信号生成組み合わせ回路
	wire			wpwmOUT;
	assign wpwmOUT = ( ( 0 <= wpwm ) && ( wpwm <= wsetPwm ) ) ? 1 : 0;
    assign pwm = wpwmOUT;
   /*************** 
	reg				rpwmOUT;
	wire			wpwmOUT;
	assign wpwmOUT = rpwmOUT;
	always@( posedge sclk ) begin
		if( !resetb ) begin
			rpwmOUT <= 1'b0;
		end
		else if( ( 0 <= wpwm ) && ( wpwm <= setPwm ) ) begin
			rpwmOUT <= 1'b1;
		end
		else begin
			rpwmOUT <= 1'b0;
		end
	end
    assign pwm = wpwmOUT;
    **************/

endmodule
