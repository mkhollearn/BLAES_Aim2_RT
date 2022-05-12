mydata <- read.csv("~/Desktop/INMAN LAB/BLAES/Data/Utah/UIC202205_Test_Data_imageset1all.csv", stringsAsFactors=TRUE)
View(mydata)

########## Descriptive stats of RT #####################
patient = "UIC202205"
hist(mydata$RT, xlab = "RT (sec)", main = "Histogram of UIC202205 RT")
boxplot(mydata$RT, ylab = "RT (sec)")

library(pastecs)
descriptives<- stat.desc(mydata$RT)
sd<- descriptives['std.dev']

######### Outlier check in RT ################################
descriptives['mean'] + 3*sd # 3SD upper boundary of RT
descriptives['mean'] - 3*sd # 3SD lower boundary of RT 

out<- boxplot.stats(mydata$RT)$out # gives the outliers based on interquartile range (IQR) criterion
#for patient UIC202205 this gives 8 data points
out_indx<- which(mydata$RT %in% c(out))
boxplot(mydata$RT,
        ylab = "RT (sec)",
        main = "Boxplot of UIC202205"
)
mtext(paste("Outliers: ",paste(out_indx, collapse = ", ")))


install.packages("plyr")
library(plyr)
count(mydata$RT > descriptives['mean'] + 3*sd) #checking number of extreme values - TRUE
#for patient UIC202205 this gives 3 values
which(mydata$RT > descriptives["mean"] + 3*sd) # shows which trials were extreme

###Dummy coding variables ####
count(mydata$Response)
count(mydata$Confidence)
count(mydata$Resp.Condition)

response<- ifelse(mydata$Response == "old", 0, 1)
count(response)
confidence<- ifelse(mydata$Confidence == "sure", 0, 1)
count(confidence)
#hist(confidence)

cond_resp<- ifelse(mydata$Resp.Condition == "old", 0, 1)
count(cond_resp)


## Accuracy calculation #####

for (i in 1:length(cond_resp)) {
  if (cond_resp[i] == response[i]) {
    accuracy[i]<- "Correct"
  }else{
    accuracy[i]<- "Incorrect"
  }
}
print(accuracy)
mydata<- cbind(mydata,accuracy) #add accuracy as a column to existing dataframe
count(accuracy)
accuracy_d<- ifelse(accuracy == "Incorrect", 0, 1)

### Regression analyses #####

#MODEL1: Can accuracy and confidence predict RT?
rt<- mydata$RT
model1<- lm(rt ~ confidence + accuracy_d, data = mydata)
summary(model1)
slope_confidence<- model1$coefficients[2] #grabs B for confidence

#plot regression slope for confidence
library(ggplot2)
ggplot(mydata,aes(x = rt, y = confidence))+geom_point()+stat_smooth(method="lm",se=F)+annotate("text",x=.75,y=.75,label=(paste("slope==",slope_confidence)),parse=TRUE)


#MODEL2: Can stimulation and confidence increase RT?
stim_d<- mydata$Stimulation..0...no..1...yes.
model2<- lm(rt ~ stim_d, data = mydata)
summary(model2)
ggplot(mydata,aes(x = rt, y = stim_d))+geom_point()+stat_smooth(method="lm",se=F)+annotate("text",x=.75,y=.75,label=(paste("slope==",model2$coefficients[2])),parse=TRUE)

#MODEL#: interaction b/w stim and confidence on RT
model3<- lm(rt ~ stim_d*confidence, data = mydata)
summary(model3)

#visualize interaction
#convert stim into nominal data
for (i in 1:length(stim)) {
  if (stim_d[i] == 1) {
    stim[i]<- "Stim"
  }else{
    stim[i]<- "No Stim"
  }
}
#plot interaction slopes
library(dplyr)
qplot(x = rt, y = confidence, data = mydata, color = stim) +
  geom_smooth(method = "lm")

#MODEL4 and 5: Stim effect on confidence
model4<- lm(confidence ~ stim_d, data = mydata)#should use GLM!
summary(model4)
#ggplot(mydata,aes(x = confidence, y = stim_d))+geom_point()+stat_smooth(method="lm",se=F)+annotate("text",x=.75,y=.75,label=(paste("slope==",model4$coefficients[2])),parse=TRUE)

exp(summary(model4)$coeff[2,1]) #calc odds ratio for 

#recode the baseline to get the other value for confidence
confidence_recoded<- ifelse(mydata$Confidence == "not_sure", 0, 1)
model5<- lm(confidence_recoded~stim_d, data = mydata)
summary(model5)
#ggplot(mydata,aes(x = confidence_recoded, y = stim_d))+geom_point()+stat_smooth(method="lm",se=F)+annotate("text",x=.75,y=.75,label=(paste("slope==",model5$coefficients[2])),parse=TRUE)

#MODEL6: Can novelty predict RT? Novelty meaning it's old or new
model6<- lm(rt ~ response, data = mydata)
summary(model6)

#MODEL7: Can stimulus identity be predicted by RT, accuracy, and confidence?
identity<- mydata$Identity
identity_d<- ifelse(identity == "scene",0,1) #collapse object conditions into one object cond

model7<- lm(identity_d ~ accuracy_d + rt + confidence, data = mydata)#should use GLM!
summary(model7)

#model<- lm(RT ~ accuracy_d*identity_d, data = mydata)#should use GLM!
#summary(model)

#model<- lm(identity_d ~ rt, data = mydata)    #checking RT and identity
#summary(model)

#MODEL8: Can stimulation change accuracy for objects? (interaction)
model8<- lm(accuracy_d ~ stim_d +identity_d, data = mydata)#should use GLM!
summary(model8)
qplot(x = accuracy_recoded, y = identity_d, data = mydata, color = stim) +
  geom_smooth(method = "lm")

#recode baseline for accuracy
accuracy_recoded<- ifelse(accuracy == "Correct", 0, 1) #correct resp is 0
model9<- lm(accuracy_recoded ~ stim_d +identity_d, data = mydata)#should use GLM!
summary(model9)
ggplot(mydata,aes(x = accuracy_recoded, y = stim_d))+geom_point()+stat_smooth(method="lm",se=F)+annotate("text",x=.75,y=.75,label=(paste("slope==",model9$coefficients[2])),parse=TRUE)
ggplot(mydata,aes(x = accuracy_recoded, y = identity_d))+geom_point()+stat_smooth(method="lm",se=F)+annotate("text",x=.75,y=.75,label=(paste("slope==",model9$coefficients[3])),parse=TRUE)


