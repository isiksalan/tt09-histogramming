module tt_um_led_cipher (
						  input wire [7:0] 	ui_in,   // Dedicated inputs
						  output wire [7:0] uo_out,  // Dedicated outputs
						  input wire [7:0] 	uio_in,  // IOs: Input path
						  output wire [7:0] uio_out, // IOs: Output path
						  output wire [7:0] uio_oe,  // IOs: Enable path (active high: 0=input, 1=output)
						  input wire 		ena,     // always 1 when the design is powered, so you can ignore it
						  input wire 		clk,     // clock
						  input wire 		rst_n    // reset_n - low to reset
						  );
   
   // UI_IN    7   _unused
   // UI_IN    6   _unused
   // UI_IN    5   start
   // UI_IN    4   getct
   // UI_IN    3   loadkey
   // UI_IN    2   loadpt
   // UI_IN    1   keyi
   // UI_IN    0   datai
   //
   // UO_OUT   7-2 _unused
   // UO_OUT   1   done
   // UO_OUT   0   dataq
   //
   // UIO_OE   7-0  _unused
   // UIO_OUT  7-0  _unused

   led_serial bitserial_cipher(.clk(clk),
                               .reset(rst_n),
                               .datai(ui_in[0]),
                               .keyi(ui_in[1]),
                               .loadpt(ui_in[2]),
                               .loadkey(ui_in[3]),
                               .getct(ui_in[4]),
                               .start(ui_in[5]),
                               .dataq(uo_out[0]),
                               .done(uo_out[1])
                               );
   assign uo_out[7:2] = 6'b0;
   assign uio_out = 7'b0;
   assign uio_oe  = 7'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:6], uio_in[7:0], 1'b0};

endmodule
