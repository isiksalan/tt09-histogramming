
`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

   reg [7:0]	      counter;

   always @(posedge clk or negedge rst_n)
     if (rst_n == 1'b0)
       counter <= 8'b0;
     else
       counter <= counter + 8'b1;

   assign uo_out   = counter;
   assign uio_oe   = 8'b0;
   assign uio_out  = 8'b0;
   
  wire _unused = &{ena, ui_in, uio_in, uio_out, 1'b0};

endmodule
