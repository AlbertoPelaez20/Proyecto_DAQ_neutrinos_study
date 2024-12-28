
# DAQ-VHDL

**Implementación en VHDL de un sistema de aquisicion de datos** 

En este repositorio se encuentra la implementacion en VHDL de un sistema de aquisicion de datos digital (DAQ) basado en el control en cascada de 8 ADCs, dos multiplexores  y un DAC . Este sistema debera ser capaz de muestrear señales variando el tiempo de muestreo de los ADCs y la comumnutacion de los multiplexores. 



## Caracteristicas

**Diseño del sistema**: El Funcionamiento de DAQ esta basado en el control en cascada de 8 ADCs de la marca Texas Instruments modelo **ADS7046** de 12-Bit, dos multiplexores **74CBTLV3257-Q100** y un DAC **MCP4725**. Los ADCs usan protocolo SPI mientras el DAC I2C. 

Tal y como se muestra en la imagen de abajo, el objetivo es muestrear una señal que será procesada por la tarjeta de pruebas  [ADC_proto_v1](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/Schematics/ADS7046_v6.pdf). El [DAQ digital](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/tree/main/DAQ_neutrinos_study) desarrollado en VHDL y probado en una Basys 3, controlará la secuencia de activación de los ADCs y almacenará los valores medidos en una memoria. Luego, cuando la secuencia de muestreo finalice, estos datos obtenidos se podrán enviar por protocolo UART para graficarlos utilizando MATLAB.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/esquemageneral.jpg?raw=true)


El DAQ también es capaz de procesar los datos muestreados para extraer dos características clave: el voltaje máximo y el tiempo de subida hasta alcanzar dicho pico. Estos datos se transmitirán mediante otro módulo UART a un Arduino, con el propósito de comparar, corroborar y validar los resultados graficados en MATLAB, contrastando el voltaje pico y el tiempo de subida.



## Diseño del DAQ 

El proceso de conversión y almacenamiento de datos comienza con una señal de disparo generada a partir de la comparación entre el voltaje de entrada y un voltaje de referencia configurado por el DAC MCP4725. Esta configuración se realiza a través del DAQ utilizando un módulo I2C. De esta manera, es posible determinar con precisión el momento en que inicia la conversión de los datos muestreados y cuándo concluye. Se usaran los pulsadores y los switches de la basys 3 para iniciar el proceso de muestreo y setear el DAC.


![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/UTEC%20Neutrino%20detector%20design%20-%20v2.jpg?raw=true)

El diseño tendra que basarse en el siguiente diagrama de bloques ya que formara parte de un proyecto mas grande.Por eso, se tendra que considerar el nombre de las entradas y el numero de ellas, en especial las que hacen referencia a los ADCs como CSadc, ENmux y SEmux.

## Bloques y partes del DAQ 

El DAQ tiene varios componentes tal y como se ve en el [diagrama2](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/d2.jpg?raw=true). Los principales son el ADCs_modules y el feature_extraction. El primero se encarga de sincronizar la secuencia de activacion y habilitacion de los 8 ADCs y tambien de almacenar los datos de muestreo en la memoria durante todo el ciclo de disparo del trigger. El segundo, se encargar de procesar los datos almacenados para detectar el voltaje PICO y el tiempo de subida de la señal.

**Diagrama de bloques del DAQ_digital implementado en la basys3**
![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/d2.jpg?raw=true)

**Esquematico de la tarjeta ADC_proto_v1**

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/ADC_proto_v1_esquematico.jpg?raw=true)


## Componente ADCs_modules.vhd

Este módulo cuenta con dos máquinas de estados. La **FMS_SPI_Control.vhd** se encarga de la secuencia de activación de los ADCs, así como de la lectura y almacenamiento de los valores de conversión en 8 registros de desplazamiento. Cuando el disparo del trigger active el proceso de medición, la máquina de estados **FMS_ADCs_Readings.vhd** tomará los valores almacenados en estos registros para enviarlos a la memoria, siempre que detecte que los 8 registros han trabajado de manera secuencial. Esto significa que, al detectar que el ADC número 8 ha finalizado su conversión, se iniciará el proceso de grabación en la memoria.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/DIAGRAMA3.jpg?raw=true)

