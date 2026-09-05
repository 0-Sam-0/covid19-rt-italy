% PLOT_EVENTI  Rt MC con annotazioni degli eventi socio-politici principali.
%
% Produce un grafico del Rt (metodo Monte Carlo-Metropolis, dati DPC) con linee
% verticali per i principali provvedimenti e fenomeni dell'epidemia COVID-19
% in Italia. Utile per interpretare i picchi e i cali di Rt.

clear; close all; clc;

base_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(base_dir, '..'));

[~, ~, ~, date_rt_infn, rt_infn, rt_lower, rt_upper] = carica_dati('dpc');

% Carica Rt MC pre-calcolato da main_mc.m
% (eseguire main_mc.m almeno una volta prima di questo script)
mat_path = fullfile(base_dir, '..', 'M2_MCMC', 'rt_mc_results.mat');
if ~isfile(mat_path)
    error('File rt_mc_results.mat non trovato. Eseguire prima main_mc.m in M2_MCMC/.');
end
res      = load(mat_path);
Rt       = res.Rt_mc;
date_out = res.date_casi;

% --- Tabella eventi: {datetime, etichetta} ---
d = @(s) datetime(s, 'InputFormat', 'dd/MM/yyyy');
eventi = {
    d('09/03/2020'), 'Lockdown naz.';
    d('04/05/2020'), 'Fase 2 (fine lockdown)';
    d('15/07/2020'), 'Estate 2020';
    d('25/10/2020'), 'DPCM ott 2020';
    d('05/11/2020'), 'Zone rosse/arancio';
    d('27/12/2020'), 'Vaccinazioni';
    d('26/04/2021'), 'Riaperture primavera';
    d('21/06/2021'), 'Fine coprifuoco';
    d('21/07/2021'), 'Variante Delta';
    d('01/01/2022'), 'Omicron BA.1';
    d('01/06/2022'), 'Omicron BA.5+';
};

fig = figure('Name', 'Rt MC — eventi', 'NumberTitle', 'off', ...
             'Position', [100 100 1400 500]);
hold on;

% Banda IC 95% INFN
x_fill = [date_rt_infn; flipud(date_rt_infn)];
y_fill = [rt_upper;     flipud(rt_lower)];
fill(x_fill, y_fill, [0.75 0.75 0.75], 'EdgeColor', 'none', 'FaceAlpha', 0.4, ...
     'HandleVisibility', 'off');

plot(date_rt_infn, rt_infn, 'k-', 'LineWidth', 1.5, 'DisplayName', 'INFN ufficiale');
plot(date_out,     Rt,      '-',  'Color', [0.10 0.50 0.85], 'LineWidth', 1.2, ...
     'DisplayName', 'R_t MC');
yline(1, 'k--', 'LineWidth', 0.9, 'HandleVisibility', 'off');

% Annotazioni verticali
for k = 1 : size(eventi, 1)
    ev_date  = eventi{k, 1};
    ev_label = eventi{k, 2};

    if ev_date < date_out(1) || ev_date > date_out(end)
        continue;
    end

    xline(ev_date, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 0.8, ...
          'HandleVisibility', 'off');
    text(ev_date + days(4), 3.85, ev_label, 'FontSize', 6.5, 'Color', [0.25 0.25 0.25], ...
         'Rotation', 90, 'HorizontalAlignment', 'right');
end

xlim([date_out(1), date_out(end)]);
ylim([0 4]);
xlabel('Data');
ylabel('R_t');
title('R_t calcolato con metodo MC-Metropolis — principali eventi COVID-19 in Italia');
legend('Location', 'northeast');
grid on;
hold off;

nome_file = fullfile(base_dir, 'rt_mc_eventi.png');
saveas(fig, nome_file);
fprintf('Grafico eventi salvato: %s\n', nome_file);
