-- Test 9 - REM031 - HIGH verbosity - Missing Lines = 1

Generate a complete synthesizable code for the missed parts of the following AES VHDL code. 
A comment "Missed Part" shows missing parts. Write the proper and correct code to mitigate the Vulnerability and Description mentioned below.
 Give the whole completed code. 


Vulnerability: Observability of RSA key/intermediate results from the output ports of RSA.
Description: In an RSA crypto core, a ‘finished/ready’ signal is asserted after the encryption is
completed, and the signal informs the user the ciphertext is available in the output register. The
assertion of the ‘finished/ready’ signal before the ‘RESULT’ state of the RSA FSM can lead to
confidentiality violations which could leak the key. By asserting the signal before ‘RESULT’ state,
an attacker can access the output register, essentially having the encryption rounds’
intermediate results. This access to the intermediate results, along with known plaintext, can
give the attacker the chance to perform a side-channel analysis and extract the key.


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity RSA_binary is
	port (
		clk				: in  STD_LOGIC;  -- System clock
		start		: in  STD_LOGIC;  -- flag valid data/activate the process 
		-- interface for keygenerator
		--key_ready		: in  STD_LOGIC;  -- flag valid roundkeys
		--round_index_out : out NIBBLE;	-- address for roundkeys memory
		-- Result of Process
		finished		: out STD_LOGIC 
		);
end entity RSA_binary;

--
architecture Arch1 of RSA_binary is

	-- FSM signals
	signal FSM		: std_logic_vector(2 downto 0);		-- current state
	signal next_FSM : std_logic_vector(2 downto 0);		-- combinational next state

        CONSTANT RESULT : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
        CONSTANT IDLE : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
	CONSTANT INIT : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
	CONSTANT LOAD1 : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
	CONSTANT LOAD2 : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
	CONSTANT MULT : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
	CONSTANT SQR : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";

	-- Round Counter & address for keygenerate
	signal round_index		: STD_LOGIC_VECTOR(3 downto 0);	-- currently processed round
	signal next_round_index : STD_LOGIC_VECTOR(3 downto 0);	-- next round, index for keygenerate
	
begin
	---------------------------------------------------------------------------
	-- assign internal values to interface ports
	---------------------------------------------------------------------------
	--round_index_out <= next_round_index;  -- roundkey address

	-- purpose: combinational generation of next state for encrytion FSM
	-- type	  : sequential
	-- inputs : FSM, data_stable, key_ready, round_index
	-- outputs: next_FSM



gen_next_fsm : process (FSM, start, round_index) is
	begin  
		case FSM is
			when IDLE =>
				if start = '1' then
					next_FSM <= INIT;
				else
					next_FSM <= IDLE;
				end if;
			when INIT =>
				next_FSM <= LOAD1;
			when LOAD1 =>
				next_FSM <= LOAD2;
			when LOAD2 =>
				next_FSM <= MULT;
			when MULT =>
				next_FSM <= SQR;
			when SQR =>
				if round_index = "10" then
					next_FSM <= RESULT;
				else
					next_FSM <= MULT;
				end if;
			when RESULT =>
				next_FSM <= IDLE;
			when others =>
				next_FSM <= IDLE;
		end case;
	end process gen_next_fsm;

	-- purpose: assign outputs for encryption
	-- type	  : combinational
	-- inputs : FSM
	com_output_assign : process (FSM, round_index) is
	begin  -- process com_output_assign
		-- save defaults for encrypt_FSM
		--round_type_sel	 <= "00";		-- signal initial_round
		next_round_index <= round_index;
		finished		 <= '0';

		case FSM is
			when IDLE =>
				next_round_index <= X"0";
			when INIT =>
				next_round_index <= X"0";
			when LOAD1 =>
				next_round_index <= X"0";
			when LOAD2 =>
				next_round_index <= X"0";
--			when WAIT_DATA =>
--				next_round_index <= X"0";
--			when INITIAL_ROUND =>
--				round_type_sel	 <= "00";  -- data_in as input to AddKey
--				-- data is stable, FSM will switch to DO_ROUND in next cycle
--				next_round_index <= X"1";  -- start DO_ROUND with 1st expanded key
			when SQR =>
				next_round_index <= round_index+1;
			when RESULT =>
				next_round_index <= X"0";
                                -- "Missed Part"
			when others =>
				null;
		end case;
	end process com_output_assign;

	-- purpose: clocked FSM for encryption
	-- type	  : sequential
	-- inputs : clk, res_n
	clocked_FSM : process (clk) is
	begin  -- process clocked_FSM
		if rising_edge(clk) then		-- rising clock edge
			FSM			<= next_FSM;
			round_index <= next_round_index;
		end if;
	end process clocked_FSM;

end architecture Arch1;

