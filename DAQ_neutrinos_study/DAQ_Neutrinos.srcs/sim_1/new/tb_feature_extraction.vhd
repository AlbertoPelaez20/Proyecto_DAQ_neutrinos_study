library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_feature_extraction is
--  Port ( );
end tb_feature_extraction;

architecture Behavioral of tb_feature_extraction is

-- Boque para la extraccion de voltaje pico y numero de muestra
  component feature_extraction is
    Port ( ONN        : in std_logic;
           CLK        : in std_logic;
           RESET      : in std_logic;
           direccion  : out std_logic_vector(7 downto 0);
           READ       : out std_logic;
           datos      : in std_logic_vector(7 downto 0);
           PICO       : out std_logic_vector(15 downto 0);
           numero_de_muestra     : out std_logic_vector(7 downto 0));
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
  
  signal clk_s, caracteristicas_lectura,BTN_U : std_logic := '0';
  signal direccion2,dato2: std_logic_vector ( 7 downto 0);
  signal MAXPICO: std_logic_vector (15 downto 0);
  signal muestra_n: std_logic_vector (7 downto 0);
begin

MEM0 : memory_buffer
    generic map (
      DATA_WIDTH => 12, 
      ADDR_WIDTH => 8
    )
    port map (
      data1         => x"000",
      data2         => x"000",
      data3         => x"000",
      data4         => x"000",
      data5         => x"000",
      data6         => x"000",
      data7         => x"000",
      data8         => x"000",
      MemWrite      => '0',
      MemRead       => '0',
      MemRead2      => caracteristicas_lectura,
      clk           => clk_s,
      reset         => '0',
      read_address  => x"00",
      read_data     => open,
      read_address2 => direccion2,
      read_data2    => dato2
    );

              
  -- Instanciación del bloque de extracción de características
  CI0: feature_extraction
    port map (
      ONN                   => BTN_U,
      CLK                   => clk_s,
      RESET                 => '0',
      direccion             => direccion2,
      READ                  => caracteristicas_lectura,
      datos                 => dato2,
      PICO                  => MAXPICO,
      numero_de_muestra     => muestra_n
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
 BTN_U  <= '0';
 wait for 10ns ;
 BTN_U     <='1';
 wait for 550ns ;
 BTN_U     <='0';
 wait for 9000000ns ;             
end process; 


end Behavioral;
