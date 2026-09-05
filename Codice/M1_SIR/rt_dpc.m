function [Rt, date_out] = rt_dpc(date_in, totale_pos_in, T_R)
% RT_DPC  Stima Rt usando totale_positivi DPC come I(t) diretto.
%
% Con i dati DPC non serve ricostruire I(t) dalla somma dei nuovi casi:
% totale_positivi è già il numero di attualmente positivi = I(t) del SIR.
%
% Formula:
%   delta_I   = totale_pos(t) - totale_pos(t-1)
%   Rt_raw(t) = 1 + T_R * delta_I / totale_pos(t)
%   Rt(t)     = media mobile causale a 7 giorni di Rt_raw(t)
%
% Input:
%   date_in       - vettore datetime (deve includere un margine di warmup
%                   di almeno 7 giorni prima della fase di interesse)
%   totale_pos_in - attualmente positivi giornalieri (DPC totale_positivi)
%   T_R           - tempo di rimozione 1/gamma in giorni
%
% Output:
%   Rt       - vettore Rt smoothed (NaN al primo giorno)
%   date_out - stessi datetime di date_in

    n      = length(totale_pos_in);
    Rt_raw = NaN(n, 1);

    for t = 2 : n
        I_t     = totale_pos_in(t);
        delta_I = totale_pos_in(t) - totale_pos_in(t - 1);

        if I_t > 0
            Rt_raw(t) = 1 + T_R * delta_I / I_t;
        else
            % I_t = 0: Rt non definito. Si forza a 0 per comodità di plot.
            % Commentare questo else per mantenere NaN (comportamento corretto).
            Rt_raw(t) = 0;
        end
    end

    % Media mobile causale a 7 giorni su Rt_raw (post-smoothing)
    Rt = movmean(Rt_raw, [6 0], 'omitnan');

    date_out = date_in;
end
