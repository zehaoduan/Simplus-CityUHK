function S = ToJsonValue(S)
% Recursively replace Inf/NaN/complex so jsonencode can emit JSON.

if isnumeric(S)
    if isempty(S)
        return
    end
    if ~isreal(S)
        if isscalar(S)
            out.real = real(S);
            out.imag = imag(S);
            S = out;
            return
        end
        C = cell(size(S));
        for i = 1:numel(S)
            C{i} = SimplusGT.IO.ToJsonValue(S(i));
        end
        S = C;
        return
    end
    if isscalar(S)
        if isinf(S)
            if S > 0
                S = 'inf';
            else
                S = '-inf';
            end
        elseif isnan(S)
            S = 'nan';
        end
        return
    end
    if any(isinf(S(:))) || any(isnan(S(:)))
        C = num2cell(S);
        for i = 1:numel(C)
            C{i} = SimplusGT.IO.ToJsonValue(C{i});
        end
        S = C;
    end
    return
end

if isstruct(S)
    f = fieldnames(S);
    for i = 1:numel(S)
        for k = 1:numel(f)
            S(i).(f{k}) = SimplusGT.IO.ToJsonValue(S(i).(f{k}));
        end
    end
    return
end

if iscell(S)
    for i = 1:numel(S)
        S{i} = SimplusGT.IO.ToJsonValue(S{i});
    end
end
end
