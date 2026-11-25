//------------------------------------------------------------------------------
// Module      : read_data_path
// Project     : AXI-LiteBurst-32
// Description : Read data mux with security zero-masking when access is denied.
//------------------------------------------------------------------------------
module read_data_path #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] mem_data,
    input  wire                  read_allow,
    output wire [DATA_WIDTH-1:0] data_out
);
    assign data_out = read_allow ? mem_data : {DATA_WIDTH{1'b0}};
endmodule
