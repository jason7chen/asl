#!/bin/csh


foreach x (C20146 C20147 C20148 C20151 C20153 C20154 C20155 C20156 C20157 C20158 C20159 C20160 C20161 C20163 C20164 C20165 C20166 C20167 C20168 C20169 C20171 C20172 C20173 C20174 C20175 C20176 C20177 C20178 C20179 C20180 C20181 C20182 C20183 C20184 C20185 C20186 C20187 C20188 C20189 C20191 C20192 C20193 C20194 C20195 C20196 C20197)

echo ${x}

# Segmenting T1 into CSF/GM/WM
set DirIn=/Volumes/data2/Jason_ASL/analysis_John/${x}/

mkdir -p /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1/
set DirOut_T1 = /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1/

fast -N -p -o ${DirOut_T1}${x}_FAST ${DirIn}T1_brain_bfc.nii.gz
echo ${x} 'T1 FAST is completed'


# Register probability map into ASL space
set DirIn = /Volumes/data2/Jason_ASL/analysis_John/${x}/

mkdir -p /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1_ASL/
set DirOut = /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1_ASL/

flirt -in ${DirIn}ASL_1/ASL4D.nii -ref ${DirIn}T1_brain_bfc.nii -o ${DirOut}ASL_to_T1.nii.gz -omat ${DirOut}ASL_to_T1.mat
convert_xfm -omat ${DirOut}inverse.mat -inverse ${DirOut}ASL_to_T1.mat

set DirIn_prob = /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1/
flirt -in ${DirIn_prob}${x}_FAST_prob_0.nii.gz -ref ${DirIn}ASL_1/ASL4D.nii -applyxfm -init ${DirOut}inverse.mat -out ${DirOut}${x}_FAST_prob_CSF_ASL.nii.gz
flirt -in ${DirIn_prob}${x}_FAST_prob_1.nii.gz -ref ${DirIn}ASL_1/ASL4D.nii -applyxfm -init ${DirOut}inverse.mat -out ${DirOut}${x}_FAST_prob_GM_ASL.nii.gz
flirt -in ${DirIn_prob}${x}_FAST_prob_2.nii.gz -ref ${DirIn}ASL_1/ASL4D.nii -applyxfm -init ${DirOut}inverse.mat -out ${DirOut}${x}_FAST_prob_WM_ASL.nii.gz

echo ${x} 'Probability Maps are registered to ASL space'

# set DirIn = /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1/

# mkdir -p /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1_MNI/
# set DirOut = /Volumes/data2/Jason_ASL/analysis_John/${x}/FAST/T1_MNI/

# # Register probability map to MNI 1mm space:

# set DirIn_T1 = /Volumes/data2/Jason_ASL/analysis_John/${x}/T1/
# applywarp -r /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -i ${DirIn}${x}_FAST_prob_0.nii.gz -w ${DirIn_T1}${x}_def1mm.nii.gz -o ${DirOut}${x}_FAST_prob_CSF_MNI.nii.gz
# applywarp -r /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -i ${DirIn}${x}_FAST_prob_1.nii.gz -w ${DirIn_T1}${x}_def1mm.nii.gz -o ${DirOut}${x}_FAST_prob_GM_MNI.nii.gz
# applywarp -r /Volumes/data2/YaqiongASL_output/StandardMNI/MNI152_T1_1mm.nii.gz -i ${DirIn}${x}_FAST_prob_2.nii.gz -w ${DirIn_T1}${x}_def1mm.nii.gz -o ${DirOut}${x}_FAST_prob_WM_MNI.nii.gz

# echo ${x} 'Probability Maps are registered to MNI space'

end