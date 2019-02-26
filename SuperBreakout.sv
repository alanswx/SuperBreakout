//============================================================================
//  SuperBreakout port to MiSTer
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//   
//============================================================================


module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);


/*
module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,


	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR
);
*/

//`define SOUND_DBG



assign LED_DISK  = lamp1;
assign LED_POWER = lamp2;
assign LED_USER  = ioctl_download;

`include "build_id.v"
localparam CONF_STR = {
	"A.SBRKOUT;;",
	"-;",
	"O1,Aspect Ratio,Original,Wide;",
	"O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",  

	"OAB,Language,English,German,French,Spanish;",
	"OC,Balls,3,5;",
	"O68,Bonus,200,400,600,900,1200,1600,2000,None;",
	"OD,Test,Off,On;",
	"-;",
	"R0,Reset;",
	"J1,Relase,Select,Start 1P,Start 2P;",
	"V,v",`BUILD_DATE
};


wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_data;

wire [10:0] ps2_key;
//wire [24:0] ps2_mouse;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy0 =  joystick_0;
wire [15:0] joy1 =  joystick_1;


hps_io #(.STRLEN(($size(CONF_STR)>>3) )/*, .PS2DIV(1000), .WIDE(0)*/) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),
	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.buttons(buttons),

	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	
	.ps2_key(ps2_key)
);



wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
//			'hX75: btn_up          <= pressed; // up
//			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h029: btn_gas         <= pressed; // space
			'h014: btn_gas         <= pressed; // ctrl

			'h005: btn_one_player  <= pressed; // F1
			'h006: btn_two_players <= pressed; // F2
		endcase
	end
end

//reg btn_up    = 0;
//reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_gas  = 0;
reg btn_one_player  = 0;
reg btn_two_players = 0;

wire m_left			=  btn_left  | joy0[1];
wire m_right		=  btn_right | joy0[0];
wire m_serve			= btn_gas| joy0[4]|joy1[4];
wire m_select1		=  joy0[5];


wire m_left1   	=	joy1[1];
wire m_right1  	=  joy1[0];
wire m_select2		=  joy1[5];


wire m_start1 = btn_one_player  | joy0[8] | joy1[8];
wire m_start2 = btn_two_players | joy0[9] | joy1[9];
wire m_coin   = m_start1 | m_start2;



/*
-- Configuration DIP switches, these can be brought out to external switches if desired
-- See Super Breakout manual page 13 for complete information. Active low (0 = On, 1 = Off)
--    1 	2							Language				(00 - English)
--   			3	4					Coins per play		(10 - 1 Coin, 1 Play) 
--						5				3/5 Balls			(1 - 3 Balls)
--							6	7	8	Bonus play			(011 - 600 Progressive, 400 Cavity, 600 Double)
		
SW2 <= "00101011";



*/


wire [7:0] SW1 = {status[11:10],1'b1,1'b0,status[12],status[8:6]};

wire [1:0] steer0;
wire [1:0] steer1;

