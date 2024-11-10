
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
    // Changed array declaration for Verilator compatibility
    reg [3:0] bin_array [31:0];  // 32 bins of 4-bits each
    
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter OUTPUT_DATA = 2'b01;
    parameter RESET_BINS = 2'b10;
    
    reg [4:0] shift_count;
    reg [7:0] data_out_reg;
    reg valid_out_reg;
    reg last_bin_reg;
    reg ready_reg;
    
    wire [5:0] input_value;
    wire [4:0] bin_index;
    wire is_odd;
    wire write_en;
    
    assign input_value = ui_in[5:0];
    assign is_odd = input_value[0];
    assign bin_index = input_value[5:1];
    assign write_en = ui_in[7];
    
    assign uo_out = data_out_reg;
    assign uio_out = {3'b0, valid_out_reg, last_bin_reg, ready_reg, 2'b0};
    assign uio_oe = 8'hFF;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                bin_array[i] <= 4'h0;
            end
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
                        if (bin_array[bin_index] == 4'hE) begin
                            bin_array[bin_index] <= 4'hF;
                            state <= OUTPUT_DATA;
                            ready_reg <= 1'b0;
                            shift_count <= 5'h0;
                        end
                        else begin
                            bin_array[bin_index] <= bin_array[bin_index] + 1'b1;
                        end
                    end
                end
                
                OUTPUT_DATA: begin
                    valid_out_reg <= 1'b1;
                    data_out_reg <= {4'h0, bin_array[shift_count]};
                    
                    if (shift_count == 5'd31) begin
                        last_bin_reg <= 1'b1;
                        state <= RESET_BINS;
                    end
                    shift_count <= shift_count + 1'b1;
                end
                
                RESET_BINS: begin
                    for (i = 0; i < 32; i = i + 1) begin
                        bin_array[i] <= 4'h0;
                    end
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
