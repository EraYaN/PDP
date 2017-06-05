library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity dadda_mult_test is
end dadda_mult_test;
 
architecture behavior of dadda_mult_test is

	component dadda_mult
		port(
			sgn    : in  std_logic;
			a, b   : in  std_logic_vector(31 downto 0);
			c_mult : out std_logic_vector(63 downto 0)
		);
	end component;

	--Inputs
	signal a   : std_logic_vector(31 downto 0) := (others => '0');
	signal b   : std_logic_vector(31 downto 0) := (others => '0');
	signal sgn : std_logic := '0';

	--Outputs
	signal c_mult : std_logic_vector(63 downto 0);

begin
 
	-- Instantiate the Unit Under Test (UUT)
	UUT: dadda_mult port map (a => a, b => b, sgn => sgn, c_mult => c_mult);

	-- Stimulus process
	stim_proc: process
	begin
		wait for 10 ns;
		sgn <= '0';
		a <= std_logic_vector(to_unsigned(123, a'length));
		b <= std_logic_vector(to_unsigned(456, b'length));

		wait for 10 ns;
		a <= std_logic_vector(to_unsigned(1234567890, a'length));
		b <= std_logic_vector(to_unsigned(3, b'length));

		wait for 10 ns;
		if (unsigned(c_mult) /= X"00000000DCC20876") then
			report "Multiplication result: 1234567890 * 3 != 3703703670"
			severity failure;
		end if;

		wait for 10 ns;
		a <= std_logic_vector(to_unsigned(1234567890, a'length));
		b <= std_logic_vector(to_unsigned(1234567890, b'length));
		
		wait for 10 ns;
		if (unsigned(c_mult) /= X"1526E583121FF444") then
			report "Multiplication result: 1234567890 * 1234567890 --> 1524157875019052100"
			severity failure;
		end if;

		wait for 10 ns;
		sgn <= '1';
		a <= std_logic_vector(to_signed(-123, a'length));
		b <= std_logic_vector(to_signed(-456, b'length));

		wait for 10 ns;
		if (signed(c_mult) /= X"000000000000DB18") then
			report "Multiplication result: -123 * -456 != 56088"
			severity failure;
		end if;

		wait for 10 ns;
		a <= std_logic_vector(to_signed(-123456789, a'length));
		b <= std_logic_vector(to_signed(3, b'length));

		wait for 10 ns;
		if (signed(c_mult) /= X"FFFFFFFFE9EC98C1") then
			report "Multiplication result: -123456789 * 3 != -370370367"
			severity failure;
		end if;

		a <= std_logic_vector(to_signed(123456789, a'length));
		b <= std_logic_vector(to_signed(-123456789, b'length));

		wait for 10 ns;
		if (signed(c_mult) /= X"FFC9D9DD68C75C47") then
			report "Multiplication result: 123456789 * -123456789 --> -1524157875019052100"
			severity failure;
		end if;

		-- End of simulation
		wait for 10 ns;
		assert false report "Simulation ended" severity note;
		wait for 1 sec;
	end process;

end;
