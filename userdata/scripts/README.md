
# 📘 MATLAB Radiotherapy Utilities – Function Reference

This document summarizes all the MATLAB functions developed, grouped by category. Each function includes a brief description, usage context, and a standardized `matRad`-style function header.


## Function Categories

✅ **Legend:**
🟢 Stable — tested and ready for integration
🟡 Needs refinement — partially implemented or pending testing
🔴 Experimental — draft or conceptual
❌ Deprecated — no longer in use

| #  | Category                                | Description                                                           |
| -- | --------------------------------------- | --------------------------------------------------------------------- |
| 1  | Core Utilities / Internal Helpers       | Functions for internal handling, indexing, and low-level computations |
| 2  | Data Import / Export                    | MAT, DICOM, and CST/plan/dose import/export                           |
| 3  | Structure and Contour Tools             | VOI manipulation, CST operations, dose threshold filtering            |
| 4  | Dose Objectives and Constraints         | CST objectives, merging, and reference plan emulation                 |
| 5  | Beam Geometry / Energy Layers           | Spot geometry, energy layers, ray tracing, and per-EL analysis        |
| 6  | Dose Calculation / Comparison           | Dose cube computation, per-EL dose, linearization, comparison         |
| 7  | Plotting, DVH and Visualization Tools   | Functions for slice, DVH, and spot visualization                      |
| 8  | Spot and Energy Layer Analysis          | Spot Analysis
| 9  | FLASH / DMF                             | FLASH / DMF  


---


### **2. Data Import / Export**

| File                        | Description                                                           | Call                                                                                                                   | Status |
| --------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------ |
| `matRad_dicomImport`        | Import DICOM from a given path                                        | `ct, cst, pln, stf = matRad_dicomImport(path)`                                                                         | 🟢     |
| `matRad_dicomImportFolder`  | Import DICOM from main folder, with optional fallback for CT/RTSTRUCT | `[ct, cst, pln, stf, resultGUI] = matRad_dicomImportFolder(primaryPath, fallbackPath)`                                 | 🟢     |
| `matRad_dicomImportPath`    | Import DICOM from folder, optional fallback                           | `[ct, cst, pln, stf, resultGUI] = matRad_dicomImportPath(inputPath, secondPath)`                                       | 🟢     |
| `matRad_dicomLoad`          | Load DICOM object and save as MAT                                     | `[matRadFileName, ct, cst, pln, stf, resultGUI] = matRad_dicomLoad(dcmImpObj, pathToFolder)`                           | 🟢     |
| `matRad_dataImport`         | Load CT/CST/dose from MAT or DICOM                                    | `[ct, cst, doseCube] = matRad_dataImport(patientName, wildcardPath, wildcard)`                                         | 🟢     |
| `matRad_dataImportPatient`  | Unified patient import (MAT/DICOM) with fallback handling             | `[ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient(patientName, inputPath, Name,Value)`              | 🟢     |
| `matRad_dataImportAndLoad`  | Simplified variant with optional saving                               | `[ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportAndLoad(patientName, inputPath, Name,Value)`              | 🟢     |
| `matRad_dataLoadMat`        | Load variables selectively from MAT file                              | `[ct, cst, pln, stf, resultGUI] = matRad_dataLoadMat(filePath)`                                                        | 🟢     |
| `matRad_matLoadSingle`      | Wrapper with fallback MAT support                                     | `[ct, cst, pln, stf, resultGUI] = matRad_matLoadSingle(filePath, fallbackMat)`                                         | 🟢     |
| `matRad_loadFolderMat`      | Load MAT files from folder with matching                              | `[ct, cst, pln, stf, resultGUI] = matRad_loadFolderMat(folderPath, matFiles, matchPattern, fallbackMat, fallbackPath)` | 🟢     |
| `matRad_loadFolderDICOM`    | Import patient data from DICOM folder, with fallback                  | `[ct, cst, pln, stf, resultGUI] = matRad_loadFolderDICOM(folderPath, matchPattern, fallbackPath)`                      | 🟢     |
| `matRad_fileSearch`         | Search for MAT files in folder                                        | `matFiles = matRad_fileSearch()`                                                                                       | 🟡     |
| `matRad_filePatientPath`    | Locate patient folders/files recursively                              | `[targetPath, patientFolder] = matRad_filePatientPath(patientID, searchFolder, searchFile)`                            | 🟢     |
| `matRad_filenameGet`        | Locate files based on naming patterns                                 | `[fileNameComplete] = matRad_filenameGet(fileFolder, gantrySep, res, workspaceType)`                                   | 🟡     |
| `matRad_filenameGenerate`   | Generate standardized filenames                                       | `[fileNameComplete] = matRad_filenameGenerate(fileFolder, pln, workspaceType)`                                         | 🟡     |
| `matRad_savePatientMat`     | Save patient data to MAT                                              | `matRad_savePatientMat(patientName, ct, cst, pln, stf, resultGUI, saveDir, saveName)`                                  | 🟢     |
| `matRad_folderFindFallback` | Find fallback folder near path                                        | `fallbackPath = matRad_folderFindFallback(basePath)`                                                                   | 🟢     |



