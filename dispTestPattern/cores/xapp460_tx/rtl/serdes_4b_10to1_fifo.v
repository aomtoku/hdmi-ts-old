//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2007                 www.xilinx.com
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       serdes_4b_10to1.v
//
//  Description :     4-bit transmitter macro for Spartan 3A (uses ODDR2)
//      Takes in 30 bits and serialises this to 4 bits DDR (4th bit is a regenerated clock)
//
//      data is transmitted LSBs first
//      0, 3,  6,  9, 12, 15, 18, 21, 24, 27 - data
//      1, 4,  7, 10, 13, 16, 19, 22, 25, 28 - data
//      2, 5,  8, 11, 14, 17, 20, 23, 26, 29 - data
//      0, 0,  0,  0,  0,  1,  1,  1,  1,  1 - clock
//
//
//  Author :          Bob Feng
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors make, and you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specifically disclaims any
//              implied warranties of merchantability, non-infringement, or
//              fitness for a particular purpose. Xilinx does not warrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designs will be
//              uninterrupted or error free, or that defects in the Designs
//              will be corrected. Furthermore, Xilinx does not warrant or
//              make any representations regarding use or the results of the
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits, cost
//              or procurement of substitute goods or services, or for any
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on any theory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure of the
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2007 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module serdes_4b_10to1 (
  input          clk,         // clock input
  input          clkx5,       // 5x clock input
  input          clkx5not,
  input [29:0]   datain,      // input data for serialisation
  input          rst,         // reset
  output [7:0]   dataout) ;   // out DDR data and clock

  wire [4:0] syncp; // internal sync signals for rising edges
  wire [4:0] syncn; // internal sync signals for falling edges

  reg [3:0] p_mux;      // muxes (+ve)
  reg [3:0] n_mux;      // muxes (-ve)
  wire [29:0] dataint;
  wire [29:0] db;

  wire  [3:0]   wa;       // RAM read address
  reg   [3:0]   wa_d;     // RAM read address
  wire  [3:0]   ra;       // RAM read address
  reg   [3:0]   ra_d;     // RAM read address

  ////////////////////////////////////////////////////
  // Here we instantiate a 16x30 Dual Port RAM
  // and fill first it with data aligned to
  // clk domain
  ////////////////////////////////////////////////////

  parameter ADDR0  = 4'b0000;
  parameter ADDR1  = 4'b0001;
  parameter ADDR2  = 4'b0010;
  parameter ADDR3  = 4'b0011;
  parameter ADDR4  = 4'b0100;
  parameter ADDR5  = 4'b0101;
  parameter ADDR6  = 4'b0110;
  parameter ADDR7  = 4'b0111;
  parameter ADDR8  = 4'b1000;
  parameter ADDR9  = 4'b1001;
  parameter ADDR10 = 4'b1010;
  parameter ADDR11 = 4'b1011;
  parameter ADDR12 = 4'b1100;
  parameter ADDR13 = 4'b1101;
  parameter ADDR14 = 4'b1110;
  parameter ADDR15 = 4'b1111;

  always@(wa) begin
    case (wa)
      ADDR0   : wa_d = ADDR1 ;
      ADDR1   : wa_d = ADDR2 ;
      ADDR2   : wa_d = ADDR3 ;
      ADDR3   : wa_d = ADDR4 ;
      ADDR4   : wa_d = ADDR5 ;
      ADDR5   : wa_d = ADDR6 ;
      ADDR6   : wa_d = ADDR7 ;
      ADDR7   : wa_d = ADDR8 ;
      ADDR8   : wa_d = ADDR9 ;
      ADDR9   : wa_d = ADDR10;
      ADDR10  : wa_d = ADDR11;
      ADDR11  : wa_d = ADDR12;
      ADDR12  : wa_d = ADDR13;
      ADDR13  : wa_d = ADDR14;
      ADDR14  : wa_d = ADDR15;
      default : wa_d = ADDR0;
    endcase
  end

  FDC fdc_wa0 (.C(clk),  .D(wa_d[0]), .CLR(rst), .Q(wa[0]));
  FDC fdc_wa1 (.C(clk),  .D(wa_d[1]), .CLR(rst), .Q(wa[1]));
  FDC fdc_wa2 (.C(clk),  .D(wa_d[2]), .CLR(rst), .Q(wa[2]));
  FDC fdc_wa3 (.C(clk),  .D(wa_d[3]), .CLR(rst), .Q(wa[3]));

  //Dual Port fifo to bridge data through
  DRAM16XN #(.data_width(30))
  fifo_u (
         .DATA_IN(datain),
         .ADDRESS(wa),
         .ADDRESS_DP(ra),
         .WRITE_EN(1'b1),
         .CLK(clk),
         .O_DATA_OUT(),
         .O_DATA_OUT_DP(dataint));

  /////////////////////////////////////////////////////////////////
  // Here starts clk5x domain for fifo read out 
  // FIFO read is set to be once every 5 cycles of clk5x in order
  // to keep up pace with the fifo write speed
  // Also FIFO read reset is delayed a bit in order to avoid
  // underflow.
  /////////////////////////////////////////////////////////////////

  always@(ra) begin
    case (ra)
      ADDR0   : ra_d = ADDR1 ;
      ADDR1   : ra_d = ADDR2 ;
      ADDR2   : ra_d = ADDR3 ;
      ADDR3   : ra_d = ADDR4 ;
      ADDR4   : ra_d = ADDR5 ;
      ADDR5   : ra_d = ADDR6 ;
      ADDR6   : ra_d = ADDR7 ;
      ADDR7   : ra_d = ADDR8 ;
      ADDR8   : ra_d = ADDR9 ;
      ADDR9   : ra_d = ADDR10;
      ADDR10  : ra_d = ADDR11;
      ADDR11  : ra_d = ADDR12;
      ADDR12  : ra_d = ADDR13;
      ADDR13  : ra_d = ADDR14;
      ADDR14  : ra_d = ADDR15;
      default : ra_d = ADDR0;
    endcase
  end

  wire rstsync, rstsync_q, rstp, rstn;
  (* ASYNC_REG = "TRUE" *) FDP fdp_rst  (.C(clkx5),  .D(rst), .PRE(rst), .Q(rstsync));

  FD fd_rstsync (.C(clkx5),  .D(rstsync), .Q(rstsync_q));
  FD fd_rstp    (.C(clkx5),  .D(rstsync_q), .Q(rstp));

  FDRE fdc_ra0 (.C(clkx5),  .D(ra_d[0]), .R(rstp), .CE(syncp[4]), .Q(ra[0]));
  FDRE fdc_ra1 (.C(clkx5),  .D(ra_d[1]), .R(rstp), .CE(syncp[4]), .Q(ra[1]));
  FDRE fdc_ra2 (.C(clkx5),  .D(ra_d[2]), .R(rstp), .CE(syncp[4]), .Q(ra[2]));
  FDRE fdc_ra3 (.C(clkx5),  .D(ra_d[3]), .R(rstp), .CE(syncp[4]), .Q(ra[3]));

  //////////////////////////////////////////////////////////////////////////////
  // 5 Cycle Counter for clkx5
  // Generate data latch and bit mux timing
  //////////////////////////////////////////////////////////////////////////////
  wire [2:0] statep, staten;
  reg [2:0] statep_d, staten_d;

  parameter ST0 = 3'b000;
  parameter ST1 = 3'b001;
  parameter ST2 = 3'b011;
  parameter ST3 = 3'b111;
  parameter ST4 = 3'b110;

  always@(statep) begin
    case (statep)
      ST0     : statep_d = ST1 ;
      ST1     : statep_d = ST2 ;
      ST2     : statep_d = ST3 ;
      ST3     : statep_d = ST4 ;
      default : statep_d = ST0;
    endcase
  end

  FDR fdc_stp0 (.C(clkx5),  .D(statep_d[0]), .R(rstp), .Q(statep[0]));
  FDR fdc_stp1 (.C(clkx5),  .D(statep_d[1]), .R(rstp), .Q(statep[1]));
  FDR fdc_stp2 (.C(clkx5),  .D(statep_d[2]), .R(rstp), .Q(statep[2]));

  wire [4:0] syncp_d;

  assign syncp_d[0] = (statep == ST0);
  assign syncp_d[1] = (statep == ST1);
  assign syncp_d[2] = (statep == ST2);
  assign syncp_d[3] = (statep == ST3);
  assign syncp_d[4] = (statep == ST4);

  FD fd_syncp0 (.C(clkx5), .D(syncp_d[0]), .Q(syncp[0]));
  FD fd_syncp1 (.C(clkx5), .D(syncp_d[1]), .Q(syncp[1]));
  FD fd_syncp2 (.C(clkx5), .D(syncp_d[2]), .Q(syncp[2]));
  FD fd_syncp3 (.C(clkx5), .D(syncp_d[3]), .Q(syncp[3]));
  FD fd_syncp4 (.C(clkx5), .D(syncp_d[4]), .Q(syncp[4]));

  //////////////////////////////////////////////////////////////////////////////
  // 5 Cycle Counter for clkx5not
  // Generate data latch and bit mux timing
  //////////////////////////////////////////////////////////////////////////////
  FD  fd_rstn (.C(clkx5not),  .D(rstsync_q), .Q(rstn));

  always@(staten) begin
    case (staten)
      ST0     : staten_d = ST1 ;
      ST1     : staten_d = ST2 ;
      ST2     : staten_d = ST3 ;
      ST3     : staten_d = ST4 ;
      default : staten_d = ST0;
    endcase
  end

  FDR fdc_stn0 (.C(clkx5not),  .D(staten_d[0]), .R(rstn), .Q(staten[0]));
  FDR fdc_stn1 (.C(clkx5not),  .D(staten_d[1]), .R(rstn), .Q(staten[1]));
  FDR fdc_stn2 (.C(clkx5not),  .D(staten_d[2]), .R(rstn), .Q(staten[2]));

  wire [4:0] syncn_d;

  assign syncn_d[0] = (staten == ST0);
  assign syncn_d[1] = (staten == ST1);
  assign syncn_d[2] = (staten == ST2);
  assign syncn_d[3] = (staten == ST3);
  assign syncn_d[4] = (staten == ST4);

  FD fd_syncn0 (.C(clkx5not), .D(syncn_d[0]), .Q(syncn[0]));
  FD fd_syncn1 (.C(clkx5not), .D(syncn_d[1]), .Q(syncn[1]));
  FD fd_syncn2 (.C(clkx5not), .D(syncn_d[2]), .Q(syncn[2]));
  FD fd_syncn3 (.C(clkx5not), .D(syncn_d[3]), .Q(syncn[3]));
  FD fd_syncn4 (.C(clkx5not), .D(syncn_d[4]), .Q(syncn[4]));

  ////////////////////////////////////////////////////////////////////////
  // Latch data out of FIFO
  // clkx5 setup time: 5 cycles since syncp[4] is used as CE
  // clkx5not setup time: 4.5 cycles since syncn[4] is used as CE
  // syncn[4] is set to be 0.5 cycle earlier than syncp[4]
  ////////////////////////////////////////////////////////////////////////
  FDE fd_db0 (.C(clkx5not), .D(dataint[0]),  .CE(syncn[4]), .Q(db[0]));
  FDE fd_db1 (.C(clkx5not), .D(dataint[1]),  .CE(syncn[4]), .Q(db[1]));
  FDE fd_db2 (.C(clkx5not), .D(dataint[2]),  .CE(syncn[4]), .Q(db[2]));

  FDE fd_db3 (.C(clkx5),    .D(dataint[3]),  .CE(syncp[4]), .Q(db[3]));
  FDE fd_db4 (.C(clkx5),    .D(dataint[4]),  .CE(syncp[4]), .Q(db[4]));
  FDE fd_db5 (.C(clkx5),    .D(dataint[5]),  .CE(syncp[4]), .Q(db[5]));

  FDE fd_db6 (.C(clkx5not), .D(dataint[6]),  .CE(syncn[4]), .Q(db[6]));
  FDE fd_db7 (.C(clkx5not), .D(dataint[7]),  .CE(syncn[4]), .Q(db[7]));
  FDE fd_db8 (.C(clkx5not), .D(dataint[8]),  .CE(syncn[4]), .Q(db[8]));

  FDE fd_db9 (.C(clkx5),    .D(dataint[9]),  .CE(syncp[4]), .Q(db[9]));
  FDE fd_db10(.C(clkx5),    .D(dataint[10]), .CE(syncp[4]), .Q(db[10]));
  FDE fd_db11(.C(clkx5),    .D(dataint[11]), .CE(syncp[4]), .Q(db[11]));

  FDE fd_db12(.C(clkx5not), .D(dataint[12]), .CE(syncn[4]), .Q(db[12]));
  FDE fd_db13(.C(clkx5not), .D(dataint[13]), .CE(syncn[4]), .Q(db[13]));
  FDE fd_db14(.C(clkx5not), .D(dataint[14]), .CE(syncn[4]), .Q(db[14]));

  FDE fd_db15(.C(clkx5),    .D(dataint[15]), .CE(syncp[4]), .Q(db[15]));
  FDE fd_db16(.C(clkx5),    .D(dataint[16]), .CE(syncp[4]), .Q(db[16]));
  FDE fd_db17(.C(clkx5),    .D(dataint[17]), .CE(syncp[4]), .Q(db[17]));

  FDE fd_db18(.C(clkx5not), .D(dataint[18]), .CE(syncn[4]), .Q(db[18]));
  FDE fd_db19(.C(clkx5not), .D(dataint[19]), .CE(syncn[4]), .Q(db[19]));
  FDE fd_db20(.C(clkx5not), .D(dataint[20]), .CE(syncn[4]), .Q(db[20]));

  FDE fd_db21(.C(clkx5),    .D(dataint[21]), .CE(syncp[4]), .Q(db[21]));
  FDE fd_db22(.C(clkx5),    .D(dataint[22]), .CE(syncp[4]), .Q(db[22]));
  FDE fd_db23(.C(clkx5),    .D(dataint[23]), .CE(syncp[4]), .Q(db[23]));

  FDE fd_db24(.C(clkx5not), .D(dataint[24]), .CE(syncn[4]), .Q(db[24]));
  FDE fd_db25(.C(clkx5not), .D(dataint[25]), .CE(syncn[4]), .Q(db[25]));
  FDE fd_db26(.C(clkx5not), .D(dataint[26]), .CE(syncn[4]), .Q(db[26]));

  FDE fd_db27(.C(clkx5),    .D(dataint[27]), .CE(syncp[4]), .Q(db[27]));
  FDE fd_db28(.C(clkx5),    .D(dataint[28]), .CE(syncp[4]), .Q(db[28]));
  FDE fd_db29(.C(clkx5),    .D(dataint[29]), .CE(syncp[4]), .Q(db[29]));

  //////////////////////////////////////////////////////////////////////////
  // Data OUT Multiplexers: clk5x and clk5xnot
  //////////////////////////////////////////////////////////////////////////
  always @ (*)
  begin
    casex (1'b1) // synthesis parallel_case full_case
      syncn[0]: begin
        n_mux[0] = db[0];
        n_mux[1] = db[1];
        n_mux[2] = db[2];
        n_mux[3] = 1'b0;
      end

      syncn[1]: begin
        n_mux[0] = db[6];
        n_mux[1] = db[7];
        n_mux[2] = db[8];
        n_mux[3] = 1'b0;
      end

      syncn[2]: begin
        n_mux[0] = db[12];
        n_mux[1] = db[13];
        n_mux[2] = db[14];
        n_mux[3] = 1'b0;
      end

      syncn[3]: begin
        n_mux[0] = db[18];
        n_mux[1] = db[19];
        n_mux[2] = db[20];
        n_mux[3] = 1'b1;
      end

      syncn[4]: begin
        n_mux[0] = db[24];
        n_mux[1] = db[25];
        n_mux[2] = db[26];
        n_mux[3] = 1'b1;
      end
    endcase
  end

  FD muxn0(.D(n_mux[0]), .C(clkx5not), .Q(dataout[4])) ;
  FD muxn1(.D(n_mux[1]), .C(clkx5not), .Q(dataout[5])) ;
  FD muxn2(.D(n_mux[2]), .C(clkx5not), .Q(dataout[6])) ;
  FD muxn3(.D(n_mux[3]), .C(clkx5not), .Q(dataout[7])) ;

  always @ (*)
  begin
    casex (1'b1) // synthesis parallel_case full_case
      syncp[0]: begin
        p_mux[0] = db[3];
        p_mux[1] = db[4];
        p_mux[2] = db[5];
        p_mux[3] = 1'b0;
      end

      syncp[1]: begin
        p_mux[0] = db[9];
        p_mux[1] = db[10];
        p_mux[2] = db[11];
        p_mux[3] = 1'b0;
      end

      syncp[2]: begin
        p_mux[0] = db[15];
        p_mux[1] = db[16];
        p_mux[2] = db[17];
        p_mux[3] = 1'b1;
      end

      syncp[3]: begin
        p_mux[0] = db[21];
        p_mux[1] = db[22];
        p_mux[2] = db[23];
        p_mux[3] = 1'b1;
      end

      syncp[4]: begin
        p_mux[0] = db[27];
        p_mux[1] = db[28];
        p_mux[2] = db[29];
        p_mux[3] = 1'b1;
      end
    endcase
  end

  FD muxp0(.D(p_mux[0]), .C(clkx5), .Q(dataout[0])) ;
  FD muxp1(.D(p_mux[1]), .C(clkx5), .Q(dataout[1])) ;
  FD muxp2(.D(p_mux[2]), .C(clkx5), .Q(dataout[2])) ;
  FD muxp3(.D(p_mux[3]), .C(clkx5), .Q(dataout[3])) ;

endmodule
