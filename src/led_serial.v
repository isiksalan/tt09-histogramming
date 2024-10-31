`define k1(i,j,k) (31-(k + 4*j + 16*i))*4
`define k2(i,j)    (15-(j + 4*i))*4

`define keyn(i,j,k)      key[`k1(i,j,k)+3:`k1(i,j,k)]
`define keyn_next(i,j,k) key_next[`k1(i,j,k)+3:`k1(i,j,k)]

`define staten(i,j)      state[`k2(i,j)+3:`k2(i,j)]
`define staten_next(i,j) state_next[`k2(i,j)+3:`k2(i,j)]

module led_serial
   (clk,	
    reset,
    keyi,	
    datai,	
    dataq,
    start,
    loadkey,
    loadpt,
    getct,
    done);
   
   input  clk;
   input  reset;
   
   input  keyi;
   input  datai;
   output dataq;
   
   input  loadkey;
   input  loadpt;
   input  getct;
   input  start;
   output done;
   
   // state
   reg [ 63:0] state, state_next;
   reg [127:0] key, key_next;
   reg [  5:0] rc, rc_next;
   
   parameter   CMD_IDLE          = 4'h0;
   parameter   CMD_HOLD          = 4'h1;
   parameter   CMD_LOADKEY       = 4'h2;
   parameter   CMD_LOADPT        = 4'h3;
   parameter   CMD_GETCT         = 4'h4;
   parameter   CMD_ADDKEY        = 4'h5;
   parameter   CMD_SBOX          = 4'h6;
   parameter   CMD_SHIFTROW      = 4'h7;
   parameter   CMD_MIXCOLCOMPUTE = 4'h8;
   parameter   CMD_MIXCOLROTATE  = 4'h9;
   reg [3:0]   cmd;
   
   parameter   STATE_IDLE     = 4'h0;
   parameter   STATE_INIT     = 4'h1;
   parameter   STATE_ROUND    = 4'h2;
   parameter   STATE_SHIFTROW = 4'h3;
   parameter   STATE_MIXCOL0  = 4'h4;
   parameter   STATE_MIXCOL1  = 4'h5;
   parameter   STATE_MIXCOL2  = 4'h6;
   parameter   STATE_MIXCOL3  = 4'h7;
   parameter   STATE_MIXCOL4  = 4'h8;
   parameter   STATE_NEXTROUND = 4'h9;
   parameter   STATE_ADDKEY   = 4'hA;
   parameter   STATE_NEXTSTEP = 4'hB;
   reg [3:0]   ctlstate, ctlstate_next;
   
   reg [3:0]   bcount, bcount_next;  // byte counter
   reg [3:0]   rcount, rcount_next;  // round counter
   reg [3:0]   scount, scount_next;  // step counter
   
   function [3:0] sbox;
      input [3:0] index;
      case (index)
	4'h0: sbox = 4'd12;
	4'h1: sbox = 4'd5;
	4'h2: sbox = 4'd6;
	4'h3: sbox = 4'd11;
	4'h4: sbox = 4'd9;
	4'h5: sbox = 4'd0;
	4'h6: sbox = 4'd10;
	4'h7: sbox = 4'd13;
	4'h8: sbox = 4'd3;
	4'h9: sbox = 4'd14;
	4'ha: sbox = 4'd15;
	4'hb: sbox = 4'd8;
	4'hc: sbox = 4'd4;
	4'hd: sbox = 4'd7;
	4'he: sbox = 4'd1;
	4'hf: sbox = 4'd2;
      endcase // case (index)
   endfunction
   
   function [3:0] logic_round;
      input [3:0] d;
      input [3:0] k;
      logic_round = sbox(d ^ k);
   endfunction // sbox
   
   function [3:0] logic_addconst_decode;
      input [3:0] d;
      case (d)
	4'h0: logic_addconst_decode = 8;
	4'h1: logic_addconst_decode = {1'b0,rc[5:3]};
	4'h2: logic_addconst_decode = 0;
	4'h3: logic_addconst_decode = 0;
	4'h4: logic_addconst_decode = 9;
	4'h5: logic_addconst_decode = {1'b0,rc[2:0]};
	4'h6: logic_addconst_decode = 0;
	4'h7: logic_addconst_decode = 0;
	4'h8: logic_addconst_decode = 2;
	4'h9: logic_addconst_decode = {1'b0,rc[5:3]};
	4'ha: logic_addconst_decode = 0;
	4'hb: logic_addconst_decode = 0;
	4'hc: logic_addconst_decode = 3;
	4'hd: logic_addconst_decode = {1'b0,rc[2:0]};
	4'he: logic_addconst_decode = 0;
	4'hf: logic_addconst_decode = 0;
      endcase // case (d)
   endfunction
   
   function automatic [3:0] logic_fmul2;
      input [3:0] d;
      logic_fmul2 = {d[2],d[1],d[3]^d[0],d[3]};
   endfunction // sbox
   
   function [3:0] logic_fmul4;
      input [3:0] d;
      logic_fmul4 = logic_fmul2(logic_fmul2(d));
   endfunction // sbox
   
   always @(posedge clk, negedge reset)
     if (reset == 1'b0)
       begin
		  ctlstate <= STATE_IDLE;
		  key      <= 128'h0;
		  state    <= 64'h0;
		  rc       <= 6'h1;
		  bcount   <= 4'h0;
		  rcount   <= 4'h0;
		  scount   <= 4'h0;	  
       end
     else
       begin
		  ctlstate <= ctlstate_next;
		  key      <= key_next;
		  state    <= state_next;
		  rc       <= rc_next;
		  bcount   <= bcount_next;
		  rcount   <= rcount_next;
		  scount   <= scount_next;	  
       end
   
   // control logic
   always @(*)
     begin
		
		// default
		bcount_next   = bcount;
		rcount_next   = rcount;
		scount_next   = scount;
		ctlstate_next = ctlstate;
		cmd           = CMD_HOLD;
		
		case (ctlstate)
		  STATE_IDLE:
			begin
			   cmd = loadkey ? CMD_LOADKEY :
					 loadpt      ? CMD_LOADPT :
					 getct       ? CMD_GETCT :
					 CMD_IDLE;
			   bcount_next = 4'h0;
			   rcount_next = 4'h0;
			   scount_next = 4'h0;
			   ctlstate_next = start ? STATE_INIT : STATE_IDLE;	       
			end
		  STATE_INIT:
			begin
			   cmd = CMD_ADDKEY;
			   
			   bcount_next = (bcount == 4'hf) ? 4'h0 : (bcount + 1);
			   ctlstate_next = (bcount == 4'hf) ? STATE_ROUND : STATE_INIT;	       
			end
		  STATE_ROUND:
			begin
			   cmd = CMD_SBOX;
			   
			   bcount_next = (bcount == 4'hf) ? 4'h0 : (bcount + 1);
			   ctlstate_next = (bcount == 4'hf) ? STATE_SHIFTROW : STATE_ROUND;	       
			end
		  STATE_SHIFTROW:
			begin
			   cmd = CMD_SHIFTROW;
			   
			   ctlstate_next = STATE_MIXCOL0;	       
			end
		  STATE_MIXCOL0:
			begin
			   cmd = CMD_MIXCOLCOMPUTE;
			   
			   ctlstate_next = STATE_MIXCOL1;	       
			end
		  STATE_MIXCOL1:
			begin
			   cmd = CMD_MIXCOLCOMPUTE;
			   
			   ctlstate_next = STATE_MIXCOL2;	       
			end
		  STATE_MIXCOL2:
			begin
			   cmd = CMD_MIXCOLCOMPUTE;
			   
			   ctlstate_next = STATE_MIXCOL3;	       
			end
		  STATE_MIXCOL3:
			begin
			   cmd = CMD_MIXCOLCOMPUTE;
			   
			   ctlstate_next = STATE_MIXCOL4;	       
			end
		  STATE_MIXCOL4:
			begin
			   cmd = CMD_MIXCOLROTATE;
			   
			   bcount_next = (bcount == 4'h3) ? 4'h0 : (bcount + 1);
			   ctlstate_next = (bcount == 4'h3) ? STATE_NEXTROUND : STATE_MIXCOL0;
			end
		  STATE_NEXTROUND:
			begin
			   rcount_next = (rcount == 4'h3) ? 4'h0 : (rcount + 1);
			   ctlstate_next = (rcount == 4'h3) ? STATE_ADDKEY : STATE_ROUND;
			end
		  STATE_ADDKEY:
			begin
			   cmd = CMD_ADDKEY;
			   
			   bcount_next = (bcount == 4'hf) ? 4'h0 : (bcount + 1);
			   ctlstate_next = (bcount == 4'hf) ? STATE_NEXTSTEP : STATE_ADDKEY;
			end
		  STATE_NEXTSTEP:
			begin
			   scount_next = (scount == 4'hb) ? 4'h0 : (scount + 1);
			   ctlstate_next = (scount == 4'hb) ? STATE_IDLE : STATE_ROUND;	       
			end
		  default:
			begin
			   ctlstate_next = STATE_IDLE;
			end
		endcase // case (state)
     end
   
   assign done = (ctlstate == STATE_IDLE);
   assign dataq = state[63];   
   
   // datapath
   always @(*)
     begin
		// default
		state_next = state;
		key_next      = key;
 		rc_next       = rc;
		case (cmd)
		  CMD_IDLE:
			begin
			   rc_next     = 6'h1;
			end
		  CMD_HOLD:
			begin
			end
		  CMD_LOADKEY:
			begin
			   // key_next   = {key[126:0],keyi};
			   // LIMITATION - FORCE KEY BIT TO 0 UPON LOADING
			   key_next   = {key[126:0],1'b0};
			end
		  CMD_LOADPT:
			begin
			   state_next = {state_next[62:0],datai};
			end
		  CMD_GETCT:
			begin
			   state_next = {state_next[62:0],1'b0};
			end
		  CMD_ADDKEY:
			begin
			   `staten_next(3,3) = `staten(0,0) ^ `keyn(0,0,0);
			   `staten_next(3,2) = `staten(3,3);
			   `staten_next(3,1) = `staten(3,2);
			   `staten_next(3,0) = `staten(3,1);    
			   `staten_next(2,3) = `staten(3,0);
			   `staten_next(2,2) = `staten(2,3);
			   `staten_next(2,1) = `staten(2,2);
			   `staten_next(2,0) = `staten(2,1);
			   `staten_next(1,3) = `staten(2,0);
			   `staten_next(1,2) = `staten(1,3);
			   `staten_next(1,1) = `staten(1,2);
			   `staten_next(1,0) = `staten(1,1);
			   `staten_next(0,3) = `staten(1,0);
			   `staten_next(0,2) = `staten(0,3);
			   `staten_next(0,1) = `staten(0,2);
			   `staten_next(0,0) = `staten(0,1);
			   
			   `keyn_next(0,0,0) = `keyn(0,0,1); 
			   `keyn_next(0,0,1) = `keyn(0,0,2); 
			   `keyn_next(0,0,2) = `keyn(0,0,3); 
			   `keyn_next(0,0,3) = `keyn(0,1,0); 
			   `keyn_next(0,1,0) = `keyn(0,1,1); 
			   `keyn_next(0,1,1) = `keyn(0,1,2); 
			   `keyn_next(0,1,2) = `keyn(0,1,3); 
			   `keyn_next(0,1,3) = `keyn(0,2,0); 
			   `keyn_next(0,2,0) = `keyn(0,2,1); 
			   `keyn_next(0,2,1) = `keyn(0,2,2); 
			   `keyn_next(0,2,2) = `keyn(0,2,3); 
			   `keyn_next(0,2,3) = `keyn(0,3,0); 
			   `keyn_next(0,3,0) = `keyn(0,3,1); 
			   `keyn_next(0,3,1) = `keyn(0,3,2); 
			   `keyn_next(0,3,2) = `keyn(0,3,3); 
			   `keyn_next(0,3,3) = `keyn(1,0,0); 
			   `keyn_next(1,0,0) = `keyn(1,0,1); 
			   `keyn_next(1,0,1) = `keyn(1,0,2); 
			   `keyn_next(1,0,2) = `keyn(1,0,3); 
			   `keyn_next(1,0,3) = `keyn(1,1,0); 
			   `keyn_next(1,1,0) = `keyn(1,1,1); 
			   `keyn_next(1,1,1) = `keyn(1,1,2); 
			   `keyn_next(1,1,2) = `keyn(1,1,3); 
			   `keyn_next(1,1,3) = `keyn(1,2,0); 
			   `keyn_next(1,2,0) = `keyn(1,2,1); 
			   `keyn_next(1,2,1) = `keyn(1,2,2); 
			   `keyn_next(1,2,2) = `keyn(1,2,3); 
			   `keyn_next(1,2,3) = `keyn(1,3,0); 
			   `keyn_next(1,3,0) = `keyn(1,3,1); 
			   `keyn_next(1,3,1) = `keyn(1,3,2); 
			   `keyn_next(1,3,2) = `keyn(1,3,3); 
			   `keyn_next(1,3,3) = `keyn(0,0,0);
			end
		  CMD_SBOX:
			begin
			   `staten_next(3,3) = logic_round(`staten(0,0), logic_addconst_decode(bcount));
			   `staten_next(3,2) = `staten(3,3);
			   `staten_next(3,1) = `staten(3,2);
			   `staten_next(3,0) = `staten(3,1);    
			   `staten_next(2,3) = `staten(3,0);
			   `staten_next(2,2) = `staten(2,3);
			   `staten_next(2,1) = `staten(2,2);
			   `staten_next(2,0) = `staten(2,1);
			   `staten_next(1,3) = `staten(2,0);
			   `staten_next(1,2) = `staten(1,3);
			   `staten_next(1,1) = `staten(1,2);
			   `staten_next(1,0) = `staten(1,1);
			   `staten_next(0,3) = `staten(1,0);
			   `staten_next(0,2) = `staten(0,3);
			   `staten_next(0,1) = `staten(0,2);
			   `staten_next(0,0) = `staten(0,1);
			end
		  CMD_SHIFTROW:
			begin
			   rc_next = {rc[4:0], (1'b1 ^ rc[4] ^ rc[5])};
			   `staten_next(0,0) = `staten(0,0);
			   `staten_next(0,1) = `staten(0,1);
			   `staten_next(0,2) = `staten(0,2);
			   `staten_next(0,3) = `staten(0,3);
			   `staten_next(1,0) = `staten(1,1);
			   `staten_next(1,1) = `staten(1,2);
			   `staten_next(1,2) = `staten(1,3);
			   `staten_next(1,3) = `staten(1,0);
			   `staten_next(2,0) = `staten(2,2);
			   `staten_next(2,1) = `staten(2,3);
			   `staten_next(2,2) = `staten(2,0);
			   `staten_next(2,3) = `staten(2,1);
			   `staten_next(3,0) = `staten(3,3);
			   `staten_next(3,1) = `staten(3,0);
			   `staten_next(3,2) = `staten(3,1);
			   `staten_next(3,3) = `staten(3,2);	       
			end
		  CMD_MIXCOLCOMPUTE:
			begin
			   `staten_next(0,0) = `staten(1,0);
			   `staten_next(1,0) = `staten(2,0);
			   `staten_next(2,0) = `staten(3,0);
			   `staten_next(3,0) = logic_fmul4(`staten(0,0)) ^
								   `staten(1,0) ^
								   logic_fmul2(`staten(2,0)) ^
								   logic_fmul2(`staten(3,0));
			end
		  CMD_MIXCOLROTATE:
			begin
			   `staten_next(0,0) = `staten(0,1);
			   `staten_next(0,1) = `staten(0,2);
			   `staten_next(0,2) = `staten(0,3);
			   `staten_next(0,3) = `staten(0,0);
			   `staten_next(1,0) = `staten(1,1);
			   `staten_next(1,1) = `staten(1,2);
			   `staten_next(1,2) = `staten(1,3);
			   `staten_next(1,3) = `staten(1,0);
			   `staten_next(2,0) = `staten(2,1);
			   `staten_next(2,1) = `staten(2,2);
			   `staten_next(2,2) = `staten(2,3);
			   `staten_next(2,3) = `staten(2,0);
			   `staten_next(3,0) = `staten(3,1);
			   `staten_next(3,1) = `staten(3,2);
			   `staten_next(3,2) = `staten(3,3);
			   `staten_next(3,3) = `staten(3,0);
			end // case: CMD_MIXCOLROTATE
		  default:
			begin
			end	    
		endcase
     end
   
endmodule
