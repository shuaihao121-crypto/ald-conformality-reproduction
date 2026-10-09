function write_warning_extract(log_file,output_file)
%WRITE_WARNING_EXTRACT Preserve warning blocks; run.log is authoritative.
log_text = fileread(log_file);
lines = regexp(log_text,'\r\n|\n|\r','split');
file = fopen(output_file,'w','n','UTF-8');
if file < 0, error('aldrepro:WriteFailed','Cannot write %s',output_file); end
cleanup = onCleanup(@() fclose(file)); %#ok<NASGU>
fprintf(file,'Warning transcript extracted from run.log. Full run.log is authoritative.\n');
recording = false;
found = false;
for k = 1:numel(lines)
    if ~isempty(regexp(lines{k},'^\s*(Warning:|警告[:：])','once'))
        recording = true;
        found = true;
    end
    if recording
        fprintf(file,'%s\n',lines{k});
        if isempty(strtrim(lines{k})), recording = false; end
    end
end
if ~found, fprintf(file,'No English/Chinese warning prefix was found in the log.\n'); end
end
