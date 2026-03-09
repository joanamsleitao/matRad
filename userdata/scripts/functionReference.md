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


## **2. Data Import / Export**

| Previous Name | Current Name | Description | Call | Status |
| --- | --- | --- | --- | --- |
| –  | matRad_dataImpWrap | High-level wrapper: for given patient, path, and plan, load from MAT if present, otherwise import from DICOM using `matRad_dicomImpDose` | `[ct, cst, doseCube, resultGUI] = matRad_dataImpWrap(patientName, inputPath, planName, 'fallbackPath', fbPath, 'saveDir', outDir)` | 🟢 |
| –  | matRad_dicomImpDose | Import CT, RTSTRUCT and one or multiple RTDOSE series; saves `matRadPatient_<pat>_<plan>.mat` or split `ct_cst_<pat>.mat` + `doseCube_<pat>_<plan>.mat` | `matRad_dicomImpDose(patientName, dicomPath, {'PlanA','PlanB'}, 'fallbackPath', path, 'saveDir', outDir)` | 🟢 |
| –  | matRad_matLoad | Load CT, CST, doseCube, resultGUI by patient/plan from MAT (exact or wildcard search, supports split CT/CST + dose files) | `[ct, cst, doseCube, resultGUI] = matRad_matLoad(patientName, planName, 'searchDir', folder)` | 🟢 |
| -  | matRad_matLoadDirect | Load variables selectively from MAT file by path | `[ct, cst, pln, stf, resultGUI] = matRad_matLoadDirect(filePath)` | 🟢 |
| –  | matRad_findPatientMats | Find all MAT files for a patient, optionally filtered by plan/beam string | `matFiles = matRad_findPatientMats('SP03', 'PassivePlusArc', 'searchDir', dir)` | 🟢 |
| | | *Workspace Based* | |
| matRad_filenameGenerate | matRad_wsFileGen | Generate standardized workspace filenames from plan gantry spacing and dose grid resolution (e.g. `Base_plnstfdijGantry10Res222_2025-01-05_1430.mat`) | `[filePath, fileFolder, fileName] = matRad_fileGen(fileFolder, pln, workspaceType)` | 🟢 |
| matRad_fileGet | matRad_wsFileFind | Find simulation/workspace MAT files by gantry spacing and dose grid resolution (e.g. `Base_plnstfdijGantry10Res222_*.mat`) | `[filePath, fileFolder, fileName, allMatches] = matRad_fileGet(folder, gantrySep, [dx dy dz], workspaceType)` | 🟢 |
| matRad_filePatientPath | matRad_patPath | Locate patient folders/files recursively | `[targetPath, patientFolder] = matRad_patPath(patientID, searchFolder, searchFile)` | 🟢 |
| matRad_savePatientMat | matRad_savePatientMat | Save patient data to MAT | `matRad_savePatientMat(patientName, ct, cst, pln, stf, resultGUI, saveDir, saveName)` | 🟢 |

Key rule:

    Patient / clinical plan IO → always use:
        matRad_dicomImpDose (save using patient+plan)
        matRad_matLoad / matRad_findPatientMats
        matRad_dataImpWrap
    Simulation / optimization workspace IO → use:
        matRad_fileGen (or matRad_wsFileGen)
        matRad_fileGet (or matRad_wsFileFind)
        matRad_matLoadDirect to load from a chosen workspace file

-----

