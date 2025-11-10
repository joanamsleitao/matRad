Here is the cleaned-up and formatted Markdown file, with the functions in each category sorted alphabetically by their **Current Name**.

# 📘 MATLAB Radiotherapy Utilities – Function Reference (with Previous Names)

This document summarizes all MATLAB functions developed, grouped by category. Each function includes:

  * **Previous Name** – original function name before shortening
  * **Current Name** – standardized short `matRad` name
  * **Description** – what it does
  * **Call** – example usage
  * **Status** – development/stability indicator

✅ **Legend:**
🟢 Stable — tested and ready for integration
🟡 Needs refinement — partially implemented or pending testing
🔴 Experimental — draft or conceptual
❌ Deprecated — no longer in use

-----

## **2. Data Import / Export**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_dataImport | matRad\_dataImp | Load CT/CST/dose from MAT or DICOM | `[ct, cst, doseCube] = matRad_dataImp(patientName, wildcardPath, wildcard)` | 🟢 |
| matRad\_dataImportAndLoad | matRad\_dataImpLoad | Simplified variant with optional saving | `[ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImpLoad(patientName, inputPath, Name,Value)` | 🟢 |
| matRad\_dataImportPatient | matRad\_dataImpPat | Unified patient import (MAT/DICOM) with fallback handling | `[ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImpPat(patientName, inputPath, Name,Value)` | 🟢 |
| matRad\_dataLoadMat | matRad\_dataLoad | Load variables selectively from MAT file | `[ct, cst, pln, stf, resultGUI] = matRad_dataLoadMat(filePath)` | 🟢 |
| matRad\_dicomImportFolder | matRad\_dicomFldr | Import DICOM from main folder, with optional fallback for CT/RTSTRUCT | `[ct, cst, pln, stf, resultGUI] = matRad_dicomFldr(primaryPath, fallbackPath)` | 🟢 |
| matRad\_dicomImport | matRad\_dicomImp | Import DICOM from a given path | `ct, cst, pln, stf = matRad_dicomImp(path)` | 🟢 |
| matRad\_dicomLoad | matRad\_dicomLoad | Load DICOM object and save as MAT | `[matRadFileName, ct, cst, pln, stf, resultGUI] = matRad_dicomLoad(dcmImpObj, pathToFolder)` | 🟢 |
| matRad\_dicomImportPath | matRad\_dicomPath | Import DICOM from folder, optional fallback | `[ct, cst, pln, stf, resultGUI] = matRad_dicomPath(inputPath, secondPath)` | 🟢 |
| matRad\_filenameGenerate | matRad\_fileGen | Generate standardized filenames | `[fileNameComplete] = matRad_fileGen(fileFolder, pln, workspaceType)` | 🟡 |
| matRad\_filenameGet | matRad\_fileGet | Locate files based on naming patterns | `[fileNameComplete] = matRad_fileGet(fileFolder, gantrySep, res, workspaceType)` | 🟡 |
| matRad\_fileSearch | matRad\_fileSearch | Search for MAT files in folder | `matFiles = matRad_fileSearch()` | 🟡 |
| matRad\_loadFolderDICOM | matRad\_folderDICOM | Import patient data from DICOM folder, with fallback | `[ct, cst, pln, stf, resultGUI] = matRad_folderDICOM(folderPath, matchPattern, fallbackPath)` | 🟢 |
| matRad\_folderFindFallback | matRad\_folderFallback | Find fallback folder near path | `fallbackPath = matRad_folderFallback(basePath)` | 🟢 |
| matRad\_loadFolderMat | matRad\_folderMat | Load MAT files from folder with matching | `[ct, cst, pln, stf, resultGUI] = matRad_folderMat(folderPath, matFiles, matchPattern, fallbackMat, fallbackPath)` | 🟢 |
| matRad\_matLoadSingle | matRad\_loadMat1 | Wrapper with fallback MAT support | `[ct, cst, pln, stf, resultGUI] = matRad_loadMat1(filePath, fallbackMat)` | 🟢 |
| matRad\_filePatientPath | matRad\_patPath | Locate patient folders/files recursively | `[targetPath, patientFolder] = matRad_patPath(patientID, searchFolder, searchFile)` | 🟢 |
| matRad\_savePatientMat | matRad\_savePatientMat | Save patient data to MAT | `matRad_savePatientMat(patientName, ct, cst, pln, stf, resultGUI, saveDir, saveName)` | 🟢 |

-----

