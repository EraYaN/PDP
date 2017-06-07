library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;
 
entity mult_test is
end mult_test;
 
architecture behavior of mult_test is

	component mult is
		port(
			clk       : in std_logic;
			reset_in  : in std_logic;
			a, b      : in std_logic_vector(31 downto 0);
			mult_func : in mult_function_type;
			c_mult    : out std_logic_vector(31 downto 0);
			pause_out : out std_logic
		);
	end component;

	--Inputs
	signal a   : std_logic_vector(31 downto 0) := (others => '0');
	signal b   : std_logic_vector(31 downto 0) := (others => '0');
	signal mf  : mult_function_type := MULT_NOTHING;
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';

	--Outputs
	signal c_mult : std_logic_vector(31 downto 0);
	signal pause  : std_logic;

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
	UUT: mult port map (
		clk       => clk,
		reset_in  => rst,
		a         => a,
		b         => b,
		mult_func => mf,
		c_mult    => c_mult,
		pause_out => pause
	);

	-- Stimulus process
	stim_proc: process
	begin
		------------------------------------------------------------------
		-- RESET
		------------------------------------------------------------------
		wait for clk_period * 5;
		rst <= '0';
		wait for clk_period * 5;

		------------------------------------------------------------------
		-- UNSIGNED
		------------------------------------------------------------------

		mf <= MULT_MULT;
		a <= std_logic_vector(to_unsigned(123, a'length));
		b <= std_logic_vector(to_unsigned(456, b'length));
		wait for clk_period;

		mf <= MULT_READ_LO;
		wait for clk_period;

		if (signed(c_mult) /= X"0000DB18") then
			report "Multiplication result: 123 * 456 != 56088"
			severity failure;
		end if;

		------------------------------------------------------------------

		mf <= MULT_MULT;
		a <= std_logic_vector(to_unsigned(1234567890, a'length));
		b <= std_logic_vector(to_unsigned(3, b'length));
		wait for clk_period;

		mf <= MULT_READ_LO;
		wait for clk_period;

		if (unsigned(c_mult) /= X"DCC20876") then
			report "Multiplication result: 1234567890 * 3 != 3703703670"
			severity failure;
		end if;

		------------------------------------------------------------------

		mf <= MULT_MULT;
		a <= std_logic_vector(to_unsigned(1234567890, a'length));
		b <= std_logic_vector(to_unsigned(1234567890, b'length));
		wait for clk_period;

		mf <= MULT_READ_LO;
		wait for clk_period;

		if (unsigned(c_mult) /= X"121FF444") then
			report "Multiplication result: REG_LO != 0x121FF444"
			severity failure;
		end if;

		mf <= MULT_READ_HI;
		wait for clk_period;

		if (unsigned(c_mult) /= X"1526E583") then
			report "Multiplication result: REG_LO != 0x1526E583"
			severity failure;
		end if;

		------------------------------------------------------------------
		-- SIGNED
		------------------------------------------------------------------

		mf <= MULT_SIGNED_MULT;
		a <= std_logic_vector(to_signed(-123, a'length));
		b <= std_logic_vector(to_signed(-456, b'length));
		wait for clk_period;

		mf <= MULT_READ_LO;
		wait for clk_period;

		if (signed(c_mult) /= X"0000DB18") then
			report "Multiplication result: -123 * -456 != 56088"
			severity failure;
		end if;

		------------------------------------------------------------------

		mf <= MULT_SIGNED_MULT;
		a <= std_logic_vector(to_signed(-123456789, a'length));
		b <= std_logic_vector(to_signed(3, b'length));
		wait for clk_period;

		mf <= MULT_READ_LO;
		wait for clk_period;

		if (signed(c_mult) /= X"E9EC98C1") then
			report "Multiplication result: REG_LO != 0xE9EC98C1"
			severity failure;
		end if;

		mf <= MULT_READ_HI;
		wait for clk_period;

		if (signed(c_mult) /= X"FFFFFFFF") then
			report "Multiplication result: REG_HI != 0xFFFFFFFF"
			severity failure;
		end if;

		------------------------------------------------------------------

		mf <= MULT_SIGNED_MULT;
		a <= std_logic_vector(to_signed(123456789, a'length));
		b <= std_logic_vector(to_signed(-123456789, b'length));
		wait for clk_period;

		mf <= MULT_READ_LO;
		wait for clk_period;

		if (signed(c_mult) /= X"68C75C47") then
			report "Multiplication result: REG_LO != 0x68C75C47"
			severity failure;
		end if;

		mf <= MULT_READ_HI;
		wait for clk_period;

		if (signed(c_mult) /= X"FFC9D9DD") then
			report "Multiplication result: REG_HI != 0xFFC9D9DD"
			severity failure;
		end if;

		------------------------------------------------------------------
		-- END OF SIMULATION
		------------------------------------------------------------------

		wait for clk_period;
		assert false report "Simulation ended" severity note;
		wait for 1 sec;
	end process;

end;
