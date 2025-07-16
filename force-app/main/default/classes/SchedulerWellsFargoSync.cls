global class SchedulerWellsFargoSync implements Schedulable {
    global void execute(SchedulableContext sc) {
        TSGCFG__Wells_Fargo_Setting__c wfSetting = TSGCFG__Wells_Fargo_Setting__c.getOrgDefaults();
        WellsFargoAPIController.ResponseModel rm = WellsFargoAPIController.validateWFSetting(wfSetting);
        
        if(!rm.isError){
            BatchWellsFargoApplicationSync obj = new BatchWellsFargoApplicationSync(wfSetting);
            Database.executeBatch(obj, 1);
        }
    }
}