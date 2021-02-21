----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.02.2021 15:45:10
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
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
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use IEEE.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    Port ( i_clk : in std_logic;
           i_rst : in std_logic;
           i_start : in std_logic;
           i_data : in std_logic_vector (7 downto 0);
           o_address : out std_logic_vector (15 downto 0);
           o_done : out std_logic;
           o_en : out std_logic;
           o_we : out std_logic;
           o_data : out std_logic_vector (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is (IDLE, READ_IMG, CALC, WAIT_CLK, WRITE_IMG, DONE, FINISH);
signal curr_state, next_state : state_type := IDLE;
signal curr_address : std_logic_vector (15 downto 0);
signal next_address : std_logic_vector (15 downto 0);
signal max_address : std_logic_vector (15 downto 0);
--signal n_col : integer range 0 to 128 := 0;
--signal n_rig : integer range 0 to 128 := 0;
signal img_size : integer range 0 to 255;
-- signal max : integer range 0 to 255 := 0; -- viene letto e subito dopo usato (?)
signal min : integer range 0 to 255 := 255;
signal delta_value : integer range 1 to 256 := 0;
signal shift_level : integer range 0 to 8 := 0;
signal temp_pixel : integer range 0 to 255 := 0;
signal new_pixel_value : integer range 0 to 255 := 0;

begin
	
project_reti_logiche: process(i_clk, i_rst, i_start)
variable i : integer := 0; -- Inutile(?)
variable temp: integer := 0; --perchè variable e non signal(?)

begin
    
    if i_rst = '1' then
        curr_state <= IDLE;
	
    elsif rising_edge(i_clk) then
        curr_state <= next_state;
        curr_address <= next_address + "0000000000000001";
        o_address <= curr_address;
    
        case curr_state is
        
        --se i_start=1 parte il processo
        when IDLE =>
			o_done <= '0';
			if(i_start = '1') then next_state <= READ_IMG;
				else next_state <= IDLE;
			end if;
			next_address <= "0000000000000000";
        
        --legge i primi due byte che corrispondono rispettivamente al numero di colonne e di righe
        when READ_IMG =>
			o_en <= '1'; 
			o_we <= '0';    -- ridondante(?)
			o_done <= '0';	-- ridondante(?)
        
			if(curr_address = "0000000000000000") then
				n_col <= conv_integer(i_data);
				next_state <= READ_IMG;
			elsif(curr_address = "0000000000000001") then
				n_rig <= conv_integer(i_data);
				next_state <= CALC;
			end if;
        
        --trova il massimo e il minimo valore dei pixel dell'immagine, calcola delta_value
        when CALC =>
			o_en <= '1';
			o_we <= '0';   -- ridondante(?)
			o_done <= '0'; -- ridondante(?)
			if(conv_integer(curr_address) < (n_col*n_rig + 2)) then -- n_col * n_rig  in un registro(?)
				if(conv_integer(i_data) >= max) then max <= conv_integer(i_data); 
				elsif(conv_integer(i_data) <= min) then min <= conv_integer(i_data); 
			end if;
			next_state <= CALC;
			elsif(conv_integer(curr_address) = (n_col*n_rig + 2)) then
				 (?)
			end if;
        
        --calcola lo shift_level
        when WAIT_CLK =>
			o_en <= '0';
			o_we <= '0';
			o_done <= '0';
			-- usare uno std_logic_vector(?) 
		if(delta_value = 0) then shift_level <= 8;
				elsif(delta_value >= 1 and delta_value <= 2) then shift_level <= 7;
				elsif(delta_value >= 3 and delta_value <= 6) then shift_level <= 6;
				elsif(delta_value >= 7 and delta_value <= 14) then shift_level <= 5;
				elsif(delta_value >= 15 and delta_value <= 30) then shift_level <= 4;
				elsif(delta_value >= 31 and delta_value <= 62) then shift_level <= 3;
				elsif(delta_value >= 63 and delta_value <= 126) then shift_level <= 2;
				elsif(delta_value >= 127 and delta_value <= 254) then shift_level <= 1;
				elsif(delta_value = 255) then shift_level <= 0;
				end if;
			end if;
			next_address <= "0000000000000001";
			next_state <= WRITE_IMG;
        
        --scrive in memoria l'immagine equalizzata
        when WRITE_IMG =>
			o_en <= '1';
			o_we <= '1';
			o_done <= '0';
			if(conv_integer(curr_address) < (n_col*n_rig + 2)) then
				temp := (conv_integer(i_data) - min)*(2 ** shift_level);
				if(temp > 255) then temp := 255;
				end if;
				next_state <= WRITE_IMG;
			end if;
			new_pixel_value <= temp;
			o_data <= std_logic_vector(to_unsigned(new_pixel_value, o_data'length));
        
        when DONE =>
			o_en <= '0';
			o_we <= '0';
			o_done <= '1';
			next_state <= FINISH;
        
        when FINISH =>
			o_en <= '0';
			o_we <= '0';
			o_done <= '0';
			next_address <= "0000000000000000";
			next_state <= IDLE;
        
        end case;
    end if;
    end process;
end Behavioral;
