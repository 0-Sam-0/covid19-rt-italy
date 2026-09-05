% PLOT_NUOVI_CASI  Nuovi positivi giornalieri — proxy per la Figura 3 di Cipressi.
%
% Cipressi usa i dati ISS dei sintomatici (non disponibili come serie pubblica).
% Si usa nuovi_positivi DPC come proxy; la forma della curva è analoga ma la
% scala è circa 100x superiore (positivi vs sintomatici ISS).

clear; close all; clc;

base_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(base_dir, '..'));

[date_casi, casi, ~, ~, ~, ~, ~] = carica_dati('dpc');

fig = figure('Name', 'Nuovi positivi giornalieri (proxy sintomatici)', ...
             'NumberTitle', 'off', 'Position', [100 100 900 400]);

plot(date_casi, movmean(casi, [6 0]), '-', ...
     'Color', [0.10 0.55 0.90], 'LineWidth', 1.2);

xlim([date_casi(1), date_casi(end)]);
xlabel('Data');
ylabel('nuovi positivi (media mobile 7gg)');
title('Nuovi positivi giornalieri (DPC nuovi\_positivi)');
grid on;

nome_file = fullfile(base_dir, 'nuovi_casi.png');
saveas(fig, nome_file);
fprintf('Grafico nuovi casi salvato: %s\n', nome_file);
