import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getIntegrationSettings from '@salesforce/apex/CW_UI_V2_Controller.getIntegrationSettings';
import getOrgDetailsStatic  from '@salesforce/apex/CW_UI_V2_Controller.getOrgDetailsStatic';
import getApiUsageViaRest  from '@salesforce/apex/CW_UI_V2_Controller.getApiUsageViaRest';
import getDailySuccessLog  from '@salesforce/apex/CW_UI_V2_Controller.getSuccessLogSummaryMap';
import getCWIntegration  from '@salesforce/apex/CW_UI_V2_Controller.getCWSettingsMapReadOnly';
import getCWConnSettings  from '@salesforce/apex/CW_UI_V2_Controller.getDefaultConnectwiseConnection';
import logImpersonation  from '@salesforce/apex/CW_UI_V2_Controller.logImpersonation';
import getCurrUserInfo  from '@salesforce/apex/CW_UI_V2_Controller.getCurrUserInfo';

import getOrgInfo from '@salesforce/apex/impersonateAPIUser.getOrgInfo';
import userId from '@salesforce/user/Id';
import impICON from '@salesforce/resourceUrl/impersonationIcon';
import impLOICON from '@salesforce/resourceUrl/impersonationLogoutIcon';
import adLogo from '@salesforce/resourceUrl/ADLogoMini';
import cwLogo from '@salesforce/resourceUrl/CWLogoMini';

export default class CwTabbedDisplay extends LightningElement {
    isLoading=true;
    LIAURL = ''; 
    impIconUrl = impICON;
    impLOIconUrl = impLOICON;
    adLogo = adLogo;
    cwLogo = cwLogo;
    RETPage = `/lightning/n/TSGCW__AgentDealer_ConnectWise_Integration?oid=${userId}`;
    isCurrentUserAPIUser = false;
    currentUserId = userId;
    apiRequiredMsg = `This Tab Requires the API User.\nLog in as the API User and Try Again.\n\nUse the <img src="${this.impIconUrl}" width="24" height="24" /> to the right; to impersonate te API User. `;
    blinkActive = false;
    @track statusMessage = 'No New Messages';
    @track isExpanded = false;
    @track activeTab = 'status';
    @track showTooltip = false;
    @track tooltipText = '';
    @track tooltipStyle = '';
    @track userProfile = {};
    @track connTest ={ label: 'Connection Result', value:''};
    @track cwIntegrationSettings=[];
    @track companyData ={};
    @track globalData = {
        version: 1,
        originalUserId: '',
        integrationStatus: 'Connected',
        syncSettings: { syncNow: false },
        integrationSettings:{},
        dailySuccessLogs:{}

    };
    async connectedCallback() {
        document.title='Agent J\'s CW v2';
        const match = window.location.href.match(/[?&]oid=([a-zA-Z0-9]{15,18})/);
        const originalId = match ? match[1] : null;
    
        if (originalId) {
            console.log('✅ Captured originalUserId from URL:', originalId);
            this.globalData.originalUserId = originalId;
            sessionStorage.setItem('originalUserId', originalId);
        } else if (!this.globalData.originalUserId) {
            // Only use sessionStorage fallback if not already set
            const stored = sessionStorage.getItem('originalUserId');
            if (stored) {
                this.globalData.originalUserId = stored;
                console.log('♻️ Restored originalUserId from sessionStorage:', stored);
            } else {
                console.warn('⚠️ No originalUserId found in URL or session');
            }
        }
        this.isLoading = true;
        console.log('oid ' + this.globalData.originalUserId + ' vs ' + this.currentUserId);
        const mkUserId = this.globalData.originalUserId||this.currentUserId;
        try {
            await Promise.all([
                this.loadCompanyData(),
                this.loadDailySuccessLogs(),
                this.loadCWIntegration(),
                this.buiildUserProfile(mkUserId)
            ]);
        } catch (error) {
            console.error('⚠️ Error during load:', error);
        } finally {
            setTimeout(()=>{this.isLoading = false;},0);
        }
    }
     
