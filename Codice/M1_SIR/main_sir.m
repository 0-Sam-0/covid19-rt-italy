%% 
% MAIN_SIR  Calcola e plotta Rt col metodo SIR per ogni fase epidemica.
%
% Per ogni fase:
%   - usa T_R specifico della variante dominante
%   - sovrappone Rt INFN ufficiale (dove disponibile)
%   - produce un grafico separato
%
% Se rt_sir_results.mat esiste nella stessa cartella, carica i risultati
% pre-calcolati saltando il calcolo. Altrimenti calcola e salva il file.

clear; close all; clc;

% Funzioni condivise (carica_dati, definisci_fasi) si trovano nella cartella padre
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% Sorgente dati casi:
%   'iss' - nuovi casi ISS per data di prelievo (iss-covid19.csv)
%   'dpc' - nuovi positivi DPC per data di referto (dpc-covid19.json)
DATA_SOURCE = 'dpc';

% Modalità smoothing — solo per DATA_SOURCE = 'iss':
%   'pre'  - media mobile su C(t) PRIMA del calcolo di Rt  [rt_iss_pre]
%   'post' - Rt calcolato dai casi grezzi, poi media mobile su Rt [rt_iss_post]
% Con DATA_SOURCE = 'dpc' questo flag è ignorato: si usa sempre totale_positivi
% come I(t) diretto con post-smoothing su Rt [rt_dpc].
SMOOTH_MODE = 'post';

% --- Carica dati ---
[date_casi, casi, totale_pos, date_rt_infn, rt_infn, rt_lower, rt_upper] = carica_dati(DATA_SOURCE);
fasi = definisci_fasi();

% Margine di warmup in giorni prima dell'inizio di ogni fase
MARGINE_WARMUP = 30;

% ============================================================
% Calcolo Rt — carica da file o ricalcola
% ============================================================
mat_path = fullfile(fileparts(mfilename('fullpath')), 'rt_sir_results.mat');

if isfile(mat_path)
    fprintf('Carico risultati SIR da file: %s\n', mat_path);
    load(mat_path, 'risultati', 'date_comb', 'Rt_comb', 'Rt_comb_lo', 'Rt_comb_hi');
else
    fprintf('Calcolo Rt SIR (sorgente: %s, smooth: %s)...\n', DATA_SOURCE, SMOOTH_MODE);
    risultati  = struct([]);
    date_comb  = datetime.empty(0, 1);
    Rt_comb    = [];
    Rt_comb_lo = [];
    Rt_comb_hi = [];

    for i = 1 : length(fasi)
        fase = fasi(i);
        win  = round(fase.T_R);

        inizio_con_margine = fase.inizio - days(MARGINE_WARMUP);
        idx_dati = date_casi >= inizio_con_margine & date_casi <= fase.fine;

        if sum(idx_dati) < win + 7
            fprintf('Fase "%s": dati insufficienti, salto.\n', fase.nome);
            risultati(i).date_fase = [];
            continue;
        end

        date_sub = date_casi(idx_dati);
        casi_sub = casi(idx_dati);

        % Calcola Rt per T_R centrale e per i due estremi dell'errore
        if strcmp(DATA_SOURCE, 'dpc')
            totale_sub = totale_pos(idx_dati);
            [Rt_full,    date_full] = rt_dpc(date_sub, totale_sub, fase.T_R);
            [Rt_full_lo, ~        ] = rt_dpc(date_sub, totale_sub, fase.T_R - fase.T_R_err);
            [Rt_full_hi, ~        ] = rt_dpc(date_sub, totale_sub, fase.T_R + fase.T_R_err);
        else
            if strcmp(SMOOTH_MODE, 'post')
                fn = @rt_iss_post;
            else
                fn = @rt_iss_pre;
            end
            [Rt_full,    date_full] = fn(date_sub, casi_sub, fase.T_R);
            [Rt_full_lo, ~        ] = fn(date_sub, casi_sub, fase.T_R - fase.T_R_err);
            [Rt_full_hi, ~        ] = fn(date_sub, casi_sub, fase.T_R + fase.T_R_err);
        end

        % Taglia al solo periodo della fase (scarta il warmup)
        idx_fase   = date_full >= fase.inizio;
        Rt_fase    = Rt_full(idx_fase);
        Rt_fase_lo = Rt_full_lo(idx_fase);
        Rt_fase_hi = Rt_full_hi(idx_fase);
        date_fase  = date_full(idx_fase);

        % Rt INFN per questo periodo
        idx_infn = date_rt_infn >= fase.inizio & date_rt_infn <= fase.fine;

        % Salva risultati per questa fase
        risultati(i).fase        = fase;
        risultati(i).date_fase   = date_fase;
        risultati(i).Rt_fase     = Rt_fase;
        risultati(i).Rt_fase_lo  = Rt_fase_lo;
        risultati(i).Rt_fase_hi  = Rt_fase_hi;
        risultati(i).ha_infn     = any(idx_infn);
        risultati(i).date_infn   = date_rt_infn(idx_infn);
        risultati(i).rt_infn_f   = rt_infn(idx_infn);
        risultati(i).rt_lower_f  = rt_lower(idx_infn);
        risultati(i).rt_upper_f  = rt_upper(idx_infn);

        % Accumula per il grafico combinato
        date_comb  = [date_comb;  date_fase];
        Rt_comb    = [Rt_comb;    Rt_fase];
        Rt_comb_lo = [Rt_comb_lo; Rt_fase_lo];
        Rt_comb_hi = [Rt_comb_hi; Rt_fase_hi];
    end

    save(mat_path, 'risultati', 'date_comb', 'Rt_comb', 'Rt_comb_lo', 'Rt_comb_hi');
    fprintf('Risultati SIR salvati: %s\n', mat_path);
