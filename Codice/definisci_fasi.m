function fasi = definisci_fasi()
% DEFINISCI_FASI  Restituisce le fasi epidemiologiche con date e T_R.
%
% Ogni elemento dello struct ha:
%   nome    - stringa descrittiva
%   inizio  - datetime inizio fase
%   fine    - datetime fine fase
%   T_R     - tempo di rimozione 1/gamma in giorni (valore centrale)
%   T_R_err - incertezza su T_R in giorni (±)
%   colore  - colore RGB per i grafici
%
% Fonti T_R: MaterialeRiferimento/report_gamma_SIR_Italia.md

    d = @(s) datetime(s, 'InputFormat', 'dd/MM/yyyy');

    fasi(1).nome         = 'Ancestrale + Alpha';
    fasi(1).inizio       = d('29/01/2020');
    fasi(1).fine         = d('20/07/2021');
    fasi(1).T_R          = 9.7;              % Lazzizzera 2021 (arXiv:2106.01602v2)
    fasi(1).T_R_err      = 2.0;              % ±2 giorni (Lazzizzera 2021)
    fasi(1).colore       = [0.15 0.40 0.75]; % blu
    fasi(1).colore_errore = [0.85 0.55 0.10]; % arancio

    fasi(2).nome         = 'Delta';
    fasi(2).inizio       = d('21/07/2021');
    fasi(2).fine         = d('31/12/2021');
    fasi(2).T_R          = 7.0;              % scaling su GT Delta (Xu et al. 2023): 9.7 × 3.65/4.95 ≈ 7.1 d
    fasi(2).T_R_err      = 1.0;              % ±1 giorno
    fasi(2).colore       = [0.85 0.33 0.10]; % arancio-rosso
    fasi(2).colore_errore = [0.10 0.50 0.80]; % blu

    fasi(3).nome         = 'Omicron BA.1/BA.2';
    fasi(3).inizio       = d('01/01/2022');
    fasi(3).fine         = d('31/05/2022');
    fasi(3).T_R          = 6.0;              % scaling su GT BA.1 (Xu et al. 2023): 9.7 × 2.99/4.95 ≈ 5.9 d
    fasi(3).T_R_err      = 1.0;              % ±1 giorno
    fasi(3).colore       = [0.13 0.65 0.30]; % verde
    fasi(3).colore_errore = [0.70 0.20 0.65]; % viola

    fasi(4).nome         = 'Omicron BA.5+';
    fasi(4).inizio       = d('01/06/2022');
    fasi(4).fine         = d('30/03/2023');
    fasi(4).T_R          = 5.0;              % scaling su SI BA.5 (Xu et al. 2023): 9.7 × 2.37/4.95 ≈ 4.6 d
    fasi(4).T_R_err      = 1.0;              % ±1 giorno
    fasi(4).colore       = [0.60 0.20 0.70]; % viola
    fasi(4).colore_errore = [0.20 0.65 0.25]; % verde

    fasi(5).nome         = 'Post-INFN (XBB+)';
    fasi(5).inizio       = d('31/03/2023');
    fasi(5).fine         = d('06/01/2026');
    fasi(5).T_R          = 5.0;              % stima per XBB+ (nessun INFN disponibile)
    fasi(5).T_R_err      = 1.0;              % ±1 giorno (stima)
    fasi(5).colore       = [0.40 0.40 0.40]; % grigio
    fasi(5).colore_errore = [0.75 0.30 0.10]; % rosso-mattone
end
