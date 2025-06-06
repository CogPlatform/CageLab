#!/usr/bin/env zsh
# This script builds the software package from source.

mcc -a ~/Code/Psychtoolbox-3/Psychtoolbox/PsychBasic/PsychPlugins/ \
-a ~/Code/Psychtoolbox-3/Psychtoolbox/PsychOpenGL/MOGL/core \
-a ~/Code/Psychtoolbox-3/Psychtoolbox/PsychOpenGL/PsychGLSLShaders \
-a ~/Code/opticka/communication \
-a ~/Code/opticka/tools \
-a ~/Code/opticka/stimuli \
-a ~/Code/opticka/stimuli/lib \
-a ~/Code/opticka/ui/images \
-a ~/Code/opticka/help \
-a ~/Code/matlab-jzmq/ \
-a ~/Code/PTBSimia/ \
-a ~/Code/CageLab/software \
-a ~/Code/CageLab/software/+clutil \
-a ~/Code/CageLab/software/+cltasks \
-a ~/Code/CageLab/software/ui \
-R -startmsg,'Runtime Init START' \
-R -completemsg,'Runime Init FINISH' \
-d ~/build \
-m ~/Code/CageLab/software/runCageLab.m