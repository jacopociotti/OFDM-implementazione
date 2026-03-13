clc
clear
close all

%% Trasmettitore
% Numero di sottoportanti 
Nsubcarrier = 64;

% Piloti
piltospacing = 16;
idx_pilot = 0 : piltospacing : Nsubcarrier;
idx_pilot(1) = 1;
num_pilots = length(idx_pilot);

% Dati (escludendo i piloti)
idx_datasymbols = setdiff(1:64, idx_pilot);
num_data = length(idx_datasymbols); % numero di simboli di dati OFDM
num_bits_data = num_data*2; % numero di bit di dati

%%
%ciclo for che scorre i numero di simboli ofdm (n-uple di simboli)
for nSymbolOfdm=1:1
bits = comm.PNSequence('Polynomial',[1 0 0 0 0 1 1],'InitialConditions', ...
    [0 0 0 0 0 1],'Mask',[1 1 0 1 0 1],'SamplesPerFrame',num_bits_data); 
bits=bits()';

%metto i bit in formato NRZ BIPOLARE
bits = 2 * bits - 1; 

% bits diventa un vettore con 2 colonne e 64 righe
bits_r=reshape(bits,2,num_bits_data/2); 

data_symbols = zeros(1,num_data);

%codifica da bit a simbolo 4-PSK, solo per i dati, non considero i piloti
for k = 1:length(bits_r)
    if isequal(bits_r(:, k)', [1, 1])
        data_symbols(k) = 1 + 1i;
    elseif isequal(bits_r(:, k)', [-1, 1])
        data_symbols(k) = -1 + 1i;
    elseif isequal(bits_r(:, k)', [1, -1])
        data_symbols(k) = +1 - 1i;
    elseif isequal(bits_r(:, k)', [-1, -1])
        data_symbols(k) = -1 - 1i;
    end
end

% Generazione toni Piloti
pilot_values = (1+1i) * ones(1,num_pilots);

% Inserisco i piloti nel vettore dei simboli OFDM
% ofdSymbol_freq contiene i dati più i 5 piloti
ofdmSymbol_freq = zeros(1, 64);
ofdmSymbol_freq(idx_datasymbols) = data_symbols;
ofdmSymbol_freq(idx_pilot) = pilot_values;

% IFFT dei simboli OFDM
ofdmTimeSignal = ifft(ofdmSymbol_freq);

%% CANALE
% Genera risposta impulsiva di un canale Rayleigh
n_taps = 10; % 2 generazioni
Channel_Response_R = random('Rayleigh',[1 0.1],[1 n_taps]); % ampiezze-valori medi delle due generazioni (percorso diretto e percorso secondario)
Channel_Response_I = 1i * random('Rayleigh',[1 0.1],[1 n_taps]);

Channel_Response = (Channel_Response_R + Channel_Response_I);

Received_Signal_Rayl = cconv(ofdmTimeSignal,Channel_Response,64);

%% Rumore
% Genero rumore gaussiano
Noise_R = wgn(1, length(ofdmSymbol_freq), -60);
Noise_I = 1i* wgn(1, length(ofdmSymbol_freq), -60);

Noise = Noise_R + Noise_I;

Received_Signal_Rayl_Noise = Received_Signal_Rayl + Noise;


%% Stima del canale
% FFT dei campioni nel tempo
ofdmFreqSignal_rx = fft(Received_Signal_Rayl_Noise);

% Visualizza costellazione ricevuta prima dell'equalizzazione
scatterplot(ofdmFreqSignal_rx);
title('Costellazione Ricevuta (Prima di Equalizzazione)');


% Stima in corrispondenza dei piloti
H_pilot = ofdmFreqSignal_rx(idx_pilot) ./ pilot_values;

% Canale stimato interpolando i piloti
H = interp1(idx_pilot,H_pilot,1:64, 'spline');

H_linear = interp1(idx_pilot,H_pilot,1:64, 'linear');


figure;
hold on;
% Canale reale
Freq_Channel_Response_actual = fft(Channel_Response,64);
plot(1:64, abs(Freq_Channel_Response_actual), 'b-', 'LineWidth', 2);
% Canale stimato con interpolazione
plot(1:length(H), abs(H), 'r--');
% Plot con interpolazione linear
plot(1:length(H), abs(H_linear), 'g.');
% Piloti
plot(idx_pilot, abs(H_pilot), 'ro', 'MarkerFaceColor', 'r');
legend('Canale Reale (Perfetto)', 'Stima Interpolata H ("spline")',  'Stima Interpolata H ("linear")', 'Stima sui Piloti');
title('Stima della Risposta in Frequenza del Canale');
xlabel('Sottoportante');
ylabel('Magnitudine |H(f)|');
hold off;

%% Equalizzazione
% Equalizzazione usando la stima H
ofdmFreqSignal_eq = ofdmFreqSignal_rx ./ H;

% Visualizza costellazione dopo l'equalizzazione
scatterplot(ofdmFreqSignal_eq);
title('Costellazione Ricevuta (Dopo Equalizzazione)');

% Estrazione dei soli simboli di dati
received_symbols_data = ofdmFreqSignal_eq(idx_datasymbols);

%% Ricevitore e Decodifica
Received_Signal = zeros(2, length(data_symbols));

% Decisore a soglia (soglia = 0)
for k = 1:length(data_symbols)
    if real(received_symbols_data(k)) > 0
        Received_Signal(1,k) = 1;
    else
        Received_Signal(1,k) = -1;
    end
    if imag(received_symbols_data(k)) > 0
        Received_Signal(2,k) = 1;
    else
        Received_Signal(2,k) = -1;
    end
end

%% BER
% differenza tra ciò che trasmetto e ciò che ricevo

received = reshape(Received_Signal,1,num_bits_data); 
% total_errors = 0;
% total_bits = 0;
Diff = Received_Signal - bits_r;
nerrori = 0;
for k = 1 : length(received)
    if (abs(received(k) - bits(k)) ~= 0)
        nerrori = nerrori + 1;
    end 
end
% Conteggio errori (sommo agli errori totali di questo step SNR)
% nerrori_frame = sum(abs(received - bits) ~= 0);
% total_errors = total_errors + nerrori_frame;
% total_bits = total_bits + num_bits_data;

Diff2 = received - bits;

fprintf("Numero di errori = %d\n", nerrori);

n = sum(abs(received-bits)/2);

end