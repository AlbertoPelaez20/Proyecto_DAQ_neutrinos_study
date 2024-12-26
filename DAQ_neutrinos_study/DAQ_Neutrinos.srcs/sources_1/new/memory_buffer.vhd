-- ====================================================
-- Memoria buffer para almacenar los datos de los ADC
-- ====================================================
-- Bloque para almacenar datos de 12 bits obtenidos de los ADCs
-- en 2 memorias de logitud de 8 bytes, las dos memorias 
-- almacenan la misma data obtenida de los ADCs, cada meoria 
-- trabaja con un bloque UART para el envio de informacion especifica
-- ( datos almacenados y caracteristicas importantes )
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
entity memory_buffer is
generic (
        DATA_WIDTH : integer := 12;  -- Tamaño de cada dato en bits
        ADDR_WIDTH : integer := 6    -- Tamaño de la dirección en bits
    );
    port (
        -- Entradas de datos
        data1,data2,data3,data4  : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);   -- Datos a escribir
        data5,data6,data7,data8  : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);   -- Datos a escribir
        
        -- Señales de control
        MemWrite, MemRead, MemRead2 : in STD_LOGIC;  -- Escritura y lectura de memoria
        clk, reset                  : in STD_LOGIC;  -- Reloj y reinicio
        
        -- Direcciones de lectura
        read_address,read_address2 : in STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);   
        
        -- Datos leídos de la memoria
        read_data,read_data2   : out STD_LOGIC_VECTOR (7 downto 0)   -- Datos leídos
    );
end memory_buffer;
architecture Behavioral of memory_buffer is
    -- Definir el número de posiciones de memoria en función de la dirección
    constant MEM_SIZE : integer := 2**ADDR_WIDTH;

    -- Declaración de las memorias como arreglos de bytes (8 bits)
    type mem_array is array(0 to MEM_SIZE-1) of STD_LOGIC_VECTOR (7 downto 0);
    signal data_mem: mem_array := (x"0a",x"A0",x"0b",x"b0",x"FF", x"Fa",x"0B",x"FF",x"FF",x"FF",x"0a",x"A0" ,others => (others => '0')); 
 
    type mem_array2 is array(0 to MEM_SIZE-1) of STD_LOGIC_VECTOR (7 downto 0);
    signal data_mem2: mem_array2 := (x"0a",x"A0",x"0b",x"b0",x"FF", x"Fa",x"0B",x"FF",x"FF",x"FF",x"0a",x"A0" ,others => (others => '0')); 
                
   
    -- Contador para manejar la dirección de escritura
    signal write_address : integer range 0 to MEM_SIZE-1 := 0;
    
    -- Dividir datos de entrada en parte alta (RH) y baja (RL)
    signal RH1,RL1,RH2,RL2,RH3,RL3,RH4,RL4:STD_LOGIC_VECTOR (7 downto 0);
    signal RH5,RL5,RH6,RL6,RH7,RL7,RH8,RL8:STD_LOGIC_VECTOR (7 downto 0);
    
      -- Señal auxiliar para detectar el flanco de subida de MemWrite
    signal MemWrite_prev : STD_LOGIC := '0';
    
begin
    -- Lógica para leer datos desde la memoria

    read_data   <= data_mem(to_integer(unsigned(read_address))) when MemRead = '1'  else (others => '0');
    read_data2  <= data_mem2(to_integer(unsigned(read_address2))) when MemRead2 = '1'  else (others => '0');

    -- Dividir datos de entrada en parte alta (RH) y baja (RL)

    RH1 <=  "0000"&data1(11 downto 8 );
    RL1 <=  data1(7 downto 0);
    RH2 <=  "0000"&data2(11 downto 8 );
    RL2 <=  data2(7 downto 0);
    RH3 <=  "0000"&data3(11 downto 8 );
    RL3 <=  data3(7 downto 0);
    RH4 <=  "0000"&data4(11 downto 8 );
    RL4 <=  data4(7 downto 0);

    RH5 <=  "0000"&data5(11 downto 8 );
    RL5 <=  data5(7 downto 0);
    RH6 <=  "0000"&data6(11 downto 8 );
    RL6 <=  data6(7 downto 0);
    RH7 <=  "0000"&data7(11 downto 8 );
    RL7 <=  data7(7 downto 0);
    RH8 <=  "0000"&data8(11 downto 8 );
    RL8 <=  data8(7 downto 0);

   -- =============================================
   -- Proceso para escritura en memoria
   -- =============================================
