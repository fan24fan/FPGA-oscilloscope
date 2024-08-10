//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           signal_switch
// Last modified Date:  2018/08/20 13:21:44
// Last Version:        V1.0
// Descriptions:        信号转换模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2018/08/20 13:21:54
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module signal_switch #(parameter   WIDTH  = 4'd8             // 一次读写寄存器的个数的位宽
)(
    //module1
    input                           m1_0,
    input                           m1_1,
    input         [15:0]            m1_2,
    input         [ 7:0]            m1_3,
    output   reg  [ 7:0]            m1_4,
    input         [WIDTH-1'b1:0]    m1_5,
    output   reg                    m1_6,
        
    //module2 
    input                           m2_0,
    input                           m2_1,
    input         [15:0]            m2_2,
    input         [ 7:0]            m2_3,
    output   reg  [ 7:0]            m2_4,
    input         [WIDTH-1'b1:0]    m2_5,
    output   reg                    m2_6,
        
    //module2 
    output   reg                    m3_0, 
    output   reg                    m3_1, 
    output   reg  [15:0]            m3_2, 
    output   reg  [ 7:0]            m3_3, 
    input         [ 7:0]            m3_4, 
    output   reg  [WIDTH-1'b1:0]    m3_5, 
    input                           m3_6, 
    
    //ctrl signal
    input                       ctrl_switch         // 切换信号
    
);

//*****************************************************
//**                    main code
//*****************************************************

//信号转换
always @(*) begin
    if(ctrl_switch) begin
        m3_0 = m2_0;
        m3_1 = m2_1;
        m3_2 = m2_2;
        m3_3 = m2_3;
        m2_4 = m3_4;
        m3_5 = m2_5;
        m2_6 = m3_6;
    end
    else begin
        m3_0 = m1_0;
        m3_1 = m1_1;
        m3_2 = m1_2;
        m3_3 = m1_3;
        m1_4 = m3_4;
        m3_5 = m1_5;
        m1_6 = m3_6;
    end 
end

endmodule
