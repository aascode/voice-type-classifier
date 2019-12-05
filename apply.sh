#!/usr/bin/env bash
THISDIR="$( cd "$( dirname "$0" )" && pwd )"

declare -a classes=(KCHI CHI MAL FEM SPEECH)

if [ $# -ge 2 ]; then
    declare -a classes=() # empty array
    list=$@
    declare -a classes=${list[@]:1} # get the classes provided by the user
fi;

if [ "$(ls -A $1/*.wav)" ]; then
    echo "Found wav files."

    echo "Creating config for pyannote."
    # Create pyannote_tmp_config containing all the necessary files
    rm -rf pyannote_tmp_config
    mkdir pyannote_tmp_config

    # Create database.yml
    echo "Databases:
    MySet: $1/{uri}.wav

Protocols:
  MySet:
    SpeakerDiarization:
      All:
        test:
          annotated: $THISDIR/pyannote_tmp_config/my_set.uem" >> $THISDIR/pyannote_tmp_config/database.yml

    # Create .uem file
    for audio in $1/*.wav; do
        duration=$(soxi -D $audio)
        echo "$(basename ${audio/.wav/}) 1 0.0 $duration"
    done >> $THISDIR/pyannote_tmp_config/my_set.uem
    echo "Done creating config for pyannote."

    export PYANNOTE_DATABASE_CONFIG=pyannote_tmp_config/database.yml
    pyannote-multilabel apply --subset=test --gpu model/train/BBT_emp.SpeakerDiarization.All.train/validate_FEM/BBT_emp.SpeakerDiarization.All.development MySet.SpeakerDiarization.All
else
    echo "The folder you provided doesn't contain any wav files."
fi;