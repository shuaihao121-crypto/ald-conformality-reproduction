function write_json(path_value,value)
%WRITE_JSON UTF-8 JSON; nonfinite numeric values follow MATLAB jsonencode.
file = fopen(path_value,'w','n','UTF-8');
if file < 0, error('aldrepro:WriteFailed','Cannot open %s',path_value); end
cleanup = onCleanup(@() fclose(file)); %#ok<NASGU>
fprintf(file,'%s\n',jsonencode(value));
end
