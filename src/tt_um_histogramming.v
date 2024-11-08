module tt_um_histogramming (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,      // will always be 1
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    
    // UI_IN    7   write_en
    // UI_IN    6:0 data_in[14:8]
    // UIO_IN   7:0 data_in[7:0]
    
    wire [15:0] data_in;
    wire valid_out, last_bin, ready;
    
    // Map the 16-bit data_in across ui_in and uio_in (removed the extra 1'b0)
    assign data_in = {ui_in[6:0], uio_in};  // Removed the 1'b0
    
    // Connect valid_out and last_bin to uio_out
    assign uio_out = {6'b0, last_bin, valid_out};
    assign uio_oe = 8'b11;  // Set output enable for the two status bits
    
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in(data_in),
        .write_en(ui_in[7]),
        .data_out(uo_out),
        .valid_out(valid_out),
        .last_bin(last_bin),
        .ready(ready)
    );
    
    // List all unused inputs to prevent warnings
    wire unused_ok = &{ena, ready, 1'b0};
endmodule