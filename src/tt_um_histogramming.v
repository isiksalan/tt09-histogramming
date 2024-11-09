module tt_um_histogramming (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    // Registers
    reg [15:0] data_reg;
    reg [7:0] data_out_reg;
    reg valid_out_reg;
    reg last_bin_reg;
    reg ready_reg;
    
    // State and control registers
    reg [1:0] state;
    reg [5:0] shift_count;
    reg local_bin_reset;
    
    // Histogram bins (4-bit each)
    reg [3:0] bin0, bin1, bin2, bin3, bin4, bin5, bin6, bin7;
    reg [3:0] bin8, bin9, bin10, bin11, bin12, bin13, bin14, bin15;
    reg [3:0] bin16, bin17, bin18, bin19, bin20, bin21, bin22, bin23;
    reg [3:0] bin24, bin25, bin26, bin27, bin28, bin29, bin30, bin31;
    reg [3:0] bin32, bin33, bin34, bin35, bin36, bin37, bin38, bin39;
    reg [3:0] bin40, bin41, bin42, bin43, bin44, bin45, bin46, bin47;
    reg [3:0] bin48, bin49, bin50, bin51, bin52, bin53, bin54, bin55;
    reg [3:0] bin56, bin57, bin58, bin59, bin60, bin61, bin62, bin63;
    
    // Parameters
    parameter IDLE = 2'b00;
    parameter OUTPUT_DATA = 2'b01;
    parameter RESET_BINS = 2'b10;
    
    // Wires
    wire write_en;
    wire load_upper;
    wire [5:0] bin_index;
    wire bin_reset;
    
    // Wire assignments
    assign write_en = ui_in[7];
    assign load_upper = ui_in[6];
    assign bin_index = ui_in[5:0];
    assign bin_reset = ~rst_n || local_bin_reset;
    
    // Function to access bins based on index
    reg [3:0] current_bin_value;
    always @(*) begin
        case(shift_count)
            6'd0: current_bin_value = bin0;
            6'd1: current_bin_value = bin1;
            6'd2: current_bin_value = bin2;
            6'd3: current_bin_value = bin3;
            6'd4: current_bin_value = bin4;
            6'd5: current_bin_value = bin5;
            6'd6: current_bin_value = bin6;
            6'd7: current_bin_value = bin7;
            6'd8: current_bin_value = bin8;
            6'd9: current_bin_value = bin9;
            6'd10: current_bin_value = bin10;
            6'd11: current_bin_value = bin11;
            6'd12: current_bin_value = bin12;
            6'd13: current_bin_value = bin13;
            6'd14: current_bin_value = bin14;
            6'd15: current_bin_value = bin15;
            6'd16: current_bin_value = bin16;
            6'd17: current_bin_value = bin17;
            6'd18: current_bin_value = bin18;
            6'd19: current_bin_value = bin19;
            6'd20: current_bin_value = bin20;
            6'd21: current_bin_value = bin21;
            6'd22: current_bin_value = bin22;
            6'd23: current_bin_value = bin23;
            6'd24: current_bin_value = bin24;
            6'd25: current_bin_value = bin25;
            6'd26: current_bin_value = bin26;
            6'd27: current_bin_value = bin27;
            6'd28: current_bin_value = bin28;
            6'd29: current_bin_value = bin29;
            6'd30: current_bin_value = bin30;
            6'd31: current_bin_value = bin31;
            6'd32: current_bin_value = bin32;
            6'd33: current_bin_value = bin33;
            6'd34: current_bin_value = bin34;
            6'd35: current_bin_value = bin35;
            6'd36: current_bin_value = bin36;
            6'd37: current_bin_value = bin37;
            6'd38: current_bin_value = bin38;
            6'd39: current_bin_value = bin39;
            6'd40: current_bin_value = bin40;
            6'd41: current_bin_value = bin41;
            6'd42: current_bin_value = bin42;
            6'd43: current_bin_value = bin43;
            6'd44: current_bin_value = bin44;
            6'd45: current_bin_value = bin45;
            6'd46: current_bin_value = bin46;
            6'd47: current_bin_value = bin47;
            6'd48: current_bin_value = bin48;
            6'd49: current_bin_value = bin49;
            6'd50: current_bin_value = bin50;
            6'd51: current_bin_value = bin51;
            6'd52: current_bin_value = bin52;
            6'd53: current_bin_value = bin53;
            6'd54: current_bin_value = bin54;
            6'd55: current_bin_value = bin55;
            6'd56: current_bin_value = bin56;
            6'd57: current_bin_value = bin57;
            6'd58: current_bin_value = bin58;
            6'd59: current_bin_value = bin59;
            6'd60: current_bin_value = bin60;
            6'd61: current_bin_value = bin61;
            6'd62: current_bin_value = bin62;
            6'd63: current_bin_value = bin63;
            default: current_bin_value = 4'h0;
        endcase
    end
    
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
    
    // Bin reset and increment logic
    always @(posedge clk or posedge bin_reset) begin
        if (bin_reset) begin
            {bin0, bin1, bin2, bin3, bin4, bin5, bin6, bin7} <= {8{4'h0}};
            {bin8, bin9, bin10, bin11, bin12, bin13, bin14, bin15} <= {8{4'h0}};
            {bin16, bin17, bin18, bin19, bin20, bin21, bin22, bin23} <= {8{4'h0}};
            {bin24, bin25, bin26, bin27, bin28, bin29, bin30, bin31} <= {8{4'h0}};
            {bin32, bin33, bin34, bin35, bin36, bin37, bin38, bin39} <= {8{4'h0}};
            {bin40, bin41, bin42, bin43, bin44, bin45, bin46, bin47} <= {8{4'h0}};
            {bin48, bin49, bin50, bin51, bin52, bin53, bin54, bin55} <= {8{4'h0}};
            {bin56, bin57, bin58, bin59, bin60, bin61, bin62, bin63} <= {8{4'h0}};
        end
        else if (state == IDLE && write_en && ready_reg) begin
            case(bin_index)
                6'd0: if (bin0 != 4'hF) bin0 <= bin0 + 1'b1;
                6'd1: if (bin1 != 4'hF) bin1 <= bin1 + 1'b1;
                6'd2: if (bin2 != 4'hF) bin2 <= bin2 + 1'b1;
                6'd3: if (bin3 != 4'hF) bin3 <= bin3 + 1'b1;
                6'd4: if (bin4 != 4'hF) bin4 <= bin4 + 1'b1;
                6'd5: if (bin5 != 4'hF) bin5 <= bin5 + 1'b1;
                6'd6: if (bin6 != 4'hF) bin6 <= bin6 + 1'b1;
                6'd7: if (bin7 != 4'hF) bin7 <= bin7 + 1'b1;
                6'd8: if (bin8 != 4'hF) bin8 <= bin8 + 1'b1;
                6'd9: if (bin9 != 4'hF) bin9 <= bin9 + 1'b1;
                6'd10: if (bin10 != 4'hF) bin10 <= bin10 + 1'b1;
                6'd11: if (bin11 != 4'hF) bin11 <= bin11 + 1'b1;
                6'd12: if (bin12 != 4'hF) bin12 <= bin12 + 1'b1;
                6'd13: if (bin13 != 4'hF) bin13 <= bin13 + 1'b1;
                6'd14: if (bin14 != 4'hF) bin14 <= bin14 + 1'b1;
                6'd15: if (bin15 != 4'hF) bin15 <= bin15 + 1'b1;
                6'd16: if (bin16 != 4'hF) bin16 <= bin16 + 1'b1;
                6'd17: if (bin17 != 4'hF) bin17 <= bin17 + 1'b1;
                6'd18: if (bin18 != 4'hF) bin18 <= bin18 + 1'b1;
                6'd19: if (bin19 != 4'hF) bin19 <= bin19 + 1'b1;
                6'd20: if (bin20 != 4'hF) bin20 <= bin20 + 1'b1;
                6'd21: if (bin21 != 4'hF) bin21 <= bin21 + 1'b1;
                6'd22: if (bin22 != 4'hF) bin22 <= bin22 + 1'b1;
                6'd23: if (bin23 != 4'hF) bin23 <= bin23 + 1'b1;
                6'd24: if (bin24 != 4'hF) bin24 <= bin24 + 1'b1;
                6'd25: if (bin25 != 4'hF) bin25 <= bin25 + 1'b1;
                6'd26: if (bin26 != 4'hF) bin26 <= bin26 + 1'b1;
                6'd27: if (bin27 != 4'hF) bin27 <= bin27 + 1'b1;
                6'd28: if (bin28 != 4'hF) bin28 <= bin28 + 1'b1;
                6'd29: if (bin29 != 4'hF) bin29 <= bin29 + 1'b1;
                6'd30: if (bin30 != 4'hF) bin30 <= bin30 + 1'b1;
                6'd31: if (bin31 != 4'hF) bin31 <= bin31 + 1'b1;
                6'd32: if (bin32 != 4'hF) bin32 <= bin32 + 1'b1;
                6'd33: if (bin33 != 4'hF) bin33 <= bin33 + 1'b1;
                6'd34: if (bin34 != 4'hF) bin34 <= bin34 + 1'b1;
                6'd35: if (bin35 != 4'hF) bin35 <= bin35 + 1'b1;
                6'd36: if (bin36 != 4'hF) bin36 <= bin36 + 1'b1;
                6'd37: if (bin37 != 4'hF) bin37 <= bin37 + 1'b1;
                6'd38: if (bin38 != 4'hF) bin38 <= bin38 + 1'b1;
                6'd39: if (bin39 != 4'hF) bin39 <= bin39 + 1'b1;
                6'd40: if (bin40 != 4'hF) bin40 <= bin40 + 1'b1;
                6'd41: if (bin41 != 4'hF) bin41 <= bin41 + 1'b1;
                6'd42: if (bin42 != 4'hF) bin42 <= bin42 + 1'b1;
                6'd43: if (bin43 != 4'hF) bin43 <= bin43 + 1'b1;
                6'd44: if (bin44 != 4'hF) bin44 <= bin44 + 1'b1;
                6'd45: if (bin45 != 4'hF) bin45 <= bin45 + 1'b1;
                6'd46: if (bin46 != 4'hF) bin46 <= bin46 + 1'b1;
                6'd47: if (bin47 != 4'hF) bin47 <= bin47 + 1'b1;
                6'd48: if (bin48 != 4'hF) bin48 <= bin48 + 1'b1;
                6'd49: if (bin49 != 4'hF) bin49 <= bin49 + 1'b1;
                6'd50: if (bin50 != 4'hF) bin50 <= bin50 + 1'b1;
                6'd51: if (bin51 != 4'hF) bin51 <= bin51 + 1'b1;
                6'd52: if (bin52 != 4'hF) bin52 <= bin52 + 1'b1;
                6'd53: if (bin53 != 4'hF) bin53 <= bin53 + 1'b1;
                6'd54: if (bin54 != 4'hF) bin54 <= bin54 + 1'b1;
                6'd55: if (bin55 != 4'hF) bin55 <= bin55 + 1'b1;
                6'd56: if (bin56 != 4'hF) bin56 <= bin56 + 1'b1;
                6'd57: if (bin57 != 4'hF) bin57 <= bin57 + 1'b1;
                6'd58: if (bin58 != 4'hF) bin58 <= bin58 + 1'b1;
                6'd59: if (bin59 != 4'hF) bin59 <= bin59 + 1'b1;
                6'd60: if (bin60 != 4'hF) bin60 <= bin60 + 1'b1;
                6'd61: if (bin61 != 4'hF) bin61 <= bin61 + 1'b1;
                6'd62: if (bin62 != 4'hF) bin62 <= bin62 + 1'b1;
                6'd63: if (bin63 != 4'hF) bin63 <= bin63 + 1'b1;
            endcase
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
                    
                    if (write_en && ready_reg) begin
                        case(bin_index)
                            6'd0: if (bin0 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd1: if (bin1 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd2: if (bin2 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd3: if (bin3 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd4: if (bin4 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd5: if (bin5 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd6: if (bin6 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd7: if (bin7 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd8: if (bin8 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd9: if (bin9 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd10: if (bin10 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd11: if (bin11 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd12: if (bin12 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd13: if (bin13 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd14: if (bin14 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd15: if (bin15 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd16: if (bin16 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd17: if (bin17 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd18: if (bin18 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd19: if (bin19 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd20: if (bin20 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd21: if (bin21 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd22: if (bin22 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd23: if (bin23 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd24: if (bin24 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd25: if (bin25 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd26: if (bin26 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd27: if (bin27 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd28: if (bin28 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd29: if (bin29 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd30: if (bin30 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd31: if (bin31 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd32: if (bin32 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd33: if (bin33 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd34: if (bin34 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd35: if (bin35 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd36: if (bin36 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd37: if (bin37 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd38: if (bin38 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd39: if (bin39 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd40: if (bin40 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd41: if (bin41 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd42: if (bin42 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd43: if (bin43 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd44: if (bin44 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd45: if (bin45 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd46: if (bin46 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd47: if (bin47 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd48: if (bin48 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd49: if (bin49 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd50: if (bin50 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd51: if (bin51 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd52: if (bin52 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd53: if (bin53 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd54: if (bin54 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd55: if (bin55 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd56: if (bin56 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd57: if (bin57 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd58: if (bin58 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd59: if (bin59 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd60: if (bin60 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd61: if (bin61 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd62: if (bin62 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                            6'd63: if (bin63 == 4'hF) begin state <= OUTPUT_DATA; ready_reg <= 1'b0; end
                        endcase
                    end
                end
                
                OUTPUT_DATA: begin
                    valid_out_reg <= 1'b1;
                    data_out_reg <= {4'h0, current_bin_value};
                    
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
