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
    
    wire [15:0] data_in;
    wire write_en;
    wire [7:0] data_out;
    wire valid_out;
    wire last_bin;
    wire ready;
    
    // Map the 16-bit data_in across ui_in and uio_in
    assign data_in = {ui_in[6:0], uio_in[7:0], 1'b0};
    assign write_en = ui_in[7];
    
    // Instantiate the histogramming module
    histogramming hist_inst (
        .clk(clk),
        .reset(~rst_n),
        .data_in(data_in),
        .write_en(write_en),
        .data_out(data_out),
        .valid_out(valid_out),
        .last_bin(last_bin),
        .ready(ready)
    );
    
    // Connect outputs
    assign uo_out = data_out;
    
    // Connect control signals to uio_out
    assign uio_out = {5'b0, ready, last_bin, valid_out};
    
    // Set outputs for control signals
    assign uio_oe = 8'b00000111;  // Enable output for ready, last_bin, valid_out
    
    // Handle unused inputs
    wire _unused_ok = &{ena};

endmodule