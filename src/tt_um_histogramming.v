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

    // Assign your inputs and outputs
    wire reset = ~rst_n;  // Active-high reset for internal use
    wire write_en = ui_in[0]; // Assign input enable
    wire [7:0] data_in = {ui_in[7:1]}; // Map 7 bits of ui_in to data_in
    wire ready;          // Internal ready signal
    wire valid_out;      // Valid output flag
    wire last_bin;       // Last bin indicator

    // Connect outputs
    assign uo_out[7:0] = {last_bin, valid_out, data_out}; // Map data_out, valid_out, last_bin
    assign uio_out = 8'b0;     // Unused IO outputs, set to 0
    assign uio_oe = 8'b0;      // Unused IO output enable, set to 0

    // Instantiate your histogramming module
    histogramming hist_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .write_en(write_en),
        .data_out(uo_out[3:0]),   // Map data_out to the lower bits of uo_out
        .valid_out(uo_out[1]),    // Map valid_out to uo_out[1]
        .last_bin(uo_out[0]),     // Map last_bin to uo_out[0]
        .ready(ready)
    );

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in[7:6], uio_in[7:0], 1'b0};

endmodule