    @wire(getOrgInfo)
    wiredSetting({ error, data }) {
        if (data) {
            const userId = data.apiUser; 
            const orgId = data.orgId;  
            const domain = window.location.origin; 

            if (userId) {
                const truncatedApiUserId = data.apiUser.substring(0, 15); 
                console.log('truncatedApiUserId: ' + truncatedApiUserId);
                const truncatedCurrentUserId = this.currentUserId.substring(0, 15);
                console.log('truncatedCurrentUserId: ' + truncatedCurrentUserId);

                this.isCurrentUserAPIUser = (truncatedCurrentUserId === truncatedApiUserId);
                if(this.isCurrentUserAPIUser==true){this.setStatusMessage('Impersonating the API User.');}
                if (userId && orgId) {
                    this.LIAURL = `${domain}/servlet/servlet.su?oid=${orgId}&suorgadminid=${userId}&retURL=%2F005%3FisUserEntityOverride%3D1%26retURL%3D${encodeURIComponent(this.RETPage)}%26appLayout%3Dsetup%26tour%3D%26isdtp%3Dp1%26sfdcIFrameOrigin%3D${domain}%26sfdcIFrameHost%3Dweb&targetURL=${encodeURIComponent(this.RETPage)}#tab1`;
                } else {
                    console.warn('Unable to construct LIAURL due to missing userId or orgId.');
                }
            } else {
                console.warn('API User is not set in the custom settings.');
                this.isCurrentUserAPIUser = true;  
            }
        } else if (error) {
            console.error('Error fetching custom setting: ', error);
        }
    }

    @wire(getIntegrationSettings)
    wiredSettings({ error, data }) {
        if (data) {
            this.globalData = {
                ...this.globalData,
                integrationSettings: data
            };
        } else if (error) {
            console.error('Error retrieving settings:', error);
        }
    }
    async loadCWIntegration() {
        try {
            const resultMap = await getCWIntegration();

            // Convert the map of wrappers to a sorted array of display objects
            this.cwIntegrationSettings = Object.keys(resultMap)
                .map(key => {
                    const setting = resultMap[key];
                    return {
                        key: key,                        
                        label: this.getLabelForIntegrationKey(key),
                        value: setting.value,
                        category: setting.category,
                        order: setting.order,
                        title: this.getTitleForIntegrationKey(key),
                        apiname:setting.apiname,
                        recordid:setting.recordId,
                    };
                })
                .sort((a, b) => a.order - b.order); 
                const conntestItem = this.cwIntegrationSettings.find(item => item.key === 'conntest');
                let newVal = this.getTestResults(conntestItem.value);
                if (conntestItem) {
                    conntestItem.value = newVal || 'No result';
                }

            console.log('CW Integration Settings:', this.cwIntegrationSettings);
            console.log('Enable Price Book:', this.syncProducts);
        } catch (error) {
            console.error('⚠️ Error loading CW settings:', error);
        }
    }
    async loadDailySuccessLogs(){
       // console.log('---------------------------------------DAILY LOG: WORKING' );
        getDailySuccessLog()
        .then(result => {
           // console.log('---------------------------------------DAILY LOG:' + result);
            this.globalData.dailySuccessLogs = result;
           // this.globalData = {
            //    ...this.globalData,
            //    dailySuccessLogs: result
            //};


        })
        .catch(error => {
            console.error('Error retrieving success logs:', error);
        });
    }

    async loadCompanyData() {
        try {
            const [orgDetails, apiUsage] = await Promise.all([
                getOrgDetailsStatic(),
                getApiUsageViaRest()
            ]);

            this.companyData = { ...orgDetails, ...apiUsage };
            console.log('companyData:', JSON.stringify(this.companyData));
        } catch (error) {
            console.error('Error loading company data:', error);
        }
    }

    async buiildUserProfile(uid){
        if(uid){
            try {
            const result = await getCurrUserInfo({ userId: uid });
            if (result) {
                this.userProfile = {
                    fullName: result.fullName,
                    profileName: result.profileName,
                    roleName: result.roleName,
                    emailAddress: result.emailAddress,
                    lastLogin: result.lastLogin
                };
            }
            console.log('UP:' + this.userProfile);
        } catch (error) {
            console.error('Error fetching user profile:', error);
        }
        }
    } 
    get syncProducts() {
        const match = this.cwIntegrationSettings?.find(setting => setting.key === 'sf2cwEnablePriceBookListSync');
        return match?.value === 'Enabled';
    }
    showHomeTooltip(event) {
        this.showCustomTooltip(event, 'The Home Tab\n\nFrom here you can view you current staus, usage, succes rate.');
    }

