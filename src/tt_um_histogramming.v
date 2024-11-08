module tt_um_histogramming (
    input wire [7:0]  ui_in,   // Dedicated inputs
    output wire [7:0] uo_out,  // Dedicated outputs
    input wire [7:0]  uio_in,  // IOs: Input path
    output wire [7:0] uio_out, // IOs: Output path
    output wire [7:0] uio_oe,  // IOs: Enable path (active high: 0=input, 1=output)
    input wire        ena,     // Always 1 when the design is powered, so you can ignore it
    input wire        clk,     // Clock
    input wire        rst_n    // Active-low reset
);

    // Assign reset as active high for internal use
    wire reset = ~rst_n;

    // Map ui_in to the histogramming module's inputs
    wire [15:0] data_in = {8'b0, ui_in[7:0]}; // Extend ui_in to 16 bits by padding upper bits
    wire write_en = ui_in[0]; // Use LSB of ui_in as write enable

    // Output signals
    wire [7:0] data_out;  // 8-bit data output from the histogramming module
    wire valid_out;       // Valid output flag
    wire last_bin;        // Last bin indicator
    wire ready;           // Ready signal

    // Connect uo_out to represent data_out, valid_out, and last_bin
    assign uo_out = {last_bin, valid_out, data_out[5:0]}; // Adjusted to use only available bits
    assign uio_out = 8'b0;     // Set unused IO outputs to 0
    assign uio_oe = 8'b0;      // Set unused IO output enable to 0

    // Instantiate the histogramming module
    histogramming hist_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .write_en(write_en),
        .data_out(data_out),
        .valid_out(valid_out),
        .last_bin(last_bin),
        .ready(ready)
    );

    // Unused input to prevent warnings
    wire _unused = &{ena, uio_in[7:0]};

endmodule
