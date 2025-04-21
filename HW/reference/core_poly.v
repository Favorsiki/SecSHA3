///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: poly_ntt.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::PolarFireSoC> <Die::MPFS250T_ES> <Package::FCVG484>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module Core_Poly #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of ID for for write address, write data, read address and read data
    parameter C_S_AXI_ID_WIDTH	= 1,
    // Width of S_AXI data bus
    parameter C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter  C_S_AXI_ADDR_WIDTH	= 32
)
( 
    // Users to add ports here
    output reg         core_poly_irq,
    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write Address ID
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    // Write address
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
    input wire [7 : 0] S_AXI_AWLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
    input wire [2 : 0] S_AXI_AWSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
    input wire [1 : 0] S_AXI_AWBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    input wire  S_AXI_AWLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    input wire [3 : 0] S_AXI_AWCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Quality of Service, QoS identifier sent for each
    // write transaction.
    input wire [3 : 0] S_AXI_AWQOS,
    // Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
    input wire [3 : 0] S_AXI_AWREGION,
    // Write address valid. This signal indicates that
    // the channel is signaling valid write address and
    // control information.
    input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
    output wire  S_AXI_AWREADY,
    // Write Data
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write last. This signal indicates the last transfer
    // in a write burst.
    input wire  S_AXI_WLAST,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire  S_AXI_WREADY,
    // Response ID tag. This signal is the ID tag of the
    // write response.
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
    output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address ID. This signal is the identification
    // tag for the read address group of signals.
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    // Read address. This signal indicates the initial
    // address of a read burst transaction.
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
    input wire [7 : 0] S_AXI_ARLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
    input wire [2 : 0] S_AXI_ARSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
    input wire [1 : 0] S_AXI_ARBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    input wire  S_AXI_ARLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    input wire [3 : 0] S_AXI_ARCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Quality of Service, QoS identifier sent for each
    // read transaction.
    input wire [3 : 0] S_AXI_ARQOS,
    // Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
    input wire [3 : 0] S_AXI_ARREGION,
    // Write address valid. This signal indicates that
    // the channel is signaling valid read address and
    // control information.
    input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
    output wire  S_AXI_ARREADY,
    // Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    // Read Data
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of
    // the read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read last. This signal indicates the last transfer
    // in a read burst.
    output wire  S_AXI_RLAST,
    // Read valid. This signal indicates that the channel
    // is signaling the required read data.
    output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire  S_AXI_RREADY
);

	// AXI4FULL signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rlast;
	reg  	axi_rvalid;
	// aw_wrap_en determines wrap boundary and enables wrapping
	wire aw_wrap_en;
	// ar_wrap_en determines wrap boundary and enables wrapping
	wire ar_wrap_en;
	// aw_wrap_size is the size of the write transfer, the
	// write address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  aw_wrap_size ; 
	// ar_wrap_size is the size of the read transfer, the
	// read address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  ar_wrap_size ; 
	// The axi_awv_awr_flag flag marks the presence of write address valid
	reg axi_awv_awr_flag;
	//The axi_arv_arr_flag flag marks the presence of read address valid
	reg axi_arv_arr_flag; 
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	reg [7:0] axi_awlen_cntr;
	//The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
	reg [7:0] axi_arlen_cntr;
	reg [1:0] axi_arburst;
	reg [1:0] axi_awburst;
	reg [7:0] axi_arlen;
	reg [7:0] axi_awlen;
	//local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	//ADDR_LSB is used for addressing 32/64 bit registers/memories
	//ADDR_LSB = 2 for 32 bits (n downto 2) 
	//ADDR_LSB = 3 for 42 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;

	genvar i;
	genvar j;
	genvar mem_byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RLAST	= axi_rlast;
	assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_BID = S_AXI_AWID;
	assign S_AXI_RID = S_AXI_ARID;
	assign  aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign  ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;

	// Implement axi_awready generation

	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      axi_awv_awr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          // slave is ready to accept an address and
	          // associated control signals
	          axi_awready <= 1'b1;
	          axi_awv_awr_flag  <= 1'b1; 
	          // used for generation of bresp() and bvalid
	        end
	      else if (S_AXI_WLAST && axi_wready)          
	      // preparing to accept next address after current write burst tx completion
	        begin
	          axi_awv_awr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_awaddr latching

	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	      axi_awlen_cntr <= 0;
	      axi_awburst <= 0;
	      axi_awlen <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	        begin
	          // address latching 
	          axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];  
	           axi_awburst <= S_AXI_AWBURST; 
	           axi_awlen <= S_AXI_AWLEN;     
	          // start address of transfer
	          axi_awlen_cntr <= 0;
	        end   
	      else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)        
	        begin

	          axi_awlen_cntr <= axi_awlen_cntr + 1;

	          case (axi_awburst)
	            2'b00: // fixed burst
	            // The write address for all the beats in the transaction are fixed
	              begin
	                axi_awaddr <= axi_awaddr;          
	                //for awsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The write address for all the beats in the transaction are increments by awsize
	              begin
	                axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //awaddr aligned to 4 byte boundary
	                axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The write address wraps when the address reaches wrap boundary 
	              if (aw_wrap_en)
	                begin
	                  axi_awaddr <= (axi_awaddr - aw_wrap_size); 
	                end
	              else 
	                begin
	                  axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                  axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //for awsize = 4 bytes (010)
	              end
	          endcase              
	        end
	    end 
	end       
	// Implement axi_wready generation

	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if ( ~axi_wready && S_AXI_WVALID && axi_awv_awr_flag)
	        begin
	          // slave can accept the write data
	          axi_wready <= 1'b1;
	        end
	      //else if (~axi_awv_awr_flag)
	      else if (S_AXI_WLAST && axi_wready)
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       
	// Implement write response logic generation

	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid <= 0;
	      axi_bresp <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST )
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	          // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	          //check if bready is asserted while bvalid is high) 
	          //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	 end   
	// Implement axi_arready generation

	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_arv_arr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          axi_arready <= 1'b1;
	          axi_arv_arr_flag <= 1'b1;
	        end
	      else if (axi_rvalid && S_AXI_RREADY && axi_arlen_cntr == axi_arlen)
	      // preparing to accept next address after current read completion
	        begin
	          axi_arv_arr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_araddr latching

	//This process is used to latch the address when both 
	//S_AXI_ARVALID and S_AXI_RVALID are valid. 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_araddr <= 0;
	      axi_arlen_cntr <= 0;
	      axi_arburst <= 0;
	      axi_arlen <= 0;
	      axi_rlast <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
	        begin
	          // address latching 
	          axi_araddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0]; 
	          axi_arburst <= S_AXI_ARBURST; 
	          axi_arlen <= S_AXI_ARLEN;     
	          // start address of transfer
	          axi_arlen_cntr <= 0;
	          axi_rlast <= 1'b0;
	        end   
	      else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)        
	        begin
	         
	          axi_arlen_cntr <= axi_arlen_cntr + 1;
	          axi_rlast <= 1'b0;
	        
	          case (axi_arburst)
	            2'b00: // fixed burst
	             // The read address for all the beats in the transaction are fixed
	              begin
	                axi_araddr       <= axi_araddr;        
	                //for arsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The read address for all the beats in the transaction are increments by awsize
	              begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The read address wraps when the address reaches wrap boundary 
	              if (ar_wrap_en) 
	                begin
	                  axi_araddr <= (axi_araddr - ar_wrap_size); 
	                end
	              else 
	                begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
	                //for arsize = 4 bytes (010)
	              end
	          endcase              
	        end
	      else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag )   
	        begin
	          axi_rlast <= 1'b1;
	        end          
	      else if (S_AXI_RREADY)   
	        begin
	          axi_rlast <= 1'b0;
	        end          
	    end 
	end       
	// Implement axi_arvalid generation

	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arv_arr_flag && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; 
	          // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end            
	    end
	end   
    
	// Add user logic here
    `define SHUFFLE
    
    // Interface signals
    wire                    pwen, pren;
    wire [13:0]             paddr;
    wire [31:0]             pwdata;
    
    assign pwen = axi_wready & S_AXI_WVALID;
    assign pren = axi_rvalid & S_AXI_RREADY;
    assign paddr = (axi_arv_arr_flag? axi_araddr[ADDR_LSB+13:ADDR_LSB]:(axi_awv_awr_flag? axi_awaddr[ADDR_LSB+13:ADDR_LSB]:0));
    assign pwdata = S_AXI_WDATA;
    
    // main logic
    localparam q = 3329;
    localparam addr_width = 5, depth = 32, data_width = 12;
    localparam  [3:0]
        IDLE      =      0,
        WRITE0    =      1,
        WRITE1    =      2,
        WRITE2    =      3,
        NTT0      =      4,
        PWM       =      5,
        INTT0     =      6,
        MACC      =      7,
        READ      =      8;

    reg  [31:0]               conf_reg;
    reg  [3:0]                CS, NS;
    reg  [2:0]                pm_sel;
    reg  [data_width*2-1:0]   pm_a0, pm_a1, pm_b0, pm_b1;
    reg                       pram0_wen, pram1_wen;
    reg  [data_width*2-1:0]   pram0_din0, pram0_din1, pram0_din2, pram0_din3;
    reg  [data_width*2-1:0]   pram1_din0, pram1_din1, pram1_din2, pram1_din3;
    reg  [6:0]                cf_oldaddr_0, cf_oldaddr_1, cf_oldaddr_2, cf_oldaddr_3;
    reg  [1:0]                wcnt;
    reg                       pvram_wen;
    reg  [8:0]                pvram_raddr, pvram_waddr;
    reg  [data_width-1:0]     pvram_din0, pvram_din1, pvram_din2, pvram_din3;
    reg  [2:0]                vec_index;
    reg                       mont_trans;
    reg                       wr0_next;
    reg                       pwm_next;
    
    wire                      poly_wen;
    wire [1:0]                pm_wen;
    wire                      pm_done;
    wire [6:0]                agen_oldaddr0, agen_oldaddr1, agen_oldaddr2, agen_oldaddr3;
    wire [6:0]                tf_address;
    wire [4:0]                new_address_0, new_address_1, new_address_2, new_address_3;
    wire [1:0]                bank_index_0, bank_index_1, bank_index_2, bank_index_3;
    wire [data_width*2-1:0]   pm_c0, pm_c1, pm_d0, pm_d1;
    wire [data_width*2-1:0]   pram0_dout0, pram0_dout1, pram0_dout2, pram0_dout3;
    wire [data_width*2-1:0]   pram1_dout0, pram1_dout1, pram1_dout2, pram1_dout3;
    wire [data_width-1:0]     pvram_dout0, pvram_dout1, pvram_dout2, pvram_dout3;
    wire [data_width-1:0]     data_in0, data_in1;
    wire [1:0]                ntt_l;

    assign poly_wen = pwen && (paddr != 14'h3fff);
    assign data_in0 = (pwdata[15])? pwdata[15:0] + q : pwdata[15:0];
    assign data_in1 = (pwdata[31])? pwdata[31:16] + q : pwdata[31:16];
    
    // write data to conf_reg
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            conf_reg    <=    0;
        end
        else begin
            if (pwen) begin
                if (paddr == 14'h3fff)
                    conf_reg    <=    pwdata;
                else
                    conf_reg    <=    0;
            end
            else begin
                conf_reg    <=    0;
            end
        end
    end
    
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) 
            CS      <=      IDLE;
        else
            CS      <=      NS;
    end
    
    always @(*) begin
        case (CS)
            IDLE: begin
                if (conf_reg[0])
                    NS      =      WRITE0;
                else if (conf_reg[3])
                    NS      =      WRITE1;
                else if (conf_reg[4])
                    NS      =      WRITE2;
                else if (conf_reg[5])
                    NS      =      READ;
                else
                    NS      =      IDLE;
                pm_sel         =      0;
                core_poly_irq  =      1'b0;
            end
            WRITE0: begin
                if (conf_reg[6])
                    NS      =      (wr0_next)? PWM : NTT0;
                else
                    NS      =      WRITE0;
                pm_sel         =      0;
                core_poly_irq  =      1'b0;
            end
            WRITE1: begin
                if (conf_reg[6])
                    NS      =      IDLE;
                else
                    NS      =      WRITE1;
                pm_sel         =      0;
                core_poly_irq  =      1'b0;
            end
            WRITE2: begin
                if (conf_reg[6])
                    NS      =      IDLE;
                else
                    NS      =      WRITE2;
                pm_sel         =      0;
                core_poly_irq  =      1'b0;
            end
            NTT0: begin
                if (pm_done)
                    NS      =      MACC;
                else
                    NS      =      NTT0;
                pm_sel         =      3'b001;
                core_poly_irq  =      1'b0;
            end
            PWM: begin
                if (pm_done)
                    NS      =      (pwm_next)? INTT0 : MACC;
                else
                    NS      =      PWM;   
                pm_sel         =      3'b010;
                core_poly_irq  =      1'b0;
            end
            INTT0: begin
                if (pm_done) 
                    NS            =      MACC;
                else 
                    NS            =      INTT0;
                pm_sel         =      3'b100;
                core_poly_irq  =      1'b0;
            end
            MACC: begin
                if (pm_done) begin
                    NS             =      IDLE;
                    core_poly_irq  =      1'b1;
                end
                else begin
                    NS             =      MACC;
                    core_poly_irq  =      1'b0;
                end
                pm_sel         =      { 2'b11, mont_trans };
            end
            READ: begin
                if (conf_reg[6])
                    NS      =      IDLE;
                else
                    NS      =      READ;
                pm_sel         =      0;
                core_poly_irq  =      1'b0;
            end
            default: begin
                NS             =      IDLE;
                pm_sel         =      0;
                core_poly_irq  =      1'b0;
            end
        endcase
    end
    
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            pram0_wen      <=    0;
            pram1_wen      <=    0;
            cf_oldaddr_0   <=    0;
            cf_oldaddr_1   <=    0;
            cf_oldaddr_2   <=    0;
            cf_oldaddr_3   <=    0;
            pram0_din0     <=    0;
            pram0_din1     <=    0;
            pram0_din2     <=    0;
            pram0_din3     <=    0;
            pram1_din0     <=    0;
            pram1_din1     <=    0;
            pram1_din2     <=    0;
            pram1_din3     <=    0;
            wcnt           <=    0;
            pm_a0          <=    0;
            pm_a1          <=    0;
            pm_b0          <=    0;
            pm_b1          <=    0;
            pvram_wen      <=    0;
            pvram_waddr    <=    0;
            pvram_din0     <=    0;
            pvram_din1     <=    0;
            pvram_din2     <=    0;
            pvram_din3     <=    0;
            vec_index      <=    0; 
            wr0_next       <=    0;
            mont_trans     <=    0;
            pwm_next       <=    0;
        end
        else begin
            case (CS)
                IDLE: begin
                    pram0_wen      <=    0;
                    pram1_wen      <=    0;
                    wcnt           <=    0;
                    pvram_wen      <=    0;
                    pvram_waddr    <=    0;
                    mont_trans     <=    0;
                    wr0_next       <=    conf_reg[1];
                    pwm_next       <=    conf_reg[2];
                end
                WRITE0: begin
                    pram0_din0   <=    pram1_din0;
                    pram0_din1   <=    pram1_din1;
                    pram0_din2   <=    pram1_din2;
                    pram0_din3   <=    pram1_din3;
                    pram0_wen    <=    pvram_waddr[0];
                    if (poly_wen) begin   
                        wcnt           <=    wcnt + 1;
                        if (wcnt == 0) begin
                            cf_oldaddr_0   <=    paddr;
                            pram1_din0     <=    { data_in0, data_in1 };
                            pvram_waddr[0] <=    0;
                        end
                        else if (wcnt == 1) begin
                            cf_oldaddr_1   <=    paddr;
                            pram1_din1     <=    { data_in0, data_in1 };
                        end
                        else if (wcnt == 2) begin
                            cf_oldaddr_2   <=    paddr;
                            pram1_din2     <=    { data_in0, data_in1 };
                        end
                        else begin
                            cf_oldaddr_3   <=    paddr;
                            pram1_din3     <=    { data_in0, data_in1 };
                            pvram_waddr[0] <=    1;
                        end
                    end
                    else begin
                        pvram_waddr[0] <=    0;
                    end
                end
                WRITE1: begin
                    pram1_din0   <=    pram0_din0;
                    pram1_din1   <=    pram0_din1;
                    pram1_din2   <=    pram0_din2;
                    pram1_din3   <=    pram0_din3;
                    pram1_wen    <=    pvram_waddr[0];
                    if (poly_wen) begin   
                        wcnt           <=    wcnt + 1;
                        if (wcnt == 0) begin
                            cf_oldaddr_0   <=    paddr;
                            pram0_din0     <=    { data_in0, data_in1 };
                            pvram_waddr[0] <=    0;
                        end
                        else if (wcnt == 1) begin
                            cf_oldaddr_1   <=    paddr;
                            pram0_din1     <=    { data_in0, data_in1 };
                        end
                        else if (wcnt == 2) begin
                            cf_oldaddr_2   <=    paddr;
                            pram0_din2     <=    { data_in0, data_in1 };
                        end
                        else begin
                            cf_oldaddr_3   <=    paddr;
                            pram0_din3     <=    { data_in0, data_in1 };
                            pvram_waddr[0] <=    1;
                        end
                    end
                    else begin
                        pvram_waddr[0] <=    0;
                    end
                    vec_index      <=    0;
                end
                WRITE2: begin
                    pvram_wen         <=    poly_wen;
                    pvram_waddr       <=    paddr[9:1];
                    if (paddr[0]) begin
                        pvram_din2        <=    data_in0;
                        pvram_din3        <=    data_in1;
                    end
                    else begin
                        pvram_din0        <=    data_in0;
                        pvram_din1        <=    data_in1;
                    end
                end 
                NTT0, INTT0: begin
                    pram1_wen      <=    0;
                    pram0_wen      <=    pm_wen[1];
                    cf_oldaddr_0   <=    agen_oldaddr0;
                    cf_oldaddr_1   <=    agen_oldaddr1;
                    cf_oldaddr_2   <=    agen_oldaddr2;
                    cf_oldaddr_3   <=    agen_oldaddr3;
                    pram0_din0     <=    pm_c0;
                    pram0_din1     <=    pm_c1;
                    pram0_din2     <=    pm_d0;
                    pram0_din3     <=    pm_d1;
                    pm_a0          <=    pram0_dout0;
                    pm_a1          <=    pram0_dout1;
                    pm_b0          <=    pram0_dout2;
                    pm_b1          <=    pram0_dout3;
                end
                PWM: begin
                    pram1_wen      <=    0;
                    pram0_wen      <=    pm_wen[0];
                    cf_oldaddr_0   <=    agen_oldaddr0;
                    cf_oldaddr_1   <=    agen_oldaddr1;
                    cf_oldaddr_2   <=    agen_oldaddr2;
                    cf_oldaddr_3   <=    agen_oldaddr3;
                    pram0_din0     <=    pm_c0;
                    pram0_din1     <=    pm_c1;
                    pram0_din2     <=    pm_d0;
                    pram0_din3     <=    pm_d1;
                    wcnt[1:0]      <=    wcnt[1:0] + 1;
                    case (wcnt[1:0])
                        2'b00: begin
                            pm_a0          <=    pram0_dout0;
                            pm_b0          <=    pram1_dout0;
                        end
                        2'b01: begin
                            pm_a0          <=    pram0_dout1;
                            pm_b0          <=    pram1_dout1;
                        end
                        2'b10: begin
                            pm_a0          <=    pram0_dout2;
                            pm_b0          <=    pram1_dout2;
                        end
                        2'b11: begin
                            pm_a0          <=    pram0_dout3;
                            pm_b0          <=    pram1_dout3;
                        end
                    endcase
                    pm_a1          <=    0;
                    pm_b1          <=    0;
                    mont_trans     <=    1'b1;
                end
                MACC: begin
                    pram1_wen      <=    0;
                    pram0_wen      <=    0;
                    cf_oldaddr_0   <=    agen_oldaddr0;
                    cf_oldaddr_1   <=    agen_oldaddr1;
                    cf_oldaddr_2   <=    agen_oldaddr2;
                    cf_oldaddr_3   <=    agen_oldaddr3;
                    wcnt[0]        <=    ~wcnt[0];
                    pm_a0          <=    (wcnt[0])? pram0_dout2 : pram0_dout0;
                    pm_a1          <=    (wcnt[0])? pram0_dout3 : pram0_dout1;
                    pm_b0          <=    { pvram_dout0, pvram_dout1 };
                    pm_b1          <=    { pvram_dout2, pvram_dout3 };
                    pram1_din0     <=    tf_address;
                    pram1_din1     <=    pram1_din0;    
                    pram1_din2     <=    pram1_din1;
                    pram1_din3     <=    pram1_din2;
                    pram0_din0     <=    pram1_din3;
                    pvram_wen      <=    pm_wen[1];
                    pvram_waddr    <=    { vec_index, pram0_din0[5:0] };
                    pvram_din0     <=    pm_d1[data_width*2-1:data_width];
                    pvram_din1     <=    pm_d1[data_width-1:0];
                    pvram_din2     <=    pm_d0[data_width*2-1:data_width];
                    pvram_din3     <=    pm_d0[data_width-1:0];
                    vec_index      <=    vec_index + pm_done;
                end
                READ: begin
                    pvram_wen         <=    (paddr[0] == 1'b1)? pren : 0;
                    pvram_waddr       <=    pvram_raddr;
                    pvram_din0        <=    0;
                    pvram_din1        <=    0;
                    pvram_din2        <=    0;
                    pvram_din3        <=    0;
                    vec_index         <=    0;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (CS)
            MACC: begin
                pvram_raddr     =    { vec_index, tf_address[5:0] };
                axi_rdata       =    0;
            end
            READ: begin
                pvram_raddr     =    paddr[9:1];
                axi_rdata       =    (paddr[0] == 0)? { pvram_dout1, 4'h0, pvram_dout0 } : { pvram_dout3, 4'h0, pvram_dout2 };
            end
            default: begin
                pvram_raddr     =    0;
                axi_rdata       =    0;
            end
        endcase
    end
    
`ifdef SHUFFLE
    address_generator_shuffling address_generator_0(
        .clk(S_AXI_ACLK), .rstn(S_AXI_ARESETN), .sel(pm_sel), 
        .old_address_0(agen_oldaddr0), .old_address_1(agen_oldaddr1),
        .old_address_2(agen_oldaddr2), .old_address_3(agen_oldaddr3),
        .tf_address(tf_address), .ntt_l(ntt_l),
        .wen(pm_wen), .done_flag(pm_done)
    );
