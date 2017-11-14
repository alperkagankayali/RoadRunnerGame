`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:30:38 03/19/2013 
// Design Name: 
// Module Name:    vga640x480 
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
module VGA(
    input wire dclk,			//pixel clock: 25MHz
    //input logic jumpingpress,
    input logic [1:0] selected,
    input reg [3:0] hex,
    input wire clr,			//asynchronous reset
    output wire hsync,		//horizontal sync out
    output wire vsync,		//vertical sync out
    output reg [7:0] red,	//red vga output
    output reg [7:0] green, //green vga output
    output reg [7:0] blue,	//blue vga output
    output reg [4:0] obstaclespassedfinal,
    output reg [1:0] livesfinal
);

// video structure constants
parameter hpixels = 800;// horizontal pixels per line
parameter vlines = 521; // vertical lines per frame
parameter hpulse = 96; 	// hsync pulse length
parameter vpulse = 2; 	// vsync pulse length
parameter hbp = 144; 	// end of horizontal back porch
parameter hfp = 784; 	// beginning of horizontal front porch
parameter vbp = 31; 		// end of vertical back porch
parameter vfp = 511; 	// beginning of vertical front porch


// active horizontal video is therefore: 784 - 144 = 640
// active vertical video is therefore: 511 - 31 = 480

// registers for storing the horizontal & vertical counters
reg [9:0] hc;
reg [9:0] vc;

logic [9:0] movement = 10'b0000000000;
logic [7:0] movementcoyote = 8'b00000000;
logic [7:0] jumping;
logic clock1,clock2,clock3,clock4,clock5,clock6,clock7,clock8;
logic position;
logic jumpingpress;
logic jumpingnotpressedagain;
logic restart;

always_ff@(posedge dclk)
begin
    if(hex == 4'b0001)
    begin
        jumpingpress = 1'b1;
        //jumpingnotpressedagain = 1'b0;
    end
    else if(hex == 4'b0101)
    begin
        restart = 1'b1;
    end
    else
    begin
        jumpingpress = 1'b0;
        jumpingnotpressedagain = 1'b1;
        restart = 1'b0;
    end
end
// Horizontal & vertical counters --
// this is how we keep track of where we are on the screen.
// ------------------------
// Sequential "always block", which is a block that is
// only triggered on signal transitions or "edges".
// posedge = rising edge  &  negedge = falling edge
// Assignment statements can only be used on type "reg" and need to be of the "non-blocking" type: <=
always @(posedge dclk or posedge clr)
begin
// reset condition
    if (clr == 1)
    begin
        hc <= 0;
        vc <= 0;
    end
    else
    begin
    // keep counting until the end of the line
        if (hc < hpixels - 1)
            hc <= hc + 1;
        else
        // When we hit the end of the line, reset the horizontal
        // counter and increment the vertical counter.
        // If vertical counter is at the end of the frame, then
        // reset that one too.
        begin
            hc <= 0;
            if (vc < vlines - 1)
                vc <= vc + 1;
            else
                vc <= 0;
        end

    end
end

// generate sync pulses (active low)
// ----------------
// "assign" statements are a quick way to
// give values to variables of type: wire
assign hsync = (hc < hpulse) ? 0:1;
assign vsync = (vc < vpulse) ? 0:1;


Clockdiv dut(dclk,clr,clock1,clock2,clock3,clock4,clock5,clock6,clock7);




logic [4:0] obstaclepassed;



typedef enum logic[1:0]{s0,s1}
statetype;
statetype state, nextstate;

always_ff@(posedge clock4,posedge clr)
begin
    if(clr) state <= s0;
    else state <= nextstate;
end

always_comb
begin
    case(state)
        s0: nextstate = s1;
        s1: nextstate = s0;

    endcase
end 

always_comb
begin
    case(state)
        s0: {position} = {1'b0};
        s1: {position} = {1'b1};

    endcase
end

always_comb
begin
    if(selected == 2'b11 || selected == 2'b10)
    begin
        clock8 = clock7;
    end
    else if(selected == 2'b01)
    begin
        clock8 = clock5;
    end
    else
        clock8 = clock6;
end


always_ff@(posedge clock3)
begin
    if(jumpingpress == 1'b1 && jumpingnotpressedagain == 1'b1 && jumping >= 0 && jumping <= 250)
    begin
        jumping <= jumping + 1;

    end
    else
    begin
        if(jumping > 0)
        begin
            jumping <= jumping - 1;
        end
    end
end

logic [1:0] lives = 2'b11;


logic [31:0] counting = 32'b00000000000000000000000000000000;


always_ff@(posedge clock8)
begin

    obstaclespassedfinal = obstaclepassed;
    livesfinal = lives;
    
    if(lives == 2'b00)
    begin
        if(restart == 1'b0)
        begin
            counting <= counting + 1;
        end
        else
        begin
            counting = 32'b11111111111111111111111111111111;
            movement <= 0;
            lives <= 2'b11;
            obstaclepassed <= 0;
        end
    end
    
    else if(movement <= 336)
        movement <= movement + 1;
    else if(movement >= 336 && movement <= 464 && jumping >= 140)
    begin
        movement <= movement + 1;
    end
    else if(movement >= 336 && movement <= 464 && jumping <= 140)
    begin
        movement <= 0;
        lives <= lives -1;
    end
    else if(movement >= 464 && movement <= 704)
        movement <= movement + 1;
    else
    begin
        movement <= 0;

        
        obstaclepassed <= obstaclepassed + 1;

    end
end

always_ff@(posedge clock8)
begin
    if(movementcoyote <= 80 && lives == 2'b10)
    begin
        movementcoyote <= movementcoyote + 1;
    end
    else if(movementcoyote>=80 && movementcoyote <= 160 && lives ==2'b01)
    begin
        movementcoyote <= movementcoyote + 1;
    end
    else if(movementcoyote>=160 && movementcoyote <= 180 && lives ==2'b00) 
    begin
        movementcoyote <= 0;
    end
    else
        movementcoyote <= movementcoyote;
end




//output

// display 100% saturation colorbars
// ------------------------
// Combinational "always block", which is a block that is
// triggered when anything in the "sensitivity list" changes.
// The asterisk implies that everything that is capable of triggering the block
// is automatically included in the sensitivty list.  In this case, it would be
// equivalent to the following: always @(hc, vc)
// Assignment statements can only be used on type "reg" and should be of the "blocking" type: =
always @(*)
begin
// first check if we're within vertical active video range
    if (vc >= vbp && vc < vfp)
    begin
// now display different colors every 80 pixels
// while we're within the active horizontal range
// -----------------
// display white bar



        if(lives != 2'b00)
        begin
            if(vc>=415 && vc < 419 && hc>=(hbp+38+movementcoyote) && hc < (hbp+70+movementcoyote) && position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=419 && vc < 423 && hc>=(hbp+34+movementcoyote) && hc < (hbp+58+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=419 && vc < 423 && hc>=(hbp+64+movementcoyote) && hc < (hbp+70+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=423 && vc < 427 && hc>=(hbp+34+movementcoyote) && hc < (hbp+48+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=427 && vc < 431 && hc>=(hbp+34+movementcoyote) && hc < (hbp+50+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=431 && vc < 435 && hc>=(hbp+34+movementcoyote) && hc < (hbp+54+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=435 && vc < 439 && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=435 && vc < 439 && hc>=(hbp+48+movementcoyote) && hc < (hbp+58+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=439 && vc < 443 && hc>=(hbp+32+movementcoyote) && hc < (hbp+44+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=439 && vc < 443 && hc>=(hbp+56+movementcoyote) && hc < (hbp+66+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=443 && vc < 447 && hc>=(hbp+32+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=443 && vc < 447 && hc>=(hbp+60+movementcoyote) && hc < (hbp+68+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=447 && vc < 451 && hc>=(hbp+20+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=447 && vc < 451 && hc>=(hbp+62+movementcoyote) && hc < (hbp+70+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=451 && vc < 455 && hc>=(hbp+18+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=451 && vc < 455 && hc>=(hbp+66+movementcoyote) && hc < (hbp+70+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=455 && vc < 459 && hc>=(hbp+18+movementcoyote) && hc < (hbp+40+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=455 && vc < 459 && hc>=(hbp+68+movementcoyote) && hc < (hbp+70+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=459 && vc < 463 && hc>=(hbp+18+movementcoyote) && hc < (hbp+32+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=463 && vc < 467 && hc>=(hbp+18+movementcoyote) && hc < (hbp+26+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=467 && vc < 471 && hc>=(hbp+18+movementcoyote) && hc < (hbp+24+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=471 && vc < 475 && hc>=(hbp+16+movementcoyote) && hc < (hbp+24+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=475 && vc < 479 && hc>=(hbp+12+movementcoyote) && hc < (hbp+18+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=479 && vc < 487 && hc>=(hbp+12+movementcoyote) && hc < (hbp+16+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=451 && vc < 475 && hc>=(hbp+12+movementcoyote) && hc < (hbp+14+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=451 && vc < 455 && hc>=(hbp+6+movementcoyote) && hc < (hbp+12+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=455 && vc < 467 && hc>=(hbp+4+movementcoyote) && hc < (hbp+12+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=467 && vc < 479 && hc>=(hbp+4+movementcoyote) && hc < (hbp+10+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=479 && vc < 487 && hc>=(hbp+4+movementcoyote) && hc < (hbp+8+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=475 && vc <483  && hc>=(hbp+22+movementcoyote) && hc < (hbp+26+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=483 && vc <487  && hc>=(hbp+24+movementcoyote) && hc < (hbp+28+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=487 && vc <495  && hc>=(hbp+26+movementcoyote) && hc < (hbp+30+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=495 && vc <499  && hc>=(hbp+28+movementcoyote) && hc < (hbp+38+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=499 && vc <503  && hc>=(hbp+30+movementcoyote) && hc < (hbp+38+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=503 && vc <511  && hc>=(hbp+30+movementcoyote) && hc < (hbp+36+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=491 && vc <495  && hc>=(hbp+32+movementcoyote) && hc < (hbp+38+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=487 && vc <491  && hc>=(hbp+32+movementcoyote) && hc < (hbp+40+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=479 && vc <487  && hc>=(hbp+34+movementcoyote) && hc < (hbp+40+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=363 && vc <371  && hc>=(hbp+38+movementcoyote) && hc < (hbp+46+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=371 && vc <375  && hc>=(hbp+36+movementcoyote) && hc < (hbp+46+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=375 && vc <379  && hc>=(hbp+34+movementcoyote) && hc < (hbp+44+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=379 && vc <383  && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=383 && vc <391  && hc>=(hbp+34+movementcoyote) && hc < (hbp+40+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=387 && vc <391  && hc>=(hbp+40+movementcoyote) && hc < (hbp+46+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=391 && vc <395  && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=391 && vc <395  && hc>=(hbp+42+movementcoyote) && hc < (hbp+46+movementcoyote)&& position)
            begin
                red=8'b11111111;
                green=8'b11111111;
                blue=8'b111111111;
            end
            else if(vc>=391 && vc <395  && hc>=(hbp+46+movementcoyote) && hc < (hbp+48+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+34+movementcoyote) && hc < (hbp+38+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+38+movementcoyote) && hc < (hbp+44+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+44+movementcoyote) && hc < (hbp+46+movementcoyote)&& position)
            begin
                red=8'b11111111;
                green=8'b11111111;
                blue=8'b111111111;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+46+movementcoyote) && hc < (hbp+48+movementcoyote)&& position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+48+movementcoyote) && hc < (hbp+50+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=399 && vc <403  && hc>=(hbp+34+movementcoyote) && hc < (hbp+54+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=399 && vc <403  && hc>=(hbp+54+movementcoyote) && hc < (hbp+58+movementcoyote)&& position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=403 && vc <407  && hc>=(hbp+34+movementcoyote) && hc < (hbp+40+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=403 && vc <407  && hc>=(hbp+40+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=403 && vc <407  && hc>=(hbp+42+movementcoyote) && hc < (hbp+56+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=407 && vc <411  && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=407 && vc <411  && hc>=(hbp+42+movementcoyote) && hc < (hbp+48+movementcoyote)&& position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=411 && vc <415  && hc>=(hbp+34+movementcoyote) && hc < (hbp+46+movementcoyote)&& position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=415 && vc <423  && hc>=(hbp+70+movementcoyote) && hc < (hbp+76+movementcoyote)&& position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=415 && vc < 419 && hc>=(hbp+38+movementcoyote) && hc < (hbp+70+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=419 && vc < 423 && hc>=(hbp+34+movementcoyote) && hc < (hbp+58+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=419 && vc < 423 && hc>=(hbp+64+movementcoyote) && hc < (hbp+70+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=423 && vc < 427 && hc>=(hbp+34+movementcoyote) && hc < (hbp+48+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=427 && vc < 431 && hc>=(hbp+34+movementcoyote) && hc < (hbp+50+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=431 && vc < 435 && hc>=(hbp+34+movementcoyote) && hc < (hbp+54+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=435 && vc < 439 && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=435 && vc < 439 && hc>=(hbp+48+movementcoyote) && hc < (hbp+58+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;

            end
            else if(vc>=439 && vc < 443 && hc>=(hbp+32+movementcoyote) && hc < (hbp+44+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=439 && vc < 443 && hc>=(hbp+56+movementcoyote) && hc < (hbp+66+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=443 && vc < 447 && hc>=(hbp+32+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=443 && vc < 447 && hc>=(hbp+60+movementcoyote) && hc < (hbp+68+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=447 && vc < 451 && hc>=(hbp+20+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=447 && vc < 451 && hc>=(hbp+62+movementcoyote) && hc < (hbp+70+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=451 && vc < 455 && hc>=(hbp+18+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=451 && vc < 455 && hc>=(hbp+66+movementcoyote) && hc < (hbp+70+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=455 && vc < 459 && hc>=(hbp+18+movementcoyote) && hc < (hbp+40+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=455 && vc < 459 && hc>=(hbp+68+movementcoyote) && hc < (hbp+70+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=459 && vc < 463 && hc>=(hbp+18+movementcoyote) && hc < (hbp+32+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=463 && vc < 467 && hc>=(hbp+18+movementcoyote) && hc < (hbp+26+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=363 && vc <371  && hc>=(hbp+38+movementcoyote) && hc < (hbp+46+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=371 && vc <375  && hc>=(hbp+36+movementcoyote) && hc < (hbp+46+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=375 && vc <379  && hc>=(hbp+34+movementcoyote) && hc < (hbp+44+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=379 && vc <383  && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=383 && vc <391  && hc>=(hbp+34+movementcoyote) && hc < (hbp+40+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=387 && vc <391  && hc>=(hbp+40+movementcoyote) && hc < (hbp+46+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=391 && vc <395  && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=391 && vc <395  && hc>=(hbp+42+movementcoyote) && hc < (hbp+46+movementcoyote)&& ~position)
            begin
                red=8'b11111111;
                green=8'b11111111;
                blue=8'b111111111;
            end
            else if(vc>=391 && vc <395  && hc>=(hbp+46+movementcoyote) && hc < (hbp+48+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+34+movementcoyote) && hc < (hbp+38+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+38+movementcoyote) && hc < (hbp+44+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+44+movementcoyote) && hc < (hbp+46+movementcoyote)&& ~position)
            begin
                red=8'b11111111;
                green=8'b11111111;
                blue=8'b111111111;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+46+movementcoyote) && hc < (hbp+48+movementcoyote)&& ~position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=395 && vc <399  && hc>=(hbp+48+movementcoyote) && hc < (hbp+50+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=399 && vc <403  && hc>=(hbp+34+movementcoyote) && hc < (hbp+54+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=399 && vc <403  && hc>=(hbp+54+movementcoyote) && hc < (hbp+58+movementcoyote)&& ~position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=403 && vc <407  && hc>=(hbp+34+movementcoyote) && hc < (hbp+40+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=403 && vc <407  && hc>=(hbp+40+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=403 && vc <407  && hc>=(hbp+42+movementcoyote) && hc < (hbp+56+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=407 && vc <411  && hc>=(hbp+34+movementcoyote) && hc < (hbp+42+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=407 && vc <411  && hc>=(hbp+42+movementcoyote) && hc < (hbp+48+movementcoyote)&& ~position)
            begin
                red=8'b00000000;
                green=8'b00000000;
                blue=8'b00000000;
            end
            else if(vc>=411 && vc <415  && hc>=(hbp+34+movementcoyote) && hc < (hbp+46+movementcoyote)&& ~position)
            begin
                red=8'b11110100;
                green=8'b11101011;
                blue=8'b11100000;
            end
            else if(vc>=467 && vc < 511 && hc>=(hbp+18+movementcoyote) && hc < (hbp+24+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=503 && vc < 511 && hc>=(hbp+24+movementcoyote) && hc < (hbp+38+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>=415 && vc <423  && hc>=(hbp+70+movementcoyote) && hc < (hbp+76+movementcoyote)&& ~position)
            begin
                red=8'b01100011;
                green=8'b00011001;
                blue=8'b00011001;
            end
            else if(vc>= 371 && vc < 376 && hc>=(hbp+356- movement+320) && hc < (hbp+364- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>= 381 && vc < 411 && hc>=(hbp+336- movement+320) && hc < (hbp+348- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>= 376 && vc < 381 && hc>=(hbp+340- movement+320) && hc < (hbp+344- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>= 406 && vc < 411 && hc>=(hbp+348- movement+320) && hc < (hbp+368- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>= 376 && vc < 406 && hc>=(hbp+352- movement+320) && hc < (hbp+368- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>= 411 && vc < 416 && hc>=(hbp+340- movement+320) && hc < (hbp+368- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=416  && vc < 421 && hc>=(hbp+344- movement+320) && hc < (hbp+368- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=421  && vc < 426 && hc>=(hbp+348- movement+320) && hc < (hbp+384- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=396  && vc < 401 && hc>=(hbp+376- movement+320) && hc < (hbp+380- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=401  && vc < 426 && hc>=(hbp+372- movement+320) && hc < (hbp+384- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=426  && vc < 431 && hc>=(hbp+352- movement+320) && hc < (hbp+380- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=431  && vc < 436 && hc>=(hbp+352- movement+320) && hc < (hbp+376- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=436  && vc < 441 && hc>=(hbp+352- movement+320) && hc < (hbp+372- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if(vc>=441  && vc < 511 && hc>=(hbp+352- movement+320) && hc < (hbp+368- movement+320))
            begin
                red=8'b01011010;
                green=8'b11111111;
                blue=8'b00000000;
            end
            else if (hc >= hbp && hc < (hbp+80))
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end


                // display yellow bar
            else if (hc >= (hbp+80) && hc < (hbp+160))
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end
            // display cyan bar
            else if (hc >= (hbp+160) && hc < (hbp+240))
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end
            // display green bar
            else if (hc >= (hbp+240) && hc < (hbp+320))
            begin

                if(vc>= 371 - jumping && vc < 381- jumping && hc>=(hbp+24+240) && hc < (hbp+56+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=381- jumping && vc<386- jumping && hc >=(hbp+28+240) && hc <(hbp+40+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=381- jumping && vc<386- jumping && hc >=(hbp+44+240) && hc <(hbp+56+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=386- jumping && vc<391- jumping && hc >=(hbp + 32+240) && hc < (hbp+36+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=386- jumping && vc<391- jumping && hc >=(hbp + 48+240) && hc < (hbp+56+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=391- jumping && vc<396- jumping && hc >=(hbp + 48+240) && hc < (hbp+60+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=396- jumping && vc<401- jumping && hc >=(hbp + 48+240) && hc < (hbp+56+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=396- jumping && vc<401- jumping && hc >=(hbp + 56+240) && hc < (hbp+60+240))
                begin
                    red=3'b111;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=401- jumping && vc<411- jumping && hc >=(hbp + 44+240) && hc < (hbp+56+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=401- jumping && vc<411- jumping && hc >=(hbp + 56+240) && hc < (hbp+64+240))
                begin
                    red=3'b111;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=411- jumping && vc<421- jumping && hc >=(hbp + 44+240) && hc < (hbp+48+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=411- jumping && vc<421- jumping && hc >=(hbp + 48+240) && hc < (hbp+60+240))
                begin
                    red=3'b111;
                    green=3'b111;
                    blue=3'b000;
                end
                else if(vc>=411- jumping && vc<416- jumping && hc >=(hbp + 60+240) && hc < (hbp+64+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b110;
                end
                else if(vc>=411- jumping && vc<416- jumping && hc >=(hbp + 68+240) && hc < (hbp+76+240))
                begin
                    red=3'b111;
                    green=3'b111;
                    blue=3'b000;
                end
                else if(vc>=416- jumping && vc<426- jumping && hc >=(hbp + 48+240) && hc < (hbp+72+240))
                begin
                    red=3'b111;
                    green=3'b111;
                    blue=3'b000;
                end
                else if(vc>=426- jumping && vc<466- jumping && hc >=(hbp + 52+240) && hc < (hbp+56+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=446- jumping && vc<461- jumping && hc >=(hbp + 48+240) && hc < (hbp+52+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=451- jumping && vc<456- jumping && hc >=(hbp + 24+240) && hc < (hbp+48+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=446- jumping && vc<461- jumping && hc >=(hbp + 28+240) && hc < (hbp+32+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=391- jumping && vc<451- jumping && hc >=(hbp + 24+240) && hc < (hbp+28+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=381- jumping && vc<431- jumping&& hc >=(hbp + 20+240) && hc < (hbp+24+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=386- jumping && vc<396- jumping && hc >=(hbp + 16+240) && hc < (hbp+20+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=401- jumping && vc<416- jumping && hc >=(hbp + 16+240) && hc < (hbp+20+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=421- jumping && vc<431- jumping && hc >=(hbp + 16+240) && hc < (hbp+20+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=466- jumping && vc<471- jumping && hc >=(hbp + 48+240) && hc < (hbp+52+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=471- jumping && vc<476- jumping && hc >=(hbp + 40+240) && hc < (hbp+48+240))
                begin
                    red=3'b000;
                    green=3'b111;
                    blue=3'b111;
                end
                else if(vc>=456- jumping && vc<461- jumping && hc >=(hbp + 32+240) && hc < (hbp+48+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b111;
                end
                else if(vc>=461- jumping && vc<466- jumping && hc >=(hbp + 28+240) && hc < (hbp+52+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b111;
                end
                else if(vc>=466- jumping && vc<471- jumping && hc >=(hbp + 24+240) && hc < (hbp+48+240))
                begin
                    red=3'b000;
                    green=3'b000;
                    blue=3'b111;
                end
                
                else if(~position)
                begin
                    if(vc >= 476- jumping && vc < 506- jumping && hc >= (hbp+40+240) && hc < (hbp+48+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 506- jumping && vc < 511- jumping && hc >= (hbp+40+240) && hc < (hbp+60+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else
                    begin 
                        red = 8'b11110111;
                        green = 8'b11011110;
                        blue = 8'b10110010;
                    end
                end
                else
                begin
                    if(vc >= 476- jumping && vc < 481- jumping && hc >= (hbp+44+240) && hc < (hbp+48+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 481- jumping && vc < 486- jumping && hc >= (hbp+48+240) && hc < (hbp+52+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 486- jumping && vc < 491- jumping && hc >= (hbp+52+240) && hc < (hbp+56+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 491- jumping && vc < 496 - jumping && hc >= (hbp+56+240) && hc < (hbp+60+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 496- jumping && vc < 501- jumping && hc >= (hbp+60+240) && hc < (hbp+64+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 501- jumping && vc < 506- jumping && hc >= (hbp+64+240) && hc < (hbp+68+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 506- jumping && vc < 511- jumping && hc >= (hbp+68+240) && hc < (hbp+80+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 476- jumping && vc < 481- jumping && hc >= (hbp+40+240) && hc < (hbp+44+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 481- jumping && vc < 486- jumping && hc >= (hbp+36+240) && hc < (hbp+40+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 486- jumping && vc < 491- jumping && hc >= (hbp+32+240) && hc < (hbp+36+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 491- jumping && vc < 496- jumping && hc >= (hbp+28+240) && hc < (hbp+32+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end   
                    else if(vc >= 496- jumping && vc < 501- jumping && hc >= (hbp+24+240) && hc < (hbp+28+240))
                    begin
                        red= 3'b111;
                        green=3'b111;
                        blue=3'b000;
                    end
                    else if(vc >= 501- jumping && vc < 506- jumping && hc >= (hbp+20+240) && hc < (hbp+24+240))
                    begin
                        red = 3'b111;
                        green = 3'b111;
                        blue = 3'b000;
                    end   
                    else if(vc >= 506- jumping && vc < 511- jumping && hc >= (hbp+20+240) && hc < (hbp+32+240))
                    begin
                        red = 3'b111;
                        green = 3'b111;
                        blue = 3'b000;
                    end
                    else
                    begin 
                        red = 8'b11110111;
                        green = 8'b11011110;
                        blue = 8'b10110010;
                    end
                end
            end
        

        // display magenta bar
        //else if (hc >= (hbp+320) && hc < (hbp+400))
        //begin
        else if (hc >=(hbp+320) && hc <(hbp+400))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        //end
        // display red bar
        else if (hc >= (hbp+400) && hc < (hbp+480))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        // display blue bar
        else if (hc >= (hbp+480) && hc < (hbp+560))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        // display black bar
        else if (hc >= (hbp+560) && hc < (hbp+640))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        // we're outside active horizontal range so display black
        else
        begin
            red = 0;
            green = 0;
            blue = 0;
        end
    end
    else
    begin
        if(counting <= 32'b11111111111111111111111111111110)
        begin
        if(hc >= (hbp) && hc < (hbp+80))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        else if(hc >= (hbp+80) && hc < (hbp+160))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        else if(hc >= (hbp+160) && hc < (hbp+240))
        begin
            if(vc >= 200 && vc < 300 && hc >= (hbp+10+160) && hc < (hbp+20+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >= 200 && vc < 210 && hc >= (hbp+20+160) && hc < (hbp+70+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >= 290 && vc < 300 && hc >= (hbp+20+160) && hc < (hbp+70+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >= 260 && vc < 290 && hc >= (hbp+60+160) && hc < (hbp+70+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >= 260 && vc < 270 && hc >= (hbp+50+160) && hc < (hbp+60+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <450  && hc >= (hbp+10+160) && hc < (hbp+20+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <450  && hc >= (hbp+60+160) && hc < (hbp+70+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <360  && hc >= (hbp+20+160) && hc < (hbp+60+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=440  && vc <450  && hc >= (hbp+20+160) && hc < (hbp+60+160))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end
        end
        else if(hc >= (hbp+240) && hc < (hbp+320))
        begin
            if(vc >= 200 && vc < 300 && hc >= (hbp+10+240) && hc < (hbp+20+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >= 200 && vc < 300 && hc >= (hbp+60+240) && hc < (hbp+70+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >= 200 && vc < 210 && hc >= (hbp+20+240) && hc < (hbp+60+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=240  && vc <250  && hc >= (hbp+20+240) && hc < (hbp+60+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <410  && hc >= (hbp+10+240) && hc < (hbp+20+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <410  && hc >= (hbp+60+240) && hc < (hbp+70+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=410  && vc <440  && hc >= (hbp+20+240) && hc < (hbp+30+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=410  && vc <440  && hc >= (hbp+50+240) && hc < (hbp+60+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=440  && vc <450  && hc >= (hbp+30+240) && hc < (hbp+50+240))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end
        end         
        else if(hc >= (hbp+320) && hc < (hbp+400))
        begin
            if(vc >=200  && vc <300  && hc >= (hbp+10+320) && hc < (hbp+20+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=200  && vc <300  && hc >= (hbp+60+320) && hc < (hbp+70+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=210  && vc <220  && hc >= (hbp+20+320) && hc < (hbp+30+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=220  && vc <230  && hc >= (hbp+30+320) && hc < (hbp+50+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=210  && vc <220  && hc >= (hbp+50+320) && hc < (hbp+60+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <450  && hc >= (hbp+10+320) && hc < (hbp+20+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <360  && hc >= (hbp+20+320) && hc < (hbp+70+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=440  && vc <450  && hc >= (hbp+20+320) && hc < (hbp+70+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=390  && vc <400  && hc >= (hbp+20+320) && hc < (hbp+60+320))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end
        end
        else if(hc >= (hbp+400) && hc < (hbp+480))
        begin
            if(vc >=200  && vc <300  && hc >= (hbp+10+400) && hc < (hbp+20+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=200  && vc <210  && hc >= (hbp+20+400) && hc < (hbp+70+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=290  && vc <300  && hc >= (hbp+20+400) && hc < (hbp+70+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=240  && vc <250  && hc >= (hbp+20+400) && hc < (hbp+60+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <450  && hc >= (hbp+10+400) && hc < (hbp+20+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=350  && vc <360  && hc >= (hbp+20+400) && hc < (hbp+70+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=390  && vc <400  && hc >= (hbp+20+400) && hc < (hbp+70+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=360  && vc <390  && hc >= (hbp+60+400) && hc < (hbp+70+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=400  && vc <410  && hc >= (hbp+20+400) && hc < (hbp+30+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=410  && vc <420  && hc >= (hbp+30+400) && hc < (hbp+40+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=420  && vc <430  && hc >= (hbp+40+400) && hc < (hbp+50+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=430  && vc <440  && hc >= (hbp+50+400) && hc < (hbp+60+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else if(vc >=440  && vc <450  && hc >= (hbp+60+400) && hc < (hbp+70+400))
            begin
                red = 3'b111;
                green = 3'b000;
                blue = 3'b000;
            end
            else
            begin
                red = 8'b11110111;
                green = 8'b11011110;
                blue = 8'b10110010;
            end
        end
            
        else if(hc >= (hbp+480) && hc < (hbp+560))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        else if(hc >= (hbp+560) && hc < (hbp+640))
        begin
            red = 8'b11110111;
            green = 8'b11011110;
            blue = 8'b10110010;
        end
        /*else if(!restart)
        begin
            logic [31:0] counting;
            if(counting <= 32'b11111111111111111111111111111111)
            begin
                counting <= counting + 1;
                /*always_ff@(posedge clock6, posedge restart)
                begin
                    if(restart)
                    begin
                        counting <= 32'b11111111111111111111111111111111;
                        movementcoyote <= 0;
                        movement <= 0;
                    end
                    else
                        counting <= counting + 1;
                end*/
            //end
        //end
        else
        begin
            red = 0;
            green = 0;
            blue = 0;
            //movementcoyote <= 0;
            //movement <= 0;
        end
        end
    end
    end
    // we're outside active vertical range so display black
    else
    begin
        red = 0;
        green = 0;
        blue = 0;
    end
end

endmodule
