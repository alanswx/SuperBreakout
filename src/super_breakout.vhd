-- Top level file for FPGA implementation of Super Breakout arcade game by Atari
-- (c) 2017 James Sweet
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.

-- Targeted to EP2C5T144C8 mini board but porting to nearly any FPGA should be fairly simple
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity super_breakout is 
port(		
			Clk_50_I		: in	std_logic;	-- 50MHz input clock
			Reset_n		: in	std_logic;	-- Reset (Active low)
			Coin1_I		: in	std_logic;	-- Coin switches 
			Coin2_I		: in 	std_logic;
			Start1_I		: in	std_logic;	-- Player start buttons
			Start2_I		: in	std_logic;
			Serve_I		: in 	std_logic;
			Select1_I	: in  std_logic;  -- Select inputs from game type select knob
			Select2_I	: in  std_logic;
			Test_I		: in 	std_logic; 	-- Self test switch
			Slam_I		: in	std_logic;	-- Slam switch
			Enc_A			: in  std_logic;	-- Rotary encoder, used in place of a pot to control the paddle
			Enc_B			: in  std_logic;
			Pot_Comp1_I	: in  std_logic;	-- If you want to use a pot instead, this goes to the output of the comparator
			VBlank_O		: out std_logic;  -- VBlank signal to reset the ramp genrator used by the pot reading circuitry
			Lamp1_O		: out	std_logic;	-- Player start button lamps (Active high to control incandescent lamps via SCR or transistors)
			Lamp2_O		: out	std_logic;
			Serve_LED_O	: out std_logic;	-- Serve button LED (Active low)
			Counter_O	: out std_logic;	-- Coin counter output (Active high)

			Audio_O		: out std_logic_vector(7 downto 0);	-- PWM audio, low pass filter is desirable but not really necessary for the simple SFX in this game
			Video_O		: out std_logic;	-- Video output, sum this through a 470R resistor to composite video
			Video_RGB	: out std_logic_vector(7 downto 0);
			CompSync_O	: out std_logic; -- Composite sync, sum this through a 1k resistor to composite video
			SW1_I			: in std_logic_vector(7 downto 0);
			
			
			hs_O			: out std_logic;
			vs_O			: out std_logic;
			hblank_O		: out std_logic;

			clk_12		: in std_logic;
			clk_6_O		: out std_logic;

			-- signals that carry the ROM data from the MiSTer disk
			dn_addr        : in  std_logic_vector(15 downto 0);
			dn_data        : in  std_logic_vector(7 downto 0);
			dn_wr          : in  std_logic
			
			

			
			);

end super_breakout;

architecture rtl of super_breakout is

--signal clk_12			: std_logic;
signal clk_6			: std_logic;
signal phi2				: std_logic;

signal reset_h			: std_logic;

signal NMI_n			: std_logic;
signal Timer_Reset_n	: std_logic;
signal IntAck_n		: std_logic;
signal IO_wr			: std_logic;
signal Adr				: std_logic_vector(9 downto 0);
signal Inputs			: std_logic_vector(1 downto 0);

-- Video timing signals
signal Hcount		   : std_logic_vector(8 downto 0) := (others => '0');
signal hcolor		   : std_logic_vector(7 downto 0);
signal H256				: std_logic;
signal H256_s			: std_logic;
signal H256_n			: std_logic;
signal H128				: std_logic;
signal H64				: std_logic;
signal H32				: std_logic;
signal H16				: std_logic;
signal H8				: std_logic;
signal H8_n				: std_logic;
signal H4				: std_logic;
signal H4_n				: std_logic;
signal H2				: std_logic;
signal H1				: std_logic;

signal Vcount  		: std_logic_vector(7 downto 0) := (others => '0');
signal Video			: std_logic;
signal V128				: std_logic;
signal V64				: std_logic;
signal V32				: std_logic;
signal V16				: std_logic;
signal V8				: std_logic;
signal V4				: std_logic;
signal V2				: std_logic;
signal V1				: std_logic;

signal Hsync			: std_logic;
signal Vsync			: std_logic;
signal Vblank			: std_logic;
signal Vreset			: std_logic;
signal Vblank_s		: std_logic;
signal Vblank_n_s		: std_logic;
signal HBlank			: std_logic;
signal CompBlank_s	: std_logic;
signal CompSync_n_s	: std_logic;

-- Video output signals
signal Playfield_n	: std_logic;
signal Ball1_n			: std_logic := '1';
signal Ball2_n			: std_logic := '1';
signal Ball3_n			: std_logic := '1';

signal Display			: std_logic_vector(7 downto 0);

signal Tones_n			: std_logic;

signal SW2				: std_logic_vector(7 downto 0) := (others => '0');
signal Mask1_n			: std_logic;
signal Mask2_n			: std_logic;
signal Sense1			: std_logic;
signal Sense2			: std_logic;

begin
-- Configuration DIP switches, these can be brought out to external switches if desired
-- See Super Breakout manual page 13 for complete information. Active low (0 = On, 1 = Off)
--    1 	2							Language				(00 - English)
--   			3	4					Coins per play		(10 - 1 Coin, 1 Play) 
--						5				3/5 Balls			(1 - 3 Balls)
--							6	7	8	Bonus play			(011 - 600 Progressive, 400 Cavity, 600 Double)
		
SW2 <= SW1_I;--"00101011";
  

-- Video mixer
Video_O <= not(Playfield_n and Ball1_n and Ball2_n and Ball3_n);
CompSync_O <= CompSync_n_s;

