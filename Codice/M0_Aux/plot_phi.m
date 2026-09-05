% PLOT_PHI  Distribuzione del tempo di generazione phi(s) — Figura 4 di Cipressi.
%
% Mostra il confronto fra la densità Gamma continua e la sua discretizzazione
% sugli intervalli [s-0.5, s+0.5], realizzata con quad come nel calcolo MC.
%
% Parametri: alpha=1.87, beta=0.28 (Guzzetta, Merler 7/12/2020)

clear; close all; clc;

base_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(base_dir, '..'));
addpath(fullfile(base_dir, '..', 'M2_MCMC'));

ALPHA = 1.87;
THETA = 1 / 0.28;
S_MAX  = 25;
S_PLOT = 30;   % mostra fino a 30 per evidenziare il taglio a 25

phi = phi_gamma(ALPHA, THETA, S_MAX);

f_gamma = @(u) u.^(ALPHA-1) .* exp(-u./THETA) ./ (gamma(ALPHA) .* THETA.^ALPHA);

f_cont  = f_gamma;
s_cont  = linspace(0.01, S_PLOT, 600);

fig = figure('Name', 'Distribuzione del tempo di generazione', ...
             'NumberTitle', 'off', 'Position', [100 100 700 450]);

bar(1:S_MAX, phi, 1, 'FaceColor', [0.10 0.20 0.80], 'EdgeColor', 'white', ...
    'LineWidth', 0.5, 'DisplayName', 'Discretizzazione');
hold on;
plot(s_cont, f_cont(s_cont), 'r-', 'LineWidth', 1.8, 'DisplayName', 'Infettività');
hold off;

xlim([0 S_PLOT]);
xlabel('Giorni');
ylabel('Infettività');
title('Distribuzione del tempo di generazione');
legend('Location', 'northeast');
grid on;

nome_file = fullfile(base_dir, 'phi_distribuzione.png');
saveas(fig, nome_file);
fprintf('Grafico phi salvato: %s\n', nome_file);
fprintf('  media = %.3f giorni,  sum(phi) = %.8f\n', sum((1:S_MAX)' .* phi), sum(phi));
