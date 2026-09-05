function [date_casi, casi, totale_pos, date_rt_infn, rt_infn, rt_lower, rt_upper] = carica_dati(sorgente)
% CARICA_DATI  Carica i dati epidemiologici e Rt INFN ufficiale.
%
% Input:
%   sorgente - 'iss' (default): nuovi casi ISS per data di prelievo (iss-covid19.csv)
%              'dpc'          : nuovi positivi DPC per data di referto (dpc-covid19.json)
%
% Output:
%   date_casi    - vettore datetime
%   casi         - nuovi casi/positivi giornalieri
%   totale_pos   - attualmente positivi (solo DPC; [] per ISS)
%   date_rt_infn - vettore datetime Rt INFN
%   rt_infn      - Rt ufficiale INFN
%   rt_lower     - IC 95% lower
%   rt_upper     - IC 95% upper

    if nargin < 1
        sorgente = 'iss';
    end

    % carica_dati.m si trova in Codice/; i dati sono in Dati/ (cartella sorella)
    base    = fileparts(fileparts(mfilename('fullpath')));
    path_rt = fullfile(base, 'Dati', 'infn-rt.csv');

    % --- Sorgente casi ---
    if strcmp(sorgente, 'dpc')

        path_dpc = fullfile(base, 'Dati', 'dpc-covid19.json');
        fid      = fopen(path_dpc, 'r', 'n', 'UTF-8');
        raw_text = fread(fid, inf, 'uint8=>char')';
        fclose(fid);
        dpc = jsondecode(raw_text);

        n          = length(dpc);
        date_casi  = NaT(n, 1);
        casi       = NaN(n, 1);
        totale_pos = NaN(n, 1);

        for k = 1 : n
            date_casi(k) = datetime(dpc(k).data, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
            np = dpc(k).nuovi_positivi;
            tp = dpc(k).totale_positivi;
            if isnumeric(np) && ~isempty(np)
                casi(k) = max(np, 0);   % correzioni negative occasionali → 0
            end
            if isnumeric(tp) && ~isempty(tp)
                totale_pos(k) = tp;
            end
        end

        % Rimuovi componente oraria (es. T18:00:00)
        date_casi = dateshift(date_casi, 'start', 'day');

        % Rimuovi righe senza casi validi
        validi     = ~isnan(casi);
        date_casi  = date_casi(validi);
        casi       = casi(validi);
        totale_pos = totale_pos(validi);

    else  % 'iss'

        path_casi = fullfile(base, 'Dati', 'iss-covid19.csv');
        fid       = fopen(path_casi, 'r', 'n', 'UTF-8');
        raw       = textscan(fid, '%s %f', 'Delimiter', ';', 'HeaderLines', 1);
        fclose(fid);

        date_casi  = datetime(raw{1}, 'InputFormat', 'dd/MM/yyyy');
        casi       = raw{2};
        totale_pos = [];   % non disponibile per ISS

    end

    % --- Rt INFN (separatore ; decimale virgola) ---
    fid = fopen(path_rt, 'r', 'n', 'UTF-8');
    % colonne: giorno;rt;stat95_upper;stat95_lower;ci68_lower;ci68_upper;ci95_lower;ci95_upper
    raw = textscan(fid, '%s %s %s %s %s %s %s %s', ...
                   'Delimiter', ';', 'HeaderLines', 1);
    fclose(fid);

    date_rt_infn = datetime(raw{1}, 'InputFormat', 'dd/MM/yyyy');

    to_double = @(col) str2double(strrep(col, ',', '.'));
    rt_infn  = to_double(raw{2});
    rt_lower = to_double(raw{7});   % ci95_lower
    rt_upper = to_double(raw{8});   % ci95_upper

    % Rimuovi righe senza dati
    validi       = ~isnan(rt_infn);
    date_rt_infn = date_rt_infn(validi);
    rt_infn      = rt_infn(validi);
    rt_lower     = rt_lower(validi);
    rt_upper     = rt_upper(validi);
end
