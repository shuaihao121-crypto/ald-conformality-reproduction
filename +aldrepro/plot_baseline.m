function fig = plot_baseline(result,model)
%PLOT_BASELINE Present the actual output from the unchanged single-case solver.
fig = figure('Color','white','Position',[100 100 900 520]);
ax = axes(fig);
plot(ax,result.x_dim,result.theta,'LineWidth',1.6,'Color',[0.13 0.25 0.35]);
xlabel(ax,'Dimensionless distance x/H');
ylabel(ax,'Surface coverage \theta');
title(ax,sprintf('Model %s baseline -- preserved implementation',model));
ylim(ax,[0 1.05]);
xlim(ax,[0 max(result.x_dim)]);
set(ax,'TickDir','in','Box','on','FontName','Arial','FontSize',11);
end
