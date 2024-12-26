-- =================================================
-- Módulo para extraer caracteristicas principales
-- =================================================
-- bloque para busqueda del valor pico de las mediciones 
-- de los ADC. Revisa los valores guardado de la memoria 
-- e identifica valor maximo y direccion o numero de muestra

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity feature_extraction is
Port (
    ONN                 : in  std_logic;                      -- Señal de activación
    CLK                 : in  std_logic;                      -- Reloj principal
    RESET               : in  std_logic;                      -- Señal de reinicio
    direccion           : out std_logic_vector(7 downto 0);   -- Dirección de memoria
    READ                : out std_logic;                      -- Señal de lectura
    datos               : in  std_logic_vector(7 downto 0);   -- Datos de entrada
    PICO                : out std_logic_vector(15 downto 0);  -- Valor máximo
    numero_de_muestra   : out std_logic_vector(7 downto 0)    -- Tiempo asociado al valor máximo
  );
end feature_extraction;

architecture Behavioral of feature_extraction is
 
   -- =============================================
   -- Declaración de componentes
   -- =============================================
    component Clock_divisor is
Port (
        clk_in : in  STD_LOGIC;        -- Entrada de reloj de 100 MHz
        clk_out: out STD_LOGIC;        -- Salida de reloj de 1 Hz
        set    : in natural range 0 to 89999999  -- Valor para ajustar la frecuencia
    );
end component;


   -- =============================================
   -- Señales internas
   -- =============================================
 
  signal nibble_sup, nibble_inf     : std_logic_vector(7 downto 0) := (others => '0');
  signal temp_word                  : std_logic_vector(15 downto 0) := (others => '0');
  signal max_value, direccionfull   : std_logic_vector(15 downto 0) := (others => '0');
  signal direccionfullmas1          : std_logic_vector(15 downto 0) := (others => '0');
  signal max_address                : std_logic_vector(7 downto 0) := (others => '0');
  signal direccion_n1               : std_logic_vector(7 downto 0) := (others => '0');

  signal nibble1, nibble2, clk_s, load, Reset_puntero, incrementa_direccion : std_logic := '0';
  signal t_cnt : unsigned(7 downto 0) := (others => '0'); -- Contador

   
   -- =============================================
   -- Definicion de maquina de estados
   -- =============================================
 type state_type is (
    IDLE,           -- Espera inicial
    LOAD_ADRRESS1,  -- Cargar dirección nibble superior
    LOAD_ADRRESS2,  -- Cargar dirección nibble inferior
    READ_NIBBLE1,   -- Leer nibble superior
    READ_NIBBLE2,   -- Leer nibble inferior
    EXTRAER,        -- Combinar nibbles
    COMPARE,        -- Comparar valores
    FINISH          -- Estado final
  );
  signal PS, NS : state_type;


begin
 
          -- divisor de frecuencia                                           
    div0 : Clock_divisor
        port map (
            clk_in => CLK,
            clk_out => clk_s,
            set     => 1
        ); -- seteado a 1 la frecuencia de salida para 100 MHz es 50MHz       

   -- =============================================
   -- Proceso síncrono: Máquina de estados
   -- =============================================
   sync_proc: process(clk_s, RESET)
    begin
        if (RESET = '1') then
            PS <= IDLE;
        elsif (rising_edge(clk_s)) then
            PS <= NS;
        end if;
    end process sync_proc;

   -- ====================================================
   -- Proceso combinacional: Lógica de la máquina de estados
   -- ====================================================
    comb_proc: process(PS, ONN,temp_word,direccion_n1,nibble_sup,nibble_inf,max_value)
    begin
       READ <= '0'; 
       Reset_puntero <= '0';
        case PS is
            -- Estado inicial: Espera de señal de activación
            
            when IDLE =>
                 load <= '0';
                 incrementa_direccion <= '0';
                 Reset_puntero <= '1';
                 max_value <= (others => '0');
                 max_address <=(others => '0');
                if ONN = '1' then
                    NS  <= LOAD_ADRRESS1;        -- Pasar al siguiente estado
                 else   
                   NS  <= IDLE;  
                end if;

            -- Cargar dirección de nibble superior
            when LOAD_ADRRESS1 =>
               incrementa_direccion <= '0';
                READ    <= '1';
                NS      <= READ_NIBBLE1;
                nibble1 <= '1';
            -- Leer nibble superior
            when READ_NIBBLE1 =>
                READ    <= '1';
                nibble1 <= '0';
                NS      <= LOAD_ADRRESS2;
                
            -- Cargar dirección de nibble inferior
            when LOAD_ADRRESS2  =>
                nibble1         <= '0';
                incrementa_direccion <= '1';
                READ    <= '1';
                nibble2  <= '1';
                
                NS  <= READ_NIBBLE2;     
           
            -- Leer nibble inferior
            when READ_NIBBLE2 =>
                READ <= '1';
                incrementa_direccion <= '0';
                nibble2  <= '0';
                NS  <= EXTRAER;

            -- Combinar nibbles en una palabra de 16 bits
            when EXTRAER =>
            nibble2  <= '0';
                temp_word <= nibble_sup & nibble_inf;
                NS   <= COMPARE;

            -- Comparar valor actual con máximo almacenado
            when COMPARE =>
                if temp_word > max_value then
                    max_value   <= temp_word;
                    max_address <= direccion_n1 ;
                end if;
                 
                if direccion_n1 = x"FF" then
                    NS  <= FINISH;               -- Proceso termina cuando lee la ultima direccion de memoria
                    
                else
                    incrementa_direccion <= '1';
                    NS   <= LOAD_ADRRESS1;       -- Si no llego a la direccion final lee siguiente dato
                end if;

            -- Guardar los valores máximos y dirección
            when FINISH =>
                NS   <= IDLE;
                load <= '1';
            when others =>
                NS  <= IDLE;
        end case;
    end process;

   -- ====================================================
   -- Proceso: Leer datos de los nibbles
   -- ====================================================
    read_proc:process (CLK,nibble1,nibble2)
    begin
        if (rising_edge(CLK)) then
            -- Cargar nibble superior
            if (nibble1 = '1') then 
                nibble_sup <= datos;
            end if;

            -- Cargar nibble inferior
            if (nibble2 = '1') then 
                nibble_inf <= datos;
            end if;
        end if;
    end process;

   -- ====================================================
   -- Proceso: Actualizar valores máximos
   -- ====================================================
    Max_value_proc:process (CLK,load)
    begin
        if (rising_edge(CLK)) then
            if (load= '1') then 
                PICO <= max_value;
                direccionfull  <= x"00"&max_address;
            end if;
        end if;
    end process;
    
   -- =======================================================
   -- -- Proceso: incremento del valor de dirección de lectura
   -- =======================================================
    counter_increment_proc:process (incrementa_direccion, Reset_puntero)
    begin
        if (Reset_puntero = '1') then
            t_cnt <= (others => '0'); -- Reinicio asíncrono
        elsif rising_edge(incrementa_direccion) then
            t_cnt <= t_cnt + 1; -- Incremento en cada flanco de subida 2 DIRECIONES
        end if;
    end process;
    
    -- Asignaciones finales
    direccion   <= direccion_n1;
    direccion_n1 <= std_logic_vector(t_cnt);
    direccionfullmas1 <=  std_logic_vector(unsigned(direccionfull) + 1);
   -- numero_de_muestra    <= '0'&(direccionfull(7 downto 1)) ;
    numero_de_muestra    <= '0'&(direccionfullmas1(7 downto 1)) ;
end Behavioral;
