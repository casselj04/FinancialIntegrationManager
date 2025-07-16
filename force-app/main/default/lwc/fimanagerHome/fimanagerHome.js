import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class FimanagerHome extends LightningElement {
    isLoading=true;
    @track activeTab = 'home';
    @track showTooltip = false;
    @track tooltipText = '';
    @track tooltipStyle = '';
    connectedCallback(){
        this.isLoading= false;
    }
    showHomeTooltip(event) {
        this.showCustomTooltip(event, 'The Home Tab\n\nFrom here you can view you current staus, usage, succes rate.');
    }
    showWFTooltip(event) {
        let msg = 'Wells Fargo Configuration\n\nFrom here you can configure Integration Settings';
        
        this.showCustomTooltip(event,msg );
    }
    showUSBTooltip(event) {
        let msg = 'US Bank Configuration\n\nFrom here you can configure Integration Settings';

        this.showCustomTooltip(event,msg );
    }
    showPSTooltip(event) {
        let msg = 'PEAC Solutions Configuration\n\nFrom here you can configure Integration Settings';

        this.showCustomTooltip(event,msg );
    }
    showLCCTooltip(event) {
        let msg = 'LEAF Configuration\n\nFrom here you can configure Integration Settings';

        this.showCustomTooltip(event,msg );
    }
    showGATooltip(event) {
        let msg = 'Great America Configuration\n\nFrom here you can configure Integration Settings';

        this.showCustomTooltip(event,msg );
    }
    showDLLTooltip(event) {
        let msg = 'De Lage Landen Configuration\n\nFrom here you can configure Integration Settings';

        this.showCustomTooltip(event,msg );
    }        
    hideTooltip(){
        this.showTooltip = false;
       // console.log('TOOLTIP HIDDEN');
    }
    showCustomTooltip(event, text) {
        let yVar = 140;

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
  
    get showHome() {
        return this.activeTab === 'home';
    }    
 
    get showWF() {
        return this.activeTab === 'wf';
    }
    get showUSB() {
        return this.activeTab === 'usb';
    }
   get showPS() {
        return this.activeTab === 'ps';
    }
    get showLCC() {
        return this.activeTab === 'lcc';
    }
    get showGA() {
        return this.activeTab === 'ga';
    }
    get showDLL() {
        return this.activeTab === 'dll';
    }

    get getTabClassHome() {
        return this.activeTab === 'home' ? 'tab-item active' : 'tab-item';
    }
    get getTabClassWF(){return this.activeTab === 'wf' ? 'tab-item active' : 'tab-item';}
    get getTabClassUSB(){return this.activeTab === 'usb' ? 'tab-item active' : 'tab-item';} 
    get getTabClassPS(){return this.activeTab === 'ps' ? 'tab-item active' : 'tab-item';}
    get getTabClassLCC(){return this.activeTab === 'lcc' ? 'tab-item active' : 'tab-item';}
    get getTabClassGA(){return this.activeTab === 'ga' ? 'tab-item active' : 'tab-item';} 
    get getTabClassDLL(){return this.activeTab === 'dll' ? 'tab-item active' : 'tab-item';}

    handleHomeClick() {this.activeTab = 'home';}
    handleWFClick() {this.activeTab = 'wf';}  
    handleUSBClick() {this.activeTab = 'usb';}
    handlePSClick() {this.activeTab = 'ps';}
    handleLCCClick() {this.activeTab = 'lcc';}
    handleGAClick() {this.activeTab = 'ga';}
    handleDLLClick() {this.activeTab = 'dll';}


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
}