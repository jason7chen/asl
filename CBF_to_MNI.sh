#!/bin/csh


foreach x (C20146 C20147 C20148 C20151 C20153 C20154 C20155 C20156 C20157 C20158 C20159 C20160 C20161 C20163 C20164 C20165 C20166 C20167 C20168 C20169 C20171 C20172 C20173 C20174 C20175 C20176 C20177 C20178 C20179 C20180 C20181 C20182 C20183 C20184 C20185 C20186 C20187 C20188 C20189 C20191 C20192 C20193 C20194 C20195 C20196 C20197)

echo ${x}

set DirIn = /Users/ciborg/Documents/analysis_John/${x}/
set DirOut = /Users/ciborg/Documents/analysis_John/${x}/ASL_1/

# # one compartment model
# flirt -in ${DirIn}/ASL_1/PVC/CBF_PVC.nii.gz -ref ${DirIn}T1_brain_bfc.nii -applyxfm -init ${DirIn}/FAST/T1_ASL/ASL_to_T1.mat -out ${DirOut}CBF_T1.nii.gz
# flirt -in ${DirOut}CBF_T1.nii.gz -ref /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -applyxfm -init ${DirIn}T1/${x}_T1_std1.mat -out ${DirOut}CBF_MNI.nii.gz

# # two compartment model
flirt -in ${DirIn}/ASL_1/two_comp/CBF.nii.gz -ref ${DirIn}T1_brain_bfc.nii -applyxfm -init ${DirIn}/FAST/T1_ASL/ASL_to_T1.mat -out ${DirIn}/ASL_1/two_comp/CBF_T1.nii.gz
flirt -in ${DirIn}/ASL_1/two_comp/CBF_T1.nii.gz -ref /Users/ciborg/Documents/MINI152_T1_1mm.nii.gz -applyxfm -init ${DirIn}T1/${x}_T1_std1.mat -out ${DirIn}/ASL_1/two_comp/CBF_MNI.nii.gz
fslmaths ${DirIn}/ASL_1/two_comp/CBF_MNI.nii.gz -mul ${DirIn}FAST/T1_MNI/CSF_mask.nii.gz ${DirIn}/ASL_1/two_comp/CBF_MNI_noCSF.nii.gz

# flirt -in ${DirIn}/ASL_1/two_comp/CBF_WM.nii.gz -ref ${DirIn}T1_brain_bfc.nii -applyxfm -init ${DirIn}/FAST/T1_ASL/ASL_to_T1.mat -out ${DirIn}/ASL_1/two_comp/CBF_WM_T1.nii.gz
# flirt -in ${DirIn}/ASL_1/two_comp/CBF_WM_T1.nii.gz -ref /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -applyxfm -init ${DirIn}T1/${x}_T1_std1.mat -out ${DirIn}/ASL_1/two_comp/CBF_WM_MNI.nii.gz

# flirt -in ${DirIn}/ASL_1/two_comp/CBF_GM.nii.gz -ref ${DirIn}T1_brain_bfc.nii -applyxfm -init ${DirIn}/FAST/T1_ASL/ASL_to_T1.mat -out ${DirIn}/ASL_1/two_comp/CBF_GM_T1.nii.gz
# flirt -in ${DirIn}/ASL_1/two_comp/CBF_GM_T1.nii.gz -ref /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -applyxfm -init ${DirIn}T1/${x}_T1_std1.mat -out ${DirIn}/ASL_1/two_comp/CBF_GM_MNI.nii.gz

echo ${x} 'CBF to MNI registration is finished'
end
