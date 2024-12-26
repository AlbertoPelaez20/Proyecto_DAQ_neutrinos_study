-- ========================================================
-- Módulo I2C maestro para setear voltaje en el DAC MCP4725
-- ========================================================
-- Basado en https://forum.digikey.com/t/i2c-master-vhdl/12797

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all;

entity i2c_master is
GENERIC(
    input_clk : INTEGER := 50_000_000; -- velocidad del reloj de entrada desde la lógica del usuario en Hz
    bus_clk   : INTEGER := 400_000);   -- velocidad a la que funcionará el bus i2c (scl) en Hz
  PORT(
    clk       : IN     STD_LOGIC;                    -- reloj del sistema
    reset_n   : IN     STD_LOGIC;                    -- reset activo bajo
    ena       : IN     STD_LOGIC;                    -- latch en comando
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); -- dirección del esclavo objetivo
    rw        : IN     STD_LOGIC;                    -- '0' es escribir, '1' es leer
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); -- datos a escribir en el esclavo
    busy      : OUT    STD_LOGIC;                    -- indica transacción en progreso
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); -- datos leídos del esclavo
    ack_error : BUFFER STD_LOGIC;                    -- bandera si hay un acuse de recibo incorrecto del esclavo
    sda       : INOUT  STD_LOGIC;                    -- salida de datos seriales del bus i2c
    scl       : INOUT  STD_LOGIC);                   -- salida del reloj serial del bus i2c
end i2c_master;

architecture Behavioral of i2c_master is
CONSTANT divider  :  INTEGER := (input_clk/bus_clk)/4; -- número de relojes en 1/4 ciclo de scl
  TYPE machine IS(ready, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); -- estados necesarios
  SIGNAL state         : machine;                        -- máquina de estados
  SIGNAL data_clk      : STD_LOGIC;                      -- reloj de datos para sda
  SIGNAL data_clk_prev : STD_LOGIC;                      -- reloj de datos durante el reloj del sistema anterior
  SIGNAL scl_clk       : STD_LOGIC;                      -- scl interno que funciona constantemente
  SIGNAL scl_ena       : STD_LOGIC := '0';               -- habilita el scl interno para la salida
  SIGNAL sda_int       : STD_LOGIC := '1';               -- sda interno
  SIGNAL sda_ena_n     : STD_LOGIC;                      -- habilita el sda interno para la salida
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- dirección y lectura/escritura almacenadas
  SIGNAL data_tx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- datos a escribir en el esclavo almacenados
  SIGNAL data_rx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- datos recibidos del esclavo
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 7 := 7;      -- rastrea el número de bits en la transacción
  SIGNAL stretch       : STD_LOGIC := '0';               -- identifica si el esclavo está estirando scl
