/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

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
  
    localparam W=6, K=6 ;

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
