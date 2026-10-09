function value = file_hash(path_value)
%FILE_HASH SHA-256 of a data file; excludes newline or encoding transformations.
file = fopen(path_value,'rb');
if file<0, error('aldrepro:MissingFile','Cannot read %s',path_value); end
cleanup = onCleanup(@() fclose(file)); %#ok<NASGU>
bytes = fread(file,Inf,'*uint8');
value = aldrepro.sha256(bytes);
end