## **3. Structure and Contour Tools (CST/VOI)**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad_cstAddDoseObjectives | matRad_cstAddObj | Add dose objectives manually | `cst = matRad_cstAddObj(cst, VOIs, basePenalty)` | 🟢 |
| matRad_cstAddDoseObjectivesMerged | matRad_cstAddObjMged | Merge objectives from multiple sources | `cst = matRad_cstAddObjMged(cst, [3 5], dvhRef, 100, 'sourceType','reference')` | 🟡 |
| matRad_cstEmulateDVHObjectives | matRad_cstAddObjRefDVH | Generate DVH-based objectives | `cst = matRad_cstAddObjRefDVH(cst, VOIs, dvhBase, basePenalty, metrics)` | 🟢 |
| matRad_cstExtractDoseObjectives | matRad_cstExtDoseObj | Extract all dose objectives from CST | `[metricStrings, objStruct] = matRad_cstExtDoseObj(cst, VOIs)` | 🟢 |
| matRad_cstMetrictoStruct | matRad_cstMetric2Struct | Convert human-readable metric to CST object | `obj = matRad_cstMetric2Struct(metricStr)` | 🟢 |
| matRad_cstPrint | matRad_cstPrint | Print objectives | `matRad_cstPrint(cst)` | 🟡 |
| matRad_setupCST | matRad_cstSetup | Initialize CST | `[cst, presDose, ixPTV, ixExt] = matRad_cstSetup(cst, VOINames, VOISites, mode)` | 🟡 |
| matRad_VOIcompare | matRad_VOIcmp | Compare VOIs between plans | `[report, relDiffs] = matRad_VOIcmp(cst, qi, qiRef, {'D_2','mean'})` | 🟢 |
| matRad_VOICreateRings | matRad_VOICreateRings | Create ring structures | `cstOut = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)` | 🟡 |
| matRad_VOIDoseThreshold | matRad_VOIDoseThr | Filter VOIs by dose threshold | `cstFilt = matRad_VOIDoseThr(cst, doseCube, 10, 'above', 'voxels.txt')` | 🟢 |
| matRad_VOIDoseThresholdMask | matRad_VOIDoseThrMask | Mask voxels above threshold | `mask = matRad_VOIDoseThrMask(cst, doseCube, {'L Lung'}, 10)` | 🟢 |
| matRad_VOIfilterDoseThreshold | matRad_VOIFilterDoseThr | Legacy function for thresholding | `cstFilt = matRad_VOIFilterDoseThr(cst, doseCube, 10, 'below')` | 🟡 |
| matRad_VOIfindIndex | matRad_VOIFindIx | Find VOI index | `ixVOI = matRad_VOIFindIx(cst, aliases)` | 🟡 |
| matRad_VOIIrradiatedHealthyTissue | matRad_VOIHealthy | Define healthy tissue VOIs above threshold | `[mask, cst, maskThr] = matRad_VOIHealthy(cst, doseCube, 10, false)` | 🟢 |
| `N/A` | `matRad_VOIHealthy` | Create VOIs for irradiated healthy tissue with island-size filtering | `[healthyMask, cstNew, healthyAboveThrMask] = matRad_VOIHealthy(cst, doseCube, doseThreshold, includeTargets, minIslandVox)` | 🟢 |
| matRad_VOIOperations | matRad_VOIOps | Combine VOIs via set operations | `[cst, newIx] = matRad_VOIOps(cst, ix1, ix2, operation, newName)` | 🟢 |
| matRad_OARFindIx | matRad_VOIOARFindIx | Finds all indexes of OARs | `ixOARs = matRad_VOIOARFindIx(cst)`  | 🟢 |
|| matRad_getVoiMask | Returns a binary mask for a VOI | `mask = matRad_getVoiMask(ct, cst, voiName, slice)` | 🟢 |
|| matRad_fixExternalMask | Repair missing voxels or gaps in External contour | `[maskExternalFixed, cstOut, alteredSlices] = matRad_fixExternalMask(ct, cst, HUrange, sliceList)` | 🟢 |



-----

## **4. Dose Objectives and Constraints**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad_cstAddDoseObjectives | matRad_cstAddObj | Add manual dose objectives to CST | `cst = matRad_cstAddObj(cst, [3 5], {'D_98 minDVH 30Gy 100','mean 200'}, true)` | 🟢 |
| matRad_cstAddDoseObjectivesMerged | matRad_cstAddObjMged | Merge objectives from manual, reference, or QI sources | `cst = matRad_cstAddObjMged(cst, [3 5], dvhRef, 100, 'sourceType','reference')` | 🟡 |
| matRad_cstEmulateDVHObjectives | matRad_cstAddObjRefDVH | Generate dose objectives from reference DVHs | `cst = matRad_cstAddObjRefDVH(cst, VOIs, dvhBase, basePenalty, metrics)` | 🟢 |
| matRad_cstExtractDoseObjectives | matRad_cstExtDoseObj | Extract all dose objectives from CST into readable metric strings | `[metricStrings, objStruct] = matRad_cstExtDoseObj(cst, VOIs)` | 🟢 |
| matRad_cstMetrictoStruct | matRad_cstMetric2Struct | Convert human-readable metric string into dose objective struct | `obj = matRad_cstMetric2Struct(metricStr)` | 🟢 |

