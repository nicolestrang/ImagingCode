function RunCBFAna %subs
% Set up variables
subs='goodsubs.txt';
RootPath = '/imaging/scratch/Hendershot/chendershot/data';
%[~, AfniPath] = unix('which afni');
%AfniPath = strtrim(AfniPath);
%AfniPath=AfniPath(1:end-5);
AfniPath='/quarantine/AFNI/AFNI_MAY_2014';
b=strfind(subs, 'txt');
if isempty(b)==0
    % Read in subject list
    fid =fopen([RootPath '/' subs], 'r', 'n');
    x=1;
    while 1
        thisline = fgetl(fid);
        if ~ischar(thisline), break, end
        SubList{x,1} = strtrim(thisline);
        x=x+1;
    end
    fclose(fid);
else
    SubList{1,1}=subs;
end
% Loop through subjects in subject list
for i =1:length(SubList)
    sub=SubList{i};
    
    % Get list of dates and figure out which is Scan1 and Scan2
    scandates=dir([RootPath '/raw/mri/cihr_infusion/' sub '/2*']);
    if length(scandates)==1
        S.scan1=scandates(1,1).name;
    else
        scanA=scandates(1,1).name;
        scanB=scandates(2,1).name;
        
        if datenum([scanA(1:4) ',' scanA(5:6) ',' scanA(7:8)]) > ...
                datenum([scanB(1:4) ',' scanB(5:6) ',' scanB(7:8)])
            S.scan1=scanB;
            S.scan2=scanA;
        elseif datenum([scanA(1:4) ',' scanA(5:6) ',' scanA(7:8)]) < ...
                datenum([scanB(1:4) ',' scanB(5:6) ',' scanB(7:8)])
            S.scan1=scanA;
            S.scan2=scanB;
        end
    end
    
    for time=1:length(scandates)
        time=num2str(time);
        OutPath = [RootPath '/analysis/cihr_infusion/subjects/' sub ...
    '/' S.(['scan' time]) '/CBF'];
        %% Set up raw directory
        % Initialize structure arrays
        anat.dir=[];
        anat.name=[];
        asl.dir=[];
        asl.name=[];
        cbf.dir=[];
        cbf.name=[];
        
        % Figure out which directories contains ASL & CBF data
        info=dir([RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/*.txt']);
        fid = fopen([RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' info.name], 'r', 'n');
        while 1
            if fid < 1; break; end
            thisline=fgetl(fid);
            if ~ischar(thisline), break, end
            if ~isempty(strfind(thisline, 'T1'))
                thisline = strsplit(thisline, '\t');
                thisline=strtrim(thisline);
                anat.dir =thisline{1,1};
                anat.name=thisline{1,2};
            elseif ~isempty(strfind(thisline, 'ASL'))
                thisline = strsplit(thisline, '\t');
                thisline=strtrim(thisline);
                asl.dir{length(asl.dir)+1,1}=thisline{1,1};
                asl.name{length(asl.name)+1,1}=thisline{1,2};
            elseif ~isempty(strfind(thisline, 'Cerebral Blood Flow'))
                thisline = strsplit(thisline, '\t');
                thisline=strtrim(thisline);
                cbf.dir{length(cbf.dir)+1,1}=thisline{1,1};
                cbf.name{length(cbf.name)+1,1}=thisline{1,2};
            end
        end
        
        % Check whether original mri data had been linked. If not, link &
        % rename data folders
        
        %Copy and rename asl & cbf folders
        for xx=1:length(asl.dir)
            % Find index of cbf scan that matches up with asl scan
            r=find(~cellfun(@isempty,strfind(cbf.dir,['e' num2str(str2num(asl.dir{xx,1}(end-1:end))) '00'])));
            if ~isempty(strfind(asl.name{xx,1},'ASL 1'))
                asl.new{xx,1}='asl_1';
                cbf.new{r,1}='cbf_1';
            elseif ~isempty(strfind(asl.name{xx,1},'ASL 2'))
                asl.new{xx,1}='asl_2';
                cbf.new{r,1}='cbf_2';
            elseif ~isempty(strfind(asl.name{xx,1},'ASL 3'))
                asl.new{xx,1}='asl_3';
                cbf.new{r,1}='cbf_3';
            elseif ~isempty(strfind(asl.name{xx,1},'ASL 4'))
                asl.new{xx,1}='asl_4';
                cbf.new{r,1}='cbf_4';
            end
            
            
            % link ASL Folders
            if exist([RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' asl.dir{xx,1}]) ...
                    && ~exist([OutPath '/raw/' asl.new{xx,1}], 'dir')
                unix(['mkdir -p ' OutPath '/raw/' asl.new{xx,1}]);
                unix(['ln -s ' RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' asl.dir{xx,1} '/* ' ...
                    OutPath '/raw/' asl.new{xx,1}]);
            end
        end
        
        for xx=1:length(cbf.dir)
            % link CBF Folders
            if exist([RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' cbf.dir{xx,1}]) ...
                    && ~exist([OutPath '/raw/' cbf.new{xx,1}], 'dir')
                unix(['mkdir -p ' OutPath '/raw/' cbf.new{xx,1}]);
                unix(['ln -s ' RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' cbf.dir{xx,1} '/* ' ...
                    OutPath '/raw/' cbf.new{xx,1}]);
            end
        end
        
        %Link T1 High Data
        if exist([RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' anat.dir]) ...
                && ~exist([OutPath '/raw/anat'], 'dir')
            unix(['mkdir -p ' OutPath '/raw/anat']);
            unix(['ln -s ' RootPath '/raw/mri/cihr_infusion/' sub '/' S.(['scan' time]) '/' anat.dir '/* ' ...
                OutPath '/raw/anat']);
        end
        
        %% Process data and copy to processd directory
        
        %T1 High
        if ~exist([OutPath '/processed/anat/T1High+orig.BRIK'])
            cd([OutPath '/raw/anat']);
            command=[AfniPath '/to3d -prefix T1High *dcm'];
            unix(command);
            command=[ 'mkdir -p ' OutPath '/processed/anat'];
            unix(command);
            command=['mv T1High* ' OutPath '/processed/anat'];
            unix(command)
        end
        
        %Create CBF 3d volumes
        for zz=1:4
            if ~exist([OutPath '/processed/cbf/cbf' num2str(zz) '+orig.HEAD']) && ...
                    exist([OutPath '/raw/cbf_' num2str(zz)]);
                cd([OutPath '/raw/cbf_' num2str(zz)]);
                command=['export DYLD_LIBRARY_PATH="";' AfniPath '/to3d -prefix cbf' num2str(zz) ' *dcm'];
                unix(command);
                if ~exist([OutPath '/processed/cbf/'])
                    command=[ 'mkdir -p ' OutPath '/processed/cbf'];
                    unix(command);
                end
                command=['mv cbf* ' OutPath '/processed/cbf'];
                unix(command);
            end
        end
        
        %Create ASL 3d volumes
        for zz=1:4
            if ~exist([OutPath '/processed/asl/asl_diff' num2str(zz) '+orig.HEAD']) && ...
                    exist([OutPath '/raw/asl_' num2str(zz)]);
                cd([OutPath '/raw/asl_' num2str(zz)]);
                if ~exist('diff_dir')
                    unix('mkdir diff_dir');
                    unix(['mv *0000*dcm *0001*dcm *0002*dcm *00030.dcm ' ...
                        '*00031.dcm *00032.dcm *00033.dcm *00034.dcm diff_dir']);
                    cd('diff_dir');
                    command=['export DYLD_LIBRARY_PATH="";' AfniPath '/to3d -prefix asl_diff' num2str(zz) ' *dcm'];
                    unix(command);
                end
                if ~exist([OutPath '/processed/asl/'])
                    command=[ 'mkdir -p ' OutPath '/processed/asl'];
                    unix(command);
                end
                command=['mv asl_diff* ' OutPath '/processed/asl'];
                unix(command);
            end
        end
        
        %% Transform data into standard space
        %Set up analysis directory
        if ~exist([OutPath '/analysis/anat/'])
            command=[ 'mkdir -p ' OutPath '/analysis/anat'];
            unix(command);
        end
        if ~exist([OutPath '/analysis/cbf/'])
            command=[ 'mkdir -p ' RootPath '/analysis/cbf'];
            unix(command);
        end
        if ~exist([OutPath '/analysis/asl/'])
            command=[ 'mkdir -p ' OutPath '/analysis/asl'];
            unix(command);
        end
        
        %Skullstrip and transform T1 to standard space
        cd([OutPath '/processed/anat']);
        if exist([OutPath '/analysis/anat/T1High+tlrc.HEAD'])==0
            command = [AfniPath '/@auto_tlrc ' ...
                '-base /quarantine/FSL/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz ' ...
                '-input T1High+orig'];
            unix(command);
            movefile('T1High+tlrc*',[OutPath '/analysis/anat'])
        end
        
        % Segment T1High
        if exist([OutPath '/analysis/anat/Segsy'])==0
            cd([OutPath '/analysis/anat/']);
            command = [AfniPath '/3dSeg ' ...
                '-anat ' OutPath '/analysis/anat/T1High+tlrc ' ...
                '-mask AUTO -classes ''CSF; GM; WM'' -bias_classes ''GM: WM'' -bias_fwhm 25 ' ...
                '-mixfrac AVG152_BRAIN_MASK -main_N 5 -blur_meth BFT'];
            unix(command);
        end
        
        % Create Bianary Grey matter mask
        if ~exist([OutPath '/analysis/anat/Segsy/GM_mask+tlrc.HEAD'])
            command = [AfniPath '/3dcalc ' ...
                '-a ' OutPath '/analysis/anat/Segsy/Classes+tlrc.HEAD ' ...
                '-expr ''equals(a,2)'' -prefix ' OutPath '/analysis/anat/Segsy/GM_mask'];
            unix(command);
        end
        
        
        for rr=1:4
            rr=num2str(rr);
            if exist([OutPath '/processed/cbf/cbf' rr '+orig.HEAD'])~=0 %%&& ...
                %%exist([RootPath '/mri/analysis/' sub '/scan' time '/cbf/cbf' rr '_al+tlrc.HEAD'])==0
                %Skullstip ASL
                if exist([OutPath '/processed/asl/asl_diff' rr '_ns+orig.HEAD'])==0
                    command = [AfniPath '/3dSkullStrip ' ...
                        '-prefix ' OutPath '/processed/asl/asl_diff' rr '_ns ' ...
                        '-input ' OutPath '/processed/asl/asl_diff' rr '+orig'];
                    unix(command);
                end
                
                %Align asl to MNI
                if exist([OutPath '/analysis/asl/asl_diff' rr '_ns_al+orig.HEAD'])==0
                    command = [AfniPath '/align_epi_anat.py ' ...
                        '-dset1 ' OutPath '/processed/anat/T1High+orig ' ...
                        '-dset2 ' OutPath '/processed/asl/asl_diff' rr '_ns+orig -dset1_strip None ' ...
                        '-dset2_strip None -dset2to1 -tlrc_apar ' OutPath '/analysis/anat/T1High+tlrc'];
                    unix(command);
                    movefile([OutPath '/processed/asl/*al*' ], ...
                        [OutPath '/analysis/asl'])
                end
                
                %Align CBF to MNI
                if exist([OutPath '/analysis/cbf/cbf' rr '_al+tlrc.HEAD'])==0
                    command = [AfniPath '/3dAllineate -base ' ...
                        OutPath '/analysis/anat/T1High+tlrc ' ...
                        '-1Dmatrix_apply ' OutPath '/analysis/asl/asl_diff' rr '_ns_al_tlrc_mat.aff12.1D ' ...0
                        '-prefix ' OutPath '/analysis/cbf/cbf' rr '_al+tlrc ' ...
                        '-input ' OutPath '/processed/cbf/cbf' rr '+orig. -verb -master BASE ' ...
                        '-mast_dxyz 2 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff ' ...
                        '-source_automask+4 -onepass'];
                    unix(command);
                end
                % Mask out all but GM on CBF volume
                command = [AfniPath '/3dcalc ' ...
                    '-a ' OutPath '/analysis/anat/Segsy/GM_mask+tlrc -b ' ...
                    OutPath '/analysis/cbf/cbf' rr '_al+tlrc ' ...
                    '-expr ''a*b'' -prefix ' OutPath '/analysis/cbf/cbf' rr '_mask'];
                unix(command);
                
            end
        end
    end
end