    showConfTooltip(event) {
        let msg = 'The System Configuration\n\nHere you can see and or set the global settings\nSuch as you End Point\nAssigned API User,\nFast Send and Fast Refresh Rates.\nThis powerful tool should be managed with care.';
        if(!this.isCurrentUserAPIUser){
            msg = this.apiRequiredMsg;
        }
        this.showCustomTooltip(event,msg );
    }

    showSyncTooltip(event) {
        let msg =  'The Manual Sync\n\nFrom here you can manually\nPush to ConnectWise or Pull From ConnectWise.\nYou can also choose to full Push and Pull Sync\nand run it at the object level.\n You can manually select your filters at the object level.\nYou can watch the progress and view a report when the action is finished.\n This a great tool for testing and determining the best way to fine tune your Strategic Schedule.';
        if(!this.isCurrentUserAPIUser){
            msg = this.apiRequiredMsg;
        }
        this.showCustomTooltip(event, msg );
    }

    showScheduleTooltip(event) {
        let msg = 'The Scheduler\n\nFrom here you can select various scheduling strategies.\nYou will see recommendations and sample strategies.\nYou can also set the customized filtering at the object level.\nYou can also view you current schedules, details and change or remove sheduled syncs.'
        if(!this.isCurrentUserAPIUser){
            msg = this.apiRequiredMsg;
        }
      
        this.showCustomTooltip(event, msg);
    }

    showMappingTooltip(event) {
        let msg = 'The Mapping\n\nFrom here you can select various scheduling strategies.\nYou will see recommendations and sample strategies.\nYou can also set the customized filtering at the object level.\nYou can also view you current schedules, details and change or remove sheduled syncs.'
        if(!this.isCurrentUserAPIUser){
            msg = this.apiRequiredMsg;
        }
      
        this.showCustomTooltip(event, msg);
    }

    hideTooltip() {
        this.showTooltip = false;
    }

    showCustomTooltip(event, text) {
        console.log('isCurrentUserAPIUser' + this.isCurrentUserAPIUser);
        let yVar = 130;
        if(this.isCurrentUserAPIUser){
            yVar =180;
        }
        const rect = event.target.getBoundingClientRect();
        this.tooltipStyle = `top: ${rect.bottom + window.scrollY - yVar}px; left: ${rect.left + window.scrollX+(rect.width/2 -10)}px;`;
        this.showTooltip = true;
        setTimeout(() => { // slight delay to ensure DOM is ready
            const tooltipDiv = this.template.querySelector('.tooltip-container');
            if (tooltipDiv) {
                tooltipDiv.innerHTML = text.replace(/\n/g, '<br/>');
            }
        }, 0);
    }

    get showStatus() {
        return this.activeTab === 'status';
    }
    get showSystem() {
        return this.activeTab === 'system';
    }
    get showSync() {
        return this.activeTab === 'sync';
    }
    get showScheduler() {
        return this.activeTab === 'scheduler';
    }
    get showMapping() {
        return this.activeTab === 'mapping';
    }


    get getTabClassStatus() {
        return this.activeTab === 'status' ? 'tab-item active' : 'tab-item';
    }
    get getTabClassSystem() {
        if(!this.isCurrentUserAPIUser){
            return 'tab-item disabled';
        } else{
            return this.activeTab === 'system' ? 'tab-item active' : 'tab-item';
        }
    }
    get getTabClassSync() {
         if(!this.isCurrentUserAPIUser){
            return 'tab-item disabled';
        } else{
            return this.activeTab === 'sync' ? 'tab-item active' : 'tab-item';
        }
    }
    get getTabClassScheduler() {
        if (!this.isCurrentUserAPIUser) {
            return 'tab-item disabled';
        } else {
            return this.activeTab === 'scheduler' ? 'tab-item active' : 'tab-item';
        }
    }
    get getTabClassMapping() {
        if (!this.isCurrentUserAPIUser) {
            return 'tab-item disabled';
        } else {
            return this.activeTab === 'mapping' ? 'tab-item active' : 'tab-item';
        }
    }
    get getImpersonationLogoutIconClass(){
       // let tClass= this.isCurrentUserAPIUser?'icon-button impersonate-icon':'hide-icon';
        if(this.isCurrentUserAPIUser){ 
            return 'icon-button impersonate-icon';
        }else {
            return 'hide-icon';
        }
    }
    get getImpersonationIconClass(){
       //let tClass= this.isCurrentUserAPIUser?'hide-icon':'icon-button impersonate-icon';
       // console.log('tClass: ' + tClass);
        //return tClass;
        if(!this.isCurrentUserAPIUser){ 
            return 'icon-button impersonate-icon';
        }else {
            return 'hide-icon';
        }
    }