-----

## **5. Beam Geometry / Energy Layers**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad_generatePln | matRad_genPln | Create basic matRad plan structure | `pln = matRad_genPln(cst, ct, gantryAngles, doseGridResolution, modality)` | 🟡 |
| matRad_generateStfOneEL | matRad_genStf1EL | Generate single-layer STF for a beam | `[stf_oneEL, stf_mb, stf_sb] = matRad_genStf1EL(ct, cst, pln)` | 🟡 |
| matRad_generateStfSSingle... | matRad_genStfELB2 | Generate STF with single EL per beam | `[stf1EL, mb, sb] = matRad_genStfELB(ct, cst, pln)` | 🟡 |
| `matRad_getMachineE...` | `matRad_machineColorMap` | Build machine-specific EL → RGB mapping for plotting | `cmap = matRad_machineColorMap(stf)` | 🟡 |
| matRad_showSpotsInSlice | matRad_showSpots | Overlay all proton spot positions on dose slice | `matRad_showSpots(ct, cst, stf, doseCube, weights)` | 🟡 |

-----

## **6. Dose Calculation / Comparison**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad_calcQIndAdapted | matRad_calcQI | Compute DVH-based quality indicators | `qi = matRad_calcQI(cst, pln, doseCube)` | 🟡 |
| matRad_compareTwoDoses | matRad_cmp2Doses | Compare reference vs test dose cubes; DVH overlay, slice differences, CI metrics | `matRad_cmp2Doses(doseRef, doseTest, ct, cst, './out')` | ❌ |
| | matRad_compareTwoDoses| Compare two dose distributions visually | `[figCenter, figMaxDiff, figDVH] = matRad_compareTwoDoses(doseRef, doseTest, ct, cst)` | 🟢 |
| matRad_compareDoseDistribution | matRad_cmpDose | Comparison of two dose cubes visually | `[~, ~, hfig] = matRad_cmpDose(cube1, cube2, ct, cst)` | 🟢 |
| matRad_doseCubeExtract | matRad_doseExtract | Extract physical or RBEx dose cube from `resultGUI` | `doseCube = matRad_doseExtract(resultGUI)` | 🟢 |
| matRad_dosePerEnergyLayer | matRad_dosePerEL | Compute dose cubes per EL | `doseCubes = matRad_dosePerEL(ct,cst,stf,dij,resultGUI,threshold%)` | 🟢 |
| matRad_calcDoseCubePerEL | matRad_ELDoseCube | Compute dose cubes per energy layer using spot masks | `eLayerStruct = matRad_ELDoseCube(dij, weights, eLayerStruct)` | 🟢 |
| matRad_linearizeDose | matRad_linearDose | Flatten DIJ into sparse form, compute dose per voxel, reshape to 3D, optional plotting | `dpDose_linear = matRad_linearDose(dij, w, pln, ct, cst, 1)` | 🟢 |
|| matRad_cutDoseAxial | Set dose to zero on selected axial slices | `doseOut = matRad_cutDoseAxial(doseIn, ct, mode, zRef, zRef2)` | 🟢 |
|| matRad_cutDosePipeline |  Cut specified axial slices to zero and visualize with matRad_showAllPlanes | `[doseCut, hFig] = matRad_cutDosePipeline(doseIn, ct, cst, mode, zRef, zRef2, nSlicesTarget, planesToShow)` | 🟢 |

-----

