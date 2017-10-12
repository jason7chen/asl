clear;
close all;
format long g;
addpath('/Users/ciborg/Documents/MATLAB/NIfTI_20140122');
addpath('/Users/ciborg/Documents/MATLAB'); 
addpath('/Volumes/data2/Jason_ASL/analysis_John/');

sub_list = {'C20146', 'C20147', 'C20148', 'C20151', 'C20153', 'C20154', 'C20155', 'C20156', 'C20157', ...
            'C20158', 'C20159', 'C20160', 'C20161', 'C20163', 'C20164', 'C20165', 'C20166', 'C20167', ...
            'C20168', 'C20169', 'C20171', 'C20172', 'C20173', 'C20174', 'C20175', 'C20176', 'C20177', ...
            'C20178', 'C20179', 'C20180', 'C20181', 'C20182', 'C20183', 'C20184', 'C20185', 'C20186', ...
            'C20187', 'C20188', 'C20189', 'C20191', 'C20192', 'C20193', 'C20194', 'C20195', 'C20196', 'C20197'};
sub_list = {'C20147'};
Dir = '/Volumes/data2/Jason_ASL/analysis_John/';
% load('CBF.mat');
opt=struct('ranksum',2,'pvTh',0.01,'resMin',0,'resMax',255,'wS',2);

%% Two-compartment model
% parameters of the CBF equation are stored in DATA_PAR.m file 
symbols = eval('DATA_PAR');
symbols = DATA_PAR(symbols);
symbols.qnt_lab_eff = 0.85;
% e.g. Philips 2D EPI or Siemens 3D GRASE
symbols.qnt_lab_eff = symbols.qnt_lab_eff*0.83; % 0.83 = 2 background suppression pulses (Garcia et al., MRM 2005)
CBF_mean = zeros(length(sub_list), 1);
CBF_GM_mean = zeros(length(sub_list), 1);
CBF_WM_mean = zeros(length(sub_list), 1);

tic