## FMS_SPI_Control

El diagrama de la maquina de estados para la secuencia de activacion de los 8 ADCs es la siquiente:

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/maquina_de_estados1.jpg?raw=true)

Para agregar los retardos o delays en la secuencia, se han definido TIMERS. Estos componentes se han configurado con un valor de 16 y se puede modificar tanto este valor de seteo, como el valor del clock tak y como se en la siguiente imagen:

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/configuracion.jpg?raw=true)

Cuando cada timer cuente 16 pulsos o flancos de subida, se activará uno de los 4 módulos SPI. Al mismo tiempo, cuando se detecte que se ha iniciado el proceso de comunicación SPI (con el CHIP SELECT en bajo), se habilitará el siguiente TIMER, que activará el segundo módulo SPI. Este proceso se repite hasta que se hayan habilitado los 4 primeros ADCs. Posteriormente, el procedimiento se repite con los 4 ADCs restantes.  

Acontinuacion se muestra un diagrama de tiempo donde se ve la secuencia de activacion de los 8 ADCs segun la maquina de estados.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/muestreo.jpg?raw=true)

## FMS_ADCs_Readings

El diagrama de la maquina de estados para el proceso de almacenamiento de los valores leidos es el siguiente:

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/maquina22.jpg?raw=true)

Este proceso detecta cuando el ADC #8 ha realizado una conversión, completando así una secuencia de conversión de 8 muestras (desde la 1 hasta la 8). En ese momento, se procede a grabar los 8 valores en la memoria y luego se espera a que la secuencia se repita. Este proceso se mantiene activo durante el tiempo que el disparo del trigger permanezca activado.

## Pruebas de Simulacion  

**Simulacion del ADCs_modules.vhd**

En el siguiente TestBench se puede ver el funcionamiento del ADCs_modules.vhd. se puede ver las etapas de las máquinas de estado en color celeste y blanco. Se puede observar la secuencia de activacion de los 8 ADCs en los 4 modulos SPI.

```bash
-- ========================================================
-- TESTBENCH DEL BLOQUE ADCs_modules
-- ========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ========================================================
-- ENTIDAD DEL TESTBENCH
-- ========================================================
entity tb_ADCs_modules is
end tb_ADCs_modules;

-- ========================================================
-- ARQUITECTURA DEL TESTBENCH
-- ========================================================
architecture Behavioral of tb_ADCs_modules is

    -- ============================
    -- COMPONENTE ADCs_modules
    -- ============================
    component ADCs_modules is
        Port (
            ONN, RESET, CLK, ONN2                 : in std_logic;      
            SELEC                                 : in std_logic_vector (2 downto 0);       
            GUARDAR, puntero_reset, READY         : out std_logic;
            BUS_CS                                : out std_logic_vector (7 downto 0);
            BUS_MUL                               : out std_logic_vector (3 downto 0);
            SCLK_1, SCLK_2, SCLK_3, SCLK_4        : out std_logic;
            SDO_1, SDO_2, SDO_3, SDO_4            : in std_logic;
            led                                   : out std_logic_vector (15 downto 0);
            sample_ADC1, sample_ADC2              : out std_logic_vector (14 downto 0);
            sample_ADC3, sample_ADC4              : out std_logic_vector (14 downto 0);
            sample_ADC5, sample_ADC6              : out std_logic_vector (14 downto 0);
            sample_ADC7, sample_ADC8              : out std_logic_vector (14 downto 0)
        );
    end component;

    -- ============================
    -- SEÑALES INTERNAS
    -- ============================
    signal ONN_S, RESET_S, CLK_S : std_logic;

-- ========================================================
-- CUERPO PRINCIPAL
-- ========================================================
begin

    -- ============================================
    -- INSTANCIA DEL COMPONENTE ADCs_modules
    -- ============================================
    UUT: ADCs_modules 
        port map (
            ONN      => '1',
            ONN2     => ONN_S,
            RESET    => RESET_S,
            SELEC    => "000", 
            SDO_1    => '1',  
            SDO_2    => '1',
            SDO_3    => '1',
            SDO_4    => '1',               
            CLK      => CLK_S
        );

    -- ============================================
    -- GENERACIÓN DEL RELOJ
    -- ============================================
    clock_gen: process
    begin
        CLK_S <= '0';
        wait for 5 ns;
        CLK_S <= '1';
        wait for 5 ns;
    end process;

    -- ============================================
    -- PROCESO DE CONTROL DE SEÑALES
    -- ============================================
    control_signals: process
    begin
        ONN_S <= '0';
        RESET_S <= '0';
        wait for 20 us;

        ONN_S <= '1';
        RESET_S <= '0';
        wait for 10 us;

        ONN_S <= '0';
        RESET_S <= '0';
        wait for 10 us;
    end process;

end Behavioral;
```

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tb1.jpg?raw=true)

