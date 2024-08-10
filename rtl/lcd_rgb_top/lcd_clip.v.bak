//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_clip
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        LCD裁剪模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lcd_clip(
    input                clk,            //时钟
    input                rst_n,          //复位，低电平有效
    
    input        [15:0]  lcd_id,         //LCD屏ID
    input                data_req,       //请求数据信号    
    input        [10:0]  pixel_xpos,     //当前像素点横坐标
    input        [10:0]  pixel_ypos,     //当前像素点纵坐标    
    output               clip_data_req,  //裁剪后的请求数据信号
    output       [8:0]   clip_pixel_xpos,//裁剪后的像素点横坐标
    output       [8:0]   clip_pixel_ypos //裁剪后的像素点纵坐标
    );

//reg define
reg          clip_data_req_t ;
reg  [8:0]   clip_pixel_xpos_t;
reg  [8:0]   clip_pixel_ypos_t;  
reg          clip_data_req_d0 ;
reg  [8:0]   clip_pixel_xpos_d0;
reg  [8:0]   clip_pixel_ypos_d0;
    
//*****************************************************
//**                    main code
//*****************************************************    

//如果是4.3寸480*272的LCD屏,则不做任何裁剪
assign clip_data_req = (lcd_id == 16'h4342) ?  data_req : clip_data_req_d0;
assign clip_pixel_xpos = (lcd_id == 16'h4342) ? pixel_xpos : clip_pixel_xpos_d0;
assign clip_pixel_ypos = (lcd_id == 16'h4342) ? pixel_ypos : clip_pixel_ypos_d0;

//根据LCD ID进行裁剪,只输出中间480*272分辨率的请求信号和坐标点
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clip_data_req_t <= 1'b0;
        clip_pixel_xpos_t <= 1'b0;
        clip_pixel_ypos_t <= 1'b0;
    end
    else begin
        case(lcd_id)
            16'h4384,16'h7084 : begin
                if(pixel_xpos >= 11'd160 && pixel_xpos < 11'd640 
                   && pixel_ypos >= 11'd104 && pixel_ypos < 11'd376) begin
                   clip_data_req_t <= 1'b1;
                   clip_pixel_xpos_t <= pixel_xpos - 11'd160;
                   clip_pixel_ypos_t <= pixel_ypos - 11'd104 + 1'b1;                   
                end
                else begin
                    clip_data_req_t <= 1'b0;
                    clip_pixel_xpos_t <= 1'b0;
                    clip_pixel_ypos_t <= 1'b0;
                end                
            end
            16'h7016 : begin
                if(pixel_xpos >= 11'd272 && pixel_xpos < 11'd752 
                   && pixel_ypos >= 11'd164 && pixel_ypos < 11'd436) begin
                   clip_data_req_t <= 1'b1;
                   clip_pixel_xpos_t <= pixel_xpos - 11'd272;
                   clip_pixel_ypos_t <= pixel_ypos - 11'd164 + 1'b1;                   
                end
                else begin
                    clip_data_req_t <= 1'b0;
                    clip_pixel_xpos_t <= 1'b0;
                    clip_pixel_ypos_t <= 1'b0;
                end                 
            end 
            default : begin
                clip_data_req_t <= 1'b0;
                clip_pixel_xpos_t <= 1'b0;
                clip_pixel_ypos_t <= 1'b0;
            end  
        endcase            
    end
end

//寄存输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clip_data_req_d0 <= 1'b0;
        clip_pixel_xpos_d0 <= 1'b0;
        clip_pixel_ypos_d0 <= 1'b0;
    end
    else begin
        clip_data_req_d0 <= clip_data_req_t;
        clip_pixel_xpos_d0 <= clip_pixel_xpos_t;
        clip_pixel_ypos_d0 <= clip_pixel_ypos_t;
    end    
end

endmodule
