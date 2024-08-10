//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           decimator
// Last modified Date:  2019/3/10 14:56:35
// Last Version:        V1.0
// Descriptions:        对输入的AD数据进行抽样
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/10 14:56:35
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module decimator(
    input       ad_clk,
    input       rst_n,
    
    input [9:0] deci_rate, 
    output reg  deci_valid
);

//reg define
reg [9:0] deci_cnt;         // 抽样计数器

//*****************************************************
//**                    main code
//*****************************************************

//抽样计数器计数
always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        deci_cnt <= 10'd0;
    else
        if(deci_cnt == deci_rate-1)
            deci_cnt <= 10'd0;
        else
            deci_cnt <= deci_cnt + 1'b1;
end

//输出抽样有效信号
always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        deci_valid <= 1'b0;
    else
        if(deci_cnt == deci_rate-1)
            deci_valid <= 1'b1;
        else
            deci_valid <= 1'b0;    
end

endmodule 