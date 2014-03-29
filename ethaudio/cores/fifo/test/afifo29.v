`default_nettype none
module afifo29 (
        input wire [28:0] Data,
        input wire WrClock,
        input wire RdClock,
        input wire WrEn,
        input wire RdEn,
        input wire Reset,
        input wire RPReset,
        output wire [28:0] Q,
        output wire Empty,
        output wire Full
);

asfifo # (
        .DATA_WIDTH(29),
        .ADDRESS_WIDTH(12)
) asfifo_inst (
        .dout(Q), 
        .empty(Empty),
        .rd_en(RdEn),
        .rd_clk(RdClock),        
        .din(Data),  
        .full(Full),
        .wr_en(WrEn),
        .wr_clk(WrClock),
        .rst(Reset)
);

endmodule
`default_nettype wire