-- r 3  g 3  b 2
-- https://github.com/mamedev/mame/blob/master/src/mame/layout/sbrkout.lay
process (hcolor,Playfield_n , Ball1_n , Ball2_n , Ball3_n)
begin
Video <=  not(Playfield_n and Ball1_n and Ball2_n and Ball3_n);
if ( (unsigned(hcolor) >=0 ) and (unsigned(hcolor) <= 40) ) then
	if (Video='1') then
		Video_RGB  <=  "10011011";
	else
		Video_RGB  <=  "00000000";
	end if;
elsif  (( unsigned(hcolor)  >=41 ) and (unsigned(hcolor) <=72)) then
	if (Video='1') then
		Video_RGB  <=  "11110010";
	else
		Video_RGB  <=  "00000000";
	end if;
elsif  (( unsigned(hcolor)  >=73 ) and (unsigned(hcolor) <=105)) then
	if (Video='1') then
		Video_RGB  <=  "00111110";
	else
		Video_RGB  <=  "00000000";
	end if;
elsif  ((unsigned(hcolor)  >=106 ) and (unsigned(hcolor) <=231)) then
	if (Video='1') then
		Video_RGB  <=  "10011011";
	else
		Video_RGB  <=  "00000000";
	end if;
elsif  (( unsigned(hcolor)  >=232) and (unsigned(hcolor) <=240)) then
	if (Video='1') then
		Video_RGB  <=  "10010011";
	else
		Video_RGB  <=  "00000000";
	end if;
elsif  (( unsigned(hcolor)  >=241) and (unsigned(hcolor) <=256)) then
	if (Video='1') then
		Video_RGB  <=  "11111111";
	else
		Video_RGB  <=  "00000000";
	end if;
else
	if (Video='1') then
		Video_RGB  <=  "11111111";
	else
		Video_RGB  <=  "00000000";
	end if;
end if;
end process;

Reset_h <= (not Reset_n); -- Some components need an active-high reset
Vblank_O <= Vblank; -- Resets ramp in analog paddle circuit (if used)

-- PLL to generate 12.096 MHz master clock

		
Vid_sync: entity work.synchronizer
port map(
		clk_12 => clk_12,
		clk_6 => clk_6,
		hcount => hcount,
		vcount => vcount,
		hsync => hsync,
		hblank => hblank,
		vblank_s => vblank_s,
		vblank_n_s => vblank_n_s,
		vblank => vblank,
		vsync => vsync,
		vreset => vreset
		);		

PF: entity work.playfield
port map(
		Clk6 => clk_6,
		Display => Display,
		HCount => HCount,
		VCount => VCount,
		H256_s => H256_s,
		HBlank => HBlank,
		VBlank => VBlank,
		VBlank_n_s => VBlank_n_s,
		HSync => HSync,
		VSync => VSync,
		CompSync_n_s => CompSync_n_s,
		CompBlank_s => CompBlank_s,
		Playfield_n => Playfield_n
		);
	
Ball_motion: entity work.motion
port map(
		Clk6 => clk_6,
		PHI2 => phi2,
		Display => Display,
		H256_s => H256_s,
		VCount => VCount,
		HCount => HCount,
		Tones_n => Tones_n,
		Ball1_n => Ball1_n,
		Ball2_n => Ball2_n,
		Ball3_n => Ball3_n	
		);

Sounds: entity work.audio
port map(
		Clk_50 => Clk_50_i,
		Reset_n => Reset_n,
		Tones_n => Tones_n,
		Display => Display(3 downto 0),
		VCount => VCount,
		Audio_PWM => Audio_O
		);
	
Knob: entity work.paddle
port map(
		Clk6 => Clk_6,
		Enc_A => Enc_A,
		Enc_B => Enc_B,
		Mask1_n => Mask1_n,
		Mask2_n => Mask2_n,
		Vblank => Vblank,
		Sense1 => Sense1,
		Sense2 => Sense2,
		NMI_n => NMI_n
		);
	
CPU: entity work.cpu_mem
port map(
		Clk12 => Clk_12,
		Clk6 => Clk_6,
		Reset_n => Reset_n,
		NMI_n => NMI_n,
		VCount => VCount,
		HCount => HCount,
		Hsync_n => not Hsync,
		Timer_Reset_n => Timer_Reset_n,
		IntAck_n => IntAck_n,
		IO_wr => IO_wr,
		Phi2_o => Phi2,
		Display => Display,
		IO_Adr => Adr,
		Inputs => Inputs
		);
	
Input_Output: entity work.IO
port map(
		clk6 => clk_6,
		SW2 => SW2, -- DIP switches
		Coin1_n => Coin1_I,
		Coin2_n => Coin2_I,
		Start1_n => Start1_I,
		Start2_n => Start2_I,
		Select1_n => Select1_I,
		Select2_n => Select2_I,
		Serve_n => Serve_I,
		Test_n => Test_I,
		Slam_n => Slam_I,
		Sense1 => Sense1,
		Sense2 => Sense2,
		Mask1_n => Mask1_n,
		Mask2_n => Mask2_n,
		Timer_Reset_n => Timer_Reset_n,
		IntAck_n => IntAck_n,
		IO_wr => IO_wr,
		Lamp1 => Lamp1_O,
		Lamp2 => Lamp2_O,
		Serv_LED_n => Serve_LED_O, 
		Counter => Counter_O,
		Adr => Adr,
		Inputs => Inputs
	);	
hs_O<= hsync;
hblank_O <= HBlank;
vblank_O <= VBlank;
vs_O <=vsync;
clk_6_O<=clk_6;	
end rtl;