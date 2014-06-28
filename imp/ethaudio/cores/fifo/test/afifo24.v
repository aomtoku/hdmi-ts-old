`default_nettype none
module afifo24 (
        input wire [23:0] Data,
        input wire WrClock,
        input wire RdClock,
        input wire WrEn,
        input wire RdEn,
        input wire Reset,
        input wire RPReset,
        output wire [23:0] Q,
        output wire Empty,
        output wire Full
);

asfifo # (
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(16)
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
