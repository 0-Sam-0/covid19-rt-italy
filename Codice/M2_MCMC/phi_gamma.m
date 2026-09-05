function phi = phi_gamma(alpha, theta, S_max)
% PHI_GAMMA  Discretizza la distribuzione Gamma dei tempi di generazione.
%
% Calcola phi(s) = P(s-0.5 <= X <= s+0.5) per X ~ Gamma(alpha, theta),
% tramite integrazione numerica (quad), come da metodologia ISS (Merler 2020).
% La distribuzione viene troncata a S_max giorni e rinormalizzata.
%
% Input:
%   alpha  - parametro di forma (shape) della Gamma
%   theta  - parametro di scala (scale): theta = 1/beta
%   S_max  - giorno di troncatura (contributo oltre S_max < 2e-3)
%
% Output:
%   phi    - vettore colonna S_max x 1, normalizzato (sum = 1)
%
% Parametri di riferimento (Guzzetta, Merler 7/12/2020):
%   alpha = 1.87,  beta = 0.28  =>  theta = 1/0.28 ~= 3.57 giorni
%   mu = alpha*theta ~= 6.68 giorni
%
% Nota: usa gamma() built-in di MATLAB (funzione di Eulero),
%       non richiede la Statistics Toolbox.

    % Densità Gamma implementata senza gampdf (no toolbox richiesto)
    f_gamma = @(u) u.^(alpha - 1) .* exp(-u ./ theta) ...
                   ./ (gamma(alpha) .* theta.^alpha);

    phi = zeros(S_max, 1);
    for s = 1 : S_max
        % Integra su [s-0.5, s+0.5], evitando lo 0 (dove f non è definita per alpha<1)
        phi(s) = quad(f_gamma, max(s - 0.5, 1e-9), s + 0.5);
    end

    % Rinormalizza dopo la troncatura
    phi = phi / sum(phi);
end
