% function [dir_name] = farmout_pbs(cmd, params, [names, [max_mem, [max_time]]])
%
% farmout_pbs is a wrapper script to drive Gatsby's batch processing system (OpenPBS) from within matlab. It was mainly
% written for large parameter sweeps. As such, the syntax of the script is to specify a single set of matlab commands
% and a cell array of parameters. This script will then start a new matlab for each entry in the parameter cell array
% and execute the matlab commnds with those parameters via PBS.
%
% The results are stored together in a directory called farmout_save_session_CURRENT_DATE. Each parameter will generate
% several files in this directory. These files are text files containing the output of standard error and standard
% output, as well as a mat files containing each the input parameter and the results for the run.
%
% The matlab cmd is either a single command, or a string of commands seperated by semicolon. Basically anything that
% will be executed by a single call to eval in matlab.
%
% The parameter to this run will be passed in as the variable 'options'. This can be anything that can be stored in a
% cell array. E.g. it could be a struct containing a set of parameters.
%
% The result must be saved in a variable called 'results' and will be saved out to a mat file
%
% The names array, is a cell array of the same length as params and specifies a name that is used in submitting
% to PBS and is visible in the qstat command. This parameter is optional.
%
%
% Example: farmout_pbs('results = 3*options',{1,2,3});
% Example: farmout_pbs('a = 3*options; b = a*a; results = b;', {1,2,3});
%
% Author: Kai Krueger

function [dir_name] = farmout_pbs(cmd, params, names, max_mem, max_time)

% This is the command used to start matlab
matlab_cmd = '/opt/matlab-7.10.0/bin/matlab';

% This is the command used to start pbs
%pbs_cmd = '/opt/torque-2.3.7/bin/qsub';
pbs_cmd = 'qsub';

% This is the matlab command that is executed before the command given to farmout_pbs.
% This can be used to set up the environment, such as add a standard path, or call a
% startup function
matlab_init_cmd='';

%%%%%%%%%%%%%%%%%%%%%
% Code starts here  %
%%%%%%%%%%%%%%%%%%%%%

prev_dir = pwd;

if (nargin == 1),
	cd(cmd);
	[ret files] = system('ls -1 Output_Results_*.mat');
	files = strsplit(files,10);
	for i = 1:length(files),
		if (length(files{i}) > 0),
			files{i};
			load(files{i});
			dir_name{i} = results;
		end;
	end;
	return;
end;

%Calculate the name of the directory, based on current time, in which the results get stored
t = clock();

dir_name = [pwd '/farmout_save_session_' num2str(t(1)) num2str(t(2),'%02d') num2str(t(3),'%02d') '_' num2str(t(4),'%02d') num2str(t(5),'%02d') ...
			num2str(round(t(6)),'%02d')]
if (system(['mkdir ' dir_name]) ~= 0)
	error('Could not create directory for data')
end;

cd(dir_name);

%Check the names array matches up with the length of the parameters
if (nargin > 2),
	if (length(names) ~= length(params)),
		disp('WARNING: length of names and params differ. Ignoring names');
		names = {};
	end;
else
	names = {};
end;
if (nargin < 4),
	max_mem = '2Gb';
end;
if (iscell(max_mem) == 0),
	tmp = max_mem;
	max_mem = {};
	for (i = 1:length(params)),
		max_mem{i} = tmp;
	end;
end;

if (nargin < 5),
	max_time = '12:00:00';
end;

if (iscell(max_time) == 0),
	tmp = max_time;
	max_time = {};
	for (i = 1:length(params)),
		max_time{i} = tmp;
	end;
end;
	

if (length(names) == 0),
	for (i = 1:length(params)),
		names{i} = ['farmout_job_' num2str(i)];
	end;
end;


for (i = 1:length(params))
	%Save out the parameter file
	options = params{i};
	param_name = ['Input_Params_' num2str(i,'%05d')];	
	save(param_name,'options');
	
	result_name = ['Output_Results_' num2str(i,'%05d')];
	
	%Generate the command string that gets executed in the matlab session
	%eval_cmd = ['maxNumCompThreads(1); cd ' dir_name '; load ' param_name ';' cmd '; save ' result_name ' results;'];
	eval_cmd = ['cd ' dir_name '; load ' param_name ';' cmd '; save ' result_name ' results;'];
    
	%Generate the pbs batch script
	submit_string = ['echo "Job execution host:" $HOSTNAME; ulimit -a; nice -15 ' matlab_cmd ' -nosplash -nojvm -nodisplay -singleCompThread -r "' matlab_init_cmd ...
					 ' '  eval_cmd ' exit;"'];
	
	file_1 = fopen('Submit.cmd','w');
	fprintf(file_1,submit_string);
	fclose(file_1);
	disp(names{i});
	
	%Submit to pbs
	system(['cat Submit.cmd | ' pbs_cmd ' -l walltime=' max_time{i} ',pvmem=' max_mem{i} ',pmem=' max_mem{i} ',mem=' max_mem{i} ' -N ' names{i} ...
			' - ']);
%	disp(['cat Submit.cmd | ' pbs_cmd ' -l walltime=' max_time{i} ',pmem=' max_mem{i} ',mem=' max_mem{i} ' -N ' names{i} ...
%			' - ']);
    
    %   pause(30);
end;

cd(prev_dir);
