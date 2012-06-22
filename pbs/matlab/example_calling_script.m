% Example of how to call farmout_pbs.m
%
% courtesy of Ross Williamson


%1. Run full-rank model on old and new classic DRC
DRC_files1 = setdiff([usethesefiles('mouse_AIUF_LH') usethesefiles('mouse_AAF_LH')], [usethesefiles('poissbad_fano') usethesefiles('poissbad_signal')]);
DRC_files2 = usethesefiles('new_cortex_default_poissgood');
DRC_files = [DRC_files1 DRC_files2];

count=1;
context_smoothing_choice = 1; %1 gives full asd, 2 gives fixed [3 0] smoothing on CRF
distance_choice = 1; %1 for normal, 2 for instantaneous
for cellnum=1:length(DRC_files)
 parameters{count}=[cellnum context_smoothing_choice distance_choice];
 names{count} = ['Regular_Analysis_Cortex_1_' num2str(count)];
 count=count+1;
end

farmout_pbs('addpath /nfs/home1/rossw/to_run/Context_Model_Repository:/nfs/home1/rossw/to_run/Context_Model_Repository/BatchRuns:/nfs/home1/rossw/to_run/Context_Model_Repository/Filelists:/nfs/home1/rossw/to_run/Context_Model_Repository/KeyFuncs:/nfs/home1/rossw/to_run/Context_Model_Repository/Scipts:/nfs/home1/rossw/to_run/Context_Model_Repository/SwitchingDensity:/nfs/home1/rossw/to_run/Context_Model_Repository/Utils; results=fit_fullrank_context(options(1),options(2),options(3))',parameters,names,'3gb','100:00:00');
