#!/bin/csh


foreach x (C20146 C20147 C20148 C20151 C20153 C20154 C20155 C20156 C20157 C20158 C20159 C20160 C20161 C20163 C20164 C20165 C20166 C20167 C20168 C20169 C20171 C20172 C20173 C20174 C20175 C20176 C20177 C20178 C20179 C20180 C20181 C20182 C20183 C20184 C20185 C20186 C20187 C20188 C20189 C20191 C20192 C20193 C20194 C20195 C20196 C20197)
# foreach x (C20146)
echo ${x}

set DirIn = /Volumes/data2/Jason_ASL/analysis_John/${x}/ASL_1/

mkdir -p /Volumes/data2/Jason_ASL/analysis_John/${x}/ASL_1/Time/
set DirOut = /Volumes/data2/Jason_ASL/analysis_John/${x}/ASL_1/Time/

# Motion Correction
mcflirt -in ${DirIn}ASL4D.nii -o ${DirIn}ASL4D_mcf.nii
echo ${x} 'Motion Correction is finished'

# Split ASL4D into 3D data along time
fslsplit ${DirIn}ASL4D_mcf.nii ${DirOut}ASL3D -t
echo ${x} 'Splitting is finished'

# Generate mask for brain extraction
bet ${DirIn}ASL4D_mcf.nii ${DirIn}ASL4D_mcf_brain.nii -m

	# Apply mask on all Control/Label images
	foreach y (00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39)
	fslmaths ${DirOut}ASL3D00${y}.nii.gz -mas ${DirIn}ASL4D_mcf_brain_mask.nii ${DirOut}ASL3D00${y}.nii.gz
	end
	echo ${x}

# Merge Images in time for both Controlled and Labeled Images (Optional)
fslmerge -t ${DirIn}ASL4D_control.nii ${DirOut}ASL3D0000.nii.gz ${DirOut}ASL3D0002.nii.gz ${DirOut}ASL3D0004.nii.gz ${DirOut}ASL3D0006.nii.gz ${DirOut}ASL3D0008.nii.gz ${DirOut}ASL3D0010.nii.gz ${DirOut}ASL3D0012.nii.gz ${DirOut}ASL3D0014.nii.gz ${DirOut}ASL3D0016.nii.gz ${DirOut}ASL3D0018.nii.gz ${DirOut}ASL3D0020.nii.gz ${DirOut}ASL3D0022.nii.gz ${DirOut}ASL3D0024.nii.gz ${DirOut}ASL3D0026.nii.gz ${DirOut}ASL3D0028.nii.gz ${DirOut}ASL3D0030.nii.gz ${DirOut}ASL3D0032.nii.gz ${DirOut}ASL3D0034.nii.gz ${DirOut}ASL3D0036.nii.gz ${DirOut}ASL3D0038.nii.gz

fslmerge -t ${DirIn}ASL4D_label.nii ${DirOut}ASL3D0001.nii.gz ${DirOut}ASL3D0003.nii.gz ${DirOut}ASL3D0005.nii.gz ${DirOut}ASL3D0007.nii.gz ${DirOut}ASL3D0009.nii.gz ${DirOut}ASL3D0011.nii.gz ${DirOut}ASL3D0013.nii.gz ${DirOut}ASL3D0015.nii.gz ${DirOut}ASL3D0017.nii.gz ${DirOut}ASL3D0019.nii.gz ${DirOut}ASL3D0021.nii.gz ${DirOut}ASL3D0023.nii.gz ${DirOut}ASL3D0025.nii.gz ${DirOut}ASL3D0027.nii.gz ${DirOut}ASL3D0029.nii.gz ${DirOut}ASL3D0031.nii.gz ${DirOut}ASL3D0033.nii.gz ${DirOut}ASL3D0035.nii.gz ${DirOut}ASL3D0037.nii.gz ${DirOut}ASL3D0039.nii.gz
echo ${x} 'Control/Label merging is finished'

# Calculate Mean (Optional)
fslmaths ${DirIn}ASL4D_control.nii -Tmean ${DirIn}ASL4D_control_mean.nii
fslmaths ${DirIn}ASL4D_label.nii -Tmean ${DirIn}ASL4D_label_mean.nii


end
