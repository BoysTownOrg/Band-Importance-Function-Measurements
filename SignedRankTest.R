require(xlsx)
data = read.xlsx(".\\Processed Results\\Group Intelligibility Metrics.xlsx",1,startRow=2,endRow=25)

print("")
print("Rectangular vs Monopolar Baseline test:")
print(wilcox.test(data$Baseline.Intelligibility[seq(1,5)],data$Baseline.Intelligibility[seq(6,10)],paired=FALSE))

print("")
print("Rectangular vs Monopolar Experiment test:")
print(wilcox.test(data$Experiment.Intelligibility[seq(1,5)],data$Experiment.Intelligibility[seq(6,10)],paired=FALSE))

print("")
print("Normal hearing baseline talker gender test:")
print(wilcox.test(data$Male.Talker[seq(1,10)],data$Female.Talker[seq(1,10)],paired=TRUE))

print("")
print("Normal hearing experiment talker gender test:")
print(wilcox.test(data$Male.Talker.1[seq(1,10)],data$Female.Talker.1[seq(1,10)],paired=TRUE))

print("")
print("Cochlear Implant baseline talker gender test:")
print(wilcox.test(data$Male.Talker[seq(12,23)],data$Female.Talker[seq(12,23)],paired=TRUE))

print("")
print("Cochlear Implant baseline talker gender test:")
print(wilcox.test(data$Male.Talker.1[seq(12,23)],data$Female.Talker.1[seq(12,23)],paired=TRUE))
