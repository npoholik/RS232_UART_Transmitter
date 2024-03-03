----------------------------------------------------------------------------------
-- ECE 3215 - Computer Systems Design 
-- Engineers: Nikolas Poholik, Robert Sloyan
-- 
-- Create Date: 01/30/2024 11:11:09 AM
-- Design Name: RS_232_UART
-- Module Name: RS232_UART - Behavioral
-- Project Name: RS_232_UART_Transmitter
-- Target Devices: Basys 3 FPGA
-- Description: The goal of this project is to create a basic UART capable of transmitting 9600 N81 over a RS232 communications channel 
----------------------------------------------------------------------------------
Library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
----------------------------------------------------------------------------------

entity RS232_UART is
    port (clk : in std_logic;      -- Internal base oscillator of 100 MHz
        output : out std_logic);   -- Transmission bits to send out 
end RS232_UART;

----------------------------------------------------------------------------------

architecture Behavioral of RS232_UART is
    -- *** Define Signals *** 
    ------------------------------------------------------------------------------
    signal baud_clk : std_logic := '0';             -- Clock divided down to desired baud 
    signal load : std_logic := '0';                 -- Will shift out new data from the PISO
    signal address : std_logic_vector(4 downto 0);  -- Keeps track of 5 bit addresses of ROM elements
    signal addressCount : std_logic := '0';         -- Acts as a clock for the address generator (9600 Hz / 8) 
    signal loadCount : std_logic := '0';            -- Assigned to load to send a pulse to PISO
    signal data : std_logic_vector(7 downto 0);     -- Holds the current value from current address of SROM
    ------------------------------------------------------------------------------

    -- *** SROM of 20 data elements (5 bit address range)
    ------------------------------------------------------------------------------
    type SROM is array (natural range <>) of std_logic_vector(7 downto 0);
    signal addressROM : SROM(0 to 19) := (x"52", x"4F", x"42", x"42", x"59", x"20", x"41", x"4E", x"44", x"20", x"4E", x"49", x"43", x"4B", x"20", x"20", x"20", x"20", x"20", x"20");
        -- Message Stored "Bobby and Nick      "
    ------------------------------------------------------------------------------

-- ***Architecture Begin***
----------------------------------------------------------------------------------
begin

    -- Data line from ROM for the PISO to take 
    data <= addressROM(to_integer(unsigned(address)));
    
    --Clock Generator for Target Baud (This is a 9600 Baud Clock)
    baud_gen: process(clk)
        variable count: integer range 0  to 8000 := 0;
        begin
            if rising_edge(clk) then
                count := count + 1;
                if count = 5208 then
                    count := 0;
                    baud_clk <= not baud_clk;
                end if;
           end if;
    end process;
    
    -- PISO: Parallel in Serial Out Shift Register: Handles data + overhead to send out of the processor
    piso: process(baud_clk)
        variable word : std_logic_vector(9 downto 0);
        begin
            if rising_edge(baud_clk) then
                if load = '0' then
                    word := '1' & word(9 downto 1);
                else 
                    word := '1' & data & '0';
                end if;
                output <= word(0);
           end if;
       end process;
       
     -- Bit Counter to keep track of data bits transmitted + account for overhead 
    bit_counter: process(baud_clk)
        variable bitCount : integer range 0 to 20 := 0; -- Counter (will reset at 15)
        begin
            if rising_edge(baud_clk) then
		        loadCount <= '0';
		        addressCount <= '0';
                bitCount := bitCount + 1;
                if bitCount = 8 then        -- increment addressCount every 8 bits (based on baud rate)
                    addressCount <= '1';
                end if;
                if bitCount = 15 then       -- send a load pulse every 15 bits (8 data bits + 7 overhead bits) and reset counter
                    bitCount := 0;
                    loadCount <= '1';
                end if;
                load <= loadCount;
            end if;
       end process;
       
     -- Address generator: Upon addressCount being updated by the bit counter, the address generator will move to the next ROM memory address
    address_gen: process(addressCount) 
        variable curAddress : std_logic_vector(4 downto 0) := "00000";
        begin 
            if rising_edge(addressCount) then
                curAddress := std_logic_vector(unsigned(curAddress) + 1);
                address <= curAddress;
                if curAddress = "01111" then
                    curAddress := "00000";
                end if;
            end if;
       end process;
----------------------------------------------------------------------------------
---*** End Architecture 
end Behavioral;
