function Rt_est = metropolis_rt(C_t, lambda_base, N_iter, N_burnin, delta)
% METROPOLIS_RT  Stima Rt per un singolo giorno tramite algoritmo Metropolis.
%
% Verosimiglianza: L(Rt) = P(C_t | Rt * lambda_base)  [Poisson]
% Proposta: uniforme centrata, Rt* = Rt + U(-delta, +delta)
% Accettazione: min(1, L(Rt*)/L(Rt))
%
% Input:
%   C_t         - casi sintomatici osservati al giorno t
%   lambda_base - sum_{s=1}^{S_max} phi(s) * C(t-s)  [costante per t fissato]
%   N_iter      - numero totale di passi Metropolis
%   N_burnin    - passi iniziali scartati (burn-in)
%   delta       - semi-ampiezza della proposta uniforme (default: 1.5)
%
% Output:
%   Rt_est  - stima di Rt (media della catena post burn-in)
%             NaN se lambda_base <= 0 o C_t non valido

    % Casi non calcolabili
    if lambda_base <= 0 || isnan(C_t) || C_t < 0
        Rt_est = NaN;
        return;
    end

    % Caso degenere: nessun caso osservato
    % (MLE = 0, ma Rt = 0 non è fisicamente significativo)
    if C_t == 0
        Rt_est = NaN;
        return;
    end

    chain = zeros(N_iter, 1);
    Rt    = 1.0;            % valore iniziale

    for k = 1 : N_iter
        % Proposta uniforme centrata sul valore corrente
        Rt_prop = Rt + delta * (2 * rand() - 1);

        if Rt_prop > 0
            % Log-ratio di verosimiglianza (termine costante C_t*log(lambda_base) si cancella)
            % ell(Rt*) - ell(Rt) = C_t*log(Rt*/Rt) - lambda_base*(Rt* - Rt)
            log_rho = C_t * log(Rt_prop / Rt) - lambda_base * (Rt_prop - Rt);

            % Accetta con probabilità min(1, exp(log_rho))
            if log_rho >= 0 || log(rand()) < log_rho
                Rt = Rt_prop;
            end
            % Se log_rho = -Inf (Rt_prop -> 0): rifiuto automatico
        end
        % Se Rt_prop <= 0: rifiuto automatico, Rt rimane invariato

        chain(k) = Rt;
    end

    % Stima: media della catena dopo il burn-in
    Rt_est = mean(chain(N_burnin + 1 : end));
end
