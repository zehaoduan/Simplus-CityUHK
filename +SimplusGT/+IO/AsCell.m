function C = AsCell(x)
% Normalize a JSON array of objects to a column cell of structs.

if isempty(x)
    C = {};
    return
end
if iscell(x)
    C = x(:);
    return
end
if isstruct(x)
    C = num2cell(x(:));
    return
end
error('Expected a JSON array of objects.');
end
