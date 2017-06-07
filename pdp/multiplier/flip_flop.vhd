library ieee;
use ieee.std_logic_1164.all;

entity flip_flop is
	port(
		clk :  in std_logic;
		rst :  in std_logic;
		ce  :  in std_logic;
		d   :  in std_logic;
		q   : out std_logic
	);
end;

architecture logic of flip_flop is
begin
	if rst = '1':
		q <= '0';
	if rising_edge(clk) and ce = '1' then
		q <= d;
	end if;
end;