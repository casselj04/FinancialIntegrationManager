public with sharing class FinancialIntegrationManager {
/*
//-------------------------US BANK SECTION
*/
    //Get the custom settings/types help tesxt etc.
    @AuraEnabled(cacheable=true)
    public static Map<String, FieldInfo> getUSBankConfigurationSettings() {
        Map<String, FieldInfo> result = new Map<String, FieldInfo>();
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();
        Schema.DescribeSObjectResult describeResult = TSGCFG__US_Bank_Configuration__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();

        for (String fieldName : fields.keySet()) {
            Schema.DescribeFieldResult fDesc = fields.get(fieldName).getDescribe();
            FieldInfo fi = new FieldInfo();
            fi.fieldApiName = fieldName;
            fi.label = fDesc.getLabel();
            fi.helpText = fDesc.getInlineHelpText()!= null?fDesc.getInlineHelpText():'';
            fi.value = (config != null && config.get(fieldName) != null) ? String.valueOf(config.get(fieldName)) : '';
            fi.dataType = fDesc.getType().name();
            result.put(fieldName, fi);
        }
        return result;
    }   
    @AuraEnabled
    public static String UpdateUSBankConfigurationSettings(Map<String, String> updatedFields) {
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new TSGCFG__US_Bank_Configuration__c();
        }

        for (String key : updatedFields.keySet()) {
            config.put(key, updatedFields.get(key));
        }
        try{
            upsert config;
            return 'Succesfully Updated Settings';
        }catch (exception e){
            return 'An Error Occurred: ' + e.getMessage();
        }
    }
    @AuraEnabled
    public static String ScheduleUSBankForMin(String selectedValue){
        String message ='';
        try{
           
            for(CronTrigger job:[SELECT Id,CronJobDetail.Name FROM CronTrigger where CronJobDetail.Name LIKE 'USBank Status Sync%'])
            {
                System.abortJob(job.id);
                message = 'Previous Job(s) removed. New ';
            }
            
            if(selectedValue=='10'){                   
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 10 Min', '0 10 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 20 Min', '0 20 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 30 Min', '0 30 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 40 Min', '0 40 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 50 Min', '0 50 * * * ?', new BatchToUpdateUSBankStatus()); 
                message += 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='20'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 20 Min', '0 20 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 40 Min', '0 40 * * * ?', new BatchToUpdateUSBankStatus());
                message += 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='30'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 30 Min', '0 30 * * * ?', new BatchToUpdateUSBankStatus());
                message += 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='40'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 40 Min', '0 40 * * * ?', new BatchToUpdateUSBankStatus());
                message += 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='50'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 50 Min', '0 50 * * * ?', new BatchToUpdateUSBankStatus());
                message += 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue =='60'){
                string CRON_EXP = '0 0 * * * ?'; //'0 0 0/1 1/1 * ? *';
                system.schedule('USBank Status Sync' , CRON_EXP , new BatchToUpdateUSBankStatus());
                message += 'US Bank scheduler is running for every 1 Hour.';
            }
            
            
        }catch(Exception e){
            message = 'Error: '+e.getMessage()+', at line '+e.getLineNumber();
        }
        return message;       
        
    }
    @AuraEnabled
    public static Void killUSBankStatusScheduled(){
        try {
            for(CronTrigger job:[SELECT Id,CronJobDetail.Name FROM CronTrigger where CronJobDetail.Name LIKE 'USBank Status Sync%'])
            {
                System.abortJob(job.id);
               
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static list<string> getSchedules(){
        try {
            List<String> Schedules = new List<string>();

            return Schedules;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class FieldInfo {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String helpText;
        @AuraEnabled public String dataType;
    }
    /*
//-------------------------US BANK SECTION END
*/
}