mem_process: process(clk, reset,MemWrite, MemWrite_prev,MemRead,MemRead2)
    begin
        if reset = '1' then
            --  Reiniciar dirección de escritura en caso de reset
            write_address <= 0;
        elsif rising_edge(clk ) then
            if (MemWrite = '1' and MemWrite_prev = '0' and  MemRead = '0' and MemRead2 = '0') then
                -- Escribir los datos de en la dirección actual
                 data_mem(write_address)        <= RH1;   -- nibble superior de lectura de ADC1
                 data_mem(write_address + 1 )   <= RL1;   -- nibble inferior de lectura de ADC1
                 data_mem(write_address + 2 )   <= RH2;   -- nibble superior de lectura de ADC2
                 data_mem(write_address + 3 )   <= RL2;   -- nibble inferior de lectura de ADC2
                 data_mem(write_address + 4 )   <= RH3;   -- nibble superior de lectura de ADC3
                 data_mem(write_address + 5 )   <= RL3;   -- nibble inferior de lectura de ADC3
                 data_mem(write_address + 6 )   <= RH4;   -- nibble superior de lectura de ADC4
                 data_mem(write_address + 7 )   <= RL4;   -- nibble inferior de lectura de ADC4
                 data_mem(write_address + 8 )   <= RH5;   -- nibble superior de lectura de ADC5
                 data_mem(write_address + 9 )   <= RL5;   -- nibble inferior de lectura de ADC5
                 data_mem(write_address + 10 )  <= RH6;   -- nibble superior de lectura de ADC6
                 data_mem(write_address + 11 )  <= RL6;   -- nibble inferior de lectura de ADC6
                 data_mem(write_address + 12 )  <= RH7;   -- nibble superior de lectura de ADC7
                 data_mem(write_address + 13 )  <= RL7;   -- nibble inferior de lectura de ADC7
                 data_mem(write_address + 14 )  <= RH8;   -- nibble superior de lectura de ADC8
                 data_mem(write_address + 15 )  <= RL8;   -- nibble inferior de lectura de ADC8
                 
                -- Escribir datos en la memoria secundaria                 
                 data_mem2(write_address)        <= RH1;   -- nibble superior de lectura de ADC1
                 data_mem2(write_address + 1 )   <= RL1;   -- nibble inferior de lectura de ADC1
                 data_mem2(write_address + 2 )   <= RH2;   -- nibble superior de lectura de ADC2
                 data_mem2(write_address + 3 )   <= RL2;   -- nibble inferior de lectura de ADC2
                 data_mem2(write_address + 4 )   <= RH3;   -- nibble superior de lectura de ADC3
                 data_mem2(write_address + 5 )   <= RL3;   -- nibble inferior de lectura de ADC3
                 data_mem2(write_address + 6 )   <= RH4;   -- nibble superior de lectura de ADC4
                 data_mem2(write_address + 7 )   <= RL4;   -- nibble inferior de lectura de ADC4
                 data_mem2(write_address + 8 )   <= RH5;   -- nibble superior de lectura de ADC5
                 data_mem2(write_address + 9 )   <= RL5;   -- nibble inferior de lectura de ADC5
                 data_mem2(write_address + 10 )  <= RH6;   -- nibble superior de lectura de ADC6
                 data_mem2(write_address + 11 )  <= RL6;   -- nibble inferior de lectura de ADC6
                 data_mem2(write_address + 12 )  <= RH7;   -- nibble superior de lectura de ADC7
                 data_mem2(write_address + 13 )  <= RL7;   -- nibble inferior de lectura de ADC7
                 data_mem2(write_address + 14 )  <= RH8;   -- nibble superior de lectura de ADC8
                 data_mem2(write_address + 15 )  <= RL8;   -- nibble inferior de lectura de ADC8

                -- Incrementamos el contador de dirección (con lógica de buffer circular)
                if write_address + 16 >= MEM_SIZE then
                    write_address <= 0;  -- Si llegamos al final, volvemos al inicio (buffer circular)
                else
                    write_address <= write_address + 16;  -- Avanzamos a la siguiente dirección
                end if;
            end if;
             -- Actualizar MemWrite_prev con el valor actual de MemWrite
            MemWrite_prev <= MemWrite;
        end if;
    end process;
end Behavioral;
