function [Rt, date_out] = rt_iss_pre(date_in, casi_in, T_R)
% RT_ISS_PRE  Stima Rt col metodo SIR da nuovi casi ISS — smoothing PRE calcolo.
%
% Formula:
%   C_smooth(t) = media mobile causale a 7 giorni di casi_in(t)
%   I(t)        = sum_{k=0}^{win-1} C_smooth(t-k)   (attivi ricostruiti)
%   Rt(t)       = 1 + T_R * [C_smooth(t) - C_smooth(t-win)] / I(t)
%
% dove win = round(T_R).
%
% Input:
%   date_in  - vettore datetime (deve includere un margine di warmup
%              di almeno win+7 giorni prima della fase di interesse)
%   casi_in  - nuovi casi giornalieri (iss-covid19.csv)
%   T_R      - tempo di rimozione 1/gamma in giorni
%
% Output:
%   Rt       - vettore Rt (NaN nei primi win+6 giorni di warmup)
%   date_out - stessi datetime di date_in

    win      = round(T_R);
    n        = length(casi_in);

    % Media mobile a 7 giorni (giorno corrente + 6 precedenti)
    C_smooth = movmean(casi_in, [6 0]);

    Rt       = NaN(n, 1);

    for t = win + 7 : n
        % Infetti attivi ricostruiti: somma dei nuovi casi lisciati
        % nelle ultime win giornate (proxy di I(t) del modello SIR)
        I_t     = sum(C_smooth(t - win + 1 : t));

        % Variazione di I(t): I(t) - I(t-1) si riduce a soli due termini
        % per cancellazione telescopica degli win-1 termini centrali
        delta_I = C_smooth(t) - C_smooth(t - win);
        if I_t > 0
          Rt(t) = 1 + T_R * delta_I / I_t;
        else
          % I_t = 0: Rt non definito. Si forza a 0 per comodità di plot.
          % Commentare questo else per mantenere NaN.
          Rt(t) = 0;
        end
    end

    date_out = date_in;
end