`else
    address_generator_inplace address_generator_0(
        .clk(S_AXI_ACLK), .rstn(S_AXI_ARESETN), .sel(pm_sel), 
        .old_address_0(agen_oldaddr0), .old_address_1(agen_oldaddr1),
        .old_address_2(agen_oldaddr2), .old_address_3(agen_oldaddr3),
        .tf_address(tf_address), .ntt_l(ntt_l),
        .wen(pm_wen), .done_flag(pm_done)
    );
`endif
    
    conflict_free_memory_map cf_mmap_0(
        .clk(S_AXI_ACLK), .rst(S_AXI_ARESETN),
        .old_address_0(cf_oldaddr_0), .old_address_1(cf_oldaddr_1),
        .old_address_2(cf_oldaddr_2), .old_address_3(cf_oldaddr_3),
        .new_address_0(new_address_0), .new_address_1(new_address_1),
        .new_address_2(new_address_2), .new_address_3(new_address_3),
        .bank_number_0(bank_index_0), .bank_number_1(bank_index_1),
        .bank_number_2(bank_index_2), .bank_number_3(bank_index_3)
    );
    
    poly_ram #(.addr_width(addr_width), .depth(depth), .data_width(data_width*2)) poly_ram_0(
        .clk(S_AXI_ACLK), .rst(S_AXI_ARESETN), .sel(pm_sel), .wen(pram0_wen),
        .bank0_index(bank_index_0), .bank1_index(bank_index_1), .bank2_index(bank_index_2), .bank3_index(bank_index_3),
        .addr0(new_address_0), .addr1(new_address_1), .addr2(new_address_2), .addr3(new_address_3),
        .din0(pram0_din0), .din1(pram0_din1), .din2(pram0_din2), .din3(pram0_din3),
        .dout0(pram0_dout0), .dout1(pram0_dout1), .dout2(pram0_dout2), .dout3(pram0_dout3)
    );
    
    poly_ram #(.addr_width(addr_width), .depth(depth), .data_width(data_width*2)) poly_ram_1(
        .clk(S_AXI_ACLK), .rst(S_AXI_ARESETN), .sel(pm_sel), .wen(pram1_wen),
        .bank0_index(bank_index_0), .bank1_index(bank_index_1), .bank2_index(bank_index_2), .bank3_index(bank_index_3),
        .addr0(new_address_0), .addr1(new_address_1), .addr2(new_address_2), .addr3(new_address_3),
        .din0(pram1_din0), .din1(pram1_din1), .din2(pram1_din2), .din3(pram1_din3),
        .dout0(pram1_dout0), .dout1(pram1_dout1), .dout2(pram1_dout2), .dout3(pram1_dout3)
    );
    
    poly_mul #(.data_width(data_width)) poly_mul_0(
        .clk(S_AXI_ACLK), .rst(S_AXI_ARESETN), .sel(pm_sel), 
        .tf_address(tf_address), .ntt_l(ntt_l),
        .a0(pm_a0), .a1(pm_a1), .b0(pm_b0), .b1(pm_b1), 
        .c0(pm_c0), .c1(pm_c1), .d0(pm_d0), .d1(pm_d1)
    );
    
    polyvec_ram #(.addr_width(addr_width+3), .depth(depth*8), .data_width(data_width)) polyvec_ram_0(
        .clk(S_AXI_ACLK), .wen(pvram_wen), .raddr(pvram_raddr), .waddr(pvram_waddr),
        .din0(pvram_din0), .din1(pvram_din1), .din2(pvram_din2), .din3(pvram_din3),
        .dout0(pvram_dout0), .dout1(pvram_dout1), .dout2(pvram_dout2), .dout3(pvram_dout3)
    );       
    
	// User logic ends
    
endmodule