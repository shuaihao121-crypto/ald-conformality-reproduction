function records = source_hashes(root)
%SOURCE_HASHES Verify the actual bytes of every preserved numerical source.
manifest = jsondecode(fileread(fullfile(root,'data','source_manifest.json')));
records = repmat(struct('path','','expected_sha256','','actual_sha256','', ...
    'matches_manifest',false),numel(manifest.files),1);
for k = 1:numel(manifest.files)
    source = manifest.files(k);
    path_value = fullfile(root,strrep(source.path,'/',filesep));
    file = fopen(path_value,'rb');
    if file < 0, error('aldrepro:MissingSource','Missing source: %s',source.path); end
    cleanup = onCleanup(@() fclose(file));
    bytes = fread(file,Inf,'*uint8');
    actual = aldrepro.sha256(bytes);
    records(k) = struct('path',source.path,'expected_sha256',source.sha256, ...
        'actual_sha256',actual,'matches_manifest',strcmpi(actual,source.sha256));
    clear cleanup
end
end
