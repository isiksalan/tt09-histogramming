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
    
    wire valid_out, last_bin, ready;
    
    // Construct data_in with proper bit alignment
    // We need all 16 bits because bin 15 needs to be accessible
    wire [15:0] data_in;
    assign data_in = {1'b0, ui_in[6:0], uio_in};  // Ensure proper alignment for bin indexing
    
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in(data_in),      // Full 16-bit input
        .write_en(ui_in[7]),    // Write enable from MSB
        .data_out(uo_out),      // Direct 8-bit output
        .valid_out(valid_out),  // Status signals
        .last_bin(last_bin),
        .ready(ready)
    );
    
    // Connect status signals to lower bits of uio_out
    assign uio_out = {6'b0, last_bin, valid_out};
    
    // Enable output for status bits only
    assign uio_oe = 8'b11;
    
    wire unused = &{ena, ready};

endmodule