## **7. Plotting, DVH and Visualization Tools**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad_plotCTSlice | matRad_plotCT | Plot CT slice | `matRad_plotCT(ct, slice)` | 🟡 |
| matRad_plotEnergyLayerHistogram | matRad_plotELhist | Plot number of spots per EL | `matRad_plotELhist(ax, stf)` | 🟡 |
| matRad_plotSpotsSlice | matRad_plotSpotsSlice | Plot all spots in a CT slice | `matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights, showRayTracing, useGeoSpots, sliceIdx)` | 🟢 |
| matRad_showDVHAdapted | matRad_showDVH | Show adapted DVH | `matRad_showDVH(cst, doseCube)` | 🟡 |
| matRad_showMultiDVH | matRad_showMultiDVH | Plot multiple DVHs from multiple sources | `matRad_showMultiDVH(dvhResults, cst)` | 🟡 |
| matRad_showSliceAndDVH | matRad_showSliceDVH | Display dose slice and DVH side-by-side | `[hleg, dvh] = matRad_showSliceDVH(ct, cst, doseCube)` | 🟡 |
| matRad_showSliceFast | matRad_showSliceFast | Quick slice visualization | `[slice, hleg] = matRad_showSliceF(ct, cst, doseCube, slice, doseWindow)` | 🟡 |
||matRad_showAllPlanes | Visualize CT, CST, and optionally dose in 3 planes and highlight altered slices if provided | hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesTarget, alteredSlices, plane) | 🟢 |
|| matRad_saveAllPlanes | Save all plane figures from matRad_showAllPlanes to folder | matRad_saveAllPlanes(hFig, exportFolder, resolution) | 🟢 |


-----

## **8. Spot and Energy Layer Analysis**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :----- | :--- | :--- |
| matRad_energyLayer_attachRays... | matRad_attachRays | Attach spot metadata to EL structure | `elStruct = matRad_attachRays(elStruct, stf)` | 🟢 |
| matRad_checkEnergies | matRad_chkEnergy | List unique energy layers per beam, counts and total rays | `[allE, nE, nR] = matRad_chkEnergy(stf)` | 🟢 |
| matRad_dosePerEnergyLayer | matRad_dosePerEL | Compute dose cubes per EL | `doseCubes = matRad_dosePerEL(ct,cst,stf,dij,resultGUI,threshold%)` | 🟢 |
| matRad_energyLayer_perVOIDose | matRad_dosePerVOI | Compute per-VOI dose per EL | `[voiDoseByEL, qiByEL] = matRad_dosePerVOI(cst, allELStruct, dij, w, refGy, refVol)` | 🟢 |
| matRad_EnergyLayerAnalysis | matRad_ELAnalysis | High-level pipeline: weight layers, compute per-EL dose, attach rays, per-VOI metrics, visualize | `[voiDoseByEL, qiByEL, topEL] = matRad_ELAnalysis(cst,stf,dij,ct,resultGUI,ixTarget,ixOAR)` | 🟢 |
| matRad_generateStfSSingleEn... | matRad_genStfELB | Simplify STF to single EL per spot | `[stf1EL, mb, sb] = matRad_genStfELB(ct, cst, pln)` | 🟡 |