    handleStatusClick() {
        this.activeTab = 'status';
    }
    handleSystemClick() {
        this.activeTab = this.isCurrentUserAPIUser?'system':'status';
    }
    handleSyncClick() {
        this.activeTab = this.isCurrentUserAPIUser?'sync':'status';
    }
    handleSchedulerClick() {
         console.log('📆 Scheduler tab clicked');
        this.activeTab = this.isCurrentUserAPIUser?'scheduler':'status';
        setTimeout(() => this.refreshSchedulerTab(), 10); // call after render
    }
    handleMappingClick() {
         console.log('🗺️ Mapping tab clicked');
        this.activeTab = this.isCurrentUserAPIUser?'mapping':'status';
    }
    refreshActiveTab() {
        switch (this.activeTab) {
            case 'status':
                this.refreshStatusTab();
                break;
            case 'system':
                this.refreshSystemTab();
                break;
            case 'sync':
                this.refreshSyncTab();
                break;
            case 'scheduler':
                this.refreshSchedulerTab();
                break;
           case 'mapping':
                this.refreshMappingTab();
                break;
        }
    }
    refreshStatusTab() {
        console.log('Refreshing Status Tab...');
        // e.g. reload data, toggle UI state, or call child method
    }
    
    refreshSystemTab() {
        console.log('Refreshing System Tab...');
        if (this.activeTab === 'system') {
            const child = this.template.querySelector('c-system-configuration');
            if (child && typeof child.refreshData === 'function') {
                child.refreshData();
            } else {
                console.warn('⚠️ c-system-configuration not found or not ready');
            }
        }
    }
    
    refreshSyncTab() {
        console.log('Refreshing Sync Tab...');
        if (this.activeTab === 'sync') {
            const child = this.template.querySelector('c-manual-sync-lwc');
            if (child && typeof child.refreshData === 'function') {
                child.refreshData();
            } else {
                console.warn('⚠️ c-manual-sync-lwc not found or not ready');
            }
        }
    }
    
