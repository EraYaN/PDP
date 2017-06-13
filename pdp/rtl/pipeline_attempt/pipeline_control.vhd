library ieee;
use ieee.std_logic_1164.all;
use work.mlite_pack.all;

entity pipeline_control is
	port(
        clk           : in std_logic;
        reset         : in std_logic;
        pause         : in std_logic;
        pc_current  : in std_logic_vector(31 downto 2);
        pc_plus4    : in std_logic_vector(31 downto 2);
        rs_index      : in std_logic_vector(5 downto 0);
        rt_index      : in std_logic_vector(5 downto 0);
        rd_index      : in std_logic_vector(5 downto 0);
        imm_out       : in std_logic_vector(15 downto 0);
        alu_func      : in alu_function_type;
        shift_func    : in shift_function_type;
        mult_func     : in mult_function_type;
        branch_func   : in branch_function_type;
        a_source_out  : in a_source_type;
        b_source_out  : in b_source_type;
        c_source_out  : in c_source_type;
        pc_source_out : in pc_source_type;
        mem_source_out: in mem_source_type;
        opcode25_0    : in std_logic_vector(25 downto 0);
        pc_currentD  : out std_logic_vector(31 downto 2);
        pc_plus4D    : out std_logic_vector(31 downto 2);
        rs_indexD      : out std_logic_vector(5 downto 0);
        rt_indexD      : out std_logic_vector(5 downto 0);
        rd_indexD      : out std_logic_vector(5 downto 0);
        imm_outD       : out std_logic_vector(15 downto 0);
        alu_funcD      : out alu_function_type;
        shift_funcD    : out shift_function_type;
        mult_funcD     : out mult_function_type;
        branch_funcD   : out branch_function_type;
        a_source_outD  : out a_source_type;
        b_source_outD  : out b_source_type;
        c_source_outD  : out c_source_type;
        pc_source_outD : out pc_source_type;
        mem_source_outD: out mem_source_type;
        opcode25_0D    : out std_logic_vector(25 downto 0)
	);
end; --entity pipeline_control

architecture logic of pipeline_control is
begin
        pipelineproc: process(clk, reset, rs_index, rt_index, rd_index, imm_out, alu_func, shift_func, mult_func, branch_func, 
                a_source_out, b_source_out, c_source_out, pc_source_out, mem_source_out)
        begin
        if (reset='1') then
                pc_currentD    <= ZERO(31 downto 2);
                pc_plus4D      <= ZERO(31 downto 3) & '1';
                rs_indexD      <= ZERO(5 downto 0);
                rt_indexD      <= ZERO(5 downto 0);
                rd_indexD      <= ZERO(5 downto 0);
                imm_outD       <= ZERO(15 downto 0);
                alu_funcD      <= ALU_NOTHING;
                shift_funcD    <= SHIFT_NOTHING;
                mult_funcD     <= MULT_NOTHING;
                branch_funcD   <= BRANCH_EQ;
                a_source_outD  <= A_FROM_REG_SOURCE;
                b_source_outD  <= B_FROM_REG_TARGET;
                c_source_outD  <= C_FROM_NULL;
                pc_source_outD <= FROM_INC4;
                mem_source_outD<= MEM_FETCH;
                opcode25_0D    <= ZERO(25 downto 0);
        elsif(rising_edge(clk)) then
                if (pause='0') then
                        pc_currentD   <= pc_current;
                        pc_plus4D     <= pc_plus4;
                        rs_indexD      <= rs_index;
                        rt_indexD      <= rt_index;
                        rd_indexD      <= rd_index;
                        imm_outD       <= imm_out;
                        alu_funcD      <= alu_func;
                        shift_funcD    <= shift_func;  
                        mult_funcD     <= mult_func;
                        branch_funcD   <= branch_func;
                        a_source_outD  <= a_source_out;
                        b_source_outD  <= b_source_out;
                        c_source_outD  <= c_source_out;
                        pc_source_outD <= pc_source_out;
                        mem_source_outD<= mem_source_out;
                        opcode25_0D    <= opcode25_0;
                end if;
        end if;
        end process;
end;