Se puede observar la habilitacion secuencial de cada ADCs, en este caso por las señales CS (CHIP SELECT) en color rojo que pasan de hight a low. Los timers habilitan cada módulo SPI cuadno a pasado el tiempo necesario, en este caso se a seteado a 16 pulsos de reloj y se puede observar como las señales de color morado. 

**Trama I2C de test para probar la comunicacion con el MCP4725**

La maquina de estados de este modulo implementado esta basado en el siguiente trabajo [I2C Master (VHDL)](https://forum.digikey.com/t/i2c-master-vhdl/12797).  La maquina de estados esta diseñada para mandar 3 bytes segun lo indica la hoJa de datos del MCP4725.

Para el envio de datos, el primer byte enviado debe contener el codigo y la dirección del dispositivo que por defecto es 1100 y 000 por defecto. 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/i2c.jpg?raw=true)


Para setear el voltaje de salida del DAC, ademas del primer byte de direccionamiento hay que enviar 2 bytes mas. el 2do byte debe contener el modo de escritura y de consumo de energia en el nibble superior. A partir del nibble inferior y considerando el 3er byte, estos 12 bits representan el valor de salida del DAC.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tramai2c.jpg?raw=true)


**Simulacion del Interface_DAC.vhd**

Para la simulacion se considera el siguiente TestBench, donde el voltaje de salida que se quiere setear esta definido por la entrada SW, que para efectos de prueba en este caso es de "100100001111".

```bash
-- ========================================================
-- TESTBENCH DEL MÓDULO Interface_DAC
-- ========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ========================================================
-- ENTIDAD DEL TESTBENCH
-- ========================================================
entity tb_Interface_DAC is
end tb_Interface_DAC;

-- ========================================================
-- ARQUITECTURA DEL TESTBENCH
-- ========================================================
architecture Behavioral of tb_Interface_DAC is

    -- ============================================
    -- COMPONENTE A PROBAR: Interface_DAC
    -- ============================================
    component Interface_DAC is
        Port (
            ONN, RESET        : in std_logic;
            CLK               : in std_logic;
            SW                : in std_logic_vector(11 downto 0);
            SDA1, SCL1        : inout std_logic
        );
    end component;

    -- ============================================
    -- SEÑALES INTERNAS
    -- ============================================
    signal on_s, clk_s, reset_s, SDA1, SCL1 : std_logic;

-- ========================================================
-- CUERPO PRINCIPAL
-- ========================================================
begin

    -- ============================================
    -- INSTANCIA DEL COMPONENTE Interface_DAC
    -- ============================================
    UUT: Interface_DAC
        port map (
            ONN      => on_s,
            RESET    => reset_s,
            CLK      => clk_s,
            SW       => "100100001111",
            SDA1     => SDA1,
            SCL1     => SCL1
        );

    -- ============================================
    -- GENERACIÓN DEL RELOJ
    -- ============================================
    clock_gen: process
    begin
        clk_s <= '0';
        wait for 5 ns;
        clk_s <= '1';
        wait for 5 ns;
    end process;

    -- ============================================
    -- PROCESO DE CONTROL DE SEÑALES
    -- ============================================
    control_signals: process
    begin
        -- Estado inicial
        on_s    <= '0';
        reset_s <= '0';
        wait for 10 ns;

        -- Activar ONN
        on_s    <= '1';
        reset_s <= '0';
        wait for 550 ns;

        -- Desactivar ONN
        on_s    <= '0';
        reset_s <= '0';
        wait for 9 ms;
    end process;

end Behavioral;
```
Estos fueron los resultados del TestBench, se puede ver como la trama contiene los 3 bytes en la señal SDA1.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tb_i2c.jpg?raw=true)

