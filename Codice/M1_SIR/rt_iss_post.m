function [Rt, date_out] = rt_iss_post(date_in, casi_in, T_R)
% RT_ISS_POST  Stima Rt col metodo SIR da nuovi casi ISS — smoothing POST calcolo.
%
% Approccio Cipressi: Rt calcolato dai casi grezzi giorno per giorno,
% poi media mobile causale a 7 giorni applicata su Rt (non sui casi).
%
% Formula:
%   I(t)      = sum_{k=0}^{win-1} C(t-k)        (casi grezzi)
%   Rt_raw(t) = 1 + T_R * [C(t) - C(t-win)] / I(t)
%   Rt(t)     = media mobile causale a 7 giorni di Rt_raw(t)
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
%   Rt       - vettore Rt smoothed (NaN nei primi win giorni)
%   date_out - stessi datetime di date_in

    win    = round(T_R);
    n      = length(casi_in);
    Rt_raw = NaN(n, 1);

    for t = win + 1 : n
        % Infetti attivi ricostruiti: somma dei casi grezzi
        % nelle ultime win giornate (proxy di I(t) del modello SIR)
        I_t = sum(casi_in(t - win + 1 : t));

        % Variazione di I(t): cancellazione telescopica degli win-1 termini centrali
        delta_I = casi_in(t) - casi_in(t - win);

        if I_t > 0
            Rt_raw(t) = 1 + T_R * delta_I / I_t;
        else
            % I_t = 0: Rt non definito. Si forza a 0 per comodità di plot.
            % Commentare questo else per mantenere NaN (comportamento corretto).
            Rt_raw(t) = 0;
        end
    end

    % Media mobile causale a 7 giorni applicata su Rt_raw
    % 'omitnan': non propaga i NaN iniziali nella finestra
    Rt = movmean(Rt_raw, [6 0], 'omitnan');

    date_out = date_in;
end
