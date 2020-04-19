module servoCtrl(
        input   wire            clk,
        input   wire            resetb,
        output  wire            pwm,
		output	wire			clk_o
//        output  wire    [7:0]   setPwm,
//        output  wire    [15:0]  divClk
);

	///////
	//debug
	assign clk_o = clk;
	//debug
	///////

    parameter   DIVCLK = 2200;//600;
    wire    [15:0]  divClk;
    assign  divClk = DIVCLK;

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
    /***/
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
    /****/

    //同期微分アクティブをカウントする
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
		else begin
			rpwm <= wpwm;
		end
	end


    //減速したsclkがゼロになる時カウントアップ
    reg     [7:0]   rpwmCoutCounter;
    wire    [7:0]   wpwmCoutCounter;
    assign wpwmCoutCounter = rpwmCoutCounter;

    always@( posedge clk ) begin
        if( !resetb ) begin
            rpwmCoutCounter <= 8'h00;
        end
        else if( ( wpwm == 8'h00 ) && ( wdiffClk == 2'b01 ) ) begin
            rpwmCoutCounter <= wpwmCoutCounter + 1;
        end
        else begin
            rpwmCoutCounter <= wpwmCoutCounter;
        end
    end

    //設定するPWM値を時間毎に変える
    reg     [7:0]   rsetPWM;
    wire    [7:0]   wsetPWM;
    assign wsetPWM = rsetPWM;
    always@( posedge sclk ) begin
        if( !resetb ) begin
            rsetPWM = 8'h00;
        end
        else if( ( 0<= wpwmCoutCounter ) && 
                 ( wpwmCoutCounter <= 8'h54 ) ) begin 
            rsetPWM <= 8'h06;
        end
        else if( ( 8'h55 <= wpwmCoutCounter ) && 
                 ( wpwmCoutCounter <= 8'hab ) ) begin
            rsetPWM <= 8'h0f; //8'h1a;
        end
        else if( ( 8'haa <= wpwmCoutCounter ) && 
                 ( wpwmCoutCounter <= 8'hff ) ) begin
            rsetPWM <= 8'h1a;//8'h34;
        end
    end
  

    servo U2( .clk(clk), .resetb(resetb), .setPwm(wsetPWM), .divClk(divClk), .pwm(pwm) );

endmodule
