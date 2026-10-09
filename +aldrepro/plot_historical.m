function fig = plot_historical(pairs)
%PLOT_HISTORICAL Minimal parity presentation of recorded I-VII metrics.
fig = figure('Color','white','Position',[80 80 1600 600], ...
    'Name','Historical I-VII model comparison');
layout = tiledlayout(fig,1,3,'Padding','compact','TileSpacing','compact');
markers = {'s','o','^','v','<','>','d'};
labels = {'I: temperature','II: inlet pressure','III: molar mass', ...
    'IV: aspect ratio','V: exposure duration','VI: sticking coefficient', ...
    'VII: adsorption capacity / site area'};
metric_names = {'x_half','slope_half','broadness'};
mask_names = {'valid_penetration','valid_slope','valid_broadness'};
axis_limits = {[0 1000],[1e-3 1],[0 260]};
titles = {'(a) Half-coverage penetration','(b) Slope at half coverage', ...
    '(c) Adsorption-front broadness'};
axis_labels = {'x_{0.5}/H','|d\theta/d(x/H)|','(x_{0.1}-x_{0.9})/H'};
for panel = 1:3
    ax = nexttile(layout,panel);
    hold(ax,'on');
    lim = axis_limits{panel};
    plot(ax,lim,lim,'--','Color',[0.65 0.65 0.65], ...
        'LineWidth',1,'HandleVisibility','off');
    for case_id = 1:7
        mask = pairs.case_id==case_id & pairs.(mask_names{panel});
        plot(ax,pairs.(['B_' metric_names{panel}])(mask), ...
            pairs.(['A_' metric_names{panel}])(mask),markers{case_id}, ...
            'LineStyle','none','MarkerSize',7,'LineWidth',1.15, ...
            'Color',[0.1 0.2 0.29],'MarkerFaceColor','white', ...
            'DisplayName',labels{case_id});
    end
    if panel==2, set(ax,'XScale','log','YScale','log'); end
    xlim(ax,lim); ylim(ax,lim); axis(ax,'square');
    set(ax,'Box','on','TickDir','in','FontName','Arial','FontSize',10.5, ...
        'LineWidth',0.8,'XMinorGrid','off','YMinorGrid','off');
    xlabel(ax,['Model B: ' axis_labels{panel}]);
    ylabel(ax,['Model A: ' axis_labels{panel}]);
    title(ax,titles{panel},'FontWeight','normal');
    if panel==1
        legend(ax,'Location','northwest','Box','off','FontSize',8.5);
    end
    hold(ax,'off');
end
title(layout,'Historical records, Cases I-VII -- no model recomputation', ...
    'FontName','Arial','FontSize',13,'FontWeight','normal');
end