| matRad_ELayerMergeSimilar | matRad_mergeEL | Merge adjacent/nearby energy layers into representative center layers | `merged = matRad_mergeEL(topEL, mergeRange, mergeTol)` | 🟢 |
| matRad_energyLayer_plotDosePerEL | matRad_plotDoseEL | Grid figure of per-EL doses with spots overlay | `t = matRad_plotDoseEL(ct,cst,stf,topELStruct,qiByEL,targetName)` | 🟢 |
| matRad_plotEnergyLayerPerWeight | matRad_plotELW | Plot per-weight energy layer representation | `matRad_plotELwt(ax, stf)` | 🟢 |
| matRad_plotEnergyLayerH... | matRad_plotELhist | Plot number of spots per EL | `matRad_plotELhist(ax, stf)` | 🟢 |
| matRad_plotE...CAndW | matRad_plotELhistCW | Plot histogram of counts and weights per EL | `matRad_plotELhistCW(ax, stf)` | 🟢 |
| matRad_plotE...CAndWStacked | matRad_plotELhistCWStack | Plot stacked histogram of counts and weights per EL | `matRad_plotELhistStack(ax, stf)` | 🟢 |
| matRad_plotE...StackedW | matRad_plotELhistWStack | Plot stacked histogram of weights per EL | `matRad_plotELhistSwt(ax, stf)` | 🟢 |
| matRad_plotE...H | matRad_plotELwtHist | Plot total spot weights per EL | `matRad_plotELwtHist(ax, stf, 'perBeam')` | 🟢 |
| matRad_plotGeoSpot | matRad_plotGeoSpot | Plot spot geometry visualization | `matRad_plotGeo(ct, stf, iBeam)` | 🟡 |
| matRad_plotSingleRay | matRad_plotRay | Visualize spots from specific ray index | `medianSpotCube = matRad_plotRay(ax, stf, iRayTarget, markerSize, weights, useGeoSpots)` | 🟢 |
| matRad_removeSpotsOverlappingVOIs | matRad_rmSpotsVOI | Remove spots overlapping VOIs; return retained mask & indices | `[logicalMask, removedIdx] = matRad_rmSpotsVOI(stf, ct, cst, ixVOI, iBeam)` | 🟢 |
| matRad_spotIx | matRad_spotIx | Compute global 1D index of a spot | `ix = matRad_spotIx(stf, iBeam, iRay, iSpot)` | 🟢 |
| matRad_calcSpotW... | matRad_spotWeight | Normalizes and assigns spot weights, and constructs a 3D weight matrix | `[stf, wMatrix] = matRad_calcSpotWeightsAndMatrix(stf, weights)` | 🟢 |
| matRad_analyzeSpotsPerBeam | matRad_spotsAnalyze ERROR | Visual/interactive analysis of one beam | `[doseHeavy, stats] = matRad_spotsAnalyze(iBeam, ct,cst,stf,dij,resultGUI,mode,threshold)` | 🟢 |
| matRad_computeSpotPositions_Geo | matRad_spotsPosGeo | Computes spot positions based on beam setup geometry | `stf = matRad_spotsPosSiddon(ct, stf, machine)` | 🟢 |
| matRad_computeSpotPositions_Siddon | matRad_spotsPosSiddon | Compute spot positions using Siddon algorithm | `stf = matRad_spotsPosSiddon(ct, stf, machine)` | 🟢 |
| matRad_computeSpotStats | matRad_spotsStats | Compute summary spot statistics | `stats = matRad_spotsStats(stf, w)` | 🟡 |
| matRad_analyzeSpotsPerBeamStats | matRad_spotsStatsBeam | Numeric stats per beam for filtered spots | `[doseHeavy, stats, wHeavy, mask] = matRad_spotsStatsBeam(iBeam,ct,cst,stf,dij,resultGUI,mode,threshold)` | 🟢 |
| matRad_weightEnergyLayers | matRad_weightEL | Summarize weights per EL, compute dose contribution, identify top layers | `[tSummary, top, all, locs] = matRad_wtEL(cst, stf, dij, w, oarIdx, wThresh)` | 🟢 |
| `matRad_getTopELStruct` | `matRad_getTopELStruct` | Subset top energy layers struct based on table | `topELStruct_red = matRad_getTopELStruct(voiDoseByEL, topELStruct, N)` | 🟢 |
| `matRad_getSingleEL` | `matRad_getSingleEL` | Extract single EL dose + metrics structs | `[elDoseStruct, elQiStruct] = matRad_getSingleEL(topELStruct, qiByEL, elName)` | 🟢 |
| `matRad_optSingleEL` | `matRad_optSingleEL` | Reoptimize a single EL via spot removal | `[doseELOpt, wELOpt, weightsFiltered] = matRad_optSingleEL(dij, cst, pln, wAll, elStruct)` | 🟢 |
| `matRad_getMachineE...` | `matRad_machineColorMap` | Build machine-specific EL → RGB mapping for plotting | `cmap = matRad_machineColorMap(stf)` | 🟡 |

-----

