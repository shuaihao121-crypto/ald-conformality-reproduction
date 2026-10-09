function artifacts = export_figures(figures,output_dir)
%EXPORT_FIGURES Archive each new figure without changing numerical sources.
figure_dir = fullfile(output_dir,'figures');
if ~exist(figure_dir,'dir'), mkdir(figure_dir); end
artifacts = cell(0,1);
if isempty(figures), return; end
% findall returns reverse creation order; stable increasing figure number.
[~,indices] = sort(arrayfun(@(f) double(f.Number),figures));
figures = figures(indices);
for k = 1:numel(figures)
    fig = figures(k);
    drawnow;
    stem = sprintf('figure_%02d',k);
    png = fullfile(figure_dir,[stem '.png']);
    pdf = fullfile(figure_dir,[stem '.pdf']);
    svg = fullfile(figure_dir,[stem '.svg']);
    if exist('exportgraphics','file')
        exportgraphics(fig,png,'Resolution',240,'BackgroundColor','white');
        exportgraphics(fig,pdf,'ContentType','vector','BackgroundColor','white');
    else
        print(fig,png,'-dpng','-r240');
        set(fig,'PaperPositionMode','auto');
        print(fig,pdf,'-dpdf','-bestfit');
    end
    % print -dsvg also works before exportgraphics acquired SVG support.
    print(fig,svg,'-dsvg','-painters');
    artifacts = [artifacts; {['figures/' stem '.png']; ...
        ['figures/' stem '.pdf']; ['figures/' stem '.svg']}]; %#ok<AGROW>
end
end
