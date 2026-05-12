clear; clc;

bits = 12;       % Разрядность амплитуды (12 бит)
rom_size = 1024; % Размер таблицы (10 бит адреса)

A = 2^(bits-1) - 1; 

fprintf('Генерация универсального ROM на %d точек...\n', rom_size);

n = 0:(rom_size-1);
% Фаза ровно на один полный круг
phase = 2 * pi * (n / rom_size); 

cos_val = round(A * cos(phase));
sin_val = round(A * sin(phase));

cos_hex = mod(cos_val + 2^bits, 2^bits);
sin_hex = mod(sin_val + 2^bits, 2^bits);

fcid = fopen('../rom/cos.mem', 'w');
fsid = fopen('../rom/sin.mem', 'w');

for i = 1:rom_size
    fprintf(fcid, '%03X\n', cos_hex(i));
    fprintf(fsid, '%03X\n', sin_hex(i));
end

fclose(fcid);
fclose(fsid);
disp('Готово!');