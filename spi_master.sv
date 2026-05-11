module spi_master #(
    parameter addr = 1,
    parameter data = 2
) (
    input logic clk,
    input logic reset,

    input logic start,
    input logic rnw,                                                    // R/W 0 для записи
    input logic [data-1:0] data_in,                                     // Данные которые я хочу записать
    input logic [addr-1:0] address,                                     // Адресс
                                     

    //Внешние ноги АЦП

    output logic SCLK,                                                   // Генерируемая тактовая частота
    output logic SDIO,                                                   // Ножка данных 
    output logic CSB                                                     // Флаг записи (0 -> запись)
);

    localparam  PACKET_WIDTH = 1 + addr + data;
    localparam  BITCNT_WIDTH = $clog2(PACKET_WIDTH);

    wire [PACKET_WIDTH-1:0] full_packet;

    assign full_packet = {
        rnw, 
        address,
        data_in
    };

    typedef enum logic [1:0] {  
        IDLE,                                                           // Покойное состояние
        SETUP,                                                          // Подготовка к чтению
        SHIFT,                                                          // Пошла передача
        DONE
    } state_t;

    logic [BITCNT_WIDTH-1:0] bit_counter;

    state_t current_state;

    always_ff @( posedge clk ) begin

        if(reset) begin
            current_state <= IDLE;
            SCLK <= 1'b0;
            SDIO <= 1'b0;
            CSB <= 1'b1;
        end else begin
            case(current_state)

                IDLE: begin
                    CSB <= 1'b1;
                    SCLK <= 1'b0;
                   if(start) begin 
                        bit_counter <= PACKET_WIDTH - 1; //?
                        current_state <= SETUP;
                   end
                end

                SETUP: begin
                    CSB <= 1'b0;
                    current_state <= SHIFT;
                end

                SHIFT: begin
                    if (SCLK == 1'b0) begin 
                        SDIO <= full_packet[bit_counter];
                        SCLK <= 1'b1;
                    end else begin 
                        SCLK <= 1'b0;
                        if (bit_counter == 0) 
                            current_state <= DONE;
                        else 
                            bit_counter <= bit_counter - 1'b1;
                    end
                end

                DONE: begin
                    CSB <= 1'b1;
		    if(!start) begin	    
                   	 current_state <= IDLE;
		    end
                end

            endcase
        end
    end
endmodule
