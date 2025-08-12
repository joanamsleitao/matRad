/home/joana/MatRad_devRBErobOpt
matRad_rc

%% Load ct, cst, dij, stf, pln and resultGUI 
load('SFUD.mat', 'cst_SFUD')
load('SFUD_10_16.mat')
load('/home/joana/MyMatRad/Robustness/ct.mat')

%%
scenModel = matRad_RandomScenarios(ct);
scenModel.nSamples = 5;
scenModel.shiftSD = [2 2 2];
pln_SFUD.multScen = scenModel;

pln_SFUD.bioParam = matRad_bioModel(pln_SFUD.radiationMode, 'physicalDose', 'none');
resultGUI_SFUDRandom = matRad_calcDoseDirect(ct, stf_SFUD, pln_SFUD,cst_SFUD, resultGUI_SFUD.w);

%% Figures to check shifts
PD = 16;
plane = 3; slice = 50;

colorBarTicks = [0, 0.25, 0.5, 0.75, 0.95, 1, round(19/PD, 1)];
figure; matRad_plotSliceWrapper(gca,ct,cst_SFUD,1,resultGUI_SFUDRandom.physicalDose,plane,slice)
figure; matRad_plotSliceWrapper(gca,ct,cst_SFUD,1,resultGUI_SFUDRandom.physicalDose_2,plane,slice)
figure; matRad_plotSliceWrapper(gca,ct,cst_SFUD,1,resultGUI_SFUDRandom.physicalDose_5,plane,slice)