## **3. Structure and Contour Tools (CST/VOI)**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_cstAddDoseObjectives | matRad\_cstAddObj | Add dose objectives manually | `cst = matRad_cstAddObj(cst, VOIs, basePenalty)` | 🟢 |
| matRad\_cstAddDoseObjectivesMerged | matRad\_cstAddObjMged | Merge objectives from multiple sources | `cst = matRad_cstAddObjMged(cst, [3 5], dvhRef, 100, 'sourceType','reference')` | 🟡 |
| matRad\_cstEmulateDVHObjectives | matRad\_cstAddObjRefDVH | Generate DVH-based objectives | `cst = matRad_cstAddObjRefDVH(cst, VOIs, dvhBase, basePenalty, metrics)` | 🟢 |
| matRad\_cstExtractDoseObjectives | matRad\_cstExtDoseObj | Extract all dose objectives from CST | `[metricStrings, objStruct] = matRad_cstExtDoseObj(cst, VOIs)` | 🟢 |
| matRad\_cstMetrictoStruct | matRad\_cstMetric2Struct | Convert human-readable metric to CST object | `obj = matRad_cstMetric2Struct(metricStr)` | 🟢 |
| matRad\_cstPrint | matRad\_cstPrint | Print objectives | `matRad_cstPrint(cst)` | 🟡 |
| matRad\_setupCST | matRad\_cstSetup | Initialize CST | `[cst, presDose, ixPTV, ixExt] = matRad_cstSetup(cst, VOINames, VOISites, mode)` | 🟡 |
| matRad\_VOIcompare | matRad\_VOIcmp | Compare VOIs between plans | `[report, relDiffs] = matRad_VOIcmp(cst, qi, qiRef, {'D_2','mean'})` | 🟢 |
| matRad\_VOICreateRings | matRad\_VOICreateRings | Create ring structures | `cstOut = matRad_VOICreateRings(ct, cst, voiName, marginMm, nRings)` | 🟡 |
| matRad\_VOIDoseThreshold | matRad\_VOIDoseThr | Filter VOIs by dose threshold | `cstFilt = matRad_VOIDoseThr(cst, doseCube, 10, 'above', 'voxels.txt')` | 🟢 |
| matRad\_VOIDoseThresholdMask | matRad\_VOIDoseThrMask | Mask voxels above threshold | `mask = matRad_VOIDoseThrMask(cst, doseCube, {'L Lung'}, 10)` | 🟢 |
| matRad\_VOIfilterDoseThreshold | matRad\_VOIFilterDoseThr | Legacy function for thresholding | `cstFilt = matRad_VOIFilterDoseThr(cst, doseCube, 10, 'below')` | 🟡 |
| matRad\_VOIfindIndex | matRad\_VOIFindIx | Find VOI index | `ixVOI = matRad_VOIFindIx(cst, aliases)` | 🟡 |
| matRad\_VOIIrradiatedHealthyTissue | matRad\_VOIHealthy | Define healthy tissue VOIs above threshold | `[cstNew, mask, maskThr] = matRad_VOIHealthy(cst, doseCube, 10, false)` | 🟢 |
| matRad\_VOIOperations | matRad\_VOIOps | Combine VOIs via set operations | `[cst, newIx] = matRad_VOIOps(cst, ix1, ix2, operation, newName)` | 🟢 |

-----

## **4. Dose Objectives and Constraints**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_cstAddDoseObjectives | matRad\_cstAddObj | Add manual dose objectives to CST | `cst = matRad_cstAddObj(cst, [3 5], {'D_98 minDVH 30Gy 100','mean 200'}, true)` | 🟢 |
| matRad\_cstAddDoseObjectivesMerged | matRad\_cstAddObjMged | Merge objectives from manual, reference, or QI sources | `cst = matRad_cstAddObjMged(cst, [3 5], dvhRef, 100, 'sourceType','reference')` | 🟡 |
| matRad\_cstEmulateDVHObjectives | matRad\_cstAddObjRefDVH | Generate dose objectives from reference DVHs | `cst = matRad_cstAddObjRefDVH(cst, VOIs, dvhBase, basePenalty, metrics)` | 🟢 |
| matRad\_cstExtractDoseObjectives | matRad\_cstExtDoseObj | Extract all dose objectives from CST into readable metric strings | `[metricStrings, objStruct] = matRad_cstExtDoseObj(cst, VOIs)` | 🟢 |
| matRad\_cstMetrictoStruct | matRad\_cstMetric2Struct | Convert human-readable metric string into dose objective struct | `obj = matRad_cstMetric2Struct(metricStr)` | 🟢 |

