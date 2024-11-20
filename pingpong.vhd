----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/11/08 18:08:27
-- Design Name: 
-- Module Name: pingpong - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pingpong is
    Port ( i_rst : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           i_swL : in STD_LOGIC;
           i_swR : in STD_LOGIC;
           o_led : out STD_LOGIC_VECTOR (7 downto 0));
end pingpong;

architecture Behavioral of pingpong is
signal swL : STD_LOGIC;
signal swR : STD_LOGIC;
signal swR_count : integer;
signal swL_count : integer;
constant sw_count_cycle : integer := 100;

signal led_mode : STD_LOGIC_VECTOR (2 downto 0);
signal prev_led_mode : STD_LOGIC_VECTOR (2 downto 0);

signal scoreL : STD_LOGIC_VECTOR (3 downto 0);
signal scoreR : STD_LOGIC_VECTOR (3 downto 0);

signal led : STD_LOGIC_VECTOR (7 downto 0);

signal divclk: STD_LOGIC;
signal divcnt: INTEGER := 0;
constant divisor : INTEGER := 20000000;
begin
o_led <= led;

--swR_handling: 右側按鈕處理
swR_handling:process(i_clk, i_rst, i_swR)
begin
    if i_rst = '1' then
        swR_count <= 0;
        swR <= '0';
    elsif i_clk'event and i_clk = '1' then
        if (i_swR = '1') then  --確認右側按鈕按下
            if swR_count < 100 then  --彈跳處理時間
                swR_count <= swR_count + 1;
            elsif swR_count = 100 then  --確認按下按鈕後輸出一個clk的訊號
                swR <= '1';
                swR_count <= swR_count + 1;
            else  --要放開按鈕才可以按第二次
                swR <= '0';
            end if;
        else  --按鈕放開後重置計數
            swR_count <= 0;
            swR <= '0';
        end if;
    end if;
end process;

--swR_handling: 右側按鈕處理
swL_handling:process(i_clk, i_rst, i_swL)
begin
    if i_rst = '1' then
        swL_count <= 0;
        swL <= '0';
    elsif i_clk'event and i_clk = '1' then
        if (i_swL = '1') then  --確認左側按鈕按下
            if swL_count < 100 then  --彈跳處理時間
                swL_count <= swL_count + 1;
            elsif swL_count = 100 then  --確認按下按鈕後輸出一個clk的訊號
                swL <= '1';
                swL_count <= swL_count + 1;
            else  --要放開按鈕才可以按第二次
                swL <= '0';
            end if;
        else  --按鈕放開後重置計數
            swL_count <= 0;
            swL <= '0';
        end if;
    end if;
end process;

FSM:process(i_clk, i_rst, swL, swR, scoreL, scoreR, led)
begin
    if i_rst = '1' then
        led_mode <= "000";
    elsif i_clk'event and i_clk = '1' then
        case led_mode is
            when "000" =>  --決定發球權
                if swR = '1' then  --右邊取得初始發球權，右邊發球
                    led_mode <= "001";
                elsif swL = '1' then  --左邊取得初始發球權，左邊發球
                    led_mode <= "100";
                else
                    null;
                end if;
            when "001" =>  -- 右邊發球
                if swR = '1' then  --右邊發球，球往左移
                    led_mode <= "110";
                else
                    null;
                end if;
            when "010" =>  --右邊得分
                if scoreR = "1111" then  --右邊滿分比賽結束
                    led_mode <= "111";
                elsif swR = '1' then  --右邊得分f且比賽尚未結束，右邊取得發球權
                    led_mode <= "001";
                else
                    null;
                end if;
            when "011" =>  --球往右移
                if led = "0000" & "0001" and swR = '1' then  --球到最右邊後擊打成功，球往右移
                    led_mode <= "110";
                elsif led = "0000" & "0000" or swR = '1' then  --球還未到最右邊就擊打或是右邊擊打失敗，左邊得分
                    led_mode <= "101";
                else  --還沒到最右邊，繼續右移
                    led_mode <= "011";
                end if;
            when "100" =>  --左邊發球
                if swL = '1' then --左邊發球，球往右移
                    led_mode <= "011";
                else
                    null;
                end if;
            when "101" =>  --左邊得分
                if scoreL = "1111" then  --左邊滿分比賽結束
                    led_mode <= "111";
                elsif swL = '1' then  --左邊得分f且比賽尚未結束，左邊取得發球權
                    led_mode <= "100";
                else
                    null;
                end if;
            when "110" =>  --球往左移
                if led = "1000" & "0000" and swL = '1' then  --球到最左邊後擊打成功，球往右移
                    led_mode <= "011";
                elsif led = "0000" & "0000" or swL = '1' then  --球還未到最左邊就擊打或是左邊擊打失敗，右邊得分
                    led_mode <= "010";
                else  --還沒到最左邊，繼續左移
                    led_mode <= "110";
                end if;
            when "111" =>  --比賽結束
                null;
            when others =>
                led_mode <= "000";
        end case;
    end if;
end process;


led_reg:process(divclk, i_rst, swL, swR, scoreL, scoreR)
begin
    if i_rst = '1' then
        led <= "0000" & "0000";
    elsif divclk'event and divclk = '1' then
        case led_mode is
            when "000" =>  --決定發球權
                led <= "0000" & "0000";
            when "001" =>  -- 右邊發球
                led <= "0000" & "0001";
            when "010" =>  --右邊得分
                led <= scoreL & scoreR;
            when "011" =>  --球往右移
                if led = "0000" & "0000" then
                    null;
                else
                    led <= '0' & led(7 downto 1);
                end if;
            when "100" =>  --左邊發球
                led <= "1000" & "0000";
            when "101" =>  --左邊得分
                led <= scoreL & scoreR;
            when "110" =>  --球往左移
                if led = "0000" & "0000" then
                    null;
                else
                    led <= led(6 downto 0) & '0';
                end if;
            when "111" =>  --比賽結束
                if scoreL = "1111" then
                    led <= "1111" & "0000";
                end if;
                if scoreR = "1111" then
                    led <= "0000" & "1111";
                end if;
            when others =>
        end case;
    end if;
end process;

score_sign:process(i_rst, divclk, led_mode)
begin
    if i_rst = '1' then
        scoreL <= "0000";
        scoreR <= "0000";
    elsif divclk'event and divclk = '1' then
        prev_led_mode <= led_mode;
        case led_mode is
            when "000" =>  --決定發球權
                null;
            when "001" =>  -- 右邊發球
                null;
            when "010" =>  --右邊得分
                if prev_led_mode = "110" then
                    scoreR <= scoreR + '1';
                else
                    null;
                end if;
            when "011" =>  --球往右移
                null;
            when "100" =>  --左邊發球
                null;
            when "101" =>  --左邊得分
                if prev_led_mode = "011" then
                    scoreL <= scoreL + '1';
                else
                    null;
                end if;
            when "110" =>  --球往左移
                null;
            when "111" =>  --比賽結束
                scoreL <= "0000";
                scoreR <= "0000";
            when others =>
                null;
        end case;
    end if;
end process;

division: process(i_clk, i_rst, divcnt)
begin
    if i_rst = '1' then
        divcnt <= 0;
        divclk <= '0';
    elsif i_clk'event and i_clk = '1' then
        if divcnt = (divisor/2) - 1 then
            divcnt <= 0;
            divclk <= not divclk;
        else
            divcnt <= divcnt + 1;
        end if;
    end if;
end process;

RND: process(divclk, i_rst)
begin
end process;

end Behavioral;
