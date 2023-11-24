//-------------------------------------------------------------------------
//      VGA controller                                                   --
//      Kyle Kloepper                                                    --
//      4-05-2005                                                        --
//                                                                       --
//      Modified by Stephen Kempf 04-08-2005                             --
//                                10-05-2006                             --
//                                03-12-2007                             --
//      Translated by Joe Meng    07-07-2013                             --
//      Modified by Zuofu Cheng   06-02-2023                             --
//      Fall 2023 Distribution                                           --
//                                                                       --
//      Used standard 640x480 vga found at epanorama                     --
//                                                                       --
//      reference: http://www.xilinx.com/bvdocs/userguides/ug130.pdf     --
//                 http://www.epanorama.net/documents/pc/vga_timing.html --
//                                                                       --
//      note: The standard is changed slightly because of 25 mhz instead --
//            of 25.175 mhz pixel clock. Refresh rate drops slightly.    --
//                                                                       --
//      For use with ECE 385 along with RealDigital HDMI encoder         --
//      ECE Department @ UIUC                                            --
//-------------------------------------------------------------------------


module  vga_controller ( input        pixel_clk,        // 50 MHz clock
                                      reset,            // reset signal
                                      Run,
                                      ppu_clk,
                         input logic [7:0] ppu_pixel,
                         input logic [9:0] ppu_x,
                                           ppu_y,
                                      
                                      
                         input logic [15:0] SW,
                         output logic hs,               // Horizontal sync pulse.  Active low
								      vs,               // Vertical sync pulse.  Active low
									  active_nblank,    // High = active, low = blanking interval
									  sync,      // Composite Sync signal.  Active low.  We don't use it in this lab,
									            //   but the video DAC on the DE2 board requires an input for it.
						 output [9:0] drawX,     // horizontal coordinate
						              drawY,     // vertical coordinate
						              
						 output logic [7:0] Red,
						                    Green,
						                    Blue
);
    
    // 800 horizontal pixels indexed 0 to 799
    // 525 vertical pixels indexed 0 to 524
	parameter [9:0] hpixels = 10'd799;
    parameter [9:0] vlines = 10'd524;

	 // horizontal pixel and vertical line counters
    logic [9:0] hc, vc;
    
	 // signal indicates if ok to display color for a pixel
	 logic display;
	 
    //Disable Composite Sync
    assign sync = 1'b0;
        
    // Block memory
    logic [15:0] blk_mem_addra;
    logic wea;
    logic [15:0] blk_mem_addrb;
    logic [7:0] doutb;
    
    assign blk_mem_addrb = (((vc[9:1]) * 256) + hc[9:1] - 31);
    assign blk_mem_addra = (((ppu_y) * 256) + ppu_x);
    
    blk_mem_gen_0 blk_ram (.addra(blk_mem_addra), .clka(ppu_clk), .dina(ppu_pixel), .wea(wea),
                       .addrb(blk_mem_addrb), .clkb(pixel_clk), .doutb(doutb));

    // Prevent overscan lines from rendering
    always_comb
    begin
        wea = 1'b0;
        if ( ppu_x < 10'd256 && ppu_y < 10'd240 )
            wea = 1'b1;
    end
   
	//Runs the horizontal counter  when it resets vertical counter is incremented
   always_ff @ ( posedge pixel_clk or posedge reset )
	begin: counter_proc
		  if ( reset ) 
			begin 
				 hc <= 10'b0000000000;
				 vc <= 10'b0000000000;
			end
		  else 
		         

         if ( hc == hpixels )  //If hc has reached the end of pixel count
          begin 
                hc <= 10'b0000000000;
                if ( vc == vlines )   //if vc has reached end of line count
                     vc <= 10'b0000000000;
                else 
                     vc <= (vc + 1);
          end
         else 
         begin
              hc <= (hc + 1);  //no statement about vc, implied vc <= vc;
         end
	 end 
   
    assign drawX = hc;
    assign drawY = vc;
   
	 //horizontal sync pulse is 96 pixels long at pixels 656-752
    //(signal is registered to ensure clean output waveform)
    always_ff @ (posedge reset or posedge pixel_clk )
    begin : hsync_proc
        if ( reset ) 
            hs <= 1'b0;
        else  
            if ((((hc + 1) >= 10'd656) & ((hc + 1) < 10'd752))) 
                hs <= 1'b0;
            else 
				    hs <= 1'b1;
    end
	 
    //vertical sync pulse is 2 lines(800 pixels) long at line 490-491
    //(signal is registered to ensure clean output waveform)
    always_ff @ (posedge reset or posedge pixel_clk )
    begin : vsync_proc
        if ( reset ) 
           vs <= 1'b0;
        else 
            if ( ((vc + 1) == 9'd490) | ((vc + 1) == 9'd491) ) 
			       vs <= 1'b0;
            else 
			       vs <= 1'b1;
    end
       
    //only display pixels between horizontal 0-639 and vertical 0-479 (640x480)
    //(This signal is registered within the DAC chip, so we can leave it as pure combinational logic here)    
    always_comb
    begin 
        if ( (hc >= 10'd640) | (vc >= 10'd480) ) 
            display = 1'b0;
        else 
            display = 1'b1;
    end 
   
    assign active_nblank = display;   
    
    // Color maps
	logic chx = hc[2] + vc[2]; // Checker board
	logic [23:0] rgb;
	assign Red = rgb[23:16];
	assign Green = rgb[15:8];
	assign Blue = rgb[7:0];

    // Calculate pixel color based on VRAM palette byte
    logic [23:0] nes_pixel;
    nes_color_rom nes_color ( .addr(doutb[5:0]), .data(nes_pixel) ); 
    
    // Render NES viewport in center of screen
    always_comb
    begin
        if ( hc >= 10'd64 & hc <= 575 )
            rgb = nes_pixel;
        else
        begin
            if (chx)
                rgb = 24'hffffff;  
            else
                rgb = 24'h000000;
        end
    end
         

endmodule