-----

## **5. Beam Geometry / Energy Layers**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_generatePln | matRad\_genPln | Create basic matRad plan structure | `pln = matRad_genPln(cst, ct, gantryAngles, doseGridResolution, modality)` | 🟡 |
| matRad\_generateStfOneEL | matRad\_genStf1EL | Generate single-layer STF for a beam | `[stf_oneEL, stf_mb, stf_sb] = matRad_genStf1EL(ct, cst, pln)` | 🟡 |
| matRad\_generateStfSSingleEnergyLayerBeam | matRad\_genStfELB2 | Generate STF with single EL per beam | `[stf1EL, mb, sb] = matRad_genStfELB(ct, cst, pln)` | 🟡 |
| matRad\_getMachineEnergyColorMap | matRad\_machineColorMap | Build machine-specific EL → RGB mapping for plotting | `cmap = matRad_machColorMap(stf)` | 🟡 |
| matRad\_showSpotsInSlice | matRad\_showSpots | Overlay all proton spot positions on dose slice | `matRad_showSpots(ct, cst, stf, doseCube, weights)` | 🟡 |

-----

## **6. Dose Calculation / Comparison**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_calcQIndAdapted | matRad\_calcQI | Compute DVH-based quality indicators | `qi = matRad_calcQI(cst, pln, doseCube)` | 🟡 |
| matRad\_compareTwoDoses | matRad\_cmp2Doses | Compare reference vs test dose cubes; DVH overlay, slice differences, CI metrics | `matRad_cmp2Doses(doseRef, doseTest, ct, cst, './out')` | 🟡 |
| matRad\_compareDoseDistribution | matRad\_cmpDose | Comparison of two dose cubes visually | `[~, ~, hfig] = matRad_cmpDose(cube1, cube2, ct, cst)` | 🟢 |
| matRad\_doseCubeExtract | matRad\_doseExtract | Extract physical or RBEx dose cube from `resultGUI` | `doseCube = matRad_doseExtract(resultGUI)` | 🟢 |
| matRad\_dosePerEnergyLayer | matRad\_dosePerEL | Compute dose cubes per EL | `doseCubes = matRad_dosePerEL(ct,cst,stf,dij,resultGUI,threshold%)` | 🟢 |
| matRad\_calcDoseCubePerEL | matRad\_ELDoseCube | Compute dose cubes per energy layer using spot masks | `eLayerStruct = matRad_ELDoseCube(dij, weights, eLayerStruct)` | 🟢 |
| matRad\_linearizeDose | matRad\_linearDose | Flatten DIJ into sparse form, compute dose per voxel, reshape to 3D, optional plotting | `dpDose_linear = matRad_linearDose(dij, w, pln, ct, cst, 1)` | 🟢 |

-----

## **7. Plotting, DVH and Visualization Tools**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_plotCTSlice | matRad\_plotCT | Plot CT slice | `matRad_plotCT(ct, slice)` | Implemented |
| matRad\_plotEnergyLayerHistogram | matRad\_plotELhist | Plot number of spots per EL | `matRad_plotELhist(ax, stf)` | Implemented |
| matRad\_plotSpotsSlice | matRad\_plotSpotsSlice | Plot all spots in a CT slice | `matRad_plotSpotsSlice(ct, stf, slice)` | Implemented |
| matRad\_showDVHAdapted | matRad\_showDVH | Show adapted DVH | `matRad_showDVH(cst, doseCube)` | 🟡 |
| matRad\_showMultiDVH | matRad\_showMultiDVH | Plot multiple DVHs from multiple sources | `matRad_showMultiDVH(dvhResults, cst)` | 🟡 |
| matRad\_showSliceAndDVH | matRad\_showSliceDVH | Display dose slice and DVH side-by-side | `[hleg, dvh] = matRad_showSliceDVH(ct, cst, doseCube)` | 🟡 |
| matRad\_showSliceFast | matRad\_showSliceF | Quick slice visualization | `[slice, hleg] = matRad_showSliceF(ct, cst, doseCube, slice, doseWindow)` | 🟡 |

-----

