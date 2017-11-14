`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:56:56 03/19/2013 
// Design Name: 
// Module Name:    segdisplay 
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
module sevenseg(
	input wire segclk,		//7-segment clock
	input wire clr,			//asynchronous reset
	input logic [1:0] lives,
	input logic [4:0] obstaclepassed,
	output reg [6:0] seg,	//7-segment display LEDs
	output reg [3:0] an		//7-segment display anode enable
	);

// constants for displaying letters on display
parameter N = 7'b1001000;
parameter E = 7'b0000110;
parameter R = 7'b1001100;
parameter P = 7'b0001100;
parameter number0 = 7'b1000000;
parameter number1 = 7'b1111001;
parameter number2 = 7'b0100100;
parameter number3 = 7'b0110000;
parameter number4 = 7'b0011001;
parameter number5 = 7'b0010010;
parameter number6 = 7'b0000010;
parameter number7 = 7'b1111000;
parameter number8 = 7'b0000000;
parameter number9 = 7'b0010000;
parameter divider = 7'b0111111;
// Finite State Machine (FSM) states
parameter left = 2'b00;
parameter midleft = 2'b01;
parameter midright = 2'b10;
parameter right = 2'b11;

// state register
reg [1:0] state;

// FSM which cycles though every digit of the display every 2.62ms.
// This should be fast enough to trick our eyes into seeing that
// all four digits are on display at the same time.
always @(posedge segclk or posedge clr)
begin
	// reset condition
	if (clr == 1)
	begin
		seg <= 7'b1111111;
		an <= 7'b1111;
		state <= left;
	end
	// display the character for the current position
	// and then move to the next state
	else
	begin
		case(state)
			left:
			begin
				if(lives == 2'b11)
				begin
                    seg <= number3;
                    an <= 4'b0111;
                    state <= midleft;
                end
                else if(lives == 2'b10)
                begin
                    seg <= number2;
                    an <= 4'b0111;
                    state <= midleft;
                end
                else if(lives == 2'b01)
                begin
                    seg <= number1;
                    an <= 4'b0111;
                    state <= midleft;
                end
                else
                begin
                    seg <= number0;
                    an <= 4'b0111;
                    state <= midleft;
                    //obstaclepassed <= 0;
                end
			end
			midleft:
			begin
				seg <= divider;
				an <= 4'b1011;
				state <= midright;
			end
			midright:
			begin
				if(obstaclepassed < 2)
				begin
                    seg <= number0;
                    an <= 4'b1101;
                    state <= right;
				end
				else if(obstaclepassed >= 2 && obstaclepassed < 4)
                begin
                    seg <= number1;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 4 && obstaclepassed < 6)
                begin
                    seg <= number2;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 6 && obstaclepassed < 8)
                begin
                    seg <= number3;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 8 && obstaclepassed < 10)
                begin
                    seg <= number4;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 10 && obstaclepassed < 12)
                begin
                    seg <= number5;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 12 && obstaclepassed < 14)
                begin
                    seg <= number6;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 14 && obstaclepassed < 16)
                begin
                    seg <= number7;
                    an <= 4'b1101;
                    state <= right;
                end
                else if(obstaclepassed >= 16 && obstaclepassed < 18)
                begin
                    seg <= number8;
                    an <= 4'b1101;
                    state <= right;
                end
                else
                begin
                    seg <= number9;
                    an <= 4'b1101;
                    state <= right;
                end
			end
			right:
			begin
				if(obstaclepassed % 2 == 0)
				begin
                    seg <= number0;
                    an <= 4'b1110;
                    state <= left;
                end
                else
                begin
                    seg <= number5;
                    an <= 4'b1110;
                    state <= left;
                end
			end
		endcase
	end
end

endmodule