Resultados obtenidos del analizador de señales

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/ANALIZADORI2C.jpg?raw=true)



**TestBench del modulo UART2 para envio de voltaje PICO y tiempo de subida**

```bash
-- ========================================================
-- TESTBENCH DE PRUEDA DEL MODULO UART_features 
-- ========================================================
-- prueba del modulo de envio de caracteristicas por UART

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_UART_freatures is
--  Port ( );
end tb_UART_freatures;

architecture Behavioral of tb_UART_freatures is

-- modulo uart para el envio de voltaje Pico y # de muestra
  component UART_features is
    Port ( SEND_1, CLK        : in  std_logic;
           NH_ADC, NL_ADC     : in  std_logic_vector(7 downto 0);
           numero_de_muestra  : in  std_logic_vector(7 downto 0);
           UART_TX_o_1        : out std_logic);
  end component;
  signal btn_UART2,clk_s,UART2_TX: std_logic := '0';
begin

 -- Instanciación del segundo transmisor UART
  UART02 : UART_features
    port map (
      SEND_1              => btn_UART2,
      CLK                 => clk_s,
      NH_ADC              => x"01",
      NL_ADC              => x"FF",
      numero_de_muestra   => x"A0",
      UART_TX_o_1         => UART2_TX
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
 btn_UART2  <= '0';
 wait for 10ns ;
 btn_UART2     <='1';
 wait for 550ns ;
 btn_UART2     <='0';
 wait for 9000000ns ;             
end process; 

end Behavioral;

```
Como se puede ver en la simulacion, se envian  los bytes x"01", x"FF" y x"A0", esto se ve en señal UART2_TX en azul.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tbuartfrea.jpg?raw=true)


**TestBench del modulo UART1 para envio datos a MATLAB**

Para el envio de datos desde la memoria no se puede apreciar porque el tiempo de simulacion es muy largo, no obstante se alcanza a ver que se envia los primeros bytes que son : x"0a",x"A0",x"0b",x"b0",x"FF", x"Fa" en la trama de la señal UART1_TX


![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tbuartmatlab.jpg?raw=true)

**TestBench del modulo feature_extraction para extraer voltaje PICO y tiempo de subida**

Para la prueba de extraccion del voltaje pico y el tiempo de subida se usa una memoria con los datos pregrabados : x"0a",x"A0",x"0b",x"b0",x"FF", x"Fa",x"0B",x"FF",x"FF",x"FF",x"0a",x"A0". En este caso el los valores d evoltaje se toman juntado 2 bytes consecutivos, por ende el primer valor de voltaje en hexadecimal es 0AA0, el segundo es 0BB0 y asi hasta 0aa0. Por otro lado el número de muestra se toma de la direccion del segundo byte que corresponde al valor pico, luego se le suman 1 y se divide por 2. Según los datos que hay preguardados en la memoria, el valor pico seria FFFF ( direccion1= 08, direccion2= 09) y le corresponderia a la muestra numero 5  (( direccion2 +1) / 2 ). Los resultados se pueden ver la señal MAXPICO de morado y muestra_n de rojo.

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tv2.jpg?raw=true
) 

**PRUEBAS CON EL DAQ IMPLEMENTADO EN LA BASYS 3**

*Prueba1*

Para las pruebas se utiliza un PSOC para  generar las señales a medir. Para una señal senoidal de periodo 80us la configuracion es la siguiente: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/psocusado.jpg?raw=true
) 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/psoconda.jpg?raw=true
) 

La señal generada se puede ver con un osciloscopio digital Hantek 6022BE 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/oscilsocopio.jpg?raw=true
) 

El disparo del trigger identifica como la señal de amarillo, el muestreo y conversion de datos debe comenzar el tiempo que esta señal este en alto.

Una vez que activamos el muestreo con los pulsadores de la basys3 y enviamos los datos obtenidos por UART a MATLAB, obtenemos los siguientes resultados: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/matlab_muestreo.jpg?raw=true) 

