#!/bin/csh


foreach x (C20146 C20147 C20148 C20151 C20153 C20154 C20155 C20156 C20157 C20158 C20159 C20160 C20161 C20163 C20164 C20165 C20166 C20167 C20168 C20169 C20171 C20172 C20173 C20174 C20175 C20176 C20177 C20178 C20179 C20180 C20181 C20182 C20183 C20184 C20185 C20186 C20187 C20188 C20189 C20191 C20192 C20193 C20194 C20195 C20196 C20197)

echo ${x}

set Dir=/Users/ciborg/Documents/analysis_John/${x}/

# # Reorient T1
# fslreorient2std ${Dir}T1.nii ${Dir}T1_reorient.nii.gz
# echo ${x} 'T1 reorient is finished'

# # Skull Strip with 3dSkullStrip
# 3dSkullStrip -input ${Dir}T1_reorient.nii.gz -prefix ${Dir}T1_brain.nii
# # bet ${Dir}T1_reorient.nii.gz ${Dir}T1_brain_2.nii.gz -R
# echo ${x} 'T1 skull strip is finished'

# # Bias Field Correction with BrainSuite
# bfc -i ${Dir}T1_brain.nii -o ${Dir}T1_brain_bfc.nii
# echo ${x} 'T1 Bias Field Correction is finished'


set DirIn=/Users/ciborg/Documents/analysis_John/${x}/

mkdir -p /Users/ciborg/Documents/analysis_John/${x}/T1/
set DirOut_T1 = /Users/ciborg/Documents/analysis_John/${x}/T1/

mkdir -p /Users/ciborg/Documents/analysis_John/${x}/FLAIR/
set DirOut_FLAIR = /Users/ciborg/Documents/analysis_John/${x}/FLAIR/


# # Register T1 to MNI 1mm:
# flirt -in ${DirIn}T1_brain_bfc.nii.gz -ref /Users/ciborg/Documents/MINI152_T1_1mm.nii.gz -o ${DirOut_T1}${x}_T1_1mm.nii.gz -omat ${DirOut_T1}${x}_T1_std1.mat

# # fnirt --in=${DirIn}T1_brain_bfc.nii.gz --ref=/Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz --aff=${DirOut_T1}${x}_T1_std1.mat --cout=${DirOut_T1}${x}_def1mm.nii.gz --iout=${DirOut_T1}${x}_T1_1mm.nii.gz
# echo ${x} 'T1 registration (1mm) is finished'



# # Reorient FLAIR
# fslreorient2std ${DirIn}FLAIR.nii.gz ${DirIn}FLAIR_reorient.nii.gz

# Register FLAIR to MNI152 space
flirt -in ${DirIn}FLAIR_reorient.nii.gz -ref ${DirIn}T1_brain_bfc.nii -o ${DirOut_FLAIR}${x}_FLAIR_T1.nii.gz
flirt -in ${DirOut_FLAIR}${x}_FLAIR_T1.nii.gz -ref /Users/ciborg/Documents/MINI152_T1_1mm.nii.gz -applyxfm -init ${DirOut_T1}${x}_T1_std1.mat -o ${DirOut_FLAIR}${x}_FLAIR_MNI.nii.gz

# convertwarp -r /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -w ${DirOut_T1}${x}_def1mm.nii.gz --premat=${DirOut_FLAIR}${x}_FLAIR_T1.mat -o ${DirOut_FLAIR}${x}_FLAIR_warp.nii.gz

# applywarp -r /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -i ${DirIn}FLAIR_reorient.nii.gz -w ${DirOut_FLAIR}${x}_FLAIR_warp.nii.gz --rel -o ${DirOut_FLAIR}${x}_FLAIR_final.nii.gz

# echo ${x} 'FLAIR registration is finished'
end
