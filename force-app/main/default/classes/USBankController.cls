public class USBankController {
    
    @AuraEnabled
    public static List<TSGCFG__US_Bank_Client_Branch__c> getClientBranchDetails(){
        List<TSGCFG__US_Bank_Client_Branch__c> clientBranchList = [SELECT id,Name,TSGCFG__Client_Name__c,TSGCFG__Client_NBR__c,TSGCFG__Is_Default__c,TSGCFG__Relation__c FROM TSGCFG__US_Bank_Client_Branch__c Order by TSGCFG__Client_NBR__c ASC];
        return clientBranchList;
    }
    
     @AuraEnabled
    public static void updateClientBranchDetails(List<TSGCFG__US_Bank_Client_Branch__c> branchDetails, List<string> removeClientIds){
        system.debug('branchDetails ::'+branchDetails);
        List<TSGCFG__US_Bank_Client_Branch__c> branchDetailsList = new List<TSGCFG__US_Bank_Client_Branch__c>();
        for(TSGCFG__US_Bank_Client_Branch__c branch:branchDetails){
            if(branch.Name == null && string.isNotBlank(branch.TSGCFG__Client_Name__c)){
                string strName = branch.TSGCFG__Client_Name__c;
                strName = strName.length() > 30 ? strName.substring(0, 30) : strName;
                integer size  = branchDetails.size()+1;
                strName = size +' '+ strName; 
                branch.Name = strName;
                
            }
            branchDetailsList.add(branch);
        }
        system.debug('branchDetailsList :: '+branchDetailsList);
        upsert branchDetailsList;

        if(!removeClientIds.isEmpty()){
            List<TSGCFG__US_Bank_Client_Branch__c> deletelist = new List<TSGCFG__US_Bank_Client_Branch__c>([select id from TSGCFG__US_Bank_Client_Branch__c where Id IN: removeClientIds]);

            if(!deletelist.isEmpty()) delete deletelist;
        }
    }
    
    @AuraEnabled
    public static US_Bank_Configuration__c getCustomSettingDetails(){
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();
        return config;
    }
    
    @AuraEnabled
    public static void updateCustomSettingDetails(TSGCFG__US_Bank_Configuration__c config){
        upsert config;
    }
    
    @AuraEnabled
    public static List<selectOptionWapper> getClientName(){
        
        List<selectOptionWapper> options = new List<selectOptionWapper>();
        List<TSGCFG__US_Bank_Client_Branch__c> clientBranchList = [SELECT id,Name,TSGCFG__Client_Name__c,TSGCFG__Client_NBR__c,TSGCFG__Is_Default__c,TSGCFG__Relation__c FROM TSGCFG__US_Bank_Client_Branch__c Order by TSGCFG__Client_NBR__c ASC];
        
        selectOptionWapper optionWrap = new selectOptionWapper();
        optionWrap.label = 'Select...';
        optionWrap.value = '';
        options.add(optionWrap);
        for(TSGCFG__US_Bank_Client_Branch__c client:clientBranchList){
            selectOptionWapper optionWrap1 = new selectOptionWapper();
            optionWrap1.label = client.TSGCFG__Client_Name__c;
            optionWrap1.value = client.TSGCFG__Client_NBR__c;
            options.add(optionWrap1);
        }
        return options;
    }
    
    
    @AuraEnabled
    public static String USBankAuthentication(){
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();
        String message;
        DOM.Document doc = USBankXMLParser.generateLoginRequest();
        //dom.Document loginResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Application_Endpoint__c,doc,'GET');
        dom.Document loginResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Application_Endpoint__c,doc,'POST','');
        String sessionID = USBankXMLParser.loginDataParser(loginResp);
        if(String.isNotBlank(sessionID) && String.isNotEmpty(sessionID)){
            message = 'Authentication process Completed!';
        }
        else{
            message = 'Error: Please Check UserName and Password';
        }
        return message; 
    }
    
    @AuraEnabled
    public static ApplicationWrapper getDealDetails(String DealId){
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();
        
        String soqlQuery = 'select  Name,TSGCFG__Purchase_Option__c,TSGCFG__Total_Lease__c,TSGADX__Business_Street_Address__c,TSGADX__Business_City__c,TSGADX__Business_State__c,TSGADX__Business_Postal_Code__c,';
        soqlQuery += 'TSGADX__Business_Phone__c,TSGADX__Contact_Phone__c,TSGCFG__Term__c,TSGADX__Product_Service__c,TSGADX__Company__r.type,TSGADX__Company__r.Name,';
        for(Schema.FieldSetMember f : SObjectType.TSGADX__Deal__c.FieldSets.TSGCFG__US_Bank.getFields()) {
            if(!soqlQuery.contains(f.getFieldPath())){
                soqlQuery += f.getFieldPath() + ', ';
            }
        }
        String fieldName = config.TSGCFG__Tax_ID__c;
        if(fieldName != null && string.isnotblank(fieldName) && !soqlQuery.contains(fieldName)){
            soqlQuery+= fieldName+',';
        }        
        soqlQuery+= 'TSGADX__Company__r.BillingStreet,TSGADX__Company__r.ShippingStreet,TSGADX__Company__r.BillingCity,TSGADX__Company__r.ShippingCity,TSGADX__Company__r.BillingState,TSGADX__Company__r.ShippingState,TSGADX__Company__r.BillingPostalCode,TSGADX__Company__r.ShippingPostalCode,TSGADX__Company__r.Phone,';
        soqlQuery+= 'TSGCFG__Purchase_Option_Quote__c,TSGADX__Main_Contact__c,TSGCFG__Lease_Rate_Factor__c,TSGADX__Main_Contact__r.FirstName,TSGADX__Main_Contact__r.LastName,TSGCFG__Equipment_Monthly_Payment__c,TSGCFG__Quote__c,TSGADX__Company__c,Id FROM TSGADX__Deal__c WHERE id =:DealId LIMIT 1';
        System.debug('soqlQuery '+soqlQuery);
        List<TSGADX__Deal__c> dealList = Database.query(soqlQuery);
        TSGADX__Deal__c deal = new TSGADX__Deal__c();
        ApplicationWrapper wrapcls = new ApplicationWrapper();
        if(dealList != null && dealList.size()>0){ 
            deal = dealList[0];
            if(deal.TSGADX__Contact_Phone__c != null){
                deal.TSGADX__Contact_Phone__c = USBankAPIHelper.FormatPhone(deal.TSGADX__Contact_Phone__c);
            }
            wrapcls.dealObj = dealList[0];
            wrapcls.Notes = '';
            if(deal.TSGCFG__Lease_Rate_Factor__c != null)
                wrapcls.Notes += 'PURCHASE RATE '+deal.TSGCFG__Lease_Rate_Factor__c+'\n';
            if(deal.TSGCFG__Equipment_Monthly_Payment__c  != null)
                wrapcls.Notes += 'MONTHLY PAYMENT '+deal.TSGCFG__Equipment_Monthly_Payment__c+'\n';
            if(deal.TSGCFG__Purchase_Option_Quote__c  != null)
                wrapcls.Notes += 'PROGRAM RATE '+deal.TSGCFG__Purchase_Option_Quote__c;
            
        }
        wrapcls.contactEmailOne = UserInfo.getUserEmail() != null ? UserInfo.getUserEmail() : '';
        wrapcls.contactEmailTwo = '';
        List<FieldSetMemberWrapperClass> wrapperList = new List<FieldSetMemberWrapperClass>();
        Schema.SObjectType sObj = Schema.getGlobalDescribe().get('TSGADX__Deal__c');
        
        for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get('TSGCFG__US_Bank').getFields()){
            FieldSetMemberWrapperClass wrapper = new FieldSetMemberWrapperClass();
            wrapper.isDBRequired = fieldMember.getDbRequired();
            wrapper.isRequired = fieldMember.getRequired();
            wrapper.fieldType = String.valueOf(fieldMember.getType());
            wrapper.fieldLabel = fieldMember.getLabel();
            wrapper.fieldAPIName = fieldMember.getFieldPath();
            if(String.valueOf(fieldMember.getType()) == 'PICKLIST' || String.valueOf(fieldMember.getType()) == 'MULTIPICKLIST'){
                wrapper.pickListValues = sObj.getDescribe().fields.getMap().get(fieldMember.getFieldPath()).getDescribe().getPicklistValues();
            }
            wrapperList.add(wrapper);
        }
        wrapcls.totalFinanceAmount = String.valueOf(deal.TSGCFG__Total_Lease__c);
        if(deal.TSGCFG__Term__c != null && deal.TSGCFG__Term__c > 0) {
            wrapcls.term = String.valueOf(deal.TSGCFG__Term__c);
        }
        wrapcls.equipmentDescription = deal.TSGADX__Product_Service__c;
        if(deal.TSGCFG__Purchase_Option__c != null){
            wrapcls.purchaseOption = deal.TSGCFG__Purchase_Option__c;
        }else{
            wrapcls.purchaseOption = '';
        }
        
        if(deal.TSGADX__Company__c != null){
            wrapcls.name = deal.TSGADX__Company__r.Name;
            if(deal.TSGADX__Business_Street_Address__c !=null){
                wrapcls.address = deal.TSGADX__Business_Street_Address__c;
            }else if(deal.TSGADX__Company__r.BillingStreet != null){
                wrapcls.address = deal.TSGADX__Company__r.BillingStreet;
            }else if(deal.TSGADX__Company__r.ShippingStreet != null){
                wrapcls.address = deal.TSGADX__Company__r.ShippingStreet;
            }
            
            if(deal.TSGADX__Business_City__c !=null){
                wrapcls.city = deal.TSGADX__Business_City__c;
            }else if(deal.TSGADX__Company__r.BillingCity != null){
                wrapcls.city = deal.TSGADX__Company__r.BillingCity;
            }else if(deal.TSGADX__Company__r.ShippingCity != null){
                wrapcls.city = deal.TSGADX__Company__r.ShippingCity;
            }
            
            if(deal.TSGADX__Business_State__c !=null){
                wrapcls.state =deal.TSGADX__Business_State__c;
            }else if(deal.TSGADX__Company__r.BillingState != null){
                wrapcls.state = deal.TSGADX__Company__r.BillingState;
            }else if(deal.TSGADX__Company__r.ShippingState != null){
                wrapcls.state = deal.TSGADX__Company__r.ShippingState;
            }
            
            if(deal.TSGADX__Business_Postal_Code__c !=null){
                wrapcls.zip = deal.TSGADX__Business_Postal_Code__c;
            }else if(deal.TSGADX__Company__r.BillingPostalCode != null){
                wrapcls.zip = deal.TSGADX__Company__r.BillingPostalCode;
            }else if(deal.TSGADX__Company__r.ShippingPostalCode != null){
                wrapcls.zip = deal.TSGADX__Company__r.ShippingPostalCode;
            }
            
            if(deal.TSGADX__Business_Phone__c !=null){
                wrapcls.telephone = USBankAPIHelper.FormatPhone(deal.TSGADX__Business_Phone__c);
            }else if(deal.TSGADX__Company__r.Phone != null) {
                wrapcls.telephone = USBankAPIHelper.FormatPhone(deal.TSGADX__Company__r.Phone);
            }   
        }
        wrapcls.BusinessTypeValues = getBusinessTypePicklistValues();
        wrapcls.selectedBusinessType = 'None';
        wrapcls.FieldSetList = wrapperList;
        //query on user to get default US Bank Client Id
        List<User> lstUsers = new List<User>([Select ID, TSGCFG__US_Bank_Client_Id__c FROM User Where Id =: UserInfo.getUserId() 
                    AND TSGCFG__US_Bank_Client_Id__c != null]);
        List<TSGCFG__US_Bank_Client_Branch__c> clientBranchList = [SELECT id,Name,TSGCFG__Client_Name__c,
                TSGCFG__Client_NBR__c,TSGCFG__Is_Default__c,TSGCFG__Relation__c FROM TSGCFG__US_Bank_Client_Branch__c 
                WHERE TSGCFG__Is_Default__c = true];
        if(lstUsers.size() > 0) {
            wrapcls.selectedClientName = lstUsers[0].TSGCFG__US_Bank_Client_Id__c;
        } else if(clientBranchList.size()>0){
            wrapcls.selectedClientName = clientBranchList[0].TSGCFG__Client_NBR__c;
        }else{
            wrapcls.selectedClientName = '';
        }
        
        return wrapcls;
    } 
    
    public static List<selectOptionWapper> getBusinessTypePicklistValues(){
        List<selectOptionWapper> options = new List<selectOptionWapper>();
        Map<String,String> MapOfBusinessType = new Map<String,String>();
        MapOfBusinessType.put('None', '9');
        MapOfBusinessType.put('Private Corporation', '32');
        MapOfBusinessType.put('Limited Liability Corp', '33');
        MapOfBusinessType.put('Municipality', '1101');
        MapOfBusinessType.put('Undetermind', '1104');
        MapOfBusinessType.put('Public Corporation', '1105');
        MapOfBusinessType.put('Proprietorship', '1106');
        MapOfBusinessType.put('Partnership', '1107');
        MapOfBusinessType.put('Nonprofit', '1108');
        MapOfBusinessType.put('Corporation', '1109');
        selectOptionWapper optionWrap = new selectOptionWapper();
        //commented on 05/09/2023 by mitraj
        // optionWrap.label = 'Select...';
        // optionWrap.value = '';
        // optionWrap.label = 'None';
        // optionWrap.value = '9';
        // options.add(optionWrap);
        for(String str : MapOfBusinessType.keySet()){
            selectOptionWapper optionWrap1 = new selectOptionWapper();
            optionWrap1.label = str;
            optionWrap1.value = MapOfBusinessType.get(str);
            options.add(optionWrap1);
        }  
        return options;
    }
    
    @AuraEnabled
    public static ApplicationWrapper submitApplicationData(TSGADX__Deal__c  wrapObj, String wrapClsStr){
        system.debug('wrapClsStr :: '+wrapClsStr);
        ApplicationWrapper wrapcls = (ApplicationWrapper)JSON.deserialize(wrapClsStr, ApplicationWrapper.class);
        ApplicationWrapper returnWrapCls = new ApplicationWrapper();
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();       
        try{
            returnWrapCls.dealObj = wrapObj; 
            DOM.Document doc = USBankXMLParser.generateLoginRequest();
            //dom.Document loginResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Application_Endpoint__c,doc,'GET');
            dom.Document loginResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Application_Endpoint__c,doc,'POST','');
            String sessionID = USBankXMLParser.loginDataParser(loginResp); 
            
            //update purchase option 
            Map<String,String> MapOfPurchaseOption = new Map<String,String>();
            MapOfPurchaseOption.put('FMV','1');
            MapOfPurchaseOption.put('% Option','2');
            MapOfPurchaseOption.put('% PUT','3');
            MapOfPurchaseOption.put('$1','4');
            
            // if(MapOfPurchaseOption.containsKey(wrapObj.TSGCFG__Purchase_Option__c)){
            //     wrapObj.TSGCFG__Purchase_Option__c = MapOfPurchaseOption.get(wrapObj.TSGCFG__Purchase_Option__c);
            // }
            if(wrapcls?.purchaseOption != null && MapOfPurchaseOption.containsKey(wrapcls.purchaseOption)){
                wrapObj.TSGCFG__Purchase_Option__c = MapOfPurchaseOption.get(wrapcls.purchaseOption);
            }
            DOM.Document AppDoc = USBankXMLParser.generateApplicationDataRequest(sessionID, wrapObj, wrapcls); 
            
            DOM.Document applicationDataResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Application_Endpoint__c,AppDoc,'GET','');
            
            String ApplicationDataRes = USBankXMLParser.ApplicationDataParser(applicationDataResp);
            List<String> dataResLst = ApplicationDataRes.split(',');
            returnWrapCls.isError = false;
            if(dataResLst != null && dataResLst.size()>0){
                if(ApplicationDataRes.contains('success') && dataResLst[0] != ''){                        
                    string message  = createApplicationRecord(dataResLst[0],ApplicationDataRes,wrapObj,wrapcls);
                    if(message.startsWith('Error')){
                        returnWrapCls.errormessages.add(message);
                        returnWrapCls.isError = true;
                    }
                    returnWrapCls.messages.add(dataResLst[0]+':'+'Application Submitted successfully');
                } else {
                    returnWrapCls.isError = true;
                    returnWrapCls.errormessages.add(ApplicationDataRes);
                }
            }
            
           
            
        }catch(Exception ex){
            returnWrapCls.isError = true;
            returnWrapCls.errormessages.add('Exception: '+ex.getMessage()+' at: '+ex.getLineNumber());
        }
        return returnWrapCls;
    }
    
    @AuraEnabled
    public static void UpdateCreditStatusFromBatch(){
        BatchToUpdateUSBankStatus batch = new BatchToUpdateUSBankStatus();
        Id batchId = Database.executeBatch(batch,1);
    }
    
    
    @AuraEnabled
    public static String getCreditDecisionStatus(String ApplicationId){
        String message = 'Credit Application is in progress. Please contact US Bank to check.';
        try{
            TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();            
            
            List<TSGCFG__Credit_Application__c> application =[SELECT id,Name,TSGCFG__Status__c,TSGCFG__Approved_Amount__c,TSGCFG__Approved_Term__c,TSGCFG__Rate_Factor__c FROM TSGCFG__Credit_Application__c WHERE id=:ApplicationId limit 1];
            TSGCFG__Credit_Application__c appObj = new TSGCFG__Credit_Application__c(id=application[0].id);
            if(application != null){
                DOM.Document statusReq = USBankXMLParser.generateCreditDecisionRequest(application[0].Name);
                //DOM.Document decisionDataResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Credit_Decision_Endpoint__c,statusReq,'GET');
                DOM.Document decisionDataResp = USBankAPIHelper.USBankCallout(config.TSGCFG__EndPoint__c+config.TSGCFG__Lease_Credit_Decision_Endpoint__c,statusReq,'POST','GetCreditDecision');
                Map<String,String> responseMap =  USBankXMLParser.CreditDecisionDataParser(decisionDataResp);
                if(responseMap.containsKey('QueryStatusDescription')){
                    if(responseMap.get('QueryStatusDescription') == 'Credit record not found'){
                        message = 'Credit Application is in progress. Please contact US Bank to check.';
                        //Credit Application not Found or In progress.
                    }             
                }
                if(responseMap.containsKey('DecisionStatus')){
                    application[0].TSGCFG__Status__c =responseMap.get('DecisionStatus');
                    message = 'Credit Application is '+responseMap.get('DecisionStatus');
                }
                if(responseMap.containsKey('DecisionStatus') && responseMap.get('DecisionStatus') == 'Approved' && responseMap.containsKey('EfeTranID')){
                    application[0].Name = responseMap.get('EfeTranID');
                }
                if(responseMap.containsKey('ApprovedAmount')){
                    application[0].TSGCFG__Approved_Amount__c =Decimal.valueOf(responseMap.get('ApprovedAmount'));
                }
                if(responseMap.containsKey('ApprovedTerm')){
                    application[0].TSGCFG__Approved_Term__c =Decimal.valueOf(responseMap.get('ApprovedTerm'));
                }
                if(responseMap.containsKey('RateFactor')){
                    application[0].TSGCFG__Rate_Factor__c =Decimal.valueOf(responseMap.get('RateFactor'));
                }
                if(responseMap.containsKey('MonthlyPaymentWithoutTaxAmount')){
                    application[0].TSGCFG__Monthly_Payment_Without_Tax_Amount__c = Decimal.valueOf(responseMap.get('MonthlyPaymentWithoutTaxAmount'));
                }
                if(responseMap.containsKey('ExpirationDate')){
                    application[0].TSGCFG__Expiration_Date__c = Date.valueOf(responseMap.get('ExpirationDate'));
                }                
                
                update application[0];
            }
        }catch(Exception ex){
            message = ex.getMessage()+' at '+ex.getLineNumber();
        }
        return message; 
    }
    
    public static string createApplicationRecord(String RecordId,String ResponseBody,TSGADX__Deal__c  wrapObj, 
            ApplicationWrapper wrapcls){       
        string message = 'success';
        try{
            TSGCFG__Credit_Application__c app = new TSGCFG__Credit_Application__c();
            List<TSGCFG__US_Bank_Client_Branch__c> clientBranchList = new List<TSGCFG__US_Bank_Client_Branch__c>();
            /*if(wrapcls.selectedClientName != null){
                clientBranchList = [SELECT id,Name,TSGCFG__Client_Name__c,TSGCFG__Client_NBR__c,TSGCFG__Is_Default__c FROM TSGCFG__US_Bank_Client_Branch__c WHERE TSGCFG__Client_NBR__c = :wrapcls.selectedClientName];
            }else{
                clientBranchList = [SELECT id,Name,TSGCFG__Client_Name__c,TSGCFG__Client_NBR__c,TSGCFG__Is_Default__c FROM TSGCFG__US_Bank_Client_Branch__c WHERE TSGCFG__Client_NBR__c = :wrapcls.defaultClientName];
            }*/
            if(wrapcls.selectedClientName != null){
                app.TSGCFG__US_Bank_Client_Id__c = wrapcls.selectedClientName;
            }
            Id RecordTypeId = Schema.SObjectType.TSGCFG__Credit_Application__c.getRecordTypeInfosByDeveloperName().get('US_Bank_Application').getRecordTypeId();
            app.RecordTypeId = RecordTypeId;
            app.Name = RecordId;
            app.TSGCFG__Deal__c = wrapcls.dealObj.id;
            app.TSGCFG__Request_Body__c = USBankXMLParser.leaseApplicationData(wrapObj,wrapcls);
            app.TSGCFG__Response_Body__c = ResponseBody;
            app.TSGCFG__Type__c ='Credit';
            if(string.isnotblank(wrapcls.Notes)){
                app.TSGCFG__Application_Notes__c = wrapcls.Notes;
            }
            if(string.isnotblank(wrapcls.totalFinanceAmount)) {
                app.TSGCFG__Application_Total_Finance_Amount__c = Decimal.valueof(wrapcls.totalFinanceAmount);
            }
            if(string.isnotblank(wrapcls.term)) {
                app.TSGCFG__Term__c = decimal.valueof(wrapcls.term);  
            }      
            app.TSGCFG__Lessee_Contact_Email__c = wrapcls.contactEmail;
            app.TSGCFG__Lessee_Contact_Phone__c = wrapcls.contactPhone;
            if(wrapObj.TSGADX__Main_Contact__c != null) {
                app.TSGCFG__Contact__c = wrapObj.TSGADX__Main_Contact__c;
            }
            if(wrapObj.TSGADX__Company__c != null){
                app.TSGCFG__Business__c = wrapObj.TSGADX__Company__c;
            }
            app.TSGCFG__Lessee_Address__c = wrapcls.address;
            app.TSGCFG__Lessee_City__c = wrapcls.city;
            app.TSGCFG__Lessee_State__c = wrapcls.state;
            app.TSGCFG__Lessee_Phone__c = wrapcls.telephone;
            app.TSGCFG__Lessee_Zip__c = wrapcls.zip;
            app.TSGCFG__Purchase_Option__c = wrapObj.TSGCFG__Purchase_Option__c;
            app.TSGCFG__Status__c = 'Submitted'; 
            app.TSGCFG__Quote__c = wrapObj.TSGCFG__Quote__c;
            /*if(clientBranchList!= null && clientBranchList.size()>0){
                app.TSGCFG__US_Bank_Client_Id__c = clientBranchList[0].TSGCFG__Client_NBR__c;
            }*/
            
            app.TSGCFG__Last_Synced__c = system.now();                
            insert app;
        }catch(Exception ex){
            message = 'Error while creating Credit Application: '+ex.getMessage()+' at '+ex.getLineNumber();
        }
        return message;
    }

    @AuraEnabled
    public static GreatAmericaAPIHelper.ResponseModel rateFactorLeaseData(string dtDate){
        GreatAmericaAPIHelper.ResponseModel rm = new GreatAmericaAPIHelper.ResponseModel();
        if(dtDate != null){
            try{

                List<CronTrigger> lstcron = new List<CronTrigger>();
                boolean blncronExecuting = false;
                for (CronTrigger c : [SELECT Id, NextFireTime, CronJobDetail.Name, PreviousFireTime, State, StartTime, EndTime, CronExpression, TimeZoneSidKey FROM CronTrigger where CronJobDetail.Name = 'Lease Data']) {
                    if(c.State == 'EXECUTING'){
                        blncronExecuting = true;
                    }
                    lstcron.add(c);
                }               
                
                if(!blncronExecuting){
                    if(lstcron.size()>0){
                        for(cronTrigger c : lstcron){
                            System.abortJob(c.Id);
                        }
                    }                    
                    string strTimeData = dtDate;
                    string strHour = strTimeData.split(':')[0];
                    string strMinute = strTimeData.split(':')[1];
                    string strsec = strTimeData.split(':')[2];

                    string CRON_EXP = strsec + ' ' + strMinute + ' ' +  strHour + ' 1/1 * ? *';    
                    system.schedule('Lease Data' , CRON_EXP , new SchedulerRateFactorSync());

                    DateTime dtStartTimeSchduler = null;
                    for (CronTrigger c : [SELECT Id, NextFireTime, CronJobDetail.Name, PreviousFireTime, State, StartTime, EndTime, CronExpression, TimeZoneSidKey FROM CronTrigger where CronJobDetail.Name = 'Lease Data']) {
                        dtStartTimeSchduler = c.NextFireTime;
                    }    
                    rm.messages.add('Lease Data scheduler will be run on ' + dtStartTimeSchduler.format() + '.');

                    rm.isError = false;
                    //rm.messages.add('Lease Data scheduler has been initiated.');
                }else{
                    rm.isError = true;
                    rm.messages.add('Lease Data scheduler is running.');
                }
                
            }catch(Exception e){
                rm.messages.add((e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
            }            
        }else{
            rm.messages.add('Lease Data settings is missing, Please contact your administrator.');
        }
        return rm;
    }
    
    @AuraEnabled
    public static List<wrpCronTrigger>  findRunningAsyncJob(){
        List<wrpCronTrigger> lstwrp = new List<wrpCronTrigger>();
        for(CronTrigger ct : [SELECT Id, NextFireTime, CronJobDetail.Name, PreviousFireTime, State, StartTime, EndTime, CronExpression, TimeZoneSidKey FROM CronTrigger where CronJobDetail.Name LIKE 'USBank Status Sync%' OR CronJobDetail.Name = 'Lease Data']){
            wrpCronTrigger o = new wrpCronTrigger();
            o.jobname = ct.CronJobDetail.Name;
            o.NextFireTime = ct.NextFireTime;
            o.TimeZoneSidKey = ct.TimeZoneSidKey;
            lstwrp.add(o);
        }
        return lstwrp;
    }
    
    @AuraEnabled
    public static String ScheduleUSBankForMin(String selectedValue){
        String message;
        try{
           
            for(CronTrigger job:[SELECT Id,CronJobDetail.Name FROM CronTrigger where CronJobDetail.Name LIKE 'USBank Status Sync%'])
            {
                System.abortJob(job.id);
            }
            
            if(selectedValue=='10'){                   
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 10 Min', '0 10 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 20 Min', '0 20 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 30 Min', '0 30 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 40 Min', '0 40 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 50 Min', '0 50 * * * ?', new BatchToUpdateUSBankStatus()); 
                message = 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='20'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 20 Min', '0 20 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 40 Min', '0 40 * * * ?', new BatchToUpdateUSBankStatus());
                message = 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='30'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 30 Min', '0 30 * * * ?', new BatchToUpdateUSBankStatus());
                message = 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='40'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 40 Min', '0 40 * * * ?', new BatchToUpdateUSBankStatus());
                message = 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue=='50'){
                System.schedule('USBank Status Sync 0 Min', '0 0 * * * ?', new BatchToUpdateUSBankStatus());
                System.schedule('USBank Status Sync 50 Min', '0 50 * * * ?', new BatchToUpdateUSBankStatus());
                message = 'US Bank scheduler is running for every '+selectedValue+' Minutes.';
            }else if(selectedValue =='1-Hour'){
                string CRON_EXP = '0 0 * * * ?'; //'0 0 0/1 1/1 * ? *';
                system.schedule('USBank Status Sync' , CRON_EXP , new BatchToUpdateUSBankStatus());
                message = 'US Bank scheduler is running for every 1 Hour.';
            }
            
            
        }catch(Exception e){
            message = 'Error: '+e.getMessage()+', at line '+e.getLineNumber();
        }
        return message;       
        
    }
    
    
    @AuraEnabled
    public static String ScheduleUSBankCreditStatus(string dtDate){
        String message;
        if(dtDate != null){
            try{
                List<CronTrigger> lstcron = new List<CronTrigger>();
                boolean blncronExecuting = false;
                for (CronTrigger c : [SELECT Id, NextFireTime, CronJobDetail.Name, PreviousFireTime, State, StartTime, EndTime, CronExpression, TimeZoneSidKey FROM CronTrigger where CronJobDetail.Name = 'USBank Status Sync']) {
                    if(c.State == 'EXECUTING'){
                        blncronExecuting = true;
                    }
                    lstcron.add(c);
                }               
                
                if(!blncronExecuting){
                    if(lstcron.size()>0){
                        for(cronTrigger c : lstcron){
                            System.abortJob(c.Id);
                        }
                    }                    
                    string strTimeData = dtDate;
                    string strHour = strTimeData.split(':')[0];
                    string strMinute = strTimeData.split(':')[1];
                    string strsec = strTimeData.split(':')[2];
                    
                    string CRON_EXP = strsec + ' ' + strMinute + ' ' +  strHour + ' 1/1 * ? *';    
                    system.schedule('USBank Status Sync' , CRON_EXP , new BatchToUpdateUSBankStatus());
                    
                    DateTime dtStartTimeSchduler = null;
                    for (CronTrigger c : [SELECT Id, NextFireTime, CronJobDetail.Name, PreviousFireTime, State, StartTime, EndTime, CronExpression, TimeZoneSidKey FROM CronTrigger where CronJobDetail.Name = 'USBank Status Sync']) {
                        dtStartTimeSchduler = c.NextFireTime;
                    }    
                    message = 'US Bank scheduler will be run on ' + dtStartTimeSchduler.format() + '.';
                    
                }else{
                    message = 'US Bank scheduler is running.';
                }
                
            }catch(Exception e){
                message = 'Error: '+e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber();
            }            
        }else{
            message = 'Error: US Bank settings is missing, Please contact your administrator.';
        }
        return message;
    }
    
    public class wrpCronTrigger{
        @AuraEnabled 
        public DateTime NextFireTime {get;set;}        
        @AuraEnabled 
        public string TimeZoneSidKey {get;set;}        
        @AuraEnabled 
        public string jobname        {get;set;}
    }
    
    public class selectOptionWapper{
        @AuraEnabled
        public string label {get; set;}        
        @AuraEnabled
        public string value {get; set;}
    }
    
    
    public class ApplicationWrapper{
        @AuraEnabled
        public List<FieldSetMemberWrapperClass> FieldSetList {get;set;}  
        @AuraEnabled
        public String Notes {get;set;}  
        @AuraEnabled
        public TSGADX__Deal__c dealObj                       {get;set;}        
        @AuraEnabled
        public List<selectOptionWapper> BusinessTypeValues   {get;set;} 
        @AuraEnabled
        public List<selectOptionWapper> ClientNameValues     {get;set;}
        @AuraEnabled
        public String defaultClientName                      {get;set;} 
        @AuraEnabled
        public String fedTaxId                               {get;set;}        
        @AuraEnabled
        public String Message                                {get;set;}        
        @AuraEnabled
        public Boolean isError                               {get;set;}        
        @AuraEnabled 
        public List<String> messages = new List<String>();
        @AuraEnabled 
        public List<String> errormessages = new List<String>();
        @AuraEnabled
        public String totalFinanceAmount{get;set;}
        @AuraEnabled
        public String term{get;set;}
        @AuraEnabled
        public String equipmentDescription{get;set;}
        @AuraEnabled
        public String purchaseOption{get;set;}
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String address{get;set;}
        @AuraEnabled
        public String city{get;set;}
        @AuraEnabled
        public String state{get;set;}
        @AuraEnabled
        public String zip{get;set;}
        @AuraEnabled
        public String telephone{get;set;}
        @AuraEnabled
        public String selectedBusinessType{get;set;}
        @AuraEnabled
        public String selectedClientName{get;set;}
        @AuraEnabled
        public String contactEmail{get;set;}
        @AuraEnabled
        public String contactEmailOne{get;set;}
        @AuraEnabled
        public String contactEmailTwo{get;set;}
        @AuraEnabled
        public String contactPhone{get;set;}
        @AuraEnabled public List<String> purchaseOptions=GreatAmericaController.getPicklistValues('TSGCFG__Quote__c', 'TSGCFG__Purchase_Option__c');
        
    }
    
    
    public class FieldSetMemberWrapperClass{
        
        @AuraEnabled
        public Boolean isDBRequired                      { get; set; }
        @AuraEnabled
        public Boolean isRequired                        { get; set; }
        @AuraEnabled
        public String fieldType                          { get; set; }
        @AuraEnabled
        public String fieldLabel                         { get; set; }
        @AuraEnabled
        public String fieldAPIName                       { get; set; }
        @AuraEnabled 
        public List<Schema.PicklistEntry> pickListValues { get; set; }
        
        
    }
    
    public class UserAgreementWrap{
        @AuraEnabled
        public boolean isError;
        
        @AuraEnabled
        public string messages;
    }
    
    @AuraEnabled
    public static UserAgreementWrap runLeaseDataBatch(){
        
        UserAgreementWrap rm = new UserAgreementWrap();
        rm.isError = false;   
        List<AsyncApexJob> lstAsync = new List<AsyncApexJob>([SELECT Id, Status, ApexClassID FROM AsyncApexJob WHERE ApexClass.Name ='BatchLeaseData' AND (Status='Processing' OR Status='Preparing' OR Status='Holding' OR Status='Queued')]);
        
        if(lstAsync.size()>0){
            rm.isError = true;  
            rm.messages ='Lease Data sync process already running. Kindly wait for sometimes.';
        } else{
            LeaseDataCallOut.UserAgreementCall();
            rm.messages ='Lease Data sync has been initiated.';
        } 
        return rm;
    }
    
    @AuraEnabled
    public static UserAgreementWrap runBatchSyncAllBOQuoteAgreement(){
        
        TSGCFG__US_Bank_Configuration__c config = TSGCFG__US_Bank_Configuration__c.getOrgDefaults();
        UserAgreementWrap rm = new UserAgreementWrap();
        if(config.TSGCFG__Lease_Credit_App_Service_endpoint__c == null){
            rm.isError = true;
            rm.messages = 'Please add proper endpoint in setup page.'; 
        }
        else{ 
            rm.isError = false;   
            List<AsyncApexJob> lstAsync = new List<AsyncApexJob>([SELECT Id, Status, ApexClassID FROM AsyncApexJob WHERE ApexClass.Name ='BatchSyncAllBOQuoteAgreement' AND (Status='Processing' OR Status='Preparing' OR Status='Holding')]);
            
            if(lstAsync.size()>0){
                rm.isError = true;  
                rm.messages ='BuyOut Quote sync process already running. Kindly wait for sometimes.';
            } else{
                List<TSGADX__Agreements__c> agreementLST = new List<TSGADX__Agreements__c>();
                string BuyOut_Lease_ID = config.TSGCFG__BuyOut_Lease_Id__c ; 
                string strQuery = 'select Id,TSGADX__Lease_ID__c';
                
                if(BuyOut_Lease_ID != null){
                    strQuery += ',' +BuyOut_Lease_ID+
                        ' from TSGADX__Agreements__c where ( TSGADX__Lease_ID__c != null OR '+BuyOut_Lease_ID+' != null) '; 
                }else{
                    strQuery += ' from TSGADX__Agreements__c where TSGADX__Lease_ID__c != null';
                }
                agreementLST = database.query(strQuery);
                //agreementLST = [select Id,TSGADX__Lease_ID__c from TSGADX__Agreements__c where TSGADX__Lease_ID__c != null];
                if(agreementLST.size()>0){
                    BatchSyncAllBOQuoteAgreement batch = new BatchSyncAllBOQuoteAgreement(agreementLST);
                    Database.executeBatch(batch,1);
                    rm.messages ='BuyOut Quote sync has been initiated.';
                }else{
                    rm.messages ='No Records to Sync.';
                }
                
            }
        } 
        return rm;
    } 
    
    
}