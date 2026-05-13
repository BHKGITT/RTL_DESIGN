module qadc(
	// Global Signals
	input 		CLK ,	 // System Clock 48Mhz 
	input 		Resetn,
	
	// ADC Signals 
	output reg	CS,		 // Active low 
	output reg	SCLK,
	output reg  MOSI,
	input  		MISO	
);
	localparam[4:0]   NUM_OF_BITS	 = 5'd15;
	
	localparam[1:0]   IDLE 			 = 2'd0;
	localparam[1:0]   ADR_DATA_PHASE = 2'd1;
	localparam[1:0]   DONE			 = 2'd3;
	
	reg[1:0] 		  ADC_STATE = IDLE;
	reg[4:0] 		  BitCounter;
	
	reg[15:0] TxmtData = 16'hA4D2;	// ctrl bit , addrb bits , data bits 
	reg[7:0]  RxData ;
	
	always@(posedge CLK)
	begin 
		if(!Resetn)
		begin
			CS	 		<= 1'b1;
			SCLK 		<= 0;					
			ADC_STATE	<= IDLE;			
		end	
		else begin
			case(ADC_STATE)
				IDLE : begin
							CS	 		<= 1'b0;
							BitCounter	<= NUM_OF_BITS;	
							MOSI 	    <= TxmtData[NUM_OF_BITS];						
							ADC_STATE	<= ADR_DATA_PHASE;
					   end 
	  ADR_DATA_PHASE : begin
							SCLK <= !SCLK;
							// Rising Edge 
							if(!SCLK)
							begin
							    if(BitCounter < 5'd8)
							    begin 
								    RxData[BitCounter] <= MISO;
								end 
							end
							else begin
								// Falling Edge
								if(BitCounter != 0)
								begin								
									MOSI 	   <= TxmtData[BitCounter -1];
									BitCounter <= BitCounter - 1'b1 ;														
								end
								else begin
									ADC_STATE  <= DONE;
								end
							end 
					   end 
				DONE : begin
							CS	 		<= 1'b1;
							SCLK 		<= 1'b0;
							ADC_STATE	<= DONE;
//							ADC_STATE	<= IDLE;
				       end
				default : ; 
			endcase
		end
	end

endmodule


module mainTB;
reg CLK;
reg Resetn;

wire CS;
wire SCLK;
wire MOSI;
reg  MISO;

// Design Intance
qadc dut (
    .CLK    (CLK),
    .Resetn (Resetn),
    .CS     (CS),
    .SCLK   (SCLK),
    .MOSI   (MOSI),
    .MISO   (MISO)
);

// ADC response data
reg [7:0] adc_tx_data;
integer bit_ptr;

// 48 MHz clock
initial
begin
    CLK = 0;
    forever #10.416 CLK = !CLK;   
end

// Reset
initial
begin
    Resetn = 0;
    MISO   = 0;
    adc_tx_data = 8'hD2;

    #100;
    Resetn = 1;
end

// Initialize transfer
always @(negedge CS)
begin
    bit_ptr = 7;
    $display("\n--- SPI Transfer Started ---");
end

// Drives MISO on falling edge of SCLK
always @(negedge SCLK)
begin
    if(!CS)
    begin
//        if(bit_ptr >= 0)
        if(dut.BitCounter <= 7)        
            MISO <= adc_tx_data[dut.BitCounter];           
        else 
            MISO <= 0;        
    end
end


initial begin
	#1000 $finish();
end

endmodule