### **3. Structure and Contour Tools (cst)**

| File                                | Description                                 | Call                                                                                         | Status |
| ----------------------------------- | ------------------------------------------- | -------------------------------------------------------------------------------------------- | ------ |
| `matRad_cstSetup`                   | Initialize CST                              | `[cst, presDose, ixPTV, ixExt] = matRad_cstSetup(cst, VOINames, VOISites, mode)`             | 🟡     |
| `matRad_cstAddDoseObjectives`       | Add dose objectives manually                | `cst = matRad_cstAddDoseObjectives(cst, VOIs, basePenalty)`                                  | 🟢     |
| `matRad_cstAddDoseObjectivesMerged` | Merge objectives from multiple sources      | `cst = matRad_cstAddDoseObjectivesMerged(cst, [3 5], dvhRef, 100, 'sourceType','reference')` | 🟡     |
| `matRad_cstEmulateDVHObjectives`    | Generate DVH-based objectives               | `cst = matRad_cstEmulateDVHObjectives(cst, VOIs, dvhBase, basePenalty, metrics)`             | 🟢     |
| `matRad_cstMetrictoStruct`          | Convert human-readable metric to CST object | `obj = matRad_cstMetrictoStruct(metricStr)`                                                  | 🟢     |
| `matRad_cstPrint`                   | Print objectives                            | `matRad_cstPrint(cst)`                                                                       | 🟡     |
| `matRad_VOICreateRings`             | Create ring structures                      | `cstOut = matRad_VOICreateRings(ct, cst, voiName, marginMm, nRings)`                         | 🟡     |
| `matRad_VOIOperations`              | Combine VOIs via set operations             | `[cst, newIx] = matRad_VOIOperations(cst, ix1, ix2, operation, newName)`                     | 🟢     |
| `matRad_VOIfindIndex`               | Find VOI index                              | `ixVOI = matRad_VOIfindIndex(cst, aliases)`                                                  | 🟡     |
| `matRad_VOIDoseThresholdMask`       | Mask voxels above threshold                 | `mask = matRad_VOIDoseThresholdMask(cst, doseCube, {'L Lung'}, 10)`                          | 🟢     |
| `matRad_VOIDoseThreshold`           | Filter VOIs by dose threshold               | `cstFilt = matRad_VOIDoseThreshold(cst, doseCube, 10, 'above', 'voxels.txt')`                | 🟢     |
| `matRad_VOIfilterDoseThreshold`     | Legacy function for thresholding            | `cstFilt = matRad_VOIfilterDoseThreshold(cst, doseCube, 10, 'below')`                        | 🟡     |
| `matRad_VOIIrradiatedHealthyTissue` | Define healthy tissue VOIs above threshold  | `[cstNew, mask, maskThr] = matRad_VOIIrradiatedHealthyTissue(cst, doseCube, 10, false)`      | 🟢     |
| `matRad_VOIcompare`                 | Compare VOIs between plans                  | `[report, relDiffs] = matRad_VOIcompare(cst, qi, qiRef, {'D_2','mean'})`                     | 🟢     |

## **4. Dose Objectives and Constraints**

| File                                | Description                                                       | Call                                                                                         | Status |
| ----------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------ |
| `matRad_cstExtractDoseObjectives`   | Extract all dose objectives from CST into readable metric strings | `[metricStrings, objStruct] = matRad_cstExtractDoseObjectives(cst, VOIs)`                    | 🟢     |
| `matRad_cstEmulateDVHObjectives`    | Generate dose objectives from reference DVHs                      | `cst = matRad_cstEmulateDVHObjectives(cst, VOIs, dvhBase, basePenalty, metrics)`             | 🟢     |
| `matRad_cstMetrictoStruct`          | Convert human-readable metric string into dose objective struct   | `obj = matRad_cstMetrictoStruct(metricStr)`                                                  | 🟢     |
| `matRad_cstAddDoseObjectives`       | Add manual dose objectives to CST                                 | `cst = matRad_cstAddDoseObjectives(cst, [3 5], {'D_98 minDVH 30Gy 100','mean 200'}, true)`   | 🟢     |
| `matRad_cstAddDoseObjectivesMerged` | Merge objectives from manual, reference, or QI sources            | `cst = matRad_cstAddDoseObjectivesMerged(cst, [3 5], dvhRef, 100, 'sourceType','reference')` | 🟡     |


