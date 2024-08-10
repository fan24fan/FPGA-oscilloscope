//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           clk_div
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        对不同型号的屏幕产生一一对应的时钟
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module clk_div(
    input               clk_25m,
    input               clk_12_5m,   
    input               rst_n,
    input       [15:0]  lcd_id,
    output              lcd_pclk
    );

assign lcd_pclk = (lcd_id == 16'h4342) ?   clk_12_5m :  clk_25m;

endmodule
