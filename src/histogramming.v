module histogramming (
    input wire clk,
    input wire reset,
    input wire [15:0] data_in,    
    input wire write_en,         
    output reg [7:0] data_out,   
    output reg valid_out,        
    output reg last_bin,        
    output reg ready            
);
    // 10 bins with 8-bit counts (changed from 20)
    reg [7:0] bins_8bit [0:9];   
    // 54 bins with 4-bit counts (changed from 44)
    reg [3:0] bins_4bit [10:63]; 
    
    // State machine states
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam OUTPUT_DATA = 2'b01;
    localparam RESET_BINS = 2'b10;
    
    // Counter for outputs
    reg [5:0] shift_count;
    
    // Extract the last 6 bits
    wire [5:0] bin_index;
    assign bin_index = data_in[5:0];
    
    // Bin reset control
    reg local_bin_reset;
    wire bin_reset;
    assign bin_reset = reset || local_bin_reset;
    
    integer i;
    
    // Bin management logic with separate reset
    always @(posedge clk or posedge bin_reset) begin
        if (bin_reset) begin
            // Reset all bins
            for (i = 0; i < 10; i = i + 1) begin  // Changed loop bound to 10
                bins_8bit[i] <= 8'h0;
            end
            for (i = 10; i < 64; i = i + 1) begin  // Changed start index to 10
                bins_4bit[i] <= 4'h0;
            end
        end
        else if (state == IDLE && write_en && ready) begin
            if (bin_index < 10) begin  // Changed condition to 10
                // Update 8-bit bins
                if (bins_8bit[bin_index] != 8'hFF) begin
                    bins_8bit[bin_index] <= bins_8bit[bin_index] + 1'b1;
                end
            end else begin
                // Update 4-bit bins
                if (bins_4bit[bin_index] != 4'hF) begin
                    bins_4bit[bin_index] <= bins_4bit[bin_index] + 1'b1;
                end
            end
        end
    end
    
    // FSM and output logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 8'h0;
            valid_out <= 1'b0;
            last_bin <= 1'b0;
            ready <= 1'b1;
            state <= IDLE;
            local_bin_reset <= 1'b0;
            shift_count <= 6'h0;
        end
        else begin
            local_bin_reset <= 1'b0;  // Default value
            
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    last_bin <= 1'b0;
                    shift_count <= 6'h0;
                    
                    if (write_en && ready) begin
                        if ((bin_index < 10 && bins_8bit[bin_index] == 8'hFF) ||  // Changed condition to 10
                            (bin_index >= 10 && bins_4bit[bin_index] == 4'hF)) begin  // Changed condition to 10
                            state <= OUTPUT_DATA;
                            ready <= 1'b0;
                        end
                    end
                end
                
                OUTPUT_DATA: begin
                    valid_out <= 1'b1;
                    
                    // Output the current bin value based on count
                    if (shift_count < 10) begin  // Changed condition to 10
                        data_out <= bins_8bit[shift_count];
                    end else begin
                        data_out <= {4'h0, bins_4bit[shift_count]};
                    end
                    
                    if (shift_count == 63) begin
                        last_bin <= 1'b1;
                        state <= RESET_BINS;
                    end else begin
                        shift_count <= shift_count + 1'b1;
                    end
                end
                
                RESET_BINS: begin
                    local_bin_reset <= 1'b1;
                    valid_out <= 1'b0;
                    last_bin <= 1'b0;
                    ready <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule