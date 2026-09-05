% MAIN_MC  Calcola Rt con il metodo Monte Carlo--Metropolis (metodologia ISS).
%
% Sorgente dati: nuovi_positivi DPC (dpc-covid19.json).
% Il valore di Rt è indipendente dalla scala della serie C(t): il fattore
% moltiplicativo si cancella nel rapporto C(t) / sum(phi*C(t-s)).
% I dati dei sintomatici ISS darebbero la stessa curva Rt con sigma maggiore
% (meno casi => Poisson più piatta); nuovi_positivi DPC è matematicamente
% equivalente e già disponibile.
%
% Per ogni giorno t >= S_MAX+1:
%   1. Calcola lambda_base = sum_{s=1}^{S_MAX} phi(s) * C(t-s)
%   2. Stima Rt tramite algoritmo Metropolis su verosimiglianza poissoniana
%   3. Post-smoothing con media mobile causale a 7 giorni
%
% Output: grafici PNG in metodo2/

clear; close all; clc;

% Funzioni condivise (carica_dati, definisci_fasi) si trovano nella cartella padre
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% ============================================================
% Parametri
% ============================================================

% Distribuzione Gamma phi(s) — Guzzetta, Merler (7/12/2020)
ALPHA = 1.87;
BETA  = 0.28;       % theta = 1/BETA
THETA = 1 / BETA;
S_MAX = 25;         % troncatura: contributo oltre 25 giorni < 2e-3

% Metropolis
N_ITER   = 5000;    % passi totali per giorno
N_BURNIN = 500;     % burn-in scartato
DELTA    = 1.5;     % semi-ampiezza proposta uniforme

% ============================================================
% Carica dati (DPC: nuovi_positivi + infn-rt)
% ============================================================
[date_casi, casi, ~, date_rt_infn, rt_infn, rt_lower, rt_upper] = carica_dati('dpc');

% ============================================================
% Discretizza distribuzione Gamma
% ============================================================
phi = phi_gamma(ALPHA, THETA, S_MAX);

fprintf('phi(s): media = %.3f giorni, sum = %.8f\n', ...
        sum((1:S_MAX)' .* phi), sum(phi));

% ============================================================
% Calcolo Rt — carica da file o ricalcola
% ============================================================
n        = length(casi);
mat_path = fullfile(fileparts(mfilename('fullpath')), 'rt_mc_results.mat');

if isfile(mat_path)
    fprintf('Carico risultati MC da file: %s\n', mat_path);
    load(mat_path, 'Rt_mc');
else
    fprintf('Calcolo Rt MC per %d giorni (potrebbe richiedere qualche minuto)...\n', ...
            n - S_MAX);
    Rt_raw = NaN(n, 1);

    for t = S_MAX + 1 : n
        % lambda_base = sum_{s=1}^{S_MAX} phi(s) * C(t-s)
        % flipud: casi(t-S_MAX:t-1) e' [C(t-25),...,C(t-1)], va invertito
        % affinche' phi(s) moltiplichi C(t-s) e non C(t-S_MAX+s-1)
        lambda_base = phi' * flipud(casi(t - S_MAX : t - 1));

        Rt_raw(t) = metropolis_rt(casi(t), lambda_base, N_ITER, N_BURNIN, DELTA);

        if mod(t - S_MAX, 200) == 0
            fprintf('  ... giorno %d / %d\n', t - S_MAX, n - S_MAX);
        end
    end

    fprintf('Calcolo completato.\n');

    % Post-smoothing: media mobile causale a 7 giorni
    Rt_mc = movmean(Rt_raw, [6 0], 'omitnan');

    save(mat_path, 'Rt_mc', 'date_casi');
    fprintf('Risultati MC salvati: %s\n', mat_path);
end

% ============================================================
% Grafico combinato: intero periodo
% ============================================================
fig_all = figure('Name', 'Rt MC — tutte le fasi', 'NumberTitle', 'off', ...
                 'Position', [100 100 1200 450]);
hold on;

x_fill = [date_rt_infn; flipud(date_rt_infn)];
y_fill = [rt_upper;     flipud(rt_lower)];
fill(x_fill, y_fill, [0.75 0.75 0.75], ...
     'EdgeColor', 'none', 'FaceAlpha', 0.5, 'DisplayName', 'IC 95% INFN');

plot(date_rt_infn, rt_infn, 'k-', 'LineWidth', 1.8, 'DisplayName', 'R_t INFN ufficiale');
plot(date_casi,    Rt_mc,   '-',  'Color', [0.10 0.50 0.85], ...
     'LineWidth', 1.5, 'DisplayName', 'R_t MC');
yline(1, 'k-', 'LineWidth', 1.2, 'DisplayName', 'soglia');

xlim([date_casi(S_MAX + 1), date_casi(end)]);
xlabel('Data');
ylabel('R_t');
title('R_t calcolato con metodo Monte Carlo Metropolis');
legend('Location', 'best');
ylim([0 4]);
grid on;
hold off;

nome_file_all = fullfile(fileparts(mfilename('fullpath')), 'rt_mc_tutte_le_fasi.png');
saveas(fig_all, nome_file_all);
fprintf('Grafico combinato salvato: %s\n', nome_file_all);

% ============================================================
% Grafici per fase (zoom + confronto INFN)
% ============================================================
fasi = definisci_fasi();

for i = 1 : length(fasi)
    fase    = fasi(i);
    idx_c   = date_casi >= fase.inizio & date_casi <= fase.fine;

    if sum(idx_c) < S_MAX + 7
        fprintf('Fase "%s": dati insufficienti, salto.\n', fase.nome);
        continue;
    end

    date_fase = date_casi(idx_c);
    Rt_fase   = Rt_mc(idx_c);

    idx_infn = date_rt_infn >= fase.inizio & date_rt_infn <= fase.fine;
    ha_infn  = any(idx_infn);

    fig = figure('Name', fase.nome, 'NumberTitle', 'off', ...
                 'Position', [100 100 900 400]);
    hold on;

    if ha_infn
        x_fill = [date_rt_infn(idx_infn); flipud(date_rt_infn(idx_infn))];
        y_fill = [rt_upper(idx_infn);     flipud(rt_lower(idx_infn))];
        fill(x_fill, y_fill, [0.75 0.75 0.75], ...
             'EdgeColor', 'none', 'FaceAlpha', 0.5, 'DisplayName', 'IC 95% INFN');
        plot(date_rt_infn(idx_infn), rt_infn(idx_infn), 'k-', ...
             'LineWidth', 1.8, 'DisplayName', 'R_t INFN ufficiale');
    end

    plot(date_fase, Rt_fase, '-', 'Color', fase.colore, ...
         'LineWidth', 1.8, 'DisplayName', 'R_t MC');
    yline(1, 'k--', 'LineWidth', 1.2, 'DisplayName', 'soglia = 1');

    xlim([date_fase(1), date_fase(end)]);
    xlabel('Data');
    ylabel('R_t');
    title(sprintf('R_t MC — %s', fase.nome));
    legend('Location', 'best');
    ylim([0 4]);
    grid on;
    hold off;

    % Errore vs INFN (solo dove entrambi disponibili)
    if ha_infn
        date_infn_fase = date_rt_infn(idx_infn);
        rt_infn_fase   = rt_infn(idx_infn);
        [~, ia, ib]    = intersect(date_fase, date_infn_fase);
        if ~isempty(ia)
            errori = abs(Rt_fase(ia) - rt_infn_fase(ib));
            errori = errori(~isnan(errori));
            if ~isempty(errori)
                fprintf('Fase "%s": max errore MC vs INFN = %.3f\n', ...
                        fase.nome, max(errori));
            end
        end
    end

    nome_sicuro = regexprep(fase.nome, '[/ \\]', '_');
    nome_file   = fullfile(fileparts(mfilename('fullpath')), ...
                           sprintf('rt_mc_fase_%d_%s.png', i, nome_sicuro));
    saveas(fig, nome_file);
    fprintf('Fase %d "%s" completata.\n', i, fase.nome);
end
