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
    
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in({ui_in[6:0], uio_in}),
        .write_en(ui_in[7]),
        .data_out(uo_out),
        .valid_out(valid_out),
        .last_bin(last_bin),
        .ready(ready)
    );
    
    assign uio_out = {6'b0, last_bin, valid_out};
    assign uio_oe = 8'b11;
    wire unused = ena | ready;

endmodule