## **5. Beam Geometry / Energy Layers**

| File                                       | Description                                     | Call                                                                            | Status |
| ------------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------------------------- | ------ |
| `matRad_generateStfOneEL`                  | Generate single-layer STF for a beam            | `[stf_oneEL, stf_mb, stf_sb] = matRad_generateStfOneEL(ct, cst, pln)`           | 🟡     |
| `matRad_generateStfSSingleEnergyLayerBeam` | Generate STF with single EL per beam            | `[stf1EL, mb, sb] = matRad_generateStfSSingleEnergyLayerBeam(ct, cst, pln)`     | 🟡     |
| `matRad_generatePln`                       | Create basic matRad plan structure              | `pln = matRad_generatePln(cst, ct, gantryAngles, doseGridResolution, modality)` | 🟡     |
| `matRad_showSpotsInSlice`                  | Overlay all proton spot positions on dose slice | `matRad_showSpotsInSlice(ct, cst, stf, doseCube, weights)`                      | 🟡     |

---

## **6. Dose Calculation **

| File                        | Description                                                                            | Call                                                                  | Status |
| --------------------------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------ |
| `matRad_calcDoseCubeSimple` | Compute 3D physical/RBEx dose cube interpolated to CT grid                             | `doseCube = matRad_calcDoseCubeSimple(dij, w)`                        | 🟢     |
| `matRad_calcDoseCubePerEL`  | Compute dose cubes per energy layer using spot masks                                   | `eLayerStruct = matRad_calcDoseCubePerEL(dij, weights, eLayerStruct)` | 🟢     |
| `matRad_linearizeDose`      | Flatten DIJ into sparse form, compute dose per voxel, reshape to 3D, optional plotting | `dpDose_linear = matRad_linearizeDose(dij, w, pln, ct, cst, 1)`       | 🟢     |
| `matRad_doseCubeExtract`    | Extract physical or RBEx dose cube from `resultGUI`                                    | `doseCube = matRad_doseCubeExtract(resultGUI)`                        | 🟢     |

## **7. Plotting, DVH and Visualization Tools**

| File                               | Description                                                                      | Call                                                                         | Status |
| ---------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ------ |
| `matRad_dvhSortGroups`             | Group DVHs from multiple phases for batch plotting/statistics                    | `groups = matRad_dvhSortGroups(dvhAll, dvhRef, 3)`                           | 🟢     |
| `matRad_showMultiDVH`              | Plot DVHs from multiple sources for each VOI                                     | `matRad_plotMultiDVH(dvhResults, cst)`                                       | 🟡     |
| `matRad_showSliceAndDVH`           | Display dose slice and DVH side-by-side                                          | `[hleg, dvh] = matRad_showSliceAndDVH(ct, cst, doseCube)`                    | 🟡     |
| `matRad_showSliceFast`             | Quick slice visualization                                                        | `[slice, hleg] = matRad_showSliceFast(ct, cst, doseCube, slice, doseWindow)` | 🟡     |
| `matRad_compareTwoDoses`           | Compare reference vs test dose cubes; DVH overlay, slice differences, CI metrics | `matRad_compareTwoDoses(doseRef, doseTest, ct, cst, './out')`                | 🟡     |
| `matRad_writeQItoTxt`              | Export/append quality indicator structs to `.txt` or `table`                     | `matRad_writeQItoTxt(qi, 'out.txt')`                                         | 🟢     |
| `matRad_getRelevantSlices`         | Find relevant axial slices with nonzero or above-threshold dose                  | `slices = matRad_getRelevantSlices(cst, ct, doseCube, 0.05, 10)`             | 🟢     |
| `matRad_energyLayer_plotDosePerEL` | Plot per-EL dose maps with spots overlay on target slice                         | `matRad_energyLayer_plotDosePerEL(ct, cst, stf, topELStruct, qiByEL, 'GTV')` | 🟢     |
| `matRad_compareDoseDistribution`   | Comparison of two dose cubes visually                                            | `[~, ~, hfig] = matRad_compareDose(cube1, cube2, ct, cst)`                   | 🟢     |
| `matRad_calcQIndAdapted`           | Compute DVH-based quality indicators                                             | `qi = matRad_calcQIndAdapted(cst, pln, doseCube)`                            | 🟡     |

