
`default_nettype none

module tt_um_histogramming (
    input  wire [7:0] ui_in,     
    output wire [7:0] uo_out,    
    input  wire [7:0] uio_in,    
    output wire [7:0] uio_out,   
    output wire [7:0] uio_oe,    
    input  wire       clk,       
    input  wire       rst_n,     
    input  wire       ena        
);
    // 32 bins with 4-bit counts for odd numbers
    reg [3:0] bins [0:31];
    
    // State machine states
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam OUTPUT_DATA = 2'b01;
    localparam RESET_BINS = 2'b10;
    
    // Counter for outputs
    reg [4:0] shift_count;
    
    // Internal registers
    reg [7:0] data_out_reg;
    reg valid_out_reg;
    reg last_bin_reg;
    reg ready_reg;
    
    // Input processing
    wire [5:0] input_value;
    wire [4:0] bin_index;
    wire is_odd;
    wire write_en;
    
    assign input_value = ui_in[5:0];
    assign is_odd = input_value[0];
    assign bin_index = input_value[5:1];
    assign write_en = ui_in[7];
    
    // Outputs
    assign uo_out = data_out_reg;
    assign uio_out = {3'b0, valid_out_reg, last_bin_reg, ready_reg, 2'b0};
    assign uio_oe = 8'hFF;
    
    integer i;
    
    // Main logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) bins[i] <= 4'h0;
            state <= IDLE;
            shift_count <= 5'h0;
            data_out_reg <= 8'h0;
            valid_out_reg <= 1'b0;
            last_bin_reg <= 1'b0;
            ready_reg <= 1'b1;
        end
        else if (ena) begin
            case (state)
                IDLE: begin
                    valid_out_reg <= 1'b0;
                    last_bin_reg <= 1'b0;
                    data_out_reg <= 8'h0;
                    
                    if (write_en && ready_reg && is_odd) begin
                        if (bins[bin_index] == 4'hE) begin
                            bins[bin_index] <= 4'hF;
                            state <= OUTPUT_DATA;
                            ready_reg <= 1'b0;
                            shift_count <= 5'h0;
                        end
                        else begin
                            bins[bin_index] <= bins[bin_index] + 1'b1;
                        end
                    end
                end
                
                OUTPUT_DATA: begin
                    valid_out_reg <= 1'b1;
                    data_out_reg <= {4'h0, bins[shift_count]};
                    
                    if (shift_count == 5'd31) begin
                        last_bin_reg <= 1'b1;
                        state <= RESET_BINS;
                    end
                    shift_count <= shift_count + 1'b1;
                end
                
                RESET_BINS: begin
                    for (i = 0; i < 32; i = i + 1) bins[i] <= 4'h0;
                    valid_out_reg <= 1'b0;
                    last_bin_reg <= 1'b0;
                    ready_reg <= 1'b1;
                    shift_count <= 5'h0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule