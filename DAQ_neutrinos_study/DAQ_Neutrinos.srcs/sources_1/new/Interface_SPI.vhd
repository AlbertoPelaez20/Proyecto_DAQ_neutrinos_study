-------------------------------------------------------------
-- Serial Peripheral Interface (SPI) 
-- Is a synchronous serial data protocol 
-- used for communication between digital circuits. Therefore with SPI interface
-- FPGAs or microcontrollers can communicate with peripheral devices, sensors and also 
-- other FPGAs and microcontrollers quickly over short distances.
-- In this implementation both SPI master and SPI slave components are written in VHDL and can be used for all FPGAs.
-- https://github.com/nematoli/SPI-FPGA-VHDL/blob/master/README.md
----------------------------------------------------------------------
library IEEE;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity Interface_SPI is
generic(
    data_length : INTEGER := 15 -- longitud de datos en bits
);
port (
    clk     : IN  STD_LOGIC;         -- reloj del sistema
    reset_n : IN  STD_LOGIC;         -- reinicio asíncrono activo en bajo
    enable  : IN  STD_LOGIC;         -- iniciar comunicación
    stop    : IN  STD_LOGIC;         -- detener el módulo SPI
    cpol    : IN  STD_LOGIC;         -- modo de polaridad del reloj
    cpha    : IN  STD_LOGIC;         -- modo de fase del reloj
    miso    : IN  STD_LOGIC;         -- maestro a esclavo (entrada del esclavo)
    sclk    : OUT STD_LOGIC;         -- reloj SPI
    ss_n    : OUT STD_LOGIC;         -- selección del esclavo
    mosi    : OUT STD_LOGIC;         -- maestro a esclavo (salida del maestro)
    busy    : OUT STD_LOGIC;         -- señal de ocupado del maestro
    tx      : IN  STD_LOGIC_VECTOR(data_length-1 DOWNTO 0); -- datos a transmitir
    rx      : OUT STD_LOGIC_VECTOR(data_length-1 DOWNTO 0)  -- datos recibidos
);
end Interface_SPI;

architecture Behavioral of Interface_SPI is
    TYPE FSM IS (init, execute);       -- máquina de estados
    SIGNAL state       : FSM;          -- estado actual de la máquina de estados
    SIGNAL receive_transmit : STD_LOGIC; -- '1' para tx, '0' para rx 
    SIGNAL clk_toggles : INTEGER RANGE 0 TO data_length*2 + 1; -- contador de cambios de reloj
    SIGNAL last_bit    : INTEGER RANGE 0 TO data_length*2; -- indicador del último bit
    SIGNAL rxBuffer    : STD_LOGIC_VECTOR(data_length-1 DOWNTO 0) := (OTHERS => '0'); -- búfer de datos recibidos
    SIGNAL txBuffer    : STD_LOGIC_VECTOR(data_length-1 DOWNTO 0) := (OTHERS => '0'); -- búfer de datos a transmitir
    SIGNAL INT_ss_n    : STD_LOGIC;    -- registro interno para ss_n 
    SIGNAL INT_sclk    : STD_LOGIC;    -- registro interno para sclk 
BEGIN	
  -- conectar los registros internos a las salidas
  ss_n <= INT_ss_n;
  sclk <= INT_sclk;  

  PROCESS(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN         -- reiniciar todo
      busy <= '1';                
      INT_ss_n <= '1';            
      mosi <= 'Z'; 
      INT_sclk <= '0';                  
      rx <= (OTHERS => '0');      
      state <= init; 

    ELSIF (falling_edge(clk)) THEN
      CASE state IS            
        WHEN init => -- bus está inactivo
          busy <= '0';             
          INT_ss_n <= '1'; 		  
          mosi <= 'Z';             
   
          IF (enable = '1') THEN -- establecer polaridad del reloj SPI
            busy <= '1';             
            INT_sclk <= cpol; -- establecer fase del reloj SPI
            receive_transmit <= NOT cpha; -- cargar datos en el búfer para transmitir
            txBuffer <= tx; -- iniciar contador de cambios de reloj
            clk_toggles <= 0; -- inicializar contador
            last_bit <= data_length*2 + conv_integer(cpha) - 1; -- último bit de rx
            state <= execute;        
          ELSE
            state <= init;          
          END IF;

        WHEN execute =>
          -- Verificar si detener el proceso
          IF (stop = '1') THEN
            busy <= '0';             
            INT_ss_n <= '1'; -- Desactivar línea ss_n
            mosi <= 'Z'; -- Colocar mosi en alta impedancia
            rx <= rxBuffer; -- Mantener los datos recibidos
            state <= init; -- Regresar al estado inicial
          ELSE
            -- Continuar con la transacción
            busy <= '1';               
            INT_ss_n <= '0'; -- Activar selección del esclavo
            receive_transmit <= NOT receive_transmit; -- Cambiar modo rx/tx          
            
            -- Contador
            IF (clk_toggles = data_length*2 + 1) THEN
              clk_toggles <= 0; -- reiniciar contador
            ELSE
              clk_toggles <= clk_toggles + 1; -- incrementar contador
            END IF;

            -- Alternar sclk
            IF (clk_toggles <= data_length*2 AND INT_ss_n = '0') THEN 
              INT_sclk <= NOT INT_sclk; -- alternar reloj SPI
            END IF;

            -- Recibir bit de miso
            IF (receive_transmit = '0' AND clk_toggles < last_bit + 1 AND INT_ss_n = '0') THEN 
              rxBuffer <= rxBuffer(data_length-2 DOWNTO 0) & miso; 
            END IF;

            -- Transmitir bit de mosi
            IF (receive_transmit = '1' AND clk_toggles < last_bit) THEN 
              mosi <= txBuffer(data_length-1);                    
              txBuffer <= txBuffer(data_length-2 DOWNTO 0) & '0'; 
            END IF;

            -- Finalizar la comunicación
            IF (clk_toggles = data_length*2 + 1) THEN   
              busy <= '0';             
              INT_ss_n <= '1';         
              mosi <= 'Z';             
              rx <= rxBuffer;    
              state <= init;          
            ELSE                       
              state <= execute;        
            END IF;
          END IF;
      END CASE;
    END IF;
  END PROCESS; 
end Behavioral;

