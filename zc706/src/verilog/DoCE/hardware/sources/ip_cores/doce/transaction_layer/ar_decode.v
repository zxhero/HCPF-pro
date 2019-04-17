
`timescale 1ns / 1ps

module ar_decode
(
    input  wire              reset,
    input  wire              clk,

    input  wire [48:0]       phy_base_0,
    input  wire [48:0]       phy_base_1,


    input  wire [83:0]       ar_user,
    input  wire              ar_user_valid,
    output wire              ar_user_ready,

    output reg  [79:0]       ar = 80'b 0,
    output reg               ar_valid=1'b 0,
    input  wire              ar_ready
);

assign    ar_user_ready = (~reset) & ((~ar_valid) | ar_ready); 


reg [79:0]     next_ar = 80'b0;
reg            next_ar_valid = 1'b 0;



always @(posedge clk)
begin

   if (reset)
   begin
       ar          <=  80'b 0;
       ar_valid    <= 1'b 0;
   end
   else
   begin
       ar          <= next_ar;
       ar_valid    <= next_ar_valid;
   end
end


always @(reset            or
         ar               or
         ar_valid         or
         ar_user_valid    or
         ar_user_ready    or
         phy_base_0       or
         phy_base_1       or
         ar_ready         or
         ar_user 
         )
begin
    next_ar           <= ar;
    next_ar_valid     <= ar_valid;
    if (reset)
    begin
        next_ar          <=  80'b 0;
        next_ar_valid    <= 1'b 0;
    end
    else if (ar_user_valid & ar_user_ready)
    begin
        next_ar[3:0]       <= ar_user[3:0];
        next_ar[79:48]     <= ar_user[83:52];
        if ((ar_user[7:4]==phy_base_0[47:44]) & phy_base_0[48])
        begin
            next_ar[47:4]      <= ar_user[51:8] | phy_base_0[43:0];
            next_ar_valid      <= 1'b 1;
        end
        else if ((ar_user[7:4]==phy_base_1[47:44]) & phy_base_1[48])
        begin
            next_ar[47:4]      <= ar_user[51:8] | phy_base_1[43:0];
            next_ar_valid      <= 1'b 1;
        end
        else
        begin
            next_ar[47:4]      <= 44'b 0;
            next_ar_valid      <= 1'b 0;
        end
    end
    else
    begin
        next_ar_valid   <= ar_valid & (~ar_ready);
    end
   
end

endmodule
