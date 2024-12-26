-- ========================================================
-- Maquina de estados para el seteo del DAC MCP4725 
-- ========================================================
-- Bloque para mandar la secuencia de 3 bytes en protocolo I2C 
-- segun como se indica en la hoja de datos del DAC MCP4725

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SetDAC is
  Port (
         Set     : in std_logic_vector(11 downto 0);
         clk     : in std_logic;
         reset   : in std_logic;
         ONN     : in std_logic;
         bussy   : in std_logic;
         ena     : out std_logic;                      -- latch en comando
         addr    : out std_logic_vector(6 downto 0);   -- dirección del esclavo objetivo
         rw      : out std_logic;                      -- '0' es escribir, '1' es leer
         data_wr : out std_logic_vector(7 downto 0)    -- datos a escribir en el esclavo
         );
end SetDAC;

architecture Behavioral of SetDAC is

   -- =============================================
   -- Definicion de maquina de estados
   -- =============================================
   type state_type is (stand_by, get_data, FIN);
   signal PS, NS: state_type;
  
   -- Señales internas
   
   signal busy_prev : std_logic := '0';
   signal busy_cnt  : integer := 0;
  

begin

   -- =============================================
   -- Proceso síncrono: Máquina de estados
   -- =============================================
   sync_proc: process(clk, reset)
   begin
      if (reset = '1') then
         PS <= stand_by;
      elsif (rising_edge(clk)) then
         PS <= NS;
      end if;
   end process sync_proc;
   
   -- ====================================================
   -- Proceso combinacional: Lógica de la máquina de estados
   -- ====================================================
   comb_proc: process(PS, bussy, ONN, busy_cnt, Set)
   begin
      case PS is
        -- Estado inicial: Espera de señal de activación
         when stand_by =>
            ena <= '0';
            busy_cnt <= 0;
            addr <= "1100000"; -- Dirección del esclavo
            data_wr <= "0000" & Set(11 downto 8); -- Primer byte de datos
            if (ONN = '1') then
               NS <= get_data;
            else
               NS <= stand_by;
            end if;
            
          -- Cargar dirección de nibble superior
         when get_data =>
            busy_prev <= bussy; -- Captura el valor anterior de busy
            if (rising_edge(bussy)) then -- Detecta flanco ascendente de busy
               if (busy_prev = '0' and bussy = '1') then
                  busy_cnt <= busy_cnt + 1; -- Incrementa el contador cuando busy pasa de '0' a '1'
               end if;
            end if;

            case busy_cnt is
               when 0 =>
                  ena <= '1'; -- Inicia la transacción
                  rw <= '0'; -- Escribir
                  data_wr <= "0000" & Set(11 downto 8); -- Primer byte de datos
                  NS <= get_data;

               when 1 =>
                  ena <= '1'; -- Inicia la transacción
                  rw <= '0'; -- Escribir
                  data_wr <= "0000" & Set(11 downto 8); -- Primer byte de datos
                  NS <= get_data;

               when 2 =>
                  ena <= '1'; -- Inicia la transacción
                  rw <= '0'; -- Escribir
                  data_wr <= Set(7 downto 0); -- Segundo byte de datos
                  if (busy_cnt = 2 and bussy = '0') then
                     ena <= '0'; -- Finalizar la transacción
                  end if;
                  NS <= get_data;

               when 3 =>
                  rw <= '0'; -- Escribir
                  ena <= '0'; -- Finalizar la transacción
                  if (busy_cnt = 3 and bussy = '0') then
                     NS <= stand_by;
                  else
                     NS <= get_data;
                  end if;

               when others =>
                  -- Manejo de caso no esperado
                  NS <= stand_by;
            end case;

         when others =>
            -- Manejo de caso no esperado
            NS <= stand_by;
      end case;
   end process comb_proc;

end Behavioral;
