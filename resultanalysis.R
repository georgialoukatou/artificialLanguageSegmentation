library(dplyr) 
library(ggplot2)
library(ggpubr)
library(plyr)
library(beanplot)
library(tidyr)
library(lme4)

pilot_long<-read.csv("/Users/admin/Documents/datafiles/pilot2/totalfull1.csv")
#pilot_long<-read.csv("/Users/admin/Documents/datafiles/pilot1/pilot_results1.csv") #no spaces for this one

pilot_long_log<-subset(pilot_long, select=c(thisResp, numberoftrial, Nsyll, question, uniqueid, group)) 
pilot_long_log$numberoftrial<- as.numeric(pilot_long_log$numberoftrial)
pilot_long_log$thisResp<- factor(pilot_long_log$thisResp)
pilot_long_log$Nsyll<- as.factor(pilot_long_log$Nsyll)

pilot_long_log$thisresplog <- NA
pilot_long_log$thisresplog[pilot_long_log$thisResp==' correct'] <- "1"
pilot_long_log$thisresplog[pilot_long_log$thisResp==' wrong'] <- "0"
pilot_long_log$thisresplog<- as.factor(pilot_long_log$thisresplog)


###Logistic regression 
pilot_long_log$level <- NA
pilot_long_log$level[pilot_long_log$question==' verb_word'] <- "word"
pilot_long_log$level[pilot_long_log$question==' verb_stem'] <- "stem"
pilot_long_log$level[pilot_long_log$question==' noun_stem'] <- "stem"
pilot_long_log$level[pilot_long_log$question==' noun_word'] <- "word"
pilot_long_log$type <- NA
pilot_long_log$type[pilot_long_log$question==' verb_word'] <- "verb"
pilot_long_log$type[pilot_long_log$question==' verb_stem'] <- "verb"
pilot_long_log$type[pilot_long_log$question==' noun_stem'] <- "noun"
pilot_long_log$type[pilot_long_log$question==' noun_word'] <- "noun"

#pilot_long_log$type<- factor(pilot_long_log$type)
#pilot_long_log$level<- factor(pilot_long_log$level)


model<-glmer(formula= thisresplog ~   level + numberoftrial +(1 + level + numberoftrial|uniqueid),  control = glmerControl(optimizer = "bobyqa"), family = binomial(link = "logit"),  data = pilot_long_log)

##add percentage correct column
pilot_short<-subset(pilot_long_log, select=c(uniqueid, thisResp, level ))
pilot_short1<-subset(pilot_long_log, select=c(uniqueid, level ))
pilot_group<-subset(pilot_long_log, select=c(uniqueid, group ))

pilot_count1 <- pilot_short1 %>%  group_by(uniqueid, level) %>%  count() 
colnames(pilot_count1)[3] <- "total"
pilot_count <- pilot_short %>%  group_by(uniqueid, level, thisResp) %>%  count() 

df<-merge(x=pilot_count1,y=pilot_count,by=c("uniqueid", "level"),all=TRUE)
pilot_perc1<-subset(df, thisResp == "correct") 
pilot_<- transform(pilot_perc1, percentage = n / total)
pilot<-unique(merge(x=pilot_,y=pilot_group,by=c("uniqueid"),all=TRUE))


####################### T-tests Nouns vs Verbs

pilot_nouns<-subset(pilot, question == 'noun_stem'| question == 'noun_word', select=c(question, percentage, group, uniqueid)) 
pilot_verbs<-subset(pilot, question == 'verb_stem'| question == 'verb_word', select=c(question, percentage, group, uniqueid)) 
#group_by(pilot_nouns, question) %>%summarise(count = n(),mean = mean(percentage, na.rm = TRUE),sd = sd(percentage, na.rm = TRUE))


dn <- with(pilot_nouns, percentage[question == "noun_word"] - percentage[question == "noun_stem"])
dv <- with(pilot_verbs, percentage[question == "verb_word"] - percentage[question == "verb_stem"])
shapiro.test(dn) 
shapiro.test(dv) 


resn <- t.test(percentage ~ question, data = pilot_nouns, paired = TRUE)
resv <- t.test(percentage ~ question, data = pilot_verbs, paired = TRUE)
resn
resv

res_fc <- t.test(pilot_nouns$percentage, pilot_verbs$percentage, paired = TRUE)
res_fc

#####

ggplot(pilot, aes(x=question, y=percentage, group=factor(question)))  + geom_boxplot()+ ylab("Percentage correct")# to add


###Number of trials
df2_ <- pilot_long_log %>%  group_by(numberoftrial, thisResp) %>%  tally()  
df2_<-subset(df2_, thisResp ==  " 'correct'"  )
df2_$numberoftrial<- factor(df2_$numberoftrial)
p<-ggplot(df2_, aes(numberoftrial, n)) + geom_bar(stat = "identity")  + ylab("Percentage correct")# to add
p


###Number of syllables
df3 <- pilot_long_log %>%   group_by(Nsyll, thisResp) %>%  tally() 
p<-ggplot(df3, aes(Nsyll, n, fill=factor(thisResp))) + geom_bar(stat = "identity")# to add
p<-p + scale_fill_discrete(name = "Response", labels = c("correct", "wrong")) +scale_fill_manual(values = c("#00AFBB", "#E7B800"))
p

########## T-tests 
pilot_words<-subset(pilot, level == 'word', select=c(level, percentage, group, uniqueid)) 
pilot_stems<-subset(pilot, level == 'stem', select=c(level, percentage, group, uniqueid)) 

#pilot_stems<-subset(pilot, question == ' verb_stem'| question == ' noun_stem', select=c(question, percentage, group, uniqueid)) 

summary(pilot_words)
shapiro.test(pilot_words$percentage) 
resw <- t.test(pilot_words$percentage, mu=0.50,  alternative = "greater")
resw

shapiro.test(pilot_stems$percentage) 
ress <- t.test(pilot_stems$percentage, mu=0.50,  alternative = "greater")
ress

res_f <- t.test(pilot_words$percentage, pilot_stems$percentage, paired = TRUE)
res_f




