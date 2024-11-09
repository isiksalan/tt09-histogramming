module tt_um_histogramming (
    input wire [7:0] ui_in,     // Dedicated inputs
    output reg [7:0] uo_out,    // Dedicated outputs
    input wire clk,             // Clock
    input wire rst_n            // Reset (active low)
);
    // Extracted inputs
    wire write_en = ui_in[0];
    wire [5:0] data_in = ui_in[6:1];  // Using 6 bits of ui_in for data
    wire start = ui_in[7];

    // Outputs
    reg [7:0] data_out;
    reg valid_out;
    reg last_bin;
    reg ready;

    // Change all bins to 4-bit counts for area efficiency
    reg [3:0] bins [0:63];  // 64 bins of 4 bits each

    // State machine states
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam OUTPUT_DATA = 2'b01;
    localparam RESET_BINS = 2'b10;

    // Counter for outputs
    reg [5:0] shift_count;

    // Bin reset control
    reg local_bin_reset;
    wire bin_reset;
    assign bin_reset = !rst_n || local_bin_reset;

    integer i;

    // Bin management logic with separate reset
    always @(posedge clk or posedge bin_reset) begin
        if (bin_reset) begin
            // Reset all bins
            for (i = 0; i < 64; i = i + 1) begin
                bins[i] <= 4'h0;
            end
        end
        else if (state == IDLE && write_en && ready) begin
            if (bins[data_in] != 4'hF) begin
                bins[data_in] <= bins[data_in] + 1'b1;
            end
        end
    end

    // FSM and output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
                        if (bins[data_in] == 4'hF) begin
                            state <= OUTPUT_DATA;
                            ready <= 1'b0;
                        end
                    end
                end

                OUTPUT_DATA: begin
                    valid_out <= 1'b1;

                    // Output the current bin value
                    data_out <= {4'h0, bins[shift_count]};

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

    // Map outputs to `uo_out`
    always @(*) begin
        uo_out[0] = valid_out;
        uo_out[1] = last_bin;
        uo_out[7:2] = 6'b0; // Unused outputs
    end
endmodule
