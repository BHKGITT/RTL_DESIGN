///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: apb.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::SmartFusion2> <Die::M2S150T> <Package::1152 FC>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

module custom_apb3_slave#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32)
   ( 
        input                   PClock ,
        input                   Presetn ,
        input[ADDR_WIDTH -1:0]  Paddr ,
        input                   Psel ,      //Psel_0 = 1 indicates slave_0 selected and data transfer required
        input                   Penable ,   //Indicates 2nd and subsequent transfer
        input                   Pwrite ,    //Pwrite = 1 : write, Pwrite = 0 : Read     
        input[DATA_WIDTH -1:0]  Pwdata ,    
        output reg              Pready ,    //Pready = 1 : Extend transfer
        output reg [DATA_WIDTH -1:0] Prdata ,         
        output                  Pslverr     //Indicates transfer failed, AP3 peripherals are not required to support the Pslverr pin  and it is "tied to low"  
    );
    
localparam[1:0]  IDLE   = 2'b00 ; 
localparam[1:0]  SETUP  = 2'b01 ; 
localparam[1:0]  ACCESS = 2'b10 ; 
reg[1:0] apb_state = IDLE ;

//Internal registers
reg[DATA_WIDTH -1:0] slv_reg_0 ;   // 0x00
reg[DATA_WIDTH -1:0] slv_reg_1 ;   // 0x04
reg[DATA_WIDTH -1:0] slv_reg_2 ;   // 0x08
reg[DATA_WIDTH -1:0] slv_reg_3 ;   // 0x0c 
reg[DATA_WIDTH -1:0] slv_reg_4 ;   // 0x10

always@(posedge PClock or negedge Presetn)
begin
    if(Presetn == 1'b0 )
    begin
        apb_state <= IDLE ;
        Pready    <= 1'b0 ;
    end
    else begin
        case(apb_state)
               IDLE : begin
                        Pready    <= 1'b0 ;
                        if(Psel == 1'b1 )
                            apb_state <= SETUP ;
                      end
              SETUP : begin                        
                        apb_state <= ACCESS ;
                        Pready    <= 1'b1;  // Ready for transfer
                      end
             ACCESS : begin
                        if(Psel == 1'b0) 
                        begin
                            apb_state <= IDLE ;
                            Pready    <= 1'b0 ; //Transfer completed
                        end
                      end
            default : apb_state <= IDLE ;
        endcase
    end
end


//Internal register :  Write to Fabric
always@(posedge PClock or negedge Presetn)
begin
    if(Presetn == 1'b0)
    begin
        slv_reg_0 <= 32'd0 ;
        slv_reg_1 <= 32'd0 ;
        slv_reg_2 <= 32'd0 ;
        slv_reg_3 <= 32'd0 ;
        slv_reg_4 <= 32'd0 ;
    end
    else begin
        if(Psel && Penable && Pwrite)
        begin
            case(Paddr[7:0])
                8'h00 : slv_reg_0 <= Pwdata ;
                8'h04 : slv_reg_1 <= Pwdata ;
                8'h08 : slv_reg_2 <= Pwdata ;
                8'h0c : slv_reg_3 <= Pwdata ;
                8'h10 : slv_reg_4 <= Pwdata ;
              default : ;
            endcase
        end
    end
end
//Internal register :  Write to MSS
always@(*)
begin
    Prdata = 32'd0 ;
    if(Psel && Pwrite == 1'b0)
    begin
        case(Paddr[7:0])
            8'h00 : Prdata = slv_reg_0 ;    
            8'h04 : Prdata = slv_reg_1 ;    
            8'h08 : Prdata = slv_reg_2 ;    
            8'h0c : Prdata = slv_reg_3 ;    
            8'h10 : Prdata = slv_reg_4 ;    
          default : Prdata = 'h FFFFFFFF ;
        endcase
    end
end

assign Pslverr = 1'b0 ;

endmodule
