
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_UART_MATLAB is
--  Port ( );
end tb_UART_MATLAB;

architecture Behavioral of tb_UART_MATLAB is

-- modulo uart para mandar datos a matlab graficar
  component UART_MATLAB is
    Port ( SEND_1        : in  std_logic;
           DATA_1        : in  std_logic_vector(7 downto 0);
           DIRECCION     : out std_logic_vector(7 downto 0);
           CLK_1         : in  std_logic;
           UART_TX_o_1   : out std_logic);
  end component;
  
  -- memoria de almacenamiento de los datos muestreados
  component memory_buffer is
    generic (
        DATA_WIDTH : integer := 12;
        ADDR_WIDTH : integer := 6
    );
    port (
        data1, data2, data3, data4  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data5, data6, data7, data8  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        MemWrite, MemRead, MemRead2, clk, reset : in std_logic;
        read_address, read_address2 : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        read_data, read_data2   : out std_logic_vector(7 downto 0)
    );
  end component;
  
  signal btn_UART1,clk_s,UART1_TX: std_logic := '0';
  signal direccion1,dato1: std_logic_vector (7 downto 0);
begin

-- Instanciación del transmisor UART
  UART01 : UART_MATLAB
    port map (
      SEND_1      => btn_UART1,
      CLK_1       => clk_s,
      DIRECCION   => direccion1,
      DATA_1      => dato1,
      UART_TX_o_1 => UART1_TX
    );
    
    MEM0 : memory_buffer
    generic map (
      DATA_WIDTH => 12, 
      ADDR_WIDTH => 8
    )
    port map (
      data1         => x"011",
      data2         => x"011",
      data3         => x"011",
      data4         => x"011",
      data5         => x"011",
      data6         => x"011",
      data7         => x"011",
      data8         => x"011",
      MemWrite      => '0',
      MemRead       => '1',
      MemRead2      => '0' ,
      clk           => clk_s,
      reset         => '0',
      read_address  => direccion1,
      read_data     => dato1,
      read_address2 =>  x"00",
      read_data2    => open
    );
    
clock_generate: process
    begin
        clk_s <= '0';
        wait for 5ns ;
        clk_s <= '1';
    wait for 5ns ;
end process;     

Control : process
    begin
        btn_UART1       <=  '0';
    wait for 10ns ;
        btn_UART1       <=  '1';
    wait for 550ns ;
        btn_UART1       <=  '0';
    wait for 9000000ns ;             
end process; 

end Behavioral;
