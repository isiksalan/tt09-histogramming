module tt_um_histogramming (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will always be 1
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    
    // UI_IN    7   write_en
    // UI_IN    6:0 data_in[14:8]
    // UIO_IN   7:0 data_in[7:0]
    
    // Create internal signals
    wire [15:0] data_in;
    
    // Map the 16-bit data_in across ui_in and uio_in
    assign data_in = {ui_in[6:0], uio_in[7:0], 1'b0};
    
    // Instantiate the histogramming module
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in(data_in),
        .write_en(ui_in[7]),
        .data_out(uo_out),
        .valid_out(),  // Leave unconnected since not critical
        .last_bin(),   // Leave unconnected since not critical
        .ready()       // Leave unconnected since not critical
    );
    
    // All UIO pins as inputs like professor's design
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;
    
    // List all unused inputs to prevent warnings
    wire _unused_ok = &{ena, 1'b0};

endmodule