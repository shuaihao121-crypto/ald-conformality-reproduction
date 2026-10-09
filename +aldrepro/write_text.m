function write_text(path_value,text_value)
%WRITE_TEXT Write captured task output without changing the user's diary.
file = fopen(path_value,'w','n','UTF-8');
if file<0, error('aldrepro:WriteFailed','Cannot write %s',path_value); end
cleanup = onCleanup(@() fclose(file)); %#ok<NASGU>
fprintf(file,'%s',text_value);
end
