library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity dadda_mult_test is
end dadda_mult_test;
 
architecture behavior of dadda_mult_test is

	component dadda_mult
		port(
			clk    : in  std_logic;
			rst    : in  std_logic;
			ce     : in  std_logic;
			sgn    : in  std_logic;
			a, b   : in  std_logic_vector(31 downto 0);
			c_mult : out std_logic_vector(63 downto 0)
		);
	end component;

	--Inputs
	signal a   : std_logic_vector(31 downto 0) := (others => '0');
	signal b   : std_logic_vector(31 downto 0) := (others => '0');
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal ce  : std_logic := '0';
	signal sgn : std_logic := '0';

	--Outputs
	signal c_mult : std_logic_vector(63 downto 0);

	--Clock
	constant clk_period : time := 10 ns;
	
begin

	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
 
	-- Instantiate the Unit Under Test (UUT)
	UUT: dadda_mult port map (clk => clk, rst => rst, ce => ce, a => a, b => b, sgn => sgn, c_mult => c_mult);

	-- Stimulus process
	stim_proc: process
	begin
		wait for clk_period * 5;
		rst <= '0';
		ce <= '1';
		wait for clk_period * 5;

		sgn <= '0';
		a <= std_logic_vector(to_unsigned(123, a'length));
		b <= std_logic_vector(to_unsigned(456, b'length));

		wait for clk_period;
		a <= std_logic_vector(to_unsigned(1234567890, a'length));
		b <= std_logic_vector(to_unsigned(3, b'length));

		wait for clk_period;
		if (unsigned(c_mult) /= X"00000000DCC20876") then
			report "Multiplication result: 1234567890 * 3 != 3703703670"
			severity failure;
		end if;

		wait for clk_period;
		a <= std_logic_vector(to_unsigned(1234567890, a'length));
		b <= std_logic_vector(to_unsigned(1234567890, b'length));
		
		wait for clk_period;
		if (unsigned(c_mult) /= X"1526E583121FF444") then
			report "Multiplication result: 1234567890 * 1234567890 != 1524157875019052100"
			severity failure;
		end if;

		wait for clk_period;
		sgn <= '1';
		a <= std_logic_vector(to_signed(-123, a'length));
		b <= std_logic_vector(to_signed(-456, b'length));

		wait for clk_period;
		if (signed(c_mult) /= X"000000000000DB18") then
			report "Multiplication result: -123 * -456 != 56088"
			severity failure;
		end if;

		wait for clk_period;
		a <= std_logic_vector(to_signed(-123456789, a'length));
		b <= std_logic_vector(to_signed(3, b'length));

		wait for clk_period;
		if (signed(c_mult) /= X"FFFFFFFFE9EC98C1") then
			report "Multiplication result: -123456789 * 3 != -370370367"
			severity failure;
		end if;

		a <= std_logic_vector(to_signed(123456789, a'length));
		b <= std_logic_vector(to_signed(-123456789, b'length));

		wait for clk_period;
		if (signed(c_mult) /= X"FFC9D9DD68C75C47") then
			report "Multiplication result: 123456789 * -123456789 != -1524157875019052100"
			severity failure;
		end if;

		-- End of simulation
		wait for clk_period;
		assert false report "Simulation ended" severity note;
		wait for 100 ns;
	end process;

end;
