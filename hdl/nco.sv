module nco(
    parameter DATA = 12,                                        // Размерность данных
    parameter ACC = 32,                                         // Аккумулятор
    parameter LANES = 8                                         // Количество выходов
) (
    input   logic                       clk,
    input   logic                       reset,
    //input   logic signed                phase_offset,           // расстройка фазы из петли костаса (пока разрядность неизваестна)
    output  logic signed [DATA-1:0]     sin_out     [0:LANES-1],
    output  logic signed [DATA-1:0]     cos_out     [0:LANES-1]                       
);

localparam bit [ACC-1:0] FTW_500MHZ = ACC'd1789569706;

logic [ACC-1:0] phase_acc = ACC'd0;

logic [DATA-1:0] sin_rom [0:1023];
logci [DATA-1:0] cos_rom [0:1023];

logic [9:0] rom_addr;

initial begin
    $readmemh("rom/cos.mem", cos_rom);
    $readmemh("rom/sin.mem", sin_rom);
end

always_ff @(posedge clk or negedge reset) begin
    if(reset) begin
        phase_acc <= '0;
    end else begin
        phase_acc <= phase_acc + FTW_500MHZ + phase_offset;
        for(int i = 0; i < LANES; i++) begin
            automatic logic [ACC-1:0] phase_cahnnel = phase_acc + (FTW_500MHZ / 8) * i;
            rom_addr <= phase_cahnnel [ACC-1: ACC-DATA+2];
            sin_out[i] <= &signed(sin_rom[rom_addr]);
            cos_out[i] <= &signed(cos_rom[rom_addr]);
        end
    end 
    
end
endmodule