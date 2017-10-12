#!/bin/csh

echo "WMH positive patients"
foreach x (C20146 C20148 C20154 C20155 C20156 C20157 C20158 C20159 C20161 C20163 C20164 C20165 C20166 C20167 C20171 C20172 C20174 C20176 C20177 C20181 C20182 C20184 C20186 C20187 C20188 C20189 C20192 C20194 C20195 C20197)
# foreach x (C20146)

echo ${x}

set DirIn = /Users/ciborg/Documents/analysis_John/${x}/
set DirOut = /Users/ciborg/Documents/analysis_John/${x}/WMH/
ls ${DirOut}FLAIR_deep.nii.gz
cp ${DirOut}FLAIR_deep.nii.gz /Users/ciborg/Documents/WMH_deep/${x}_FLAIR_deep.nii.gz

# fslmaths ${DirIn}FAST/T1_MNI/${x}_FAST_prob_GM_MNI.nii.gz -thr 0.6 ${DirOut}GM_mask.nii.gz
# fslmaths ${DirOut}GM_mask.nii.gz -bin ${DirOut}GM_mask.nii.gz

# fslmaths ${DirIn}FAST/T1_MNI/${x}_FAST_prob_WM_MNI.nii.gz -thr 0.6 ${DirOut}WM_mask.nii.gz
# fslmaths ${DirOut}WM_mask.nii.gz -bin ${DirOut}WM_mask.nii.gz

end