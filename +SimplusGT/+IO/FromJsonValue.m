function v = FromJsonValue(v)
% Convert JSON scalars that stand in for MATLAB specials.
% "inf" / "-inf" / "nan" strings become Inf / -Inf / NaN.
% Empty and missing stay empty.

if isempty(v)
    v = [];
    return
end

if isstring(v) || ischar(v)
    s = strtrim(char(v));
    if strcmpi(s, 'inf')
        v = Inf;
    elseif strcmpi(s, '-inf')
        v = -Inf;
    elseif strcmpi(s, 'nan')
        v = NaN;
    else
        n = str2double(s);
        if ~isnan(n) && ~isempty(s)
            v = n;
        end
    end
    return
end

if isnumeric(v)
    v = double(v);
    return
end

if islogical(v)
    v = double(v);
    return
end

if isstruct(v) && isfield(v, 'real') && isfield(v, 'imag')
    v = double(v.real) + 1i * double(v.imag);
    return
end
end