## **9. FLASH / DMF**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| matRad_restoreFLASH_detectDMF | matRad_detectFLASH | Detect likely FLASH DMF-affected voxels using dose-only heuristics (`threshold`, `valley`, `morph`) and reconstruct pre-DMF dose cube. Returns reconstructed dose, mask, and report with statistics. | `[doseFLASH, flashMask, report] = matRad_detectFLASH(doseEff, cst, ixTarget)`<br>`[doseFLASH, flashMask, report] = matRad_detectFLASH(doseEff, cst, ixTarget, 'DMF',2.0,'DoseThr',10,'Method','valley','DoPlot',true)` | 🟡 |
| matRad_evaluateFLASHBeams | matRad_evalFLASH | Evaluate multiple FLASH proton beam plans using dose metrics: PTV, FLASH target, OARs, Conformity Index (CI), and objective values. Prints a summary table. | `matRad_evalFLASH(beamSearch, cst, ptvAlias, flashAlias, oarAliases, prescribedDose)` | ❌ |
| matRad_FLASHApplyDMF | matRad_flashApplyDMF | Apply FLASH DMF to a 3D dose cube using pre-computed voxel masks or per-VOI DMF. Supports optional output summary. | `doseCubeMod = matRad_flashApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask)`<br>`doseCubeMod = matRad_flashApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask, outputTxtFile)` | ❌ |
| matRad_FLASHDMFPipeline | matRad_flashPipeline | Complete FLASH dose-modification pipeline. Applies a Dose Modifying Factor (DMF) to voxels above a threshold in selected OARs, healthy tissue, or both. Returns modified dose cube, binary masks, and optionally updates CST. | `[doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline(cst, doseCube, DMF, voiSelection, doseThreshold)`<br>`[doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline(cst, doseCube, DMF, voiSelection, doseThreshold, outputTxtFile, includeHealthyTissue, returnMasks, applyMode)` | ❌ |
| matRad_recoverFlashDose | matRad_recoverFlash | Reconstruct original FLASH dose distribution from DMF-modified dose cube. Generates dose difference map and FLASH-effect mask. Optional QC plotting included. | `[doseFLASH, doseDiff, flashMask] = matRad_recoverFlash(ct, cst, doseEff, DMF, FLASHthresh, doPlot)` | ❌ |
| matRad_recoverFlashDoseSimple | matRad_recoverFlashSimple | Threshold-based reconstruction of pre-DMF FLASH dose. Provides dose difference and voxel mask. Simple, fast version for QC purposes. | `[doseFLASH, doseDiff, flashVoxels] = matRad_recoverFlashSimple(ct, cst, doseEff, DMF, FLASHthresh, doPlot)` | ❌ |

----- 
| Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- |
| matRad_flashVoxels | prepare voxel masks and CST entries for FLASH analysis | `[flashMask, flashOARmask, cstFLASH] = matRad_flashVoxels(cst, doseCube, doseThreshold, voiSelection, includeHealthy)` | 🟢 |
| matRad_flashApplyDMF | Apply FLASH DMF to a precomputed voxel mask | `doseCubeMod = matRad_flashApplyDMF(doseCube, flashMask, DMF)` | 🟢 |
| matRad_flashLog | Print FLASH preprocessing results | `logFileName = matRad_flashLog(cstFLASH, DMF, doseThreshold, finalMask)` | 🟢 |
| matRad_flashPipeline | Full FLASH dose modification and visualization pipeline |  `[doseCubeModified, cstModified, flashMask, logFileName, hFigSlicesCenter, hFigSlicesMaxDiff, hFigDVH] = `matRad_flashPipeline(cst, doseCube, doseThreshold, DMF, voiSelection, includeHealthyTissues)`| 🟡 |
-----

## **10. Miscellaneous**

| Previous Name | Current Name | Description | Call | Status |
| :--- | :--- | :--- | :--- | :--- |
| STAR_getPatientPaths | STAR_getPatientPaths | Helper to locate STAR patient data | `[paths] = STAR_getPatientPaths(baseFolder)` | 🟢 |
| matRad_getDoseInVOI |

-----
## ** A. To be added **