end

% ============================================================
% Grafici per fase
% ============================================================
for i = 1 : length(risultati)
    if isempty(risultati(i).date_fase)
        continue;
    end

    fase       = risultati(i).fase;
    date_fase  = risultati(i).date_fase;
    Rt_fase    = risultati(i).Rt_fase;
    Rt_fase_lo = risultati(i).Rt_fase_lo;
    Rt_fase_hi = risultati(i).Rt_fase_hi;
    ha_infn    = risultati(i).ha_infn;

    % --- Grafico ---
    fig = figure('Name', fase.nome, 'NumberTitle', 'off', ...
                 'Position', [100 100 900 400]);
    hold on;

    if ha_infn
        date_infn_fase = risultati(i).date_infn;
        rt_infn_fase   = risultati(i).rt_infn_f;
        rt_lower_fase  = risultati(i).rt_lower_f;
        rt_upper_fase  = risultati(i).rt_upper_f;

        % Banda IC 95% INFN
        x_fill = [date_infn_fase; flipud(date_infn_fase)];
        y_fill = [rt_upper_fase;  flipud(rt_lower_fase)];
        fill(x_fill, y_fill, [0.75 0.75 0.75], ...
             'EdgeColor', 'none', 'FaceAlpha', 0.5, ...
             'DisplayName', 'IC 95% INFN');

        plot(date_infn_fase, rt_infn_fase, 'k-', ...
             'LineWidth', 1.8, 'DisplayName', 'R_t INFN ufficiale');
    end

    % Rt calcolato col metodo SIR — curva centrale
    plot(date_fase, Rt_fase, '-', 'Color', fase.colore, ...
         'LineWidth', 1.8, ...
         'DisplayName', sprintf('R_t SIR  (T_R = %.1f d)', fase.T_R));

    % Curve di errore T_R ± T_R_err (linee tratteggiate, colore distinto)
    plot(date_fase, Rt_fase_lo, '--', 'Color', fase.colore_errore, ...
         'LineWidth', 0.9, ...
         'DisplayName', sprintf('R_t SIR  (T_R = %.1f d)', fase.T_R - fase.T_R_err));
    plot(date_fase, Rt_fase_hi, '--', 'Color', fase.colore_errore, ...
         'LineWidth', 0.9, ...
         'DisplayName', sprintf('R_t SIR  (T_R = %.1f d)', fase.T_R + fase.T_R_err));

    % Soglia epidemica
    yline(1, 'k--', 'LineWidth', 1.2, 'DisplayName', 'soglia = 1');

    xlim([date_fase(1), date_fase(end)]);
    xlabel('Data');
    ylabel('R_t');
    title(sprintf('R_t — %s', fase.nome));
    legend('Location', 'best');
    ylim([0 4]);
    grid on;
    hold off;

    % Salva figura
    nome_sicuro = regexprep(fase.nome, '[/ \\]', '_');
    nome_file = fullfile(fileparts(mfilename('fullpath')), ...
                         sprintf('rt_fase_%d_%s.png', i, nome_sicuro));
    saveas(fig, nome_file);
    fprintf('Fase %d "%s" completata. Figura: %s\n', i, fase.nome, nome_file);

    % Errore massimo SIR vs INFN (solo dove entrambi disponibili)
    if ha_infn
        [~, ia, ib] = intersect(date_fase, date_infn_fase);

        if ~isempty(ia)
            % Errore vs valore centrale INFN: min distanza tra le 3 curve SIR
            err_c  = abs(Rt_fase(ia)    - rt_infn_fase(ib));
            err_lo = abs(Rt_fase_lo(ia) - rt_infn_fase(ib));
            err_hi = abs(Rt_fase_hi(ia) - rt_infn_fase(ib));
            errori_centrale = min([err_c, err_lo, err_hi], [], 2);
            errori_centrale = errori_centrale(~isnan(errori_centrale));

            % Errore vs IC 95% INFN: distanza tra la banda SIR e la banda INFN
            min_sir = min([Rt_fase(ia), Rt_fase_lo(ia), Rt_fase_hi(ia)], [], 2);
            max_sir = max([Rt_fase(ia), Rt_fase_lo(ia), Rt_fase_hi(ia)], [], 2);
            errori_ci = max(0, max(min_sir - rt_upper_fase(ib), ...
                                   rt_lower_fase(ib) - max_sir));
            errori_ci = errori_ci(~isnan(errori_ci));

            if ~isempty(errori_centrale)
                fprintf('  -> max errore SIR vs INFN centrale: %.3f\n', max(errori_centrale));
            end
            if ~isempty(errori_ci)
                fprintf('  -> max errore SIR vs IC95 INFN:     %.3f\n', max(errori_ci));
            end
        end
    end
