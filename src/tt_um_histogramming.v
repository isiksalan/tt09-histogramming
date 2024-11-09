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
    // Internal registers to store 16-bit input data
    reg [15:0] data_reg;
    reg [7:0] data_out_reg;
    reg valid_out_reg;
    reg last_bin_reg;
    reg ready_reg;
    
    // 64 bins with 4-bit counts
    reg [3:0] bins_4bit [0:63]; 
    
    // State machine states
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam OUTPUT_DATA = 2'b01;
    localparam RESET_BINS = 2'b10;
    
    // Counter for outputs
    reg [5:0] shift_count;
    
    // Input control signals from ui_in
    wire write_en = ui_in[7];           // Use MSB as write enable
    wire load_upper = ui_in[6];         // Load upper byte
    wire [5:0] bin_index = ui_in[5:0];  // Use lower 6 bits as bin index
    
    // Bin reset control
    reg local_bin_reset;
    wire bin_reset;
    assign bin_reset = ~rst_n || local_bin_reset;
    
    integer i;
    
    // Data input handling
    always @(posedge clk) begin
        if (~rst_n) begin
            data_reg <= 16'h0;
        end else if (load_upper) begin
            data_reg[15:8] <= ui_in;
        end else begin
            data_reg[7:0] <= ui_in;
        end
    end
    
    // Bin management logic with separate reset
    always @(posedge clk or posedge bin_reset) begin
        if (bin_reset) begin
            // Reset all bins
            for (i = 0; i < 64; i = i + 1) begin
                bins_4bit[i] <= 4'h0;
            end
        end else if (state == IDLE && write_en && ready_reg) begin
            // Update 4-bit bins
            if (bins_4bit[bin_index] != 4'hF) begin
                bins_4bit[bin_index] <= bins_4bit[bin_index] + 1'b1;
            end
        end
    end
    
    // FSM and output logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out_reg <= 8'h0;
            valid_out_reg <= 1'b0;
            last_bin_reg <= 1'b0;
            ready_reg <= 1'b1;
            state <= IDLE;
            local_bin_reset <= 1'b0;
            shift_count <= 6'h0;
        end
        else begin
            local_bin_reset <= 1'b0;  // Default value
            
            case (state)
                IDLE: begin
                    valid_out_reg <= 1'b0;
                    last_bin_reg <= 1'b0;
                    shift_count <= 6'h0;
                    
                    if (write_en && ready_reg) begin
                        if (bins_4bit[bin_index] == 4'hF) begin
                            state <= OUTPUT_DATA;
                            ready_reg <= 1'b0;
                        end
                    end
                end
                
                OUTPUT_DATA: begin
                    valid_out_reg <= 1'b1;
                    data_out_reg <= {4'h0, bins_4bit[shift_count]};
                    
                    if (shift_count == 63) begin
                        last_bin_reg <= 1'b1;
                        state <= RESET_BINS;
                    end else begin
                        shift_count <= shift_count + 1'b1;
                    end
                end
                
                RESET_BINS: begin
                    local_bin_reset <= 1'b1;
                    valid_out_reg <= 1'b0;
                    last_bin_reg <= 1'b0;
                    ready_reg <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Output assignments
    assign uo_out = data_out_reg;
    assign uio_out = 8'b0;  // Unused
    assign uio_oe = 8'b0;   // All pins as inputs
    
    // Handle unused inputs
    wire _unused_ok = &{ena, uio_in};

endmodule
