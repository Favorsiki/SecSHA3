`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/19 10:19:37
// Design Name: 
// Module Name: hash_AXIS_v1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

	module demo_hash_interface #
	(
		// Users to add parameters here
    
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32,

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
        output wire h_wen, 
        output wire h_dout_req,
        output wire [31:0] h_din,
        input  wire [31:0] h_dout,
        input  wire h_valid, 
        input  wire h_done, 
        input  wire h_squeeze_start, 
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);
    wire s00_axis_wen, m00_axis_squeeze_start, m00_axis_doutreq;
    wire [31:0] s00_axis_din, m00_axis_dout;
// Instantiation of Axi Bus Interface S00_AXIS
	HASH_S_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
	) hash_AXIS_v1_0_S00_AXIS_inst (
        .o_axis_wen(s00_axis_wen),
        .o_axis_data(s00_axis_din),
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	HASH_M_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
	) hash_AXIS_v1_0_M00_AXIS_inst (
        .i_axis_squeeze_start(m00_axis_squeeze_start),
        .i_axis_data(m00_axis_dout),
		.o_axis_doutreq(m00_axis_doutreq),
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready)
	);

	// Add user logic here
    assign h_wen = s00_axis_wen;
	assign h_dout_req = m00_axis_doutreq;
    assign h_din = s00_axis_din;
    assign m00_axis_squeeze_start = h_squeeze_start;
    assign m00_axis_dout = h_dout;
	// User logic ends

	endmodule

`timescale 1 ns / 1 ps

	module HASH_S_AXIS  #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line

        // AXI4Stream sink: Data Width
        parameter integer C_S_AXIS_TDATA_WIDTH    = 32
    )
    (
        // Users to add ports here
        output wire o_axis_wen,
        output wire [31:0] o_axis_data,
        // User ports ends
        // Do not modify the ports beyond this line

        // AXI4Stream sink: Clock
        input wire  S_AXIS_ACLK,
        // AXI4Stream sink: Reset
        input wire  S_AXIS_ARESETN,
        // Ready to accept data in
        output wire  S_AXIS_TREADY,
        // Data in
        input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
        // Byte qualifier
        input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
        // Indicates boundary of last packet
        input wire  S_AXIS_TLAST,
        // Data is in valid
        input wire  S_AXIS_TVALID
    );
    // function called clogb2 that returns an integer which has the 
    // value of the ceiling of the log base 2.
    function integer clogb2 (input integer bit_depth);
      begin
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
          bit_depth = bit_depth >> 1;
      end
    endfunction

    // Total number of input data.
    localparam NUMBER_OF_INPUT_WORDS  = 256;        // 1024B
    // bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
    localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1); // clog(127)=7
    // Define the states of state machine
    // The control state machine oversees the writing of input streaming data to the FIFO,
    // and outputs the streaming data from the FIFO
    parameter [1:0] IDLE = 1'b0,        // This is the initial/idle state 

                    WRITE_FIFO  = 1'b1; // In this state FIFO is written with the
                                        // input stream data S_AXIS_TDATA 
    wire      axis_tready;
    // State variable
    reg mst_exec_state;  
    // FIFO implementation signals
    genvar byte_index;     
    // FIFO write enable
    wire fifo_wren;
    // FIFO full flag
    //reg fifo_full_flag;
    // FIFO write pointer
    reg [bit_num-1:0] write_pointer;
    // sink has accepted all the streaming data and stored in FIFO
      reg writes_done;
    // I/O Connections assignments

    assign S_AXIS_TREADY    = axis_tready;
    // Control state machine implementation
    always @(posedge S_AXIS_ACLK) 
    begin  
      if (!S_AXIS_ARESETN) 
      // Synchronous reset (active low)
        begin
          mst_exec_state <= IDLE;
        end  
      else
        case (mst_exec_state)
          IDLE: 
            // The sink starts accepting tdata when 
            // there tvalid is asserted to mark the
            // presence of valid streaming data 
              if (S_AXIS_TVALID)
                begin
                  mst_exec_state <= WRITE_FIFO;
                end
              else
                begin
                  mst_exec_state <= IDLE;
                end
          WRITE_FIFO: 
            // When the sink has accepted all the streaming input data,
            // the interface swiches functionality to a streaming master
            if (writes_done)
              begin
                mst_exec_state <= IDLE;
              end
            else
              begin
                // The sink accepts and stores tdata 
                // into FIFO
                mst_exec_state <= WRITE_FIFO;
              end

        endcase
    end
    // AXI Streaming Sink 
    // 
    // The example design sink is always ready to accept the S_AXIS_TDATA  until
    // the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
    assign axis_tready = ((mst_exec_state == WRITE_FIFO) && (write_pointer <= NUMBER_OF_INPUT_WORDS-1));

    always@(posedge S_AXIS_ACLK) begin
        if(!S_AXIS_ARESETN) begin
            write_pointer <= 0;
            writes_done <= 1'b0;
        end else if (mst_exec_state == WRITE_FIFO) begin
            if (write_pointer <= NUMBER_OF_INPUT_WORDS-1) begin
                if (fifo_wren) begin
                    // write pointer is incremented after every write to the FIFO
                    // when FIFO write signal is enabled.
                    write_pointer <= write_pointer + 1;
                    writes_done <= 1'b0;
                end
                if ((write_pointer == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST) begin
                    // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
                    // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
                    writes_done <= 1'b1;
                end
            end  
        end else begin
            write_pointer <= 0;
            writes_done <= 1'b0;
        end  
    end

    // FIFO write enable generation
    assign fifo_wren = S_AXIS_TVALID && axis_tready;
    assign o_axis_wen  = fifo_wren;
    assign o_axis_data = S_AXIS_TDATA;

    endmodule


	module HASH_M_AXIS #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line

        // Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
        parameter integer C_M_AXIS_TDATA_WIDTH    = 32,
        // Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
        parameter integer C_M_START_COUNT    = 32
    )
    (
        // Users to add ports here
        input wire i_axis_squeeze_start,
        input wire [31:0] i_axis_data,
        output wire o_axis_doutreq,
        // User ports ends
        // Do not modify the ports beyond this line

        // Global ports
        input wire  M_AXIS_ACLK,
        // 
        input wire  M_AXIS_ARESETN,
        // Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
        output wire  M_AXIS_TVALID,
        // TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
        output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
        // TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
        output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
        // TLAST indicates the boundary of a packet.
        output wire  M_AXIS_TLAST,
        // TREADY indicates that the slave can accept a transfer in the current cycle.
        input wire  M_AXIS_TREADY
    );
    // Total number of output data                                                 
    localparam NUMBER_OF_OUTPUT_WORDS = 100; // 400B                                                   
                                                                                         
    // function called clogb2 that returns an integer which has the                      
    // value of the ceiling of the log base 2.                                           
    function integer clogb2 (input integer bit_depth);                                   
      begin                                                                              
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
          bit_depth = bit_depth >> 1;                                                    
      end                                                                                
    endfunction                                                                          
                                                                                         
    // WAIT_COUNT_BITS is the width of the wait counter.                                 
    localparam integer WAIT_COUNT_BITS = clogb2(C_M_START_COUNT-1); // log(31)=5                  
                                                                                         
    // bit_num gives the minimum number of bits needed to address 'depth' size of FIFO.  
    localparam bit_num  = clogb2(NUMBER_OF_OUTPUT_WORDS);           // log(100)=7                    
                                                                                         
    // Define the states of state machine                                                
    // The control state machine oversees the writing of input streaming data to the FIFO,
    // and outputs the streaming data from the FIFO                                      
    parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state               
                                                                                         
                    INIT_COUNTER  = 2'b01, // This state initializes the counter, once   
                                    // the counter reaches C_M_START_COUNT count,        
                                    // the state machine changes state to SEND_STREAM     
                    SEND_STREAM   = 2'b10; // In this state the                          
                                         // stream data is output through M_AXIS_TDATA   
    // State variable                                                                    
    reg [1:0] mst_exec_state;                                                            
    // Example design FIFO read pointer                                                  
    reg [bit_num-1:0] read_pointer;                                                      

    // AXI Stream internal signals
    //wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
    reg [WAIT_COUNT_BITS-1 : 0]     count;
    //streaming data valid
    wire      axis_tmp;
    //streaming data valid delayed by one clock cycle
    reg      axis_tvalid;
    //Last of the streaming data 
    //wire      axis_tlast_tttttttt;
    //Last of the streaming data delayed by one clock cycle
    reg      axis_tlast;
    //FIFO implementation signals
    //reg [C_M_AXIS_TDATA_WIDTH-1 : 0]     stream_data_out;
    wire      tx_en;
    //The master has issued all the streaming data stored in FIFO
    reg      tx_done;


    // I/O Connections assignments

    assign M_AXIS_TVALID   = axis_tvalid;
    assign M_AXIS_TDATA    = i_axis_data;
    assign M_AXIS_TLAST    = axis_tlast;
    assign M_AXIS_TSTRB    = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};


    // Control state machine implementation                             
    always @(posedge M_AXIS_ACLK)                                             
    begin                                                                     
      if (!M_AXIS_ARESETN)                                                    
      // Synchronous reset (active low)                                       
        begin                                                                 
          mst_exec_state <= IDLE;                                             
          count    <= 0;                                                      
        end                                                                   
      else                                                                    
        case (mst_exec_state)                                                 
          IDLE:                                                               
            // The slave starts accepting tdata when                          
            // there tvalid is asserted to mark the                           
            // presence of valid streaming data                               
            //if ( count == 0 )                                                 
            //  begin                                                           
                mst_exec_state  <= INIT_COUNTER;                              
            //  end                                                             
            //else                                                              
            //  begin                                                           
            //    mst_exec_state  <= IDLE;                                      
            //  end                                                             
                                                                              
          INIT_COUNTER:                                                       
            // The slave starts accepting tdata when                          
            // there tvalid is asserted to mark the                           
            // presence of valid streaming data                               
            if ( count == C_M_START_COUNT - 1 )                               
              begin                                                           
                mst_exec_state  <= SEND_STREAM;                               
              end                                                             
            else                                                              
              begin                                                           
                count <= count + 1;                                           
                mst_exec_state  <= INIT_COUNTER;                              
              end                                                             
                                                                              
          SEND_STREAM:                                                        
            // The example design streaming master functionality starts       
            // when the master drives output tdata from the FIFO and the slave
            // has finished storing the S_AXIS_TDATA                          
            if (tx_done)                                                      
              begin                                                           
                mst_exec_state <= IDLE;                                       
              end                                                             
            else                                                              
              begin                                                           
                mst_exec_state <= SEND_STREAM;                                
              end                                                             
        endcase                                                               
    end                                                                       


    //tvalid generation
    //axis_tmp is asserted when the control state machine's state is SEND_STREAM and
    //number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
    assign axis_tmp = ((mst_exec_state == SEND_STREAM) && (read_pointer < NUMBER_OF_OUTPUT_WORDS) && i_axis_squeeze_start);
    always @(*) begin
        axis_tlast = (read_pointer == NUMBER_OF_OUTPUT_WORDS) && M_AXIS_TREADY; 
    end                                
    always @(posedge M_AXIS_ACLK) case (mst_exec_state) 
        SEND_STREAM : begin
            if (read_pointer < NUMBER_OF_OUTPUT_WORDS) begin
                axis_tvalid <= i_axis_squeeze_start;
            end else begin
                if (M_AXIS_TREADY) axis_tvalid <= 0;
            end 
        end 
        default : axis_tvalid <= 0;
    endcase                                                                                              


    //read_pointer pointer

    always@(posedge M_AXIS_ACLK) begin                                                                            
        if(!M_AXIS_ARESETN) begin                                                                        
            read_pointer <= 1;                                                         
            tx_done <= 1'b0;                                                           
        end else if (mst_exec_state == SEND_STREAM) begin  
            if (axis_tlast) begin                                                                      
                // tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
                // has been out.                                                         
                tx_done <= 1'b1;                                                         
            end else begin                                                                      
                if (tx_en)                                                               
                // read pointer is incremented after every read from the FIFO          
                // when FIFO read signal is enabled.                                   
                begin                                                                  
                    read_pointer <= read_pointer + 1;                                    
                    tx_done <= 1'b0;                                                     
                end                                                                    
            end 
        end else begin
          read_pointer <= 1;
          tx_done <= 0;
		    end                                                                  
    end                                                                              


    //FIFO read enable generation 

    assign tx_en = M_AXIS_TREADY && M_AXIS_TVALID;                                      

    // Add user logic here
    assign o_axis_doutreq = tx_en;
    // User logic ends

    endmodule