%% For each patient
for n = 1:length(sub_list)
    sub = sub_list{n};
    % Load GM/WM Probability Map
    GM_PM = load_untouch_nii(strcat(Dir, sub, '/FAST/T1_ASL/', sub, '_FAST_prob_GM_ASL.nii.gz'));
    WM_PM = load_untouch_nii(strcat(Dir, sub, '/FAST/T1_ASL/', sub, '_FAST_prob_WM_ASL.nii.gz'));
    % Load ASL 4D data
    ASL4D = load_untouch_nii(strcat(Dir, sub, '/ASL_1/ASL4D.nii'));
    filename = dir(strcat(Dir, sub, '/ASL_1/Time/*ASL*'));
    params_path = strcat(Dir, sub, '/ASL_1/ASL4D_parms.mat');
    load(params_path);
    CBF4D = load_untouch_nii(strcat(Dir, sub, '/ASL_1/ASL4D_control.nii.gz'));
    CBF_GM4D = CBF4D;
    CBF_WM4D = CBF4D;
    temp = zeros(1,size(ASL4D.img, 3));
    
    % Slice Gradient for 2D readout (No need for 3D readout)
    symbols.qnt_slice_gradient = zeros(size(ASL4D.img(:,:,:,1)));
    for ii = 1:size(ASL4D.img, 3)
        symbols.qnt_slice_gradient(:,:,ii) = ii;
    end
    symbols.qnt_slice_gradient = single(symbols.qnt_slice_gradient(:,:,:));
    symbols.qnt_slice_gradient(~isfinite(symbols.qnt_slice_gradient))   = 0;
    symbols.qnt_slice_gradient = max(symbols.qnt_slice_gradient,1);
    if  nanmax(symbols.qnt_slice_gradient(:))>50 % not expected in 2D sequences
        error('Erroneous values in slice_gradient_images!');
    end
    symbols.qnt_slice_gradient = symbols.qnt_init_PLD + ((symbols.qnt_slice_gradient-1) .* symbols.qnt_PLDslicereadout); % effective PLD%

   
    % T2* correction of arterial blood
    T2_star_factor = exp(parms.EchoTime/symbols.qnt_T2art); 
    
    % tissue transit time
    gamma_GM = 1400;
    gamma_WM = 1600;
    
    % GM/WM tissue longitudinal relaxation
    symbols.T1GM = 1332;
    symbols.T1WM = 850;
    
    % Multiplication factor and division factor for the CBF equation
    % Option for one compartment model:
    % MultiFactor = 1000 * 6000 * symbols.qnt_labda * exp(symbols.qnt_slice_gradient ./ symbols.qnt_T1a);
    % DivFactor = 2 * symbols.qnt_lab_eff * symbols.qnt_T1a * (1- exp(-symbols.qnt_labdur/symbols.qnt_T1a));
    MultiFactor_GM = 1000 * 6000 * symbols.qnt_labda * exp(gamma_GM ./ symbols.qnt_T1a);
    DivFactor_GM = 2 * symbols.qnt_lab_eff * symbols.T1GM * (exp((gamma_GM - symbols.qnt_slice_gradient) ./ symbols.T1GM) - exp((gamma_GM - symbols.qnt_labdur - symbols.qnt_slice_gradient) ./ symbols.T1GM));
    
    MultiFactor_WM = 1000 * 6000 * symbols.qnt_labda * exp(gamma_WM ./ symbols.qnt_T1a);
    DivFactor_WM = 2 * symbols.qnt_lab_eff * symbols.T1WM * (exp((gamma_WM - symbols.qnt_slice_gradient) ./ symbols.T1WM) - exp((gamma_WM - symbols.qnt_labdur - symbols.qnt_slice_gradient) ./ symbols.T1WM));
    
    %% Calculate CBF for every control/label image
    for i = 1:size(ASL4D.img, 4)/2
        control = load_untouch_nii(strcat(Dir, sub, '/ASL_1/Time/', filename(2 * i - 1).name));
        label = load_untouch_nii(strcat(Dir, sub, '/ASL_1/Time/', filename(2 * i).name));
        CBF = control;
        CBF_GM = CBF;
        CBF_WM = CBF;
        CBF.img = double(abs(control.img - label.img)); % |control - label|
        
        % Partial Volume Effect Correction for GM & WM
        [imFil,imMap,errRes]=pveAsllani(GM_PM.img, WM_PM.img, [], CBF.img, opt);
        imFil(isnan(imFil))=0;
        CBF.img=imFil;
        CBF_WM.img=imMap(:,:,:,1);
        CBF_WM.img(isnan(CBF_WM.img))=0;
        CBF_GM.img=imMap(:,:,:,2);
        CBF_GM.img(isnan(CBF_GM.img))=0;
        
        
        % Quantification of CBF in GM & WM
        CBF_WM.img = CBF_WM.img * T2_star_factor .* MultiFactor_WM ./ (symbols.M0 .* DivFactor_WM);
        CBF_WM.img = CBF_WM.img ./ (parms.RescaleSlopeOriginal .* parms.MRScaleSlope); % scale the image
        
        CBF_GM.img = CBF_GM.img * T2_star_factor .* MultiFactor_GM ./ (symbols.M0 .* DivFactor_GM);
        CBF_GM.img = CBF_GM.img ./ (parms.RescaleSlopeOriginal .* parms.MRScaleSlope); % scale the image
        
        CBF.img = CBF_WM.img .* WM_PM.img + CBF_GM.img .* GM_PM.img;
        
        CBF4D.img(:,:,:,i) = CBF.img;
        CBF_WM4D.img(:,:,:,i) = CBF_WM.img;
        CBF_GM4D.img(:,:,:,i) = CBF_GM.img;
    end
    
    %% Save CBF files
    CBF3D = CBF;
    CBF3D.img = mean(CBF4D.img, 4);
    CBF_WM3D = CBF_WM;
    CBF_WM3D.img = mean(CBF_WM4D.img, 4);
    CBF_GM3D = CBF_GM;
    CBF_GM3D.img = mean(CBF_GM4D.img, 4);
    mkdir(strcat(Dir, sub, '/ASL_1/two_comp/'));
    save_untouch_nii(CBF3D, strcat(Dir, sub, '/ASL_1/two_comp/CBF.nii.gz'));
    save_untouch_nii(CBF_WM3D, strcat(Dir, sub, '/ASL_1/two_comp/CBF_WM.nii.gz'));
    save_untouch_nii(CBF_GM3D, strcat(Dir, sub, '/ASL_1/two_comp/CBF_GM.nii.gz'));
    
    
    %% Select Mid 3 Slices in Axial Plane for CBF value
    for i = 1:size(CBF3D.img, 3)
        temp(i) = mean(nonzeros(CBF3D.img(:,:,i)));
    end
    
    mid = round(size(ASL4D.img, 3)/2);
    mid_mean = (temp(mid-1) + temp(mid) + temp(mid+1))/3;
    CBF_mean(n) = mid_mean;
    
    for i = 1:size(CBF_WM3D.img, 3)
        temp_WM(i) = mean(nonzeros(CBF_WM3D.img(:,:,i)));
    end
    mid = round(size(CBF_WM3D.img, 3)/2);
    mean_WM = (temp_WM(mid-1) + temp_WM(mid) + temp_WM(mid+1))/3;
    CBF_WM_mean(n) = mean_WM;
    
    for i = 1:size(CBF_GM3D.img, 3)
        temp_GM(i) = mean(nonzeros(CBF_GM3D.img(:,:,i)));
    end
    mid = round(size(CBF_WM3D.img, 3)/2);
    mean_GM = (temp_GM(mid-1) + temp_GM(mid) + temp_GM(mid+1))/3;
    CBF_GM_mean(n) = mean_GM;
    
end
toc
%% Show results in table "result"
result = table;
result.SUBJECT = sub_list';
result.CBF_PVE_2 = CBF_mean;
result.CBF_GM_2 = CBF_GM_mean;
result.CBF_WM_2 = CBF_WM_mean;
% save CBF.mat result
% 
% exit;