BEGIN

  -- genera el temporizador para el reloj del bus (scl_clk) y el reloj de datos (data_clk)
  PROCESS(clk, reset_n)
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;  -- temporizador para la generación del reloj
  BEGIN
    IF(reset_n = '0') THEN                -- reset activado
      stretch <= '0';
      count := 0;
    ELSIF(clk'EVENT AND clk = '1') THEN
      data_clk_prev <= data_clk;          -- guarda el valor anterior del reloj de datos
      IF(count = divider*4-1) THEN        -- fin del ciclo de temporización
        count := 0;                       -- reinicia el temporizador
      ELSIF(stretch = '0') THEN           -- no se detecta estiramiento de reloj del esclavo
        count := count + 1;               -- continúa con la temporización de generación del reloj
      END IF;
      -- Reemplazo de CASE con IF-ELSE
    IF count < divider THEN              -- primer 1/4 ciclo del reloj
      scl_clk <= '0';
      data_clk <= '0';
    ELSIF count < divider*2 THEN        -- segundo 1/4 ciclo del reloj
      scl_clk <= '0';
      data_clk <= '1';
    ELSIF count < divider*3 THEN        -- tercer 1/4 ciclo del reloj
      scl_clk <= '1';                  -- libera scl
      IF scl = '0' THEN                -- detecta si el esclavo está estirando el reloj
        stretch <= '1';
      ELSE
        stretch <= '0';
      END IF;
      data_clk <= '1';
    ELSE                                -- último 1/4 ciclo del reloj
      scl_clk <= '1';
      data_clk <= '0';
    END IF;

    END IF;
  END PROCESS;

  -- máquina de estados y escritura en sda durante scl bajo (bajo borde de data_clk)
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 -- reset activado
      state <= ready;                      -- vuelve al estado inicial
      busy <= '1';                         -- indica que no está disponible
      scl_ena <= '0';                      -- establece scl en alta impedancia
      sda_int <= '1';                      -- establece sda en alta impedancia
      ack_error <= '0';                    -- limpia la bandera de error de acuse de recibo
      bit_cnt <= 7;                        -- reinicia el contador de bits de datos
      data_rd <= "00000000";               -- limpia el puerto de datos leídos
    ELSIF(clk'EVENT AND clk = '1') THEN
      IF(data_clk = '1' AND data_clk_prev = '0') THEN  -- borde ascendente del reloj de datos
        CASE state IS
          WHEN ready =>                      -- estado inactivo
           
            IF(ena = '1') THEN               -- transacción solicitada
              busy <= '1';                   -- bandera de ocupado
              addr_rw <= addr & rw;          -- recopila la dirección y comando solicitados del esclavo
              data_tx <= data_wr;            -- recopila los datos solicitados para escribir
              state <= start;                -- pasa al bit de inicio
            ELSE                             -- permanece inactivo
              busy <= '0';                   -- desactiva la bandera de ocupado
              state <= ready;                -- permanece inactivo
            END IF;
          WHEN start =>                      -- bit de inicio de la transacción
            busy <= '1';                     -- reanuda ocupado si en modo continuo
            sda_int <= addr_rw(bit_cnt);     -- establece el primer bit de dirección en el bus
            state <= command;                -- pasa al comando
          WHEN command =>                    -- byte de dirección y comando de la transacción
            IF(bit_cnt = 0) THEN             -- transmisión de comando finalizada
              sda_int <= '1';                -- libera sda para el acuse del esclavo
              bit_cnt <= 7;                  -- reinicia el contador de bits para los estados de "byte"
              state <= slv_ack1;             -- pasa al acuse del esclavo (comando)
            ELSE                             -- siguiente ciclo de reloj del estado de comando
              bit_cnt <= bit_cnt - 1;        -- rastrea los bits de la transacción
              sda_int <= addr_rw(bit_cnt-1); -- escribe el bit de dirección/comando en el bus
              state <= command;              -- continúa con el comando
            END IF;
          WHEN slv_ack1 =>                   -- bit de acuse del esclavo (comando)
           busy <= '0';      -- AGREGADO!
            IF(addr_rw(0) = '0') THEN        -- comando de escritura
              sda_int <= data_tx(bit_cnt);   -- escribe el primer bit de datos
              state <= wr;                   -- pasa al byte de escritura
            ELSE                             -- comando de lectura
              sda_int <= '1';                -- libera sda de los datos entrantes
              state <= rd;                   -- pasa al byte de lectura
            END IF;
          WHEN wr =>                         -- byte de escritura de la transacción
            busy <= '1';                     -- reanuda ocupado si en modo continuo
            IF(bit_cnt = 0) THEN             -- transmisión de byte de escritura finalizada
              sda_int <= '1';                -- libera sda para el acuse del esclavo
              bit_cnt <= 7;                  -- reinicia el contador de bits para los estados de "byte"
              state <= slv_ack2;             -- pasa al acuse del esclavo (escritura)
            ELSE                             -- siguiente ciclo de reloj del estado de escritura
              bit_cnt <= bit_cnt - 1;        -- rastrea los bits de la transacción
              sda_int <= data_tx(bit_cnt-1); -- escribe el siguiente bit en el bus
              state <= wr;                   -- continúa escribiendo
            END IF;
          WHEN rd =>                         -- byte de lectura de la transacción
            busy <= '1';                     -- reanuda ocupado si en modo continuo
            IF(bit_cnt = 0) THEN             -- recepción de byte de lectura finalizada
              IF(ena = '1' AND addr_rw = addr & rw) THEN  -- continuando con otra lectura en la misma dirección
                sda_int <= '0';              -- acuse de que el byte ha sido recibido
              ELSE                           -- detención o continuación con una escritura
                sda_int <= '1';              -- envía un no-acuse (antes de detener o repetir inicio)
              END IF;
              bit_cnt <= 7;                  -- reinicia el contador de bits para los estados de "byte"
              data_rd <= data_rx;            -- salida de datos recibidos
              state <= mstr_ack;             -- pasa al acuse del maestro
            ELSE                             -- siguiente ciclo de reloj del estado de lectura
              bit_cnt <= bit_cnt - 1;        -- rastrea los bits de la transacción
              state <= rd;                   -- continúa leyendo
            END IF;
          WHEN slv_ack2 =>                   -- bit de acuse del esclavo (escritura)
            IF(ena = '1') THEN               -- continúa la transacción
              busy <= '0';                   -- la continuación es aceptada
              addr_rw <= addr & rw;          -- recopila la dirección y comando solicitados del esclavo
              data_tx <= data_wr;            -- recopila los datos solicitados para escribir
              IF(addr_rw = addr & rw) THEN   -- continúa la transacción con otra escritura
                sda_int <= data_wr(bit_cnt); -- escribe el primer bit de datos
                state <= wr;                 -- pasa al byte de escritura
              ELSE                           -- continúa la transacción con una lectura o nuevo esclavo
                state <= start;              -- pasa al inicio repetido
              END IF;
            ELSE                             -- completa la transacción
              state <= stop;                 -- pasa al bit de detención
            END IF;
          WHEN mstr_ack =>                   -- bit de acuse del maestro después de una lectura
            IF(ena = '1') THEN               -- continúa la transacción
              busy <= '0';                   -- la continuación es aceptada y los datos recibidos están disponibles en el bus
              addr_rw <= addr & rw;          -- recopila la dirección y comando solicitados del esclavo
              data_tx <= data_wr;            -- recopila los datos solicitados para escribir
              IF(addr_rw = addr & rw) THEN   -- continúa la transacción con otra lectura
                sda_int <= '1';              -- libera sda de los datos entrantes
                state <= rd;                 -- pasa al byte de lectura
              ELSE                           -- continúa la transacción con una escritura o nuevo esclavo
                state <= start;              -- inicio repetido
              END IF;    
            ELSE                             -- completa la transacción
              state <= stop;                 -- pasa al bit de detención
            END IF;
          WHEN stop =>                       -- bit de detención de la transacción
            busy <= '0';                     -- desactiva la bandera de ocupado
            state <= ready;                  -- pasa al estado inactivo
        END CASE;    
      ELSIF(data_clk = '0' AND data_clk_prev = '1') THEN  -- borde descendente del reloj de datos
        CASE state IS
          WHEN start =>                  
            IF(scl_ena = '0') THEN                  -- iniciando nueva transacción
              scl_ena <= '1';                       -- habilita la salida de scl
              ack_error <= '0';                     -- restablece la salida de error de acuse de recibo
            END IF;
          WHEN slv_ack1 =>                          -- recibiendo acuse del esclavo (comando)
            IF(sda /= '0' OR ack_error = '1') THEN  -- no-acuse o no-acuse previo
              ack_error <= '1';                     -- establece la salida de error si no-acuse
            END IF;
          WHEN rd =>                                -- recibiendo datos del esclavo
            data_rx(bit_cnt) <= sda;                -- recibe el bit de datos actual del esclavo
          WHEN slv_ack2 =>                          -- recibiendo acuse del esclavo (escritura)
            IF(sda /= '0' OR ack_error = '1') THEN  -- no-acuse o no-acuse previo
              ack_error <= '1';                     -- establece la salida de error si no-acuse
            END IF;
          WHEN stop =>
            scl_ena <= '0';                         -- desactiva scl
          WHEN OTHERS =>
            NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;  

  -- establece la salida de sda
  WITH state SELECT
    sda_ena_n <= data_clk_prev WHEN start,     -- genera condición de inicio
                 NOT data_clk_prev WHEN stop,  -- genera condición de detención
                 sda_int WHEN OTHERS;          -- establece en el señal de sda interno    
      
  -- establece las salidas de scl y sda
  scl <= '0' WHEN (scl_ena = '1' AND scl_clk = '0') ELSE 'Z';
  sda <= '0' WHEN sda_ena_n = '0' ELSE 'Z';
  
end Behavioral;