joy2quad steerjoy2quad0
(
	.CLK(clk_sys),
	//.clkdiv('d22500),
	.clkdiv('d5500),
	
	.right(m_right),
	.left(m_left),
	
	.steer(steer0)
);
joy2quad steerjoy2quad1
(
	.CLK(clk_sys),
	//.clkdiv('d22500),
	.clkdiv('d5500),
	
	.right(m_right1),
	.left(m_left1),
	
	.steer(steer1)
);



/*			Pot_Comp1_I	: in  std_logic;	-- If you want to use a pot instead, this goes to the output of the comparator
			Serve_LED_O	: out std_logic;	-- Serve button LED (Active low)
			Counter_O	: out std_logic;	-- Coin counter output (Active high)
*/
wire videowht;
wire lamp1,lamp2;

super_breakout super_breakout(
	.Clk_50_I(CLK_50M),
	.Reset_n(~(RESET | status[0] | buttons[1] | ioctl_download)),

	.dn_addr(ioctl_addr[16:0]),
	.dn_data(ioctl_data),
	.dn_wr(ioctl_wr),

	.Video_O(videowht),
	//.VideoB_O(videoblk),

	//.Sync_O(compositesync),
	.Audio_O(audio1),
	//.Audio2_O(audio2),
	.Coin1_I(~m_coin),
	.Coin2_I(~m_coin),
	
	.Start1_I(~m_start1),
	.Start2_I(~m_start2),
	
	.Serve_I(~m_serve),
	.Select1_I(~m_select1),
	.Select2_I(~m_select2),
	.Slam_I(1),
	.Test_I	(~status[13]),
	.Enc_A(steer0[1]),
	.Enc_B(steer0[0]),
	.Lamp1_O(lamp1),
	.Lamp2_O(lamp2),
	.hs_O(hs),
	.vs_O(vs),
	.hblank_O(hbl0),
	.vblank_O(vbl0),
	.clk_12(clk_12),
	.clk_6_O(CLK_VIDEO_2),
	.SW1_I(SW1)
	);
			
wire [7:0] audio1;
wire [1:0] video;
wire [3:0] videor;
///////////////////////////////////////////////////
//wire clk_sys, clk_ram, clk_ram2, clk_pixel, locked;
wire clk_sys,locked;
wire clk_12,CLK_VIDEO_2;



wire hs,vs,hblank,vblank,hbl0,vbl0;

assign hblank=hbl0;
assign vblank=vbl0;
//----
/*
assign VGA_HS=hs;
assign VGA_VS=vs;

assign HDMI_ARX = 4;
assign HDMI_ARY = 3;

assign VGA_CLK  = CLK_VIDEO_2;
assign VGA_CE   = 1;

assign VGA_R={videowht,videowht,videowht,videowht,videowht,videowht,videowht,videowht};
assign VGA_G={videowht,videowht,videowht,videowht,videowht,videowht,videowht,videowht};
assign VGA_B={videowht,videowht,videowht,videowht,videowht,videowht,videowht,videowht};

assign VGA_DE=~(vblank | hblank);

assign HDMI_CLK =  VGA_CLK;
assign HDMI_CE  =  VGA_CE ;
assign HDMI_R   = VGA_R  ;
assign HDMI_G   =VGA_G ;
assign HDMI_B   =  VGA_B ;
assign HDMI_DE  = VGA_DE ;
assign HDMI_HS  =  VGA_HS;
assign HDMI_VS  = VGA_VS ;
assign HDMI_SL  =  2'd0  ;
*/



assign HDMI_ARX = status[1] ? 8'd16 : status[2] ? 8'd4 : 8'd1;
assign HDMI_ARY = status[1] ? 8'd9  : status[2] ? 8'd3 : 8'd1;


wire [2:0] r,g;
wire [1:0] b;
assign r={videowht,videowht,videowht};
assign g={videowht,videowht,videowht};
assign b={videowht,videowht};



arcade_rotate_fx #(336,240,8) arcade_video
(
	.*,

	.clk_video(CLK_VIDEO_2),
	.ce_pix(CLK_VIDEO_2/*ce_vid*/),

	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),
	
	.fx(status[5:3]),
	.no_rotate(status[2])
);


/*

assign HDMI_ARX = status[5] ? 8'd16 : status[4] ? 8'd4 : 8'd1;
assign HDMI_ARY = status[5] ? 8'd9  : status[4] ? 8'd3 : 8'd1;

wire vbl0;

wire hblank, vblank;
reg  ce_vid;
wire hs, vs;
wire rde, rhs, rvs;
wire [2:0] r,g;
wire [1:0] b;
wire [2:0] rr,rg;
wire [1:0] rb;


assign r={videowht,videowht,videowht};
assign g={videowht,videowht,videowht};
assign b={videowht,videowht};


assign VGA_CLK  = clk_sys;
assign VGA_CE   = ce_vid;
assign VGA_R    = {r,r,r[2:1]};
assign VGA_G    = {g,g,g[2:1]};
assign VGA_B    = {b,b,b,b};
assign VGA_DE   = ~(hblank | vblank);
assign VGA_HS   = ~hs;
assign VGA_VS   = ~vs;
wire clk_hdmi = clk_sys;

assign HDMI_CLK = status[4] ? VGA_CLK: clk_hdmi;
assign HDMI_CE  = status[4] ? VGA_CE : 1'b1;
assign HDMI_R   = status[4] ? VGA_R  : {rr,rr,rr[2:1]};
assign HDMI_G   = status[4] ? VGA_G  : {rg,rg,rg[2:1]};
assign HDMI_B   = status[4] ? VGA_B  : {rb,rb,rb,rb};
assign HDMI_DE  = status[4] ? VGA_DE : rde;
assign HDMI_HS  = status[4] ? VGA_HS : rhs;
assign HDMI_VS  = status[4] ? VGA_VS : rvs;
assign HDMI_SL  = status[4] ? 2'd0   : status[9:8];

screen_rotate #(336,240,8) screen_rotate
(
	.clk_in(clk_sys),
	.ce_in(ce_vid),
	.video_in({r,g,b}),
	.hblank(hblank),
	.vblank(vblank),

	.clk_out(clk_hdmi),
	.video_out({rr,rg,rb}),
	.hsync(rhs),
	.vsync(rvs),
	.de(rde)
);


assign hblank = hbl[8];
assign vblank = vbl;


//assign clk_pix = clk_12;
assign clk_pix = CLK_VIDEO;
wire clk_pix;
wire hbl0;
reg [8:0] hbl;
reg vbl;
always @(posedge clk_sys) begin
	reg old_pix;
	old_pix <= clk_pix;
	ce_vid <= 0;
	if(old_pix & ~clk_pix) begin
		ce_vid <= 1;
		hbl <= (hbl<<1)|hbl0;
		vbl <= vbl0;
	end
end

*/

assign AUDIO_L={audio1,8'b00000000};
assign AUDIO_R=AUDIO_L;
assign AUDIO_S = 0;
wire scrap;
assign clk_sys=CLK_VIDEO_2;
pll pll (
	 .refclk ( CLK_50M   ),
	 .rst(0),
	 .locked 		( locked    ),        // PLL is running stable
	 .outclk_0		( scrap		),        // 12 MHz
	 .outclk_1		( clk_12		)        // 12 MHz
	 );

endmodule
