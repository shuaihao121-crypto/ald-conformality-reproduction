function result = smoke()
%SMOKE Small independent invariants; does not validate full research scans.
names = {}; errors = []; tolerances = [];
check('SHA256 empty (portable)',strcmp(aldrepro.sha256(zeros(0,1,'uint8'),true), ...
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),0,0);
check('SHA256 abc (portable)',strcmp(aldrepro.sha256(uint8('abc'),true), ...
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'),0,0);
check('SHA256 two-block standard vector (portable)',strcmp(aldrepro.sha256(uint8( ...
    'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),true), ...
    '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'),0,0);
geom = geometry_modelB(5,4);
q = geom.q;
column_error = max(abs(sum(q,1)-1));
check('View-factor column conservation',column_error<2e-13,column_error,2e-13);
check('View-factor nonnegative',min(q(:))>=-2e-14,max(0,-min(q(:))),2e-14);
area_weighted = q.*geom.area';
reciprocity_error = max(max(abs(area_weighted-area_weighted')));
check('Area-weighted reciprocity',reciprocity_error<2e-13,reciprocity_error,2e-13);
probes = [ones(geom.N,1),sin((1:geom.N)'),linspace(-1,1,geom.N)'];
fft_error = 0;
for k = 1:size(probes,2)
    fft_error = max(fft_error,max(abs(qmul_modelB(probes(:,k),geom)-q*probes(:,k))));
end
check('FFT versus dense multiplication',fft_error<2e-13,fft_error,2e-13);
bare = zeros(numel(geom.surface_idx),1);
absorbing = markov_modelB(bare,1,geom);
adsorption_error = max(abs(absorbing.P_ads-absorbing.p_in(geom.surface_idx)));
check('Fully sticking first-collision absorption',adsorption_error<2e-13,adsorption_error,2e-13);
check('Fully sticking exit probability zero',abs(absorbing.P_exit)<2e-13,abs(absorbing.P_exit),2e-13);
partial = linspace(0,0.8,numel(geom.surface_idx))';
transport = markov_modelB(partial,0.23,geom);
conservation_error = abs(transport.prob_sum-1);
check('Partial-surface absorption plus escape',conservation_error<2e-12,conservation_error,2e-12);
sprob = [1; transport.beta];
residual = norm((eye(geom.N)-q.*(1-sprob)')*transport.r-transport.p_in,Inf);
check('Frozen Markov balance residual',residual<2e-12,residual,2e-12);
saturated = markov_modelB(ones(size(bare)),0.23,geom);
escape_error = abs(saturated.P_exit-1);
check('Saturated surface escape equals one',escape_error<2e-12,escape_error,2e-12);
check('Saturated surface adsorption zero',all(saturated.P_ads==0),max(abs(saturated.P_ads)),0);

p = parameters_modelB();
p.AR=5; p.fs=4; p.beta0=0.1; p.ep=0.05; p.show_progress=false;
p.pA0=2; p.tend=1e-8;
short = run_modelB_case(p);
check('No half-coverage front returns NaN',isnan(short.x_half)&&isnan(short.slope_half),0,0);
check('No-front raw broadness is excluded by entrance',short.entrance_theta<0.995 && min(short.theta)<0.1,0,0);
check('Small-run coverage physically bounded',all(isfinite(short.theta))&&all(short.theta>=0)&&all(short.theta<=1),0,0);
p.tend=0.001;
first = run_modelB_case(p);
second_p=p; second_p.pA0=8; second_p.tend=0.00025;
second = run_modelB_case(second_p);
dose_error = max(abs(first.theta-second.theta));
check('Constant-dose small geometry profile equality',dose_error<2e-12,dose_error,2e-12);
check('Constant-dose small geometry step equality',first.n_steps==second.n_steps,abs(first.n_steps-second.n_steps),0);

pa = parameters_modelA();
x = [0;1;5;20]*1e-6;
pressure = pressure_modelA(1e-3,x,pa,zeros(size(x)));
check('Model A zero-collision Knudsen limit finite',all(isfinite(pressure)),0,0);
check('Model A inlet pressure boundary',abs(pressure(1)-pa.pA0)<1e-12,abs(pressure(1)-pa.pA0),1e-12);
check('Model A pressure in physical interval',all(pressure>=0)&&all(pressure<=pa.pA0),0,0);
pb = parameters_modelB();
mapping_error = abs(pa.q*pb.s0-1);
check('A/B q to surface-site-area mapping',mapping_error<1e-14,mapping_error,1e-14);

result = struct('status','passed','number_checks',numel(names),'check_names',{names}, ...
    'absolute_errors',errors,'tolerances',tolerances, ...
    'parameters',struct('AR',5,'fs',4,'beta0',0.1,'ep',0.05, ...
    'constant_dose_pressures_Pa',[2 8],'constant_dose_times_s',[0.001 0.00025]), ...
    'scope','Small structural and numerical invariants; no full Table 2 scan or legacy Model A integration.', ...
    'known_behavior','At low coverage the raw broadness may be zero; validity masks exclude this profile.');
fprintf('Smoke: %d checks passed. Full scans were not executed.\n',numel(names));

    function check(name,condition,error_value,tolerance)
        assert(condition,'aldrepro:SmokeFailure','Smoke check failed: %s',name);
        names{end+1} = name;
        errors(end+1) = error_value;
        tolerances(end+1) = tolerance;
        fprintf('PASS  %s (error %.3g; tolerance %.3g)\n',name,error_value,tolerance);
    end
end
