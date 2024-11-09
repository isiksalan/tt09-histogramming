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
    
    // Properly map 16-bit data_in from ui_in and uio_in
    // For bin 15 (decimal) test case:
    // 15 = 0b0000_0000_0000_1111
    // ui_in[6:0] will contain 0b000_0000 (upper bits)
    // uio_in will contain 0b0000_1111 (lower bits)
    wire [15:0] data_in;
    assign data_in[15:8] = {1'b0, ui_in[6:0]};  // Upper bits from ui_in
    assign data_in[7:0] = uio_in;               // Lower bits from uio_in
    
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in(data_in),
        .write_en(ui_in[7]),    // Write enable is MSB of ui_in
        .data_out(uo_out),      // 8-bit output directly to uo_out
        .valid_out(valid_out),  // Status bit 0
        .last_bin(last_bin),    // Status bit 1
        .ready(ready)           // Not used externally
    );
    
    // Status signals to uio_out[1:0]
    assign uio_out = {6'b0, last_bin, valid_out};  // Map status bits to LSBs
    assign uio_oe = 8'b11;  // Enable output for status bits
    
    wire unused = ena | ready;  // Handle unused signals

endmodule