---


## **8. Spot and Energy Layer Analysis**

| File                                       | Description                                                                                      | Call                                                                                                                | Status      |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- | ----------- |
| `matRad_checkEnergies`                     | List unique energy layers per beam, counts and total rays                                        | `[allE, nE, nR] = matRad_checkEnergies(stf)`                                                                        | 🟢          |
| `matRad_generateStfSSingleEnergyLayerBeam` | Simplify STF to single EL per spot                                                               | `[stf1EL, mb, sb] = matRad_generateStfSSingleEnergyLayerBeam(ct, cst, pln)`                                         | 🟡          |
| `matRad_ELayerMergeSimilar`                | Merge adjacent/nearby energy layers into representative center layers                            | `merged = matRad_ELayerMergeSimilar(topEL, mergeRange, mergeTol)`                                                   | 🟢          |
| `matRad_weightEnergyLayers`                | Summarize weights per EL, compute dose contribution, identify top layers                         | `[tSummary, top, all, locs] = matRad_weightEnergyLayers(cst, stf, dij, w, oarIdx, wThresh)`                         | 🟢          |
| `matRad_dosePerEnergyLayer`                | Compute dose cubes per EL                                                                        | `doseCubes = matRad_dosePerEnergyLayer(ct,cst,stf,dij,resultGUI,threshold%)`                                        | 🟢          |
| `matRad_energyLayer_perVOIDose`            | Compute per-VOI dose per EL                                                                      | `[voiDoseByEL, qiByEL] = matRad_energyLayer_perVOIDose(cst, allELStruct, dij, w, refGy, refVol)`                    | 🟢          |
| `matRad_energyLayer_attachRaysToELStruct`  | Attach spot metadata to EL structure                                                             | `elStruct = matRad_energyLayer_attachRaysToELStruct(elStruct, stf)`                                                 | 🟢          |
| `matRad_energyLayer_plotDosePerEL`         | Grid figure of per-EL doses with spots overlay                                                   | `t = matRad_energyLayer_plotDosePerEL(ct,cst,stf,topELStruct,qiByEL,targetName)`                                    | 🟢          |
| `matRad_EnergyLayerAnalysis`               | High-level pipeline: weight layers, compute per-EL dose, attach rays, per-VOI metrics, visualize | `[voiDoseByEL, qiByEL, topEL] = matRad_EnergyLayerAnalysis(cst,stf,dij,ct,resultGUI,ixTarget,ixOAR)`                | 🟢          |
| `matrad_exampleEnergyLayerAnalysis`        | Example/demo script showcasing EnergyLayerAnalysis                                               | `matrad_exampleEnergyLayerAnalysis()`                                                                               | 🟡          |
| `matRad_computeSpotStats`                  | Compute summary spot statistics                                                                  | `stats = matRad_computeSpotStats(stf, w)`                                                                           | 🟡          |
| `matRad_analyzeSpotsPerBeam`               | Visual/interactive analysis of one beam                                                          | `[doseHeavy, stats] = matRad_analyzeSpotsPerBeam(iBeam, ct,cst,stf,dij,resultGUI,mode,threshold)`                   | 🟢          |
| `matRad_analyzeSpotsPerBeamStats`          | Numeric stats per beam for filtered spots                                                        | `[doseHeavy, stats, wHeavy, mask] = matRad_analyzeSpotsPerBeamStats(iBeam,ct,cst,stf,dij,resultGUI,mode,threshold)` | 🟢          |
| `matRad_removeSpotsOverlappingVOIs`        | Remove spots overlapping VOIs; return retained mask & indices                                    | `[logicalMask, removedIdx] = matRad_removeSpotsOverlappingVOIs(stf, ct, cst, ixVOI, iBeam)`                         | 🟢          |
| `matRad_getMachineEnergyColorMap`          | Build machine-specific EL → RGB mapping for plotting                                             | `cmap = matRad_getMachineEnergyColorMap(stf)`                                                                       | 🟡          |
| `matRad_plotEnergyLayerWeightsHistogram`   | Plot total spot weights per EL                                                                   | `matRad_plotEnergyLayerWeightsHistogram(ax, stf, 'perBeam')`                                                        | Implemented |
| `matRad_plotEnergyLayerHistogram`          | Plot number of spots per EL                                                                      | `matRad_plotEnergyLayerHistogram(ax, stf)`                                                                          | Implemented |
| `matRad_calcSpotWeightsAndMatrix`          | Normalize weights and build 3D matrix                                                            | `[stf, wMatrix] = matRad_calcSpotWeightsAndMatrix(stf, weights)`                                                    | Implemented |
| `matRad_computeSpotPositions_Siddon`       | Compute spot positions using Siddon algorithm                                                    | `stf = matRad_computeSpotPositions_Siddon(ct, stf, machine)`                                                        | Implemented |
| `matRad_plotSingleRay`                     | Visualize spots from specific ray index                                                          | `medianSpotCube = matRad_plotSingleRay(ax, stf, iRayTarget, markerSize, weights, useGeoSpots)`                      | Implemented |
| `matRad_spotIx`                            | Compute global 1D index of a spot                                                                | `ix = matRad_spotIx(stf, iBeam, iRay, iSpot)`                                                                       | Implemented |