## **8. Spot and Energy Layer Analysis**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matrad\_exampleEnergyLayerAnalysis | ?? | Example/demo script showcasing EnergyLayerAnalysis | `matRad_EX_ELAnal()` | 🟡 |
| matRad\_energyLayer\_attachRaysToELStruct | matRad\_attachRays | Attach spot metadata to EL structure | `elStruct = matRad_attachRays(elStruct, stf)` | 🟢 |
| matRad\_checkEnergies | matRad\_chkEnergy | List unique energy layers per beam, counts and total rays | `[allE, nE, nR] = matRad_chkEnergy(stf)` | 🟢 |
| matRad\_dosePerEnergyLayer | matRad\_dosePerEL | Compute dose cubes per EL | `doseCubes = matRad_dosePerEL(ct,cst,stf,dij,resultGUI,threshold%)` | 🟢 |
| matRad\_energyLayer\_perVOIDose | matRad\_dosePerVOI | Compute per-VOI dose per EL | `[voiDoseByEL, qiByEL] = matRad_dosePerVOI(cst, allELStruct, dij, w, refGy, refVol)` | 🟢 |
| matRad\_EnergyLayerAnalysis | matRad\_ELAnalysis | High-level pipeline: weight layers, compute per-EL dose, attach rays, per-VOI metrics, visualize | `[voiDoseByEL, qiByEL, topEL] = matRad_ELAnalysis(cst,stf,dij,ct,resultGUI,ixTarget,ixOAR)` | 🟢 |
| matRad\_generateStfSSingleEnergyLayerBeam | matRad\_genStfELB | Simplify STF to single EL per spot | `[stf1EL, mb, sb] = matRad_genStfELB(ct, cst, pln)` | 🟡 |
| matRad\_getMachineEnergyColorMap | matRad\_machineColorMap | Build machine-specific EL → RGB mapping for plotting | `cmap = matRad_machColorMap(stf)` | 🟡 |
| matRad\_ELayerMergeSimilar | matRad\_mergeEL | Merge adjacent/nearby energy layers into representative center layers | `merged = matRad_mergeEL(topEL, mergeRange, mergeTol)` | 🟢 |
| matRad\_energyLayer\_plotDosePerEL | matRad\_plotDoseEL | Grid figure of per-EL doses with spots overlay | `t = matRad_plotDoseEL(ct,cst,stf,topELStruct,qiByEL,targetName)` | 🟢 |
| matRad\_plotEnergyLayerPerWeight | matRad\_plotELW | Plot per-weight energy layer representation | `matRad_plotELwt(ax, stf)` | 🟢 |
| matRad\_plotEnergyLayerHistogram | matRad\_plotELhist | Plot number of spots per EL | `matRad_plotELhist(ax, stf)` | 🟢 |
| matRad\_plotEnergyLayerHistogramCountsAndWeights | matRad\_plotELhistCW | Plot histogram of counts and weights per EL | `matRad_plotELhistCW(ax, stf)` | 🟢 |
| matRad\_plotEnergyLayerHistogramCountsAndWeightsStacked | matRad\_plotELhistCWStack | Plot stacked histogram of counts and weights per EL | `matRad_plotELhistStack(ax, stf)` | 🟢 |
| matRad\_plotEnergyLayerHistogramStackedWeights | matRad\_plotELhistWStack | Plot stacked histogram of weights per EL | `matRad_plotELhistSwt(ax, stf)` | 🟢 |
| matRad\_plotEnergyLayerWeightsHistogram | matRad\_plotELwtHist | Plot total spot weights per EL | `matRad_plotELwtHist(ax, stf, 'perBeam')` | 🟢 |
| matRad\_plotGeoSpot | matRad\_plotGeoSpot | Plot spot geometry visualization | `matRad_plotGeo(ct, stf, iBeam)` | 🟡 |
| matRad\_plotSingleRay | matRad\_plotRay | Visualize spots from specific ray index | `medianSpotCube = matRad_plotRay(ax, stf, iRayTarget, markerSize, weights, useGeoSpots)` | 🟢 |
| matRad\_removeSpotsOverlappingVOIs | matRad\_rmSpotsVOI | Remove spots overlapping VOIs; return retained mask & indices | `[logicalMask, removedIdx] = matRad_rmSpotsVOI(stf, ct, cst, ixVOI, iBeam)` | 🟢 |
| matRad\_spotIx | matRad\_spotIx | Compute global 1D index of a spot | `ix = matRad_spotIx(stf, iBeam, iRay, iSpot)` | 🟢 |
| matRad\_calcSpotWeightsAndMatrix | matRad\_spotWeight | Normalizes and assigns spot weights, and constructs a 3D weight matrix | `[stf, wMatrix] = matRad_calcSpotWeightsAndMatrix(stf, weights)` | 🟢 |
| matRad\_analyzeSpotsPerBeam | matRad\_spotsAnalyze ERROR | Visual/interactive analysis of one beam | `[doseHeavy, stats] = matRad_spotsAnalyze(iBeam, ct,cst,stf,dij,resultGUI,mode,threshold)` | 🟢 |
| matRad\_computeSpotPositions\_Geo | matRad\_spotsPosGeo | Computes spot positions based on beam setup geometry | `stf = matRad_spotsPosSiddon(ct, stf, machine)` | 🟢 |
| matRad\_computeSpotPositions\_Siddon | matRad\_spotsPosSiddon | Compute spot positions using Siddon algorithm | `stf = matRad_spotsPosSiddon(ct, stf, machine)` | 🟢 |
| matRad\_computeSpotStats | matRad\_spotsStats | Compute summary spot statistics | `stats = matRad_spotsStats(stf, w)` | 🟡 |
| matRad\_analyzeSpotsPerBeamStats | matRad\_spotsStatsBeam | Numeric stats per beam for filtered spots | `[doseHeavy, stats, wHeavy, mask] = matRad_spotsStatsBeam(iBeam,ct,cst,stf,dij,resultGUI,mode,threshold)` | 🟢 |
| matRad\_weightEnergyLayers | matRad\_weightEL | Summarize weights per EL, compute dose contribution, identify top layers | `[tSummary, top, all, locs] = matRad_wtEL(cst, stf, dij, w, oarIdx, wThresh)` | 🟢 |

