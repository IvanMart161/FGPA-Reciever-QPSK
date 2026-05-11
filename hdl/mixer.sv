`timescale 100ps / 100ps
module mixer #(
    parameter ADC_WIDTH = 12,
    parameter DDS_WIDTH = 12,
    parameter WIDTH_OUT = ADC_WIDTH + DDS_WIDTH,
    parameter LANES = 8
) (
    input logic                                  clk,
    input logic                                  rst,

    input logic signed      [ADC_WIDTH-1:0]      data_in [0:LANES-1],
    input logic signed      [DDS_WIDTH-1:0]      cos_in  [0:LANES-1],
    input logic signed      [DDS_WIDTH-1:0]      sin_in  [0:LANES-1],

    output logic signed     [WIDTH_OUT-1:0]      i_out   [0:LANES-1],
    output logic signed     [WIDTH_OUT-1:0]      q_out   [0:LANES-1]
);

genvar i;
generate 
    for(i=0; i < LANES; i++) begin : gen_mixer
        always_ff @(posedge clk or negedge rst) begin
            if (!rst) begin
                 i_out[i] <= '0;
                 q_out[i] <= '0;
             end else begin
                 
                  i_out[i] <= data_in[i] * cos_in[i];               // Канал I
                  q_out[i] <= data_in[i] * sin_in[i];               // Канал Q
             end 
        end
         
    end
endgenerate

endmodule 
