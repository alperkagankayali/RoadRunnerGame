`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:28:25 03/19/2013 
// Design Name: 
// Module Name:    NERP_demo_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module TopModule(
	input wire clk,			//master clock = 50MHz
	input wire clr,			//right-most pushbutton for reset
	//input logic jumpingpress,
	input logic [1:0] selected,
	input logic [3:0] JBI,
	output logic [3:0] JBO,
	output wire [6:0] seg,	//7-segment display LEDs
	output wire [3:0] an,	//7-segment display anode enable
	output wire dp,			//7-segment display decimal point
	output wire [2:0] red,	//red vga output - 3 bits
	output wire [2:0] green,//green vga output - 3 bits
	output wire [1:0] blue,	//blue vga output - 2 bits
	output wire hsync,		//horizontal sync out
	output wire vsync,		//vertical sync out
	output logic jumpingpress
	);
	
	logic clk2;
	logic [3:0] hexs;
	//logic jumpingpress = 1'b0;
	clk_wiz_1 wiz
      (
     // Clock in ports
      .clk_in1(clk),
      // Clock out ports  
      .clk_out1(clk2),
      // Status and control signals               
      .reset(reset), 
      .locked(locked)            
      );

// 7-segment clock interconnect
wire segclk;

// VGA display clock interconnect
wire dclk;

// disable the 7-segment decimal points
assign dp = 1;

// generate 7-segment clock & display clock
Clockdiv U1(
	.clk(clk2),
	.clr(clr),
	.segclk(segclk),
	.dclk(dclk),
	.jumpingclk(jumpingclk),
	.positionclk(positionclk),
	.movingclk1(movingclk1),
	.movingclk2(movingclk2),
	.movingclk3(movingclk3)
	);

logic [4:0] opf;
logic [1:0] lf;

keypad U4(
    .clk(clk),
    .JBI(JBI),
    .JBO(JBO),
    .hex(hexs),
    .key(key)
    );
    /*always_ff@(posedge clk)
    //begin
        if(hexs == 4'b0001)
        begin
            jumpingpress = 1'b1;
        end
    end*/

VGA U3(
	.dclk(dclk),
	//.jumpingpress(jumpingpress),
	.hex(hexs),
	.selected(selected),
	.clr(clr),
	.hsync(hsync),
	.vsync(vsync),
	.red(red),
	.green(green),
	.blue(blue),
	.obstaclespassedfinal(opf),
	.livesfinal(lf)
	);

// 7-segment display controller
sevenseg U2(
	.segclk(segclk),
	.clr(clr),
	.lives(lf),
	.obstaclepassed(opf),
	.seg(seg),
	.an(an)
	);


// VGA controller


endmodule