end

% ============================================================
% Grafico combinato: tutte le fasi insieme
% ============================================================
fig_all = figure('Name', 'Rt tutte le fasi', 'NumberTitle', 'off', ...
                 'Position', [100 100 1200 450]);
hold on;

% Banda IC 95% INFN
x_fill = [date_rt_infn; flipud(date_rt_infn)];
y_fill = [rt_upper;     flipud(rt_lower)];
fill(x_fill, y_fill, [0.75 0.75 0.75], ...
     'EdgeColor', 'none', 'FaceAlpha', 0.5, 'DisplayName', 'IC 95% INFN');

plot(date_rt_infn, rt_infn, 'k-', 'LineWidth', 1.8, 'DisplayName', 'R_t ufficiale');

plot(date_comb, Rt_comb, '-', 'Color', [0.85 0.10 0.10], ...
     'LineWidth', 1.5, 'DisplayName', 'R_t SIR');

yline(1, 'k-', 'LineWidth', 1.2, 'DisplayName', 'soglia');

xlim([date_comb(1), date_comb(end)]);
xlabel('Data');
ylabel('R_t');
title('R_t calcolato con modello SIR');
legend('Location', 'best');
ylim([0 4]);
grid on;
hold off;

nome_file_all = fullfile(fileparts(mfilename('fullpath')), 'rt_tutte_le_fasi.png');
saveas(fig_all, nome_file_all);
fprintf('Grafico combinato salvato: %s\n', nome_file_all);
