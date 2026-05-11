module buffer # (
    parameter DATA = 16,
    parameter WIDTH = 4
)(
    input logic signed          [DATA-1:0]      sin,
    input logic                                 clk,
    output logic signed         [DATA-1:0]      sout [0:WIDTH-1]
)
    integer i;
    always_ff @(posedge clk) begin
        if(reset) begin 
            for(int i=0; i<4; i++) begin 
                sout[i] <= 0; 
            end
        end else begin
            for(int i=0; i<4; i++) begin
                sout [i] <= sin; 
            end   
        end
    end
endmodule