-----

## **9. FLASH / DMF**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad\_restoreFLASH\_detectDMF | matRad\_detectFLASH | Detect likely FLASH DMF-affected voxels using dose-only heuristics (`threshold`, `valley`, `morph`) and reconstruct pre-DMF dose cube. Returns reconstructed dose, mask, and report with statistics. | `[doseFLASH, flashMask, report] = matRad_detectFLASH(doseEff, cst, ixTarget)`<br>`[doseFLASH, flashMask, report] = matRad_detectFLASH(doseEff, cst, ixTarget, 'DMF',2.0,'DoseThr',10,'Method','valley','DoPlot',true)` | 🟢 |
| matRad\_evaluateFLASHBeams | matRad\_evalFLASH | Evaluate multiple FLASH proton beam plans using dose metrics: PTV, FLASH target, OARs, Conformity Index (CI), and objective values. Prints a summary table. | `matRad_evalFLASH(beamSearch, cst, ptvAlias, flashAlias, oarAliases, prescribedDose)` | 🟢 |
| matRad\_FLASHApplyDMF | matRad\_flashApplyDMF | Apply FLASH DMF to a 3D dose cube using pre-computed voxel masks or per-VOI DMF. Supports optional output summary. | `doseCubeMod = matRad_flashApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask)`<br>`doseCubeMod = matRad_flashApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask, outputTxtFile)` | 🟢 |
| matRad\_FLASHDMFPipeline | matRad\_flashPipeline | Complete FLASH dose-modification pipeline. Applies a Dose Modifying Factor (DMF) to voxels above a threshold in selected OARs, healthy tissue, or both. Returns modified dose cube, binary masks, and optionally updates CST. | `[doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline(cst, doseCube, DMF, voiSelection, doseThreshold)`<br>`[doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline(cst, doseCube, DMF, voiSelection, doseThreshold, outputTxtFile, includeHealthyTissue, returnMasks, applyMode)` | 🟢 |
| matRad\_recoverFlashDose | matRad\_recoverFlash | Reconstruct original FLASH dose distribution from DMF-modified dose cube. Generates dose difference map and FLASH-effect mask. Optional QC plotting included. | `[doseFLASH, doseDiff, flashMask] = matRad_recoverFlash(ct, cst, doseEff, DMF, FLASHthresh, doPlot)` | 🟢 |
| matRad\_recoverFlashDoseSimple | matRad\_recoverFlashSimple | Threshold-based reconstruction of pre-DMF FLASH dose. Provides dose difference and voxel mask. Simple, fast version for QC purposes. | `[doseFLASH, doseDiff, flashVoxels] = matRad_recoverFlashSimple(ct, cst, doseEff, DMF, FLASHthresh, doPlot)` | 🟢 |

-----

## **10. Miscellaneous**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| STAR\_getPatientPaths | STAR\_getPatientPaths | Helper to locate STAR patient data | `[paths] = STAR_getPatientPaths(baseFolder)` | 🟢 |