Son datos muy parecidosy cercanos con lo medido. Tiempo de muestreo de 4.6 us que para 8 muestras nos da un tiempo de 0.575 us por muestra. Para 80 us se necesitaran: (80/4.6)x8 =  aproximadamente 139 muestras. 

Para el voltaje pico se necesita un tiempo de aproximadamente la mitad : 40 us por lo que se necesitaría aproximadamente 69 muestras para llegar al pico (40/0.575). Según lo obtenido por el FPGA, aproximadamente se alcanza el pico de la señal en la muestra 71 y un valor de 3.12839  (considerar un offset de 8 para las muestras debido a que los ADC envían una medición anterior, por lo tanto alcanzaría el pico en la muestra 71-8 =  63 , , un valor relativamente cercano a 69 que era lo calculado para llegar a ese pico) 

*Prueba2*

Para una señal senoidal de periodo 60us la configuracion es la siguiente: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/psoc60micro.jpg?raw=true
) 

Señal generada : 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/osciloscopio60micro.jpg?raw=true
) 

Datos muestreados y graficados en MATLAB: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/60micromatlab.jpg?raw=true) 

Se necesitaría aproximadamente 52 muestras para llegar al pico (30/0.575). Según lo obtenido por el FPGA, aproximadamente se alcanza el pico de la señal en la muestra 58 y un valor de 3.08086. (considerar un offset de 8 para las muestras debido a que los ADC envían una medición anterior, por lo tanto alcanzaría el pico en la muestra 58-8 = 50, un valor cercano a 52 que era lo calculado para llegar a ese pico)

*Prueba3*

Para una señal senoidal de periodo 40us la configuracion es la siguiente: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/psoc40micro.jpg?raw=true
) 

Señal generada : 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/oscilos40micro.jpg?raw=true
) 

Datos muestreados y graficados en MATLAB: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/matlabuart40micro.jpg?raw=true) 

se necesitaría aproximadamente 34 muestras para llegar al pico (20/0.575). Según lo obtenido por el FPGA, aproximadamente se alcanza el pico de la señal en la muestra 45 y un valor de 2.9447. (considerar un offset de 8 para las muestras debido a que los ADC empiezan midiendo antes de que el trigguer se dispare, por lo que las 8 primeras muestras son mediciones antes de superar el triguer, por lo tanto alcanzaría el pico en la muestra 45-8 = 37, , un valor cercano a 34 que era lo calculado para llegar a ese pico )

*Prueba4*

Para una señal senoidal de periodo 20us la configuracion es la siguiente: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/psoc20micro.jpg?raw=true
) 

Señal generada : 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/oscilos20micro.jpg?raw=true
) 

Datos muestreados y graficados en MATLAB: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/matlab20micro.jpg?raw=true) 

Se necesitaría aproximadamente 17 muestras para llegar al pico (10/0.575). Según lo obtenido por el FPGA, aproximadamente se alcanza el pico de la señal en la muestra 23 y un valor de 2.51154. (considerar un offset de 8 para las muestras debido a que los ADC empiezan midiendo antes de que el trigguer se dispare, por lo que las 8 primeras muestras son mediciones antes de superar el trigguer, por lo tanto alcanzaría el pico en la muestra 23-8 = 15,  un valor cercano a 17 que era lo calculado para llegar a ese pico )

*Prueba5*

Para una señal diente de sierra de periodo 80us la configuracion es la siguiente: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/dientedesierrra80micripsoc.jpg?raw=true
) 

Señal generada : 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/oscilocopediente80micro.jpg?raw=true
) 

Datos muestreados y graficados en MATLAB: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/dientedesierramatlab80micro.jpg?raw=true) 

Para 60 us se necesitaran: (80/4.6)x8 =  aproximadamente 139 muestras, como se tiene un máximo de 120 se juega con el trigger ya que no se vería toda la señal en la grafica. Viendo la gradfica del osciloscopio , requiere de un tiempo de subida de 60 us por lo que se necesitaría (60/4.6)x8 = 104 muestras, un valor muy aproximado con lo que obtenemos con el fpga el cual determina que el pico se alcanza en la muestra 102.





## Tech Stack

**Programming Languages:** VHDL, MATLAB, C/C++

**Protocols:** SPI, I2C


## Documentation

[Documentation](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/tree/main/Datasheeds)

