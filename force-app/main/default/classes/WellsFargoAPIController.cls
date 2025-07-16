public with sharing class WellsFargoAPIController {
    static List<String> jobNames = new List<String>{
        'SchedulerWellsFargoSync Job 1 - 15 minutes', 'SchedulerWellsFargoSync Job 2 - 15 minutes', 
            'SchedulerWellsFargoSync Job 3 - 15 minutes', 'SchedulerWellsFargoSync Job 4 - 15 minutes',
            'SchedulerWellsFargoSync Job 1 - 30 minutes', 'SchedulerWellsFargoSync Job 2 - 30 minutes',
            'SchedulerWellsFargoSync Job 1 - Hourly'
            };
                
                @AuraEnabled
                public static ResponseModel submitWFCreditApp(String wfmString){
                    
                    ResponseModel rm = new ResponseModel();
                    try {
                        WellsFargoModel wfm = (WellsFargoModel) JSON.deserialize(wfmString, WellsFargoModel.class);
                        String reqBody = getBodyForSubmitCreditApplication(wfm);
                        String resBody;
                        wfm.rm = submitCreditAppToAPI(wfm.wfSetting, reqBody);
                        
                        if(wfm.rm.isError==false){
                            String ackId;
                            Dom.Document doc = new Dom.Document();  
                            doc.load(wfm.rm.messages[0]);  
                            
                            Dom.XMLNode rootElement = doc.getRootElement();  
                            for ( Dom.XMLNode childElement : rootElement.getChildElements() ) {  
                                
                                for ( Dom.XMLNode detailElement : childElement.getChildElements() ){
                                    if(detailElement.getName() == 'Fault')
                                        rm.messages.add(detailElement.getChildElement('faultcode', null).getText() +'=='+detailElement.getChildElement('faultstring', null).getText());
                                    if(detailElement.getName() == 'Acknowledgement'){
                                        ackId = detailElement.getChildElement('AcknowledgementId', null).getText();
                                    } 
                                }   
                            }
                            if(rm.messages.size()==0 && String.isNotBlank(ackId)){
                                rm.messages.add('Submitted successfully! AcknowledgementId: '+ackId);
                                
                                TSGCFG__Credit_Application__c app = new TSGCFG__Credit_Application__c();
                                
                                app.RecordTypeId = Schema.SObjectType.TSGCFG__Credit_Application__c.getRecordTypeInfosByDeveloperName().get('WF_Application').getRecordTypeId();
                                app.Name = ackId;
                                app.TSGCFG__Deal__c = wfm.deal.Id;
                                app.TSGCFG__Request_Body__c = reqBody;
                                app.TSGCFG__Response_Body__c = wfm.rm.messages[0];
                                
                                app.TSGCFG__Application_Total_Finance_Amount__c = Decimal.valueof(wfm.requestedAmount);
                                app.TSGCFG__Term__c = decimal.valueof(wfm.requestedTerm);  
                                
                                app.TSGCFG__Quote__c = wfm.deal.TSGCFG__Quote__c;
                                if(wfm.deal.TSGADX__Company__c != null){
                                    app.TSGCFG__Business__c = wfm.deal.TSGADX__Company__c;
                                }
                                
                                app.TSGCFG__Type__c ='Credit';
                                app.TSGCFG__Status__c = 'Submitted'; 
                                app.TSGCFG__Last_Synced__c = system.now();
                                
                                app.TSGCFG__Dealer_Id__c = wfm.dealer.TSGCFG__Dealer_Id__c;
                                app.TSGCFG__Dealer_Name__c = wfm.dealer.Name;
                                
                                //commented on 15-12-2021 as we need to add loggedinto user info/deal owner info
                                //app.TSGCFG__Dealer_Contact_Name__c = wfm.dealer.TSGCFG__Contact_First_Name__c+' '+wfm.dealer.TSGCFG__Contact_Last_Name__c;
                                //app.TSGCFG__Dealer_Contact_Email__c = wfm.dealer.TSGCFG__Contact_Email__c;
                                
                                //added on 15-12-2021 to set Dealer node base on setting either login user or deal owner
                                app.TSGCFG__Dealer_Contact_Name__c = wfm.dealOwnerOrLoggedInUser.FirstName +' '+wfm.dealOwnerOrLoggedInUser.LastName;
                                app.TSGCFG__Dealer_Contact_Email__c = wfm.dealOwnerOrLoggedInUser.Email;
                                
                                app.TSGCFG__Lessee_Address__c = wfm.deal.TSGADX__Business_Street_Address__c;
                                app.TSGCFG__Lessee_City__c = wfm.deal.TSGADX__Business_City__c;
                                app.TSGCFG__Lessee_State__c = wfm.deal.TSGADX__Business_State__c;
                                app.TSGCFG__Lessee_Zip__c = wfm.deal.TSGADX__Business_Postal_Code__c;
                                
                                insert app;
                                rm.isError = false;
                                rm.returnRecordId = app.Id;
                                rm.returnObjectApiName = 'TSGCFG__Credit_Application__c';
                            }
                        }else{
                            rm = wfm.rm;
                        }
                    } catch (Exception e) {
                        rm.messages.add('submitWFCreditApp == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
                    }
                    return rm;
                }
    
    @AuraEnabled
    public static WellsFargoModel getWFAppDependencies(Id recordId){
        WellsFargoModel wfm = new WellsFargoModel();
        try {
            if(string.isBlank(recordId))
                wfm.rm.messages.add('Invalid Deal.');
            else{
                List<TSGADX__Deal__c> deals = [select id, Name, TSGCFG__Quote__c, TSGADX__Company__c,
                                               TSGADX__Company__r.Name, TSGADX__Price__c, TSGCFG__Term__c,
                                               TSGADX__Business_City__c, TSGADX__Business_Country__c, 
                                               TSGADX__Business_State__c, TSGADX__Business_Street_Address__c, 
                                               TSGADX__Business_Postal_Code__c, OwnerId,TSGADX__Company__r.BillingCity,
                                               TSGADX__Company__r.BillingStreet,
                                               TSGADX__Company__r.BillingState,TSGADX__Company__r.BillingPostalCode,TSGADX__Company__r.BillingCountry,
                                               TSGADX__Company__r.Phone from TSGADX__Deal__c where id=:recordId];
                if(deals.size()==0)
                    wfm.rm.messages.add('Deal not found, please contact your administrator.');
                else {
                    if(deals[0].TSGADX__Company__c == null)
                        wfm.rm.messages.add('Deal\'s business details not found, please complete the details.');
                    if(deals[0].TSGADX__Company__c != null && deals[0].TSGADX__Company__r.BillingState == null)
                        wfm.rm.messages.add('Deal\'s Business: Billing State may not be empty.');
                    else{
                        if(deals[0].TSGADX__Company__c != null){
                            List<TSGCFG__States__c> states = [select Name, TSGCFG__State_Name__c from TSGCFG__States__c where TSGCFG__State_Name__c=:deals[0].TSGADX__Company__r.BillingState OR Name =:deals[0].TSGADX__Company__r.BillingState];
                            if(states.size()>0){
                                wfm.stateCode = states[0].Name;
                            }else
                                wfm.rm.messages.add('Deal\'s Business: Billing State is not Valid value for defined State Codes.');
                        }
                    }
                    // if(deals[0].TSGADX__Company__c != null && (deals[0].TSGADX__Company__r.BillingPostalCode == null || (deals[0].TSGADX__Company__r.BillingPostalCode != null && !deals[0].TSGADX__Company__r.BillingPostalCode.isNumeric())
                    //    || (deals[0].TSGADX__Company__r.BillingPostalCode != null && deals[0].TSGADX__Company__r.BillingPostalCode.isNumeric() && deals[0].TSGADX__Company__r.BillingPostalCode.length() != 5 )))
                    //     wfm.rm.messages.add('Deal\'s Business: The zip code is blank, or is not the valid US zip code.');

                    if (deals[0].TSGADX__Company__c != null) {
                        String postalCode = deals[0].TSGADX__Company__r.BillingPostalCode;

                        if (postalCode == null) {
                            wfm.rm.messages.add('Deal\'s Business: The zip code is blank, or is not the valid US zip code.');
                        } else {
                            // Remove all non-digit characters
                            postalCode = postalCode.replaceAll('[^0-9]', '');

                            // Trim from the left if longer than 5 digits
                            if (postalCode.length() > 5) {
                                postalCode = postalCode.substring(postalCode.length() - 5);
                            }

                            // Check if the cleaned code is exactly 5 digits
                            if (postalCode.length() != 5) {
                                wfm.rm.messages.add('Deal\'s Business: The zip code is blank, or is not the valid US zip code.');
                            } else {
                                // Optional: Save the cleaned value back if needed
                                deals[0].TSGADX__Company__r.BillingPostalCode = postalCode;
                            }
                        }
                    }
                    
                    if(deals[0].TSGADX__Company__c != null && deals[0].TSGADX__Company__r.BillingCountry != null && deals[0].TSGADX__Company__r.BillingCountry != 'US' && deals[0].TSGADX__Company__r.BillingCountry != 'USA'  && deals[0].TSGADX__Company__r.BillingCountry != 'United States')
                        wfm.rm.messages.add('Deal\'s Business: Applications are only available for US based businesses.');
                    if(deals[0].TSGADX__Company__c != null && (deals[0].TSGADX__Company__r.BillingCity == null || deals[0].TSGADX__Company__r.BillingCity == ''))
                        wfm.rm.messages.add('Deal\'s Business: The Billing City may not be empty.');
                    
                }
                if(wfm.rm.messages.size()==0){
                     wfm.deal = deals[0];
                     //added on 16-12-2021 to set Dealer node base on setting either login user or deal owner
                     TSGCFG__Wells_Fargo_Setting__c TempWFSetting = TSGCFG__Wells_Fargo_Setting__c.getOrgDefaults();
                     //if(TempWFSetting.TSGCFG__Use_logged_in_user_for_credit_app__c){
                        if(TempWFSetting.TSGCFG__Dealer_Lease_Admin_Detail_for_Credit_App__c){
                        user u = new user();
                        u.FirstName = TempWFSetting.TSGCFG__First_Name__c != null ? TempWFSetting.TSGCFG__First_Name__c : '';
                        u.LastName = TempWFSetting.TSGCFG__Last_Name__c != null ? TempWFSetting.TSGCFG__Last_Name__c: '';
                        u.Email = TempWFSetting.TSGCFG__Email__c != null ? TempWFSetting.TSGCFG__Email__c : '';
                        wfm.dealOwnerOrLoggedInUser = u ;
                    }else{
                        wfm.dealOwnerOrLoggedInUser = [select Id,FirstName,LastName,Email,Name from user where Id =: UserInfo.getUserId() limit 1]; 
                       // wfm.dealOwnerOrLoggedInUser = [select Id,FirstName,LastName,Email,Name from user where Id =: deals[0].OwnerId  limit 1];
                    }
                    //End 16-12-2021
                }
                   
            }
            
            if(wfm.rm.messages.size()==0){
                wfm.wfDealers = TSGCFG__Wells_Fargo_Dealer__c.getAll().Values();
                if(wfm.wfDealers == null || wfm.wfDealers.size()==0)
                    wfm.rm.messages.add('No dealer found, please contact your administrator.');
                
                wfm.wfSetting = TSGCFG__Wells_Fargo_Setting__c.getOrgDefaults();
                wfm.rm.messages.addAll(validateWFSetting(wfm.wfSetting).messages);
                
                List<User> userList = [select id,TSGCFG__Wells_Fargo_Dealer_ID__c from User where id=:UserInfo.getUserId()];
                if(userList.size()>0 && userList[0].TSGCFG__Wells_Fargo_Dealer_Id__c != null)
                    wfm.defaultDealerId = userList[0].TSGCFG__Wells_Fargo_Dealer_Id__c;
                
                if(wfm.rm.messages.size()==0){
                    wfm.rm.isError = false;
                }
            }
        } catch (Exception e) {
            wfm.rm.messages.add('getCreditAppDependencies == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        return wfm;
    }
    
    //This method returns list of CronTrigger if any job is scheduled for RateFactor or Greatamerica sync
    @AuraEnabled
    public static AsyncJobStatus  findRunningAsyncJob(){
        AsyncJobStatus model = new AsyncJobStatus();
        try {
            List<CronTrigger> ctList = [SELECT Id, NextFireTime, CronJobDetail.Name, PreviousFireTime, State, StartTime, EndTime, CronExpression, TimeZoneSidKey FROM CronTrigger where CronJobDetail.Name in: jobNames order by NextFireTime];
            if(ctList.size()==4)
                model.message = 'Currently scheduled to run every 15 minutes';
            else if(ctList.size()==2)
                model.message = 'Currently scheduled to run every 30 minutes';
            else if(ctList.size()==1)
                model.message = 'Currently scheduled to Hourly';
            else if(ctList.size() == 0)
                model.message = 'No schedule job exist, please click "Schedule" to run in background.';
            
            if(ctList.size()>0){
                model.NextFireTime = ctList[0].NextFireTime;
                model.TimeZoneSidKey = ctList[0].TimeZoneSidKey;
            }
            model.rm.isError = false;
        }catch (Exception e) {
            model.rm.messages.add('findRunningAsyncJob == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        
        return model;
    }
    
    @AuraEnabled
    public static WellsFargoModel getWellsFargoDealers(){
        WellsFargoModel wfm = new WellsFargoModel();
        try {
            wfm.wfDealers = TSGCFG__Wells_Fargo_Dealer__c.getAll().Values();
            wfm.rm.isError = false;
        } catch (Exception e) {
            wfm.rm.messages.add('getWellsFargoDealers == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        return wfm;
    }
    
    @AuraEnabled
    public static ResponseModel saveWellsFargoDealers(List<TSGCFG__Wells_Fargo_Dealer__c> wfDealers, List<String> dealersToDelete){
        ResponseModel rm = new ResponseModel();
        try {
            if(dealersToDelete != null && dealersToDelete.size()>0)
                delete [select id from TSGCFG__Wells_Fargo_Dealer__c where Id in:dealersToDelete];
            
            upsert wfDealers;
            
            rm.isError = false;
            rm.messages.add('Saved Successfully');
        } catch (Exception e) {
            rm.messages.add('saveWellsFargoDealers == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        return rm;
    }
    
    @AuraEnabled
    public static WellsFargoModel getWellsFargoSettings(){
        WellsFargoModel wfm = new WellsFargoModel();
        try {
            wfm.wfSetting = TSGCFG__Wells_Fargo_Setting__c.getOrgDefaults();
            wfm.rm.isError = false;
        } catch (Exception e) {
            wfm.rm.messages.add('getWellsFargoSettings == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        return wfm;
    }
    
    @AuraEnabled
    public static ResponseModel saveWellsFargoSettings(TSGCFG__Wells_Fargo_Setting__c wfSetting){
        ResponseModel rm = new ResponseModel();
        try {
            upsert wfSetting;
            rm.isError = false;
            rm.messages.add('Saved Successfully');
        } catch (Exception e) {
            rm.messages.add('saveWellsFargoSettings == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        return rm;
    }
    @AuraEnabled
    public static ResponseModel submitCreditAppToAPI(TSGCFG__Wells_Fargo_Setting__c wfSetting, String body){
        return submitHTTPRequest(wfSetting, body, 'PartnerCreditAppSvcX', 'GET');
    }
    
    @AuraEnabled
    public static ResponseModel submitHTTPRequest(TSGCFG__Wells_Fargo_Setting__c wfSetting, String body, String endPointPath, String requestType){
        ResponseModel rm = new ResponseModel();
        system.debug('-------------------------------Location 1');
        try {
            Blob headerValue = Blob.valueOf(wfSetting.TSGCFG__Username__c+':'+wfSetting.TSGCFG__Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            
            
            HttpRequest req = new HttpRequest();
            if(!Test.isRunningTest())
                req.setClientCertificateName(wfSetting.TSGCFG__Signed_Certificate_Name__c);
            req.setHeader('Content-Type','application/xml');
            req.setHeader('Authorization', authorizationHeader);
            req.setMethod(requestType);
            //String partnerReferenceId = 'STUV7X67RC15';
            req.setBody(body);
            req.setEndpoint(wfSetting.TSGCFG__Endpoint__c+'/'+endPointPath);
            system.debug('@@@=='+endPointPath);
           system.debug('@@@=='+body);
           system.debug('@@@=='+body);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            system.debug('@@@=='+res.getBody());
            rm.messages.add(res.getBody());
            rm.isError = false;
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            rm.messages.add('endPointPath == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }
        return rm;
    }
    
    @AuraEnabled
    public static ResponseModel scheduleWellsFargoSync(String interval){
        ResponseModel rm = new ResponseModel();
        try{
            if(String.isNotBlank(interval)){
                ResponseModel rm2 = deleteWellsFargoScheduler(jobNames);                        
                if(rm2.isError)
                    return rm2;
                Integer i=1;
                if(interval == '15 minutes')
                    System.schedule('SchedulerWellsFargoSync Job '+ (i++) +' - '+interval, '0 15 * * * ?', new SchedulerWellsFargoSync());
                if(interval == '15 minutes' || interval == '30 minutes')
                    System.schedule('SchedulerWellsFargoSync Job '+ (i++) +' - '+interval, '0 30 * * * ?', new SchedulerWellsFargoSync());
                if(interval == '15 minutes')
                    System.schedule('SchedulerWellsFargoSync Job '+ (i++) +' - '+interval, '0 45 * * * ?', new SchedulerWellsFargoSync());
                
                System.schedule('SchedulerWellsFargoSync Job '+ (i++) +' - '+interval, '0 0 * * * ?', new SchedulerWellsFargoSync());
                
                rm.isError = false;
                rm.messages.add('Scheduled Successfully');
            }else{
                rm.messages.add('Please select job interval.');
            }
        }catch(Exception e){
            rm.messages.add('scheduleWellsFargoSync == '+(e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }  
        return rm;
    }
    
    public static ResponseModel deleteWellsFargoScheduler(List<String> jobNames){
        ResponseModel rm = new ResponseModel();
        try{
            boolean schedulerRunning = false;
            List<CronTrigger> lstcron = [SELECT Id,State FROM CronTrigger where CronJobDetail.Name like: jobNames];
            for (CronTrigger c : lstcron) 
            {
                if(c.State == 'EXECUTING')
                    schedulerRunning = true;
            }  
            
            if(!schedulerRunning){
                for(cronTrigger c : lstcron)
                    System.abortJob(c.Id);
                
                rm.isError = false;
            }else{
                rm.messages.add('Scheduler is running.');
            }
        }catch(Exception e){
            rm.messages.add('deleteWellsFargoScheduler == '+ (e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
        }  
        return rm;
    }
    
    public class ResponseModel{
        @AuraEnabled public Boolean isError=true;
        @AuraEnabled public String returnRecordId;
        @AuraEnabled public String returnObjectApiName;
        @AuraEnabled public List<String> messages = new List<String>();
    }
    
    public class WellsFargoModel{
        @AuraEnabled public ResponseModel rm = new ResponseModel();
        @AuraEnabled public TSGCFG__Wells_Fargo_Setting__c wfSetting;
        @AuraEnabled public List<TSGCFG__Wells_Fargo_Dealer__c> wfDealers;
        @AuraEnabled public TSGADX__Deal__c deal;
        @AuraEnabled public TSGCFG__Wells_Fargo_Dealer__c dealer;
        //added on 16-12-2021 to send dealOwner or LoggedInUser based on WF setting 
        @AuraEnabled public user dealOwnerOrLoggedInUser;//end 16-12-2021
        @AuraEnabled public String stateCode;
        @AuraEnabled public String defaultDealerId;
        @AuraEnabled public String partnerDealerId;
        @AuraEnabled public String relationshipType;
        @AuraEnabled public String companyType;
        @AuraEnabled public String requestedAmount;
        @AuraEnabled public String requestedTerm;
    }
    
    public class AsyncJobStatus{
        @AuraEnabled public ResponseModel rm = new ResponseModel();
        @AuraEnabled public String message;
        @AuraEnabled public Datetime NextFireTime;
        @AuraEnabled public String TimeZoneSidKey;
    }
    
    public static String getBodyForSubmitCreditApplication(WellsFargoModel wfm) {
        String postalCode ;
        if (wfm.deal.TSGADX__Company__c != null  && wfm.deal.TSGADX__Company__r.BillingPostalCode != null ) {  
            postalCode = wfm.deal.TSGADX__Company__r.BillingPostalCode;
            postalCode = postalCode.replaceAll('[^0-9]', '');
            postalCode = postalCode.substring(postalCode.length() - 5);
        }else{
            postalCode = '';
        }

        String body = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:par="http://partnercredit.wellsfargo.com" xmlns:wfh="http://wfheader.wellsfargo.com">'+
            '<soapenv:Header/>'+
            '<soapenv:Body>'+
            '<par:CreditApplication>'+
            '<wfh:WFHeader>'+
            '<HeaderVersion xmlns="">1</HeaderVersion>'+
            '<InterfaceId xmlns="">PartnerCreditService.submitCreditApplication</InterfaceId>'+
            '<SourceAppId xmlns="">AgentDealer</SourceAppId>'+
            '<Operation xmlns="">submitCreditApplication</Operation>'+
            '</wfh:WFHeader>'+
            
            '<PartnerReferenceId xmlns="">'+wfm.wfSetting.TSGCFG__Partner_Reference_Id__c+'</PartnerReferenceId>'+
            '<Customer xmlns="">'+
            '<CustomerParty>'+
            '<RelationshipType>'+wfm.relationshipType+'</RelationshipType>'+
            '<CompanyType>'+wfm.companyType+'</CompanyType>'+
            '<Business>'+
            '<Name>'+wfm.deal.TSGADX__Company__r.Name.replaceAll('[^a-zA-Z0-9]', ' ')+'</Name>'+
            '<LegalEntity>Corporation</LegalEntity>'+
            '<Phone>'+(wfm.deal.TSGADX__Company__r.Phone!=null ? wfm.deal.TSGADX__Company__r.Phone : '') +'</Phone>'+
            '</Business>'+
            '<Consenting>true</Consenting>'+
            '<ListOfAddresses>'+
            '<Address>'+
            '<StreetAddress>'+(wfm.deal.TSGADX__Company__r.BillingStreet != null ? wfm.deal.TSGADX__Company__r.BillingStreet : '')+'</StreetAddress>'+
            '<City>'+(wfm.deal.TSGADX__Company__r.BillingCity != null ? wfm.deal.TSGADX__Company__r.BillingCity : '')+'</City>'+
            '<State>'+(wfm.stateCode != null ? wfm.stateCode : '')+'</State>'+
            '<Zip>'+postalCode+'</Zip>'+
            //'<Country>'+(wfm.deal.TSGADX__Business_Country__c != null ? wfm.deal.TSGADX__Business_Country__c : '')+'</Country>'+ //commented on 29-9-2021 as need to send USA as country only
            '<Country>USA</Country>'+
                        /*
            '<StreetAddress>14 Gerling St.</StreetAddress>'+
            '<City>Schenectady</City>'+
            '<State>NY</State>'+
            '<Zip>12345</Zip>'+
            '<Country>USA</Country>'+
            */
            '</Address>'+
            '</ListOfAddresses>'+
            '</CustomerParty>'+
            '</Customer>'+
            '<Dealer xmlns="">'+
            
            '<Id>'+wfm.dealer.Name+'</Id>'+
            '<Name>'+wfm.dealer.TSGCFG__Dealer_Id__c+'</Name>'+
            '<ListOfContacts>'+
            '<Contact>'+
            '<FirstName>'+wfm.dealOwnerOrLoggedInUser.FirstName+'</FirstName>'+
            '<LastName>'+wfm.dealOwnerOrLoggedInUser.LastName+'</LastName>'+
            '<Email>'+wfm.dealOwnerOrLoggedInUser.Email+'</Email>'+
            
            '</Contact>'+
            
            '</ListOfContacts>'+
            
            '<PartnerDealerId>'+wfm.dealer.TSGCFG__Dealer_Id__c+'</PartnerDealerId>'+
            '<PartnerDealerType></PartnerDealerType>'+ //'+wfm.partnerDealerType+'
            '</Dealer>'+
                        
                        /*'<ListOfAssociatedParties xmlns="">'+
            '<AssociatedParty>'+
            '<RelationshipType>Guarantor</RelationshipType>'+
            '<CompanyType>Personal</CompanyType>'+
            '<Person>'+
            
            '<FirstName>MICHAEL</FirstName>'+
            '<LastName>Smith</LastName>'+
            '<SSN>799636322</SSN>'+
            '<DateOfBirth>1970-06-08</DateOfBirth>'+
            '</Person>'+
            '<Consenting>true</Consenting>'+
            '<ListOfAddresses>'+
            '<Address>'+
            '<StreetAddress>800 Lincoln RD</StreetAddress>'+
            '<City>HUNTSVILLE</City>'+
            '<State>MI</State>'+
            '<Zip>48803</Zip>'+
            '<Country>USA</Country>'+
            '</Address>'+
            '</ListOfAddresses>'+
            '<OwnershipPct>50</OwnershipPct>'+
            
            '</AssociatedParty>'+
            '</ListOfAssociatedParties>'+*/
            '<Submittal xmlns="">'+
            '<ApplicationRecvDate>'+Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')+'</ApplicationRecvDate>'+//'+Datetime.now()+' 2021-02-01T10:49:11
            '<RequestedAmount>'+wfm.requestedAmount+'</RequestedAmount>'+
            '<RequestedTerm>'+wfm.requestedTerm+'</RequestedTerm>'+
            '</Submittal>'+
            
            '</par:CreditApplication>'+
            '</soapenv:Body>'+
            '</soapenv:Envelope>';
        
        return body;
    }
    
    @AuraEnabled
    public static string getBodyForSyncAppStatus(String appNumber){
        String body =   '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:par="http://partnercreditappstatus.wellsfargo.com" xmlns:wfh="http://wfheader.wellsfargo.com">' +
            '<soapenv:Header/>' +
            '<soapenv:Body>' +
            '<par:getCreditApplicationStatus>' +
            '<wfh:WFHeader>' +
            '<HeaderVersion>1</HeaderVersion>' +
            '<InterfaceId>PartnerCreditAppStatusService.getCreditApplicationStatus</InterfaceId>' +
            '<SourceAppId>AgentDealer</SourceAppId>' +
            '<Operation>getCreditApplicationStatus</Operation>' +
            '</wfh:WFHeader>' +
            //'<par:PartnerReferenceId>B2B-'+appNumber+'</par:PartnerReferenceId>'+
            '<par:AcknowledgementId>B2B-'+appNumber+'</par:AcknowledgementId>' +
            '</par:getCreditApplicationStatus>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>';
        return body;
    }
    
    @AuraEnabled
    public static ResponseModel syncCreditAppFromAPI(TSGCFG__Wells_Fargo_Setting__c wfSetting, String body){
        return submitHTTPRequest(wfSetting, body, 'PartnerCreditAppStatusSvcX', 'GET');
    }
    
    @AuraEnabled
    public static ResponseModel syncCreditAppStatus(Id recordId){
        ResponseModel rm = new ResponseModel();
        List<TSGCFG__Credit_Application__c> creditApps;
        try {
            if(string.isBlank(recordId))
                rm.messages.add('Invalid Credit Application.');
            else{
                creditApps = [select id, Name, TSGCFG__Status__c, TSGCFG__Last_Synced__c  
                              from TSGCFG__Credit_Application__c where id=:recordId];
                if(creditApps.size()==0)
                    rm.messages.add('Credit Application not found, please contact your administrator.');
            }
            
            if(rm.messages.size()==0){
                TSGCFG__Wells_Fargo_Setting__c wfSetting = TSGCFG__Wells_Fargo_Setting__c.getOrgDefaults();
                ResponseModel rm2 = validateWFSetting(wfSetting);
                if(rm2.isError)
                    rm.messages.addAll(rm2.messages);
                else{
                    rm = fetchCreditAppStatus(creditApps, wfSetting)[0];
                }
            }
        } catch (Exception e) {
            rm.messages.add('syncCreditAppStatus == '+ (e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
            //throw new AuraHandledException(e.getMessage());
        }
        
        return rm;
    }
    
    @AuraEnabled
    public static List<ResponseModel> fetchCreditAppStatus(List<TSGCFG__Credit_Application__c> creditApps, TSGCFG__Wells_Fargo_Setting__c wfSetting){
        List<ResponseModel> rmList = new List<ResponseModel>();
        ResponseModel rm = new ResponseModel();
        try{
            Map<Id, ContentVersion> appCVMap = new Map<Id, ContentVersion>();
            Map<Id,String> documentNameMap = new Map<Id,String>();
            Set<String> documentNames = new Set<String>();
            
            for(TSGCFG__Credit_Application__c creditApp:creditApps){
                rm = new ResponseModel();
                
                String reqBody = getBodyForSyncAppStatus(creditApp.Name);
                ResponseModel rm2 = syncCreditAppFromAPI(wfSetting, reqBody);
                
                if(!rm2.isError){
                    creditApp.TSGCFG__Last_Synced__c = Datetime.now();
                    String currentStatus;
                    String decisionDate;
                    String approvalNumber;
                    String approvalAmount;
                    String content;
                    String attachmentName;
                    
                    Dom.Document doc = new Dom.Document();  
                    doc.load(rm2.messages[0]);  
                    //String dummyData = '';
                    //doc.load(dummyData);
                    Dom.XMLNode rootElement = doc.getRootElement();  
                    for ( Dom.XMLNode childElement : rootElement.getChildElements() ) {  
                        
                        for ( Dom.XMLNode detailElement : childElement.getChildElements() ){
                            if(detailElement.getName() == 'ServiceException'){
                                //rm.messages.add('Credit App: '+creditApp.Name);
                                for ( Dom.XMLNode exElement : detailElement.getChildElements() ){
                                    if(exElement.getName() == 'faultDetails'){
                                        rm.messages.add('Credit App: '+creditApp.Name+', '+exElement.getChildElement('faultCode', 'http://partnercreditappstatus.wellsfargo.com').getText() +'=='+exElement.getChildElement('messages', 'http://partnercreditappstatus.wellsfargo.com').getText());
                                        if(exElement.getChildElement('messages', 'http://partnercreditappstatus.wellsfargo.com').getText() != null 
                                           && exElement.getChildElement('messages', 'http://partnercreditappstatus.wellsfargo.com').getText().containsIgnoreCase('Decision In Progress')){
                                               creditApp.TSGCFG__Status__c = 'Decision In Progress'; 
                                           }
                                        
                                    }
                                    
                                }
                            }
                            
                            if(detailElement.getName() == 'Fault'){
                                rm.messages.add('Credit App: '+creditApp.Name+', '+detailElement.getChildElement('faultcode', null).getText() +'=='+detailElement.getChildElement('faultstring', null).getText());
                            }
                            
                            if(detailElement.getName() == 'getCreditApplicationStatusResponse'){
                                for ( Dom.XMLNode exElement : detailElement.getChildElements() ){
                                    if(exElement.getName() == 'CreditDecisionInformation'){
                                        currentStatus = exElement.getChildElement('CreditDecision', 'http://partnercreditappstatus.wellsfargo.com').getText();
                                        if(exElement.getChildElement('DecisionDate', 'http://partnercreditappstatus.wellsfargo.com') != null)
                                            decisionDate = exElement.getChildElement('DecisionDate', 'http://partnercreditappstatus.wellsfargo.com').getText();
                                        if(exElement.getChildElement('ApprovalNumber', 'http://partnercreditappstatus.wellsfargo.com') != null)
                                            approvalNumber = exElement.getChildElement('ApprovalNumber', 'http://partnercreditappstatus.wellsfargo.com').getText();
                                        if(exElement.getChildElement('ApprovalAmount', 'http://partnercreditappstatus.wellsfargo.com') != null)
                                            approvalAmount = exElement.getChildElement('ApprovalAmount', 'http://partnercreditappstatus.wellsfargo.com').getText();
                                    }
                                    
                                    if(exElement.getName() == 'Attachment'){
                                        content = exElement.getChildElement('Content', 'http://partnercreditappstatus.wellsfargo.com').getText();
                                        attachmentName = exElement.getChildElement('AttachmentName', 'http://partnercreditappstatus.wellsfargo.com').getText();
                                    }
                                }
                            }
                        }   
                    }
                    if(rm.messages.size()==0 && String.isNotBlank(currentStatus)){
                        creditApp.TSGCFG__Status__c = currentStatus; 
                        
                        if(String.isNotBlank(approvalAmount))
                            creditApp.TSGCFG__Approved_Amount__c = Double.ValueOf(approvalAmount);
                        if(String.isNotBlank(decisionDate) && decisionDate.contains('T'))
                            creditApp.TSGCFG__Decision_Date__c = Datetime.valueOf(decisionDate.replace('T',' '));
                        if(String.isNotBlank(approvalNumber))
                            creditApp.TSGCFG__Approval_Number__c = approvalNumber;
                        
                        if(String.isNotBlank(content) && String.isNotBlank(attachmentName)){
                            String fileName = 'B2B-'+creditApp.Name+'_'+currentStatus;
                            system.debug('@@@==attachmentName'+attachmentName);
                            String fileExtension = attachmentName.split('\\.')[attachmentName.split('\\.').size()-1];
                            appCVMap.put(creditApp.Id,getContentVersion(content,fileName,fileExtension));
                            
                            documentNameMap.put(creditApp.Id, 'B2B-'+creditApp.Name);
                            documentNames.add('B2B-'+creditApp.Name+'%');
                        }
                        
                        
                        rm.messages.add('Current Status: "'+currentStatus+'", Application '+creditApp.Name+' Synced successfully!');
                        rm.isError = false;
                    }
                }else{
                    rm.messages.addAll(rm2.messages);
                }
                rmList.add(rm);
            }
            update creditApps;
            
            if(appCVMap.size()>0){
                //finding exisitng document synced from wells fargo
                //for delition purpose
                //FYI, delete action will be performed at the end
                //after making sure new document has been synced
                
                //first fetch content document link with Credit Application Id
                Map<Id,ContentDocumentLink> cdMap = new Map<Id,ContentDocumentLink>();
                for(ContentDocumentLink cdl: [select id,ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId in:documentNameMap.keySet()]){
                    cdMap.put(cdl.ContentDocumentId,cdl);
                }
                
                //Then fetching Content Version with ContentDocumentId 
                //and matching file name starts with B2B-#ApplicationNumber
                //If ContentDocument parent application's file name matches with ContenVersion filename/pathonclient
                //Then adding its ContentDocument in a List to delete later
                List<ContentDocument> cdList = new List<ContentDocument>();
                if(cdMap.size()>0){
                    for(ContentVersion cv: [select id,ContentDocumentId,PathOnClient from ContentVersion where ContentDocumentId in:cdMap.keySet() AND PathOnClient like: documentNames]){
                        String fileName = documentNameMap.get(cdMap.get(cv.ContentDocumentId).LinkedEntityId);
                        
                        if(fileName != null && cv.PathOnClient.startsWith(fileName))
                            cdList.add(new ContentDocument(id=cv.ContentDocumentId));
                    }
                }
                
                //inserting latest document's ContentVersion data
                insert appCVMap.values();
                
                //fetching ContentDocumentId for the created ContentVersion
                Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>();
                for(ContentVersion cv:[SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id in:appCVMap.values()]){
                    cvMap.put(cv.Id,cv);
                }
                
                //Creating ContentDocumentLink for the files
                Map<Id,ContentDocumentLink> cdlMap = new Map<Id,ContentDocumentLink>();
                
                for(Id appId:appCVMap.keySet()){
                    //Create ContentDocumentLink
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cvMap.get(appCVMap.get(appId).Id).ContentDocumentId;
                    cdl.LinkedEntityId = appId; // you can use objectId,GroupId etc
                    cdl.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
                    //cDe.Visibility = 'InternalUsers';
                    cdlMap.put(cdl.Id, cdl);
                }
                
                //finally inserting ContentDocumentLink to relate document with Application record
                if(cdlMap.size()>0)
                    insert cdlMap.values();
                
                //finally deleting old documents synced from wells fargo
                if(cdList.size()>0)
                    delete cdList;
            }
        } catch (Exception e) {
            rm.isError = true;
            rm.messages.add('syncCreditAppStatus == '+ (e.getTypeName()+', '+e.getMessage()+', at line '+e.getLineNumber()));
            rmList.add(rm);
            //throw new AuraHandledException(e.getMessage());
        }
        
        return rmList;
    }
    
    public static ContentVersion getContentVersion(String fileBody, String fileName, String fileExtension){
        //String yourFiles = 'Lets assume this is your binary string of the files';
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVer.PathOnClient = fileName+'.'+fileExtension; //'ionicLogo.png'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = fileName;//'Proposal '; // Display name of the files
        conVer.VersionData = EncodingUtil.base64Decode(fileBody); // converting your binary string to Blog
        return conVer;
    }
    
    public static ResponseModel validateWFSetting(TSGCFG__Wells_Fargo_Setting__c wfSetting){
        ResponseModel rm = new ResponseModel();
        
        if(wfSetting == null || wfSetting.Id==null)
            rm.messages.add('API settings not found, please contact your administrator.');
        else{
            if(wfSetting.TSGCFG__Endpoint__c == null)
                rm.messages.add('API Endpoint missing, please contact your administrator.');
            if(wfSetting.TSGCFG__Partner_Reference_Id__c == null)
                rm.messages.add('API Partner Refernce Id not found, please contact your administrator.');
            if(wfSetting.TSGCFG__Username__c == null)
                rm.messages.add('API Username missing, please contact your administrator.');
            if(wfSetting.TSGCFG__Password__c == null)
                rm.messages.add('API Password missing, please contact your administrator.');
            if(wfSetting.TSGCFG__Signed_Certificate_Name__c == null)
                rm.messages.add('API Signed Certificate Name missing, please contact your administrator.');
        }
        
        if(rm.messages.size()==0)
            rm.isError = false;
        
        return rm;
    } 
}