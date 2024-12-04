/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module sap_1( input clk,  input rst, output [7:0] bus_out);
  reg[7:0] bus_reg;
  reg[3:0] pc;
  always @(posedge clk) begin
    if (rst) begin bus_reg <= 8'b0;
    end else begin 
      if (ir_rden) begin bus_reg = ir;
      end else if (adder_rden) begin bus_reg = adder_out;
      end else if (reg_a_rden) begin bus_reg = reg_a;
      end else if (mem_rden) begin bus_reg = mem_out;
      end else if (pc_rden) begin bus_reg = pc;
      end else begin bus_reg = 8'b0;
      end
    end
  end
    
  wire hlt; 
  wire pc_inc; wire pc_rden; 
  always @(posedge clk) begin
    if (rst) begin pc <= 4'b0;
    end else if (pc_inc) begin pc <= pc + 1; end
  end

  wire mar_load; wire mem_rden; wire[7:0] mem_out;
  reg[3:0] mar; reg[7:0] rom[0:15];
  initial begin
    rom[0] = 8'h0D; rom[1] = 8'h1E; rom[2] = 8'h2F; rom[3] = 8'hF0;
    rom[4] = 8'h00; rom[5] = 8'h00; rom[6] = 8'h00; rom[7] = 8'h00;
    rom[8] = 8'h00; rom[9] = 8'h00; rom[10] = 8'h00; rom[11] = 8'h00;
    rom[12] = 8'h00; rom[13] = 8'h03; rom[14] = 8'h04; rom[15] = 8'h02;
  end
    
  always @(posedge clk) begin
    if (rst) begin mar <= 4'b0;
    end else if (mar_load) begin mar <= bus_reg[3:0];
    end
  end
  assign mem_out = rom[mar];

  wire reg_a_load; wire reg_a_rden; reg[7:0] reg_a;
  always @(posedge clk) begin
    if (rst) begin reg_a <= 8'b0;
    end else if (reg_a_load) begin reg_a <= bus_reg;
    end
  end

  wire reg_b_load; reg[7:0] reg_b;
  always @(posedge clk) begin
    if (rst) begin reg_b <= 8'b0;
    end else if (reg_b_load) begin reg_b <= bus_reg;
    end
  end

  wire adder_sub; wire adder_rden; wire[7:0] adder_out;
  assign adder_out = (adder_sub) ? reg_a-reg_b : reg_a+reg_b;

  wire ir_load; wire ir_rden; reg[7:0] ir;
  always @(posedge clk) begin
    if (rst) begin ir <= 8'b0;
    end else if (ir_load) begin ir <= bus_reg;
    end
  end

  localparam SIG_ADDER_EN  = 0; localparam SIG_ADDER_SUB = 1;
  localparam SIG_B_LOAD    = 2; localparam SIG_A_EN      = 3;
  localparam SIG_A_LOAD    = 4; localparam SIG_IR_EN     = 5;
  localparam SIG_IR_LOAD   = 6; localparam SIG_MEM_EN    = 7;
  localparam SIG_MEM_LOAD  = 8; localparam SIG_PC_EN     = 9;
  localparam SIG_PC_INC    = 10; localparam SIG_HLT       = 11;
    
  localparam OP_LDA = 4'b0000; localparam OP_ADD = 4'b0001;
  localparam OP_SUB = 4'b0010; localparam OP_HLT = 4'b1111;
   
  reg [2:0]  stage; reg [11:0] control_word;
  wire [3:0] opcode ;
  assign opcode = ir[7:4] ;
  always @(posedge clk) begin
    if (rst) begin stage <= 0;
    end else begin
      if (stage == 5) begin stage <= 0;
      end else begin stage <= stage + 1;
      end
      control_word <= 12'b0;
      case (stage)
        0: begin
              control_word[SIG_PC_EN] <= 1;
              control_word[SIG_MEM_LOAD] <= 1;
            end
        1: begin
              control_word[SIG_PC_INC] <= 1;
            end
        2: begin
              control_word[SIG_MEM_EN] <= 1;
              control_word[SIG_IR_LOAD] <= 1;
            end
        3: begin
              case (opcode)
                OP_LDA: begin
                  control_word[SIG_IR_EN] <= 1;
                  control_word[SIG_MEM_LOAD] <= 1;
                end
                OP_ADD: begin
                  control_word[SIG_IR_EN] <= 1;
                  control_word[SIG_MEM_LOAD] <= 1;
                end
                OP_SUB: begin
                  control_word[SIG_IR_EN] <= 1;
                  control_word[SIG_MEM_LOAD] <= 1;
                end
                OP_HLT: begin
                  control_word[SIG_HLT] <= 1;
                end
              endcase
            end
        4: begin
              case (opcode)
                OP_LDA: begin
                  control_word[SIG_MEM_EN] <= 1;
                  control_word[SIG_A_LOAD] <= 1;
                end
                OP_ADD: begin
                  control_word[SIG_MEM_EN] <= 1;
                  control_word[SIG_B_LOAD] <= 1;
                end
                OP_SUB: begin
                  control_word[SIG_MEM_EN] <= 1;
                  control_word[SIG_B_LOAD] <= 1;
                end
              endcase
            end
        5: begin
              case (opcode)
                OP_ADD: begin
                  control_word[SIG_ADDER_EN] <= 1;
                  control_word[SIG_A_LOAD] <= 1;
                end
                OP_SUB: begin
                  control_word[SIG_ADDER_SUB] <= 1;
                  control_word[SIG_ADDER_EN] <= 1;
                  control_word[SIG_A_LOAD] <= 1;
                end
              endcase
            end
          endcase
        end
    end
    assign { hlt, pc_inc, pc_rden, mar_load, mem_rden, ir_load, ir_rden,
        reg_a_load, reg_a_rden, reg_b_load, adder_sub, adder_rden } = control_word ;
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