    refreshSchedulerTab() {
        console.log('Refreshing Scheduler Tab...');
        
        // Component must be rendered first
        if (this.activeTab === 'scheduler') {
            const child = this.template.querySelector('c-scheduler-lwc');
            if (child && typeof child.refreshData === 'function') {
                child.refreshData();
            } else {
                console.warn('⚠️ c-scheduler-lwc not found or not ready');
            }
        }
    }
    refreshMappingTab() {
        console.log('Refreshing Status Tab...');
        // e.g. reload data, toggle UI state, or call child method
    }
    //Mind The StepChildren--------------------------
    //-----------------------------------------------
    handleChildUpdate(event) {
        const { field, value } = event.detail;
    
        this.globalData = {
            ...this.globalData,
            [field]: value,version: this.globalData.version + .0001 
        };
        this.showToast('Global Data Updated', `Version: ${this.globalData.version}`,'success');
    }
    showToast(title, message,variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
    handleToastRequest(event) {
        const { title, message, variant } = event.detail;
        this.showToast(title, message, variant);
    }
    handleStatusUpdate(event){
        const newMsg = event.detail.newMsg;
        this.setStatusMessage(newMsg);
    }
    //----------------------------------------------------------
    //status bar
    get statusContentClass() {
        return this.isExpanded ? 'status-content expanded' : 'status-content';
    }

    get statusTabClass() {
        return `status-tab ${this.blinkActive ? 'blink' : ''}`;
    }
    getLabelForIntegrationKey(key) {
            const labelMap = {
                apiUser: 'API User Assignment:',
                allowSyncAdminOnly: 'Allow sync only to Admins:',
                checkQLIBeforeDelete: 'Check QLI Before Delete:',
                checkQuoteBeforeDelete: 'Check Quote Before Delete:',
                contactRecordsPerCall: 'Contact Records Per Call:',
                cw2sfCreateOnlyBusinesses: 'CW2SF - Create Only - Businesses:',
                cw2sfCreateOnlyContacts: 'CW2SF - Create Only - Contacts:',
                cwDealDefaultOwnerEmail: 'CW Default Owner Email:',
                cwOpportunityEnable: 'CW Opportunity Enable:',
                cwPriceBookLevel: 'CW Price Book Level:',
                dealRecordsPerCall: 'Deal Records Per Call:',
                deleteLogsOlderThan: 'Days to keep Error\/ Warning logs:',
                deleteSuccessLogsOlderThan: 'Days to keep Success logs:',
                enableBusinessIdentifier: 'Enable Business Identifier:',
                enableLastModifiedSync: 'Enable Last Modified Sync:',
                enableLastSyncFilter: 'Enable Last Sync Filter:',
                includeCyclesInDLI: 'Include Cycles In DLI Calculations:',
                matchCWMembersOnDeal: 'Match Members by:',
                repCostUpliftPercentage: 'Rep Cost Uplift Percentage:',
                sf2cwCreateOnlyBusinesses: 'SF2CW - Create Only - Businesses:',
                sf2cwCreateOnlyContacts: 'SF2CW - Create Only - Contacts:',
                sf2cwEnablePriceBookListSync: 'SF2CW Enable Price Book List Sync:',
                sfDealDefaultOwnerEmail: 'SF Default Owner Email:',
                showWarningsInErrorLogs: 'Show warnings in error logs:',
                syncCWNowInterval: 'Send & Refresh Interval:',
                useRevToRepPricing: 'Use Revenue to RepCost Pricing:',
                conntest: 'Connection Result:',
                endpointurl: 'End Point URL:',
                clientid: 'AD Client Id:',
                privatekey: 'Private Key:',
                publickey: 'Public Key:',
                companyid: 'Company Id:'
            };

            return labelMap[key] || key;
    }
    getTitleForIntegrationKey(key) {
            const labelMap = {
                apiUser: 'This is the currently assigned user that will be used for processing data coming from ConnectWise',
                allowSyncAdminOnly: 'Restricts Syncronnizing to Administrators Only',
                checkQLIBeforeDelete: 'This disallows the deleteion of Deal Line Item and Quote Line Items associated with Opportunities in ConnectWise',
                checkQuoteBeforeDelete: 'This disallows the deleteion of Quotes associated with Opportunities in ConnectWise',
                contactRecordsPerCall: 'Number of Contact records processed in each batch.',
                cw2sfCreateOnlyBusinesses: 'When this is enabled, new businesses wll be created in Salesforce existing businesses will not be modified.',
                cw2sfCreateOnlyContacts: 'When this is enabled, new contacts wll be created in Salesforce existing contacts will not be modified.',
                cwDealDefaultOwnerEmail: 'This is the email address of the default user to be used when the member doesn\'t exist or no member is chosen.',
                cwOpportunityEnable: 'This is checked by default to enable the Opportunity Object Legacy clients can continue without the use of this object.',
                cwPriceBookLevel: 'This is the name of the PriceBok level assigned to ConectWise products created in Salesforce "ConnectWise" is used by default',
                dealRecordsPerCall: 'Number of Deal records processed in each batch.',
                deleteLogsOlderThan: 'This is the number of days the Error logs are saved',
                deleteSuccessLogsOlderThan: 'This is the number of days the Succcess logs are saved',
                enableBusinessIdentifier: 'Enabled by default to create a unque Identifier for Businesses that will be Sync\'ed with ConnectWise ',
                enableLastModifiedSync: 'This will restrict the Salesforce to only send records modified after the last time they were sync\'d',
                enableLastSyncFilter: 'This will restrict The Updating of records from ConnectWise to only records cahnged after the last time they were sync\'ed',
                includeCyclesInDLI: 'This will include the number of Cycles in Calculatiing the recurring Prices and Costs',
                matchCWMembersOnDeal: 'This determines if we will attempt to match members to users based on email or name. Email is strongly recommended',
                repCostUpliftPercentage: 'This is default uplift that can be added to create a rep cost',
                sf2cwCreateOnlyBusinesses: 'When this is enabled, new businesses wll be created in ConnectWise existing businesses will not be modified.',
                sf2cwCreateOnlyContacts: 'When this is enabled, new contacts wll be created in ConnectWise existing contacts will not be modified.',
                sf2cwEnablePriceBookListSync: 'This is disabled by default. When Enabled(by Agent Dealer Admin Only) this will allow syncing of price book items to the products in ConnectWIse',
                sfDealDefaultOwnerEmail: 'This is the email address of the default user to be used when the user doesn\'t exist or no user is sent in to Salesforce.',
                showWarningsInErrorLogs: 'Depreccated by Pick List',
                syncCWNowInterval: 'Number of minutes between "Instant: batch runs for send and refresh actions',
                useRevToRepPricing: 'This enables the matching od revenue to repcost to calculate the uplift from ConnectWise to Salesforce',
                conntest: 'Your Connection was tested and this displays the result of that test.',
                endpointurl: 'This is the necessary URL That is used to connect to ConnectWise',
                clientid: 'This is AgentDealer\'s Client Id assigned by ConnectWise.',
                privatekey: 'Private Key Used to Ensure Privacy with connections',
                publickey: 'Public Key used in conjunction with private key ot connect to ConnectWise',
                companyid: 'This is the Identifier used to determine which instance of ConnectWise this org should sync with'
            };

            return labelMap[key] || key;
    }
    getTestResults(res){
        let resVal = 'Successfully Connected'
        if(res !='200'){
            resVal='Connection Failed : (' + res +').';
        }
        console.log('res:' + res + '  ' +  resVal);
        return resVal;
    }
    expandStatus() {
        this.isExpanded = true;
        this.blinkActive = false;
    }

    collapseStatus() {
        this.isExpanded = false;
    }

    setStatusMessage(newMsg) {
        if((newMsg)&&(this.statusMessage=='No New Messages')){
            this.statusMessage='';
        }
        if (newMsg !== this.statusMessage) {
            //this.statusMessage = newMsg;
            this.statusMessage += ' | ' + newMsg;
        }

        this.blinkActive = true;

        // Optional: auto-stop blink after a few seconds
        setTimeout(() => {
            if (!this.isExpanded) {
                this.blinkActive = false;
            }
        }, 30000);
        
        
    }
    testTheBlink(){
        this.setStatusMessage('testthis chump');
    }
    //----------------------------------------------------------
    //Logging in and out
    @track logoutUrl = '';
    hasLoggedOut = false;
    logoutPage = `/lightning/n/TSGCW__AgentDealer_ConnectWise_Integration?logout=true`;

    triggerImpLogout() {
        if (this.isCurrentUserAPIUser) {
            console.log('Logging Out in new tab...');
            const logoutTab = window.open('/secur/logout.jsp', '_blank');
    
            setTimeout(() => {
                try {
                    if (logoutTab && !logoutTab.closed) {
                        logoutTab.close();
                        console.log('Logout tab closed');
                    }
                } catch (e) {
                    console.warn('Could not close logout tab:', e);
                }
                this.handleLogoutComplete();
            }, 100);
        }
    }

    impersonateAPIUser() {
        sessionStorage.setItem('originalUserId', userId); // (optional backup before impersonate)
        logImpersonation({userId: this.currentUserId})
        .then(result => {
            if (result!='success'){
                this.showToast('Impersonation Aborted','Error updating Activity logs:'+ result,'Error');
                console.error('Error updating Activity logs:' + result, error); 
            }
        })
        .catch(error => {
            console.error('Error retrieving success logs:', error);
        });
        window.location.href = this.LIAURL; // which includes RETPage with ?oid=userId
    }

    handleLogoutComplete() {
        if (!this.hasLoggedOut) {
            this.hasLoggedOut = true;
            window.location.href = this.logoutPage;
        }
    }
    
}
//NOTES:
/*
The original id will pass throu the retURL and be set when it comes in we will add the logout.jsp file to the Iframe to logout and then we will reload being right wher ewe ar. This will happen when the modal loads and asks if you wan tto logout as the API User.c/cw2sf_ImmediateSyncDealAction
On First Load Modal will ask if you wan to login as api User if you say no the Tabs will not work Only the fron COnnectWise Home will be visible.c/cw2sf_ImmediateSyncDealAction
This will also requirre you to be part of a permissionset or a sysadmin.
onload={handleLogoutComplete}
*/