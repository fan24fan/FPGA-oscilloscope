//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           da_wave_gen
// Last modified Date:  2019/3/11 13:04:35
// Last Version:        V1.0
// Descriptions:        产生正弦波形并送到DA
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/11 13:04:35
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module da_wave_gen(
    input           sys_clk,    //时钟
    input           rst_n,      //复位信号，低电平有效

    output          da_clk,     //DA(9708)驱动时钟,最大支持125Mhz时钟
    output [7:0]    da_data     //输出给DA的数据  
    );

//wire define 
wire [7:0] rom_addr;            //ROM读地址
wire [7:0] rom_data;            //ROM读出的数据

//*****************************************************
//**                    main code
//*****************************************************

//ROM存储波形
rom_256x8b  u_rom_256x8b(
    .clock          (sys_clk),
    .address        (rom_addr),
    .q              (rom_data)
    );
    
//DA数据发送
da_wave_send u_da_wave_send(
    .clk            (sys_clk), 
    .rst_n          (rst_n),
    
    .rd_addr        (rom_addr),
    .rd_data        (rom_data),
    
    .da_clk         (da_clk),  
    .da_data        (da_data)
    );

endmodule 