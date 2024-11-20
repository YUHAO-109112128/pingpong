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

--swR_handling: �k�����s�B�z
swR_handling:process(i_clk, i_rst, i_swR)
begin
    if i_rst = '1' then
        swR_count <= 0;
        swR <= '0';
    elsif i_clk'event and i_clk = '1' then
        if (i_swR = '1') then  --�T�{�k�����s���U
            if swR_count < 100 then  --�u���B�z�ɶ�
                swR_count <= swR_count + 1;
            elsif swR_count = 100 then  --�T�{���U���s���X�@��clk���T��
                swR <= '1';
                swR_count <= swR_count + 1;
            else  --�n��}���s�~�i�H���ĤG��
                swR <= '0';
            end if;
        else  --���s��}�᭫�m�p��
            swR_count <= 0;
            swR <= '0';
        end if;
    end if;
end process;

--swR_handling: �k�����s�B�z
swL_handling:process(i_clk, i_rst, i_swL)
begin
    if i_rst = '1' then
        swL_count <= 0;
        swL <= '0';
    elsif i_clk'event and i_clk = '1' then
        if (i_swL = '1') then  --�T�{�������s���U
            if swL_count < 100 then  --�u���B�z�ɶ�
                swL_count <= swL_count + 1;
            elsif swL_count = 100 then  --�T�{���U���s���X�@��clk���T��
                swL <= '1';
                swL_count <= swL_count + 1;
            else  --�n��}���s�~�i�H���ĤG��
                swL <= '0';
            end if;
        else  --���s��}�᭫�m�p��
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
            when "000" =>  --�M�w�o�y�v
                if swR = '1' then  --�k����o��l�o�y�v�A�k��o�y
                    led_mode <= "001";
                elsif swL = '1' then  --������o��l�o�y�v�A����o�y
                    led_mode <= "100";
                else
                    null;
                end if;
            when "001" =>  -- �k��o�y
                if swR = '1' then  --�k��o�y�A�y������
                    led_mode <= "110";
                else
                    null;
                end if;
            when "010" =>  --�k��o��
                if scoreR = "1111" then  --�k�亡�����ɵ���
                    led_mode <= "111";
                elsif swR = '1' then  --�k��o��f�B���ɩ|�������A�k����o�o�y�v
                    led_mode <= "001";
                else
                    null;
                end if;
            when "011" =>  --�y���k��
                if led = "0000" & "0001" and swR = '1' then  --�y��̥k����������\�A�y���k��
                    led_mode <= "110";
                elsif led = "0000" & "0000" or swR = '1' then  --�y�٥���̥k��N�����άO�k���������ѡA����o��
                    led_mode <= "101";
                else  --�٨S��̥k��A�~��k��
                    led_mode <= "011";
                end if;
            when "100" =>  --����o�y
                if swL = '1' then --����o�y�A�y���k��
                    led_mode <= "011";
                else
                    null;
                end if;
            when "101" =>  --����o��
                if scoreL = "1111" then  --���亡�����ɵ���
                    led_mode <= "111";
                elsif swL = '1' then  --����o��f�B���ɩ|�������A������o�o�y�v
                    led_mode <= "100";
                else
                    null;
                end if;
            when "110" =>  --�y������
                if led = "1000" & "0000" and swL = '1' then  --�y��̥�����������\�A�y���k��
                    led_mode <= "011";
                elsif led = "0000" & "0000" or swL = '1' then  --�y�٥���̥���N�����άO�����������ѡA�k��o��
                    led_mode <= "010";
                else  --�٨S��̥���A�~�򥪲�
                    led_mode <= "110";
                end if;
            when "111" =>  --���ɵ���
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
            when "000" =>  --�M�w�o�y�v
                led <= "0000" & "0000";
            when "001" =>  -- �k��o�y
                led <= "0000" & "0001";
            when "010" =>  --�k��o��
                led <= scoreL & scoreR;
            when "011" =>  --�y���k��
                if led = "0000" & "0000" then
                    null;
                else
                    led <= '0' & led(7 downto 1);
                end if;
            when "100" =>  --����o�y
                led <= "1000" & "0000";
            when "101" =>  --����o��
                led <= scoreL & scoreR;
            when "110" =>  --�y������
                if led = "0000" & "0000" then
                    null;
                else
                    led <= led(6 downto 0) & '0';
                end if;
            when "111" =>  --���ɵ���
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
            when "000" =>  --�M�w�o�y�v
                null;
            when "001" =>  -- �k��o�y
                null;
            when "010" =>  --�k��o��
                if prev_led_mode = "110" then
                    scoreR <= scoreR + '1';
                else
                    null;
                end if;
            when "011" =>  --�y���k��
                null;
            when "100" =>  --����o�y
                null;
            when "101" =>  --����o��
                if prev_led_mode = "011" then
                    scoreL <= scoreL + '1';
                else
                    null;
                end if;
            when "110" =>  --�y������
                null;
            when "111" =>  --���ɵ���
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
