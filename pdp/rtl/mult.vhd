---------------------------------------------------------------------
-- TITLE: Multiplication and Division Unit
-- AUTHORS: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 1/31/01
-- FILENAME: mult.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the division unit in 32 clocks.
--
--
-- DIVISION
-- long upper=a, lower=0;
-- a = b << 31;
-- for(i = 0; i < 32; ++i)
-- {
--    lower = lower << 1;
--    if(upper >= a && a && b < 2)
--    {
--       upper = upper - a;
--       lower |= 1;
--    }
--    a = ((b&2) << 30) | (a >> 1);
--    b = b >> 1;
-- }
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.mlite_pack.all;

entity mult is
	port(
		clk       : in std_logic;
		reset_in  : in std_logic;
		a, b      : in std_logic_vector(31 downto 0);
		mult_func : in mult_function_type;
		c_mult    : out std_logic_vector(31 downto 0);
		pause_out : out std_logic
	);
end; --entity mult

architecture logic of mult is

	component dadda_mult
		port(
			sgn    : in  std_logic;
			a, b   : in  std_logic_vector(31 downto 0);
			c_mult : out std_logic_vector(63 downto 0)
		);
	end component;

	constant MODE_MULT  : std_logic := '1';
	constant MODE_DIV   : std_logic := '0';

	signal mode_reg     : std_logic;
	signal negate_reg   : std_logic;
	signal count_reg    : std_logic_vector(5 downto 0);
	signal aa_reg       : std_logic_vector(31 downto 0);
	signal aa2_reg      : std_logic_vector(31 downto 0);
	signal aa3_reg      : std_logic_vector(31 downto 0);
	signal bb_reg       : std_logic_vector(31 downto 0);
	signal bb2_reg		: std_logic_vector(32 downto 0);
	signal bb3_reg		: std_logic_vector(33 downto 0);
	signal upper_reg    : std_logic_vector(31 downto 0);
	signal lower_reg    : std_logic_vector(31 downto 0);

	signal a_neg        : std_logic_vector(31 downto 0);
	signal b_neg        : std_logic_vector(31 downto 0);
	signal sum          : std_logic_vector(32 downto 0);
	signal sum2         : std_logic_vector(32 downto 0);
	signal sum3         : std_logic_vector(32 downto 0);

	signal c_dadda_mult : std_logic_vector(63 downto 0);
	signal sgn          : std_logic;