## **9. FLASH / DMF**

| File                            | Description                                                                                                                                                                                                                                                                       | Call                                                                                                                                                                                                                                                                                          | Status |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `matRad_FLASHDMFPipeline`       | Complete FLASH dose-modification pipeline. Applies a Dose Modifying Factor (DMF) to voxels above a threshold in selected OARs, healthy tissue, or both. Returns modified dose cube, binary masks, and optionally updates CST. Supports modes: `'OAR'`, `'Healthy'`, `'Combined'`. | `[doseCubeMod, maskStruct, cstOut] = matRad_FLASHDMFPipeline(cst, doseCube, DMF, voiSelection, doseThreshold)`<br>`[doseCubeMod, maskStruct, cstOut] = matRad_FLASHDMFPipeline(cst, doseCube, DMF, voiSelection, doseThreshold, outputTxtFile, includeHealthyTissue, returnMasks, applyMode)` | 🟢     |
| `matRad_FLASHApplyDMF`          | Apply FLASH DMF to a 3D dose cube using pre-computed voxel masks or per-VOI DMF. Supports optional output summary.                                                                                                                                                                | `doseCubeMod = matRad_FLASHApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask)`<br>`doseCubeMod = matRad_FLASHApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask, outputTxtFile)`                                                                                           | 🟢     |
| `matRad_recoverFlashDose`       | Reconstruct original FLASH dose distribution from DMF-modified dose cube. Generates dose difference map and FLASH-effect mask. Optional QC plotting included.                                                                                                                     | `[doseFLASH, doseDiff, flashMask] = matRad_recoverFlashDose(ct, cst, doseEff, DMF, FLASHthresh, doPlot)`                                                                                                                                                                                      | 🟢     |
| `matRad_recoverFlashDoseSimple` | Threshold-based reconstruction of pre-DMF FLASH dose. Provides dose difference and voxel mask. Simple, fast version for QC purposes.                                                                                                                                              | `[doseFLASH, doseDiff, flashVoxels] = matRad_recoverFlashDoseSimple(ct, cst, doseEff, DMF, FLASHthresh, doPlot)`                                                                                                                                                                              | 🟢     |
| `matRad_restoreFLASH_detectDMF` | Detect likely FLASH DMF-affected voxels using dose-only heuristics (`threshold`, `valley`, `morph`) and reconstruct pre-DMF dose cube. Returns reconstructed dose, mask, and report with statistics.                                                                              | `[doseFLASH, flashMask, report] = matRad_restoreFLASH_detectDMF(doseEff, cst, ixTarget)`<br>`[doseFLASH, flashMask, report] = matRad_restoreFLASH_detectDMF(doseEff, cst, ixTarget, 'DMF',2.0,'DoseThr',10,'Method','valley','DoPlot',true)`                                                  | 🟢     |
| `matRad_evaluateFLASHBeams`     | Evaluate multiple FLASH proton beam plans using dose metrics: PTV, FLASH target, OARs, Conformity Index (CI), and objective values. Prints a summary table.                                                                                                                       | `matRad_evaluateFLASHBeams(beamSearch, cst, ptvAlias, flashAlias, oarAliases, prescribedDose)`                                                                                                                                                                                                | 🟢     |


## **10. Miscellaneous**

| File                   | Description                        | Call                                         | Status |
| ---------------------- | ---------------------------------- | -------------------------------------------- | ------ |
| `STAR_getPatientPaths` | Helper to locate STAR patient data | `[paths] = STAR_getPatientPaths(baseFolder)` | 🟢     |
