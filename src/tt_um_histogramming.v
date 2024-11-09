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

    reg [15:0] data_reg;
    reg [7:0] data_out_reg;
    reg valid_out_reg;
    reg last_bin_reg;
    reg ready_reg;
    
    reg [3:0] bins [0:63]; 
    
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter OUTPUT_DATA = 2'b01;
    parameter RESET_BINS = 2'b10;
    
    reg [5:0] shift_count;
    reg local_bin_reset;
    
    wire write_en;
    wire load_upper;
    wire [5:0] bin_index;
    wire bin_reset;
    
    integer i;
    
    assign write_en = ui_in[7];
    assign load_upper = ui_in[6];
    assign bin_index = ui_in[5:0];
    assign bin_reset = ~rst_n || local_bin_reset;
    
    // Data input handling
    always @(posedge clk) begin
        if (~rst_n) begin
            data_reg <= 16'h0;
        end 
        else if (load_upper) begin
            data_reg[15:8] <= ui_in;
        end 
        else begin
            data_reg[7:0] <= ui_in;
        end
    end
    
    // Bin management logic with separate reset
    always @(posedge clk or posedge bin_reset) begin
        if (bin_reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                bins[i] <= 4'h0;
            end
        end
        else if (state == IDLE && write_en && ready_reg) begin
            if (bins[bin_index] != 4'hF) begin
                bins[bin_index] <= bins[bin_index] + 1'b1;
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
            local_bin_reset <= 1'b0;
            
            case (state)
                IDLE: begin
                    valid_out_reg <= 1'b0;
                    last_bin_reg <= 1'b0;
                    shift_count <= 6'h0;
                    
                    if (write_en && ready_reg && bins[bin_index] == 4'hF) begin
                        state <= OUTPUT_DATA;
                        ready_reg <= 1'b0;
                    end
                end
                
                OUTPUT_DATA: begin
                    valid_out_reg <= 1'b1;
                    data_out_reg <= {4'h0, bins[shift_count]};
                    
                    if (shift_count == 63) begin
                        last_bin_reg <= 1'b1;
                        state <= RESET_BINS;
                    end 
                    else begin
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
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Output assignments
    assign uo_out = data_out_reg;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;
    
    // Handle unused inputs
    wire _unused_ok;
    assign _unused_ok = &{ena, uio_in};

endmodule