begin
 
	pause_out <= '1' when (count_reg /= "000000") and 
			 (mult_func = MULT_READ_LO or mult_func = MULT_READ_HI) else '0';

	-- ABS and remainder signals
	a_neg <= bv_negate(a);
	b_neg <= bv_negate(b);
	sum <= bv_adder(upper_reg, aa_reg, mode_reg);
	sum2 <= bv_adder(upper_reg, aa2_reg, mode_reg);
	sum3 <= bv_adder(upper_reg, aa3_reg, mode_reg);

	-- Result
	process(mult_func, lower_reg, upper_reg, negate_reg)
	begin
		if mult_func = MULT_READ_LO then
			if negate_reg = '0' then
				c_mult <= lower_reg;
			else
				c_mult <= bv_negate(lower_reg);
			end if;
		elsif mult_func = MULT_READ_HI then
			if negate_reg = '0' then
				c_mult <= upper_reg;
			else
				c_mult <= bv_negate(upper_reg);
			end if;
		else
			c_mult <= ZERO;
		end if;
	end process;

	dadda: dadda_mult port map(
		a      => aa_reg,
		b      => bb_reg,
		sgn    => sgn,
		c_mult => c_dadda_mult
	);

	-- Multiplication/division unit
	mult_proc: process(clk, reset_in, a, b, mult_func, a_neg, b_neg, sum, sum2, sum3, mode_reg,
		negate_reg, count_reg, aa_reg, aa2_reg, aa3_reg, bb_reg, bb2_reg, bb3_reg, upper_reg, lower_reg)
		variable count : std_logic_vector(2 downto 0);
		variable vbb2 : std_logic_vector(32 downto 0);
		variable vbb3 : std_logic_vector(32 downto 0);
	begin
		count := "001";
		if reset_in = '1' then
			mode_reg <= '0';
			negate_reg <= '0';
			count_reg <= "000000";
			aa_reg <= ZERO;
			aa2_reg <= ZERO;
			aa3_reg <= ZERO;
			bb_reg <= ZERO;
			bb2_reg <= ZERO & '0';
			bb3_reg <= ZERO & "00";
			upper_reg <= ZERO;
			lower_reg <= ZERO;
			sgn <= '0';
		elsif rising_edge(clk) then
			case mult_func is
				when MULT_WRITE_LO =>
					lower_reg <= a;
					negate_reg <= '0';
					sgn <= '0';
				when MULT_WRITE_HI =>
					upper_reg <= a;
					negate_reg <= '0';
					sgn <= '0';
				when MULT_MULT =>
					mode_reg <= MODE_MULT;
					count_reg <= "000001";
					aa_reg <= a;
					bb_reg <= b;
					sgn <= '0';
				when MULT_SIGNED_MULT =>
					mode_reg <= MODE_MULT;
					count_reg <= "000001";
					aa_reg <= a;
					bb_reg <= b;
					sgn <= '1';
				when MULT_DIVIDE =>
					vbb2 := b & '0';
					vbb3 := '0' & b;
					mode_reg <= MODE_DIV;
					aa_reg <= b(1 downto 0) & ZERO(29 downto 0);
					aa2_reg <= b(0) & '0' & ZERO(29 downto 0);
					aa3_reg <= bv_adder(vbb2, vbb3,'1')(1 downto 0) & ZERO(29 downto 0);
					bb_reg <= b;
					bb2_reg <= vbb2;
					bb3_reg <= bv_adder(vbb2,vbb3,'1');
					upper_reg <= a;
					count_reg <= "010000";
					negate_reg <= '0';
					sgn <= '0';
				when MULT_SIGNED_DIVIDE =>
					mode_reg <= MODE_DIV;
					if b(31) = '0' then
						vbb2 := b & '0';
						vbb3 := '0' & b;
						aa_reg(31 downto 30) <= b(1 downto 0);
						aa2_reg(31 downto 30) <= vbb2(1 downto 0);
						aa3_reg(31 downto 30) <= bv_adder(vbb2, vbb3,'1')(1 downto 0);
						bb_reg <= b;
						bb2_reg <= vbb2;
						bb3_reg <= bv_adder(vbb2, vbb3,'1');
					else
						vbb2 := b_neg & '0';
						vbb3 := '0' & b_neg;
						aa_reg(31 downto 30) <= b_neg(1 downto 0);
						aa2_reg(31 downto 30) <= vbb2(1 downto 0);
						aa3_reg(31 downto 30) <= bv_adder(vbb2, vbb3,'1')(1 downto 0);
						bb_reg <= b_neg;
						bb2_reg <= vbb2;
						bb3_reg <= bv_adder(vbb2,vbb3,'1');
					end if;
					if a(31) = '0' then
						upper_reg <= a;
					else
						upper_reg <= a_neg;
					end if;
					aa_reg(29 downto 0) <= ZERO(29 downto 0);
					aa2_reg(29 downto 0) <= ZERO(29 downto 0);
					aa3_reg(29 downto 0) <= ZERO(29 downto 0);
					count_reg <= "010000";
					negate_reg <= a(31) xor b(31);
					sgn <= '0';
				when others =>
					if count_reg /= "000000" then
						if mode_reg = MODE_MULT then
							lower_reg <= c_dadda_mult(31 downto 0);
							upper_reg <= c_dadda_mult(63 downto 32);
						else
							-- Division
							if sum3(32) = '0' and aa3_reg /= ZERO and
							   bb3_reg(31 downto 2) = ZERO(31 downto 2) then
								upper_reg <= sum3(31 downto 0);
								lower_reg(1 downto 0) <= "11";
							elsif sum2(32) = '0' and aa2_reg /= ZERO and
							   bb2_reg(31 downto 2) = ZERO(31 downto 2) then
							    upper_reg <= sum2(31 downto 0);
								lower_reg(1 downto 0) <= "10";
							elsif sum(32) = '0' and aa_reg /= ZERO and
							   bb_reg(31 downto 2) = ZERO(31 downto 2) then
							    upper_reg <= sum(31 downto 0);
								lower_reg(1 downto 0) <= "01";
							else
								lower_reg(1 downto 0) <= "00";
							end if;
							aa_reg <= bb_reg(3 downto 2) & aa_reg(31 downto 2);
							aa2_reg <= bb2_reg(3 downto 2) & aa2_reg(31 downto 2);
							aa3_reg <= bb3_reg(3 downto 2) & aa3_reg(31 downto 2);
							lower_reg(31 downto 2) <= lower_reg(29 downto 0);
							bb_reg <= "00" & bb_reg(31 downto 2);
							bb2_reg <= "00" & bb2_reg(32 downto 2);
							bb3_reg <= "00" & bb3_reg(33 downto 2);
						end if;
						count_reg <= count_reg - count;
						sgn <= sgn;
					end if;
			end case;
		 
	  end if;

   end process;
	
end; --architecture logic
