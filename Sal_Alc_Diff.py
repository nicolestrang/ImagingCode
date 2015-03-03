#!/usr/bin/python
import sys
import os
from datetime import datetime

# Path Definitions
RootPath=('/imaging/scratch/Hendershot/chendershot/data/analysis/' +
        'cihr_infusion')

# Function for getting a list of subdirectories
def get_subdirectories(a_dir):
    return [name for name in os.listdir(a_dir)
            if os.path.isdir(os.path.join(a_dir, name))]

#Alchol Participant Set
AlcoholFirst=set(['1017','1038','1052','1074','1097','1139','1140','1154','1156','1183','1181','1189',
                  '1197','1203','1186','1200','1195','1212','1031','1216','1219'])

#Saline Participant Set                 
SalineFirst=set(['1034','1048','1049','1065','1081','1087','1100','1115','1147','1168','1176',
                 '1177','1187','1175','1182','1208','1109','1163','1086','1211','1221','1224'])

#ConditionsDictionary
Conditions={'cope1':'Breath', 'cope2':'Tone', 'cope3':'Breath_Tone'}

# Import SubList or use Single Subject as SubList
if '.txt'  in sys.argv[1]:
    SubList =[]
    with open(sys.argv[1], 'r') as f:
            for line in f:
                SubList.append(line)
    f.close()
    print(SubList)
else:
    SubList =[]
    SubList.append(sys.argv[1])
# Loop though all subjects in List
for sub in SubList:
    sub=sub.strip()
    SubPath=(RootPath + '/subjects/' + sub)

    # Read in Dates for Subject
    dates=get_subdirectories(SubPath)
    
    # Remove non dates from list
    dates=[x for x in dates if "20" in x]
    scanA=datetime.strptime(dates[0],"%Y%m%d")
    scanB=datetime.strptime(dates[1],"%Y%m%d")

    #Figure out which date is first
    if scanA < scanB:
        scan1=scanA.strftime('%Y%m%d')
        scan2=scanB.strftime('%Y%m%d')
    else:
        scan1=scanB.strftime('%Y%m%d')
        scan2=scanA.strftime('%Y%m%d')

    #Based on Lists assign dates to Alcohol and Saline sessions
    if sub in AlcoholFirst:
        alc_scan=scan1
        sal_scan=scan2
    else:
        alc_scan=scan2
        sal_scan=scan1

    #Make a directory for Alcohol_Saline Differences
    if not os.path.exists(SubPath + '/Saline_Alcohol'):
        os.makedirs(SubPath + '/Saline_Alcohol')

    #Use template design and set up for subject and contrast
    #Loop though all constratsts in Contrats List
    for c, c_name in Conditions.items():
        
        f=open(RootPath + '/models/Saline_Alcohol.fsf')
        template=f.read()
        f.close

        newdata=template.replace('curr_sub', sub)
        newdata=newdata.replace('SalineDate', sal_scan)
        newdata=newdata.replace('AlcoholDate', alc_scan)
        newdata=newdata.replace('cond', c)
        newdata=newdata.replace('Name', c_name)

        print(SubPath + '/Saline_Alcohol/' + c_name + '.fsf')
        f=open(SubPath + '/Saline_Alcohol/' + c_name + '.fsf', 'w')
        f.write(newdata)
        f.close()

        #Use fsl to run design matrix
        command=('feat ' + SubPath + '/Saline_Alcohol/' + c_name + '.fsf')
        print(command)
        os.system(command)


        #Delete design matrices no in folder
