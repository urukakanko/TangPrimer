module servoCtrl(
        input   wire            clk,
        input   wire            resetb,
        output  wire            pwm,
		output	wire			clk_o
//        output  wire    [7:0]   setPwm,
//        output  wire    [15:0]  divClk
);

	wire [7:0] version = 8'h02;
	//ver0.0.1：2020/04/18:とりあえず動作
	//ver0.0.2:2020/04/19:PWM設定bit幅を16bit化
	
	///////
	//debug
	assign clk_o = clk;
	//debug
	///////

    parameter   DIVCLK = 6;//2200;//600;
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
	reg		[15:0]	rpwm;
	wire	[15:0]	wpwm;
	assign wpwm = rpwm;
	always@( posedge clk ) begin
		if( !resetb  ) begin
			rpwm <= 16'h0000;
		end
        else if ( wdiffClk == 2'b01 ) begin
			rpwm <= wpwm + 16'h0001;
        end
		else begin
			rpwm <= wpwm;
		end
	end


    //減速したrpwmがゼロになる時カウントアップ
    reg     [15:0]   rpwmCoutCounter;
    wire    [15:0]   wpwmCoutCounter;
    assign wpwmCoutCounter = rpwmCoutCounter;
    always@( posedge clk ) begin
        if( !resetb ) begin
            rpwmCoutCounter <= 16'h0000;
        end
        else if( ( wpwm == 8'h00 ) && ( wdiffClk == 2'b01 ) ) begin
            rpwmCoutCounter <= wpwmCoutCounter + 16'h0001;
        end
		else if( wpwmCoutCounter == 16'h00ca ) begin
            rpwmCoutCounter <= 16'h0000;
		end
        else begin
            rpwmCoutCounter <= wpwmCoutCounter;
        end
    end
    
    
    //設定するPWM値を時間毎に変える
    //reg     [7:0]   rsetPWM;
    //wire    [7:0]   wsetPWM;
    reg     [15:0]   rsetPWM;
    wire    [15:0]   wsetPWM;
    assign wsetPWM = rsetPWM;
    always@( posedge sclk ) begin
        if( !resetb ) begin
            rsetPWM = 8'h00;
        end
        else if( ( 0<= wpwmCoutCounter ) && 
                 ( wpwmCoutCounter <= 16'h0032 ) ) begin 
            rsetPWM <= 16'h510;  //0.5/23.6*0xffff       8'h06;
        end
        else if( ( 16'h0033 <= wpwmCoutCounter ) && 
                 ( wpwmCoutCounter <= 16'h0064 ) ) begin
            rsetPWM <= 16'h0ae4; //1.0/23.6*0xffff         8'h0f; //8'h1a;
        end
        else if( ( 16'h0096 <= wpwmCoutCounter ) && 
                 ( wpwmCoutCounter <= 16'h00c8 ) ) begin
            rsetPWM <= 16'h1a24; //2.4/23.6*0xffff       8'h1a;//8'h34;
        end
    end
  

    servo U2( .clk(clk), .resetb(resetb), .setPwm(wsetPWM), .divClk(divClk), .pwm(pwm) );

endmodule
