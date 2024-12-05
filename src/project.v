`default_nettype none

module sap_1( input clk,  input rst, output [7:0] bus_out);
  reg[7:0] bus_reg;
  reg[3:0] pc;
  reg pc_inc, pc_rden, mar_load, mem_rden, ir_load, ir_rden,
        reg_a_load, reg_a_rden, reg_b_load, adder_sub, adder_rden  ;
  reg[7:0] reg_a; reg[7:0] reg_b;
  reg[7:0] ir;
  wire[7:0] adder_out;
  reg [2:0]  present_state; wire [3:0] opcode ;

  assign adder_out = (adder_sub) ? reg_a-reg_b : reg_a+reg_b;

  wire[7:0] mem_out; reg[3:0] mar; reg[7:0] mem[0:15];
  always @(posedge clk) begin
    if (rst) begin bus_reg <= 8'b0;
    end else begin 
      if (ir_rden) begin bus_reg <= ir;
      end else if (pc_rden) begin bus_reg <= pc;
      end else if (mem_rden) begin bus_reg <= mem_out;
      end else if (adder_rden) begin bus_reg <= adder_out;
      end else if (reg_a_rden) begin bus_reg <= reg_a;
      end else begin bus_reg <= 8'b0;
      end
    end
  end
    
  always @(posedge clk) begin
    if (rst) begin pc <= 4'b0;
    end else if (pc_inc) begin pc <= pc + 1; end
  end

  always @(posedge clk) begin
    if (rst) begin mar <= 4'b0;
    end else if (mar_load) begin mar <= bus_reg[3:0];
    end
  end
  assign mem_out = mem[mar];

  always @(posedge clk) begin
    if (rst) begin reg_a <= 8'b0;
    end else if (reg_a_load) begin reg_a <= bus_reg;
    end
  end

  always @(posedge clk) begin
    if (rst) begin reg_b <= 8'b0;
    end else if (reg_b_load) begin reg_b <= bus_reg;
    end
  end

  always @(posedge clk) begin
    if (rst) begin ir <= 8'b0;
    end else if (ir_load) begin ir <= bus_reg;
    end
  end

  assign opcode = ir[7:4] ;
  always @(posedge clk) begin
    if (rst) begin present_state <= 0;
    end else begin
      if (present_state == 5) begin present_state <= 0;
      end else begin present_state <= present_state + 1;
      end
      {pc_inc, pc_rden, mar_load, mem_rden, ir_load, ir_rden,
       reg_a_load, reg_a_rden, reg_b_load, adder_sub, adder_rden } <= 0 ;
      case (present_state)
        0: begin pc_rden <= 1; mar_load <= 1 ; end
        1: begin pc_inc <= 1 ; end
        2: begin mem_rden <= 1 ; ir_load <= 1 ; end 
        3: begin
              case (opcode)
                4'd0: begin ir_rden <= 1 ; mar_load <= 1 ; end 
                4'd1: begin ir_rden <= 1 ; mar_load <= 1 ; end 
                4'd2: begin ir_rden <= 1 ; mar_load <= 1 ; end 
              endcase
            end
        4: begin
              case (opcode)
                4'd0: begin mem_rden <= 1 ; reg_a_load <= 1 ; end 
                4'd1: begin mem_rden <= 1 ; reg_b_load <= 1 ; end 
                4'd2: begin mem_rden <= 1 ; reg_b_load <= 1 ; end 
              endcase
            end
        5: begin
              case (opcode)
                4'd1: begin adder_rden <= 1; reg_a_load <= 1 ; end
                4'd2: begin adder_sub <= 1 ; 
                              adder_rden <= 1; reg_a_load <= 1 ; end
              endcase
            end
          endcase
        end
    end
    assign bus_out = bus_reg;
endmodule

module tt_um_patsacbghub_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out  = ui_in * ui_in;  // Example: ou_out is the sum of ui_in and uio_in
    
  // assign uio_out = 0;
  // assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0, ui_in, uio_in};
  assign uio_out = 0 ; assign uio_oe = 0 ;

  sap_1 cpu_inst0 ( clk,  ~ rst_n, uo_out );

endmodule

module tt_um_patsacbghub_example_orig (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out  = ui_in * ui_in;  // Example: ou_out is the sum of ui_in and uio_in
    
  // assign uio_out = 0;
  // assign uio_oe  = 0;

  reg [31:0] scan_in_reg ;
  always @( posedge clk ) begin
    scan_in_reg <= {scan_in_reg[30:0], ui_in[7] } ;
  end
  
    localparam W=4, K=5 ;

    reg [ (W-1):0 ] mem [0:(2<<K)-1] ;
    wire [K-1 : 0] addr ; wire [W-1 : 0] wr_data ; wire [W-1 : 0] rd_data ;
    wire wr_en ;
    assign wr_en = scan_in_reg[0] ;
    assign addr = scan_in_reg[(K-1)+1:1] ;
    assign wr_data = scan_in_reg[(W-1+(K+1)):(K+1)] ;
    always @( posedge clk ) begin
      if ( wr_en ) mem[ addr ] <= wr_data ;
    end
    assign uo_out = {mem[ addr ][8-W-1:0], mem[ addr ][W-1:0]} ;
    
  // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, 1'b0, uio_in};
  assign uio_out = 0 ; assign uio_oe = 0 ;

endmodule

