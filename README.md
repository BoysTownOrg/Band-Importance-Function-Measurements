#Band-Importance-Function-Measurements
Created by Adam Bosen, Post-Doctoral Fellow at Boys Town National Research Hospital
adam.bosen@boystown.org

Please feel free to contact me with any questions or comments on the software, and I will do my best to answer in a timely manner.  I appreciate your consideration of using this software in your own work.

This software is intended for generating and analyzing experiments to measure band importance functions in listeners with normal hearing and listeners with cochlear implants.  `SetupExperiment.m`, `RunExperiment.m`, `ProcessExperimentResultsForScoring.m`, and `AnalyzeProcessedResults.R` are the four primary scripts that serve this purpose.  Detailed documentation of how to adapt these scripts to your own needs is provided in [Band Importance Test Software Design Notes.docx](Band Importance Test Software Design Notes.docx).

NOTE: You will not be able to set up new experiments without a copy of the IEEE (aka Harvard) Sentence recordings. A copy of these recordings can be obtained freely as part of the iStar software, which can be obtained [here](http://istar.emilyfufoundation.org/istar_download.html).  Once you have the recordings, place them in the Band-Importance-Function-Measurements\Sound Files\ieee directory.  The software assumes names of the form [AW|TA][0-9]+.WAV (examples: TA01.WAV, AW720.WAV), and assumes the contents of each file match the corresponding text in [Sound Files/IEEE3_FILE_NAMES.TXT](Sound Files/IEEE3_FILE_NAMES.TXT).

This data and software are licensed as described in [LICENSE.md](LICENSE.md).
