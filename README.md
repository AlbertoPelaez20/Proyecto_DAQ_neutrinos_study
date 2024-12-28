
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


![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/UTEC%20Neutrino%20detector%20design%20-%20v1.jpg?raw=true)

El diseño tendra que basarse en el siguiente diagrama de bloques ya que formara parte de un proyecto mas grande.Por eso, se tendra que considerar el nombre de las entradas y el numero de ellas, en especial las que hacen referencia a los ADCs como CSadc, ENmux y SEmux.

## Bloques y partes del DAQ 

El DAQ tiene varios componentes tal y como se ve en el [diagrama2](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/diagrama2.jpg?raw=true). Los principales son el ADCs_modules y el feature_extraction. El primero se encarga de sincronizar la secuencia de activacion y habilitacion de los 8 ADCs y tambien de almacenar los datos de muestreo en la memoria durante todo el ciclo de disparo del trigger. El segundo, se encargar de procesar los datos almacenados para detectar el voltaje PICO y el tiempo de subida de la señal.


![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/d2.jpg?raw=true)

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

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tb1.jpg?raw=true)

**Simulacion del Interface_DAC.vhd**

La maquina de estados de este modulo implementado esta basado en el siguiente trabajo [I2C Master (VHDL)](https://forum.digikey.com/t/i2c-master-vhdl/12797)  : 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/machinestatei2c.jpeg?raw=true)

Estos fueron los resultados del TestBench y de las pruebas con el analizador de señales.

**TestBench**

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tb_i2c.jpg?raw=true)


**TestBench del modulo UART2 para envio de voltaje PICO y tiempo de subida**

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tbuartfrea.jpg?raw=true)


**TestBench del modulo UART1 para envio datos a MATLAB**

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tbuartmatlab.jpg?raw=true)

**TestBench del modulo feature_extraction para extraer voltaje PICO y tiempo de subida**

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/tv2.jpg?raw=true
) 


**PRUEBAS CON EL DAQ IMPLEMENTADO EN LA BASYS 3**

*Prueba1*

Para las pruebas se utiliza un PSOC para  generar las señales a medir. Para una señal senoidal de periodo 80us la configuracion es la siguiente: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/psoconda.jpg?raw=true
) 

La señal generada se puede ver con un osciloscopio digital asi como se muestra aocntinuacion: 

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


