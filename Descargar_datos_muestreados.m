% Crear el objeto serial
serialObj = serialport("COM5", 9600);  % Ajusta el puerto y baudrate según tu configuración
configureTerminator(serialObj, "LF");  % Configura el terminador si es necesario

% Inicializa variables
num_bytes = 240;  % Número de bytes a recibir (240 bytes)
datos_utiles = [];  % Para almacenar los datos útiles

% Leer los bytes recibidos desde el puerto serial
disp("Esperando datos...");
received_data = read(serialObj, num_bytes, "uint8");  % Leer 240 bytes

% Mostrar los bytes recibidos para verificar
disp("Bytes recibidos:");
disp(received_data); 

% Conversión de los datos recibidos a valores de ADC (120 mediciones de 12 bits)
num_measurements = num_bytes / 2;  % 120 mediciones (cada medición tiene 2 bytes)
adc_values = zeros(1, num_measurements);  % Crear un array para almacenar los valores de 120 mediciones

for i = 1:2:length(received_data)
    high_byte = received_data(i);         % Byte alto del ADC
    low_byte = received_data(i + 1);      % Byte bajo del ADC
    adc_values(ceil(i / 2)) = bitshift(high_byte, 8) + low_byte;  % Combinar los bytes
end

% Mostrar los valores ADC
disp("Valores ADC:");
disp(adc_values);

% Convertir a voltajes considerando 3.3V y 12 bits (4096 pasos)
voltajes = (adc_values / 4096) * 3.3;

% Mostrar los voltajes calculados
disp("Voltajes:");
disp(voltajes);
clear serialObj;

% Gráficas
t_m = 1; % 10 ms
tiempo1 = 0:t_m:((length(voltajes) * t_m) - t_m);

figure;
subplot(2,1,1)
plot(tiempo1, voltajes, '-o');
ylim([0 4]);  % Establecer el rango del eje Y de 0 a 3.4V
title('Voltajes de los ADC');
xlabel('Número de muestra'); ylabel('Voltaje (V)'); % Label axis
xticks(0:119);
grid on;
grid minor;

subplot(2,1,2)

bar(voltajes);
title('Voltajes de los ADC');
xlabel('Número de muestra');
ylabel('Voltaje (V)');
xticks(1:120);
ylim([0 4]);  % Establecer el rango del eje Y de 0 a 3.4V
grid on;
grid minor;
