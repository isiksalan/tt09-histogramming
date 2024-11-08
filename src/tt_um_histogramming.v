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
    
    wire [15:0] data_in;
    wire valid_out, last_bin, ready;
    
    // Map the 15-bit data_in across ui_in and uio_in
    // Keep alignment precise for bin indexing
    assign data_in = {ui_in[6:0], uio_in};
    
    // Instantiate the histogramming module
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in(data_in),
        .write_en(ui_in[7]),    // Use MSB as write enable
        .data_out(uo_out),      // Output data directly
        .valid_out(valid_out),  // Connect to status signals
        .last_bin(last_bin),
        .ready(ready)
    );
    
    // Map status signals to uio_out[1:0]
    // valid_out -> uio_out[0]
    // last_bin -> uio_out[1]
    assign uio_out = {6'b0, last_bin, valid_out};
    
    // Enable output for status bits only
    assign uio_oe = 8'b00000011;
    
    // Handle unused input
    wire unused_ok = &{ena, ready, 1'b0};

endmodule